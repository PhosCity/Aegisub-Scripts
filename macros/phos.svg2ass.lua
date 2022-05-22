-- SCRIPT PROPERTIES
script_name = "svg2ass"
script_description = "Script that uses svg2ass to convert svg files to ass lines"
script_author = "PhosCity"
script_version = "1.1.0"
script_namespace = "phos.svg2ass"

local pathsep = package.config:sub(1, 1)
DependencyControl = require("l0.DependencyControl")
local depRec = DependencyControl({
	feed = "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
	{
		"a-mo.ConfigHandler",
		version = "1.1.4",
		url = "https://github.com/TypesettingTools/Aegisub-Motion",
		feed = "https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json",
	},
})

ConfigHandler = depRec:requireModules()

local CONFIG_GUI = {
	main = {
		label1 = {
			x = 0,
			y = 0,
			width = 5,
			height = 1,
			class = "label",
			label = "Absoulute path of svg2ass executable:",
		},
		svgpath = {
			x = 0,
			y = 1,
			width = 20,
			height = 3,
			class = "edit",
			config = true,
			value = "svg2ass",
		},
		label2 = {
			x = 0,
			y = 4,
			width = 5,
			height = 1,
			class = "label",
			label = "svg2ass options:",
		},
		label3 = {
			x = 0,
			y = 5,
			width = 5,
			height = 1,
			class = "label",
			label = "Default options already used: -S, -E, -T ",
		},
		label4 = {
			x = 0,
			y = 6,
			width = 10,
			height = 1,
			class = "label",
			label = "No processing of options below will be done. Garbage in, Garbage out.",
		},
		svgopt = {
			x = 0,
			y = 7,
			width = 20,
			height = 3,
			class = "edit",
			config = true,
			value = "",
		},
		label5 = {
			x = 0,
			y = 10,
			width = 5,
			height = 1,
			class = "label",
			label = "Custom ASS Tags:",
		},
		label6 = {
			x = 0,
			y = 11,
			width = 10,
			height = 1,
			class = "label",
			label = "Default tags added automatically: \\an7\\pos(0,0)\\p1",
		},
		label7 = {
			x = 0,
			y = 12,
			width = 10,
			height = 1,
			class = "label",
			label = "No processing of tags below will be done. Garbage in, Garbage out.",
		},
		usertags = {
			x = 0,
			y = 13,
			width = 20,
			height = 3,
			class = "edit",
			config = true,
			value = "\\bord0\\shad0",
		},
	},
}

local config = ConfigHandler(CONFIG_GUI, depRec.configFile, false, script_version, depRec.configDir)

-- Modify config
local function config_setup()
	config:read()
	config:updateInterface("main")
	local button, result = aegisub.dialog.display(CONFIG_GUI.main)
	if button then
		config:updateConfiguration(result, "main")
		config:write()
		config:updateInterface("main")
	end
end

-- Check if svg2ass exists in the path given in config
local function check_svg2ass_exists(path)
	if pathsep == "\\" then
		local cex = io.open(path)
		if cex == nil then
			LOG(
				"svg2ass not found in the path provided in the config.\nMake sure that svg2ass is available in the path defined.\n"
			)
			AK()
		else
			cex:close()
		end
	else
		local exitcode = os.execute(path .. " -h")
		if not exitcode then
			LOG(
				"svg2ass not found in the path provided in the config.\nMake sure that svg2ass is available in the path defined.\n"
			)
			AK()
		end
	end
end

-- Convert timestamp to time in ms
local function string2time(timecode)
	timecode = timecode:gsub("(%d):(%d%d):(%d%d)%.(%d%d)", function(a, b, c, d)
		return d * 10 + c * 1000 + b * 60000 + a * 3600000
	end)
	return timecode
end

-- Convert a "Dialogue: 0,0:00..." string to a "line" table
local function string2line(str)
	local ltype, layer, s_time, e_time, style, actor, margl, margr, margv, eff, txt = str:match(
		"(%a+): (%d+),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),(.*)"
	)
	local l2 = {}
	l2.class = "dialogue"
	if ltype == "Comment" then
		l2.comment = true
	else
		l2.comment = false
	end
	l2.layer = layer
	l2.start_time = string2time(s_time)
	l2.end_time = string2time(e_time)
	l2.style = style
	l2.actor = actor
	l2.margin_l = margl
	l2.margin_r = margr
	l2.margin_t = margv
	l2.effect = eff
	l2.text = txt
	return l2
end

-- Convert time in ms to timestamp
local function time2string(num)
	local timecode = math.floor(num / 1000)
	local tc0 = 0
	local tc1 = math.floor(timecode / 60)
	local tc2 = timecode % 60
	local numstr = "00" .. num
	local tc3 = numstr:match("(%d%d)%d$")
	repeat
		if tc2 >= 60 then
			tc2 = tc2 - 60
			tc1 = tc1 + 1
		end
		if tc1 >= 60 then
			tc1 = tc1 - 60
			tc0 = tc0 + 1
		end
	until tc2 < 60 and tc1 < 60
	if tc1 < 10 then
		tc1 = "0" .. tc1
	end
	if tc2 < 10 then
		tc2 = "0" .. tc2
	end
	tc0 = tostring(tc0)
	tc1 = tostring(tc1)
	tc2 = tostring(tc2)
	local timestring = tc0 .. ":" .. tc1 .. ":" .. tc2 .. "." .. tc3
	return timestring
end

-- Convert shape to clip
local function shape_to_clip(text)
	if text:match("^{[^}]-\\p1") then
		local shape = text:match("}([^{]+)")
		if shape then
			text = text:gsub("\\i?clip%([^),]*%)", ""):gsub(shape, ""):gsub("\\p1", "")
			text = text:gsub("}", "\\clip(" .. shape .. ")}")
		end
	else
		LOG("Something went wrong when converting shape to clip! The result does not contain shape.\n")
		AK()
	end
	return text
end

-- Convert clip to iclip
local function shape_to_iclip(text)
	text = shape_to_clip(text)
	if text:match("^{[^}]-\\clip") then
		text = text:gsub("\\clip", "\\iclip")
	else
		LOG("Something went wrong when converting shape to iclip! The result does not contain clip.\n")
		AK()
	end
	return text
end

-- Execute the command
local function run_cmd(command)
	local handle = io.popen(command)
	local result = handle:read("*a")
	handle:close()
	return result
end

-- Progressbar
local function progress(msg)
	if aegisub.progress.is_cancelled() then
		AK()
	end
	aegisub.progress.title(msg)
end

-- Surveys the selected lines. Returns the least starting time, max end time and a style among them
local function reconnaissance(subs, sel)
	local start_time, end_time = math.huge, 0
	local style_list = {}
	local style
	for _, i in ipairs(sel) do
		start_time = math.min(start_time, subs[i].start_time)
		end_time = math.max(end_time, subs[i].end_time)
		local stl = subs[i].style
		if style_list[stl] == nil then
			style_list[stl] = 1
			table.insert(style_list, stl)
		end
	end
	if #style_list > 1 then
		-- stylua: ignore start
		local dlg = {{ class = "label", x = 0, y = 0, width = 1, height = 1, label = "Your selection has multiple styles. Please select one:", },}
		for k, v in ipairs(style_list) do
			dlg[#dlg + 1] = { class = "checkbox", x = 0, y = k, width = 1, height = 1, label = v, name = "stl" .. tostring(k), }
		end
		-- stylua: ignore end
		local pressed, result = ADD(dlg, { "OK", "Cancel" })
		if pressed == "Cancel" then
			AK()
		elseif pressed == "OK" then
			for i = 1, #dlg do
				if result["stl" .. tostring(i)] then
					style = style_list[i]
				end
			end
		end
	else
		style = style_list[1]
	end
	return start_time, end_time, style
end

-- Pastes the shape data over the selected lines while keeping the original tags
local function pstover(subs, sel, result, line_count, res)
	if #sel ~= line_count then
		LOG("Number of selected lines is not equal to output lines. Pasteover failed.")
		AK()
	end

	for _, i in ipairs(sel) do
		if subs[i].class == "dialogue" then
			local text = subs[i].text
			if res.clip and not text:match("^{[^}]-\\clip") then
				LOG("Your selection consists of lines without clip. Pasteover failed.")
				AK()
			end
			if res.iclip and not text:match("^{[^}]-\\iclip") then
				LOG("Your selection consists of lines without iclip. Pasteover failed.")
				AK()
			end
			if res.drawing and not text:match("^{[^}]-\\p1") then
				LOG("Your selection consists of lines that are not shape. Pasteover failed.")
				AK()
			end
		end
	end

	local shape_tbl = {}
	for j in result:gmatch("[^\n]+") do
		local line = string2line(j)
		local shape = line.text:match("}([^{]+)")
		table.insert(shape_tbl, shape)
	end

	for k, i in ipairs(sel) do
		if subs[i].class == "dialogue" then
			local line = subs[i]
			local tags = line.text:match("{\\[^}]-}")
			local shape = shape_tbl[k]
			line.text = tags .. shape

			-- Convert shape to clip
			if res.clip then
				line.text = line.text:gsub("\\clip%(m [%d%a%s%-]+", "\\p1")
				line.text = shape_to_clip(line.text)
			end

			-- Convert shape to iclip
			if res.iclip then
				line.text = line.text:gsub("\\iclip%(m [%d%a%s%-]+", "\\p1")
				line.text = shape_to_iclip(line.text)
			end

			subs[i] = line
		end
	end
	return sel
end

-- Main function
local function svg2ass(subs, sel, res, usetextbox)
	-- Read config
	config:read()
	config:updateInterface("main")
	local opt = config.configuration.main

	local start_time, end_time, style = reconnaissance(subs, sel)
	local result

	if not usetextbox then
		-- Check if svg2ass executable exists
		check_svg2ass_exists(opt.svgpath)

		-- Select svg file
		local script_folder
		if pathsep == "\\" then
			script_folder = ""
		else
			script_folder = ADP("?script")
		end
		local fname = aegisub.dialog.open("Select svg file", "", script_folder, "*.svg", false, true)

		if not fname then
			AK()
		else
			-- Generate svg2ass command
			local command = opt.svgpath
				.. " -S "
				.. time2string(start_time)
				.. " -E "
				.. time2string(end_time)
				.. ' -T "'
				.. style
				.. '"'
			if opt.svgopt then
				command = command .. " " .. opt.svgopt
			end
			command = command .. ' "' .. fname .. '"'

			-- Execute the command and grab it's result
			result = run_cmd(command)
		end
	else
		--Grab what is in the textbox
		local raw_output = res.txtbox
		if not raw_output:match("^Dialogue") then
			LOG("Please replace the textbox content with svg2ass output.")
			AK()
		end

		result = ""
		for z in raw_output:gmatch("[^\n]+") do
			z = z:gsub(
				"(%a+: %d+,)([^,]-,[^,]-,[^,]-)(,[^,]-,[^,]-,[^,]-,[^,]-,[^,]-,.*)",
				"%1" .. time2string(start_time) .. "," .. time2string(end_time) .. "," .. style .. "%3"
			)
			result = result .. z .. "\n"
		end
	end

	-- Count the total number of lines in result
	local _, line_count = string.gsub(result, "\n", "\n")

	local newsel = {}
	if not res.pasteover then
		local inserts, count = 0, 1
		for j in result:gmatch("[^\n]+") do
			-- Progressbar
			progress("Progress Occurs")
			aegisub.progress.set((count * 100) / line_count)

			local newline = string2line(j)
			local primary_color = newline.text:match("\\1c&H%x+&"):gsub("\\1c&", "\\c&")
			local tags = "{\\an7\\pos(0,0)" .. opt.usertags .. primary_color .. "\\p1}"
			local text = newline.text:gsub("{\\[^}]-}", "")
			newline.text = tags .. text

			-- Convert shape to clip
			if res.clip then
				newline.text = shape_to_clip(newline.text)
			end

			-- Convert shape to iclip
			if res.iclip then
				newline.text = shape_to_iclip(newline.text)
			end

			subs.insert(sel[1] - inserts, newline)
			table.insert(newsel, sel[1] - inserts)
			inserts = inserts - 1
			count = count + 1
		end
	else
		newsel = pstover(subs, sel, result, line_count, res)
	end
	return newsel
end

local function main(subs, sel)
	ADD = aegisub.dialog.display
	ADP = aegisub.decode_path
	AK = aegisub.cancel
	LOG = aegisub.log
	local GUI = {
		{
			x = 0,
			y = 0,
			width = 7,
			height = 5,
			name = "txtbox",
			class = "textbox",
			text = "have ass, will typeset",
		},
		{
			x = 0,
			y = 6,
			name = "drawing",
			label = "drawing          ",
			class = "checkbox",
			value = true,
			hint = "Convert svg to drawing",
		},
		{
			x = 1,
			y = 6,
			name = "clip",
			label = "clip          ",
			class = "checkbox",
			hint = "Convert svg to clip",
		},
		{
			x = 2,
			y = 6,
			name = "iclip",
			label = "iclip          ",
			class = "checkbox",
			hint = "Convert svg to iclip",
		},
		{
			x = 3,
			y = 6,
			name = "pasteover",
			label = "pasteover",
			class = "checkbox",
			hint = "Convert svg but paste shape date over selected lines",
		},
	}
	Buttons = { "Import", "Textbox", "Cancel" }
	Pressed, Res = ADD(GUI, Buttons)
	if Pressed == "Cancel" then
		AK()
	elseif Pressed == "Import" then
		svg2ass(subs, sel, Res, false)
	elseif Pressed == "Textbox" then
		svg2ass(subs, sel, Res, true)
	end
end

depRec:registerMacros({
	{ "Run", "Run the script", main },
	{ "Config", "Configuration for script", config_setup },
})
