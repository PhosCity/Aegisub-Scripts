export script_name = "#BETA# QC Report"
export script_description = "Write and generate QC reports"
export script_author = "PhosCity"
export script_namespace = "phos.qcreport"
export script_version = "0.0.1"

default_config =
  section: {"Timing", "Typesetting", "Editing"},

local depctrl
local config
haveDepCtrl, DependencyControl = pcall(require, "l0.DependencyControl")
if haveDepCtrl
  depctrl = DependencyControl({})
  config = depctrl\getConfigHandler(default_config, "config", false)

create_gui = (opt) ->
  dlg = {}
  for index, item in ipairs opt.section
    dlg[#dlg+1] = {x: index-1, y: 0, class: "checkbox", label: item, name: item}

  dlg[#dlg+1] = {x: 0, y: 1, class: "label", label: "Write you notes below"}
  dlg[#dlg+1] = {x: 0, y: 2, class: "textbox", name: "note", value: "", width: 20, height: 20}

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
      qc_note = res["note"]\gsub("\n", "\\N")\gsub("[\\N]+", "\\N")\gsub("{", "[")\gsub("}", "]")
      qc_note = "[#{header}] #{qc_note}"
      line = subs[act]
      line.text  ..= "{*#{qc_note}*}"
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
        note = qc\gsub("#{section_header}", "")\gsub("[%[%]]", "")\gsub("^%s+", "")
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
  })
