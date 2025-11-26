export script_name = "Transform Test"
export script_description = "ASSFoundation Test"
export script_version = "0.0.1"
export script_author = "PhosCity"
export script_namespace = "phos.TransformTest"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
  feed: "",
  {
    {"a-mo.LineCollection", version: "1.3.0", url: "https://github.com/TypesettingTools/Aegisub-Motion",
      feed: "https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
    {"l0.ASSFoundation", version: "0.4.0", url: "https://github.com/TypesettingTools/ASSFoundation",
      feed: "https://raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"}
  }
}
LineCollection, ASS = depctrl\requireModules!
logger = depctrl\getLogger!

testFunction = (sub, sel) ->
  lines = LineCollection sub, sel
  lines\runCallback (lines, line, i) ->
    data = ASS\parse line
    transforms = data\getTags "transform"
    for index, tr in ipairs transforms
      logger\log "\n=== Transform #{index} ==="
      start_time = tr.startTime\get!
      end_time = tr.endTime\get!
      accel = tr.accel\get!
      logger\log "Start Time: #{start_time}"
      logger\log "End Time: #{end_time}"
      logger\log "Accel: #{accel}"
      for tag in *tr.tags\getTags!
        tagname = tag.__tag.name
        tagvalue = table.concat({tag\getTagParams!}, ",")
        logger\log "#{tagname}(#{tagvalue})"
  lines\replaceLines!

depctrl\registerMacro testFunction
