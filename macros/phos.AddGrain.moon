export script_name = "Add Grain"
export script_description = "Add static and dynamic grain"
export script_version = "0.0.1"
export script_author = "PhosCity"
export script_namespace = "phos.AddGrain"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
  -- feed: "",
  {
    {"a-mo.LineCollection", version: "1.3.0", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
    {"a-mo.Line", version: "1.5.3", url: "https://github.com/TypesettingTools/Aegisub-Motion",
      feed: "https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
    {"l0.ASSFoundation", version: "0.5.0", url: "https: //github.com/TypesettingTools/ASSFoundation",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
    "Yutils"
  }
}
LineCollection, Line, ASS, Yutils = depctrl\requireModules!
logger = depctrl\getLogger!


grainIsInstalled = ->
  isInstalled = false
  for font in *Yutils.decode.list_fonts!
    isInstalled = true if font.name == "Grain" and font.longname == "Grain Regular"
  isInstalled


randomize = ->
  character = string.char math.random 65, 90
  character = character\lower! if math.random! < math.random!
  character


main = (mode) ->
  (sub, sel) ->
    unless grainIsInstalled!
      logger\log "It seems you have not installed grain font."
      logger\log "The script will proceed but will not look as intented unless you install the font."
      logger\log "You can install it from following link:"
      logger\log "https://cdn.discordapp.com/attachments/425357202963038208/708726507173838958/grain.ttf"

    lines = LineCollection sub, sel
    return if #lines.lines == 0

    lines\runCallback (lines, line, i) ->
      data = ASS\parse line

      -- Pure white layer
      data\callback ((section) -> section\replace "!!", randomize), ASS.Section.Text
      data\removeTags {"fontname", "outline", "shadow", "color1"}
      data\insertTags {ASS\createTag 'fontname', "Grain"}
      data\insertTags {ASS\createTag 'outline', 0}
      data\insertTags {ASS\createTag 'shadow', 0}
      data\insertTags {ASS\createTag 'color1', 255, 255, 255} 
      data\insertTags {ASS\createTag 'bold', 0} 
      if mode == "dense"
        data\removeTags {"color3", "color4", "alpha1", "alpha3"}
        data\insertTags {ASS\createTag 'color3', 255, 255, 255}
        data\insertTags {ASS\createTag 'color4', 255, 255, 255}
        data\insertTags {ASS\createTag 'alpha1', 254}
        data\insertTags {ASS\createTag 'alpha3', 255}
        data\replaceTags {ASS\createTag 'shadow', 0.01}
      data\cleanTags!
      data\commit!

      -- Pure black layer
      newLine = Line line, lines
      newdata = data\copy!
      newdata\callback ((section) ->
        section\replace ".", (character) ->
          if character != "\\" and character != "N"     -- Trying to not convert "\N" to random character
            randomize!
          else
            character
      ), ASS.Section.Text
      newdata\replaceTags {ASS\createTag 'color1', 0, 0, 0}
      if mode == "dense"
        newdata\replaceTags {ASS\createTag 'color3', 0, 0, 0}
        newdata\replaceTags {ASS\createTag 'color4', 0, 0, 0}
      newdata\commit!
      lines\addLine newLine, nil, true, line.number + 1
    lines\replaceLines!
    lines\insertLines!

  
depctrl\registerMacros({
  { "Add grain", "Add grain", main "normal" },
  { "Add dense grain", "Add dense grain", main "dense" },
})
