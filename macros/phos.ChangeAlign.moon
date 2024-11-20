export script_name        = "Change Alignment"
export script_description = "Changes the alignment of a text or shape without changing its original position"
export script_version     = "1.0.0"
export script_author      = "PhosCity"
export script_namespace   = "phos.ChangeAlign"


DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
    feed: "",
    {
        {"ILL.ILL", version: "1.5.1", url: "https://github.com/TypesettingTools/ILL-Aegisub-Scripts/"
            feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json"},
    }
}
ILL = depctrl\requireModules!
{:Ass, :Line} = ILL


main = (aln) ->
    (sub, sel, activeLine) ->
        ass = Ass sub, sel, activeLine
        for l, s, i, n in ass\iterSel!
            ass\progressLine s, i, n
            Line.extend ass, l
            Line.changeAlign l, aln
            ass\setLine l, s


depctrl\registerMacros({
  {"1", "Change alignment to 1", main 1},
  {"2", "Change alignment to 2", main 2},
  {"3", "Change alignment to 3", main 3},
  {"4", "Change alignment to 4", main 4},
  {"5", "Change alignment to 5", main 5},
  {"6", "Change alignment to 6", main 6},
  {"7", "Change alignment to 7", main 7},
  {"8", "Change alignment to 8", main 8},
  {"9", "Change alignment to 9", main 9},
})
