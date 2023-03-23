export script_name = "Auto Fade"
export script_description = "Automatically determine fade in and fade out"
export script_version = "0.0.4"
export script_author = "PhosCity"
export script_namespace = "phos.AutoFade"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
  feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
  {
    {"a-mo.LineCollection", version: "1.3.0", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
    {"l0.ASSFoundation", version: "0.5.0", url: "https: //github.com/TypesettingTools/ASSFoundation",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
    "aegisub.clipboard"
  },
}
LineCollection, ASS, clipboard = depctrl\requireModules!
logger = depctrl\getLogger!


windowAssertError = ( condition, errorMessage ) ->
  if not condition
    logger\log errorMessage
    aegisub.cancel!


createGUI = (coordinateValue) ->
  dialog = {
    {x: 0, y: 0, width: 1, height: 1, class: "label", label: "Co-ordinate"},
    {x: 1, y: 0, width: 20, height: 1, class: "edit", name: "coordinate", value: coordinateValue},
  }
  btn, res = aegisub.dialog.display dialog, {"Fade in", "Fade out", "Both", "Cancel"}
  if btn == nil or btn == "Cancel"
    aegisub.cancel!
  else
    return res, btn


main = (sub, sel) ->
  windowAssertError aegisub.get_frame, "You are using unsupported Aegisub.\nPlease use arch1t3cht's Aegisub for this script."
  fadeLimit = (aegisub.ms_from_frame(2)-aegisub.ms_from_frame(1))/2  -- Fade time below this can be negleted.

  getColor = (curFrame, x, y) ->
    frame = aegisub.get_frame(curFrame, false)
    color = frame\getPixelFormatted(x, y)
    color

  extractRGB = (color) ->
    b, g, r = color\match "&H(..)(..)(..)&"
    tonumber(b, 16), tonumber(g, 16), tonumber(r, 16)

  euclideanDistance = (color1, color2) ->
    b1, g1, r1 = extractRGB(color1)
    b2, g2, r2 = extractRGB(color2)
    math.sqrt((b1-b2)^2 + (g1-g2)^2 + (r1-r2)^2)

  determineFadeTime = (fadeType, startFrame, endFrame, xCord, yCord, targetColor) ->
    local fadeTime
    for i = startFrame, endFrame
      color = getColor(i, xCord, yCord)
      dist = euclideanDistance(color, targetColor)
      if (fadeType == "Fade in" and dist < 5) or (fadeType == "Fade out" and dist > 5)
        fadeTime = math.floor((aegisub.ms_from_frame(i+1)+ aegisub.ms_from_frame(i))/2)
        break
    windowAssertError fadeTime, "#{fadeType} time could not be determined."
    fadeTime

  lines = LineCollection sub, sel
  windowAssertError #lines.lines == 1, "Because of how this script works, it can only be run in one line at a time. Sorry for the inconvenience."
  lines\runCallback (lines, line, i) ->
    local removeClip, fadein, fadeout

    -- Try to see if there is a single point clip in the line
    xCord, yCord = line.text\match "\\i?clip%(m ([%d.]+) ([%d.]+)%)"
    if xCord
      removeClip = true
    else -- Since there is no single point clip, try to see if there is coordinate in clipboard
      xCord, yCord = clipboard.get!\match "([%d.]+),([%d.]+)"

    res, btn = createGUI xCord and "#{xCord},#{yCord}" or ""

    xCord, yCord = res.coordinate\match "([%d.]+),([%d.]+)"
    if not xCord and not yCord
      windowAssertError false, "The co-ordinate could not be properly determined. The format of the co-ordinate is x,y"

    currentFrame = aegisub.project_properties!.video_position
    windowAssertError currentFrame >= line.startFrame, "Your current video position is before the start time of the line."
    windowAssertError currentFrame <= line.endFrame, "Your current video position is after the end time of the line."
    targetColor = getColor(currentFrame, xCord, yCord)

    if btn == "Fade in" or btn == "Both"
      fadeinTime = determineFadeTime("Fade in", line.startFrame, currentFrame, xCord, yCord, targetColor)
      fadein = fadeinTime - line.start_time
      fadein = 0 if fadein < fadeLimit

    if btn == "Fade out" or btn == "Both"
      -- Speed up calculation of fade out by skipping having to step through each frame
      while true
        fr = math.floor((currentFrame + line.endFrame) / 2)
        color = getColor(fr, xCord, yCord)
        if euclideanDistance(color, targetColor) < 5
          currentFrame = fr
        else
          break
        break if line.endFrame - currentFrame < 10
      fadeoutTime = determineFadeTime("Fade out", currentFrame, line.endFrame, xCord, yCord, targetColor)
      fadeout = line.end_time - fadeoutTime
      fadeout = 0 if fadeout < fadeLimit

    if fadein or fadeout
      fadein or= 0
      fadeout or= 0
      data = ASS\parse line
      data\removeTags {"clip_vect", "iclip_vect"} if removeClip
      if fadein != 0 and fadeout != 0
        data\replaceTags {ASS\createTag "fade_simple", fadein, fadeout}
      data\commit!
    else
      windowAssertError false, "Neither fade in nor fade out could be determined."
  lines\replaceLines!

depctrl\registerMacro main
