export script_name = "Remove Tags"
export script_description = "Dynamically remove tags based on selection"
export script_version = "1.0.1"
export script_author = "PhosCity"
export script_namespace = "phos.RemoveTags"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
    feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
    {
        {"a-mo.LineCollection", version: "1.3.0", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
            feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
        {"l0.ASSFoundation", version: "0.5.0", url: "https: //github.com/TypesettingTools/ASSFoundation",
            feed: "https: //raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
        {"l0.Functional", version: "0.6.0", url: "https://github.com/TypesettingTools/Functional",
            feed: "https://raw.githubusercontent.com/TypesettingTools/Functional/master/DependencyControl.json"},
    }
}
LineCollection, ASS, Functional = depctrl\requireModules!
logger = depctrl\getLogger!
{:list} = Functional


--- Collects all the tags in the selected lines
---@param sub table subtitle object
---@param sel table selected lines
---@return table collection that has tagList, buttons, top row options, tag groups, hints and more
collectTags = (sub, sel) ->
    collection =
        tagList: {}
        startTagIndex: nil
        buttons: {"Remove Tags", "Remove All", "Cancel"}
        topRow: {start_tag: false, inline_tags: false, transforms: false, invert: true}
        removeGroup: {color: false, alpha: false, rotation: false, scale: false, perspective: false, inline_except_last: false} 
        removeGroupTags: {
            color: {"color1", "color2", "color3", "color4"}
            alpha: {"alpha", "alpha1", "alpha2", "alpha3", "alpha4"}
            rotation: {"angle", "angle_x", "angle_y"}
            scale: {"fontsize", "scale_x", "scale_y"}
            perspective: {"angle", "angle_x", "angle_y", "shear_x", "shear_y"}
        }
        hint: {
            color: "c, 1c, 2c, 3c, 4c"
            alpha: "alpha, 1a, 2a, 3a, 4a"
            rotation: "frz, frx, fry"
            scale: "fs, fscx, fscy"
            perspective: "frz, frx, fry, fax, fay, org"
            inline_except_last: "Remove all inline tags except the last one"
            start_tag: "Remove from start tags only"
            inline_tags: "Remove from inline tags only"
            transform: "Remove from transform only"
            invert: "Remove all except selected"
        } 

    lines = LineCollection sub, sel
    return if #lines.lines == 0
    lines\runCallback (lines, line, i) ->
        aegisub.cancel! if aegisub.progress.is_cancelled!
        aegisub.progress.task "Collecting tags from %d of %d lines..."\format i, #lines.lines if i%10==0
        aegisub.progress.set 100*i/#lines.lines
        data = ASS\parse line
        tagSectionCount = data\getSectionCount ASS.Section.Tag
        collection.removeGroup.inline_except_last = tagSectionCount > 2 if not collection.removeGroup.inline_except_last
        collection.topRow.inline_tags = tagSectionCount > 1 if not collection.topRow.inline_tags

        -- Determine if there is a tag at the start of the line
        -- If we reach a Text section or Drawing section before we reach a Tag section, then there is no start tag block.
        for j = 1, #data.sections
            if data.sections[j].instanceOf[ASS.Section.Tag]
                collection.topRow.start_tag = true
                collection.startTagIndex = j
                break
            elseif data.sections[j].instanceOf[ASS.Section.Text] or data.sections[j].instanceOf[ASS.Section.Drawing]
                break

        -- Collect all the tags in the line

        --- Determines which group a tag belongs to
        ---@param tagName string name of tag as ASSFoundation understands it
        tagSorter = (tagName) ->
            with collection.removeGroup
                if tagName\match "color"
                    .color = true
                elseif tagName\match "alpha"
                    .alpha = true
                elseif tagName\match "angle"
                    .rotation = true
                    .perspective = true
                elseif tagName\match "shear" or tagName == "origin"
                    .perspective = true
                elseif tagName\match "scale" or tagName == "fontsize"
                    .scale = true

        for tag in *data\getTags!
            tagName = tag.__tag.name
            table.insert collection.tagList, tagName
            tagSorter tagName

            if tag.class == ASS.Tag.Transform
                collection.topRow.transforms = true
                for transformTag in *tag.tags\getTags!
                    table.insert collection.tagList, transformTag.__tag.name
                    tagSorter transformTag.__tag.name

    -- No tags could be found in the selected lines
    if #collection.tagList == 0
        aegisub.dialog.display { { class: "label", label: "No tags found in the selected lines." } }, { "Close" }, { cancel: "Close" }
        aegisub.cancel!

    -- Insert a button for removing transform if transform tag exists in the line
    -- table.insert collection.buttons, 3, "Transform" if collection.topRow.transforms

    -- Deduplicate the taglist
    collection.tagList = list.uniq collection.tagList

    -- Sort the taglist
    collection.tagList = [tag for tag in *(list.join(ASS.tagSortOrder, {"transform"})) when list.find collection.tagList, (value) -> value == tag ]
    return collection


--- Dynamically creates a gui depending on the options set in collection table
---@param collection table collection table
---@return table dialog table
---@return table collection updated
createGui = (collection) ->
    y, dialog = 0, {}
    -- Left portion of the GUI
    for key, value in pairs collection.removeGroup
        continue unless value
        table.insert collection.buttons, 1, "Remove Group" if y == 0
        label = ("Remove all #{key}")\gsub "_", " "
        dialog[#dialog+1]= {x: 0, y: y, class: "checkbox", label: label, name: key, hint: collection.hint[key]}
        y += 1

    -- Right portion of the GUI
    startX = 0
    startX = 1 if collection.buttons[1] == "Remove Group"
    x = startX

    for key in *[ item for item in *{"start_tag", "inline_tags", "transforms", "invert"} when collection.topRow[item]]       -- Manually sorting since lua doesn't loop through table in order
        label = key\gsub("^%l", string.upper)\gsub("_%l", string.upper)\gsub("_", " ")
        dialog[#dialog+1]= {x: x, y: 0, class: "checkbox", label: label, name: key, hint: collection.hint[key]}
        x += 1

	-- Determine the number of columns in gui
    column = math.max math.ceil(math.sqrt #collection.tagList), x

	-- Dynamically create gui
    count = 0
    for y = 1, column
        for x = startX, column + startX - 1
            count += 1
            break if count > #collection.tagList
            label = (ASS.toFriendlyName[collection.tagList[count]])\gsub("\\1c%s+", "")\gsub("\\", "")
            dialog[#dialog+1] = {x: x, y: y, class: "checkbox", label: label, name: collection.tagList[count]}

    return dialog, collection


--- Removes tags in a line
---@param data table line content object from ASSFoundation
---@param tags table list of tags that must be removed from the line
---@param start integer index of tag block from which to start removing tags
---@param end_ integer index of tag block upto which to remove tags
---@param transforms table ASSFoundation transform tag object
---@param transformOnly boolean should tags only be removed inside transform
---@return table data updated line content object
removeTags = (data, tags, start, end_, transforms, transformOnly) ->
    data\removeTags tags, start, end_ unless transformOnly
    if #transforms > 0
        for _, tr in ipairs transforms
            toRemove = {}
            for index, tag in ipairs tr.tags.tags
                for i in *tags
                    table.insert toRemove, index if tag.__tag.name == i and i != "transform"
            list.removeIndices tr.tags.tags, toRemove
    data


--- Main processing function that gathers and executes all other functions
---@param sub table subtitle object
---@param sel table selected lines
main = (sub, sel) ->
    collection = collectTags sub, sel
    dialog, collection = createGui collection
    logger\dump collection.buttons
    btn, res = aegisub.dialog.display dialog, collection.buttons, {"cancel": "Cancel"}
    aegisub.cancel! unless btn

    lines = LineCollection sub, sel
    return if #lines.lines == 0
    lines\runCallback (lines, line, i) ->
        aegisub.cancel! if aegisub.progress.is_cancelled!
        aegisub.progress.task "Removing tags from %d of %d lines..."\format i, #lines.lines if i%10==0
        aegisub.progress.set 100*i/#lines.lines
        data = ASS\parse line
        tagSectionCount = data\getSectionCount ASS.Section.Tag
        transforms = data\getTags "transform"
        switch btn
            -- when "Transform" then removeTransformSection sub, sel

            when "Remove All"
                if res.start_tag
                    data\removeTags _, 1, 1
                elseif res.inline_tags
                    data\removeTags _, 2, tagSectionCount
                else
                    data\stripTags!

            when "Remove Group"
                if res["inline_except_last"]
                    data\removeTags _, (collection.startTagIndex and collection.startTagIndex + 1 or 1), tagSectionCount - 1
                else
                    start, end_, tagsToDelete = 1, tagSectionCount, {}
                    end_ = 1 if res.start_tag
                    start = 2 if res.inline_tags
                    for key, value in pairs collection.removeGroupTags
                        continue unless res[key]
                        tagsToDelete = list.join tagsToDelete, value
                    tagsToDelete = list.diff ASS.tagSortOrder, tagsToDelete if res.invert
                    data = removeTags(data, tagsToDelete, start, end_, transforms)

            when "Remove Tags"
                local tagsToDelete
                if res.invert
                    tagsToDelete = [tag for tag in *collection.tagList when not res[tag]]
                else
                    tagsToDelete = [tag for tag in *collection.tagList when res[tag]]
                if res.start_tag
                    data = removeTags(data, tagsToDelete, 1, 1, transforms)
                elseif res.inline_tags
                    data\removeTags(tagsToDelete, 2, tagSectionCount)
                elseif res.transforms
                    data = removeTags(data, tagsToDelete, 1, 1, transforms, true)
                else
                    data = removeTags(data, tagsToDelete, _, _, transforms)
        data\cleanTags 2
        data\commit!
    lines\replaceLines!

depctrl\registerMacro main
