export script_name = "Chromatic Abberation"
export script_description = "Add chromatic abberation to shape and text."
export script_version = "1.0.0"
export script_author = "PhosCity"
export script_namespace = "phos.ChromaticAbberation"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
    feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
    {
        {"a-mo.LineCollection", version: "1.3.0", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
            feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
        {"l0.ASSFoundation", version: "0.5.0", url: "https: //github.com/TypesettingTools/ASSFoundation",
            feed: "https: //raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
        {"phos.AssfPlus", version: "1.0.2", url: "https://github.com/PhosCity/Aegisub-Scripts",
            feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json"},
        {"phos.AegiGui", version: "1.0.0", url: "https://github.com/PhosCity/Aegisub-Scripts",
            feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json"},
        "aegisub.util"
    }
}
LineCollection, ASS, AssfPlus, AegiGui, util = depctrl\requireModules!


createGUI = ->
    str = "
    | label, x Offset                           | float,xOffset, 2 | pad, 10 | label, Color 1 | color, color1, &H00FFFF& |
    | label, y Offset                           | float,yOffset, 2 | null    | label, Color 2 | color, color2, &HFF00FF& |
    | check, keepBaseColor, Keep Original Color |                  |         | label, Color 3 | color, color3, &HFFFF00& |
    "
    btn, res = AegiGui.open str, "Apply:ok, Revert, Cancel:cancel"
    aegisub.cancel! unless btn
    res, btn


mixColors = (res) ->
    f1_r, f1_g, f1_b = util.extract_color res["color1"]
    f2_r, f2_g, f2_b = util.extract_color res["color2"]
    f3_r, f3_g, f3_b = util.extract_color res["color3"]

    n2_r, n2_g, n2_b = (f1_r * f2_r) / 255, (f1_g * f2_g) / 255, (f1_b * f2_b) / 255
    n3_r, n3_g, n3_b = (f1_r * f3_r) / 255, (f1_g * f3_g) / 255, (f1_b * f3_b) / 255
    n4_r, n4_g, n4_b = (f2_r * f3_r) / 255, (f2_g * f3_g) / 255, (f2_b * f3_b) / 255

    n1_r, n1_g, n1_b = (n2_r * n3_r * n4_r) / (255 * 255), (n2_g * n3_g * n4_g) / (255 * 255), (n2_b * n3_b * n4_b) / (255 * 255)

    {
        {r: f1_r, g: f1_g, b: f1_b},
        {r: f2_r, g: f2_g, b: f2_b},
        {r: f3_r, g: f3_g, b: f3_b},
        {r: n1_r, g: n1_g, b: n1_b},
        {r: n2_r, g: n2_g, b: n2_b},
        {r: n3_r, g: n3_g, b: n3_b},
        {r: n4_r, g: n4_g, b: n4_b},
    }


pathfinding = (shape, xOffset, yOffset) ->

    shape2 = shape\copy!
    shape1 = shape2\copy!\sub xOffset, yOffset
    shape3 = shape2\copy!\add xOffset, yOffset

    f1 = shape1\copy!
    f2 = shape2\copy!
    f3 = shape3\copy!

    n1 = shape1\copy!
    n2 = shape2\copy!
    n3 = shape3\copy!
    n4 = shape3\copy!

    AssfPlus._shape.pathfinder "Difference", f1, shape2
    AssfPlus._shape.pathfinder "Difference", f1, shape3

    AssfPlus._shape.pathfinder "Difference", f2, shape1
    AssfPlus._shape.pathfinder "Difference", f2, shape3

    AssfPlus._shape.pathfinder "Difference", f3, shape1
    AssfPlus._shape.pathfinder "Difference", f3, shape2

    AssfPlus._shape.pathfinder "Intersect", n1, n2
    AssfPlus._shape.pathfinder "Intersect", n1, n3

    AssfPlus._shape.pathfinder "Difference", n2, shape3
    AssfPlus._shape.pathfinder "Difference", n2, f2

    AssfPlus._shape.pathfinder "Difference", n3, shape2
    AssfPlus._shape.pathfinder "Difference", n3, f3

    AssfPlus._shape.pathfinder "Difference", n4, shape1
    AssfPlus._shape.pathfinder "Difference", n4, f3

    f1, f2, f3, n1, n2, n3, n4


main = (sub, sel) ->

    res, btn = createGUI!

    if btn == "Revert"
        AssfPlus._util.revertLines sub, sel, "phos.ca"
        return

    xOffset = res["xOffset"]
    yOffset = res["yOffset"]

    color = mixColors res

    lines = LineCollection sub, sel
    return if #lines.lines == 0

    toDelete, toAdd = {}, {}
    windowError = AssfPlus._util.windowError
    lines\runCallback (lines, line, i) ->

        data = ASS\parse line
        table.insert toDelete, line
        AssfPlus._util.setOgLineExtradata line, "phos.ca"

        pos = data\getPosition!
        posInLine = data\getTags "position"
        if #posInLine == 0
            data\insertTags pos

        textSectionCount = data\getSectionCount ASS.Section.Text
        drawingSectionCount = data\getSectionCount ASS.Section.Drawing

        if drawingSectionCount == 0 and textSectionCount == 0
            windowError "There is neither text section nor drawing section in the line. Nothing to do here."

        elseif drawingSectionCount > 0 and textSectionCount > 0
            windowError "Lines with both text section and drawing section cannot be handled by this script."

        elseif drawingSectionCount > 1
            windowError "Lines with multiple drawing section cannot be handled by this script."

        elseif drawingSectionCount > 0

            if res["keepBaseColor"]
                tags = (data\getEffectiveTags 1, true, true, false).tags
                b, g, r = tags.color1\getTagParams!
                color[4].r, color[4].g, color[4].b = r, g, b

            data\callback ((section) ->
                f1, f2, f3, n1, n2, n3, n4 = pathfinding section, xOffset, yOffset

                for index, item in ipairs {f1, f2, f3, n1, n2, n3, n4}
                    continue if item\toString! == ""
                    section.contours = item.contours
                    r, g, b = color[index].r, color[index].g, color[index].b
                    data\replaceTags {ASS\createTag "color1", b, g, r}
                    table.insert toAdd, ASS\createLine { line }
            ), ASS.Section.Drawing

        elseif textSectionCount > 0

            shape = AssfPlus.lineData.getTextShape data
            if shape == nil or shape == ""
                windowError "Text shape not found."
            shape = ASS.Draw.DrawingBase {str: shape}

            f1, f2, f3, n1, n2, n3, n4 = pathfinding shape, xOffset, yOffset

            prepareLine = (shape, color, keepBaseColor = false) ->
                return if shape\toString! == ""
                data\replaceTags {ASS\createTag "clip_vect", shape}
                unless keepBaseColor
                    r, g, b = color.r, color.g, color.b
                    data\replaceTags {ASS\createTag "color1", b, g, r}
                table.insert toAdd, ASS\createLine { line }

            prepareLine n1, color[4], res["keepBaseColor"]

            data\removeTags "color1", 2, #data.sections
            data\cleanTags 1

            prepareLine n2, color[5]
            prepareLine n4, color[7]
            prepareLine f2, color[2]

            pos\sub xOffset, yOffset
            prepareLine f1, color[1]

            pos\add xOffset * 2, yOffset * 2
            prepareLine f3, color[3]
            prepareLine n3, color[6]

    for ln in *toAdd
      lines\addLine ln

    lines\insertLines!
    lines\deleteLines toDelete


depctrl\registerMacro main