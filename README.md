# PhosCity's Aegisub Scripts Collection

1. [Bidirectional Snapping](#bidirectional-snapping)
1. [Wave](#wave)
1. [Wobble](#wobble)
1. [svg2ass](#svg2ass)
1. [Timing Assistant](#timing-assistant)
1. [Remove tags](#remove-tags)
1. [Edit Tags](#edit-tags)
1. [QC Report](#qc-report)

## Bidirectional Snapping

**_Available in Dependency Control_**

If you're a timer like me who does not use TPP and times primarily using hotkeys, then you'll be disappointed to know that Aegisub does not have hotkeys specifically for timing. While there are other scripts that allows you snap to keyframes, they are either a simple snap to adjacent keyframes or a TPP style snapping scripts. This one is geared towards timing.

While timing you might have come across the case multiple times where you go to the next line only to realize that the end time of the line overshoots the keyframe you want to snap to. Then you have no choice but to snap backwards using mouse. Here's where this script comes handy. This script is made to be hotkeyed, so first hotkey the end snapping and the start snapping function in the audio section. When you press the hotkey to snap end once, it snaps to the keyframe ahead. If you press the same hotkey again, it snaps to the keyframe behind. Then every press of the hotkey will continue snapping to previous keyframe. This way, you can snap to the keyframe ahead or behind using the same hotkey. For the start time, the opposite happens. One press snaps behind and then double press snaps forward.

I use Bidirectional Snapping in combination with [this script](https://github.com/The0x539/Aegisub-Scripts/blob/trunk/src/0x.JoinPrevious.lua) which is also hotkeyed and allows me to link the previous line to current line without moving to previous line.

An attempt has been made below to showcase it's usage but you should use it yourself to see how it works. Here, `w` has been hotkeyed to end-snapping and `q` has been hotkeyed to beginning-snapping.

https://user-images.githubusercontent.com/65547311/168461607-d575b757-4504-4a31-8c9b-f52d01fe566f.mp4

## Wave

**_Available in Dependency Control_**

![wave](./assets/wave.png)

Wave is a script that allows you to mimic the wavy signs through some fscx, fscy and fsp trickery. When you open the scripts, there are few parameters you can change and you'll have to go through some trial and error to determine what values give you the result you want.

Credits for the original code excerpt before my modification goes to [The0x539](https://github.com/The0x539)

Below are few examples of what kind of waves you can achieve but depending on the values you use, you can create different types of waves as well.

https://user-images.githubusercontent.com/65547311/164889225-2d8a6ccf-7798-4810-a3cf-3f87568abef0.mp4

## Wobble

**_Available in Dependency Control_**

Wobble is a remake of a very old script that distorts the text with the parameters you choose. The old script however was very difficult to use. It neither recognized the text already present in the line nor the tags used nor did it output the result in a usable format. So I decided to remake it.

![wobble](./assets/wobble-gui.png)

When you open the script, you will be presented with the gui as shown above. Imagine that when you use this script, it distorts the text along a wave horizontally or vertically or both. The parameters control the nature of the wave thus controls how the text is distorted. Frequency is the number of waves (crest and trough) you want in the text. Use very small value for useful output. Strength is the number of pixels that the text will be distorted to. With trial and error, you can create many interesting distortions.

As you can see below, the top is the original font and everything below it is distorted using this script. I use it when the sign is distorted or I need a irregular font that I cannot find.

![wobble2](./assets/wobble-example.png)

## svg2ass

**_Available in Dependency Control_**

The script svg2ass is a wrapper for a program [svg2ass](https://github.com/irrwahn/svg2ass) which allows you to select a svg file from Aegisub itself and convert it to shape, clip or iclip. It works in both windows as well as unix operating system. I generally create svg files using GIMP(can perform complex selections and convert those selections to svg in a matter of seconds) or Inkscape and use svg2ass to convert them to subtitle lines. If you cannot/ do not want to compile svg2ass, then there is also a [website](https://qgustavor.github.io/svg2ass-gui/) where you can upload the svg file to obtain the output.

The first thing you should do is to set the config and provide the path where you have the svg2ass executable. At the same time, you can also provide custom tags you want to append to final result and the custom svg2ass parameters if you prefer.

![svg2ass_config](./assets/svg2ass_config.png)

To use this script, simply click on `Import` button and select the svg file. The resulting lines will have the same start time, end time and style as the selected line. If you checked clip or iclip in the gui, the resulting shape will be converted to clip or iclip respectively. Alternatively if you don't have the svg2ass executable, you can get the output of svg2ass from the website and paste the result in the textbox and click on the `Textbox` button. The resulting lines will the same as `Import`

![svg2ass](./assets/svg2ass.png)

## Timing Assistant

**_Not Available in Dependency Control_**

I made this script knowing full well that no experienced timer would use this but I had to because I loved TPP's convenience but hated that it was too unintelligent to require a separate pass to fix all the errors it generated.

Rationale:

When I time, I always make a series of decision for every line. Do I need to add lead in, lead out, snap to keyframes or link the lines? So I wanted to create a script that allows me to do it in a press of a hotkey. Someone just rolled their eyes and said, "Phos, you just made an inferior TPP". It might be inferior but it is definitely not a TPP. The workflow of using this script is the same as timing without TPP but only difference is that the aforementioned decisions is made for you by the script.

How to use:

![timer](./assets/timer.png)

The first thing to do after you install the script is to set up the config. By default, it contains the values I use and what I consider sane defaults. You are however free to change it and the script will perform as intended as long as the values you put are within reason. The second thing to do is of course hotkey the script in audio section.

Now you are ready for timing. Here, you'll first do the exact timing on the line and then press the hotkey. The script will make the decision for you whether it should add lead in, snap to keyframe, link the lines together or add lead out. You then move to the next line and repeat. _Exact time, hotkey. Exact time, hotkey. That's it._

I have come to like this method because it has the convenience of decision making of TPP but at the same time, if I do not agree with the script, I am free to fix it and move to next line.

**Note**: If the end time of your line exceeds the audio of next line, don't fix it. Go to the next line, exact time it and then press the hotkey. The script will fix it. It works in this manner because it can only make proper decision of line linking of current line in context of start time of next line.

**Note2:** This is just the first release of the script and I understand that it'll not be perfect right now but as I keep timing with it and come across edge cases where it fails, I'll be sure to improve it where I can.

If you want to to check exactly what steps the script takes for decision making, expand the following and let me know if I got something wrong.

<details>
  <summary>Click here to expand</summary>

For start time:

1. If start time is already snapped to keyframe, it does not make any changes to the start time.
1. Checks if there is a keyframe within the time specified in the config and snaps to it.
1. If it was not snapped, it checks the end time of previous line and if it is within the linking time specified in config, it adds lead in to current line and extends the end time of the previous line.
1. If it was neither snapped nor linked, it simply adds lead in.

For end time:

1. If end time is already snapped to keyframe, it does not make any changes to the end time.
1. Here's a special step that is only applicable when your keyframe snapping value is greater than 850 ms. Snapping to keyframes more than 850 ms away is not always the correct thing to do, hence this special step. If the script finds that there is a keyframe 850+ ms away from exact end and you've allowed to snap to that distance in config, then it first checks cps of the line (without leadout). If cps is greater than 15, then it snaps to keyframe. If the cps is less than 15, then it either tries to add lead out to the line or extend the end time such that it is 500 ms away from keyframe whichever is lesser.
1. If above special case is not true(which is most of the case), it simply checks if there is a keyframe within time specifed in the config and snaps to it.
1. If it did not snap, it simply adds lead out to the line.

</details>

## Remove Tags

**_Not Available in Dependency Control_**

_Lyger's module is a dependency. If you have downloaded lyger's script from dependency control, chances are you already have it. You can also get it from [here](https://github.com/TypesettingTools/lyger-Aegisub-Scripts/blob/master/modules/LibLyger.moon)_

![image](./assets/remove_tags1.png)

This is undoubtedly a clone of unanimated's script called `Script Cleanup` but there are two major differences. The first being that as the name suggests, this script only has the portions of `Script Cleanup` that deals with removing tags. The second being that the GUI of this script is dynamically generated i.e. only tags that are available in the selected lines are available for you to remove.

### `Remove All` button

- If you simply click the `Remove All` button, it removes all the tags form the selected lines.
- If you check `Start tags` in the top row and then press `Remove All` button, it removes all start tags from selected lines.
- Similarly, checking `Inline tags` in top row removes all inline tags.

### `Kill Tags` button

- All the tags that you individually selected would be removed.
- If `Start tags` is checked, the selected tags will only be removed from start tags.
- If `Inline tags` is checked, the selected tags will only be removed from inline tags.
- If `Transform` is checked, the selected tags will only be removed from transforms.
- If `Inverse` is checked, all the tags except the selected ones will be deleted.

### `Run Selected` button

This button executes the things you select in the left column and is mostly used to delete groups of tags at once. Staying true to it's mission, the script also dynamically creates this section. Which means that if your selection does not contain any color tags, the option to remove color tags won't be available. The groups available are:

- All color tags (c, 1c, 2c, 3c, 4c)
- All alpha tags (alpha, 1a, 2a, 3a, 4a)
- All rotation tags (frz, frx, fry)
- All scale tags (fs, fscx, fscy)
- All perspective tags (frz, frx, fry, fax, fay, org)
- All inline tags except last (useful for undoing gradient)

## Transform button

![image](./assets/remove_tags2.png)

This button is only available to you if there are transforms in your selection. The idea for this is to easily select a specific transform that you want to delete. Each row has transforms for a single line. If you have a line with dozens of transforms, the gui produced will be very wide so keep that in mind. Simply select the transforms you want to delete and click `Remove`

## Edit Tags

**_Not Available in Dependency Control_**

The main idea is that it presents the tags and it's value of the current line in a HYDRA like GUI so that I can easily edit the values of that tag. It is mostly useful for complex lines that has a lot of tags. It separates start tags, inline tags and transforms in different sections for easy editing.

Since the GUI is dynamically generated, it may sometime produce sub-optimal GUI but for 99% of lines, it should work without issue. Just don't go using this script in the line you generated using ktemplates or programming. You shouldn't be editing such lines manually anyway.

Take the following line with transforms, move and clips.

```
{\an9\blur1\c&HEEE7DD&\fscx126\fscy126\clip(868,612,1736,942)\move(1716.96,667.57,2151.04,667.64,21,3942)\t(21,3942,\blur1\fscx126\fscy126\clip(868,596,988,942))\t(300,1500,1.2,\blur2)}Whenever people\Nget near me,
```

When you run the script on this line, following gui is generated:

![image](./assets/edittags1.png)

Similarly for following line with gradient by character:

```
{\an4\pos(977.06,961.97)\fscx29.52\fscy16.17\frz-199.62\fax-0.13\fnStatic Bold\b1\c&H6460F6&\3c&HFFFFFF&\blur0.9\iclip(m 845.3 955.18 b 844.97 954.36 843.03 953.8 840.78 953.13 838.53 952.45 835.86 951.89 832.83 950.88 829.79 949.86 822.21 947.39 816.25 945.7 810.29 944.01 807.47 942.78 807.47 942.78 807.47 942.78 813.23 935.49 813.7 934.9 814.9 933.4 828.51 915.06 831.1 911.58 833.69 908.09 835.79 904.94 835.67 904.15 835.56 903.36 835.38 901.83 834.81 901.04 834.25 900.25 833.42 897.44 833.2 896.65 832.97 895.86 833.05 894.1 832.6 893.42 832.15 892.75 829.53 892.08 825.63 890.72 822.12 889.51 819.55 889.04 814.83 887.8 810.1 886.56 801.44 884.46 798.85 883.67 796.26 882.89 785.09 879.33 785.09 879.33 l 684.4 842.2 540.4 1020.4 754 1094.8 767.65 1101.85 832.9 992.42 837.55 985.67 b 837.55 985.67 840.93 981.36 841.22 980.69 841.53 980.01 845.33 975.09 845.33 974.73 845.33 974.49 845.61 966.06 845.61 966.06 845.61 964.85 845.7 962.15 845.7 960.58 845.7 959 845.98 956.75 845.3 955.18)}S{\fax-0.14}t{\fax-0.15}o{\fax-0.16}p {\fax-0.18}w{\fax-0.19}o{\fax-0.2}r{\fax-0.21}r{\fax-0.22}y{\fax-0.23}i{\fax-0.24}n{\fax-0.25}g {\fax-0.27\c&H3E3C3E&}a{\fax-0.28}b{\fax-0.29}o{\fax-0.3}u{\fax-0.31}t {\fax-0.32}t{\fax-0.33}a{\fax-0.34}l{\fax-0.35}k{\fax-0.36}i{\fax-0.37}n{\fax-0.38}g {\fax-0.4}t{\fax-0.41}o {\fax-0.43}o{\fax-0.44}t{\fax-0.45}h{\fax-0.46}e{\fax-0.47}r{\fax-0.48}s{\fax-0.49}!
```

![image](./assets/edittags2.png)

## QC Report

**_Not Available in Dependency Control_**

![image](./assets/qcreport-main.png)

This script is designed to write and generate QC reports from Aegisub. If you wish to write QC reports using a media player, there is a program called [mpvQC](https://github.com/mpvqc/mpvQC) which is designed to do just that.

The top row of the gui consists of configurable sections like timing, typesetting etc that you can tick to specify the type of note. If nothing is ticked, it's treated as a general note. Below that is a drop-down which has pre-made reports for each sections for making even faster notes.

Below that is a textbox where you are free to write you report. The way you format your report in the textbox is preserved. If you selected any pre-made reports, it is appended to the beginning of the text in the text-box. You can leave this box empty and only select the pre-made report.

Finally, there is a checkbox called `Use video frame`. Normally, the report is added to current line but if you tick this, the report is added on the basis of the current video frame. If the current video frame has a subtitle, then the report is added to that line. If there isn't, then an empty line with report is inserted whose time is same as the video frame.

After you write all your notes, you can generate a report and a properly formatted note will with time will be generated that you can copy and share. The generated report is fully compatible with arch1t3cht's [Note Browser](https://github.com/arch1t3cht/Aegisub-Scripts#note-browser) script. After you generate the report and you no longer need them in your subtitle, you can clean them up too.

![image](./assets/qcreport-generate.png)

There is also a config where you can configure a lot of things about the script so be sure to check that out.
