export script_name = "Edit tags"
export script_description = "Edit tags of current lines"
export script_author = "PhosCity"
export script_namespace = "phos.edittags"
export script_version = "1.0.1"

-- Initialize some variables
row, column, column_limit, dlg, transformTable = 0, 0, 10, {}, {}

tagClass = {
	alpha: "dropdown", "1a": "dropdown", "2a": "dropdown", "3a": "dropdown", "4a": "dropdown",
	c: "color", "1c": "color", "2c": "color", "3c": "color", "4c": "color",
	q: "dropdown",
	an: "dropdown",
	blur: "floatedit", be: "intedit",
	bord: "floatedit", xbord: "floatedit", ybord:  "floatedit",
	shad: "floatedit", xshad: "floatedit", yshad: "floatedit",
	fscx: "floatedit", fscy: "floatedit",
	frx: "floatedit", fry: "floatedit", frz: "floatedit",
	fax: "floatedit", fay: "floatedit",
	fs: "intedit", fsp: "floatedit",
	i: "checkbox", b: "checkbox", u: "checkbox", s: "checkbox",
	pos: "coordinate", org: "coordinate",
	fad: "coordinate", fade: "complex",
	move: "complex",
	clip: "complex", iclip: "complex",
	t: "transform",
	}

esc = (str) ->
	return str\gsub "[%%%(%)%[%]%.%-%+%*%?%^%$]", "%%%1"

table_contains = (tbl, x) ->
	for item in *tbl
		return true if item == x
	return false

-- Deactivate the tags inside transform by changing \ to |
untransform = (line) ->
	-- I cannot find a way to match transform tag that has a clip inside it.
	if line\match "\\i?clip"
		line = line\gsub "(\\i?clip)%(([^)]+)%)", "%1|s|%2|e|" 

	for tr in line\gmatch "\\t%([^)]+%)"
		new_tr = tr\gsub("\\", "|")\gsub("|t", "\\t")
		line = line\gsub esc(tr), new_tr
	
	-- Reverting the clip
	line = line\gsub("|s|", "(")\gsub("|e|", ")")

	return line

-- Divides the line in a {tag}text section pair
collect_section = (subs, act) ->
	section = {}
	line = subs[act]
	line.text = untransform line.text
	line.text = line.text\gsub "{([^\\}]-)}", "|s|%1|e|"				-- A bit hacky way to deactivate the comments so that they are treated as text and not tags

	for item in line.text\gmatch "{[^{}]*}[^{}]*"
		item = item\gsub("|s|", "{")\gsub("|e|", "}")				-- Revert the comments to it's former glory
		table.insert section, item

	if #section == 0
		aegisub.log "No tags found in the selection."
		aegisub.cancel!
	else
		return section

-- Takes in a {tag}text section and creates a table with key-value pair of tag and it's value
analyzeSection = (section) ->
	transform_count, tagTable = 0, {}
	tag, text = section\match "^({%*?\\[^}]-})(.*)"

	for tagname, tagvalue in tag\gmatch "\\([1-4]?[a-z]+)([^\\{}]*)"
		-- Since transform can appear multiple times in a same section, number it for later processing
		if tagname == "t"
			transform_count += 1
			tagname = tagname..transform_count

		table.insert tagTable, tagname
		tagTable[tagname] = tagvalue

	return tagTable, text

-- Add tags and it's value to gui based on the type of tag
guiHelper = (tagname, tagvalue, section_count) ->
	klass = tagClass[tagname]
	klass = "edit" if not klass
	if klass == "dropdown"
		alphaitem = { "00", "10", "20", "30", "40", "50", "60", "70", "80", "90", "A0", "B0", "C0", "D0", "E0", "F0", "F8", "FF" }
		dropdownItems = switch tagname
			when "q" then { "0", "1", "2", "3" }
			when "an" then { "1", "2", "3", "4", "5", "6", "7", "8", "9" }
			else alphaitem

		if tagname == "alpha" or tagname == "1a" or tagname == "2a" or tagname == "3a" or tagname == "4a"
			tagvalue = tagvalue\gsub("[H&]", "")
			if not table_contains alphaitem, tagvalue
				table.insert alphaitem, tagvalue

		dlg[#dlg+1] = { x: column, y:row, class: "label", label: tagname }
		column +=1
		dlg[#dlg+1] = { x: column, y:row, class: "dropdown", items: dropdownItems, value: tagvalue, name: tagname..section_count }
		column +=1
	elseif klass == "color"
		dlg[#dlg+1] = { x: column, y:row, class: "label", label: tagname }
		column +=1
		dlg[#dlg+1] = { x: column, y:row, class: "color", name: tagname..section_count, value: tagvalue }
		column +=1
	elseif klass == "checkbox"
		tagvalue = switch tagvalue
			when "1" then true
			when "0" then false
			else tagvalue

		taglabel = switch tagname
			when "i" then "Italics"
			when "b" then "Bold"
			when "u" then "Underline"
			when "s" then "Strikeout"

		if tagname == "b" and tagvalue != true and tagvalue != false				-- Non-boolean font weights
			dlg[#dlg+1] = { x: column, y:row, class: "label", label: taglabel }
			column +=1
			dlg[#dlg+1] = { x: column, y:row, class: "edit", name: tagname..section_count, value: tagvalue }
		else
			dlg[#dlg+1] = { x: column, y:row, class: klass, name: tagname..section_count, value: tagvalue, label: taglabel }
		column +=1
	elseif klass == "coordinate"
		first_item, second_item = tagvalue\match "%(([%d%.%-]+),([%d%.%-]+)%)"
		dlg[#dlg+1] = { x: column, y:row, class: "label", label: tagname }
		column +=1
		dlg[#dlg+1] = { x: column, y:row, class: "floatedit", name: tagname.."x"..section_count, value: first_item }
		column +=1
		dlg[#dlg+1] = { x: column, y:row, class: "floatedit", name: tagname.."y"..section_count, value: second_item }
		column +=1
	elseif klass == "edit" or klass == "floatedit" or klass == "intedit"
		dlg[#dlg+1] = { x: column, y:row, class: "label", label: tagname }
		column +=1
		dlg[#dlg+1] = { x: column, y:row, class: klass, name: tagname..section_count, value: tagvalue }
		column +=1
	elseif klass == "complex"
		if column != 0
			row += 1
			column = 0
		dlg[#dlg+1] = { x: column, y:row, class: "label", label: tagname }
		column += 1
		a, b, c, d, e, f, g, hint = nil, nil, nil, nil, nil, nil, nil, {}
		switch tagname
			when "fade"
				a, b , c, d, e, f, g = tagvalue\match "%((%d+),(%d+),(%d+),([%-%d]+),([%-%d]+),([%-%d]+),([%-%d]+)%)"
				hint = {"a1", "a2", "a3", "t1", "t3", "t4" }
			when "move"
				if tagvalue\match "%([%-%d%.]+,[%-%d%.]+,[%-%d%.]+,[%-%d%.]+%)"
					a, b, c, d = tagvalue\match "%(([%-%d%.]+),([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)%)"
				else
					a, b, c, d, e, f = tagvalue\match "%(([%-%d%.]+),([%-%d%.]+),([%-%d%.]+),([%-%d%.]+),([%-%d]+),([%-%d]+)%)"
				hint = {"x1", "y1", "x2", "y2", "t1", "t2" }
			else		--clip or iclip
				if tagvalue\match "%([%-%d%.]+,[%-%d%.]+,[%-%d%.]+,[%-%d%.]+%)"
					a, b, c, d = tagvalue\match "%(([%-%d%.]+),([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)%)"
					hint = {"x1", "y1", "x2", "y2" }
		if a
			dlg[#dlg+1] = { x: column, y:row, class: "floatedit", name: tagname.."a"..section_count, value: a, hint: hint[1] }
			column +=1
			dlg[#dlg+1] = { x: column, y:row, class: "floatedit", name: tagname.."b"..section_count, value: b, hint: hint[2] }
			column +=1
			dlg[#dlg+1] = { x: column, y:row, class: "floatedit", name: tagname.."c"..section_count, value: c, hint: hint[3] }
			column +=1
			dlg[#dlg+1] = { x: column, y:row, class: "floatedit", name: tagname.."d"..section_count, value: d, hint: hint[4] }
			column +=1
			if tagname == "fade" or tagname =="move"
				dlg[#dlg+1] = { x: column, y:row, class: "floatedit", name: tagname.."e"..section_count, value: e, hint: hint[5] }
				column +=1
				dlg[#dlg+1] = { x: column, y:row, class: "floatedit", name: tagname.."f"..section_count, value: f, hint: hint[6] }
				column +=1
			if tagname == "fade"
				dlg[#dlg+1] = { x: column, y:row, class: "floatedit", name: tagname.."g"..section_count, value: g, hint: hint[7] }
				column +=1
		else
			dlg[#dlg+1] = { x: column, y:row, width: column_limit, class: "edit", name: tagname..section_count, value: tagvalue }
		column = column_limit

-- Receives a {tag}text section and adds all its tags to gui
addsectiontoGUI = (section, section_count ) ->
	tagTable, text = analyzeSection section

	dlg[#dlg+1] = { x: column, y:row, width: column_limit, class: "edit", value: text, name: "text"..section_count }
	row += 1

	for tag in *tagTable
		if column >= (column_limit-1) and tagClass[tag] != "complex"
			row += 1
			column = 0
		if tag\match "(t[%d]+)"
			table.insert transformTable, tagTable[tag]
		else
			guiHelper tag, tagTable[tag], section_count

-- Adds inline tags to gui. For long gbc, it just adds all of them to textbox
inlinetagsGUI = (tagtextsection) ->
	row += 1
	column = 0
	dlg[#dlg+1] = { x: column, y:row, class: "label", label: "Inline Tags:" }

	-- Somewhat arbitary number 10. Any longer and put inline tags in textbox cuz the gui produced will be big and will go over the screen in the small monitors
	if #tagtextsection < 10
		for section_count, section in ipairs tagtextsection
			if section_count > 1 then addsectiontoGUI section, section_count
			row += 1
			column = 0
	else
		row += 1
		column = 0
		inline = ""
		for section_count, section in ipairs tagtextsection
			if section_count > 1 then inline = inline .. section .. "\n"

		dlg[#dlg+1] = { x: column, y:row, width: column_limit, height: math.min(math.ceil(#tagtextsection*0.7),20), class: "textbox", value: inline, name: "inline" }
		row += math.min(math.ceil(#tagtextsection*0.7),20)

-- Adds transforms to gui along with it's time and accel
transformGUI = () ->
	transform_count = 0
	for index, item in ipairs transformTable
		row += 1
		column = 0
		if transform_count < 1
			dlg[#dlg+1] = { x: column, y:row, class: "label", label: "Transform:" }
			row += 1
			column = 0
			transform_count += 1
		tag_start, tag_end = item\match "%(([%d.-]+),([%d.-]+)[^)]*%)"
		accel = item\match "%([%d.-]-,[%d.-]-,([%d.-]-),|[^)]*%)"

		dlg[#dlg+1] = { x: column, y:row, class: "label", label: index..". Start: " }
		column+=1
		dlg[#dlg+1] = { x: column, y:row, class: "edit", value: tag_start, name: "trstart"..index }
		column+=1
		dlg[#dlg+1] = { x: column, y:row, class: "label", label: "End: " }
		column+=1
		dlg[#dlg+1] = { x: column, y:row, class: "edit", value: tag_end, name: "trend"..index }
		column+=1
		dlg[#dlg+1] = { x: column, y:row, class: "label", label: "Accel: " }
		column +=1
		dlg[#dlg+1] = { x: column, y:row, class: "edit", value: accel, name: "traccel"..index }
		row += 1
		column = 0

		item = item\gsub("\\t%(", "")\gsub("%)$", "")
		for tagname, tagvalue in item\gmatch "|([1-4]?[a-z]+)([^|{}]*)"
			if column >= (column_limit-1)
				row += 1
				column = 0
			guiHelper tagname, tagvalue, "tr"..index

-- Gets the user input values from gui for the given tag
getnewvalues = (tag, res, section_count) ->
	klass = tagClass[tag]
	newval = res[tag..section_count]
	if klass == "coordinate"
		val_x = res[tag.."x"..section_count]
		val_y = res[tag.."y"..section_count]
		newval = "("..val_x..","..val_y..")"
	elseif klass == "checkbox"
		newval = switch newval
			when true then 1
			when false then 0
	elseif klass == "dropdown"
		if tag == "alpha" or tag == "1a" or tag == "2a" or tag == "3a" or tag == "4a"
			newval = newval\gsub("^", "&H")\gsub("$", "&")
	elseif klass == "color"
		newval = newval\gsub("#(%x%x)(%x%x)(%x%x)", "&H%3%2%1&")
	elseif klass == "complex"
		a, b, c, d, e, f, g = res[tag.."a"..section_count], res[tag.."b"..section_count], res[tag.."c"..section_count], res[tag.."d"..section_count], res[tag.."e"..section_count], res[tag.."f"..section_count], res[tag.."g"..section_count]
		if a then newval = "("..a..","..b..","..c..","..d..")"			-- move without time or rect [i]clip
		switch tag
			when "move"
				if e and f != 0 then newval = newval\gsub "%)", ","..e..","..f..")"		-- move with time
			when "fade"
				newval = newval\gsub "%)", ","..e..","..f..","..g..")"

	return newval

-- Rebuilds a {tag}text section from the values users puts in gui
rebuildsection = (section, section_count, text, transform_count, res) ->
	tagTable, _ = analyzeSection section
	newval = ""
	text = text .."{"
	for _, tag in ipairs tagTable
		if tag\match "t[%d]+"
			transform_count += 1
			trstart, trend, traccel = res["trstart"..transform_count], res["trend"..transform_count], res["traccel"..transform_count]
			newval= "(" .. trstart .. "," .. trend .. "," .. traccel .. ","
			newval= newval\gsub(",,,", ",")\gsub(",,",",")\gsub("\\t%(,","\\t(")

			tagvalue = tagTable[tag]
			for t in tagvalue\gmatch "|([1-4]?[a-z]+)[^|{}]*"
				newval= newval.. "\\" .. t .. getnewvalues(t, res, "tr"..transform_count)
			newval= newval.. ")"
			tag = "t"
		else
			newval = getnewvalues tag, res, section_count
		text = text .. "\\".. tag .. newval
	text = text .."}".. res["text"..section_count]
	return text, transform_count

main = (subs, sel, act) ->
	section = collect_section subs, act

	-- Dynamically create GUI
	row, column, column_limit, dlg, transformTable = 0, 0, 10, {}, {}
	addsectiontoGUI section[1], 1						-- Start tags
	if #section > 1 then inlinetagsGUI section				-- Inline tags
	if #transformTable > 0 then  transformGUI!				-- Transforms

	btn, res = aegisub.dialog.display dlg, {"Apply", "Cancel"}, {"ok": "Apply", "cancel": "Cancel"}
	if btn
		transform_count, text = 0, ""
		if #section < 10												-- Non or short gbc lines
			for section_count, sec in ipairs section
				text, transform_count = rebuildsection sec, section_count, text, transform_count, res
		else														-- Long gbc lines
			text, _ = rebuildsection section[1], 1, text, transform_count, res
			new_inline = res["inline"]
			new_inline = new_inline\gsub("\n", "")
			text = text .. new_inline

		line = subs[act]
		line.text = text
		subs[act] = line

aegisub.register_macro script_name, script_description, main
