require("karaskel")
local karaskel = karaskel
local aegisub = aegisub

-- SCRIPT PROPERTIES
script_name = "Wano Sign"
script_author = "PhosCity"
script_version = "0.0.1"
script_description = "Wano Sign"

-- MAIN PROCESSING FUNCTIONS
local function numberClipLines(subs, sel)
	local clips = {}
	local count = 1
	for _, i in ipairs(sel) do
		if subs[i].class == "dialogue" and subs[i].actor == "Clip" then
			local line = subs[i]
			line.effect = line.effect .. count
			line.comment = true
			count = count + 1
			subs[i] = line
			table.insert(clips, line.text:match("\\clip%([%d%a%s.-]+%)"))
		end
	end
	return clips
end

local function numberSignLines(subs, sel)
	local count, layer = nil, nil
	for _, i in ipairs(sel) do
		if subs[i].class == "dialogue" and subs[i].actor == "Mask" then
			local line = subs[i]
			if line.layer ~= layer then
				layer = line.layer
				count = 1
			end
			line.effect = line.effect .. count
			count = count + 1
			subs[i] = line
		end
	end
end

local function numberTextLines(subs, sel)
	local count = 1
	for _, i in ipairs(sel) do
		if subs[i].class == "dialogue" and subs[i].actor == "Text" then
			local line = subs[i]
			line.effect = line.effect .. count
			count = count + 1
			subs[i] = line
		end
	end
end

local function main(subs, sel)
	local clips = numberClipLines(subs, sel)
	-- for j = 1, #clips do
	--   aegisub.log(clips[j])
	--   aegisub.log("\n")
	-- end

	numberSignLines(subs, sel)
	numberTextLines(subs, sel)

	for _, i in ipairs(sel) do
		if subs[i].class == "dialogue" then
			local line = subs[i]
			if line.actor == "Line" or line.actor == "Text" then
				local klip = clips[tonumber(line.effect)]
				if klip then
					line.text = "{" .. klip .. "}" .. line.text
					line.text = line.text:gsub("}{", "")
				else
					line.effect = ""
				end
				subs[i] = line
			end
		end
	end
end

--Register macro
aegisub.register_macro(script_author .. "/" .. script_name, script_description, main)
