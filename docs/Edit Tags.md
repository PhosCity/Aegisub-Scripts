<font color="red">**Not Available in Dependency Control**</font>

[Link to script](https://github.com/PhosCity/Aegisub-Scripts/blob/main/macros/phos.edittags.moon)

The main idea is that it presents the tags, and it's value of the current line in a HYDRA like GUI so that I can easily edit the values of that tag. It is mostly useful for complex lines that has a lot of tags. It separates start tags, inline tags and transforms in different sections for easy editing.

When you run the script on a line, following GUI is generated:

![image](./assets/edittags1.png)

I've tried to make GUI as similar to HYDRA as possible since the familiarity helps with finding which tags you want to edit. The tags present in your lines are ticked and the effective tag values are pre-filled. Here effective tags value means that if the tag is not available in the line, the tag value is taken from style. Not only you can change the value of the ticked tag in the GUI, but you can also tick any tags of the GUI to add that tag to the line. You can also untick any tag to remove them from the line. The order of your tags are respected.

While I did not plan to add an option to modify tags in multiple lines, for the sake of completion, I added one nonetheless. Its usefulness is highly doubtful. I took inspiration from unanimated's Modifire. In short, if you select multiple lines and run the script, following GUI will be shown which shows tags in all the selected lines without duplication. It's essentially find and replace for tags i.e. if you change the value of the tag in the GUI, all the instances of that said tag will be modified. However, the difference is that you can find and replace as many tags as you want all at once.

![image](./assets/edittags2.png)
