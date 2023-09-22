export script_name = "Timing Assistant"
export script_description = "A second brain for timers."
export script_version = "1.1.0"
export script_author = "PhosCity"
export script_namespace = "phos.TimingAssistant"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
  feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json"
}
logger = depctrl\getLogger!

getTime, getFrame = aegisub.ms_from_frame, aegisub.frame_from_ms
defaultConfig =
  startLeadIn: 120
  startKeysnapBefore: 350
  startKeysnapAfter: 100
  startLink: 620
  endLeadOut: 400
  endKeysnapBefore: 300
  endKeysnapAfter: 900
  debug: false
  automove: false


config = depctrl\getConfigHandler defaultConfig
configSetup = ->
  y, dlg = 1,  {
		{x: 0, y: 0,  width: 1, height: 1, class: "label",    label: "Start:"}
		{x: 0, y: 10, width: 1, height: 1, class: "label",    label: "End:"}
		{x: 0, y: 18, width: 5, height: 1, class: "checkbox", label: "Auto-move to next line after making changes", name: "automove", value: config.c.automove}
		{x: 3, y: 0,  width: 1, height: 1, class: "checkbox", label: "Debug", name: "debug", value: config.c.debug, hint: "Disply debugging messages"}
  }
  data = {
    {"Lead in",         "startLeadIn",        config.c.startLeadIn,        "100-150 ms",  "Lead in amound from exact start"}
    {"Key Snap Before", "startKeysnapBefore", config.c.startKeysnapBefore, "~2*leadin",   "Time to snap to keyframe before the exact start"}
    {"Key Snap After",  "startKeysnapAfter",  config.c.startKeysnapAFter,  "0-100 ms",   "Time to snap to keyframe after the exact start"}
    {"Line Link",       "startLink",          config.c.startLink,          "~500+leadin", "Time from exact start of current line to end-time of previous line to link"}
    {"Lead out",        "endLeadOut",         config.c.endLeadOut,         "350-450 ms",  "Lead out amount from exact end"}
    {"Key Snap Before", "endKeysnapBefore",   config.c.endKeysnapBefore,   "100-300 ms",  "Time to snap to keyframe before the exact end"}
    {"Key Snap After",  "endKeysnapAfter",    config.c.endKeysnapAfter,    "800-1000 ms", "Time to snap to keyframe after the exact end"}
  }
  for index, item in ipairs data
    dlg[#dlg+1] = {x: 0, y: y,   width: 5, height: 1, class: "label",   label: item[5]}
    dlg[#dlg+1] = {x: 0, y: y+1, width: 1, height: 1, class: "label",   label: item[1]}
    dlg[#dlg+1] = {x: 1, y: y+1, width: 1, height: 1, class: "intedit", name: item[2], value: item[3]}
    dlg[#dlg+1] = {x: 3, y: y+1, width: 1, height: 1, class: "label",   label: "Recommended value: #{item[4]}"}
    if index %4 == 0 y += 4 else y += 2

  btn, res = aegisub.dialog.display dlg, { "Save", "Reset", "Cancel" }
  aegisub.cancel! if btn == "Cancel"
  opt = config.c
  saveSource = res
  saveSource = defaultConfig if btn == "Reset"
  with saveSource
    opt.startLeadIn = .startLeadIn
    opt.startKeysnapBefore = .startKeysnapBefore
    opt.startKeysnapAfter = .startKeysnapAfter
    opt.startLink = .startLink
    opt.endLeadOut = .endLeadOut
    opt.endKeysnapBefore = .endKeysnapBefore
    opt.endKeysnapAfter = .endKeysnapAfter
    opt.automove = .automove
    opt.debug = .debug
  config\write!


debugMsg = (msg) -> logger\log msg if config.c.debug


isKeyframe = (time) ->
  keyframe = aegisub.keyframes!
  currFrame = getFrame time
  for kf in *keyframe
    return true if currFrame == kf
  false


calculateCPS = (line) ->
  text = line.text
  duration = (line.end_time - line.start_time)/1000
  char = text\gsub("%b{}", "")\gsub("\\[Nnh]", "*")\gsub("%s?%*+%s?", " ")\gsub("[%s%p]", "")
  math.ceil(char\len!/duration)


findAdjacentKeyframes = (time) ->
  keyframe = aegisub.keyframes!
  local previousKeyframe, nextKeyframe
  currFrame = getFrame time
  for k, kf in ipairs keyframe
    previousKeyframe = keyframe[k] if kf < currFrame
    nextKeyframe = keyframe[k] if kf > currFrame
    break if nextKeyframe
  return previousKeyframe, nextKeyframe


timeStart = (sub, sel, opt) ->
  for i in *sel
    continue unless sub[i].class == "dialogue"
    line = sub[i]
    local snap, link, previousLine, endTimePrevious
    startTime, endTime = aegisub.get_audio_selection!

    debugMsg "Start:"

    -- Determine if start time of current line is already snapped to keyframe and exit if it is
    if isKeyframe(startTime)
      debugMsg "Line start was already snapped to keyframe"
      return
    
    -- Determine the previous non-commented line.
    j = 1
    while true
      previousLine = sub[i - j]
      break if previousLine.comment == false or i - j <= 1
      j += 1

    -- Determine the end time of previous line
    endTimePrevious = previousLine.end_time

    -- Keyframe Snapping
    previousKeyframe, nextKeyframe = findAdjacentKeyframes startTime
    if math.abs(getTime(previousKeyframe) - startTime) < opt.startKeysnapBefore
      line.start_time = getTime previousKeyframe
      snap = true
      debugMsg "Keyframe snap behind"
    if math.abs(getTime(nextKeyframe) - startTime) < opt.startKeysnapAfter and not snap
      line.start_time = getTime nextKeyframe
      snap = true
      debugMsg "Keyframe snap ahead"

    -- Line Linking
    if endTimePrevious and math.abs(endTimePrevious - startTime) < opt.startLink and not isKeyframe(endTimePrevious)
      previousKeyframe, nextKeyframe = findAdjacentKeyframes endTimePrevious
      keyframePlus500ms = getTime(previousKeyframe) + 500

      if startTime < endTimePrevious and endTimePrevious < keyframePlus500ms
        line.start_time = startTime - opt.startLeadIn unless snap
        previousLine.end_time = getTime previousKeyframe
        debugMsg "Link lines failed because a keyframe is close. Snap end of last line. Add lead in to current line."

      elseif (startTime - opt.startLeadIn) > (getTime(nextKeyframe) - 500)
        line.start_time = getTime(nextKeyframe) -500 unless snap
        previousLine.end_time = line.start_time
        debugMsg "Link lines by ensuring that start time is 500 ms away from next keyframe."

      else
        line.start_time = startTime - math.min(opt.startLeadIn, startTime - keyframePlus500ms) unless snap
        previousLine.end_time = line.start_time
        debugMsg "Link lines by adding appropriate lead in to current line."

      sub[i - j] = previousLine
      link = true

    -- lead in
    unless snap or link
      line.start_time = startTime - opt.startLeadIn
      debugMsg "Lead In"

    line.end_time = endTime
    sub[i] = line


timeEnd = (sub, sel, opt) ->
  for i in *sel
    continue unless sub[i].class == "dialogue"
    line = sub[i]
    _, endTime = aegisub.get_audio_selection!
    local snap

    debugMsg "\nEnd:"

    -- Determine if end time of current line is already snapped to keyframe and exit if it is
    if isKeyframe(endTime)
      debugMsg "Line end was already snapped to keyframe"
      return

    -- Find the previous and next keyframe for end time
    previousKeyframe, nextKeyframe = findAdjacentKeyframes endTime

    -- If the keyframe is after 850 ms and before the limit you set, check the cps
    -- If cps is less than 15, then add normal lead out or make the end time 500 ms far from keyframe whichever is lesser
    -- If cps is more than 15, then snap to keyframe
    nextKfDistance = math.abs(getTime(nextKeyframe) - endTime)
    previousKfDistance = math.abs(getTime(previousKeyframe) - endTime)
    if opt.endKeysnapAfter >= 850 and nextKfDistance >= 850 and nextKfDistance <= opt.endKeysnapAfter and previousKfDistance > opt.endKeysnapBefore
      cps = calculateCPS(line)
      if cps <= 15
        line.end_time = endTime + math.min(opt.endLeadOut, nextKfDistance  - 500)
        debugMsg "cps is less than 15.\nAdjusting end time so that it's 500 ms away from keyframe or adding lead out whichever is lesser." 
      else
        line.end_time = getTime nextKeyframe
        debugMsg "cps is more than 15.\nSnapping to keyframe more than 850 ms away."
    else
      -- Keyframe Snapping
      if previousKfDistance < opt.endKeysnapBefore
        line.end_time = getTime previousKeyframe
        snap = true
        debugMsg "Keyframe snap behind"
      if nextKfDistance < opt.endKeysnapAfter and not isKeyframe(line.end_time)
        line.end_time = getTime nextKeyframe
        snap = true
        debugMsg "Keyframe snap ahead"

      -- Lead out
      unless snap
        line.end_time = endTime + opt.endLeadOut
        debugMsg "Lead Out"
    sub[i] = line


timeBoth = (sub, sel) ->
  logger\assert #sel == 1, "You must select exactly one line\nThis is not a TPP replacement."
  config\load!
  opt = config.c
  timeStart sub, sel, opt
  timeEnd sub, sel, opt

  if opt.automove and sel[1] + 1 <= #sub
    return { sel[1] + 1}


depctrl\registerMacros({
  { "Time", "Time the line after exact timing", timeBoth },
  { "Config", "Configuration for the script", configSetup }
})
