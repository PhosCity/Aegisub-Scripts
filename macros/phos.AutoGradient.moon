export script_name = "Auto Gradient"
export script_description = "Automatically attemp to gradient the line."
export script_version = "0.0.2"
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
  },
}
LineCollection, ASS = depctrl\requireModules!
logger = depctrl\getLogger!

getColor = (curFrame, x, y) ->
  frame = aegisub.get_frame(curFrame, false)
  color = frame\getPixelFormatted(x, y)
  color

round = (num, idp = 0) ->
  return num if idp == math.huge
  fac = 10^idp
  return math.floor(num * fac + 0.5) / fac

distance = (x1, y1, x2, y2) -> math.sqrt (x2-x1)^2 + (y2-y1)^2

getPointsBetweenCoordinates = (startCoord, endCoord) ->
  x1, y1 = table.unpack startCoord
  x2, y2 = table.unpack endCoord
  dist = distance(x1, y1, x2, y2)
  points = {}
  for i = 1, dist
    m1 = i
    m2 = dist - i
    x = (m1 * x2 + m2 * x1)/(m1 + m2)
    y = (m1 * y2 + m2 * y1)/(m1 + m2)
    table.insert points, {x, y}
  points

extractRGB = (color) ->
  b, g, r = color\match "&H(..)(..)(..)&"
  tonumber(b, 16), tonumber(g, 16), tonumber(r, 16)

colorsAreAlmostSame = (color1, color2) ->
  return false unless color1
  return false unless color2
  b1, g1, r1 = extractRGB color1
  b2, g2, r2 = extractRGB color2
  bdiff, gdiff, rdiff = math.abs(b1-b2), math.abs(g1-g2), math.abs(r1-r2)
  tolerance = 2
  if bdiff < tolerance and gdiff < tolerance and rdiff < tolerance
    return true
  return false

main = (mode) ->
  (sub, sel) ->

    lines = LineCollection sub, sel
    return if #lines.lines == 0
    if #lines.lines > 1
      logger\log "This script really works in one line only for now. Bug me if you want it to work in multilines."
      aegisub.cancel!

    local bounds
    clipTable = {}
    currentFrame = aegisub.project_properties!.video_position
    lines\runCallback (lines, line, i) ->
      aegisub.cancel! if aegisub.progress.is_cancelled!

      data = ASS\parse line
      clip = data\getTags "clip_vect"
      return if  #clip == 0
      data\removeTags "clip_vect"

      bounds = data\getLineBounds!  -- Get line bounds for later use

      for index, cnt in ipairs clip[1].contours[1].commands  -- Is this the best way to loop through co-ordinate?
        break if index == 3
        x, y = cnt\get!
        table.insert clipTable, {x, y}
      data\commit!

    x1, y1 = bounds[1].x, bounds[1].y
    x2, y2 = bounds[2].x, bounds[2].y

    clipTable = getPointsBetweenCoordinates(clipTable[1], clipTable[2])
    clipCnt = #clipTable

    gradientTable = {}
    local prevColor
    if mode == "vertical"
      for j = y1, y2
        currPercent = (j - y1) / (y2 - y1)
        index = math.floor(round(currPercent * clipCnt))
        index = math.max(index, 1)
        x, y = table.unpack clipTable[index]
        color = getColor currentFrame, x, y

        if colorsAreAlmostSame(prevColor, color)
          gradientTable[#gradientTable][4] = j+1
        else
          table.insert gradientTable, {x1, j, x2, j+1, color}
        prevColor = color
    else
      for j = x1, x2
        currPercent = (j - x1) / (x2 - x1)
        index = math.floor(round(currPercent * clipCnt))
        index = math.max(index, 1)
        x, y = table.unpack clipTable[index]
        color = getColor currentFrame, x, y

        if colorsAreAlmostSame(prevColor, color)
          gradientTable[#gradientTable][3] = j+1
        else
          table.insert gradientTable, {j, y1, j+1, y2, color}
        prevColor = color

    x1 = nil
    y1 = nil
    mode = nil
    bounds = nil
    clipCnt = nil
    clipTable = nil
    prevColor = nil
    colorTable = nil
    currentFrame = nil
    collectgarbage!

    to_delete = {}
    lines\runCallback (lines, line, i) ->
      aegisub.cancel! if aegisub.progress.is_cancelled!
      table.insert to_delete, line

      data = ASS\parse line
      for item in *gradientTable
        leftX, leftY, rightX, rightY, color = table.unpack item
        b, g, r = extractRGB(color)
        data\replaceTags {ASS\createTag "clip_rect", leftX, leftY, rightX, rightY}
        data\replaceTags {ASS\createTag "color1", b, g, r}
        lines\addLine ASS\createLine {line}

    lines\insertLines!
    lines\deleteLines to_delete

    lines = nil
    to_delete = nil
    gradientTable = nil
    collectgarbage!

depctrl\registerMacros({
  {"Horizontal", "Horizontal Gradient", main "horizontal"},
  {"Vertical", "Vertical Gradient", main "vertical"},
})
