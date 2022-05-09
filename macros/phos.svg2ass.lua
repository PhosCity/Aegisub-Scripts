-- SCRIPT PROPERTIES
script_name = "svg2ass(Linux Only)"
script_description = "Script that uses svg2ass to convert svg files to ass lines"
script_author = "PhosCity"
script_version = "0.0.1"
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
			label = "Path of svg2ass executable:",
		},
		{
			x = 0,
			y = 1,
			width = 30,
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
			width = 30,
			height = 3,
			name = "svgopt",
			class = "edit",
			value = config.c.svg2ass_parameters,
		},
		{
			x = 0,
			y = 8,
			width = 5,
			height = 1,
			class = "label",
			label = "Custom ASS Tags:",
		},
		{
			x = 0,
			y = 9,
			width = 30,
			height = 3,
			name = "usrtgs",
			class = "edit",
			value = config.c.user_tags,
		},
	}
	Buttons = { "Save", "Cancel" }
	Pressed, Res = ADD(GUI, Buttons)
	if Pressed == "Cancel" then
		AK()
	elseif Pressed == "Save" then
		config.c.svg2ass_path = Res.svgpth
		config.c.svg2ass_parameters = Res.svgopt
		config.c.user_tags = Res.usrtgs
		config:write()
	end
end

local function check_svg2ass(path)
	local exitcode = os.execute(path .. " -h")
	return exitcode
end

local function string2time(timecode)
	timecode = timecode:gsub("(%d):(%d%d):(%d%d)%.(%d%d)", function(a, b, c, d)
		return d * 10 + c * 1000 + b * 60000 + a * 3600000
	end)
	return timecode
end

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

local function run_cmd(command)
	local handle = io.popen(command)
	local result = handle:read("*a")
	handle:close()
	return result
end

local function main(subs, sel)
	config:load()
	local exitcode = check_svg2ass(config.c.svg2ass_path)
	if not exitcode then
		aegisub.log(
			"svg2ass not found in the path provided in the config.\nMake sure that svg2ass is available in the path defined.\n"
		)
		return
	end
	if #sel ~= 1 then
		aegisub.log(
			"You must select exactly one line\nThat line's start time, end time and style will be copied to resulting lines."
		)
		return
	end
	local ffilter = "SVG Files (.svg)|*.svg"
	local script_dir = aegisub.decode_path("?script")
	local fname = aegisub.dialog.open("Select svg file", "", script_dir, ffilter, false, true)
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
					.. ' "'
					.. fname
					.. '" | tac'
				local result = run_cmd(command)
				for j in result:gmatch("[^\n]+") do
					local line2 = string2line(j)
					local primary_color = line2.text:match("\\1c&H%x+&"):gsub("\\1c&", "\\c&")
					local tags = "{\\an7\\pos(0,0)" .. config.c.user_tags .. primary_color .. "\\p1}"
					local text = line2.text:gsub("{\\[^}]-}", "")
					line2.text = tags .. text
					subs[-i] = line2
				end
			end
		end
	end
end

aegisub.register_macro(script_name .. "/" .. "Run", script_description, main)
aegisub.register_macro(script_name .. "/" .. "Config", script_description, config_setup)
