font color="green">**Available in Dependency Control**</font>

[Link to script](https://github.com/PhosCity/Aegisub-Scripts/blob/main/macros/phos.FoldOperations.moon)

If you use [arch1t3cht's Aegisub](https://github.com/arch1t3cht/Aegisub),then it
comes with a feature to visually group and
collapse lines in the subtitle grid called folds.

This script allows you to perform various operations on such folds.

!!! info

    If you have only one line selected, this script will function on the fold
    surrounding that line. If you select multiple lines, then the script will
    operate on all the folds around all the selected lines. So in this way you can
    either operate on a single fold or multiple folds. You can operate on any fold
    if you select even a single line of that fold. You do not need to open a fold
    to operate on it, if it's closed.

# Screenshots

Fold Operations Menu:

![image](./assets/foldoperations1.png)

Fold Operations GUI:

![image](./assets/foldoperations2.png)

# Usage

Before I explain the usage of this script, there are two popular ways I've
noticed people use folds. One is to simply select all the lines and create
folds and another is to add commented lines at the start and end of lines where
the first line has name for the fold. If you use commented lines, go to the GUI
of the script and tick `Comments around fold` under config before doing
anything else.

=== "Fold with comments"

    ![image](./assets/fold-with-comments.png)

=== "Same fold without comments"

    ![image](./assets/fold-without-comments.png)

!!! tip

    I prefer to use comments around my fold since it is cleaner and
    instantly allows me to recognize the signs among the list of folds. This script
    has an operation that will allow you to easily create named folds with
    comments.

## Operations

### `Select Fold`

This selects all the lines in fold. If you want to, for example, run `ASSWipe`
on all lines in a fold, use this to select all the lines and wipe.

### `Create Fold Around Selected Lines`

Select all the lines which you want to add to fold and run this. A GUI will
prompt you to enter name for the fold. The script will then insert commented
lines with name and create a fold with selected lines.

![image](./assets/foldoperations4.png)

If the fold is nested, it will show you by the number of arrows before fold names.

![image](./assets/foldoperations3.png)

### `Comment Fold`

This comments all the lines in fold.
If a line was already commented before running this, the script remembers it.

### `Uncomment Fold`

This uncomments all the lines in fold.
If the script remembers that a line was commented before running
`Comment Fold`, it does not uncomment them.

### `Toggle Comments in Fold`

This toggles the comments inside the current fold.
Any commented lines will become uncommented, and vice versa.
If the fold was commented using `Comment Fold`,
the state of the already commented folds is respected.

### `Comment or Uncomment Fold`

Comment the lines of fold if it contains any uncommented lines,
otherwise uncomment it all.

### `Delete Fold`

This deletes all the lines of fold.

### `Clear Fold`

This removes the fold without removing the lines itself.
If you use comments around the fold, it will remove that as well.

### `Copy Fold`

This copies all the lines in fold along with it's fold state
and styles to system clipboard.

### `Cut Fold`

This copies all the lines in fold along with it's fold state
and styles to system clipboard and deletes the fold.

### `Paste Fold`

This pastes all the lines in that was copied or cut using this script.
The fold copied from one Aegisub window can be pasted in the same or
different Aegisub window.

!!! info

    If the file in another Aegisub window does not have styles of copied lines,
    those styles will also be added to new file.

<video width="960" height="540" controls>
  <source src="../assets/fold-copy-paste.mp4" type="video/mp4">
Your browser does not support the video tag.
</video>
