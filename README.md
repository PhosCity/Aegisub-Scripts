# Snap to Keyframes

This one is for the timers who do not use TPP to time subtitles. There are other scripts that allows you to snap to keyframes but this script has a specific purpose. It can snap the end to keyframe ahead and snap the beginning to keyframe behind it just like other scripts but you'll inevitably come across lines while timing where the end of the line overshoots the keyframe so you need to snap the keyframe behind. So the way you can overcome this is hotkey both the end-snapping and beginning-snapping in Aegisub settings. Then when you press the hotkey once, it snaps the keyframe ahead. Then in the next press of the hotkey, it snaps to keyframe behind. So if you want to snap the end ahead, press hotkey once and if you want to snap the end behind, a quick successive double pressing of the same hotkey will give you what you want. For the beginning of line, the opposite happens. One press snaps behind and then double press snaps forward.

If you don't use TPP, you might also be interested in [this script](https://github.com/The0x539/Aegisub-Scripts/blob/trunk/src/0x.JoinPrevious.lua).

An attempt has been made below to showcase it's usage but you should use it yourself to see how it works. Here, `w` has been hotkeyed to end-snapping and `q` has been hotkeyed to beginning-snapping.



https://user-images.githubusercontent.com/65547311/164889186-9938c819-3ffd-4077-b053-73cc58450bed.mp4

# Wave

This one's simple. Once you open the script, there are few parameters you can change and with trial and error of using different values, you might be able to add the wave you want to the text.


https://user-images.githubusercontent.com/65547311/164889225-2d8a6ccf-7798-4810-a3cf-3f87568abef0.mp4

# Wobble

This one's a remake of an old script that I found. Basically distorts the text with the parameters you choose as you can see below. The top one is original font. All below is distorted using this script.
![wobble](https://user-images.githubusercontent.com/65547311/164889279-7a7601cb-88ed-4dde-b444-4f4a4d273df6.png)
