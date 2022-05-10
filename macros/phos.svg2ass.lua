-- SCRIPT PROPERTIES
script_name = "svg2ass"
script_description = "Script that uses svg2ass to convert svg files to ass lines"
script_author = "PhosCity"
script_version = "0.0.5"
script_namespace = "phos.svg"

DependencyControl = require("l0.DependencyControl")
local depRec = DependencyControl({})
ConfigHandler = require("l0.DependencyControl.ConfigHandler")

local default_config = {
	svg2ass_path = "svg2ass",
	svg2ass_parameters = "",
	user_tags = "\\bord0\\shad0",
}
local config = ConfigHandler(depRec:getConfigFileName(), default_config, "config")

local function config_setup()
	local CONFIG_GUI = {
		{
			x = 0,
			y = 0,
			width = 5,
			height = 1,
			class = "label",
			label = "Absoulute path of svg2ass executable:",
		},
		{
			x = 0,
			y = 1,
			width = 20,
			height = 3,
			name = "svgpth",
			class = "edit",
			value = config.c.svg2ass_path,
		},
		{
			x = 0,
			y = 4,
			width = 5,
			height = 1,
			class = "label",
			label = "svg2ass options:",
		},
		{
			x = 0,
			y = 5,
			width = 5,
			height = 1,
			class = "label",
			label = "Default options already used: -S, -E, -T ",
		},
		{
			x = 0,
			y = 6,
			width = 10,
			height = 1,
			class = "label",
			label = "No processing of options below will be done. Garbage in, Garbage out.",
		},
		{
			x = 0,
			y = 7,
			width = 20,
			height = 3,
			name = "svgopt",
			class = "edit",
			value = config.c.svg2ass_parameters,
		},
		{
			x = 0,
			y = 10,
			width = 5,
			height = 1,
			class = "label",
			label = "Custom ASS Tags:",
		},
		{
			x = 0,
			y = 11,
			width = 10,
			height = 1,
			class = "label",
			label = "Default tags added automatically: \\an7\\pos(0,0)\\p1",
		},
		{
			x = 0,
			y = 12,
			width = 10,
			height = 1,
			class = "label",
			label = "No processing of tags below will be done. Garbage in, Garbage out.",
		},
		{
			x = 0,
			y = 13,
			width = 20,
			height = 3,
			name = "usrtgs",
			class = "edit",
			value = config.c.user_tags,
		},
	}
	Buttons = { "Save", "Cancel" }
	Pressed, Res = ADD(CONFIG_GUI, Buttons)
	if Pressed == "Cancel" then
		AK()
	elseif Pressed == "Save" then
		config.c.svg2ass_path = Res.svgpth
		config.c.svg2ass_parameters = Res.svgopt
		config.c.user_tags = Res.usrtgs
		config:write()
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
	end
	return text
end

-- Convert clip to iclip
local function clip_to_iclip(text)
	if text:match("^{[^}]-\\clip") then
		text = text:gsub("\\clip", "\\iclip")
		return text
	end
end

local function run_cmd(command)
	local handle = io.popen(command)
	local result = handle:read("*a")
	handle:close()
	return result
end

local function svg2ass(subs, sel, res)
	config:load()
	check_svg2ass_exists(config.c.svg2ass_path)
	if #sel ~= 1 then
		aegisub.log(
			"You must select exactly one line\nThat line's start time, end time and style will be copied to resulting lines."
		)
		return
	end
	local ffilter = "SVG Files (.svg)|*.svg"
	local script_dir = aegisub.decode_path("?script")
	local fname = aegisub.dialog.open("Select svg file", "", "", ffilter, false, true)
	local newsel = {}
	for _, i in ipairs(sel) do
		if subs[i].class == "dialogue" then
			local line = subs[i]
			if not fname then
				aegisub.cancel()
			else
				local command = config.c.svg2ass_path
					.. " -S "
					.. time2string(line.start_time)
					.. " -E "
					.. time2string(line.end_time)
					.. " -T "
					.. line.style
				if config.c.svg2ass_parameters then
					command = command .. " " .. config.c.svg2ass_parameters
				end
				command = command .. ' "' .. fname .. '"'
				local result = run_cmd(command)
				local inserts = 1
				for j in result:gmatch("[^\n]+") do
					local newline = string2line(j)
					local primary_color = newline.text:match("\\1c&H%x+&"):gsub("\\1c&", "\\c&")
					local tags = "{\\an7\\pos(0,0)" .. config.c.user_tags .. primary_color .. "\\p1}"
					local text = newline.text:gsub("{\\[^}]-}", "")
					newline.text = tags .. text
					if res.clip then
						newline.text = shape_to_clip(newline.text)
					end
					if res.iclip then
						newline.text = shape_to_clip(newline.text)
						newline.text = clip_to_iclip(newline.text)
					end
					subs.insert(sel[1] - inserts, newline)
					table.insert(newsel, sel[1] - inserts)
					inserts = inserts - 1
				end
			end
		end
	end
	return newsel
end

local function main(subs, sel)
	ADD = aegisub.dialog.display
	ADP = aegisub.decode_path
	AK = aegisub.cancel
	local GUI = {
		{
			x = 0,
			y = 0,
			width = 5,
			height = 1,
			class = "label",
			label = "Please save your file before running the script.",
		},
		{
			x = 0,
			y = 1,
			width = 5,
			height = 1,
			class = "label",
			label = "It's in early stage and may crash.\n",
		},
		{
			x = 0,
			y = 2,
			name = "drawing",
			label = "drawing",
			class = "checkbox",
		},
		{
			x = 1,
			y = 2,
			name = "clip",
			label = "clip",
			class = "checkbox",
		},
		{
			x = 2,
			y = 2,
			name = "iclip",
			label = "iclip",
			class = "checkbox",
		},
	}
	Buttons = { "Export", "Cancel" }
	Pressed, Res = ADD(GUI, Buttons)
	if Pressed == "Cancel" then
		AK()
	elseif Pressed == "Export" then
		svg2ass(subs, sel, Res)
	end
end

aegisub.register_macro(script_name .. "/" .. "Run", script_description, main)
aegisub.register_macro(script_name .. "/" .. "Config", script_description, config_setup)
