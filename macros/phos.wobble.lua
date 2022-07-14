-- Script information
script_name = "Wobble text"
script_description = "Converts a text to a shape and adds wobbling."
script_author = "PhosCity"
script_version = "1.4.4"
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

-- UI configuration template
-- stylua: ignore start
local config_template = {
	{ class = "label", x = 0, y = 0, width = 1, height = 1, label = "Wobble frequency: ", },
	{ class = "floatedit",
		name = "wobble_frequency_x",
		x = 1, y = 0,
		width = 1, height = 1,
		hint = "Horizontal wobbling frequency in percent",
		value = 0, min = 0, max = 100, step = 0.5,
	},
	{
		class = "floatedit",
		name = "wobble_frequency_y",
		x = 2, y = 0,
		width = 1, height = 1,
		hint = "Vertical wobbling frequency in percent",
		value = 0, min = 0, max = 100, step = 0.5,
	},
	{ class = "label", x = 0, y = 1, width = 1, height = 1, label = "Wobble strength: ", },
	{
		class = "floatedit",
		name = "wobble_strength_x",
		x = 1, y = 1,
		width = 1, height = 1,
		hint = "Horizontal wobbling strength in pixels",
		value = 0, min = 0, max = 100, step = 0.01,
	},
	{
		class = "floatedit",
		name = "wobble_strength_y",
		x = 2, y = 1,
		width = 1, height = 1,
		hint = "Vertical wobbling strength in pixels",
		value = 0, min = 0, max = 100, step = 0.01,
	},
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

	if (frequency_x >= 0 and config.wobble_strength_x >= 0) or (frequency_y >= 0 and config.wobble_strength_y >= 0) then
		text_shape = Yutils.shape.filter(Yutils.shape.split(Yutils.shape.flatten(text_shape), 1), function(x, y)
			return x + math.sin(y * frequency_x * math.pi * 2) * config.wobble_strength_x,
				y + math.sin(x * frequency_y * math.pi * 2) * config.wobble_strength_y
		end)
		return text_shape
	end
end

local function ibus(value)
	if not value then
		return nil
	elseif value == "1" then
		return true
	elseif value == "0" then
		return false
	end
end

local function main(subs, sel, config)
	local meta, styles = karaskel.collect_head(subs, false)

	for _, i in ipairs(sel) do
		if subs[i].class == "dialogue" then
			local line = subs[i]
			if line.text == "" or line.text:gsub("{\\[^}]-}", "") == "" then
				aegisub.log("No text detected.")
				aegisub.cancel()
			end
			karaskel.preproc_line(subs, meta, styles, line)
			-- get tag values
			local tags = line.text:match("{\\[^}]-}")
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
			if tonumber(align) ~= 7 then
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
			subs[i] = line
		end
	end
end

-- Save UI configuration to template
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
	local ok, config = aegisub.dialog.display(config_template, { "Calculate", "Cancel" })
	if ok == "Cancel" then
		aegisub.cancel()
	elseif ok == "Calculate" then
		save_values(config_template, config)
		main(subs, sel, config)
	end
end

-- Register macro to Aegisub
if haveDepCtrl then
	depRec:registerMacro(load_macro)
else
	aegisub.register_macro(script_author .. "/" .. script_name, script_description, load_macro)
end
