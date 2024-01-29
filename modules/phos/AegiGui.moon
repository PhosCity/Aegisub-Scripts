haveDepCtrl, DependencyControl, depctrl = pcall require, 'l0.DependencyControl'
local Functional
if haveDepCtrl
  depctrl = DependencyControl{
    name: "AegiGui",
    version: "0.0.1",
    description: "Create GUI for Aegisub macros.",
    author: "PhosCity",
    moduleName: "phos.AegiGui",
    url: "https://github.com/PhosCity/Aegisub-Scripts",
    feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
    {
      {"l0.Functional", version: "0.5.0", url: "https://github.com/TypesettingTools/Functional",
      feed: "https://raw.githubusercontent.com/TypesettingTools/Functional/master/DependencyControl.json"},
    }
  }
  Functional = depctrl\requireModules!
else
  Functional = require "l0.Functional"

{:string, :list} = Functional


_class_info = {
  -- Aegi class
  label: {"string"},                                                          -- label
  edit: {"string", "string", "string"},                                       -- name, text(opt),  hint(opt)
  intedit: {"string", "integer", "integer", "integer", "string"},             -- name, value,      min(opt),   max(opt), hint(opt)
  floatedit: {"string", "string", "number", "number", "number", "string"},    -- name, value,      min(opt),   max(opt), step(opt), hint(opt)
  textbox: {"string", "number", "string", "string"},                          -- name, text(opt),  height,     hint(opt)
  dropdown: {"string", "table", "string", "string"},                          -- name, items,      value(opt), hint(opt)
  checkbox: {"string", "string", "boolean", "string"},                        -- name, label,      value(opt), hint(opt)
  color: {"string", "colorstring", "string"},                                 -- name, value(opt), hint(opt)
  coloralpha: {"string", "colorstring", "string"},                            -- name, value(opt), hint(opt)
  alpha: {"string", "string", "string"},                                      -- name, value(opt), hint(opt)
  -- Non Aegi class
  pad: {"integer"},                                                           -- value
  }


tableContains = (tbl, x) ->
  for item in *tbl
    return true if item == x
  return false


sanitize = (errorMsg, errorLevel, tbl, x , y, nameTable) ->
  _class = tbl[1]
  tempErrorMsg = ""
  no_of_arguments = math.huge  -- This is the number of minimum arguments that a class needs to function
  tblString = table.concat tbl, ","

  switch _class
    when "int", "intedit"
      tbl[1] = "intedit"
      no_of_arguments = 3
    when "float", "floatedit"
      tbl[1] = "floatedit"
      no_of_arguments = 3
    when "text", "textbox"
      tbl[1] = "textbox"
      no_of_arguments = 2
    when "drop", "dropdown"
      tbl[1] = "dropdown"
      no_of_arguments = 3
    when "check", "checkbox"
      tbl[1] = "checkbox"
      no_of_arguments = 3
    when "color", "coloralpha", "alpha", "label", "edit", "pad"
      no_of_arguments = 2
    when ""
      tempErrorMsg ..= "WARNING: Could not determine class for this cell. Check manually.\n"
      errorLevel = 1
    else
      errorLevel = 1
      errorMsg ..= "\nRow: #{y}, Column: #{x}\n#{tblString}\nWARNING: Class \"#{_class}\" is invalid.\n"
      return errorMsg, errorLevel, tbl, nameTable

  -- Name conflict checking
  if _class != "label" and _class != "pad"
    name = tbl[2]
    if tableContains nameTable, name
      tempErrorMsg ..= "WARNING: Name \"#{name}\" for class \"#{_class}\" is repeated.\n"
      errorLevel = 1
    table.insert nameTable, name

  _class = tbl[1]
  if #tbl < no_of_arguments
    tempErrorMsg ..= "WARNING: Class \"#{_class}\" requires #{no_of_arguments} arguments. The script provided #{#tbl} arguments.\n"
    errorLevel = 1

  for i, item in ipairs tbl
    continue if i == 1
    -- item = string.trim item

    if item == "_"
      tbl[i] = nil
      continue

    _type = type(item)
    correct_type = _class_info[_class][i - 1]

    unless correct_type
      tempErrorMsg ..= "INFO: You provided too many arguments for this class. \"#{item}\" will de discarded...\n"
      continue

    if correct_type == "number"
      item_number = tonumber(item)
      if item_number
        tbl[i] = item_number
      else
        tempErrorMsg ..= "WARNING: Argument #{i} for class \"#{_class}\" should be a number. Received \"#{item}\" instead.\n"
        errorLevel = 1

    elseif correct_type == "integer"
      item_number = tonumber(item)
      -- Maybe the module should just raise fatal error rather than truncating float number to integer
      -- If a user wants to use int class and is accidently giving float numbers, warning and forcing them to use integers would be a better idea.
      if item_number
        tbl[i] = item_number
        if item\match "%."
          tempErrorMsg ..= "INFO: Argument #{i} for class \"#{_class}\" should be an integer. Received \"#{item}\" instead. Everything after decimal will be trunctated.\n"
          tbl[i] = math.floor item_number
      else
        tempErrorMsg ..= "WARNING: Argument #{i} for class \"#{_class}\" should be a number. Received \"#{item}\" instead.\n"
        errorLevel = 1

    elseif correct_type == "table"
      tempTbl = string.split item, "::"
      initialCount = #tempTbl
      tempTbl, finalCount = list.uniq tempTbl
      tbl[i] = tempTbl

      unless initialCount == finalCount
          tempErrorMsg ..= "INFO: There were duplicate items in table. Deduplicated them. If this shouldn't happen, please fix them.\n"

    elseif correct_type == "colorstring"
      unless item\match("^&H%x+&$") or item\match("^#%x+$")
        tempErrorMsg ..= "WARNING: Argument #{i} for class \"#{_class}\" does not appear to be a valid colorstring. Received \"#{item}\" instead.\n"
        errorLevel = 1

    elseif correct_type == "boolean"
      if item == "false"
        tbl[i] = false
      elseif item == "true"
        tbl[i] = true
      else
        tempErrorMsg ..= "WARNING: Argument #{i} for class \"#{_class}\" should be boolean. Received \"#{item}\" instead."
        errorLevel = 1

    elseif _type != correct_type
      tempErrorMsg ..= "WARNING: Argument #{i} for class \"#{_class}\" should be a #{correct_type}. Got \"#{_type}\" instead.\n"
      errorLevel = 1

  if tempErrorMsg != ""
    errorMsg ..= "\nRow: #{y}, Column: #{x}\n#{tblString}\n#{tempErrorMsg}"

  errorMsg, errorLevel, tbl, nameTable


btnHandler = (btn, errorMsg, errorLevel) ->
  return nil, nil, errorMsg, errorLevel unless btn

  _type = type(btn)
  if _type != "string"
    errorMsg ..= "\nWARNING: Invalid argument passed as button string.\n"
    errorLevel = 1
    return nil, nil, errorMsg, errorLevel

  return nil, errorMsg, errorLevel if string.trim(btn) == ""

  buttonTable = {}
  buttonIDTable = {}
  tempErrorMsg = ""
  validID = {"ok", "yes", "save", "apply", "close", "no", "cancel", "help", "context_help"}

  for item in *string.split(btn, ",")
    item = string.trim item
    if item == ""
      tempErrorMsg ..= "\nWARNING: Empty button string sent as argument."
      errorLevel = 1
      continue

    itemSplit = string.split(item, ":")
    buttonName = itemSplit[1]
    if buttonName
      buttonName = string.trim buttonName
      table.insert buttonTable, buttonName
    else
      errorMsg ..= "\nWARNING: Could not determine button name in \"#{item}\""
      errorLevel = 1

    buttonID = itemSplit[2]
    if buttonID
      buttonID = string.trim buttonID
      if tableContains validID, buttonID
        buttonIDTable[buttonID] = buttonName
      else
        errorMsg ..= "\nWARNING: \"#{buttonID}\" in \"#{item}\" is not a valid button ID.\n"
        errorLevel = 1

  buttonTable, buttonIDTable, errorMsg, errorLevel


create = (str, btn = nil) ->
  -- Initialize some variables
  errorMsg = ""
  errorLevel = 0 -- 0 if warn only, 1 if fatal
  nameTable = {}
  finalTable = {}
  local cellCount
  y = 0

  -- Preliminary Check
  if string.trim(str) == ""
    aegisub.log "The string you provided is empty!"
    aegisub.cancel!


  -- Handle buttons
  button, buttonID, errorMsg, errorLevel = btnHandler(btn, errorMsg, errorLevel)

  -- Handle things that must be escaped before processing the string
  for item in str\gmatch "(%[%[[^%]]+%]%])"
    str = str\gsub (string.escLuaExp(item)), (a) ->
      a\gsub("^%[%[","")\gsub("%]%]$","")\gsub(",", "<<comma>>")\gsub("\n","<<linebreak>>")\gsub("|","<<delimiter>>")

  -- Now we begin looping through the string
  for row in *string.split(str, "\n")
    row = string.trim(row)
    continue if row == "" 

    if row == "null" or row\match "^[|%s]+$"
      y += 1
      continue

    unless row\match "^|.+|$"
      errorMsg ..= "WARNING: Row #{y} is malformed. Missing \"|\" at beginning or end.\n"
      errorLevel = 1

    row = row\gsub("^|", "")\gsub("|$", "")

    rowSplit, currCellCount = string.split row, "|"
    cellCount or= currCellCount
    if cellCount != currCellCount
      errorMsg ..= "WARNING: Row #{y} has different number of cells. (Count of |)\n"
      errorLevel = 1

    x = 0
    local prevNonEmptyColumn
    for column in *rowSplit

      column = string.trim(column)

      if column == "null"
        x += 1
        prevNonEmptyColumn = nil
        continue
      elseif column == ""
        prevNonEmptyColumn.width += 1 if prevNonEmptyColumn
        x += 1
        continue

      tbl = [string.trim(item) for item in *string.split(column, ",")]

      errorMsg, errorLevel, tbl, nameTable = sanitize(errorMsg, errorLevel, tbl, x, y, nameTable)

      -- There is probably no need to continue if errorLevel is already fatal. We just need to continue loop to collect more error messages.
      continue if errorLevel > 1

      _class = tbl[1]

      -- Revert characters that were escaped before
      for i, item in ipairs tbl
        continue unless type(item) == "string"
        tbl[i] = item\gsub("<<comma>>", ",")\gsub("<<linebreak>>", "\n")\gsub("<<delimiter>>", "|")

      if _class == "label"
        table.insert finalTable, {x: x, y: y, class: _class, label: tbl[2] or "", height: 1, width: 1}

      elseif _class == "edit"
        tempTbl = {x: x, y: y, class: _class, name: tbl[2], text: tbl[3] or "", height: 1, width: 1}
        hint = tbl[4]
        tempTbl["hint"] = hint if hint
        table.insert finalTable, tempTbl

      elseif _class == "intedit"
        tempTbl = {x: x, y: y, class: _class, name: tbl[2], value: tbl[3], height: 1, width: 1}
        tempTbl["min"] = tbl[4] or nil
        tempTbl["max"] = tbl[5] or nil
        hint = tbl[6]
        tempTbl["hint"] = hint if hint
        table.insert finalTable, tempTbl

      elseif _class == "floatedit"
        tempTbl = {x: x, y: y, class: _class, name: tbl[2], value: tbl[3], height: 1, width: 1}
        tempTbl["min"] = tbl[4] or nil
        tempTbl["max"] = tbl[5] or nil
        tempTbl["step"] = tbl[6] or nil
        hint = tbl[7]
        tempTbl["hint"] = hint if hint
        table.insert finalTable, tempTbl

      elseif _class == "textbox"
        tempTbl = {x: x, y: y, class: _class, name: tbl[2], width: 1, height: tbl[3], value: tbl[4] or ""}
        hint = tbl[5]
        tempTbl["hint"] = hint if hint
        table.insert finalTable, tempTbl

      elseif _class == "dropdown"
        tempTbl = {x: x, y: y, class: _class, name: tbl[2], items: tbl[3], value: tbl[4] or "", height: 1, width: 1}
        hint = tbl[5]
        tempTbl["hint"] = hint if hint
        table.insert finalTable, tempTbl

      elseif _class == "checkbox"
        tempTbl = {x: x, y: y, class: _class, name: tbl[2], label: tbl[3], value: tbl[4] or false, height: 1, width: 1}
        hint = tbl[5]
        tempTbl["hint"] = hint if hint
        table.insert finalTable, tempTbl

      elseif _class == "color" or _class == "coloralpha" or _class == "alpha"
        tempTbl = {x: x, y: y, class: _class, name: tbl[2], value: tbl[3] or "", height: 1, width: 1}
        hint = tbl[4]
        tempTbl["hint"] = hint if hint
        table.insert finalTable, tempTbl

      elseif _class == "pad"
        if type(tbl[2]) == "number" -- This is to allow continuation of script for debugging. Otherwise string.rep will raise error when the tbl[2] is not number
          table.insert finalTable, {x: x, y: y, class: "label", label: string.rep(" ", tbl[2]), height: 1, width: 1}
          prevNonEmptyColumn = nil

      x += 1
      prevNonEmptyColumn = finalTable[#finalTable] unless _class == "pad"
    y += 1

  -- Only show fatal error messages
  if errorLevel == 1
    aegisub.log "There are fatal errors. GUI cannot initialize until you fix them.\n"
    aegisub.log errorMsg
    aegisub.cancel!

  return finalTable, button, buttonID, errorMsg, errorLevel


debug = (str, btn = nil) ->
  _,_, _, errorMsg, errorLevel = create str, btn
  if errorMsg == ""
    aegisub.log "There are no errors. GUI can properly initialize."
  else
    aegisub.log "There are non fatal errors. GUI can initialize but fixing these errors may do you good.\n"
    aegisub.log errorMsg
  aegisub.cancel!


open = (str, btn = nil) ->
  gui,button, buttonID = create str, btn
  pressed,res = aegisub.dialog.display(gui, button, buttonID)
  pressed, res


lib = {
  :create
  :debug
  :open
}

if haveDepCtrl
  lib.version = depctrl
  return depctrl\register lib
else
  return lib
