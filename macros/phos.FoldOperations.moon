export script_name = "Fold Operations"
export script_description = "Different operations on folds"
export script_version = "0.0.2"
export script_author = "PhosCity"
export script_namespace = "phos.FoldOperations"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
  feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
}

parseLineFold = (line) ->
  return if not line.extra

  info = line.extra["_aegi_folddata"]
  return if not info

  side, collapsed, id = info\match("^(%d+);(%d+);(%d+)$")
  return {:side, :collapsed, :id}


selectFoldAroundActiveLine = (sub, sel, act) ->
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


commentCurrentFold = (sub, sel, act) ->
  newSelection = selectFoldAroundActiveLine sub, sel, act
  for i in *newSelection
    line = sub[i]
    line.comment = not line.comment
    sub[i] = line


createNamedFold = (sub, sel, act) ->
  highestID, linesAdded = 0, 0
  for i = 1, #sub
    continue unless sub[i].class == "dialogue"
    line = sub[i]
    foldData = parseLineFold line
    continue unless foldData
    highestID = math.max highestID, foldData.id
  id = highestID + 1

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
    if i == sel[1]
      line.text = (res.name)\gsub(".", string.upper).."  START  "
      line.extra["_aegi_folddata"] = "0;1;#{id}"
      sub.insert sel[1], line
    elseif i == sel[#sel]
      line.text = (res.name)\gsub(".", string.upper).."  END  "
      line.extra["_aegi_folddata"] = "1;1;#{id}"
      sub.insert sel[#sel] + 2, line


createGUI = ->
  dialog = {
    {x: 0, y: 0, width: 1, height: 1, class: "checkbox", name: "selectCurrentFold",  value: false, label: "Select current fold"},
    {x: 1, y: 0, width: 1, height: 1, class: "checkbox", name: "commentCurrentFold", value: false, label: "Toggle comment on current fold"},
    {x: 0, y: 1, width: 1, height: 1, class: "checkbox", name: "createNamedFold",    value: false, label: "Create a new named fold"},
  }
  btn, res = aegisub.dialog.display(dialog, {"Apply", "Cancel"}, {"ok": "Apply", "cancel": "Cancel"})
  aegisub.cancel! unless btn
  return res


main = (sub, sel, act) ->
  res = createGUI!
  if res.selectCurrentFold
    newSelection = selectFoldAroundActiveLine sub, sel, act
    return newSelection
  elseif res.commentCurrentFold
    commentCurrentFold sub, sel, act
  elseif res.createNamedFold
    createNamedFold sub, sel, act


depctrl\registerMacro main
