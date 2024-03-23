<font color="red">**Not Available in Dependency Control**</font>

[Link to script](https://github.com/PhosCity/Aegisub-Scripts/blob/main/modules/phos/AssfPlus.moon)

# Introduction

This is a module that will contain a lot of extensions for ASSFoundation.
Given how the development in ASSFoundation has not progressed for years,
this is the only way for me to add more features to it.
This will either fix things in ASSFoundation, extend an existing feature or
add a feature that does not exist at all.

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
x1, y1, x2, y2 = lineData.getBoundingBox data, true
```

## firstSectionIsTag

Find out if there is a tag section before text section or drawing section.

| Arguments | Meaning            | Type | Default Value |
| --------- | ------------------ | ---- | ------------- |
| data      | Assf Line Contents | -    | -             |

| Returns                                         |
| ----------------------------------------------- |
| true if there is a tag section in the beginning |

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

# Tags

## Color

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

# Logging
