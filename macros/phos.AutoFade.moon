export script_name = "Auto Fade"
export script_description = "Automatically determine fade in and fade out"
export script_version = "0.0.2"
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
  },
}
LineCollection, ASS = depctrl\requireModules!
logger = depctrl\getLogger!


windowAssertError = ( condition, errorMessage ) ->
  if not condition
    logger\log errorMessage
    aegisub.cancel!


createGUI = ->
  dialog = {
    {x: 0, y: 0, width: 1, height: 1, class: "label", label: "Co-ordinate"},
    {x: 1, y: 0, width: 5, height: 1, class: "edit", name: "coordinate", value: ""},
    {x: 0, y: 1, width: 1, height: 1, class: "checkbox", name: "fadein", label: "Fade in"},
    {x: 0, y: 2, width: 1, height: 1, class: "checkbox", name: "fadeout", label: "Fade out"},
  }
  btn, res = aegisub.dialog.display dialog, {"OK", "Cancel"}, {"ok": "OK", "cancel": "Cancel"}
  aegisub.cancel! unless btn
  res


main = (sub, sel) ->
  windowAssertError aegisub.get_frame, "You are using unsupported Aegisub.\nPlease use arch1t3cht's Aegisub for this script."
  res = createGUI!
  aegisub.cancel! if not res.fadein and not res.fadeout

  getColor = (curFrame, x, y) ->
    frame = aegisub.get_frame(curFrame, false)
    color = frame\getPixelFormatted(x, y)
    color

  extractRGB = (color) ->
    b, g, r = color\match "&H(..)(..)(..)&"
    tonumber(b, 16), tonumber(g, 16), tonumber(r, 16)

  xCord, yCord = res.coordinate\match "([^,]+),(.*)"
  currentFrame = aegisub.project_properties!.video_position
  targetColor = getColor(currentFrame, xCord, yCord)
  targetB, targetG, targetR = extractRGB(targetColor)

  determineFadeTime = (fadeType, startFrame, endFrame) ->
    local fadeTime
    for i = startFrame, endFrame
      color = getColor(i, xCord, yCord)
      b, g, r = extractRGB(color)
      euclideanDistance = math.sqrt((b-targetB)^2 + (g-targetG)^2 + (r-targetR)^2)
      if (fadeType == "Fade in" and euclideanDistance < 5) or (fadeType == "Fade out" and euclideanDistance > 5)
        fadeTime = math.floor((aegisub.ms_from_frame(i+1)+ aegisub.ms_from_frame(i))/2)
        break
    windowAssertError fadeTime, "#{fadeType} time could not be determined."
    fadeTime

  lines = LineCollection sub, sel
  return if #lines.lines == 0
  lines\runCallback (lines, line, i) ->
    aegisub.cancel! if aegisub.progress.is_cancelled!
    local fadein, fadeout
    if res.fadein
      fadeinTime = determineFadeTime("Fade in", line.startFrame, currentFrame)
      fadein = fadeinTime - line.start_time

    if res.fadeout
      fadeoutTime = determineFadeTime("Fade out", currentFrame, line.endFrame)
      fadeout = line.end_time - fadeoutTime

    if fadein or fadeout
      fadein or= 0
      fadeout or= 0
      data = ASS\parse line
      data\replaceTags {ASS\createTag "fade_simple", fadein, fadeout}
      data\commit!
    else
      windowAssertError false, "Neither fade in nor fade out could be determined."
  lines\replaceLines!

depctrl\registerMacro main
