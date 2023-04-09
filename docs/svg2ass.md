<font color="green">**Available in Dependency Control**</font>

[Link to script](https://github.com/PhosCity/Aegisub-Scripts/blob/main/macros/phos.svg2ass.moon)

The script svg2ass is a wrapper for a program [svg2ass](https://github.com/irrwahn/svg2ass) which allows you to select an SVG file from Aegisub itself and convert it to shape, clip or iclip. It works in both windows and Unix operating system. I generally create SVG files using GIMP(can perform complex selections and convert those selections to SVG in a matter of seconds) or Inkscape and use svg2ass to convert them to subtitle lines.

!!! info

    If you cannot/do not want to compile svg2ass, there is also a [website](https://qgustavor.github.io/svg2ass-gui/) where you can upload the SVG file to obtain the output.

The first thing you should do is to set the config and provide the path where you have the svg2ass executable. At the same time, you can also provide custom tags you want to append to final result and the custom svg2ass parameters if you prefer.

![svg2ass_config](./assets/svg2ass_config.png)

To use this script, simply click on `Import` button and select the SVG file. The resulting lines will have the same start time, end time and style as the selected line. If you checked clip or iclip in the GUI, the resulting shape will be converted to clip or iclip respectively. Alternatively if you don't have the svg2ass executable, you can get the output of svg2ass from the website and paste the result in the textbox and click on the `Textbox` button. The resulting lines will the same as `Import`.

![svg2ass](./assets/svg2ass.png)
