-- SCRIPT PROPERTIES
script_name = "Timing Assistant"
script_description = "A second brain for timers"
script_author = "PhosCity"
script_version = "1.0.4"
script_namespace = "phos.timingassistant"

DependencyControl = require("l0.DependencyControl")
local depctrl = DependencyControl({})

local default_config = {
	start = {
		leadin = 120,
		keysnap = 300,
		linelink = 620,
	},
	final = {
		leadout = 400,
		keysnap_behind = 300,
		keysnap_after = 900,
	},
	debug = false,
	automove = false,
}

local config = depctrl:getConfigHandler({
	start = {
		leadin = default_config.start.leadin,
		keysnap = default_config.start.keysnap,
		linelink = default_config.start.linelink,
	},
	final = {
		leadout = default_config.final.leadout,
		keysnap_behind = default_config.final.keysnap_behind,
		keysnap_after = default_config.final.keysnap_after,
	},
	debug = default_config.debug,
	automove = default_config.automove,
})

local function config_setup()
	-- stylua: ignore start
	local CONFIG_GUI = {
		{ x = 0,	y = 0,		width = 1,	height = 1,	class = "label",	label = "Start:", },
		{ x = 0,	y = 1,		width = 5,	height = 1,	class = "label",	label = "Lead in amount from exact start", },
		{ x = 0,	y = 2,		width = 1,	height = 1,	class = "label",	label = "Lead in:", },
		{ x = 1,	y = 2,		width = 1,	height = 1,	class = "intedit",	name = "start_leadin",		value = config.c.start.leadin, },
		{ x = 3,	y = 2,		width = 1,	height = 1,	class = "label",	label = "Recommended value: 100-150 ms", },
		{ x = 0,	y = 3,		width = 5,	height = 1,	class = "label",	label = "Time to snap to keyframe from exact start", },
		{ x = 0,	y = 4,		width = 1,	height = 1,	class = "label",	label = "Key Snap:", },
		{ x = 1,	y = 4,		width = 1,	height = 1,	class = "intedit",	name = "start_snap",		value = config.c.start.keysnap, },
		{ x = 3,	y = 4,		width = 1,	height = 1,	class = "label",	label = "Recommended value: ~2*leadin", },
		{ x = 0,	y = 5,		width = 5,	height = 1,	class = "label",	label = "Time from exact start of current line to end-time of previous line to link", },
		{ x = 0,	y = 6,		width = 1,	height = 1,	class = "label",	label = "Line Link:", },
		{ x = 1,	y = 6,		width = 1,	height = 1,	class = "intedit",	name = "start_link",		value = config.c.start.linelink, },
		{ x = 3,	y = 6,		width = 1,	height = 1,	class = "label",	label = "Recommended value: ~500+leadin", },
		{ x = 0,	y = 8,		width = 1,	height = 1,	class = "label",	label = "End:", },
		{ x = 0,	y = 9,		width = 5,	height = 1,	class = "label",	label = "Lead out amount from exact end", },
		{ x = 0,	y = 10,		width = 1,	height = 1,	class = "label",	label = "Lead out:", },
		{ x = 1,	y = 10,		width = 1,	height = 1,	class = "intedit",	name = "end_leadout",		value = config.c.final.leadout, },
		{ x = 3,	y = 10,		width = 1,	height = 1,	class = "label", 	label = "Recommended value: 350-450 ms", },
		{ x = 0,	y = 11,		width = 5,	height = 1,	class = "label", 	label = "Time to snap to keyframe before the exact end", },
		{ x = 0,	y = 12,		width = 1,	height = 1,	class = "label", 	label = "Key Snap Behind:", },
		{ x = 1,	y = 12,		width = 1,	height = 1,	class = "intedit",	name = "end_snap_behind",	value = config.c.final.keysnap_behind, },
		{ x = 3,	y = 12,		width = 1,	height = 1,	class = "label",	label = "Recommended value: 100-300 ms", },
		{ x = 0,	y = 13,		width = 5,	height = 1,	class = "label", 	label = "Time to snap to keyframe after the exact end", },
		{ x = 0,	y = 14,		width = 1,	height = 1,	class = "label", 	label = "Key Snap Ahead:", },
		{ x = 1,	y = 14,		width = 1,	height = 1,	class = "intedit",	name = "end_snap_ahead",	value = config.c.final.keysnap_after, },
		{ x = 3,	y = 14,		width = 1,	height = 1,	class = "label",	label = "Recommended value: 800-1000 ms", },
		{ x = 0,	y = 16,		width = 5,	height = 1,	class = "checkbox",	label = "Auto-move to next line after making changes", name="automove", value = config.c.automove},
		{ x = 3,	y = 0,		width = 1,	height = 1,	class = "checkbox",	label = "Debug",	name = "dbug",		value = config.c.debug,	hint = "Disply debugging messages" },

	}
	-- stylua: ignore end
	local buttons = { "Save", "Reset", "Cancel" }
	local pressed, result = aegisub.dialog.display(CONFIG_GUI, buttons)
	if pressed == "Cancel" then
		aegisub.cancel()
	elseif pressed == "Save" then
		local opt = config.c
		opt.start.leadin = result.start_leadin
		opt.start.keysnap = result.start_snap
		opt.start.linelink = result.start_link
		opt.final.leadout = result.end_leadout
		opt.final.keysnap_behind = result.end_snap_behind
		opt.final.keysnap_after = result.end_snap_ahead
		opt.automove = result.automove
		opt.debug = result.dbug
		config:write()
	elseif pressed == "Reset" then
		local opt = config.c
		opt.start.leadin = default_config.start.leadin
		opt.start.keysnap = default_config.start.keysnap
		opt.start.linelink = default_config.start.linelink
		opt.final.leadout = default_config.final.leadout
		opt.final.keysnap_behind = default_config.final.keysnap_behind
		opt.final.keysnap_after = default_config.final.keysnap_after
		opt.automove = default_config.automove
		opt.debug = default_config.debug
		config:write()
	end
end

local function get_frame(time)
	return aegisub.frame_from_ms(time)
end

local function get_time(frame)
	return aegisub.ms_from_frame(frame)
end

local function debug_msg(msg)
	local debug = config.c.debug
	if debug then
		aegisub.log(msg .. "\n")
	end
end

local function is_keyframe(time)
	local keyframes = aegisub.keyframes()
	local frame = get_frame(time)
	for _, kf in ipairs(keyframes) do
		if frame == kf then
			return true
		end
	end
	return false
end

local function calculate_cps(line)
	local text = line.text
	local duration = (line.end_time - line.start_time) / 1000
	local char = text:gsub("%b{}", ""):gsub("\\[Nnh]", "*"):gsub("%s?%*+%s?", " "):gsub("[%s%p]", "")
	local linelen = char:len()
	local cps = math.ceil(linelen / duration)
	return cps
end

local function prev_next_keyframe(time)
	local previous_keyframe, next_keyframe
	local keyframes = aegisub.keyframes()
	local current_kf = get_frame(time)
	for k, kf in ipairs(keyframes) do
		if kf < current_kf then
			previous_keyframe = keyframes[k]
		end
		if not next_keyframe and kf > current_kf then
			next_keyframe = keyframes[k]
		end
	end

	return previous_keyframe, next_keyframe
end

local function time_start(subs, sel, opt)
	for _, i in ipairs(sel) do
		if subs[i].class == "dialogue" then
			local line = subs[i]
			local snap, link, end_time_previous
			local start_time, end_time = aegisub.get_audio_selection()

			debug_msg("Start:")

			-- Determine if start time of current line is already snapped to keyframe and exit if it is
			local is_snapped = is_keyframe(start_time)
			if is_snapped then
				debug_msg("Line start was already snapped to keyframe")
				return
			end

			-- Determine the end time of previous line
			local previous_line = subs[i - 1]
			end_time_previous = previous_line.end_time

			-- Keyframe Snapping
			local previous_keyframe, next_keyframe = prev_next_keyframe(start_time)

			if math.abs(get_time(previous_keyframe) - start_time) < opt.start.keysnap then
				line.start_time = get_time(previous_keyframe)
				snap = true
				debug_msg("Keyframe snap behind")
			end
			if
				math.abs(get_time(next_keyframe) - start_time) < opt.start.keysnap and not is_keyframe(line.start_time)
			then
				line.start_time = get_time(next_keyframe)
				snap = true
				debug_msg("Keyframe snap ahead")
			end

			-- Link Linking
			if
				end_time_previous ~= nil
				and math.abs(end_time_previous - start_time) < opt.start.linelink
				and not is_keyframe(end_time_previous)
				and not previous_line.comment
			then
				previous_keyframe, next_keyframe = prev_next_keyframe(end_time_previous)
				local time_500_after_kf = get_time(previous_keyframe) + 500
				if start_time < end_time_previous and end_time_previous < time_500_after_kf then
					if not snap then
						line.start_time = start_time - opt.start.leadin
					end
					previous_line.end_time = get_time(previous_keyframe)
					debug_msg(
						"Link lines failed because a keyframe is close. Snap end of last line. Add lead in to current line."
					)
				elseif (start_time - opt.start.leadin) > (get_time(next_keyframe) - 500) then
					if not snap then
						line.start_time = get_time(next_keyframe) - 500
					end
					previous_line.end_time = line.start_time
					debug_msg("Link lines by ensuring that start time is 500 ms away from next keyframe.")
				else
					if not snap then
						line.start_time = start_time - math.min(opt.start.leadin, start_time - time_500_after_kf)
					end
					previous_line.end_time = line.start_time
					debug_msg("Link lines by adding appropriate lead in to current line.")
				end
				subs[i - 1] = previous_line
				link = true
			end

			-- Lead in
			if not snap and not link then
				line.start_time = start_time - opt.start.leadin
				debug_msg("Lead In")
			end

			line.end_time = end_time
			subs[i] = line
		end
	end
end

local function time_end(subs, sel, opt)
	for _, i in ipairs(sel) do
		if subs[i].class == "dialogue" then
			local line = subs[i]
			local _, end_time = aegisub.get_audio_selection()
			local snap
			debug_msg("\nEnd:")

			-- Determine if end time of current line is already snapped to keyframe and exit if it is
			local is_snapped = is_keyframe(end_time)
			if is_snapped then
				debug_msg("Line end was already snapped to keyframe")
				return
			end

			-- Find the previous and next keyframe for end time
			local previous_keyframe, next_keyframe = prev_next_keyframe(end_time)

			-- If the keyframe is somewhere between 850 to 1000 ms, check the cps
			-- If cps is less than 15, then add normal lead out or make the end time 500 ms far from keyframe whichever is lesser
			-- If cps is more than 15, then snap to keyframe
			local next_kf_dist = math.abs(get_time(next_keyframe) - end_time)
			local prev_kf_dist = math.abs(get_time(previous_keyframe) - end_time)
			if
				opt.final.keysnap_after >= 850
				and next_kf_dist >= 850
				and next_kf_dist <= opt.final.keysnap_after
				and prev_kf_dist > opt.final.keysnap_behind
			then
				local cps = calculate_cps(line)
				if cps <= 15 then
					line.end_time = end_time + math.min(opt.final.leadout, next_kf_dist - 500)
					debug_msg(
						"cps is less than 15.\nAdjusting end time so that it's 500 ms away from keyframe or adding lead out whichever is lesser."
					)
				else
					line.end_time = get_time(next_keyframe)
					debug_msg("cps is more than 15.\nSnapping to keyframe more than 850 ms away.")
				end
			else
				-- Keyframe Snapping
				if prev_kf_dist < opt.final.keysnap_behind then
					line.end_time = get_time(previous_keyframe)
					snap = true
					debug_msg("Keyframe snap behind")
				end
				if next_kf_dist < opt.final.keysnap_after and not is_keyframe(line.end_time) then
					line.end_time = get_time(next_keyframe)
					snap = true
					debug_msg("Keyframe snap ahead")
				end

				-- Lead out
				if not snap then
					line.end_time = end_time + opt.final.leadout
					debug_msg("Lead Out")
				end
			end

			subs[i] = line
		end
	end
end

local function time_both(subs, sel)
	if #sel ~= 1 then
		aegisub.log("You must select exactly one line\nThis is not a TPP replacement.")
		return
	end

	config:load()
	local opt = config.c

	time_start(subs, sel, opt)
	time_end(subs, sel, opt)

	if opt.automove then
		for _, i in ipairs(sel) do
			if i + 1 <= #subs then
				sel = { i + 1 }
			end
		end
		return sel
	end
end

depctrl:registerMacros({
	{ "Time", "Time the line after exact timing", time_both },
	{ "Config", "Configuration for script", config_setup },
})
