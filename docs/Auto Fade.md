<font color="green">**Available in Dependency Control**</font>

[Link to script](https://github.com/PhosCity/Aegisub-Scripts/blob/main/macros/phos.AutoFade.moon)

`Auto Fade` allows you to determine the fade in and fade out time of a sign. Manually determining them requires you to step through frames of the video and find the frame where fade in ends or fade out starts and then add the fade tag to the line. This script automates all of those steps.

!!! warning "Warning"

    This script only works in arch1t3cht's [Aegisub](https://github.com/arch1t3cht/Aegisub).

# Usage

## Static Sign

<video width="960" height="540" controls>
  <source src="https://user-images.githubusercontent.com/65547311/227202163-633bc88d-5bee-4c43-a611-084b3479aa8a.mp4" type="video/mp4">
Your browser does not support the video tag.
</video>

- Time your sign.
- Determine if your sign has fade in, fade out or both.
- Play the video until you reach any frame in which there is neither fade in nor fade out.
- Now you have two options. Either add a single point `clip/iclip` over the sign as shown in first example of the video or hover over the Japanese sign, right click and choose "Copy coordinates to Clipboard" as shown in the second example of video above.
- Open the script (while staying in the same video frame). The co-ordinate should have automatically be picked up and shown in the GUI. Then choose `Fade in` or `Fade out` or `Both` button depending on what you want.
- The script will automatically add appropriate fade to your text.

## Moving Sign

<video width="960" height="540" controls>
  <source src="../assets/auto-fade-tracking.mp4" type="video/mp4">
Your browser does not support the video tag.
</video>

If your sign is moving and you also have motion tracking data for the sign, Available, you can use that data to determine the fade for such moving sign as well.

All the steps are the same as shown above except before you click the button, paste the tracking data in the text box and change the drop-down from `Single Co-ordinate` to `Tracking Data`.
