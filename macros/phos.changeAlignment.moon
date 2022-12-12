export script_name = "Change Alignment"
export script_description = "Change alignment of line without changing it's appearance."
export script_version = "1.0.2"
export script_author = "PhosCity"
export script_namespace = "phos.changeAlignment"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
  feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
  {
    {"a-mo.LineCollection", version: "1.3.0", url: "https://github.com/TypesettingTools/Aegisub-Motion",
      feed: "https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
    {"l0.ASSFoundation", version: "0.5.0", url: "https://github.com/TypesettingTools/ASSFoundation",
      feed: "https://raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
  }
}
LineCollection, ASS = depctrl\requireModules!

changeAlignment = (sub, sel) ->
  -- GUI
  dialog, x, y, target_align = {}, 0, 2, nil
  for i = 1, 9
    dialog[#dialog+1] = {x: x, y: y, class: "checkbox", label: i, name: i}
    x += 1
    if i % 3 == 0
      y -= 1
      x = 0
  btn, res = aegisub.dialog.display dialog, {"OK", "Cancel"}, {"ok": "OK", "cancel": "Cancel"}
  for key, value in pairs res
    target_align = key if value
  aegisub.cancel! unless target_align

  -- Changing Alignment
  lines = LineCollection sub, sel
  return if #lines.lines == 0

  target = ASS\createTag("align", target_align)

  lines\runCallback ((lines, line, i) ->
    aegisub.cancel! if aegisub.progress.is_cancelled!
    data = ASS\parse line
    pos, align = data\getPosition!
    unless target\equal align
      drawingSectionCount = data\getSectionCount ASS.Section.Drawing
      if drawingSectionCount > 0                                            -- Drawings
        data\callback ((section) ->
          ex = section\getExtremePoints true
          offset = target\getPositionOffset ex.w, ex.h, align
          section\add offset
          data\replaceTags {target}
        ), ASS.Section.Drawing
      else                                                                  -- Everything else
        metrics = data\getTextMetrics true
        width, height = metrics.width, metrics.height
        pos\add target\getPositionOffset width, height, align
        data\replaceTags {target, pos}
      data\commit!
  ), true

  lines\replaceLines!

depctrl\registerMacro changeAlignment
