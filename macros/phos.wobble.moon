export script_name = "Wobble"
export script_description = "Adds wobbling to text and shape"
export script_version = "2.0.4"
export script_author = "PhosCity"
export script_namespace = "phos.wobble"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
  feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
  {
    {"a-mo.LineCollection", version: "1.3.0", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
    {"l0.ASSFoundation", version: "0.5.0", url: "https: //github.com/TypesettingTools/ASSFoundation",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
    {"Yutils"}
  },
}
LineCollection, ASS, Yutils = depctrl\requireModules!
logger = depctrl\getLogger!


configTemplate = {
  { class: "label",     x: 0, y: 0, label: "Wobble frequency: " },
  { class: "floatedit", x: 1, y: 0, hint: "Horizontal wobbling frequency in percent", value: 0, min: 0, max: 100, step: 0.5,  name: "wobbleFrequencyX" },
  { class: "floatedit", x: 2, y: 0, hint: "Vertical wobbling frequency in percent",   value: 0, min: 0, max: 100, step: 0.5,  name: "wobbleFrequencyY" },
  { class: "label",     x: 0, y: 1, label: "Wobble strength: " },
  { class: "floatedit", x: 1, y: 1, hint: "Horizontal wobbling strength in pixels",   value: 0, min: 0, max: 100, step: 0.01, name: "wobbleStrengthX" },
  { class: "floatedit", x: 2, y: 1, hint: "Vertical wobbling strength in pixels",     value: 0, min: 0, max: 100, step: 0.01, name: "wobbleStrengthY" },
}

animateTemplate = {
  { class: "label",     x: 1, y: 0, label: "Start Value" },
  { class: "label",     x: 2, y: 0, label: "End Value"   },
  { class: "label",     x: 3, y: 0, label: "Accel"       },
  { class: "label",     x: 0, y: 1, label: "Frequency x" },
  { class: "floatedit", x: 1, y: 1, hint: "Horizontal wobbling frequency in percent", value: 0, min: 0, max: 100, step: 0.5, name: "freqXStart" },
  { class: "floatedit", x: 2, y: 1, hint: "Horizontal wobbling frequency in percent", value: 0, min: 0, max: 100, step: 0.5, name: "freqXEnd" },
  { class: "floatedit", x: 3, y: 1, hint: "Accel for frequency x",                    value: 1, name: "freqXAccel" },
  { class: "label",     x: 0, y: 2, label: "Frequency y" },
  { class: "floatedit", x: 1, y: 2, hint: "Vertical wobbling frequency in percent",   value: 0, min: 0, max: 100, step: 0.5, name: "freqYStart" },
  { class: "floatedit", x: 2, y: 2, hint: "Vertical wobbling frequency in percent",   value: 0, min: 0, max: 100, step: 0.5, name: "freqYEnd" },
  { class: "floatedit", x: 3, y: 2, hint: "Accel for frequency y",                    value: 1, name: "freqYAccel" },

  { class: "label",     x: 0, y: 3, label: "Strength x" },
  { class: "floatedit", x: 1, y: 3, hint: "Horizontal wobbling strength in pixels",   value: 0, min: 0, max: 100, step: 0.01, name: "strengthXStart" },
  { class: "floatedit", x: 2, y: 3, hint: "Horizontal wobbling strength in pixels",   value: 0, min: 0, max: 100, step: 0.01, name: "strengthXEnd" },
  { class: "floatedit", x: 3, y: 3, hint: "Accel for strength x",                     value: 1, name: "strengthXAccel" },
  { class: "label",     x: 0, y: 4, label: "Strength y" },
  { class: "floatedit", x: 1, y: 4, hint: "Vertical wobbling strength in pixels",     value: 0, min: 0, max: 100, step: 0.01, name: "strengthYStart" },
  { class: "floatedit", x: 2, y: 4, hint: "Vertical wobbling strength in pixels",     value: 0, min: 0, max: 100, step: 0.01, name: "strengthYEnd" },
  { class: "floatedit", x: 3, y: 4, hint: "Accel for strength y",                     value: 1, name: "strengthYAccel" },
}

waveTemplate = {
  { class: "label",     x: 0, y: 0, label: "Wobble frequency: " },
  { class: "floatedit", x: 1, y: 0, hint: "Horizontal wobbling frequency in percent", value: 0, min: 0, max: 100, step: 0.5, name: "wobbleFrequencyX" },
  { class: "floatedit", x: 2, y: 0, hint: "Vertical wobbling frequency in percent",   value: 0, min: 0, max: 100, step: 0.5, name: "wobbleFrequencyY" },
  { class: "label",     x: 0, y: 1, label: "Wobble strength: " },
  { class: "floatedit", x: 1, y: 1, hint: "Horizontal wobbling strength in pixels",   value: 0, min: 0, max: 100, step: 0.01, name: "wobbleStrengthX" },
  { class: "floatedit", x: 2, y: 1, hint: "Vertical wobbling strength in pixels",     value: 0, min: 0, max: 100, step: 0.01, name: "wobbleStrengthY" },
  { class: "label",     x: 0, y: 2, label: "Wave" },
  { class: "floatedit", x: 1, y: 2, hint: "Waving speed. (Values between 1-5)",       value: 0, min: 0, max: 5,   step: 0.1, name: "wavingSpeed" },
}

createGUI = (guiType) ->
  dialog = switch guiType
    when "Static" then configTemplate
    when "Animate" then animateTemplate
    when "Wave" then waveTemplate

  btn, res = aegisub.dialog.display dialog, {"OK", "Cancel"}, {"ok": "OK", "cancel": "Cancel"}
  aegisub.cancel! unless btn

  -- Save GUI configuration
  local configEntry
  for key, value in pairs res
    for i = 1, #dialog
      configEntry = dialog[i]
      continue unless configEntry.name == key
      if configEntry.value
        configEntry.value = value
      elseif configEntry.text
        configEntry.text = value
      break
  res.wavingSpeed = 0 unless guiType == "Wave"
  res


-- When percentage_value is 1, it returns ~0.0001 and for 100, it returns ~2.5
frequencyValue = (percentage_value) ->
  if percentage_value < 50
    return 0.0000825 * 1.212 ^ percentage_value
  else
    return (1.25 * percentage_value) / 50


interpolate = (startValue, endValue, accel, lineCnt, i) ->
	factor = (i - 1) ^ accel / (lineCnt - 1) ^ accel
	if factor <= 0
		return startValue
	elseif factor >= 1
		return endValue
	else
		return factor * (endValue - startValue) + startValue


wobble = (shape, res) ->
  frequencyX = frequencyValue res.wobbleFrequencyX
  frequencyY = frequencyValue res.wobbleFrequencyY
  if (frequencyX > 0 and res.wobbleStrengthX > 0) or (frequencyY > 0 and res.wobbleStrengthY > 0)
    shape = Yutils.shape.filter(Yutils.shape.split(Yutils.shape.flatten(shape), 1), (x, y) ->
      return x + math.sin(y * frequencyX * math.pi * 2 + res.wavingSpeed) * res.wobbleStrengthX, y + math.sin(x * frequencyY * math.pi * 2 + res.wavingSpeed) * res.wobbleStrengthY
    )
  shape


main = (wobbleType) ->
  (sub, sel) ->
    res = createGUI wobbleType

    lines = LineCollection sub, sel
    lineCnt = #lines.lines
    return if lineCnt == 0

    local speedIncrement
    alignMsgShown = false
    lines\runCallback ((lines, line, i) ->
      aegisub.cancel! if aegisub.progress.is_cancelled!
      aegisub.progress.task "Processing line %d of %d lines..."\format i, lineCnt if i%10==0
      aegisub.progress.set 100*i/lineCnt

      data = ASS\parse line
      local shape
      if data\getSectionCount(ASS.Section.Drawing) > 0
        data\callback ((section) -> shape = section\toString!), ASS.Section.Drawing
      elseif data\getSectionCount(ASS.Section.Text) > 0
        effTags = (data\getEffectiveTags -1, true, true, false).tags
        if alignMsgShown == false and not effTags.align\equal 7
          alignMsgShown = true
          logger\log "The resulting line may have different position because the alignment is not 7."
          logger\log "The script will proceed the operation but if position matters to you, please use '\\an7' in the line."

        data\callback ((section) ->
          -- TODO: Text.getShape does not work currently. Use that after Arch's PR gets added.
          _, _, shape = section\getTextMetrics true
          shape = shape\gsub " c", ""
        ), ASS.Section.Text
      else
        logger\log "No text or drawing in the line."
        aegisub.cancel!

      if wobbleType == "Wave"
        speedIncrement or= res.wavingSpeed
        res.wavingSpeed += speedIncrement
      elseif wobbleType == "Animate"
        if (res.freqXStart >= 0 and res.strengthXStart >= 0) or (res.freqYStart >= 0 and res.strengthYStart >= 0)
          res.wobbleFrequencyX = interpolate(res.freqXStart, res.freqXEnd, res.freqXAccel, lineCnt, i)
          res.wobbleFrequencyY = interpolate(res.freqYStart, res.freqYEnd, res.freqYAccel, lineCnt, i)
          res.wobbleStrengthX = interpolate(res.strengthXStart, res.strengthXEnd, res.strengthXAccel, lineCnt, i)
          res.wobbleStrengthY = interpolate(res.strengthYStart, res.strengthYEnd, res.strengthYAccel, lineCnt, i)

      shape = wobble shape, res
      drawing = ASS.Draw.DrawingBase{str: shape}
      data\removeSections 2, #data.sections
      data\insertSections ASS.Section.Drawing {drawing}
      data\removeTags {"fontname", "fontsize", "italic", "bold", "underline", "strikeout", "spacing"}
      data\replaceTags {ASS\createTag 'scale_x', 100}
      data\replaceTags {ASS\createTag 'scale_y', 100}
      data\commit!
    ), true
    lines\replaceLines!


depctrl\registerMacros({
  {"Static", "Get distorted text or shape in a line", main "Static"},
  {"Animate", "Animate from one value of distortion to another", main "Animate"},
  {"Wave", "Create wave effect", main "Wave"},
})
