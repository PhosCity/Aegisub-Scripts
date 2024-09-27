<font color="green">**Available in Dependency Control**</font>

[Link to script](https://github.com/PhosCity/Aegisub-Scripts/blob/main/modules/phos/AssfPlus.moon)

# Introduction

This is a module that will contain a lot of extensions for ASSFoundation.
Given how the development in ASSFoundation has not progressed for years,
this is the only way for me to add more features to it.
This will either fix things in ASSFoundation, extend an existing feature or
add a feature that does not exist at all.

# LineCollection

This acts on the line collected by LineCollection.

## collectTags

This collects all the tag's names present in the selected lines. Additionally, it collects information like if there are start tags, inline tags and transforms present in the line or not.

| Arguments     | Meaning                                                  | Type    | Default Value |
| ------------- | -------------------------------------------------------- | ------- | ------------- |
| lines         | LineCollection line table                                | table   | -             |
| errorOnNoTags | Exit the script if no tags were collected with a message | boolean | false         |
| checkDrawing  | Also collects \p tags                                    | boolean | false         |

| Returns    | Description                        | Type  |
| ---------- | ---------------------------------- | ----- |
| collection | A table with all the info collectd | table |

The collection returns a table in the following format:

```moon
collection =
    tagList: {}
    tagTypes: {start_tag: false, inline_tags: false, transforms: false}
    multiple_inline_tags: false
```

Usage:

```moon
lines = LineCollection sub, sel
return if #lines.lines == 0
collection = AssfPlus.LineCollection.collectTags lines
```

# Line Data

## getLineBounds

This is similar to `getLineBounds` of ASSFoundation but this allows you to get
the line bounds after removing border, shadows, clip and blur. All of these
tags affect the line bounds. So when I need to find the line bounds of fill of
text only for example, I can disable them and get actual line bounds.

| Arguments     | Meaning                          | Type    | Default Value |
| ------------- | -------------------------------- | ------- | ------------- |
| data          | Assf Line Contents               | -       | -             |
| noBordShad    | bounds without border and shadow | boolean | false         |
| noClip        | bounds without clips             | boolean | false         |
| noBlur        | bounds without blur              | boolean | false         |
| noPerspective | bounds without perspective       | boolean | false         |

| Returns | Description              | Type  |
| ------- | ------------------------ | ----- |
| bounds  | Line bounds same as assf | Table |

```moon
data = ASS\parse line

-- This will give you the same result as assf will.
bounds = lineData.getLineBounds data

-- This will give you line bounds after removing borders and shadows
bounds = lineData.getLineBounds data, true

-- This will give you line bounds after removing, borders, shadows, clips, blurs and perspective.
bounds = lineData.getLineBounds data, true, true, true, true
```

## getBoundingBox

It's purpose is just like [getLineBounds](#getlinebounds) but this will give
you the co-ordinates of the bounding box. It's just a convenience function.

| Arguments                               |
| --------------------------------------- |
| Same as [getLineBounds](#getlinebounds) |

| Returns        | Type   |
| -------------- | ------ |
| x1, y1, x2, y2 | Number |

```moon
data = ASS\parse line
x1, y1, x2, y2 = lineData.getBoundingBox data, true
```

## firstSectionIsTag

Find out if there is a tag section before text section or drawing section.

| Arguments | Meaning            | Type | Default Value |
| --------- | ------------------ | ---- | ------------- |
| data      | Assf Line Contents | -    | -             |

| Returns                                         | Type    |
| ----------------------------------------------- | ------- |
| true if there is a tag section in the beginning | boolean |
| the index of start tag section                  | integer |

## trim

While assf does have a trim method, it only trims the spaces from the
beginning and the end of the line but it does not trim spaces around line
breaks. These spaces can mess up calculation of text extents.

| Arguments | Meaning            | Type | Default Value |
| --------- | ------------------ | ---- | ------------- |
| data      | Assf Line Contents | -    | -             |

| Returns |
| ------- |
| Nothing |

```moon
data = ASS\parse line
lineData.trim(data)
```

## getTextShape

There is really no way to convert text to shape in Linux reliably (not even ILL at the time of this writing)
and there is no way to use Assf to convert text to shape in any OS at all.
This is just a temporary workaround until a proper fix for it is made.

There were two main problems that I faced:

- Any text that is more than 18 characters are truncated when converted to shapes. I fixed this by splitting the text into chunks of 15 characters, converting them to shape and then appending them together.
- There were many fonts where the aegisub.text_extents and pangocairo gave wrong font extents and metrics. This caused the converted shape to be scaled incorrectly. I tried to fix it by using SubInspector which correctly returns bounds of the actual generated bitmaps.

The resulting shape has an alignment of 7, scale of 100 and is anchored to position (0,0).

Known cases where it may not work:

- Gradient by character
- Negative spacing

| Arguments | Meaning            | Type | Default Value |
| --------- | ------------------ | ---- | ------------- |
| data      | Assf Line Contents | -    | -             |

| Returns | Type   |
| ------- | ------ |
| Shape   | String |
| Width   | Number |
| Height  | Number |

```moon
data = ASS\parse line
shape = lineData.getTextShape data
shape, width, height = lineData.getTextShape data
```

## convertTextToShape

Convert and replace the text in current line to shape.

| Arguments | Meaning            | Type | Default Value |
| --------- | ------------------ | ---- | ------------- |
| data      | Assf Line Contents | -    | -             |

| Returns |
| ------- |
| nil     |

```moon
data = ASS\parse line
lineData.convertTextToShape data
```

## changeAlignment

Change alignment of a line while maintaining its position.

| Arguments | Meaning                | Type   | Default Value |
| --------- | ---------------------- | ------ | ------------- |
| data      | Assf Line Contents     | -      | -             |
| alignment | Alignment to change to | number | 7             |

| Returns |
| ------- |
| nil     |

```moon
data = ASS\parse line
lineData.changeAlignment data, 5
data\commit!
```

## insertTransformTags

This inserts transform tags. Honestly this exists because I could not figure out how to insert transform tags natively.

| Arguments       | Meaning                                                                                                                                        | Type    | Default Value |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------- | ------------- |
| data            | Assf Line Contents                                                                                                                             | -       | -             |
| tags            | Table of Assf Tag Object                                                                                                                       | table   | -             |
| t1              | Start time of transform in miliseconds                                                                                                         | integer | -             |
| t2              | End time of transform in miliseconds                                                                                                           | integer | -             |
| accel           | Accel of transform                                                                                                                             | float   | -             |
| index           | Index of Assf section in which to insert transform tag                                                                                         | integer | 1             |
| sectionPosition | Position within an Assf section in which to insert transform tag                                                                               | integer | -             |
| direct          | if true, considers all sections and attempts to insert in that section if that section is tag section. if false it only considers tag sections | boolean | false         |

| Returns |
| ------- |
| nil     |

```moon
AssfPlus.lineData.insertTransformTag data, {ASS\createTag('alpha1', 0)},
    0, 200, 0.5, 1, _, true
```

# Text Section

## getTags

While you don't necessarily don't need `getTags` in a text section, I sometimes
find myself needing to know which tags actually exists in the line rather than
effective tags in the line. If you want to act on a tag, it's still better to
use `getEffectiveTags` btw. This is for getting information on which tags
exists in line for the current text section.

| Arguments | Meaning                            | Type    | Default Value |
| --------- | ---------------------------------- | ------- | ------------- |
| data      | Assf Line Contents                 | -       | -             |
| section   | Assf text section                  | -       | -             |
| listOnly  | if you only need list of tag names | boolean | false         |

| Returns                                                                   |
| ------------------------------------------------------------------------- |
| Assf tagList if listOnly is false, list of tag's name if listOnly is true |

```moon
tags = textSection.getTags data, section
if tags.fontname
    -- do things here if \fn exists in the line before this section
```

Get the list of tag names only

```moon
tags = textSection.getTags data, section, true
```

# Tag Section

## replaceTags

Replace tags method does not exist for tag section.

| Arguments | Meaning                                | Type   |
| --------- | -------------------------------------- | ------ |
| section   | Assf Tag Section                       | -      |
| tags      | Table of Assf Tag Objects              | -      |
| index     | Index at which to add the replaced tag | Number |

| Returns |
| ------- |
| nil     |

Index can be -1 to add the tag at the end of the tag section. If the tag section contains reset tag, then the tags will automatically add it to the end of the tag section.

```moon
AssfPlus.tagSection.replaceTags section, {
    ASS\createTag("outline", 0),
    ASS\createTag("shadow", 0),
    ASS\createTag("alpha4", 255),
}, -1
```

# Tags

## Color

### extractColor

Extract the R, G and B value of a color. The input can be the color string or a color object made by Assf.

| Arguments | Type                                       |
| --------- | ------------------------------------------ |
| color     | colorString or {r, g, b} or assf color tag |

| Returns | Type   |
| ------- | ------ |
| r, g, b | Number |

```moon
r, g, b = _tag.color.extractColor "&H1010CF&"
r, g, b = _tag.color.extractColor {73, 201, 37}
r, g, b = _tag.color.extractColor {ASS\createTag "color1", 73, 201, 37}
```

### getDeltaE

This will compare 2 colors to check how similar they are.
The similarity is based on human perception.
If delta E value is less than 1, then they appear the same
for human eyes. If they're 1 - 2, then they need to be observed
carefully to find difference.

| Arguments | Type                                       |
| --------- | ------------------------------------------ |
| color1    | colorString or {r, g, b} or assf color tag |
| color2    | colorString or {r, g, b} or assf color tag |

| Returns       | Type   |
| ------------- | ------ |
| delta E value | Number |

```moon
deltaEValue = _tag.color.getDeltaE "&H1010CF&", "&H1515A9&"
deltaEValue = _tag.color.getDeltaE {73, 201, 37}, {169, 21, 21}
deltaEValue = _tag.color.getDeltaE {ASS\createTag "color1", 73, 201, 37}, {ASS\createTag "color1", 169, 21, 21}

```

### getXYZ

Converts RGB to XYZ. I needed to convert the color from RGB to XYZ to LAB for delta E calculation.
That's the only reason why this exists.

| Arguments | Type                                       |
| --------- | ------------------------------------------ |
| color     | colorString or {r, g, b} or assf color tag |

| Returns | Type   |
| ------- | ------ |
| X, Y, Z | Number |

```moon
X, Y, Z = _tag.color.getXYZ "&H1010CF&"
X, Y, Z = _tag.color.getXYZ {73, 201, 37}
X, Y, Z = _tag.color.getXYZ {ASS\createTag "color1", 73, 201, 37}
```

### getLAB

Converts RGB to LAB.

| Arguments | Type                                       |
| --------- | ------------------------------------------ |
| color     | colorString or {r, g, b} or assf color tag |

| Returns | Type   |
| ------- | ------ |
| L, A, B | Number |

```moon
L, A, B = _tag.color.getLAB "&H1010CF&"
L, A, B = _tag.color.getLAB {73, 201, 37}
L, A, B = _tag.color.getLAB {ASS\createTag "color1", 73, 201, 37}
```

# Shapes

## Pathfinder

This allows us to perform various boolean operations in shapes. This depends on ILL.

This takes the shape1 and shape2, performs the boolean operation on them and then the resulting shape is saved on shape1.

The different modes are "Unite", "Intersect", "Difference" and "Exclude"

| Arguments | Type                                                                                 |
| --------- | ------------------------------------------------------------------------------------ |
| mode      | string                                                                               |
| shape1    | Assf Drawing Section or Assf Drawing                                                 |
| shape2    | Assf drawing Seciton or Assf Drawing or Assf rectangular clip or Assf vectorial clip |

| Returns |
| ------- |
| nil     |

```moon
_shape.pathfinder "Intersect", shape1, shape2
```

# Utils

These are some of the functions that are not necessarily related to assf.

## setOgLineExtradata

This saves the original line in extradata so that the changes made by scripts can be reverted later on.
The extradata name provided should be unique to that script.

| Arguments     | Type                                |
| ------------- | ----------------------------------- |
| line          | Aegsiub line or LineCollection line |
| extradataName | string                              |

| Returns |
| ------- |
| nil     |

```moon
for line in *sel
    _util.setOgLineExtradata line, "a-mo"
```

## revertLines

This reverts the line if there is original line present in extradata saved using `setOgLineExtradata`.

| Arguments     | Type                                 |
| ------------- | ------------------------------------ |
| sub           | subtitle table from Aegisub api      |
| sel           | selected line table from Aegisub api |
| extradataName | string                               |

| Returns |
| ------- |
| nil     |

```moon
for line in *sel
    _util.revertLines sub, sel, "a-mo"
```

## windowError

This shows the message and exits the script

| Arguments    | Type   |
| ------------ | ------ |
| errorMessage | string |

| Returns |
| ------- |
| nil     |

```moon
_util.windowError "This is an error message."
```

## windowAssertError

This shows the message and exits the script if the condition is false.

| Arguments    | Type    |
| ------------ | ------- |
| condition    | boolean |
| errorMessage | string  |

| Returns |
| ------- |
| nil     |

```moon
_util.windowError a > b, "a was not greater than b unfortunately."
```

## Progress Reporting

This shows a progress bar and counter as well as a title for the progress window.

| Arguments | Meaning             | Type    |
| --------- | ------------------- | ------- |
| title     | Title of the window | string  |
| count     | current count       | integer |
| total     | total count         | integer |

| Returns |
| ------- |
| nil     |

```moon
Assf._util.progress "Removing Lines", 1, 100
```

## Check Cancellation

This checks if user has cancelled the script and if they have then stops the further execution of the script.

| Arguments |
| --------- |
| nil       |

| Returns |
| ------- |
| nil     |

```moon
Assf._util.checkCancellation!
```

## checkVideoIsOpen

This checks if a video is loaded or not in the current subtitle file.

| Arguments |
| --------- |
| nil       |

| Returns                                                           |
| ----------------------------------------------------------------- |
| boolean true if video is open, boolean flase if video is not open |

```moon
if Assf._util.checkVideoIsOpen!
    -- do something here if video is open
else
    -- do something here if video is closed
```

## getFramerate

The gets the framerate of the video that is open. The framerate is in frame per second.
If the video is not open the framerate returned is 23.379 fps.

| Arguments         | Meaning                                 | Default Value |
| ----------------- | --------------------------------------- | ------------- |
| default_framerate | Framerate returned if video is not open | 23.379        |

| Returns                       |
| ----------------------------- |
| framerate in frame per second |

```moon
fps = Assf._util.getFramerate!
```

# Credits

This module stands on the shoulders of giants that did most of the work.

- ASSFoundation (Obviously)
- Perspective by Arch (For things related to perspective)
- ILL (For things related to shapes)
- Yutils
- SubInspector
