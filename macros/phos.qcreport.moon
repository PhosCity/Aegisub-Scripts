export script_name = "#BETA# QC Report"
export script_description = "Write and generate QC reports"
export script_author = "PhosCity"
export script_namespace = "phos.qcreport"
export script_version = "0.0.2"

default_config =
  section: {"Timing", "Typesetting", "Editing"},

local depctrl
local config
haveDepCtrl, DependencyControl = pcall(require, "l0.DependencyControl")
if haveDepCtrl
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
  for i = 1, #subs do
    if subs[i].class == "dialogue"
      line = subs[i]
      continue unless line.text\match "{%*%[.*%*}"
      line.text = line.text\gsub "{%*%[.*%*}", ""
      line.effect = line.effect\gsub "%[QC-[^%]]+%]", ""
      subs[i] = line

create_gui = (opt) ->
  dlg = {}
  for index, item in ipairs opt.section
    dlg[#dlg+1] = {x: index-1, y: 0, class: "checkbox", label: item, name: item}

  dlg[#dlg+1] = {x: 0, y: 1, width: 2, height: 1, class: "label", label: "Write you notes below:"}
  dlg[#dlg+1] = {x: 0, y: 2, class: "textbox", name: "note", value: "", width: 21, height: 10}

  return dlg

main = (subs, sel, act) ->
  config\load()
  opt = config.c

  dlg = create_gui opt
  btn, res = aegisub.dialog.display dlg, {"Add Note", "Cancel"}, {"ok": "Add Note", "cancel": "Cancel"}
  if btn
    local header
    for section in *opt.section
      header = section if res[section]
    header or= "Note"
    unless res["note"] == ""
      qc_note = res["note"]\gsub("\n", "\\N")\gsub("{", "[")\gsub("}", "]")
      qc_note = "[#{header}] #{qc_note}"
      line = subs[act]
      line.text  ..= "{*#{qc_note}*}"
      line.effect  ..= "[QC-#{header}]"
      subs[act] = line

time2string = (num) ->
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
        note = time2string(line.start_time).." - "..note.."\n"
        report[section_header] or= {}
        table.insert(report[section_header], note)

  for k, v in pairs report
    aegisub.log "[#{k}]\n"
    for _, note in ipairs v
      aegisub.log note
    aegisub.log "\n"

if haveDepCtrl
  depctrl\registerMacros({
    { "Write QC", script_description, main },
    { "Generate QC Report", script_description, generate_QC },
    { "Config", "Configuration for script", config_setup },
    { "Clear Notes", "Clear the notes", clear_notes },
  })
