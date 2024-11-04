<font color="green">**Available in Dependency Control**</font>

[Link to script](https://github.com/PhosCity/Aegisub-Scripts/blob/main/macros/phos.ASS2SVG.moon)

`ASS2SVG` allows you to convert shape from ass subtitles to svg path that you can open in program like Inkscape and make changes to it. This is a companion script to [inkscape-svg2ass](https://github.com/PhosCity/inkscape-svg2ass), an Inkscape extension that converts svg path to ass shape.

!!! warning "Warning"

    This script only works in shapes and not text. This is because of differences in the semantics of how text is rendered in SVG that is very different than ASS. This not only makes the sizes of fonts different but there is also no 3D transformation of text in SVG which makes exporting tags like frx and fry impossible.

# Usage

<video width="2560" height="1540" controls>
  <source src="../assets/ass2svg.mp4" type="video/mp4">
Your browser does not support the video tag.
</video>

- Select lines with shapes in Aegisub.
- Run the script.
- Navigate to the folder where you want to save the svg and input the filename of the svg.
- You will find a file exported in that folder with that name.
