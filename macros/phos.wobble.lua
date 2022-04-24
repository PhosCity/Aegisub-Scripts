-- Script information
script_name = "Wobble text"
script_description = "Converts a text to a shape and adds wobbling."
script_author = "PhosCity"
script_version = "1.3.2"
script_namespace = "phos.wobble"

-- Credits to Youka for this
require("karaskel")

-- local Yutils
local haveDepCtrl, DependencyControl, depRec = pcall(require, "l0.DependencyControl")
if haveDepCtrl then
	depRec = DependencyControl({
		feed = "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
		{
			"Yutils",
		},
	})
	Yutils = depRec:requireModules()
else
	Yutils = include("Yutils.lua")
end

-- UI configuration template
local config_template = {
	{
		class = "label",
		x = 0,
		y = 0,
		width = 1,
		height = 1,
		label = "Wobble frequency: ",
	},
	{
		class = "floatedit",
		name = "wobble_frequency_x",
		x = 1,
		y = 0,
		width = 1,
		height = 1,
		hint = "Horizontal wobbling frequency in percent",
		value = 0,
		min = 0,
		max = 10,
		step = 0.00001,
	},
	{
		class = "floatedit",
		name = "wobble_frequency_y",
		x = 2,
		y = 0,
		width = 1,
		height = 1,
		hint = "Vertical wobbling frequency in percent",
		value = 0,
		min = 0,
		max = 10,
		step = 0.00001,
	},
	{
		class = "label",
		x = 0,
		y = 1,
		width = 1,
		height = 1,
		label = "Wobble strength: ",
	},
	{
		class = "floatedit",
		name = "wobble_strength_x",
		x = 1,
		y = 1,
		width = 1,
		height = 1,
		hint = "Horizontal wobbling strength in pixels",
		value = 0,
		min = 0,
		max = 100,
		step = 0.01,
	},
	{
		class = "floatedit",
		name = "wobble_strength_y",
		x = 2,
		y = 1,
		width = 1,
		height = 1,
		hint = "Vertical wobbling strength in pixels",
		value = 0,
		min = 0,
		max = 100,
		step = 0.01,
	},
}

local function wobble(fontname, fontsize, bold, italic, underline, strikeout, scale_x, scale_y, spacing, text, config)
	-- Calculate shape from configuration settings
	local text_shape = Yutils.decode.create_font(
		fontname,
		bold,
		italic,
		underline,
		strikeout,
		fontsize,
		scale_x / 100,
		scale_y / 100,
		spacing
	).text_to_shape(text)
	if
		(config.wobble_frequency_x > 0 and config.wobble_strength_x > 0)
		or (config.wobble_frequency_y > 0 and config.wobble_strength_y > 0)
	then
		text_shape = Yutils.shape.filter(Yutils.shape.split(Yutils.shape.flatten(text_shape), 1), function(x, y)
			return x + math.sin(y * config.wobble_frequency_x * math.pi * 2) * config.wobble_strength_x,
				y + math.sin(x * config.wobble_frequency_y * math.pi * 2) * config.wobble_strength_y
		end)
		return text_shape
	end
end

local function make_shape(subs, sel, config)
	local meta, styles = karaskel.collect_head(subs, false)
	-- local text_shape = wobble(subs, sel, config)
	for _, j in ipairs(sel) do
		if subs[j].class == "dialogue" then
			local line = subs[j]
			karaskel.preproc_line(subs, meta, styles, line)
			-- get styledata
			local fontname = line.styleref.fontname
			local fontsize = line.styleref.fontsize
			local bold = line.styleref.bold
			local italic = line.styleref.italic
			local underline = line.styleref.underline
			local strikeout = line.styleref.strikeout
			local scale_x = line.styleref.scale_x
			local scale_y = line.styleref.scale_y
			local spacing = line.styleref.spacing
			-- get line data
			local text = line.text:gsub("{\\[^}]-}", "")
			if line.text:match("\\fn([^}\\]+)") then
				fontname = line.text:match("\\fn([^}\\]+)")
			end
			if line.text:match("\\fs([%d]+)") then
				fontsize = line.text:match("\\fs([%d]+)")
			end
			if line.text:match("\\b[01][\\}]") then
				local b = line.text:match("\\b([01])[\\}]")
				if b == "1" then
					bold = true
				else
					bold = false
				end
			end
			if line.text:match("\\i[01][\\}]") then
				local i = line.text:match("\\i([01])[\\}]")
				if i == "1" then
					italic = true
				else
					italic = false
				end
			end
			if line.text:match("\\u[01][\\}]") then
				local u = line.text:match("\\u([01])[\\}]")
				if u == "1" then
					underline = true
				else
					underline = false
				end
			end
			if line.text:match("\\s[01][\\}]") then
				local s = line.text:match("\\s([01])[\\}]")
				if s == "1" then
					strikeout = true
				else
					strikeout = false
				end
			end
			if line.text:match("\\fscx([^}\\]+)") then
				scale_x = line.text:match("\\fscx([^}\\]+)")
			end
			if line.text:match("\\fscy([^}\\]+)") then
				scale_y = line.text:match("\\fscy([^}\\]+)")
			end
			if line.text:match("\\fsp([^}\\]+)") then
				spacing = line.text:match("\\fsp([^}\\]+)")
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
				text,
				config
			)
			local tags = "{\\p1}"
			if line.text:match("{\\[^}]-}") then
				tags = line.text:match("{\\[^}]-}") .. tags
			end
			tags = tags
				:gsub("\\fn[^}\\]+", "")
				:gsub("\\fs[%d]+", "")
				:gsub("\\b[01]", "")
				:gsub("\\i[01]", "")
				:gsub("\\u[01]", "")
				:gsub("\\s[01]", "")
				:gsub("\\fscx[%d.]+", "")
				:gsub("\\fscy[%d.]+", "")
				:gsub("\\fsp[%d.]+", "")
				:gsub("\\fsp[%d.]+", "")
				:gsub("}{", "")

			line.text = tags .. text_shape
			subs[j] = line
		end
	end
end

-- Macro execution
local function load_macro(subs, sel)
	-- Show UI
	local ok, config = aegisub.dialog.display(config_template, { "Calculate", "Cancel" })

	-- Save UI configuration to template
	local config_template_n, config_template_entry = #config_template, nil
	for config_key, config_value in pairs(config) do
		for i = 1, config_template_n do
			config_template_entry = config_template[i]
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

	if ok == "Cancel" then
		aegisub.cancel()
	end
	if ok == "Calculate" then
		make_shape(subs, sel, config)
	end
end

-- Register macro to Aegisub

if haveDepCtrl then
	depRec:registerMacro(load_macro)
else
	aegisub.register_macro(script_author .. "/" .. script_name, script_description, load_macro)
end
