haveDepCtrl, DependencyControl, depctrl = pcall require, 'l0.DependencyControl'
local Functional, ASS, Yutils, AMath, Perspective
if haveDepCtrl
    depctrl = DependencyControl{
        name: "AssfPlus",
        version: "0.0.2",
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
    ASS, Functional, AMath, Perspective, Yutils = depctrl\requireModules!
else
    ASS = require "l0.ASSFoundation"
    Functional = require "l0.Functional"
    Yutils = require "Yutils"
    Perspective = require "arch.Perspective"
    AMath = require "arch.Math"

logger = depctrl\getLogger!
{:string, :list, :util} = Functional
{:Matrix} = AMath

local lineData
local _tag

assertLineContent = (data) ->
    logger\assert data.class == ASS.LineContents, " Expected ASSFoundation line data. Got something else."


assertTextSection = (section) ->
    logger\assert section.class == ASS.Section.Text, " Expected a text section. Got something else."


lineData = {

    getLineBounds: (data, noBordShad = false, noClip = false, noBlur = false, noPerspective = false) ->
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

            if noPerspective
                for tag in *{"shear_x", "shear_y", "angle", "angle_x", "angle_y"}
                    dataCopy\replaceTags {ASS\createTag tag, 0}

            bound = dataCopy\getLineBounds!

        bound


    getBoundingBox: (data, noBordShad = false, noClip = false, noBlur = false, noPerspective = false) ->
        bound = lineData.getLineBounds data, noBordShad, noClip, noBlur, noPerspective

        x1, y1 = bound[1].x, bound[1].y
        x2, y2 = bound[2].x, bound[2].y

        x1, y1, x2, y2


    firstSectionIsTag: (data) ->
        assertLineContent data

        local firstSectionIsTag
        for section in *data.sections
            continue if section.class == ASS.Section.Comment
            firstSectionIsTag = true if section.class == ASS.Section.Tag
            break
        firstSectionIsTag

    trim: (data) ->
        assertLineContent data
        trimLeft, trimRight, t = {}, {}, 0
        data\callback ((section, _, _, j) ->
            t = j
            value = section\getString!
            value = value\gsub "%s*\\N%s*", "\\N"
            if value\match "^\\N"
                table.insert trimRight, j - 1
            if value\match "\\N$"
                table.insert trimLeft, j + 1
            section.value = value
        ), ASS.Section.Text

        return if t == 0
        table.insert trimLeft, 1, 1
        table.insert trimRight, t

        data\callback ((section, _, _, j) ->
            for item in *trimLeft
                section\trimLeft! if item == j
            for item in *trimRight
                section\trimRight! if item == j
        ), ASS.Section.Text

}


textSection = {

    getTags: (data, section, listOnly = false) ->
        assertLineContent data
        assertTextSection section

        index = section.index
        local tags
        for i = index - 1, 0, -1
            break if i == 0
            sec = data.sections[i]
            continue if sec.class == ASS.Section.Comment 
            tags = (sec\getEffectiveTags false, false, true).tags
            break

        if listOnly and tags
            tagList = [key for key in pairs tags]
            return tagList

        tags

}


_tag = {

    color: {

        extractColor: (tag) ->
            local r, g, b
            if type(tag) == "string"
                r, g, b = util.extract_color tag
            elseif type(tag) == "table"
                r, g, b = table.unpack tag
            else
                logger\assert tag.class == ASS.Tag.Color, " Expected color tag . Got something else."
                r, g, b = tag\getTagParams!
            return r, g, b

        getXYZ: (tag) ->
            r, g, b = _tag.color.extractColor tag

            r, g, b = r/0xFF, g/0xFF, b/0xFF

            f = (n) ->
                if n > 0.04045
                    return ((n + 0.055) / 1.055) ^ 2.4
                else
                    return n / 12.92

            r, g, b = f(r), f(g), f(b)

            x = r*0.4124564 + g*0.3575761 + b*0.1804375
            y = r*0.2126729 + g*0.7151522 + b*0.0721750
            z = r*0.0193339 + g*0.1191920 + b*0.9503041

            x, y, z


        getLAB: (tag) ->
            xyz2lab = (x, y, z) ->
                Xn, Yn, Zn = 0.95047, 1.0, 1.08883

                x, y, z = x/Xn, y/Yn, z/Zn

                f = (n) ->
                    if n > 0.008856
                        return n ^ (1/3)
                    else
                        return (903.3 * n + 16) / 116

                x, y, z = f(x), f(y), f(z)

                l = (116 * y) - 16
                a = 500 * (x - y)
                b = 200 * (y - z)

                l, a, b


            x, y, z = _tag.color.getXYZ tag
            l, a, b = xyz2lab x, y, z
            l, a, b


        getDeltaE: (color1, color2, weights = {}) ->
            l1, a1, b1 = _tag.color.getLAB color1
            l2, a2, b2 = _tag.color.getLAB color2

            x1 = {L: l1, A: a1, B: b1}
            x2 = {L: l2, A: a2, B: b2}

            radiansToDegrees = (rad) ->
                rad * 180/math.pi

            degreesToRadians = (deg) ->
                deg * math.pi/180

            gethPrimeFn = (x, y) ->
                if x == 0 and y == 0
                    return 0
                hueAngle = radiansToDegrees(math.atan(x, y))
                if hueAngle > 0
                    return hueAngle
                else
                    return hueAngle + 360

            getDeltahPrime = (c1, c2, hPrime1, hPrime2) ->
                -- If either C'1 or C'2 is 0, then Δh' is irrelevant and may be set to 0
                if c1 == 0 or c2 == 0
                    return 0

                if math.abs(hPrime1 - hPrime2) <= 180
                    return hPrime2 - hPrime1

                if hPrime2 <= hPrime1
                    return hPrime2 - hPrime1 + 360
                else
                    return hPrime2 - hPrime1 - 360

            gethBarPrime = (hPrime1, hPrime2) ->
                if math.abs(hPrime1 - hPrime2) > 180
                    return (hPrime1 + hPrime2 + 360) / 2
                return (hPrime1 + hPrime2) / 2

            getT = (hBarPrime) ->
                return 1 -
                    0.17 * math.cos(degreesToRadians(hBarPrime - 30)) +
                    0.24 * math.cos(degreesToRadians(2 * hBarPrime)) +
                    0.32 * math.cos(degreesToRadians(3 * hBarPrime + 6)) -
                    0.20 * math.cos(degreesToRadians(4 * hBarPrime - 63))

            getRsubT = (cBarPrime, hBarPrime) ->
                return -2 *
                    math.sqrt(
                        cBarPrime^7 / (cBarPrime^7 + 25^7)
                    ) *
                        math.sin(
                            degreesToRadians(
                                60 *
                                math.exp(
                                    -(
                                        ((hBarPrime - 275) / 25) ^ 2
                                    )
                                )
                            )
                        )

            deltaPrime = x2.L - x1.L

            ksubL = weights.lightness or 1
            ksubC = weights.chroma or 1
            ksubH = weights.hue or 1

            deltaLPrime = x2.L - x1.L

            lBar = (x1.L + x2.L) / 2

            c1 = math.sqrt(x1.A^2 + x1.B^2)
            c2 = math.sqrt(x2.A^2 + x2.B^2)

            cBar = (c1 + c2) / 2

            aPrime1 = x1.A +
                (x1.A / 2) *
                (1 - math.sqrt(
                    cBar^7 /
                    (cBar^7 + 25^7)
                ))

            aPrime2 = x2.A +
                (x2.A / 2) *
                (1 - math.sqrt(
                    cBar^7 /
                    (cBar^7 + 25^7)
                ))

            cPrime1 = math.sqrt(
                aPrime1^2 + x1.B^2
            )

            cPrime2 = math.sqrt(
                aPrime2^2 + x2.B^2
            )

            cBarPrime = (cPrime1 + cPrime2) / 2

            deltaCPrime = cPrime2 - cPrime1

            sSubL = 1 + (
                (0.015 * (lBar - 50)^2) /
                math.sqrt(20 + (lBar - 50)^2)
            )

            sSubC = 1 + 0.045 * cBarPrime

            hPrime1 = gethPrimeFn(x1.B, aPrime1)
            hPrime2 = gethPrimeFn(x2.B, aPrime2)
            deltahPrime = getDeltahPrime(c1, c2, hPrime1, hPrime2)
            deltaHPrime = 2 * math.sqrt(cPrime1 * cPrime2) * math.sin(degreesToRadians(deltahPrime) / 2)
            hBarPrime = gethBarPrime(hPrime1, hPrime2)
            t = getT(hBarPrime)
            sSubH = 1 + 0.015 * cBarPrime * t
            rSubT = getRsubT(cBarPrime, hBarPrime)

            -- Put it all together
            lightness = deltaLPrime / (ksubL * sSubL)
            chroma = deltaCPrime / (ksubC * sSubC)
            hue = deltaHPrime / (ksubH * sSubH)

            return math.sqrt(
                lightness^2 +
                chroma^2 +
                hue^2 +
                rSubT * chroma * hue
            )

    }

}


lib = {
    :lineData
    :textSection
    :_tag
}


if haveDepCtrl
    lib.version = depctrl
    return depctrl\register lib
else
    return lib