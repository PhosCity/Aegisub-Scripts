-- Script information
script_name = "Wobble text"
script_description = "Converts a text to a shape and adds wobbling."
script_author = "PhosCity"
script_version = "2.0.2"
script_namespace = "phos.wobble"

local haveDepCtrl, DependencyControl, depRec = pcall(require, "l0.DependencyControl")
if haveDepCtrl then
	depRec = DependencyControl({
		feed = "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
		{
			"Yutils",
			"karaskel",
		},
	})
	Yutils = depRec:requireModules()
else
	Yutils = include("Yutils.lua")
	require("karaskel")
end
local align_msg_shown = false


-- UI configuration template
-- stylua: ignore start
local config_template = {
	{ class = "label",     x = 0, y = 0, width = 1, height = 1, label = "Wobble frequency: ", },
	{ class = "floatedit", x = 1, y = 0, width = 1, height = 1, hint  = "Horizontal wobbling frequency in percent", value = 0, min = 0, max = 100, step = 0.5, name = "wobble_frequency_x" },
	{ class = "floatedit", x = 2, y = 0, width = 1, height = 1, hint  = "Vertical wobbling frequency in percent",   value = 0, min = 0, max = 100, step = 0.5, name = "wobble_frequency_y" },
	{ class = "label",     x = 0, y = 1, width = 1, height = 1, label = "Wobble strength: ", },
	{ class = "floatedit", x = 1, y = 1, width = 1, height = 1, hint  = "Horizontal wobbling strength in pixels",   value = 0, min = 0, max = 100, step = 0.01, name = "wobble_strength_x" },
	{ class = "floatedit", x = 2, y = 1, width = 1, height = 1, hint  = "Vertical wobbling strength in pixels",     value = 0, min = 0, max = 100, step = 0.01, name = "wobble_strength_y" },
}

local animate_template = {
	{ class = "label",     x = 1, y = 0, width = 1, height = 1, label = "Start Value", },
	{ class = "label",     x = 2, y = 0, width = 1, height = 1, label = "End Value", },
	{ class = "label",     x = 3, y = 0, width = 1, height = 1, label = "Accel", },
	{ class = "label",     x = 0, y = 1, width = 1, height = 1, label = "Frequency x", },
	{ class = "floatedit", x = 1, y = 1, width = 1, height = 1, hint  = "Horizontal wobbling frequency in percent", value = 0, min = 0, max = 100, step = 0.5, name = "freq_x_start" },
	{ class = "floatedit", x = 2, y = 1, width = 1, height = 1, hint  = "Horizontal wobbling frequency in percent", value = 0, min = 0, max = 100, step = 0.5, name = "freq_x_end" },
	{ class = "floatedit", x = 3, y = 1, width = 1, height = 1, hint  = "Accel for frequency x",                    value = 1, name = "freq_x_accel" },
	{ class = "label",     x = 0, y = 2, width = 1, height = 1, label = "Frequency y", },
	{ class = "floatedit", x = 1, y = 2, width = 1, height = 1, hint  = "Vertical wobbling frequency in percent",   value = 0, min = 0, max = 100, step = 0.5, name = "freq_y_start" },
	{ class = "floatedit", x = 2, y = 2, width = 1, height = 1, hint  = "Vertical wobbling frequency in percent",   value = 0, min = 0, max = 100, step = 0.5, name = "freq_y_end" },
	{ class = "floatedit", x = 3, y = 2, width = 1, height = 1, hint  = "Accel for frequency y",                    value = 1, name = "freq_y_accel" },

	{ class = "label",     x = 0, y = 3, width = 1, height = 1, label = "Strength x", },
	{ class = "floatedit", x = 1, y = 3, width = 1, height = 1, hint  = "Horizontal wobbling strength in pixels",   value = 0, min = 0, max = 100, step = 0.01, name = "strength_x_start" },
	{ class = "floatedit", x = 2, y = 3, width = 1, height = 1, hint  = "Horizontal wobbling strength in pixels",   value = 0, min = 0, max = 100, step = 0.01, name = "strength_x_end" },
	{ class = "floatedit", x = 3, y = 3, width = 1, height = 1, hint  = "Accel for strength x",                     value = 1, name = "strength_x_accel" },
	{ class = "label",     x = 0, y = 4, width = 1, height = 1, label = "Strength y", },
	{ class = "floatedit", x = 1, y = 4, width = 1, height = 1, hint  = "Vertical wobbling strength in pixels",     value = 0, min = 0, max = 100, step = 0.01, name = "strength_y_start" },
	{ class = "floatedit", x = 2, y = 4, width = 1, height = 1, hint  = "Vertical wobbling strength in pixels",     value = 0, min = 0, max = 100, step = 0.01, name = "strength_y_end" },
	{ class = "floatedit", x = 3, y = 4, width = 1, height = 1, hint  = "Accel for strength y",                     value = 1, name = "strength_y_accel" },
}

local wave_template = {
	{ class = "label",     x = 0, y = 0, width = 1, height = 1, label = "Wobble frequency: ", },
	{ class = "floatedit", x = 1, y = 0, width = 1, height = 1, hint  = "Horizontal wobbling frequency in percent", value = 0, min = 0, max = 100, step = 0.5, name = "wobble_frequency_x" },
	{ class = "floatedit", x = 2, y = 0, width = 1, height = 1, hint  = "Vertical wobbling frequency in percent",   value = 0, min = 0, max = 100, step = 0.5, name = "wobble_frequency_y" },
	{ class = "label",     x = 0, y = 1, width = 1, height = 1, label = "Wobble strength: ", },
	{ class = "floatedit", x = 1, y = 1, width = 1, height = 1, hint  = "Horizontal wobbling strength in pixels",   value = 0, min = 0, max = 100, step = 0.01, name = "wobble_strength_x" },
	{ class = "floatedit", x = 2, y = 1, width = 1, height = 1, hint  = "Vertical wobbling strength in pixels",     value = 0, min = 0, max = 100, step = 0.01, name = "wobble_strength_y" },
  { class = "label",     x = 0, y = 2, width = 1, height = 1, label = "Wave" },
  { class = "floatedit", x = 1, y = 2, width = 1, height = 1, hint  = "Waving speed. (Values between 1-5)",       value = 0, min = 0, max = 5,   step = 0.1, name = "waving_speed" },
}
-- stylua: ignore end

-- When percentage_value is 1, it returns ~0.0001 and for 100, it returns ~2.5
local function frequency_value(percentage_value)
	if percentage_value < 50 then
		return 0.0000825 * 1.212 ^ percentage_value
	else
		return (1.25 * percentage_value) / 50
	end
end

local function interpolate(start_value, end_value, accel, sel_n, i)
	local factor = (i - 1) ^ accel / (sel_n - 1) ^ accel
	if factor <= 0 then
		return start_value
	elseif factor >= 1 then
		return end_value
	else
		return factor * (end_value - start_value) + start_value
	end
end

-- Progress bar, title etc
local function progress(index, sel_n, title)
	if aegisub.progress.is_cancelled() then
		aegisub.cancel()
	end
	aegisub.progress.task("Processing line " .. index .. "/" .. sel_n)
	aegisub.progress.set(100 * index / sel_n)
	aegisub.progress.title(title)
end

-- Actual wobbling happens here
local function wobble(fontname, fontsize, bold, italic, underline, strikeout, scale_x, scale_y, spacing, text, config)
	local frequency_x = frequency_value(config.wobble_frequency_x)
	local frequency_y = frequency_value(config.wobble_frequency_y)
	local stripped_text = text:gsub("{\\[^}]-}", "")
	-- Calculate shape from configuration settings
	local text_shape
	if text:match("^{[^}]-\\p1") then
		text_shape = stripped_text
	else
		text_shape = Yutils.decode
			.create_font(fontname, bold, italic, underline, strikeout, fontsize, scale_x / 100, scale_y / 100, spacing)
			.text_to_shape(stripped_text)
	end

	if (frequency_x > 0 and config.wobble_strength_x > 0) or (frequency_y > 0 and config.wobble_strength_y > 0) then
		text_shape = Yutils.shape.filter(Yutils.shape.split(Yutils.shape.flatten(text_shape), 1), function(x, y)
			return x + math.sin(y * frequency_x * math.pi * 2 + config.waving_speed) * config.wobble_strength_x,
				y + math.sin(x * frequency_y * math.pi * 2 + config.waving_speed) * config.wobble_strength_y
		end)
	end
	return text_shape
end

-- convert value to boolean for bold, italics, strikeout and underline tag
local function ibus(value)
	if not value then
		return nil
	elseif value == "1" then
		return true
	elseif value == "0" then
		return false
	end
end

-- Collects data from the current line that'll be used for making shape
local function make_shape(subs, line, config)
	local meta, styles = karaskel.collect_head(subs, false)
	karaskel.preproc_line(subs, meta, styles, line)
	-- get tag values
	local tags = line.text:match("{\\[^}]-}") or ""
	local align = tags:match("\\an([1-9])") or line.styleref.align
	local fontname = tags:match("\\fn([^}\\]+)") or line.styleref.fontname
	local fontsize = tags:match("\\fs([%d]+)") or line.styleref.fontsize
	local scale_x = tags:match("\\fscx([^}\\]+)") or line.styleref.scale_x
	local scale_y = tags:match("\\fscy([^}\\]+)") or line.styleref.scale_y
	local spacing = tags:match("\\fsp([^}\\]+)") or line.styleref.spacing
	local italic = ibus(tags:match("\\i([01])[\\}]")) or line.styleref.italic
	local bold = ibus(tags:match("\\b([01])[\\}]")) or line.styleref.bold
	local underline = ibus(tags:match("\\u([01])[\\}]")) or line.styleref.underline
	local strikeout = ibus(tags:match("\\s([01])[\\}]")) or line.styleref.strikeout

	-- Check if the line has alignment of 7. Anything else and the position of output line may not be the same as the input line
	if tonumber(align) ~= 7 and align_msg_shown == false then
		align_msg_shown = true
		aegisub.log(
			"The resulting line may have different position because the alignment is not 7.\nThe script will proceed the operation but if position matters to you, please use '\\an7' in the line.\n"
		)
	end

	local text_shape = wobble(
		fontname,
		tonumber(fontsize),
		bold,
		italic,
		underline,
		strikeout,
		tonumber(scale_x),
		tonumber(scale_y),
		tonumber(spacing),
		line.text,
		config
	)

	local original_tags = ""
	if line.text:match("{\\[^}]-}") then
		original_tags = line.text:match("{\\[^}]-}")
		original_tags = original_tags
			:gsub("\\fn[^}\\]+", "")
			:gsub("\\fs[%d]+", "")
			:gsub("\\i[01]", "")
			:gsub("\\b[01]", "")
			:gsub("\\u[01]", "")
			:gsub("\\s[01]", "")
			:gsub("\\fscx[%d.]+", "")
			:gsub("\\fscy[%d.]+", "")
			:gsub("\\fsp[%d.]+", "")
	end

	local new_tags = original_tags .. "{\\fscx100\\fscy100\\p1}"
	new_tags = new_tags:gsub("}{", "")

	line.text = new_tags .. text_shape
	return line
end

local function main(subs, sel, config)
	for x, i in ipairs(sel) do
		progress(x, #sel, "Wobbling...")
		local line = subs[i]
		if line.text == "" or line.text:gsub("{\\[^}]-}", "") == "" then
			aegisub.log("No text detected.")
			aegisub.cancel()
		end
		line = make_shape(subs, line, config)
		subs[i] = line
	end
end

local function wave(subs, sel, config)
	local speed_increment = config.waving_speed

	for x, i in ipairs(sel) do
		progress(x, #sel, "This may take some time...")
		local line = subs[i]
		if line.text == "" or line.text:gsub("{\\[^}]-}", "") == "" then
			aegisub.log("No text detected.")
			aegisub.cancel()
		end
		line = make_shape(subs, line, config)
		subs[i] = line

		config.waving_speed = config.waving_speed + speed_increment
	end
end

local function animate(subs, sel, config)
	for x, i in ipairs(sel) do
		progress(x, #sel, "This may take some time...")
		local line = subs[i]
		if
			(config.freq_x_start >= 0 and config.strength_x_start >= 0)
			or (config.freq_y_start >= 0 and config.strength_y_start >= 0)
		then
			config.wobble_frequency_x =
				interpolate(config.freq_x_start, config.freq_x_end, config.freq_x_accel, #sel, x)
			config.wobble_frequency_y =
				interpolate(config.freq_y_start, config.freq_y_end, config.freq_y_accel, #sel, x)
			config.wobble_strength_x =
				interpolate(config.strength_x_start, config.strength_x_end, config.strength_x_accel, #sel, x)
			config.wobble_strength_y =
				interpolate(config.strength_y_start, config.strength_y_end, config.strength_y_accel, #sel, x)

			line = make_shape(subs, line, config)
			subs[i] = line
		end
	end
end

-- Save GUI configuration
local function save_values(tbl, config)
	local config_template_n, config_template_entry = #tbl, nil
	for config_key, config_value in pairs(config) do
		for i = 1, config_template_n do
			config_template_entry = tbl[i]
			if config_template_entry.name == config_key then
				if config_template_entry.value then
					config_template_entry.value = config_value
				elseif config_template_entry.text then
					config_template_entry.text = config_value
				end
				break
			end
		end
	end
end

-- Macro execution
local function load_macro(subs, sel)
	align_msg_shown = false
	local ok2
	local ok, config = aegisub.dialog.display(
		config_template,
		{ "Calculate", "Wave", "Animate", "Cancel" },
		{ ["cancel"] = "Cancel" }
	)
	if ok == "Calculate" then
		config.waving_speed = 0
		save_values(config_template, config)
		main(subs, sel, config)
	elseif ok == "Animate" then
		config.waving_speed = 0
		ok2, config = aegisub.dialog.display(animate_template, { "Animate", "Cancel" }, { ["cancel"] = "Cancel" })
		if ok2 then
			save_values(animate_template, config)
			animate(subs, sel, config)
		end
	elseif ok == "Wave" then
		ok2, config = aegisub.dialog.display(wave_template, { "Apply", "Cancel" }, { ["cancel"] = "Cancel" })
		if ok2 then
			save_values(wave_template, config)
			wave(subs, sel, config)
		end
	end
end

-- Register macro to Aegisub
if haveDepCtrl then
	depRec:registerMacro(load_macro)
else
	aegisub.register_macro(script_author .. "/" .. script_name, script_description, load_macro)
end
