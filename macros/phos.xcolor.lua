--Script properties
script_name = "Xcolor"
script_author = "PhosCity"
script_version = "1.0.2"
script_description = "Eyedropper for Linux."
script_namespace = "phos.xcolor"

-- Dependencies
-- gpick

-- Altermative for gpick = xcolor
-- command = xcolor -c "&H%{02Hb}%{02Hg}%{02Hr}&"
-- command = gpick -pso --no-newline | sed "s|#\\(..\\)\\(..\\)\\(..\\)|\\&H\\3\\2\\1\\&|"

local haveDepCtrl, DependencyControl, depRec = pcall(require, "l0.DependencyControl")
if haveDepCtrl then
	depRec = DependencyControl({
		feed = "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/personal/DependencyControl.json",
	})
end

local function isRunnable()
	local pathsep = package.config:sub(1, 1)
	if pathsep == "\\" then
		aegisub.log("This script is only to be used in Linux.")
		aegisub.cancel()
	end

	local installed = os.execute("which gpick")
	if not installed then
		aegisub.log("The program gpick is not installed\nPlease install it before using it.\n")
		aegisub.cancel()
	end
end

local function get_color()
	local handle = io.popen("gpick -pso --no-newline")
	local result = handle:read("*a")
	handle:close()
	result = result:gsub("#(%x%x)(%x%x)(%x%x)", "&H%3%2%1&")
	if result:match("&H%x+&") then
		return result
	else
		aegisub.cancel()
	end
end

local function color_tag(text, color, color_type)
	local tags = ""
	if text:match("^{\\[^}]*}") then
		tags = text:match("^({\\[^}]*})")
	end
	text = text:gsub("^{\\[^}]*}", "")
	if color then
		tags = tags:gsub("\\1?" .. color_type .. "&H%x+&", "")
		tags = tags .. "{\\" .. color_type .. color .. "}"
		tags = tags:gsub("}{", "")
	end
	return (tags .. text)
end

local function main(subs, sel)
	isRunnable()
	local pressed, result = aegisub.dialog.display({
		{ x = 0, y = 0, class = "checkbox", label = "Fill", name = "fill" },
		{ x = 0, y = 1, class = "checkbox", label = "Border", name = "border" },
		{ x = 0, y = 2, class = "checkbox", label = "Shadow", name = "shadow" },
	}, { "Apply", "Cancel" }, { ["ok"] = "Apply", ["Cancel"] = "Cancel" })
	if pressed then
		if result.fill or result.border or result.shadow then
			for _, i in ipairs(sel) do
				if subs[i].class == "dialogue" then
					local line = subs[i]
					local color = get_color()
					if result.fill then
						line.text = color_tag(line.text, color, "c")
					end
					if result.border then
						line.text = color_tag(line.text, color, "3c")
					end
					if result.shadow then
						line.text = color_tag(line.text, color, "4c")
					end
					subs[i] = line
				end
			end
		end
	end
end

--Register macro
if haveDepCtrl then
	depRec:registerMacro(main)
else
	aegisub.register_macro(script_name, script_description, main)
end
