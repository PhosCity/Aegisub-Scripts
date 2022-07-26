export script_name = "Rotate Gradient"
export script_description = "Create rotated gradient with clip."
export script_author = "PhosCity"
export script_namespace = "phos.RotateGradient"
export script_version = "1.0.1"

-- How to use: https://github.com/PhosCity/Aegisub-Scripts/#rotated-gradient
DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
  feed: "",
  {
    {"l0.Functional", version: "0.3.0", url: "https://github.com/TypesettingTools/Functional",
     feed: "https://raw.githubusercontent.com/TypesettingTools/Functional/master/DependencyControl.json"},
    {"SubInspector.Inspector", version: "0.6.0", url: "https://github.com/TypesettingTools/SubInspector",
    feed: "https://raw.githubusercontent.com/TypesettingTools/SubInspector/master/DependencyControl.json",
    optional: true},
    "karaskel",
  }
}
Functional, SubInspector = depctrl\requireModules!
import list, util from Functional

debug = false

-- tag list, grouped by dialog layout
tags_grouped = {
    {"c", "3c", "4c"},
    {"alpha", "1a", "2a", "3a", "4a"},
    {"bord", "xbord", "ybord"},
    {"shad", "xshad", "yshad"},
    {"blur", "be"},
}
tags_flat = list.join unpack tags_grouped

-- If the line does not have a tag in line, it either takes the style value or the default value as assigned below
default_tag_value = {
	c: "style", "3c": "style", "4c": "style",
  alpha: "&H00&", "1a": "style", "2a": "style", "3a": "style", "4a": "style",
	bord: "style", shad: "style",
  xbord: 0, ybord:  0, xshad: 0, yshad: 0,
	blur: 0, be: 0,
  }

-- Dialog Creator (Nicked from Gradient Everything)
create_dialog = () ->
  dlg = {
    -- define pixels per strip
    { x: 0, y: 0, width: 2, height: 1, class: "label", label:"Pixels per strip: "},
    { x: 2, y: 0, width: 2, height: 1, class: "intedit", name: "strip", min: 1, value: 1, step: 1 },
    -- Acceleration
    { x: 0, y: 6, width: 2, height: 1, class: "label", label: "Acceleration: " },
    { x: 2, y: 6, width: 2, height: 1, class:"floatedit", name: "accel", value: 1, hint: "1 means no acceleration, >1 starts slow and ends fast, <1 starts fast and ends slow" },
  }
  -- generate tag checkboxes
  for y, group in ipairs tags_grouped
    dlg[#dlg+1] = { name: tag, class: "checkbox", x: x-1, y: y, width: 1, height: 1, label: "\\#{tag}", value: false } for x, tag in ipairs group

  btn, res = aegisub.dialog.display dlg, {"OK", "Cancel"}, {"ok": "OK", "cancel": "Cancel"}
  return res if btn else aegisub.cancel!


-- Round a number to specified number of decimal places
round = (num, numDecimalPlaces) ->
  mult = 10^(numDecimalPlaces or 0)
  rnd = math.floor(num * mult + 0.5) / mult
  return rnd


-- Show debug messages
debug_msg = (msg) ->
  aegisub.log msg.."\n"	if debug


-- The script runs only if 2 lines are selected
-- TODO: Maybe in the future, the script will support multi-stop gradient and this becomes unnecessary
validate = (sub, sel) -> #sel==2


-- Check if a table contains an item
table_contains = (tbl, x) ->
	for item in *tbl
		return true if item == x
	return false


-- For 3 points, determine the point of intersection of line passing through first 2 points and a line perpendicular to it passing through 3rd point
intersect_perpendicular = (x1, y1, x2, y2, x3, y3) ->
  k = ((x3 - x1) * (x2 - x1) + (y3 - y1) * (y2 - y1)) / ((x2 - x1)^2 + (y2 - y1)^2)
  x = x1 + k * (x2 - x1)
  y = y1 + k * (y2 - y1)
  return x, y


-- Divides a line between 2 points in equal interval (user defined pixels in this case)
divide = (x1, y1, x2, y2, pixel)->
  pixel = 1 unless pixel
  distance = math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
  no_of_section = math.ceil(distance / pixel)
  points = {}
  for i = 0, no_of_section
    k = i / no_of_section
    x = x1 + k * (x2 - x1)
    y = y1 + k * (y2 - y1)
    points[i] or= {}
    points[i]["x"] = x
    points[i]["y"] = y
  return points


-- For the particular tag, get the value of that tag either from the style, inline tags or default value
tag_lookup = (subs, line, tag) ->
  meta, styles = karaskel.collect_head(subs, false)
  karaskel.preproc_line(subs, meta, styles, line)
  tag_value = line.text\match "\\#{tag}([^\\}]+)"
  tag_value = line.text\match "\\c(&H%x+&)" if tag == "c"     -- \\c interferes with \\clip
  if not tag_value
    if default_tag_value[tag] == "style"
      tag_value = switch tag
        when "c" then util.color_from_style(line.styleref.color1)
        when "3c" then util.color_from_style(line.styleref.color3)
        when "4c" then util.color_from_style(line.styleref.color4)
        when "1a" then util.alpha_from_style(line.styleref.color1)
        when "3a" then util.alpha_from_style(line.styleref.color3)
        when "4a" then util.alpha_from_style(line.styleref.color4)
        when "bord" then line.styleref.outline
        when "shad" then line.styleref.shadow
    else
      tag_value = default_tag_value[tag]
  return tag_value


-- Gets clip, tag values etc that are required for further processing
prepare_line = (subs, sel, res) ->
  text, tag_state = nil, {}
  for index, item in ipairs sel
    line = subs[item]
    stripped_text = line.text\gsub "{\\[^}]+}", ""
    if index == 1
      text = stripped_text
      for tag in *tags_flat
        if res[tag]
          tag_state["start"] or= {}
          tag_state["start"][tag] = tag_lookup(subs, line, tag)
    elseif index == 2
      if text != stripped_text
        aegisub.log "You have selected lines that does not have same text. Exiting."
        aegisub.cancel!
      for tag in *tags_flat
        if res[tag]
          tag_state["end"] or= {}
          tag_state["end"][tag] = tag_lookup(subs, line, tag)
      if line.text\match "\\clip%(m [%d%.%-]+ [%d%.%-]+ l [%d%.%-]+ [%d%.%-]+ [%d%.%-]+ [%d%.%-]+%)"
        x1, y1, x2, y2, x3, y3 = line.text\match "\\clip%(m ([%d%.%-]+) ([%d%.%-]+) l ([%d%.%-]+) ([%d%.%-]+) ([%d%.%-]+) ([%d%.%-]+)%)"
        return x1, y1, x2, y2, x3, y3, tag_state

  aegisub.log "No clip found in the seleceted lines. Exiting"
  aegisub.cancel!


-- This is used at first to determine the boudning box of the original text
-- and then later to find invisible lines due to adding rotated clips.
-- It amounts to most of the slowness of the script and probably is not how you should use SubInspector
bounding_box = (subs, line) ->
  lines = {}
  lines[1] = line
  assi, _ = SubInspector subs
  bounds, times = assi\getBounds lines
  bounding, invisible = {}, true
  for i = 1, #times
    b = bounds[i]
    if b != false
      bounding["left"] = b.x - 3
      bounding["right"] = b.w + b.x + 3
      bounding["top"] = b.y - 3
      bounding["bottom"] = b.y + b.h + 3
      invisible = false
  return bounding, invisible


-- Determines the left and right point of a clip for each division of line
clipCreator = (points, bounds, slope) ->
  x_left = bounds["left"]
  x_right = bounds["right"]
  clip = {}
  for i = 0, #points
    intercept = points[i]["y"] - slope * points[i]["x"]
    y_left = slope * x_left + intercept
    y_right = slope * x_right + intercept
    clip[i] = clip[i] or {}
    clip[i]["x_left"] = round(x_left, 3)
    clip[i]["x_right"] = round(x_right, 3)
    clip[i]["y_left"] = round(y_left, 3)
    clip[i]["y_right"] = round(y_right, 3)
  return clip


-- Actual gradienting happens here. It removes all the lines where clip outside the line causes it to be invisible and then gradients the tags
tagGradient = (subs, new_sel, tagState, res) ->
  invisible_line_to_delete = {}
  for index, item in ipairs new_sel
    _, invisible = bounding_box(subs, subs[item])
    if invisible
      table.insert(invisible_line_to_delete, item)
  count = 0
  for i in *new_sel
    continue if table_contains(invisible_line_to_delete, i)
    line = subs[i]
    count += 1
    factor = (count - 1) ^ res.accel / (#new_sel - #invisible_line_to_delete - 1) ^ res.accel
    start_tag = line.text\match "^{\\[^}]+}"
    text = line.text\gsub "^{\\[^}]+}", ""
    for tag in *tags_flat
      if res[tag]
        start_tag = start_tag\gsub("\\#{tag}[^\\}]+", "") unless tag == "c"
        start_tag = start_tag\gsub("\\c&H%x+&", "") if tag == "c"
        local new_value
        if tag == "c" or tag =="3c" or tag =="4c"
          new_value = util.interpolate_color(factor, tagState["start"][tag], tagState["end"][tag])
        elseif tag == "alpha" or tag == "1a" or tag == "3a" or tag =="4a"
          new_value = util.interpolate_alpha(factor, tagState["start"][tag], tagState["end"][tag])
        else
          new_value = util.interpolate(factor, tagState["start"][tag], tagState["end"][tag])
          new_value = round(new_value, 3)
        start_tag = start_tag\gsub("}", "\\#{tag}#{new_value}}")
    line.text = start_tag..text
    subs[i] = line
  subs.delete(invisible_line_to_delete)


-- Adds the rotated clips to the line
addClip = (subs, sel, og_line, klip, gradientDirection, points) ->
  new_sel = {}
  for i = 1, #points
    -- Determine four corners of the clip
    top_left_x = klip[i-1]["x_left"]
    top_left_y = klip[i-1]["y_left"]
    top_right_x = klip[i-1]["x_right"]
    top_right_y = klip[i-1]["y_right"]
    bottom_left_x = klip[i]["x_left"]
    bottom_left_y = klip[i]["y_left"]
    bottom_right_x = klip[i]["x_right"]
    bottom_right_y = klip[i]["y_right"]

    -- Create overlap in the clip
    if gradientDirection == "up"          -- 3rd point up
      bottom_left_y -= 0.75
      bottom_right_y -= 0.75
    elseif gradientDirection == "down"    --3rd point down
      top_left_y -= 0.75
      top_right_y -= 0.75

    -- Add clip to the line
    line = og_line
    clip = "\\clip(m #{top_left_x} #{top_left_y} l #{top_right_x} #{top_right_y} #{bottom_right_x} #{bottom_right_y} #{bottom_left_x} #{bottom_left_y})"
    tags = line.text\match "^{\\[^}]+}"
    text = line.text\gsub "^{\\[^}]+}", ""
    tags = "{}" unless tags
    tags = tags\gsub("\\i?clip%([^)]*%)", "")\gsub("}", "#{clip}}")
    line.text = tags..text
    line.comment = false
    new_index = sel[#sel]+i
    subs.insert(new_index, line)
    table.insert(new_sel, new_index)
  return new_sel


-- Main function
main = (subs, sel) ->
  res = create_dialog!
  bounding, _ = bounding_box(subs, subs[sel[1]])
  x1, y1, x2, y2, x3, y3, tagState = prepare_line(subs, sel, res)
  debug_msg("x1 : "..x1)
  debug_msg("y1 : "..y1)
  debug_msg("x2 : "..x2)
  debug_msg("y2 : "..y2)
  debug_msg("x3 : "..x3)
  debug_msg("y3 : "..y3)

  x, y = intersect_perpendicular(x1, y1, x2, y2, x3, y3)
  local gradientDirection
  if tonumber(y) < tonumber(y3)
    gradientDirection = "down"
  else
    gradientDirection = "up"
  debug_msg("Gradeint Direction: "..gradientDirection)
  points = divide(x, y, x3, y3 , res.strip)

  slope = (y2-y1)/(x2-x1)
  klip = clipCreator(points, bounding, slope)
  og_line= {}
  for index, i in ipairs sel
    line = subs[i]
    og_line = line if index == 1
    line.comment = true
    subs[i] = line

  new_sel = addClip(subs, sel, og_line, klip, gradientDirection, points)
  tagGradient(subs, new_sel, tagState, res)

depctrl\registerMacro(main, validate)
