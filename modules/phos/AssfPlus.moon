haveDepCtrl, DependencyControl, depctrl = pcall require, 'l0.DependencyControl'
local Functional, ASS, Yutils, Math, Perspective
if haveDepCtrl
    depctrl = DependencyControl{
        name: "AssfPlus",
        version: "0.0.1",
        description: "Adds more features to ASSFoundation.",
        author: "PhosCity",
        moduleName: "phos.AssfPlus",
        url: "https://github.com/PhosCity/Aegisub-Scripts",
        feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
        {
            {"l0.ASSFoundation", version: "0.5.0", url: "https: //github.com/TypesettingTools/ASSFoundation",
            feed: "https: //raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
            { "l0.Functional", version: "0.6.0", url: "https://github.com/TypesettingTools/Functional",
            feed: "https://raw.githubusercontent.com/TypesettingTools/Functional/master/DependencyControl.json" },
            {"arch.Math", version: "0.1.8", url: "https://github.com/TypesettingTools/arch1t3cht-Aegisub-Scripts",
            feed: "https://raw.githubusercontent.com/TypesettingTools/arch1t3cht-Aegisub-Scripts/main/DependencyControl.json"},
            {"arch.Perspective", version: "1.0.0", url: "https://github.com/TypesettingTools/arch1t3cht-Aegisub-Scripts",
            feed: "https://raw.githubusercontent.com/TypesettingTools/arch1t3cht-Aegisub-Scripts/main/DependencyControl.json"},
            "Yutils"
        }
    }
    ASS, Functional, Math, Perspective, Yutils = depctrl\requireModules!
else
    ASS = require "l0.ASSFoundation"
    Functional = require "l0.Functional"
    Yutils = require "Yutils"
    Perspective = require "arch.Perspective"
    Math = require "arch.Math"

logger = depctrl\getLogger!
{:string, :list} = Functional

local lineData

assertLineContent = (data) ->
    logger\assert type(data) == "table", " Expected ASSFoundation line data. Got something else."
    logger\assert data.class == ASS.LineContents, " Expected ASSFoundation line data. Got something else."


assertTextSection = (section) ->
    logger\assert type(data) == "table", " Expected a text section. Got something else."
    logger\assert section.class == ASS.Section.Text, " Expected a text section. Got something else."


lineData = {

    getLineBounds: (data, noBordShad = false, noClip = false, noBlur = false) ->
        assertLineContent data

        local bound

        unless noBordShad or noClip or noBlur
            bound = data\getLineBounds!
        else
            dataCopy = data\copy!
            if noBordShad
                for tag in *{"outline", "outline_x", "outline_y", "shadow", "shadow_x", "shadow_y"}
                    dataCopy\replaceTags {ASS\createTag tag, 0}

            if noClip
                for tag in *ASS.tagNames.clips
                    dataCopy\removeTags tag

            if noBlur
                for tag in *{"blur", "blur_edges"}
                    dataCopy\removeTags tag

            bound = dataCopy\getLineBounds!

        bound


    getBoundingBox: (data, noBordShad = false, noClip = false, noBlur = false) ->
        bound = lineData.getLineBounds data, noBordShad, noClip, noBlur

        x1, y1 = bound[1].x, bound[1].y
        x2, y2 = bound[2].x, bound[2].y

        x1, y1, x2, y2


}


lib = {
    :lineData
}


if haveDepCtrl
    lib.version = depctrl
    return depctrl\register lib
else
    return lib