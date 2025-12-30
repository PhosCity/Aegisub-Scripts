<font color="green">**Available in Dependency Control**</font>

[Link to script](https://github.com/PhosCity/Aegisub-Scripts/blob/main/macros/phos.AlignAndDistribute.moon)

# Introduction

This script is inspired from `Align and Distribute` feature from Inkscape.
It is used to align the lines relative to something.
The alignment is done along the top, center and bottom edge vertically and along
the left, center and right edge of line horizontally.

!!! note

    Everything this script does is based on the bounding box of the line. So
    things like position or alignment of the line doesn't matter.

Lines can be align relative to:

1. Video
1. PlayRes
1. LayoutRes (If the file has one)
1. Rectangular Clip (If the line has one)
1. First or last line of the selection
1. Any custom line of the selection


<video width="2560" height="1546" controls>
  <source src="../assets/Align and Distribute/align_1.mp4" type="video/mp4">
Your browser does not support the video tag.
</video>

<video width="2560" height="1546" controls>
  <source src="../assets/Align and Distribute/align_2.mp4" type="video/mp4">
Your browser does not support the video tag.
</video>

<video width="2560" height="1546" controls>
  <source src="../assets/Align and Distribute/align_3.mp4" type="video/mp4">
Your browser does not support the video tag.
</video>

<video width="2560" height="1546" controls>
  <source src="../assets/Align and Distribute/align_4.mp4" type="video/mp4">
Your browser does not support the video tag.
</video>

The lines can also be distributed. This means to make all the selected lines
equidistant from each other. The first line and the last line of the selection
is taken as the reference line.

<video width="2560" height="1546" controls>
  <source src="../assets/Align and Distribute/align_5.mp4" type="video/mp4">
Your browser does not support the video tag.
</video>
