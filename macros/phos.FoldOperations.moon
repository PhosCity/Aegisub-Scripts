export script_name = "Fold Operations"
export script_description = "Different operations on folds"
export script_version = "1.1.1"
export script_author = "PhosCity"
export script_namespace = "phos.FoldOperations"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
  feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
  {
    {"a-mo.LineCollection", version: "1.3.0", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json" },
    {"l0.Functional", version: "0.6.0", url: "https://github.com/TypesettingTools/Functional",
      feed: "https://raw.githubusercontent.com/TypesettingTools/Functional/master/DependencyControl.json"},
    "aegisub.clipboard"
  }
}
LineCollection, Functional, clipboard = depctrl\requireModules!
{:list, :string, :table, :util} = Functional

logger = depctrl\getLogger!
config = depctrl\getConfigHandler {commentAroundFold: false}
config\load!
opt = config.c


-- parse the fold extradata in a line
parseLineFold = (line) ->
  return if not line.extra

  info = line.extra["_aegi_folddata"]
  return if not info

  side, collapsed, id = info\match("^(%d+);(%d+);(%d+)$")
  return {:side, :collapsed, :id}


-- returns the fold id that is available to be used
highestID = (sub) ->
  currHighestID = 0
  for i = 1, #sub
    continue unless sub[i].class == "dialogue"
    line = sub[i]
    foldData = parseLineFold line
    continue unless foldData
    currHighestID = math.max currHighestID, foldData.id
  currHighestID + 1


-- If you have commented lines around actual lines as fold markers, remove them from selection
correctSelection = (sel) ->
  if opt.commentAroundFold
    sel = list.slice sel, 2, #sel - 1
  sel


-- selects all the lines in a fold around active line
selectFoldAroundActiveLine = (sub, _, act) ->
  foldStack, newSelection, foldAroundLine = {}, {}

  for i = 1, #sub
    continue unless sub[i].class == "dialogue"
    line = sub[i]
    folddata = parseLineFold line
    if folddata and folddata.side == "0"
      table.insert foldStack, {index: i, id: folddata.id}

    if i == act
      break if #foldStack == 0
      foldAroundLine = foldStack[#foldStack]
      newSelection = [ j for j = foldAroundLine.index, i ]
    elseif i > act
      table.insert newSelection, i

    if folddata and folddata.side == "1"
      assert(#foldStack > 0 and foldStack[#foldStack].id == folddata.id)
      foldStack[#foldStack] = nil

      if foldAroundLine and foldAroundLine.id == folddata.id
        break

  return newSelection

-- selects all the lines in a fold around active line however if you have commented fold names around fold, it deselects them
selectActiveFold = (sub, _, act) ->
  newSelection = selectFoldAroundActiveLine sub, _, act
  return correctSelection newSelection


-- comment all the lines in a fold around active line. Remembers line that were already commented.
commentCurrentFold = (sub, _, act) ->
  newSelection = selectFoldAroundActiveLine sub, _, act
  return if #newSelection == 0

  newSelection = correctSelection newSelection
  lines = LineCollection sub, newSelection, -> true
  return if #lines.lines == 0
  lines\runCallback ((lGines, line, i) ->
    aegisub.cancel! if aegisub.progress.is_cancelled!
    if line.comment
      line\setExtraData 'fold-operation', "commented"
    else
      line.comment = true
  ), true
  lines\replaceLines!


-- uncomment all the lines in a fold around active line. If the lines were already commented prior to commenting, they are left commented.
uncommentCurrentFold = (sub, _, act) ->
  newSelection = selectFoldAroundActiveLine sub, _, act
  return if #newSelection == 0

  newSelection = correctSelection newSelection
  lines = LineCollection sub, newSelection, -> true
  return if #lines.lines == 0
  lines\runCallback ((lines, line, i) ->
    aegisub.cancel! if aegisub.progress.is_cancelled!
    if line\getExtraData 'fold-operation'
      line.comment = true
      line.extra["fold-operation"] = nil
    else
      line.comment = false
  ), true
  lines\replaceLines!


-- toggle comment state on all the lines in a fold around active line. Any commented lines will become uncommented, and vice versa.
-- if any commented lines have the "fold-operation" marker, signifying that they've been commented out by this macro, assume they're not to be uncommented.
toggleCommentCurrentFold = (sub, _, act) ->
  newSelection = selectFoldAroundActiveLine sub, _, act
  return if #newSelection == 0

  newSelection = correctSelection newSelection
  lines = LineCollection sub, newSelection, -> true
  return if #lines.lines == 0
  lines\runCallback ((lines, line, i) ->
    aegisub.cancel! if aegisub.progress.is_cancelled!
    line.comment = not line.comment unless line.comment and line\getExtraData 'fold-operation'
  ), true
  lines\replaceLines!


-- toggles the current fold between "commented" and "uncommented". If the fold contains any lines that are uncommented, assume it is uncommented.
stateToggleCommentCurrentFold = (sub, _, act) ->
  newSelection = selectFoldAroundActiveLine sub, _, act
  return if #newSelection == 0

  newSelection = correctSelection newSelection
  lines = LineCollection sub, newSelection, -> true
  return if #lines.lines == 0

  isUncommented = (() -> for line in *lines.lines return true if not line.comment)!

  if isUncommented
    commentCurrentFold sub, _, act
  else
    uncommentCurrentFold sub, _, act


-- delete all the lines in a fold around active line
deleteCurrentFold = (sub, _, act) ->
  newSelection = selectFoldAroundActiveLine sub, _, act
  return if #newSelection == 0
  sub.delete newSelection
  return {newSelection[#newSelection] - #newSelection + 1}


-- copy all the lines in a fold around active line to clipboard. Copies fold state as well as styles.
copyFold = (sub, act) ->
  newSelection = selectFoldAroundActiveLine sub, _, act
  return if #newSelection == 0

  lines = LineCollection sub, newSelection, -> true
  return if #lines.lines == 0

  stringToCopy = ""
  lines\runCallback (lines, line, i) ->
    aegisub.cancel! if aegisub.progress.is_cancelled!
    stringToCopy ..= line\__tostring!.."||**||"

    foldData = line\getExtraData '_aegi_folddata'
    commentData = line\getExtraData 'fold-operation'
    if foldData or commentData
      stringToCopy ..= (foldData or "noFold")..","..(commentData or "noComment").. "||**||"
    else
      stringToCopy ..= "noExtradata".."||**||"

    stringToCopy ..= line.styleRef.raw.."\n"

  clipboard.set stringToCopy
  return newSelection


-- copy all the lines in a fold around active line to clipboard
copyCurrentFold = (sub, sel, act) ->
  copyFold sub, act
  return sel


-- cut all the lines in a fold around active line to clipboard
cutCurrentFold = (sub, _, act) ->
  newSelection = copyFold sub, act
  sub.delete newSelection
  return {newSelection[#newSelection] - #newSelection + 1}


-- paste all the folded lines in clipboard. Pastes fold state as well as styles.
pasteCurrentFold = (sub, _, act) ->
  dataString = clipboard.get!
  if not dataString or not dataString\match "||Style:"
    logger\log "There are no folded lines in your clipboard. You need to copy the folds using this script."
    aegisub.cancel!

  dialogueRaw, extradata, styleRaw = {}, {}, {}
  for item in *(string.split dataString, "\n")
    continue if item == nil or item  == ""
    dlg, ext, stl = item\match "(.-)||%*%*||(.-)||%*%*||(.*)"
    table.insert dialogueRaw, dlg
    table.insert extradata, ext
    table.insert styleRaw, stl

  -- Validate that the fold that starts definitely ends
  foldValidationTable, minimumID = {}, math.huge
  for fold in *extradata
    continue if fold  == "noExtradata" or fold\match "^noFold"
    side, id = fold\match "^(%d+);%d+;(%d+),"
    minimumID = math.min minimumID, id      -- This will be used later
    foldValidationTable[id] or= {}
    if tonumber(side) == 0
      foldValidationTable[id]["start"] = true
    elseif tonumber(side) == 1
      foldValidationTable[id]["end"] = true
  for _, fold in pairs foldValidationTable
    unless fold.start and fold.end
      logger\log "Fold validation failed. Fold that starts must end and vice versa.\nMake sure you copied folds using the script."
      aegisub.cancel!

  -- Deduplicate style list
  styleRaw = list.uniq styleRaw

  -- Map the raw style text to its fields
  style = {}
  defaultStyleFields = {"name", "fontname", "fontsize", "color1", "color2", "color3", "color4",
    "bold", "italic", "underline", "strikeout", "scale_x", "scale_y", "spacing", "angle",
    "borderstyle", "outline", "shadow", "align", "margin_l", "margin_r", "margin_t", "encoding"}
  for item in *styleRaw
    elements = [x for x in item\gsub("^Style: ", "")\gmatch "([^,]+)"]
    fields = {defaultStyleFields[i], elements[i] for i=1,#elements}

    -- Number fields
    for tag in *{"fontsize", "scale_x", "scale_y", "spacing", "angle", "borderstyle", "outline", "shadow", "align", "margin_l", "margin_r", "margin_t", "encoding"}
      fields[tag] = tonumber(fields[tag])

    -- Boolean fields
    for tag in *{"bold", "italic", "underline", "strikeout"}
      if fields[tag] == "-1"
        fields[tag] = true
      elseif fields[tag] == "0"
        fields[tag] = false

    -- Color fields for some reason
    for tag in *{"color1", "color2", "color3", "color4"}
      fields[tag] ..= "&"

    -- Add missing fields
    fields["margin_b"] = fields["margin_t"]
    fields["section"] = "[V4+ Styles]"
    fields["class"] = "style"

    style[fields.name] = fields

  -- Determine styles that needs to be added
  for i = 1, #sub
    stl = sub[i]
    break if stl.class == "dialogue"
    continue unless stl.class == "style"

    if style[stl.name]
      -- HACK: Remove fields "raw" and "relative_to" to ensure the table equality if all other fields are same
      stl = table.filter stl, (_, key) -> key != "raw"
      stl = table.filter stl, (_, key) -> key != "relative_to"
      if not table.equals style[stl.name], stl
        logger\log "STYLE CONFLICT\nStyle \"#{stl.name}\" already exists in the file but has different field values."
        aegisub.cancel!
      else
        style = table.filter style, (_, key) -> key != stl.name

  -- Insert missing styles
  for i = 1, #sub
    count = i-1
    if sub[i].class == "dialogue"
      for _, stl in pairs style
        sub.insert(count, stl)
        count += 1
      break

  -- Insert lines
  id = highestID sub

  string2line = (lineRaw, ext) ->
    line, extra = {}, {}
    if ext  != "noExtradata"
      foldData, commentData = ext\match "(.-),(.*)"
      if foldData != "noFold"
        foldData = foldData\gsub "(%d+;%d+;)(%d+)", (a, b) -> a..math.floor(b + id - minimumID)
        extra["_aegi_folddata"] = foldData
      if commentData == "commented"
        extra["fold-operation"] = commentData
    with line
      ltype, .layer, s_time, e_time, .style, .actor, .margin_l, .margin_r, .margin_t, .effect, .text = lineRaw\match("(%a+): (%d+),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),(.*)")
      .class = "dialogue"
      .comment = ltype == "Comment" and true or false
      .start_time = util.assTimecode2ms(s_time)
      .end_time = util.assTimecode2ms(e_time)
      .extra = extra
    line

  for index, item in ipairs dialogueRaw
    ext = extradata[index]
    line = string2line item, ext
    sub.insert(act + 1, line)


-- Create a fold around selected lines a commented lines around as fold markers with the user provided name.
createNamedFold = (sub, sel, act) ->
  id = highestID sub

  btn, res = aegisub.dialog.display(
    {
      {x: 0, y: 0, width: 1, height: 1, class: "label", label: "Enter name of the fold"},
      {x: 1, y: 0, width: 1, height: 1, class: "edit", name: "name", value: ""},
    },
    {"Apply", "Cancel"},
    {"ok": "Apply", "cancel": "Cancel"}
  )
  aegisub.cancel! unless btn

  for i in *{sel[1], sel[#sel]}
    line = sub[i]
    line.actor = ""
    line.effect = ""
    line.comment = true
    line.extra["_aegi_folddata"] = nil

    addFold = (foldType) ->
      line.text = (res.name)\gsub(".", string.upper).." #{foldType}"
      line.extra["_aegi_folddata"] = "#{foldType == "START" and 0 or 1};1;#{id}"
      sub.insert foldType == "START" and i or i+2, line

    if sel[1] == sel[#sel] -- Only 1 line is selected
      addFold "START"
      addFold "END"
      break
    elseif i == sel[1]
      addFold "START"
    elseif i == sel[#sel]
      addFold "END"


-- GUI that has all the functions this script provides.
gui = (sub, sel, act) ->
  dialog = {
    {x: 0, y: 0,  width: 1, height: 1, class: "label",    label: "- Config -----", hint: "Tick this if you add commented lines as fold markers before and after actual lines."},
    {x: 0, y: 1,  width: 1, height: 1, class: "checkbox", name: "commentAroundFold",    value: opt.commentAroundFold, label: "Comments around fold", hint: "Tick this if you add commented lines as fold markers before and after actual lines."},
    {x: 0, y: 3,  width: 1, height: 1, class: "label",    label: "- Selection -----"},
    {x: 0, y: 4,  width: 1, height: 1, class: "checkbox", name: "selectCurrentFold",    value: false,                 label: "Select current fold"},
    {x: 1, y: 3,  width: 1, height: 1, class: "label",    label: "- Deletion -----"},
    {x: 1, y: 4,  width: 1, height: 1, class: "checkbox", name: "deleteCurrentFold",    value: false,                 label: "Delete current fold"},
    {x: 0, y: 6,  width: 1, height: 1, class: "label",    label: "- Comment -----"},
    {x: 0, y: 7,  width: 1, height: 1, class: "checkbox", name: "commentCurrentFold",   value: false,                 label: "Comment"},
    {x: 1, y: 7,  width: 1, height: 1, class: "checkbox", name: "uncommentCurrentFold", value: false,                 label: "Uncomment"},
    {x: 0, y: 9,  width: 1, height: 1, class: "label",    label: "- Cut-Copy-Paste -----"},
    {x: 0, y: 10,  width: 1, height: 1, class: "checkbox", name: "cutCurrentFold",       value: false,                 label: "Cut current fold"},
    {x: 1, y: 10,  width: 1, height: 1, class: "checkbox", name: "copyCurrentFold",      value: false,                 label: "Copy current fold"},
    {x: 2, y: 10,  width: 1, height: 1, class: "checkbox", name: "pasteCurrentFold",     value: false,                 label: "Paste current fold"},
    {x: 0, y: 12,  width: 1, height: 1, class: "label",    label: "- Others -----"},
    {x: 0, y: 13, width: 2, height: 1, class: "checkbox", name: "createNamedFold",      value: false,                 label: "Create a new named fold around selected lines"},
  }
  btn, res = aegisub.dialog.display(dialog, {"Apply", "Cancel"}, {"ok": "Apply", "cancel": "Cancel"})
  aegisub.cancel! unless btn
  opt.commentAroundFold = res.commentAroundFold
  config\write!

  if res.selectCurrentFold
    newSelection = selectFoldAroundActiveLine sub, _, act
    return newSelection
  elseif res.commentCurrentFold
    commentCurrentFold sub, _, act
  elseif res.uncommentCurrentFold
    uncommentCurrentFold sub, _, act
  elseif res.cutCurrentFold
    cutCurrentFold sub, _, act
  elseif res.copyCurrentFold
    copyCurrentFold sub, sel, act
  elseif res.pasteCurrentFold
    pasteCurrentFold sub, _, act
  elseif res.deleteCurrentFold
    deleteCurrentFold sub, _, act
  elseif res.createNamedFold
    createNamedFold sub, sel, act


depctrl\registerMacros({
  {"Select Current Fold", "Select the fold around the active line", selectActiveFold},
  {"Comment Current Fold", "Comment the fold around the active line", commentCurrentFold},
  {"Uncomment Current Fold", "Uncomment the fold around the active line", uncommentCurrentFold},
  {"Comment or Uncomment Current Fold", "Comment the fold around the active line if it contains uncommented lines, otherwise uncomment it all", stateToggleCommentCurrentFold},
  {"Toggle Comments in Current Fold", "Toggle comment state on all lines in current fold", toggleCommentCurrentFold},
  {"Delete Current Fold", "Delete the fold around the active line", deleteCurrentFold},
  {"Cut Current Fold", "Cut the fold around the active line", cutCurrentFold},
  {"Copy Current Fold", "Copy the fold around the active line", copyCurrentFold},
  {"Paste Current Fold", "Paste the fold from your clipboard", pasteCurrentFold},
  {"Create Fold Around Selected Lines", "Create a fold around selected lines with a name as comment", createNamedFold}
  {"GUI", "GUI", gui}
})
