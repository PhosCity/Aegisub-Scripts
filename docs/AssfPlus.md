<font color="red">**Not Available in Dependency Control**</font>

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

| Arguments  | Meaning                | Type              | Default Value |
| ---------- | ---------------------- | ----------------- | ------------- |
| data       | duration of line in ms | Assf Line Conents | -             |
| noBordShad | start frame of a line  | boolean           | false         |
| noClip     | end frame of a line    | boolean           | false         |
| noBlur     | style table            | boolean           | false         |

| Returns | Description              | Type  |
| ------- | ------------------------ | ----- |
| bounds  | Line bounds same as assf | Table |

```moon
-- This will give you the same result as assf will.
bounds = lineData.getLineBounds data

-- This will give you line bounds after removing borders and shadows
bounds = lineData.getLineBounds data, true

-- This will give you line bounds after removing, boreders, shadows, clips and blurs.
bounds = lineData.getLineBounds data, true, true, true
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

# Text Section

# Shapes

# Logging
