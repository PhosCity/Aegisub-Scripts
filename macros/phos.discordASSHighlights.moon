export script_name = "Discord ASS Highlight"
export script_description = "Copy line to discord with highlights"
export script_version = "0.0.3"
export script_author = "PhosCity"
export script_namespace = "phos.DiscordASSHighlight"

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
    die "Value too large to create an ASS timecode" if h > 9
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
    [8]: "30m"      -- dark gray
  }

  str = "\27["
  str ..= formatCodes[format]..";" if format
  str ..= colorCodes[color] .. text .. "\27[".. colorCodes[0]
  str


contours = (shape) ->
  local shapeType, splitShape, splitCount
  if shape\match "[%-%d%.]+,"
    splitShape, splitCount = split shape, ","
    shapeType = "rect"
  else
    splitShape, splitCount = split shape, "%s+", nil, false

  local drawingCmd
  finalString, bezierCount, count = "", 0, 1
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


tagColorizer = (text, highlightCoodinate) ->

  tag = {"alpha", "1a", "3a", "4a",
    "fscx", "fscy",
    "fsp", "fs", "fn",
    "fax", "frx", "fry", "frz",
    "bord", "xbord", "ybord",
    "shad", "xshad", "yshad",
    "blur", "be",
    "an", "q",
    "fade", "fad",
    "pos", "move", "org"
    "1c", "c", "3c", "4c",
    "i", "b", "u", "s", "t", "p"
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

main = (highlightCoodinate = false, copyHeaders = true) ->
  (subs, sel) ->
    output = "```ansi\n"
    for i in *sel
      continue unless subs[i].class == "dialogue"
      line = subs[i]

      if copyHeaders
        lineType = line.comment and "Comment:" or "Dialogue:"
        lineType = formatText(lineType,4)

        layer = formatText(line.layer,1)

        startTime = ms2AssTimecode line.start_time
        startTime = formatText(startTime,3)

        endTime = ms2AssTimecode line.end_time
        endTime = formatText(endTime,3)

        style = formatText(line.style,2)

        actor = formatText(line.actor,2)

        margin_left = formatText(line.margin_l,1)
        margin_right = formatText(line.margin_r,1)
        margin_vertical = formatText(line.margin_t,1)

        effect = formatText(line.effect,2)
        output ..= "#{lineType} #{layer},#{startTime},#{endTime},#{style},#{actor},#{margin_left},#{margin_right},#{margin_vertical},#{effect},"

      text = line.text

      -- Comments
      text=text\gsub("{([^\\}]-)}","{"..formatText("%1",8).."}")

      -- Shape
      if highlightCoodinate and text\match "\\p(%d+)"
        for shape in text\gmatch "}(m [^{]+)"
          text = text\gsub escLuaExp(shape), contours(shape)

      -- Tags
      text = tagColorizer(text, highlightCoodinate) if text\match("{\\[^}]-}")

      -- Brackets
      text = text\gsub "[{}]", formatText("%1",3)

      -- Line Breaks
      text = text\gsub "\\N", formatText("\\N", 1)

      output ..= text.."\n"
    output ..= "```"
    aegisub.log output

aegisub.register_macro(script_name.."/Copy line", script_description, main nil)
aegisub.register_macro(script_name.."/Copy line with shape highlights", script_description, main true)
aegisub.register_macro(script_name.."/Copy line without headers", script_description, main nil, false)
aegisub.register_macro(script_name.."/Copy line without headers with shape highlights", script_description, main true, false)
