export script_name = "#BETA# Edit tags"
export script_description = "Dynamically edit tags based on selection"
export script_author = "PhosCity"
export script_namespace = "phos.edittags"
export script_version = "0.0.3"

tagClass = {
	alpha: "dropdown", "1a": "dropdown", "2a": "dropdown", "3a": "dropdown", "4a": "dropdown",
	q: "dropdown",
	an: "dropdown",
	c: "color", "1c": "color", "2c": "color", "3c": "color", "4c": "color",
	blur: "floatedit",
	be: "floatedit",
	bord: "floatedit", xbord: "floatedit", ybord:  "floatedit",
	shad: "floatedit", xshad: "floatedit", yshad: "floatedit",
	fscx: "floatedit", fscy: "floatedit",
	frx: "floatedit", fry: "floatedit", frz: "floatedit",
	fax: "floatedit", fay: "floatedit",
	fs: "floatedit", fsp: "floatedit",
	i: "checkbox", b: "checkbox", u: "checkbox", s: "checkbox",
	pos: "coordinate", org: "coordinate",
	fad: "coordinate",
	fade: "complex",
	move: "complex",
	clip: "complex",
	iclip: "complex",
	fn: "edit",
	p: "edit",
	t: "transform",
	}

esc = (str) ->
	str = str\gsub "[%%%(%)%[%]%.%-%+%*%?%^%$]", "%%%1"
	return str

table_contains = (tbl, x) ->
	found = false
	for item in *tbl
		found = true if item == x
	return found

-- Deactivate the tags inside transform by changing \ to |
untransform = (line) ->
	for tr in line\gmatch "\\t%([^)]+%)"
		new_tr = tr\gsub("\\", "|")\gsub("|t", "\\t")
		line = line\gsub esc(tr), new_tr

	return line

-- Divides the line in a {tag}text section pair
collect_section = (subs, act) ->
	section = {}
	line = subs[act]

	line.text = untransform line.text

	for item in line.text\gmatch "{[^{}]*}[^{}]*"
		table.insert section, item

	if #section == 0
		aegisub.log "No tags found in the selection."
		aegisub.cancel!
	else
		return section

-- Takes in a {tag}text section and creates a table with key-value pair of tag and it's value
analyzeSection = (section) ->
	transform_count, tagTable = 0, {}
	text = section\gsub "^{%*?\\[^}]-}", ""
	tag = section\gsub esc(text), ""

	for tagname, tagvalue in tag\gmatch "\\([1-4]?[a-z]+)([^\\{}]*)"
		-- Since transform can appear multiple times in a same section, number it for later processing
		if tagname == "t"
			transform_count += 1
			tagname = tagname..transform_count

		table.insert tagTable, tagname
		tagTable[tagname] = tagvalue

	return tagTable, text

guiHelper = (dlg, row, column, tagname, tagvalue, section_count) ->
	klass = tagClass[tagname]
	klass = "edit" if not klass
	if klass == "dropdown"
		alphaitem = { "00", "10", "20", "30", "40", "50", "60", "70", "80", "90", "A0", "B0", "C0", "D0", "E0", "F0", "F8", "FF" }
		dropdownItems = switch tagname
			when "q" then { "0", "1", "2", "3" }
			when "an" then { "1", "2", "3", "4", "5", "6", "7", "8", "9" }
			when "alpha" then alphaitem
			when "1a" then alphaitem
			when "2a" then alphaitem
			when "3a" then alphaitem
			when "4a" then alphaitem

		if tagname == "alpha" or tagname == "1a" or tagname == "2a" or tagname == "3a" or tagname == "4a"
			tagvalue = tagvalue\gsub("[H&]", "")
			if not table_contains alphaitem, tagvalue
				table.insert alphaitem, tagvalue

		taglabel = tagname
		taglabel = "Alignment" if tagname == "an"


		dlg[#dlg+1] = { x: column, y:row, width: 1, class: "label", label: taglabel }
		column +=1
		dlg[#dlg+1] = { x: column, y:row, width: 1, class: "dropdown", items: dropdownItems, value: tagvalue, name: tagname..section_count }
		column +=1
	elseif klass == "color"
		lbl = switch tagname
			when "c" then "Primary"
                	when "1c" then "Primary"
                	when "2c" then "2c"
                	when "3c" then "Border"
                	when "4c" then "Shadow"

		dlg[#dlg+1] = { x: column, y:row, width: 1, class: "label", label: lbl }
		column +=1
		dlg[#dlg+1] = { x: column, y:row, width: 1, class: "color", name: tagname..section_count, value: tagvalue }
		column +=1
	elseif klass == "checkbox"
		tagvalue = switch tagvalue
			when "1" then true
			when "0" then false

		taglabel = switch tagname
			when "i" then "Italics"
			when "b" then "Bold"
			when "u" then "Underline"
			when "s" then "Strikeout"

		dlg[#dlg+1] = { x: column, y:row, width: 1, class: "checkbox", name: tagname..section_count, value: tagvalue, label: taglabel }
		column +=1
	elseif klass == "coordinate"
		first_item, second_item = tagvalue\match "%(([%d%.%-]+),([%d%.%-]+)%)"
		dlg[#dlg+1] = { x: column, y:row, width: 1, class: "label", label: tagname }
		column +=1
		dlg[#dlg+1] = { x: column, y:row, width: 1, class: "floatedit", name: tagname.."x"..section_count, value: first_item }
		column +=1
		dlg[#dlg+1] = { x: column, y:row, width: 1, class: "floatedit", name: tagname.."y"..section_count, value: second_item }
		column +=1
	elseif klass == "edit" or klass == "floatedit" or klass == "intedit"
		dlg[#dlg+1] = { x: column, y:row, width: 1, class: "label", label: tagname }
		column +=1
		dlg[#dlg+1] = { x: column, y:row, width: 1, class: klass, name: tagname..section_count, value: tagvalue }
		column +=1
	elseif klass == "complex"
		row += 1
		column = 0
		dlg[#dlg+1] = { x: column, y:row, width: 1, class: "label", label: tagname }
		column += 1
		dlg[#dlg+1] = { x: column, y:row, width: 10, class: "edit", name: tagname..section_count, value: tagvalue }
		row += 1
		column = 0

	return dlg, row, column

createGUI = (tagtextsection) ->
	row, column, column_limit, inline_count, transform_count, dlg, transformTable = 0, 0, 10, 0, 0, {}, {}
	for section_count, section in ipairs tagtextsection
		if section_count != 1
			row += 1
			column = 0
			if inline_count < 1
				dlg[#dlg+1] = { x: column, y:row, width: 1, class: "label", label: "Inline Tags:" }
				row += 1
				column = 0
				inline_count += 1

		tagTable, text = analyzeSection section, true

		dlg[#dlg+1] = { x: column, y:row, width: column_limit, class: "edit", value: text, name: "text"..section_count }
		row += 1

		for tag in *tagTable
			if column >= (column_limit-1) and tagClass[tag] != "complex"
				row += 1
				column = 0

			if tag\match "(t[%d]+)"
				table.insert transformTable, tagTable[tag]
			else
				dlg, row, column = guiHelper dlg, row, column, tag, tagTable[tag], section_count
			
	for index, item in ipairs transformTable
		row += 1
		column = 0
		if transform_count < 1
			dlg[#dlg+1] = { x: column, y:row, width: 1, class: "label", label: "Transform:" }
			row += 1
			column = 0
			transform_count += 1
		tag_start, tag_end = item\match "%(([%d.-]+),([%d.-]+)[^)]*%)"
		accel = item\match "%([%d.-]+,[%d.-]+,([%d.-]+)[^)]*%)"

		dlg[#dlg+1] = { x: column, y:row, width: 1, class: "label", label: index..". Start: " }
		column+=1
		dlg[#dlg+1] = { x: column, y:row, width: 1, class: "edit", value: tag_start, name: "trstart"..index }
		column+=1
		dlg[#dlg+1] = { x: column, y:row, width: 1, class: "label", label: "End: " }
		column+=1
		dlg[#dlg+1] = { x: column, y:row, width: 1, class: "edit", value: tag_end, name: "trend"..index }
		column+=1
		dlg[#dlg+1] = { x: column, y:row, width: 1, class: "label", label: "Accel: " }
		column +=1
		dlg[#dlg+1] = { x: column, y:row, width: 1, class: "edit", value: accel, name: "traccel"..index }
		row += 1
		column = 0

		item = item\gsub("\\t%(", "")\gsub("%)", "")
		for tagname, tagvalue in item\gmatch "|([1-4]?[a-z]+)([^|{}]*)"
			if column >= (column_limit-1)
				row += 1
				column = 0
			dlg, row, column = guiHelper dlg, row, column, tagname, tagvalue, "tr"..index
	return dlg

editLines = (subs, act, res, tagtextsection) ->
	transform_count, text = 0, ""
	for section_count, section in ipairs tagtextsection
		tagTable, _ = analyzeSection section
		text = text .."{"
		for _, tag in ipairs tagTable
			klass = tagClass[tag]
			if tag\match "t[%d]+"
				tagvalue = tagTable[tag]
				transform_count += 1
				trstart = res["trstart"..transform_count]
				trend = res["trend"..transform_count]
				traccel = res["traccel"..transform_count]
				tra = "\\t(" .. trstart .. "," .. trend .. "," .. traccel .. ","
				tra = tra\gsub(",,,", ",")\gsub(",,",",")\gsub("\\t%(,","\\t(")

				for t in tagvalue\gmatch "|([1-4]?[a-z]+)[^|{}]*"
					tra = tra .. "\\" .. t .. res[t .. "tr" .. transform_count]
				tra = tra .. ")"
				text = text .. tra
			elseif klass == "coordinate"
				val_x = res[tag.."x"..section_count]
				val_y = res[tag.."y"..section_count]
				newval = "("..val_x..","..val_y..")"
				text = text .. "\\".. tag .. newval
			elseif klass == "checkbox"
				newval = switch res[tag..section_count]
					when true then 1
					when false then 0
				text = text .. "\\".. tag .. newval
			elseif klass == "dropdown"
				newval = res[tag..section_count]
				if tag == "alpha" or tag == "1a" or tag == "2a" or tag == "3a" or tag == "4a"
					newval = newval\gsub("^", "&H")\gsub("$", "&")
				text = text .. "\\".. tag .. newval
			elseif klass == "color"
				newval = res[tag..section_count]
				newval = newval\gsub("#(%x%x)(%x%x)(%x%x)", "&H%3%2%1&")
				text = text .. "\\".. tag .. newval
			else
				text = text .. "\\".. tag .. res[tag..section_count]
		text = text .."}".. res["text"..section_count]

	line = subs[act]
	line.text = text
	subs[act] = line

main = (subs, sel, act) ->
	section = collect_section subs, act
	GUI = createGUI section
	btn, res = aegisub.dialog.display GUI, {"Apply", "Cancel"}, {"ok": "Apply", "cancel": "Cancel"}
	if btn
		editLines subs, act, res, section

aegisub.register_macro script_name, script_description, main
