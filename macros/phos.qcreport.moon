export script_name = "#BETA# QC Report"
export script_description = "Write and generate QC reports"
export script_author = "PhosCity"
export script_namespace = "phos.qcreport"
export script_version = "0.0.4"

default_config =
  section: {"Timing", "Typesetting", "Editing"},

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl({})
config = depctrl\getConfigHandler(default_config, "config", false)


config_setup = () ->
  config\load()
  opt = config.c

  value = ""
  for item in *opt.section
    value ..= "#{item}\n"
  
  CONFIG_GUI = {
		{ x: 0, y: 0, width: 1, height: 1, class: "label", label: "Add your sections below:", },
		{ x: 0, y: 1, width: 15, height: 10, class: "textbox", value: value, name: "section" },
	}
  buttons = { "Save", "Reset", "Cancel" }
  pressed, result = aegisub.dialog.display(CONFIG_GUI, buttons)
  switch pressed
    when "Cancel" then aegisub.cancel!
    when "Save"
      section_tbl = {}
      for s in result["section"]\gmatch("[^\n]+")
        table.insert section_tbl, s
      opt.section = section_tbl
      config\write()
    when "Reset"
      opt.section = default_config.section
      config\write()


clear_notes = (subs, sel) ->
  to_delete = {}
  for i = 1, #subs do
    if subs[i].class == "dialogue"
      line = subs[i]
      continue unless line.text\match "{%*%[.*%*}"
      line.text = line.text\gsub "{%*%[.*%*}", ""
      line.effect = line.effect\gsub "%[QC-[^%]]+%]", ""
      if line.text == "" then table.insert(to_delete, i)
      subs[i] = line
  subs.delete(to_delete)


create_gui = (opt) ->
  dlg = {}
  for index, item in ipairs opt.section
    dlg[#dlg+1] = {x: index-1, y: 0, class: "checkbox", label: item, name: item}

  dlg[#dlg+1] = {x: 0, y: 1, width: 2, height: 1, class: "label", label: "Write you notes below:"}
  dlg[#dlg+1] = {x: 18, y: 1, width: 2, height: 1, class: "checkbox", label: "Use video frame", name: "use_video", value: opt.use_video}
  dlg[#dlg+1] = {x: 0, y: 2, class: "textbox", name: "note", value: "", width: 21, height: 10}

  return dlg


-- This one uses video frame position to add notes
-- If the current frame has a line, then then the note will be added to that line
-- If the current frame has no line, then a new line with note will be inserted with current frame's time
useVideo = (subs, header, note) ->
  video_frame = aegisub.project_properties().video_position

  unless video_frame
    aegisub.log "Video is not loaded. Adding note to current selected line."
    return nil
  else
    time_frame = aegisub.ms_from_frame(video_frame)

    for i=1, #subs
      continue unless subs[i].class == "dialogue"
      line = subs[i]
      if time_frame > line.start_time and time_frame < line.end_time
        return i, {i}

    for i=1, #subs
      continue unless subs[i].class == "dialogue"
      line = subs[i]
      if line.start_time > time_frame
        line.text = "{*#{note}*}"
        line.start_time = time_frame
        line.end_time = time_frame
        line.effect = "[QC-#{header}]"
        subs[-i] = line
        return false, {i}


writeQC = (subs, sel, act) ->
  config\load()
  opt = config.c

  dlg = create_gui opt
  btn, res = aegisub.dialog.display dlg, {"Add Note", "Cancel"}, {"ok": "Add Note", "cancel": "Cancel"}

  opt.use_video = res["use_video"]
  config\write()

  if btn
    return if res["note"] == ""

    header = "Note"
    for section in *opt.section
      header = section if res[section]

    qc_note = res["note"]\gsub("\n", "\\N")\gsub("{", "[")\gsub("}", "]")
    qc_note = "[#{header}] #{qc_note}"

    -- If video_frame is chosen
    local new_index
    local new_sel
    if res["use_video"]
      new_index, new_sel = useVideo(subs, header, qc_note)
      return new_sel unless new_index

    new_index or= act
    line = subs[new_index]
    line.text  ..= "{*#{qc_note}*}"
    line.effect  ..= "[QC-#{header}]"
    subs[new_index] = line

    return new_sel


ms2timecode = (num) ->
  hh = math.floor((num / (60 * 60 * 1000)) % 24)
  mm = math.floor((num / (60 * 1000)) % 60)
  ss = math.floor((num / 1000) % 60)
  ms = num % 1000
  return string.format("%01d:%02d:%02d.%01d", hh, mm, ss, ms)


generate_QC = (subs, sel) ->
  report = {}
  for i = 1, #subs do
    if subs[i].class == "dialogue"
      line = subs[i]
      for qc in line.text\gmatch "{%*([^%*]+)%*}"
        section_header = qc\match "^%[([^%]]+)%].*"
        note = qc\gsub("#{section_header}", "")\gsub("[%[%]]", "")\gsub("^%s+", "")\gsub("\\N", "\n")
        note = ms2timecode(line.start_time).." - "..note.."\n"
        report[section_header] or= {}
        table.insert(report[section_header], note)

  for k, v in pairs report
    aegisub.log "[#{k}]\n"
    for _, note in ipairs v
      aegisub.log note
    aegisub.log "\n"


depctrl\registerMacros({
  { "Write QC", script_description, writeQC },
  { "Generate QC Report", script_description, generate_QC },
  { "Config", "Configuration for script", config_setup },
  { "Clear Notes", "Clear the notes", clear_notes },
})
