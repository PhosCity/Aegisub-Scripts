export script_name = "Auto Gradient"
export script_description = "Automatically attemp to gradient the line."
export script_version = "0.0.1"
export script_author = "PhosCity"
export script_namespace = "phos.AutoGradient"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
  feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
  {
    {"a-mo.LineCollection", version: "1.3.0", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
    {"l0.ASSFoundation", version: "0.5.0", url: "https: //github.com/TypesettingTools/ASSFoundation",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
      "aegisub.util"
  },
}
LineCollection, ASS, util = depctrl\requireModules!
logger = depctrl\getLogger!

getColor = (curFrame, x, y) ->
  frame = aegisub.get_frame(curFrame, false)
  color = frame\getPixelFormatted(x, y)
  color

round = (num, idp = 0) ->
  return num if idp == math.huge
  fac = 10^idp
  return math.floor(num * fac + 0.5) / fac

main = (mode) ->
  (sub, sel) ->

    lines = LineCollection sub, sel
    return if #lines.lines == 0
    if #lines.lines > 1
      logger\log "This script really works in one line only for now. Bug me if you want it to work in multilines."
      aegisub.cancel!

    local bounds
    clipTable= {start: {}, end:{}}
    currentFrame = aegisub.project_properties!.video_position
    lines\runCallback (lines, line, i) ->
      aegisub.cancel! if aegisub.progress.is_cancelled!

      data = ASS\parse line
      clip = data\getTags "clip_vect"
      return if  #clip == 0
      data\removeTags "clip_vect"

      -- Get line bounds for later use
      bounds = data\getLineBounds!

      for index, cnt in ipairs clip[1].contours[1].commands          -- Is this the best way to loop through co-ordinate?
        break if index == 3
        x, y = cnt\get!
        if index == 1
          clipTable.start.x = x
          clipTable.start.y = y
        else
          clipTable.end.x = x
          clipTable.end.y = y
      data\commit!

    colorTable = {}
    if mode == "vertical"
      x = clipTable.start.x
      step = clipTable.start.y > clipTable.end.y and -1 or 1
      for y = clipTable.start.y, clipTable.end.y, step
        table.insert colorTable, getColor(currentFrame, x, y)
    else
      y = clipTable.start.y
      step = clipTable.start.x > clipTable.end.x and -1 or 1
      for x = clipTable.start.x, clipTable.end.x, step
        table.insert colorTable, getColor(currentFrame, x, y)

    collectgarbage!

    x1, y1 = bounds[1].x, bounds[1].y
    x2, y2 = bounds[2].x, bounds[2].y

    to_delete = {}
    lines\runCallback (lines, line, i) ->
      aegisub.cancel! if aegisub.progress.is_cancelled!
      table.insert to_delete, line

      data = ASS\parse line
      if mode == "vertical"
        for j = y1, y2
          currPercent = (j - y1) / (y2 - y1)
          index = math.floor(round(currPercent * #colorTable))
          index = math.max(index, 1)
          color = colorTable[index]
          r, g, b = util.extract_color(color)
          data\replaceTags {ASS\createTag "clip_rect", x1, j, x2, j + 1}
          data\replaceTags {ASS\createTag "color1", b, g, r}
          lines\addLine ASS\createLine {line}
      else
        for j = x1, x2
          currPercent = (j - x1) / (x2 - x1)
          index = math.floor(round(currPercent * #colorTable))
          index = math.max(index, 1)
          color = colorTable[index]
          r, g, b = util.extract_color(color)
          data\replaceTags {ASS\createTag "clip_rect", j, y1, j+1, y2}
          data\replaceTags {ASS\createTag "color1", b, g, r}
          lines\addLine ASS\createLine {line}

    lines\insertLines!
    lines\deleteLines to_delete

    mode = nil
    lines = nil
    bounds = nil
    clipTable = nil
    to_delete = nil
    colorTable = nil
    collectgarbage!

depctrl\registerMacros({
  {"Horizontal", "Horizontal Gradient", main "horizontal"},
  {"Vertical", "Vertical Gradient", main "vertical"},
})
