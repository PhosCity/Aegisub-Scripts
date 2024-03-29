# Introduction

[ASSFoundation](https://github.com/TypesettingTools/ASSFoundation), henceforth called assf, is a module that aims to make working with subtitle object efficient. It does most of the heavy lifting so that we can do more with less lines of code in our script. No need to use messy regular expressions, define the types of tags and the nature of their values. No need to reinvent the wheel and write functions to work in subtitle object or write your own module for common things.

This guide assumes that you already know [how to write Aegisub scripts](https://unanimated.github.io/ts/ts-lua.htm) and know the basics of [Moonscript](https://moonscript.org/reference/).

Here's the very basics:

```moonscript
export script_name = "name of the script"
export script_description = "description of your script"
export script_version = "0.0.1"
export script_author = "you"
export script_namespace = "namespace of your script"

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

functionName = (sub, sel, act) ->
  -- stuff goes here

depctrl\registerMacro functionName
```

This is the framework that all your scripts will have. Here we import LineCollection and assf and define a function called functionName. This function name is what we register in aegisub in the last line. Everything we do below will go inside the function where `--stuff goes here` is written. We also define logger for logging purposes but if you don't need to log anything, you can remove that line.

# LineCollection

LineCollection is actually not a part of assf but almost anything that assf does will act on the line table generated by LineCollection. The line table generated by LineCollection will have all the elements of a normal line table like start_time, actor, end_time etc but in addition, it also adds other elements. Apart from the [basic fields of line table](https://aeg-dev.github.io/AegiSite/docs/3.2/automation/lua/modules/karaskel.lua/#dialogue-line-table), following fields are now available to you.:

| Fields          | Meaning                           | Type    |
| --------------- | --------------------------------- | ------- |
| duration        | duration of line in ms            | integer |
| startFrame      | start frame of a line             | integer |
| endFrame        | end frame of a line               | integer |
| styleRef        | style table                       | table   |
| number          | number of line in subtitle file   | integer |
| humanizedNumber | number of line as seen in Aegisub | integer |

Some of the methods LineCollection provides to us to modify subtitles are:

| Method         | Usage                           | Meaning                                                                             |
| -------------- | ------------------------------- | ----------------------------------------------------------------------------------- |
| LineCollection | lines = LineCollection sub, sel | Add all the selected lines to a variable named `lines`. It ignores commented lines. |
| replaceLines   | lines\replaceLines!             | Any change you make to `lines` will be put back to the subtitle                     |
| deleteLines    | lines\deleteLines!              | Delete all the lines                                                                |
|                | lines\deleteLines tbl           | Provide a table of line to delete those lines only                                  |
| insertLines    | lines\insertLines!              | insert lines to subtitle file                                                       |
|                | newLines\insertLines            | Insert a new set of lines that you defined called newLines                          |
| addline        | lines\addLine                   | add line to subtitle file                                                           |

You can actually work in the line table generated by LineCollection without using assf as shown in an example below where we change the effect of the line to "Actor".

```moonscript
functionName = (sub, sel) ->
  lines = LineCollection sub, sel
  for line in *lines
    line.effect = "Actor"
  lines\replaceLines!
```

But we'll use LineCollection alongside assf to get the most out of both of them.

# Logger

Logger is a logging module from dependency control that you can use to log messages. If you do not pass log level, default log level is 2. By default, Aegisub's log level is set to 3 which means that the message above 3 wont be seen by end user unless they set the log level higher themself. The script exits after showing message if the log level is below 2.

```moonscript
logger\log "A simple message inside quotes"
logger\log 4, "A simple message inside quotes but with log level 4"

-- dump is the most useful part of logger as far as debugging goes.
-- You can pass a table and it'll show you a nice formatted view with all it's keys and values.
logger\dump table

-- With predefined log levels
logger\fatal "message"                                                      -- log level 0
logger\error "message"                                                      -- log level 1
logger\warn "message"                                                       -- log level 2
logger\hint "message"                                                       -- log level 3
logger\debug "message"                                                      -- log level 4
logger\trace "message"                                                      -- log level 5
logger\assert condition, "Show this message if the condition is false"      -- log level 1
```

# ASSFoundation

## Name of tags as understood by assf

| Tag     | Assf name   |
| ------- | ----------- |
| \\fscx  | scale_x     |
| \\fscy  | scale_y     |
| \\an    | align       |
| \\frz   | angle       |
| \\fry   | angle_y     |
| \\frx   | angle_x     |
| \\bord  | outline     |
| \\xbord | outline_x   |
| \\ybord | outline_y   |
| \\shad  | shadow      |
| \\xshad | shadow_x    |
| \\yshad | shadow_y    |
| \\r     | reset       |
| \\pos   | position    |
| \\move  | move        |
| \\org   | origin      |
| \\alpha | alpha       |
| \\1a    | alpha1      |
| \\2a    | alpha2      |
| \\3a    | alpha3      |
| \\4a    | alpha4      |
| \\1c    | color1      |
| \\2c    | color2      |
| \\3c    | color3      |
| \\4c    | color4      |
| \\clip  | clip_vect   |
| \\iclip | iclip_vect  |
| \\clip  | clip_rect   |
| \\iclip | iclip_rect  |
| \\p     | drawing     |
| \\be    | blur_edges  |
| \\blur  | blur        |
| \\fax   | shear_x     |
| \\fay   | shear_y     |
| \\b     | bold        |
| \\i     | italic      |
| \\u     | underline   |
| \\s     | strikeout   |
| \\fsp   | spacing     |
| \\fs    | fontsize    |
| \\fn    | fontname    |
| \\k     | k_fill      |
| \\kf    | k_sweep     |
| \\ko    | k_bord      |
| \\q     | wrapstyle   |
| \\fad   | fade_simple |
| \\fade  | fade        |
| \\t     | transform   |

## Loop through all selected lines

```moonscript
lines = LineCollection sub, sel
return if #lines.lines == 0
lines\runCallback (lines, line, i) ->
```

This loops through all selected lines. If the number of lines is 0, exits out. Here `line` is the line table for the current line and `i` is the index of line i.e. the first selected line has index 1 and second has index 2 and so on.

## Line Data

This creates a line data for each line. Everything assf does will be acted on this line data.

```moonscript
lines = LineCollection sub, sel
return if #lines.lines == 0
lines\runCallback (lines, line, i) ->
  data = ASS\parse line
```

## Sections

In assf, a single line can have four different types of sections. Their names make them self-explanatory so I'll only list them.

1. ASS.Section.Text
1. ASS.Section.Tag
1. ASS.Section.Drawing
1. ASS.Section.Comment

## Work in different sections of a line

```moonscript
lines = LineCollection sub, sel
return if #lines.lines == 0
lines\runCallback (lines, line, i) ->
  data = ASS\parse line
  data\callback (section) ->
    if section.class == ASS.Section.Tag
      -- do stuff to tags
    elseif section.class == ASS.Section.Text
      -- do stuff to text
    elseif section.class == ASS.Section.Comment
      -- do stuff to comment
    elseif section.class == ASS.Section.Drawing
      -- do stuff to drawing
```

If you care, you can download this [example script](./examples/sections.moon) and try this in different types of lines (with/without tags, comments, drawings, text, gbc etc.) to get a idea of how assf treats different sections of a line.

If you want to work in an individual section, you can do the following:

Example: Working with only text of line

```moonscript
data = ASS\parse line
data\callback ((section) ->
  --obtain the text
  text = section.value
  -- do stuff to text of line
), ASS.Section.Text
```

Example: Working with only tags of line

```moonscript
data = ASS\parse line
data\callback ((section) ->
  for tags in *section\getTags!
    -- do stuff to tags of line
), ASS.Section.Tag
```

### Modifying text

#### Change whole text

```moonscript
data = ASS\parse line
data\callback ((section) ->
  section.value = "Change the text to this."
), ASS.Section.Text
data\commit!
```

#### Append text to the existing text

`string\append str, sep`

str = string you want to append to the text

sep = string that seperates your text and str

```moonscript
data = ASS\parse line
data\callback ((section) ->
  section\append "string you want to append"
), ASS.Section.Text
data\commit!
```

#### Prepend text to the existing text

```moonscript
data = ASS\parse line
data\callback ((section) ->
  section\prepend "string you want to prepend"
), ASS.Section.Text
data\commit!
```

#### Replace text

`string\replace pattern, replacement, plainMatch, useRegex`

If `useRegex` is true, regular expressions (re module) can be used else gsub is used for replacement.

If `plainMatch` is true, then `useRegex` is automatically set to false and any thing that must be escaped in the pattern is escaped and any thing that must be escaped in the pattern is escaped for gsub to work.

```moonscript
data = ASS\parse line
data\callback ((section) ->
  section\replace "pattern you want to replace", "replacment for pattern"
), ASS.Section.Text
data\commit!
```

### Modifying Tags

#### [getDefaultTags](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L636)

```moonscript
data = ASS\parse line
styleTags = data\getDefaultTags!
-- Then we can access a table for each tag as such
angleTable = styleTags.tags.angle
-- We can directly get the value as:
angle= styleTags.tags.angle\get!
```

#### [insertDefaultTags](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L349)

| Parameters     | Meaning                                                                                                       | Type            |
| -------------- | ------------------------------------------------------------------------------------------------------------- | --------------- |
| tagnames       | names of tag or table of tag's name                                                                           | string or table |
| index          | index of section i.e. 1 = first section and so on                                                             | integer         |
| sectionPostion | position where tag is inserted ({\1\2\3...})                                                                  | integer         |
| direct         | if true, index considers all sections and errors if index is not tag section else only considers tag sections | boolean         |

```moonscript
data = ASS\parse line
data\insertDefaultTags "align"                            -- Insert a single tag
data\insertDefaultTags {"scale_x", "scale_y", "blur"}     -- Insert multiple tags
data\insertDefaultTags "fontname", 2                      -- Insert tag at second tag block
data\commit!
```

A way to change the value of the default tag you inserted is:

```moonscript
data = ASS\parse line
blur = data\insertDefaultTags "blur"
blur.value = 5
data\commit!
```

#### [getEffectiveTags](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L313)

| Parameters      | Meaning                                                                                        | Type    |
| --------------- | ---------------------------------------------------------------------------------------------- | ------- |
| index           | index of section of which effective tag is being required (It considers all types of sections) | integer |
| includeDefault  | include style tag value if override tag is not found                                           | boolean |
| includePrevious | consider the tag value of tag section before current section                                   | boolean |
| copyTags        |                                                                                                | boolean |

```moonscript
data = ASS\parse line
-- Get effective tag values for last section
tags = (data\getEffectiveTags -1, true, true, false).tags

-- Then you can insert tags to line in following way
data\removeTags "align"
data\insertTags tags.align
data\commit!
```

#### [removeTags](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L313)

Remove tags already present in the line

| Parameters | Meaning                                            | Type            |
| ---------- | -------------------------------------------------- | --------------- |
| tagnames   | names of tag or table of tag's name                | string or table |
| start      | index of section from where to start removing tags | integer         |
| end        | index of selection upto which to remove tags       | integer         |
| relative   |                                                    | boolean         |

```moonscript
data = ASS\parse line
-- You can pass a single tag name to delete it
data\removeTags "outline"
-- You can pass a table of tag names to delete them all
data\removeTags {"align", "blur"}
-- Removes first instance of the tag blur
data\removeTags "blur", 1, 1
-- Removes second to fifth instance of the tag blur
data\removeTags "blur", 2, 5
data\commit!
```

NOTE: After you remove tags using `removeTags`, there might be stray '{}' left if that's the only tag. It is recommended that you use [cleanTags]() to remove them.
TODO: link the guide portion of clean

It is very useful to get a value of a tag to a variable using `removeTags` as well

```moonscript
path = data\removeTags({"clip_vect","iclip_vect"})
```

#### [insertTags](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L331)

Insert tags to current line.

| Parameters | Meaning                                                                                               | Type              |
| ---------- | ----------------------------------------------------------------------------------------------------- | ----------------- |
| tag        | tag instance you want to insert                                                                       | assf tag instance |
| start      | index of section from where to start removing tags                                                    | integer           |
| end        | index of selection upto which to remove tags                                                          | integer           |
| relative   | if true, only tag section is considered (i.e. 2 = second tag section not literal 2nd section in line) | boolean           |

```moonscript
data = ASS\parse line
tags = (data\getEffectiveTags -1, true, true, false).tags
data\insertTags tags.shadow
data\insertTags tags.scale_x, 2
data\insertTags tags.scale_y, -1
```

#### [createTag](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/FoundationMethods.moon#L65)

Create a new instance of tags.

```moonscript
data = ASS\parse line
data\removeTags "position"
pos = ASS\createTag 'position', 5, 50
data\insertTags pos
data\commit!
```

Alternatively, you can direct insert a tag without assigning it to a variable.

```moonscript
data = ASS\parse line
data\insertTags {ASS\createTag 'position', 5, 50}                 -- \pos(5,50)
data\insertTags {ASS\createTag 'outline', 5}                      -- \bord5
data\insertTags {ASS\createTag 'blur', 0.8}                       -- \blur0.8
data\insertTags {ASS\createTag 'move', 0, 0, 50, 50}              -- \move(0,0,50,50)
data\insertTags {ASS\createTag 'move', 0, 0, 50, 50, 25, 500}     -- \move(0,0,50,50,25,500)
data\insertTags {ASS\createTag 'clip_rect', 50, 50, 500, 500}     -- \clip(50,50,500,500)
data\insertTags {ASS\createTag 'drawing', 1}                      -- \p1
data\insertTags {ASS\createTag "transform", {tags}, t1, t2}       -- transfrom all tags inside {tags} from time t1 to t2

-- creating Vectorial Clip
m = ASS.Draw.Move
l = ASS.Draw.Line
data\insertTags {ASS\createTag 'clip_vect', {m(0,0), l(500,500), l(700,100)}}         -- \clip( m 0 0 l 500 500 700 100)
data\commit!
```

Some tags like color and alpha can have special parameters

```moonscript
data\insertTags {ASS\createTag 'color1', 15, 34, 22}      -- b, g, r
data\insertTags {ASS\createTag 'alpha', 110}

-- You can also give hex as a parameter
data\insertTags {ASS\createTag 'alpha', "6E"}
```

#### [replaceTags](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L265)

Replace tags present in a line.

| Parameters      | Meaning                                                                                               | Type              |
| --------------- | ----------------------------------------------------------------------------------------------------- | ----------------- |
| tagList         | tag instance you want to replace                                                                      | assf tag instance |
| start           | index of section from where to start replacing tags                                                   | integer           |
| end             | index of selection upto which to replace tags                                                         | integer           |
| relative        | if true, only tag section is considered (i.e. 2 = second tag section not literal 2nd section in line) | boolean           |
| insertRemaining | if the tag you're replacing does not already exist in the line, it adds the tag to the line.          | boolean           |

```moonscript
data = ASS\parse line
bord = ASS\createTag "outline", 5
data\replaceTags bord                   -- Replace all bord tags
data\replaceTags bord, 2, 5, true       -- Replace bord from 2nd to 5th tag block
data\commit!
```

You can also create a new instance of tag and replace it in a single line

```moonscript
data = ASS\parse line
data\replaceTags {ASS\createTag "angle", 5}
data\commit!
```

#### [getTags](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L260)

Obtain the tags present in the line.

| Parameters | Meaning                                                                                               | Type            |
| ---------- | ----------------------------------------------------------------------------------------------------- | --------------- |
| tag name   | name of the tag                                                                                       | string or table |
| start      | index of section from where to look for tags                                                          | integer         |
| end        | index of selection upto which to look for tags                                                        | integer         |
| relative   | if true, only tag section is considered (i.e. 2 = second tag section not literal 2nd section in line) | boolean         |

```moonscript
data = ASS\parse line
bord = data\getTags "outline"         -- A table that has all the border values in this line
first = bord[1]\get!                  -- To get the first border value
first = bord[1].value                 -- Another way to get value
nth = bord[n]\get!                    -- Get nth border value

for b in *bord                        -- To get all values of border tags in a line
  logger\dump b\get!
```

To get multiple tag values

```moonscript
data = ASS\parse line
for tag in *data\getTags {"outline", "scale_x"}
  tagname = tag.__tag.name
  tagvalue = tag\getTagParams!
  logger\log "#{tagname}(#{tagvalue})"
```

```moonscript
tag = data\getTags "tagname", 1         -- Get first instance of tag value
tag = data\getTags "tagname", 1, 3      -- Get from first to third instance of tag value
tag = data\getTags "tagname", -1, -3    -- Get last instance of tag value
```

#### [modTags](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L245)

Modify tags already present in the line. If the tag is not found in the line, it does nothing.

| Parameters | Meaning                                      | Type            |
| ---------- | -------------------------------------------- | --------------- |
| tag name   | name of the tag                              | string or table |
| callback   |                                              | callback        |
| start      | index of section from where to modify tags   | integer         |
| end        | index of selection upto which to modify tags | integer         |
| relative   |                                              | boolean         |

```moonscript
data = ASS\parse line
data\modTags "outline", (tag) -> tag\add 1            -- Add 1 to all \bord in the line
data\modTags {"outline"}, ((tag) -> tag\add 1), 1, 3  -- Add 1 to \bord in 1st to 3rd tag block
data\commit!
```

You can have multiple lines for modifying tags, run functions inside them and so on.

```moonscript
data = ASS\parse line
data\modTags {"scale_x"}, (tag) ->
  old_value = tag.value
  new_value = old_value * 5
  tag.value = new_value
data\commit!
```

#### [getPosition](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L601)

Get position, alignment or org.

| Parameters   | Meaning              | Type    |
| ------------ | -------------------- | ------- |
| style        | line style           | string  |
| align        | alignment            | integer |
| forceDefault | ignore override \pos | boolean |

```moonscript
pos, align, org = data\getPosition!

-- Get position of the line if alignent were 7
pos, align, org = data\getPosition nil, 7

-- To get the actual value {\bord1do the following
pos_x, pos_y = pos.x, pos.y
org_x, org_y = org.x, org,y
an = align

-- Alternatively, you can also do something like this if you need value
x, y = data\getPosition!\getTagParams!
```

#### [getLineBounds](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L710)

```moonscript
data = ASS\parse line
bound = data\getLineBounds!
```

Then to get co-ordinate of the bounding box:

```moonscript
x1, y1 = bound[1].x, bound[1].y                 -- To get co-ordinate of top left boundary
x2, y2 = bound[2].x, bound[2].y                 -- To get co-ordinate of bottom right boundary
```

To get the dimension of the bounding box():

```moonscript
height = bound.h                                -- To get height of the text
width = bound.w                                 -- To get width of the text
```

An easy way to check if the text is visible in the screen or not is to check if height or width is 0 or not

To check if the text is animated or not (transform, move etc)

```moonscript
if bound.animated == true
  logger\log "Text is animated."
else
  logger\log "Text is not animated."
```

Then you can also loop over all the fbf lines to get their bounding box. This is also the same number of lines you'd get if you do line2fbf so you could probably do other interesting things by using this loop.

```moonscript
for item in *bound.fbf
  logger\dump item
```

#### [getString](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L112)

```moonscript
data = ASS\parse line
line_text =  data\getString!
```

To loop over tag blocks and get their string.

```moonscript
data = ASS\parse line
data\callback ((section) ->
  tag_text = section\getString!
), ASS.Section.Tag
```

Something similar for text

```moonscript
data = ASS\parse line
data\callback ((section) ->
  text = section\getString!
), ASS.Section.Text
```

  <!-- LineContents.cleanTags = (level = 3, mergeConsecutiveSections = true, defaultToKeep, tagSortOrder) => -->

#### cleanTags

Clean/Sort/Merge tags in the line.

| Parameters               | Meaning                                     | Type    | Default |
| ------------------------ | ------------------------------------------- | ------- | ------- |
| level                    |                                             | integer | 3       |
| mergeConsecutiveSections | level for cleanTags                         | boolean | true    |
| defaultToKeep            | adjust position after splitting             | table   |         |
| tagSortOrder             | add origin if needed to maintain appearance | table   |         |

Clean Level:

- 0: no cleaning
- 1: remove empty tag sections
- 2: deduplicate tags inside sections
- 3: deduplicate tags globally,
- 4: remove tags matching the style defaults and otherwise ineffective tags

```moonscript
data = ASS\parse line
data\cleanTags!
data\cleanTags 1
data\cleanTags nil, nil, nil, tagSortOrder              -- where tagSortOrder is the table of tags
```

Note: Make sure the tagSortOrder has all the tags in the table if you want to run it. There might be some unwanted results if done otherwise. Also the tags in the tagSortOrder must be the names of the tags as understood by assf.

#### Splitting Stuff

##### [splitAtIntervals](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L467)

| Parameters  | Meaning                                     | Type     | Default |
| ----------- | ------------------------------------------- | -------- | ------- |
| callback    |                                             | callback |         |
| cleanLevel  | level for cleanTags                         | integer  | 3       |
| reposition  | adjust position after splitting             | boolean  | true    |
| writeOrigin | add origin if needed to maintain appearance | boolean  |         |

```moonscript
data = ASS\parse line
char = data\splitAtIntervals 1, 4, false          -- split by characters
char = data\splitAtIntervals 2, 4, true, true     -- split by 2 characters

-- get nth split
n_char = char[n]
```

Working with split characters:

```moonscript
lines = LineCollection sub, sel

-- define newLines where we'll be adding each split characters
newLines = LineCollection sub

lines\runCallback (lines, line, i) ->
  data = ASS\parse line
  charLines = data\splitAtIntervals 2, 4, false          -- split by characters

  -- Looping through each interval
  for char in *charLines
    charData = char.ASS

    -- get effective tag for each split
    effTags = charData.sections[1]\getEffectiveTags(true,true).tags

    -- do stuff to each split here like adding new tags
    -- don't forget to add their position as well

    -- commit changes to the split
    charData\commit!
    newLines\addLine char

-- add new lines that contains all the splits
newLines\insertLines!

-- remove orignal lines
lines\deleteLines!
```

##### [repositionSplitLines](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L536)

After using any other split methods of assf, if you want the splits to maintain position, use this.

| Parameters  | Meaning                                     | Type    | Default |
| ----------- | ------------------------------------------- | ------- | ------- |
| splitLines  | split lines from other split methods        | integer | 3       |
| writeOrigin | add origin if needed to maintain appearance | boolean | true    |

```moonscript
lines = LineCollection sub, sel
newLines = LineCollection sub
lines\runCallback (lines, line, i) ->
  data = ASS\parse line
  charLines = data\splitAtIntervals 2, 4, false          -- split by 2 characters
  charLines = data\repositionSplitLines charLines
  for char in *charLines
    charData = char.ASS
    charData\commit!
    newLines\addLine char
newLines\insertLines!
lines\deleteLines!
```

##### [splitAtTags](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L452)

Split line at each tag block and get new lines

| Parameters  | Meaning                                     | Type    | Default |
| ----------- | ------------------------------------------- | ------- | ------- |
| cleanLevel  | clean level for \cleanTags                  | integer | 3       |
| reposition  | repostion split tags                        | boolean |         |
| writeOrigin | add origin if needed to maintain appearance | boolean |         |

```moonscript
lines = LineCollection sub, sel
newLines = LineCollection sub
lines\runCallback (lines, line, i) ->
  data = ASS\parse line
  splitLines = data\splitAtTags nil, true, true
  for char in *splitLines
    charData = char.ASS

    -- Here you can do stuff to each line before committing if you desire

    charData\commit!
    newLines\addLine char
newLines\insertLines!
lines\deleteLines!
```

#### Stripping Stuff

##### [stripTags](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L367)

Remove all tags present in the line.

```moonscript
data\stripTags!
```

##### [stripText](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L371)

Remove all text present in the line.

```moonscript
data\stripText!
```

##### [stripComments](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L375)

Remove all comments present in the line.

```moonscript
data\stripComments!
```

##### [stripDrawings](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L379)

Remove all drawings as well as `\\p` tags present in the line.

```moonscript
data\stripDrawings!
```

#### Miscellaneous

##### [trim](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L570)

Trim whitespace in the beginning or end of the text.

```moonscript
data\trim!
```

##### [getTagCount](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L362)

Get the total number of tags present in the line. Start as well as inline override tags - it counts all of them.

```moonscript
tagCount = data\getTagCount!
```

##### [getTextExtents](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L699)

Get the width of the text no matter it's orientation.

```moonscript
width = data\getTextExtents!
```

##### [getTextMetrics](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L737)

```moonscript
metrics = data\getTextMetrics!

-- Access different metrics
ascent = metrics.ascent
descent = metrics.descent
internal_leading = metrics.internal_leading
external_leading = metrics.external_leading
height = metrics.height
width = metrics.width
```

##### [getSectionCount](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L768)

Get the exact count of the type of section

```moonscript
tagSectionCount = data\getSectionCount ASS.Section.Tag
textSectionCount = data\getSectionCount ASS.Section.Text
drawingSectionCount = data\getSectionCount ASS.Section.Drawing
commentSectionCount = data\getSectionCount ASS.Section.Comment
```

##### [getTextLength](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L781)

Get the total number of characters in the text. Letters, spaces and punctuations.

```moonscript
len = data\getTextLength!
```

##### [isAnimated](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L786)

Check if the text is animated or not. Checks if there are transforms, move, fade or karaoke tags. It's intelligent enough to know that a single frame line can't be animated so it'll return false even if a single frame line has those tags.

```moonscript
checkAnimated = data\isAnimated!
```

##### [reverse](https://github.com/TypesettingTools/ASSFoundation/blob/ba2cace60efc39edfdedce1747b2b68aeff0af01/l0/ASSFoundation/LineContents.moon#L818)

It reverses the text of the current line. `It's huge.` will become `.eguh s'tI`. This is sometimes useful but the most useful part of this function is that it keeps the tags intact. So for example if you run this in gbc, the gbc will remain intact while the text will be reversed.

```moonscript
data\reverse!

-- you can also save it to a variable and do some stuff to it before committing it
rev = data\reverse!
```

#### Working with move

Check if move exists in a line

```moonscript
data = ASS\parse line
pos = data\getPosition!
if pos.class == ASS.Tag.Move
  logger\log "Move exists"
else
  logger\log "Move does not exist"
```

Check if the move is simple or not

```moonscript
-- if move is simple "\move(x1,y1,x2,y2)"
pos.__tag.signature == "simple"

-- else "\move(x1,y1,x2,y2,t1,t2)"
pos.__tag.signature == "default"
```

Obtain values of move tag

```moonscript
if pos.class == ASS.Tag.Move and pos.__tag.signature == "simple"
  x1, y1, x2, y2 = pos\getTagParams!
elseif pos.class == ASS.Tag.Move and pos.__tag.signature == "default"
  x1, y1, x2, y2, t1, t2 = pos\getTagParams!
```

It is also possible to obtain each value individually if you desire.

```moonscript
x1, y1 = pos.startPos\get!
x2, y2 = pos.endPos\get!
t1 = pos.startTime\get!
t2 = pos.endTime\get!
```

#### Working with transform

There are 3 types of transform

1. "accel" - \t(accel,style modifiers)
1. "default" - \t(t1,t2,accel,style modifiers)
1. "time" - \t(t1,t2,style modifiers)

To check if tags are transformed

```moonscript
data = ASS\parse line
tags = data\getEffectiveTags -1, true, true, false
transformed = tags\checkTransformed!
-- Get the list of all the tags that were transformed
for key, _ in pairs transformed
  logger\log key
```

To get the idea of how transform table is structured, you can run the following [script](./examples/transform.moon)

Obtain all parameters of transforms

```moonscript
data = ASS\parse line
transforms = data\getTags "transform"
for tr in *transforms
  t1, t2, tags = tr\getTagParams!
```

Change the times or accel in transforms (Here adding 100 to start time, 200 to end time and 5 to accel of all transforms)

```moonscript
data = ASS\parse line
transforms = data\getTags "transform"
for index, tr in ipairs transforms
  tr.startTime\add 100
  tr.endTime\add 200
  tr.accel\add 5
data\commit!
```

Modify tags inside transforms (In this case add 50 to fscx as an example)

```moonscript
data = ASS\parse line
transforms = data\getTags "transform"
for index, tr in ipairs transforms
  for tag in *tr.tags\getTags!
    if tag.__tag.name == "scale_x"
      tag\add 50
data\commit!
```

#### Working with fade

There are two types of fade. Simple fade (\\fad) and complex fade (\\fade).

```moonscript
-- Simple fade
fad = data\getTags "fade_simple"      -- Get simple fade
t1, t2 = fad\getTagParams!            -- Get parameters of simple fade

-- Complex fade
fade = data\getTags "fade"                            -- Get complex fade
a1, a2, a3, t1, t2, t3, t4 = fade\getTagParams!       -- Get parameters of simple fade
```

Parameters of fade tags:

| Parameters in assf | Equivalent fade parameters |
| ------------------ | -------------------------- |
| inAlpha            | a1                         |
| midAlpha           | a2                         |
| outAlpha           | a3                         |
| inStartTime        | t1                         |
| inDuration         | t2                         |
| outStartTime       | t3                         |
| outDuration        | t4                         |

Modifying fades

```moonscript
for tag in *data\getTags {'fade'}
  tag.inStartTime -= 150
  tag.outStartTime -= 150
```
