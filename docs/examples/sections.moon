export script_name = "ASSFoundation Test"
export script_description = "ASSFoundation Test"
export script_version = "0.0.1"
export script_author = "PhosCity"
export script_namespace = "phos.ASSFoundationTest"

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
    data\callback (section) ->
      if section.class == ASS.Section.Tag
        logger\log "\n=====ASS.Section.Tag====="
        for tag in *section\getTags!
          tagname = tag.__tag.name
          tagvalue = table.concat({tag\getTagParams!}, ",")
          logger\log "#{tagname}(#{tagvalue})"
      elseif section.class == ASS.Section.Text
        logger\log "\n=====ASS.Section.Text====="
        logger\log section.value
      elseif section.class == ASS.Section.Comment
        logger\log "\n=====ASS.Section.Comment====="
        logger\log section.value
      elseif section.class == ASS.Section.Drawing
        logger\log "\n=====ASS.Section.Drawing====="
        logger\dump section\getString!
  lines\replaceLines!

depctrl\registerMacro testFunction
