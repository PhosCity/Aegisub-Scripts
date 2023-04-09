<font color="red">**Not Available in Dependency Control**</font>

[Link to script](https://github.com/PhosCity/Aegisub-Scripts/blob/main/macros/phos.FitTextInClip.moon)

<video width="960" height="540" controls>
  <source src="https://user-images.githubusercontent.com/65547311/215322416-523ba2cf-d8e1-41d3-a0a8-264550c5fe92.mp4" type="video/mp4">
Your browser does not support the video tag.
</video>

This script will fit the text in the current line inside the rectangular clip and try to make it justified.

!!! warning

    This script uses [Yutils](https://github.com/TypesettingTools/Yutils) to determine the width of the text. Therefore, the efficacy of this script entirely depends on whether Yutils can accurately determine the width of the text.

# Usage

- Add `\an7` to the line.
- Move the line so that the top left corner of text is exactly where it should be.
- Draw a rectangular clip starting very close to top left corner of the text such that the width of the clip is equal to the length of the text you want to be fitted to.
- Run the script.
