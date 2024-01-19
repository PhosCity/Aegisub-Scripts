export script_name = "Discord ASS Highlight"
export script_description = "Copy line to discord with highlights"
export script_version = "0.0.1"
export script_author = "PhosCity"
export script_namespace = "phos.DiscordASSHighlight"

-- If you want to highlight coordinate, set this to true. Although if the shape is too long, discord fails to color them.
highlightCoodinate = false


die = (msg) ->
  aegisub.log "msg"
  aegisub.cancel!


escLuaExp = (str) -> str\gsub "([%%%(%)%[%]%.%*%-%+%?%$%^])", "%%%1"


splitTimestamp= (time) ->
    splitTime = (time, div) ->
      split = time % div
      return split, (time - split) / div

    splits = {}
    splits.f, time = splitTime time, 1000
    splits.s, time = splitTime time, 60
    splits.m, time = splitTime time, 60
    splits.h = time
    return splits


ms2AssTimecode = (time) ->
    {:h, :m, :s, :f} = splitTimestamp time
    if h > 9
      return nil, "value too large to create an ASS timecode"
    return string.format("%01d:%02d:%02d.%02d", h, m, s, f/10)


split = (str, sep = " ", init = 1, plain = true, limit = -1) ->
    first, last = str\find sep, init, plain
    -- fast return if there's nothing to split - saves one str.sub()
    return {str}, 1 if not first or limit == 0

    splits, s = {}, 1
    while first and s != limit + 1
      splits[s] = str\sub init, first - 1
      s += 1
      init = last + 1
      first, last = str\find sep, init, plain

    splits[s] = str\sub init
    return splits, s


formatText = (text, color, format) ->
  color < 1 or color > 8 and die "Invalid color code."

  formatCodes = {
    ["bold"]: 1,
    ["underline"]: 4,
  }

  colorCodes = {
    [0]: "0m",      -- reset
    [1]: "31m",     -- red
    [2]: "32m",     -- yellowish green
    [3]: "33m",     -- yellow
    [4]: "34m",     -- light blue
    [5]: "35m",     -- pink
    [6]: "36m",     -- cyan
    [7]: "37m"      -- white
    [8]: "37m"      -- dark gray
  }

  str = "\27["
  if format
    str ..= formatCodes[format]..";"
  str ..= colorCodes[color] .. text .. "\27[".. colorCodes[0]
  str


contours = (shape) ->
  local shapeType, splitShape, splitCount
  if shape\match "[%-%d%.]+,"
    splitShape, splitCount = split shape, ","
    shapeType = "rect"
  else
    splitShape, splitCount = split shape, "%s+", nil, false
    shapetype = "vect"

  local drawingCmd
  finalString = ""
  bezierCount = 0
  count = 1
  for i, coord in ipairs splitShape
    if coord\match "[mnlbspc]"
      drawingCmd = coord
      finalString ..= "#{coord} "
      continue

    if drawingCmd == "b"
      bezierCount += 1
      bezierCount = 1 if bezierCount == 7
    else
      bezierCount = 0

    if count % 2 == 0
      finalString ..= formatText(coord, 2, bezierCount > 4 and "underline" or "bold")
    else
      finalString ..= formatText(coord, 1, bezierCount > 4 and "underline" or "bold")

    unless i == splitCount
      finalString ..= shapeType == "rect" and "," or " "

    count += 1

  finalString


tagColorizer = (text) ->

  tag = {"alpha", "1a", "3a", "4a",
    "fscx", "fscy",
    "fs", "fsp", "fn",
    "fax", "frx", "fry", "frz",
    "bord", "xbord", "ybord",
    "shad", "xshad", "yshad",
    "blur", "be",
    "an",
    "q",
    "fade", "fad",
    "pos", "move", "org"
    "c", "1c", "3c", "4c",
    "i", "b", "u", "s", "t"
  }

  if highlightCoodinate
    for item in *{"clip", "iclip"}
      continue unless text\match "\\#{item}%("
      for klip in text\gmatch "\\#{item}%(([^)]-)%)"
        text = text\gsub "\\#{item}%(#{klip}%)", formatText("\\",5)..formatText(item,5, "bold").."(".. contours(klip)..")"
  else
    table.insert tag, 1, "iclip"
    table.insert tag, 1, "clip"

  for item in *tag
    text=text\gsub "\\#{item}([^\\}]+)([\\}])", formatText("\\",5)..formatText(item,5, "bold")..formatText("%1",6, "bold").."%2"
  text

main = (subs, sel) ->
  output = "```ansi\n"
  for i in *sel
    continue unless subs[i].class == "dialogue"
    line = subs[i]

    lineType = line.comment and "Comment: " or "Dialogue: "
    lineType = formatText(lineType,4)

    layer = formatText(line.layer,3)

    startTime = ms2AssTimecode line.start_time
    startTime = formatText(startTime,3)

    endTime = ms2AssTimecode line.end_time
    endTime = formatText(endTime,3)

    style = formatText(line.style,2)

    actor = formatText(line.actor,3)

    margin_left = formatText(line.margin_l,3)
    margin_right = formatText(line.margin_r,3)
    margin_vertical = formatText(line.margin_t,3)

    effect = formatText(line.effect,2)

    text = line.text

    -- Comments
    text=text\gsub("{([^\\}]-)}","{"..formatText("%1",1).."}")

    -- Tags
    tags = text\match("{\\[^}]-}")
    text = tagColorizer(text) if tags

    -- Shape
    if highlightCoodinate and text\match "\\p(%d+)"
      for shape in text\gmatch "}(m [^{]+)"
        text = text\gsub escLuaExp(shape), contours(shape)

    -- Brackets
    text = text\gsub "[{}]", formatText("%1",3)

    -- Line Breaks
    text = text\gsub "\\N", formatText("\\N", 1)

    output ..= lineType..layer..","..startTime..","..endTime..","..style..","..actor..","..margin_left..","..margin_right..","..margin_vertical..","..effect..","..text.."\n"
  output ..= "```"
  aegisub.log output

aegisub.register_macro(script_name, script_description, main)
