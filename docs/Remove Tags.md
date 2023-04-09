<font color="green">**Available in Dependency Control**</font>

[Link to script](https://github.com/PhosCity/Aegisub-Scripts/blob/main/macros/phos.RemoveTags.moon)

![remove_tags](https://user-images.githubusercontent.com/65547311/211794907-5974c7cf-a824-4dd4-a96c-56a268ac7cc9.png)

This script deals with all things related to removing tags from the line. One of the main motivation for writing this script when a script like unanimated's `Script Cleanup` exists is because I would spend a lot of time searching the exact tag I wanted to remove from the 40 options of the GUI. When I have only 10 tags, I wanted to choose the tags I want to remove from those 10 tags only. So, GUI of this script is dynamically generated i.e. only tags that are available in the selected lines are available for you to remove. The GUI from the image above is not what you'll see when you run it.

#### `Remove All` button

- If you simply click the `Remove All` button, it removes all the tags form the selected lines.
- If you check `Start Tags` in the top row and then press `Remove All` button, it removes all start tags from selected lines.
- Similarly, checking `Inline Tags` in top row removes all inline tags.

#### `Remove Tags` button

- All the tags that you individually tick would be removed.
- If `Start tags` is checked, the selected tags will only be removed from start tags.
- If `Inline tags` is checked, the selected tags will only be removed from inline tags.
- If `Transform` is checked, the selected tags will only be removed from transforms.
- If `Inverse` is checked, all the tags except the selected ones will be deleted.

#### `Remove Group` button

This button executes the things you select in the left column and is mostly used to delete groups of tags at once. Staying true to it's mission, the script also dynamically creates this section. Which means that if your selection does not contain any color tags for example, the option to remove color tags won't be available. You can also tick `Start Tag` or `Inline Tag` the top row and only remove the tag group from start tag block or inline tag block only. The groups available are:

- All color tags (c, 1c, 2c, 3c, 4c)
- All alpha tags (alpha, 1a, 2a, 3a, 4a)
- All rotation tags (frz, frx, fry)
- All scale tags (fs, fscx, fscy)
- All perspective tags (frz, frx, fry, fax, fay, org)
- All inline tags except last (useful for undoing gradient)

<!-- TODO (Maybe): An option to select and remove each individual transform tags. -->
