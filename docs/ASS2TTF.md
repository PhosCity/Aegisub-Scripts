<font color="green">**Available in Dependency Control**</font>

[Link to script](https://github.com/PhosCity/Aegisub-Scripts/blob/main/macros/phos.ASS2TTF.moon)

`ASS2TTF` allows you to convert shape from ass subtitles to a ttf font. This script
only works in shapes and not text. For best result use a shape with 7 alignment.
The only requirement for this script is to have fontforge in path.

# Usage

<video width="2560" height="1540" controls>
  <source src="../assets/ass2ttf.mp4" type="video/mp4">
Your browser does not support the video tag.
</video>

- Write a character you want to assign to the shape in the effect field. You
    cannot reuse same character twice. You also cannot use multiple character
    in effect field.
- Select lines with shapes in Aegisub.
- Run the script.
- Navigate to the folder where you want to save the font and input the filename
    of the font.
- You will find a ttf file exported in that folder with that name. Install it.
- In order to use it in Aegisub, use the filename as well.
