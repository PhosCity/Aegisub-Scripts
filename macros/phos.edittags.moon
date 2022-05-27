export script_name = "#BETA# Edit tags"
export script_description = "Dynamically edit tags based on selection"
export script_author = "PhosCity"
export script_namespace = "phos.edittags"
export script_version = "0.0.1"

tagClass = (tag) ->
	tagParam = {
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
		p: "intedit"
		}
	
	return tagParam[tag]

dropdownValues = {
	alpha: { "00", "10", "20", "30", "40", "50", "60", "70", "80", "90", "A0", "B0", "C0", "D0", "E0", "F0", "F8", "FF" }
	"1a": { "00", "10", "20", "30", "40", "50", "60", "70", "80", "90", "A0", "B0", "C0", "D0", "E0", "F0", "F8", "FF" }
	"2a": { "00", "10", "20", "30", "40", "50", "60", "70", "80", "90", "A0", "B0", "C0", "D0", "E0", "F0", "F8", "FF" }
	"3a": { "00", "10", "20", "30", "40", "50", "60", "70", "80", "90", "A0", "B0", "C0", "D0", "E0", "F0", "F8", "FF" }
	"4a": { "00", "10", "20", "30", "40", "50", "60", "70", "80", "90", "A0", "B0", "C0", "D0", "E0", "F0", "F8", "FF" }
	q: { "0", "1", "2", "3" }
	an: { "1", "2", "3", "4", "5", "6", "7", "8", "9"}
	}

esc = (str) ->
	str = str\gsub "[%%%(%)%[%]%.%-%+%*%?%^%$]", "%%%1"
	return str

collect_tags = (subs, sel) ->
	tagSection = {}
	transformTable = {}

	for i in *sel
		line = subs[i]

		for transform in line.text\gmatch "\\t%([^)]*%)"
			table.insert transformTable, transform

		line.text = line.text\gsub "\\t%([^)]*%)", ""

		for tags in line.text\gmatch "{[^{}]*}[^{}]*"
			table.insert tagSection, tags

	if #tagSection == 0 and #transformTable == 0
		aegisub.log "No tags found in the selection."
		aegisub.cancel!
	else
		return tagSection, transformTable

sortTags = (tagNameTable) ->
	sort_order = {"pos", "org", "fad", "blur", "be", "bord", "xbord", "ybord", "shad", "xshad", "yshad", "fscx", "fscy", "frx", "fry", "frz", "fax", "fay", "fn", "fs", "fsp", "c", "1c", "2c", "3c", "4c", "alpha", "1a", "2a", "3a", "4a", "p", "t", "an", "q", "b", "i", "u", "s", "p", "move", "fade", "clip", "iclip", }
	sorted_tags = [tag for tag in *sort_order when tagNameTable[tag] != nil]
	for _, tag in ipairs sorted_tags
		sorted_tags[tag] = tagNameTable[tag]

	return sorted_tags

analyzeSection = (tagSection, dosort) ->
	tagNameTable = {}
	text = tagSection\gsub "^{>?\\[^}]-}", ""
	tag = tagSection\gsub esc(text), ""

	for tagname, tagvalue in tag\gmatch "\\([1-4]?[a-z]+)([^\\{}]*)"
		table.insert tagNameTable, tagname
		tagNameTable[tagname] = tagvalue
	
	if dosort
		tagNameTable = sortTags tagNameTable
	return tagNameTable, text

guiHelper = (dlg, row_count, column_count, tagname, tagvalue, section_count) ->
	klass = tagClass tagname
	if klass == "dropdown"
		if tagname == "alpha" or tagname == "1a" or tagname == "2a" or tagname == "3a" or tagname == "4a"
			tagvalue = tagvalue\gsub("H", "")\gsub("&", "")

		taglabel = tagname
		taglabel = "Alignment" if tagname == "an"

		dropdownItems = dropdownValues[tagname]
		dlg[#dlg+1] = { x: column_count, y:row_count, width: 1, class: "label", label: taglabel }
		column_count +=1
		dlg[#dlg+1] = { x: column_count, y:row_count, width: 1, class: "dropdown", items: dropdownItems, value: tagvalue, name: tagname..section_count }
		column_count +=1
	elseif klass == "color"
		lbl = switch tagname
			when "c" then "Primary"
                	when "1c" then "Primary"
                	when "2c" then "2c"
                	when "3c" then "Border"
                	when "4c" then "Shadow"

		dlg[#dlg+1] = { x: column_count, y:row_count, width: 1, class: "label", label: lbl }
		column_count +=1
		dlg[#dlg+1] = { x: column_count, y:row_count, width: 1, class: "color", name: tagname..section_count, value: tagvalue }
		column_count +=1
	elseif klass == "checkbox"
		tagvalue = switch tagvalue
			when "1" then true
			when "0" then false

		taglabel = switch tagname
			when "i" then "Italics"
			when "b" then "Bold"
			when "u" then "Underline"
			when "s" then "Strikeout"

		dlg[#dlg+1] = { x: column_count, y:row_count, width: 1, class: "checkbox", name: tagname..section_count, value: tagvalue, label: taglabel }
		column_count +=1
	elseif klass == "coordinate"
		first_item, second_item = tagvalue\match "%(([%d%.%-]+),([%d%.%-]+)%)"
		dlg[#dlg+1] = { x: column_count, y:row_count, width: 1, class: "label", label: tagname }
		column_count +=1
		dlg[#dlg+1] = { x: column_count, y:row_count, width: 1, class: "floatedit", name: tagname.."x"..section_count, value: first_item }
		column_count +=1
		dlg[#dlg+1] = { x: column_count, y:row_count, width: 1, class: "floatedit", name: tagname.."y"..section_count, value: second_item }
		column_count +=1
	elseif klass == "edit" or klass == "floatedit" or klass == "intedit"
		dlg[#dlg+1] = { x: column_count, y:row_count, width: 1, class: "label", label: tagname }
		column_count +=1
		dlg[#dlg+1] = { x: column_count, y:row_count, width: 1, class: klass, name: tagname..section_count, value: tagvalue }
		column_count +=1
	elseif klass == "complex"
		row_count += 1
		column_count = 0
		dlg[#dlg+1] = { x: column_count, y:row_count, width: 1, class: "label", label: tagname }
		column_count += 1
		dlg[#dlg+1] = { x: column_count, y:row_count, width: 5, class: "edit", name: tagname..section_count, value: tagvalue }

	return dlg, row_count, column_count

createGUI = (tagSection) ->
	row_count, column_count, column_limit, dlg = 0, 0, 10, {}
	for section_count, section in ipairs tagSection
		if section_count != 1
			row_count += 1
			column_count = 0
		tagTable, text = analyzeSection section, true
		dlg[#dlg+1] = { x: column_count, y:row_count, width: column_limit, class: "edit", value: text, name: "text"..section_count }
		row_count += 1

		for tag in *tagTable
			if column_count >= (column_limit-1)
				row_count += 1
				column_count = 0
			dlg, row_count, column_count = guiHelper dlg, row_count, column_count, tag, tagTable[tag], section_count
	return dlg

editLines = (subs, sel, res, tagSection) ->
	text = ""
	for section_count, section in ipairs tagSection
		tagTable, _ = analyzeSection section, false
		text = text .."{"
		for _, tag in ipairs tagTable
			klass = tagClass tag
			if klass == "coordinate"
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
	
	for i in *sel
		line = subs[i]
		line.text = text
		subs[i] = line

main = (subs, sel) ->
	tagSection, transformTable = collect_tags subs, sel
	GUI = createGUI tagSection
	btn, res = aegisub.dialog.display GUI, {"Apply", "Cancel"}, {"ok": "Apply", "cancel": "Cancel"}
	if btn
		editLines subs, sel, res, tagSection

aegisub.register_macro script_name, script_description, main
