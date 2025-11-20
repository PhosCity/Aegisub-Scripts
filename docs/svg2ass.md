<font color="green">**Available in Dependency Control**</font>

[Link to script](https://github.com/PhosCity/Aegisub-Scripts/blob/main/macros/phos.svg2ass.moon)

The script svg2ass allows you to select an SVG file from Aegisub itself and convert it to shape, clip or iclip. It works in both windows and Unix operating system. I generally create SVG files using GIMP(can perform complex selections and convert those selections to SVG in a matter of seconds) or Inkscape and use svg2ass to convert them to subtitle lines.

In order to convert svg to ass, you will need to download [a python file](https://github.com/PhosCity/Aegisub-Scripts/blob/main/misc/phos.ink2ass.py) and save it somewhere. You also need ton install python itself if you haven't already. Finally you need to install a python module named _inkex_. You can find a guide to how to install python and python module all over the internet if you don't know already.

Once you install this script, the first thing you should do in Aegisub is to set the config and provide the path where you have the ink2ass python file is located. To do this, go to Automation -> svg2ass -> Config in Aegisub and select the file in file browser.

To use this script, simply click on `Import` button and select the SVG file. The resulting lines will have the same start time, end time and style as the selected line. If you checked clip or iclip in the GUI, the resulting shape will be converted to clip or iclip respectively.

![svg2ass](./assets/svg2ass.png)
