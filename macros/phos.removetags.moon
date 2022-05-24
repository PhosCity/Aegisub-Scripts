export script_name = "#BETA# Remove Tags"
export script_description = "Dynamically remove tags based on selection"
export script_author = "PhosCity"
export script_namespace = "phos.removetags"
export script_version = "0.0.2"

DependencyControl = require "l0.DependencyControl"
depCtrl = DependencyControl{
    feed: "",
    {
        {"lyger.LibLyger", version: "2.0.0", url: "http://github.com/TypesettingTools/lyger-Aegisub-Scripts"},
    }
}
LibLyger = depCtrl\requireModules!

collect_tags = (subs, sel) ->
	tag_table = {}

	for i in *sel
		line = subs[i]
		for tagname in line.text\gmatch("\\([1-4]?[a-z]+)[^\\{}]*")
			if tag_table[tagname] == nil then
				tag_table[tagname] = 1
				table.insert tag_table,tagname

	if #tag_table == 0
		aegisub.log "No tags found in the selected line."
		aegisub.cancel!
	else
		return tag_table

sort_tags = (tag_table) ->
	sort_order ={"r", "an", "q", "pos", "move", "org", "fad", "fade", "blur", "be", "bord", "xbord", "ybord", "shad", "xshad", "yshad", "fscx", "fscy", "frx", "fry", "frz", "fax", "fay", "fn", "fs", "fsp", "c", "1c", "2c", "3c", "4c", "alpha", "1a", "2a", "3a", "4a", "clip", "iclip", "b", "i", "u", "s", "p", "k", "kf", "K", "ko", "t"}
	sorted_tags = [tag for tag in *sort_order when tag_table[tag] != nil]
	return sorted_tags

create_gui = (tag_table) ->
	dialog = {
		{x:0, y:0, class: "checkbox", width:1, height:1, label: "Start tags", name: "start", hint: "Remove from start tags only" },
		{x:1, y:0, class: "checkbox", width:1, height:1, label: "Inline tags", name: "inline", hint: "Remove from inline tags only" },
		{x:2, y:0, class: "checkbox", width:1, height:1, label: "Transform", name: "transform", hint: "Remove from transform only" },
	}

	-- Determine the number of columns in gui
	column = math.max math.ceil(math.sqrt #tag_table), 3

	-- Dynamically create gui
	count = 0
	for i = 1, column
		for j = 0, column-1
			count += 1
			if count <= #tag_table
				dialog[#dialog+1] = { label: tag_table[count], class: "checkbox",  x: j, y: i, width: 1,  height: 1  , name: tag_table[count], }
	
	return dialog

remove_tags = (subs, sel, tags_to_delete, res) ->
	for i in *sel
		line = subs[i]
		if res.start
			start_tags = line.text\match "^{>?\\[^}]-}"
			line.text = line.text\gsub LibLyger.esc(start_tags), ""
			start_tags = LibLyger.line_exclude start_tags, tags_to_delete
			line.text  = start_tags .. line.text
		elseif res.inline
			start_tags = line.text\match "^{>?\\[^}]-}"
			line.text = line.text\gsub LibLyger.esc(start_tags), ""
			line.text = LibLyger.line_exclude line.text, tags_to_delete
			line.text = start_tags .. line.text
		elseif res.transform
			line.text = LibLyger.time_exclude line.text, tags_to_delete
		else
			line.text = LibLyger.line_exclude line.text, tags_to_delete

		-- Some cleanup after deleting tags
		line.text = line.text\gsub("\\t%([%-%.%d,]*%)", "")\gsub("{}", "")
		subs[i] = line

remove_all_tags = (subs, sel) ->
	for i in *sel
		line = subs[i]
		line.text = line.text\gsub("{[*>]?\\[^}]-}","")
		subs[i] = line

main = (subs, sel) ->
	tag_table = collect_tags subs, sel
	sorted_tags = sort_tags tag_table
	GUI = create_gui sorted_tags
	buttons = {"Apply", "Cancel", "Remove All"}
	btn, res = aegisub.dialog.display GUI, buttons
	if btn == "Cancel"
		aegisub.cancel!
	elseif btn == "Apply"
		tags_to_delete = [tag for tag in *tag_table when res[tag]]
		remove_tags subs, sel, tags_to_delete, res
	else
		remove_all_tags subs, sel


depCtrl\registerMacro main
