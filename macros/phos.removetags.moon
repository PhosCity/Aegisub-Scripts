export script_name = "Remove Tags"
export script_description = "Dynamically remove tags based on selection"
export script_author = "PhosCity"
export script_namespace = "phos.removetags"
export script_version = "1.0.0"

DependencyControl = require "l0.DependencyControl"
depCtrl = DependencyControl{
    {
        {"lyger.LibLyger", version: "2.0.0", url: "http://github.com/TypesettingTools/lyger-Aegisub-Scripts"},
    }
}
LibLyger = depCtrl\requireModules!

tags_color = {"c", "1c", "2c", "3c", "4c"}
tags_alphas = {"alpha", "1a", "2a", "3a", "4a"}
tags_rotation = {"frz", "frx", "fry"}
tags_scale = {"fs", "fscx", "fscy"}
tags_perspective = {"frz", "frx", "fry", "fax", "fay", "org"}
buttons = {}

table_contains = (tbl, x) ->
	for item in *tbl
		return true if item == x
	return false

cleanup = (line) -> line\gsub("\\t%([%-%.%d,]*%)", "")\gsub("{[*]?}", "")

collect_tags = (subs, sel) ->
	tag_table = {}
	remove_groups = { color: false, alphas: false, rotation: false, scale: false, perspective: false, inline_except_last: false }

	for i in *sel
		line = subs[i]

		_, tag_section = line.text\gsub "{[*>]?\\[^}]-}", ""
		if tag_section > 2 remove_groups["inline_except_last"] = true

		for tagname in line.text\gmatch("\\([1-4]?[a-z]+)[^\\{}]*")
			if tag_table[tagname] == nil then
				tag_table[tagname] = 1
				table.insert tag_table,tagname
				if table_contains tags_color, tagname then remove_groups["color"] = true
				if table_contains tags_alphas, tagname then remove_groups["alphas"] = true
				if table_contains tags_rotation, tagname then remove_groups["rotation"] = true
				if table_contains tags_scale, tagname then remove_groups["scale"] = true
				if table_contains tags_perspective, tagname then remove_groups["perspective"] = true

	if #tag_table == 0
		aegisub.log "No tags found in the selected line."
		aegisub.cancel!
	else
		return tag_table, remove_groups

sort_tags = (tag_table) ->
	sort_order ={"r", "an", "q", "pos", "move", "org", "fad", "fade", "blur", "be", "bord", "xbord", "ybord", "shad", "xshad", "yshad", "fscx", "fscy", "frx", "fry", "frz", "fax", "fay", "fn", "fs", "fsp", "c", "1c", "2c", "3c", "4c", "alpha", "1a", "2a", "3a", "4a", "clip", "iclip", "b", "i", "u", "s", "p", "k", "kf", "K", "ko", "t"}
	sorted_tags = [tag for tag in *sort_order when tag_table[tag] != nil]
	return sorted_tags

create_gui = (tag_table, remove_groups) ->
	dialog = {}
	-- Left portion of GUI
	count = 0
	for k, v in pairs remove_groups
		label = k\gsub("^", "Remove all ")\gsub("_", " ")
		hint = ""
		if v == true
			switch k
				when "color" then hint = table.concat(tags_color, ",")
				when "alphas" then hint = table.concat(tags_alphas, ",")
				when "rotation" then hint = table.concat(tags_rotation, ",")
				when "scale" then hint = table.concat(tags_scale, ",")
				when "perspective" then hint = table.concat(tags_perspective, ",")
			dialog[#dialog+1]= {x:0, y: count, class: "checkbox", label: label, name: k, hint: hint}
			count += 1
			table.insert buttons, 1, "Run Selected" unless table_contains buttons, "Run Selected"

	-- Right portion of GUI
	start_x = 0
	if count > 0 then start_x = 1
	dialog[#dialog+1] = {x: start_x, y:0, class: "checkbox", label: "Start tags", name: "start", hint: "Remove from start tags only"}
	dialog[#dialog+1] = {x: start_x + 1, y:0, class: "checkbox", label: "Inline tags", name: "inline", hint: "Remove from inline tags only"}
	dialog[#dialog+1] = {x: start_x + 2, y:0, class: "checkbox", label: "Transform", name: "transform", hint: "Remove from transform only"}
	dialog[#dialog+1] = {x: start_x + 3, y:0, class: "checkbox", label: "Invert", name: "invert", hint: "Remove all except selected"}

	-- Determine the number of columns in gui
	column = math.max math.ceil(math.sqrt #tag_table), 4

	-- Dynamically create gui
	count = 0
	for i = 1, column
		for j = start_x, column+start_x-1
			count += 1
			if count <= #tag_table
				dialog[#dialog+1] = {x: j, y: i, class: "checkbox", label: tag_table[count], name: tag_table[count]}
	
	return dialog

remove_tags = (subs, sel, tags_to_delete, res) ->
	delete = LibLyger.line_exclude
	if res["invert"] then delete = LibLyger.line_exclude_except
	for i in *sel
		line = subs[i]
		if res.start
			start_tags = line.text\match "^{>?\\[^}]-}"
			line.text = line.text\gsub LibLyger.esc(start_tags), ""
			start_tags = delete start_tags, tags_to_delete
			line.text  = start_tags .. line.text
		elseif res.inline
			start_tags = line.text\match "^{>?\\[^}]-}"
			line.text = line.text\gsub LibLyger.esc(start_tags), ""
			line.text = delete line.text, tags_to_delete
			line.text = start_tags .. line.text
		elseif res.transform
			line.text = LibLyger.time_exclude line.text, tags_to_delete
		else
			line.text = delete line.text, tags_to_delete
		line.text = cleanup(line.text)
		subs[i] = line

remove_all_tags = (subs, sel, res) ->
	for i in *sel
		line = subs[i]
		if res.start
			line.text = line.text\gsub "^{>?\\[^}]-}", ""
		elseif res.inline
			start_tags = line.text\match "^{>?\\[^}]-}"
			line.text = line.text\gsub("{[*>]?\\[^}]-}","")
			line.text = start_tags .. line.text
		else
			line.text = line.text\gsub("{[*>]?\\[^}]-}","")
		subs[i] = line

run_selected = (subs, sel, res) ->
	for i in *sel
		line = subs[i]
		if res["color"]
			line.text = LibLyger.line_exclude line.text, tags_color
		if res["alphas"]
			line.text = LibLyger.line_exclude line.text, tags_alphas
		if res["rotation"]
			line.text = LibLyger.line_exclude line.text, tags_rotation
		if res["scale"]
			line.text = LibLyger.line_exclude line.text, tags_scale
		if res["perspective"]
			line.text = LibLyger.line_exclude line.text, tags_perspective
		if res["inline_except_last"]
			r = math.huge
			while r != 0
				line.text, r = line.text\gsub "(.){[*>]?\\[^}]-}(.-{%*?\\)", "%1%2"
		line.text = cleanup(line.text)
		subs[i] = line

main = (subs, sel) ->
	buttons = {"Kill Tags", "Remove All", "Cancel"}
	tag_table, remove_groups = collect_tags subs, sel
	sorted_tags = sort_tags tag_table
	GUI = create_gui sorted_tags, remove_groups

	btn, res = aegisub.dialog.display GUI, buttons
	switch btn
		when "Cancel" then aegisub.cancel!
		when "Run Selected" then run_selected subs, sel, res
		when "Remove All" then remove_all_tags subs, sel, res
		when "Kill Tags"
			tags_to_delete = [tag for tag in *tag_table when res[tag]]
			remove_tags subs, sel, tags_to_delete, res


depCtrl\registerMacro main