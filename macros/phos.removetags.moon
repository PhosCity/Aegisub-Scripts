export script_name = "#BETA# Remove Tags"
export script_description = "Dynamically remove tags based on selection"
export script_author = "PhosCity"
export script_namespace = "phos.removetags"
export script_version = "0.0.1"

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
		for tagname in line.text\gmatch("\\([1-4]?%a+)[^\\{}]*") do
			if tag_table[tagname] == nil then
				tag_table[tagname] = 1
				table.insert tag_table,tagname

	if #tag_table == 0
		aegisub.log "No tags found in the selected line."
		aegisub.cancel!
	else
		return tag_table

sort_tags = (tag_table) ->
	sort_order ={"r", "an", "q", "pos", "move", "org", "fad", "fade", "blur", "be", "bord", "xbord", "ybord", "shad", "xshad", "yshad", "fscx", "fscy", "frx", "fry", "frz", "fax", "fay", "fn", "fs", "fsp", "1c", "2c", "3c", "4c", "alpha", "1a", "2a", "3a", "4a", "clip", "iclip", "b", "i", "u", "s", "p", "k", "kf", "K", "ko", "t"}
	sorted_tags = {}
	for _, tag in ipairs sort_order
		if tag_table[tag] ~= nil
			table.insert sorted_tags, tag
	return sorted_tags

create_gui = (tag_table) ->
	dialog = {}

	-- Determine the number of columns in gui
	column = math.ceil(math.sqrt #tag_table)-1

	-- Dynamically create gui
	count = 0
	for i = 0, column
		for j = 0, (column-1)
			count += 1
			if count <= #tag_table
				dialog[#dialog+1] = { label: tag_table[count], class: "checkbox",  x: j, y: i, width: 1,  height: 1  , name: tag_table[count], }
	
	return dialog

remove_tags = (subs, sel, tags_to_delete) ->
	for i in *sel
		line = subs[i]
		line.text = LibLyger.line_exclude line.text, tags_to_delete
		subs[i] = line


main = (subs, sel) ->
	tag_table = collect_tags subs, sel
	sorted_tags = sort_tags tag_table
	GUI = create_gui sorted_tags
	btn, res = aegisub.dialog.display GUI
	-- tags_to_delete = { k,tag for k, tag in ipairs tag_table when res[tag]}
	tags_to_delete = {}
	for k, v in ipairs tag_table
		if res[v] then
			table.insert tags_to_delete, v

	if btn
		remove_tags subs, sel, tags_to_delete

depCtrl\registerMacro main
