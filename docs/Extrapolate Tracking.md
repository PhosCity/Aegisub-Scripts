<font color="red">**Not Available in Dependency Control**</font>

[Link to script](https://github.com/PhosCity/Aegisub-Scripts/blob/main/macros/phos.ExtrapolateTracking.moon)

When you're motion-tracking a sign, and you cannot track the first or last few frames either because the sign moved out of the screen or it faded out, you can use this script to extrapolate the tracking for those lines. There is a similar function in 'Significance' script by unanimated, but it only extrapolates scaling and position. This script goes a little beyond and extrapolates the following tags.

![image](./assets/extrapolate.png){: style="height:170px;width:308px"}

On top of that, it also supports extrapolating only tags selected by the user.

# Usage

- If you already have badly tracked lines in Aegisub, mark those lines with 'x' in Effect.
- Instead, if you only have correctly tracked lines in Aegisub, write 'x,n' in the first or last correctly tracked line where you replace 'n' with the number of new lines you want to insert before or after the marked line. For example, if you write 'x,5' in last line, the script will insert 5 new lines with extrapolated tags after it. If you mark the first line, it'll insert 5 new lines before marked line.

- Select the lines you marked plus frames before or after it. How many frames you select depends on how "linear" the tracking is. With perfectly linear tracking, you can select all the tracked lines to get more accurate extrapolation. If there seems to be a small accel, use only about 5 reference frames.

!!! warning "Requirements"

    - All selected lines must be 1 frame long.
    - Selection must be consecutive and sorted by time.
    - If lines are split in layers, run the script separately for each layer.
