export script_name = "Extrapolate Tracking"
export script_description = "Extrapolate the tag values where mocha can't reach"
export script_author = "PhosCity"
export script_namespace = "phos.ExtrapolateTracking"
export script_version = "1.0.1"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
  feed: "",
  {
    {"l0.Functional", version: "0.3.0", url: "https://github.com/TypesettingTools/Functional",
     feed: "https://raw.githubusercontent.com/TypesettingTools/Functional/master/DependencyControl.json"},
  }
}
Functional = depctrl\requireModules!
import list, util from Functional


logg = (msg, exit_with_msg = false) ->
  msg = "{#{table.concat msg, ", "}}" if type(msg) == "table"
  aegisub.log tostring(msg).."\n"
  aegisub.cancel! if exit_with_msg


alpha_hex2number = (alpha) ->
  alpha = alpha\gsub("[&H]", "")
  tonumber(alpha, 16)


round = (num, numDecimalPlaces) ->
  mult = 10^(numDecimalPlaces or 0)
  math.floor(num * mult + 0.5) / mult


main = (subs, sel) ->
  -- Initiate some variables
  tagValue, unextrapolatableTags, commonDifference, add_lines = {}, {}, {}, false
  noOfProcessedLines = #sel
  tagsList =  {
    "blur", "be", "bord", "xbord", "ybord",
    "shad", "xshad", "yshad",
    "fscx", "fscy", "fs",
    "frx", "fry", "frz",
    "fax", "fay",
    "pos", "org",
    "alpha", "1a", "3a", "4a"
  }

  line1 = subs[sel[1]]
  line2 = subs[sel[#sel]]
  e1 = line1.effect
  e2 = line2.effect
  marker = "x,[%d]+"

  if e1 !='x' and e2 !='x' and not e1\match(marker) and not e2\match(marker) 
    logg "The first OR last line of the selection must have a marker in Effect.
There are 2 types of markers.
You can mark lines at beginning or end with 'x' so that tags in those lines will be extrapolated.
You can also mark the first or last line with 'x,n' so that the script will add 'n' lines at beginning or end with extrapolated tags.", true

  if e1 =='x' and e2 =='x' or e1\match(marker) and e2\match(marker) or e1 == "x" and e2\match(marker) or e1\match(marker) and e2 == "x"
    logg "You can only either extrapolate the beginning or end at any given time."

  if e1\match(marker) or e2\match(marker)
    add_lines = true
  else
    for i in *sel
      noOfProcessedLines -= 1 if subs[i].effect == "x"
  fadein = true if e1\match(marker) or e1 == "x"
  sel = list.reverse sel if fadein

  -- Insert new lines if user asks to
  if add_lines
    lineNo = sel[#sel]
    newLine = subs[lineNo]
    count = tonumber(newLine.effect\match "x,([%d]+)")
    startFrame = aegisub.frame_from_ms newLine.start_time
    endFrame = aegisub.frame_from_ms newLine.end_time
    newLine.effect = "x"
    if fadein
      for i = 1, count
        newLine.start_time = aegisub.ms_from_frame(startFrame-i)
        newLine.end_time = aegisub.ms_from_frame(endFrame-i)
        if newLine.start_time < 0
          logg "Going back #{count} frames from first selected line causes negative time. Exiting.", true
        else
          subs.insert(lineNo, newLine)
    else
      for i = 1, count
        newLine.start_time = aegisub.ms_from_frame(startFrame+i)
        newLine.end_time = aegisub.ms_from_frame(endFrame+i)
        subs.insert(lineNo + i, newLine)

    -- update selection to include newly added lines
    for i = 1, count
      if fadein
        table.insert sel, 1, sel[1]+1
      else
        table.insert sel, sel[#sel]+1

  -- Find the start and end value of each tags
  for index, i in ipairs sel
    line = subs[i]
    break if line.effect == "x"
    startTags = line.text\match("^{\\[^}]+}") or ""
    startTags = startTags\gsub "\\t%b()", ""
    for tag in *tagsList
      value = startTags\match "\\#{tag}([^\\}]+)"
      value = startTags\match "\\fs(%d*)" if tag == "fs"     -- fs interferes with fscx and fscy
      if value and value != ""
        tagValue[tag] or= {}
        if index == 1
          tagValue[tag]["start"] = value
        else
          tagValue[tag]["end"] = value
      else
        table.insert unextrapolatableTags, tag

  -- Find tags that can be extrapolated
  unextrapolatableTags = list.uniq unextrapolatableTags
  extrapolatableTags = list.diff tagsList, unextrapolatableTags
  if #extrapolatableTags == 0
    logg "Tags that can be extrapolated could not be found in the selection.", true

  -- Calculate the common difference for each extrapolable tags
  for tag in *extrapolatableTags
    if tag == "pos" or tag == "org"
      x_start, y_start = tagValue[tag]["start"]\match("%((.-),(.-)%)")
      x_end, y_end = tagValue[tag]["end"]\match("%((.-),(.-)%)")
      x_common = (x_end - x_start) / (noOfProcessedLines - 1)
      y_common = (y_end - y_start) / (noOfProcessedLines - 1)
      commonDifference[tag] = "(#{x_common},#{y_common})"
    elseif tag == "alpha" or tag == "1a" or tag == "3a" or tag == "4a"
      alpha_start = alpha_hex2number tagValue[tag]["start"]
      alpha_end = alpha_hex2number tagValue[tag]["end"]
      commonDifference[tag] = (alpha_end - alpha_start) / (noOfProcessedLines - 1)
    else
      commonDifference[tag] = (tagValue[tag]["end"] - tagValue[tag]["start"]) / (noOfProcessedLines - 1)

  -- Create a dialog with extrapolable tags.
  dlg = {{x: 0, y: 0, class: "checkbox", label: "All Tags", width: 1, height: 1, name: "all", value: true}}
  column = math.ceil(math.sqrt #extrapolatableTags)-1           -- Determine the number of columns in gui
  count = 0
  for y = 1, (column+1)
    for x = 0, column
      count += 1
      if count <= #extrapolatableTags
        dlg[#dlg+1] = {x: x, y: y, class: "checkbox", label: extrapolatableTags[count], width: 1, height: 1, name: extrapolatableTags[count] }

  btn, res = aegisub.dialog.display dlg
  aegisub.cancel! unless btn

  -- Acutal extrapolation happens here
  c = 0
  for index, i in ipairs sel
    line = subs[i]
    continue unless line.effect == "x"
    c += 1
    text = line.text\gsub "^{\\[^}]+}", ""
    startTags = line.text\match "^{\\[^}]+}"
    startTags = startTags\gsub("\\t%b()", (tr) -> tr\gsub("\\", "||")\gsub("^||", "\\"))           -- Deactivate the tags inside transform for now
    for tag in *extrapolatableTags
      originalValue = tagValue[tag]["end"]
      difference = commonDifference[tag]
      local value
      if tag == "pos" or tag == "org"
        pos_x, pos_y = originalValue\match "%((.-),(.-)%)"
        x_diff, y_diff = difference\match "%((.-),(.-)%)"
        new_pos_x = round(pos_x + x_diff * c, 3)
        new_pos_y = round(pos_y + y_diff * c, 3)
        value = "(#{new_pos_x},#{new_pos_y})"
      elseif tag == "alpha" or tag == "1a" or tag == "3a" or tag == "4a"
        alpha = alpha_hex2number originalValue
        new_alpha = alpha + difference * c
        new_alpha = 255 if new_alpha > 255
        new_alpha = 0 if new_alpha < 0
        value = util.ass_alpha new_alpha
      else
        value = round(originalValue + difference * c, 3)
      if res[tag] or res["all"]
        startTags = switch tag
          when "fs" then startTags\gsub "\\fs[%d%.]+", "\\#{tag}#{value}"
          else startTags\gsub "\\#{tag}[^\\}]+", "\\#{tag}#{value}"

    startTags = startTags\gsub "||", "\\"                                                           -- Reactivate the transform tags
    line.text = startTags..text
    subs[i] = line


depctrl\registerMacro(main)
