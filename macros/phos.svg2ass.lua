-- SCRIPT PROPERTIES
script_name = "svg2ass"
script_description = "Script that uses svg2ass to convert svg files to ass lines"
script_author = "PhosCity"
script_version = "0.0.6"
script_namespace = "phos.svg"

DependencyControl = require("l0.DependencyControl")
local depRec = DependencyControl({
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
	local cex = io.open(path)
	if cex == nil then
		aegisub.log(
			"svg2ass not found in the path provided in the config.\nMake sure that svg2ass is available in the path defined.\n"
		)
		aegisub.cancel()
	else
		cex:close()
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
		aegisub.log("Something went wrong!")
		aegisub.cancel()
	end
	return text
end

-- Convert clip to iclip
local function clip_to_iclip(text)
	text = shape_to_clip(text)
	if text:match("^{[^}]-\\clip") then
		text = text:gsub("\\clip", "\\iclip")
	else
		aegisub.log("Something went wrong!")
		aegisub.cancel()
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
		aegisub.cancel()
	end
	aegisub.progress.title(msg)
end

-- Main function
local function svg2ass(subs, sel, res)
	-- Read config
	config:read()
	config:updateInterface("main")
	local opt = config.configuration.main

	-- Check if svg2ass executable exists
	check_svg2ass_exists(opt.svgpath)

	if #sel ~= 1 then
		aegisub.log(
			"You must select exactly one line\nThat line's start time, end time and style will be copied to resulting lines."
		)
		return
	end

	-- Select svg file
	local ffilter = "SVG Files (.svg)|*.svg"
	local fname = aegisub.dialog.open("Select svg file", "", "", ffilter, false, true)

	-- Initialize new selection(for new llines that were added)
	local newsel = {}

	for _, i in ipairs(sel) do
		if subs[i].class == "dialogue" then
			local line = subs[i]
			if not fname then
				aegisub.cancel()
			else
				-- Generate svg2ass command
				local command = opt.svgpath
					.. " -S "
					.. time2string(line.start_time)
					.. " -E "
					.. time2string(line.end_time)
					.. " -T "
					.. line.style
				if opt.svgopt then
					command = command .. " " .. opt.svgopt
				end
				command = command .. ' "' .. fname .. '"'

				-- Execute the command and grab it's result
				local result = run_cmd(command)

				-- Count the total number of lines in result
				local _, line_count = string.gsub(result, "\n", "\n")

				local inserts = 0
				local count = 1
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
						newline.text = clip_to_iclip(newline.text)
					end

					subs.insert(sel[1] - inserts, newline)
					table.insert(newsel, sel[1] - inserts)
					inserts = inserts - 1
					count = count + 1
				end
			end
		end
	end
	return newsel
end

local function main(subs, sel)
	local GUI = {
		{
			x = 0,
			y = 0,
			width = 7,
			height = 5,
			class = "textbox",
			text = "have ass, will typeset\nwill also crash Aegisub\nsave file before running",
		},
		{
			x = 0,
			y = 6,
			name = "drawing",
			label = "drawing               ",
			class = "checkbox",
			value = true,
		},
		{
			x = 1,
			y = 6,
			name = "clip",
			label = "clip               ",
			class = "checkbox",
		},
		{
			x = 2,
			y = 6,
			name = "iclip",
			label = "iclip",
			class = "checkbox",
		},
	}
	Buttons = { "Import", "Cancel" }
	Pressed, Res = aegisub.dialog.display(GUI, Buttons)
	if Pressed == "Cancel" then
		aegisub.cancel()
	elseif Pressed == "Import" then
		svg2ass(subs, sel, Res)
	end
end

aegisub.register_macro(script_name .. "/Run", script_description, main)
aegisub.register_macro(script_name .. "/Config", script_description, config_setup)
