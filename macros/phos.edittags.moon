export script_name = "Edit tags"
export script_description = "Edit tags of current lines"
export script_author = "PhosCity"
export script_namespace = "phos.edittags"
export script_version = "1.1.0"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
  feed: "",
  {
    {"l0.Functional", version: "0.3.0", url: "https://github.com/TypesettingTools/Functional",
     feed: "https://raw.githubusercontent.com/TypesettingTools/Functional/master/DependencyControl.json"},
     "Yutils"
     "karaskel",
  }
}
Functional, Yutils = depctrl\requireModules!
import list, util, string from Functional

progress = (index, sel_n, title) ->
  if aegisub.progress.is_cancelled!
    aegisub.cancel!
	aegisub.progress.task("Processing line " .. index .. "/" .. sel_n)
	aegisub.progress.set(100 * index / sel_n)
	aegisub.progress.title(title)


esc = (str) ->
  return str\gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]", "%%%1")


logg = (msg, exit_with_msg = false) ->
  msg = "{#{table.concat msg, ", "}}" if type(msg) == "table"
  aegisub.log tostring(msg).."\n"
  aegisub.cancel! if exit_with_msg


table_contains = (tbl, x) ->
  for item in *tbl
    return true if item == x
  return false


ibus = (tagvalue) ->
  tagvalue = switch tagvalue
    when true then 1
    when false then 0
  tagvalue


alfas = (value) ->
  alphaitem = { "00", "10", "20", "30", "40", "50", "60", "70", "80", "90", "A0", "B0", "C0", "D0", "E0", "F0", "F8", "FF" }
  if not table_contains alphaitem, value
    table.insert alphaitem, value
  alphaitem


fontList = (font) ->
  items = {}
  for family in *Yutils.decode.list_fonts()
    table.insert items, family.name
  if not table_contains items, font
    table.insert items, font
  items


tagInfo = {
  alpha:"00", "1a":"style", "3a":"style", "4a":"style", 
  i:"style", b:"style", u:"style", s:"style", 
  c:"style", "3c":"style", "4c":"style", 
  fs:"style", fsp:"style", fn:"style",
  fax:0, frx:0, fry:0, frz:"style", 
  bord:"style", xbord:0, ybord:0, 
  shad:"style", xshad:0, yshad:0, 
  fscx:"style", fscy:"style", 
  blur:0, be:0, 
  an:"style", 
  q:2, 
}


-- Gets the user input values from gui for the given tag
getnewvalues = (tag, res) ->
  newval = res[tag.."value"]
  switch tag
    when "pos", "org", "fad"
      val_x = res[tag.."x"]
      val_y = res[tag.."y"]
      newval = "(#{val_x},#{val_y})"
    when "c", "3c", "4c"
      newval = newval\gsub("#(%x%x)(%x%x)(%x%x)", "&H%3%2%1&")
    when "alpha", "1a", "3a", "4a"
      newval = newval\gsub("^", "&H")\gsub("$", "&")
    when "clip", "iclip"
      a, b, c, d = res[tag.."x1"], res[tag.."y1"], res[tag.."x2"], res[tag.."y2"]
      if a
        newval = "(#{a},#{b},#{c},#{d})"
      else
        newval = "(#{res[tag.."value"]})"
    when "move"
      a, b, c, d, e, f = res[tag.."x1"], res[tag.."y1"], res[tag.."x2"], res[tag.."y2"], res[tag.."t1"], res[tag.."t2"]
      if e == 0 and f == 0
        newval = "(#{a},#{b},#{c},#{d})"
      else
        newval = "(#{a},#{b},#{c},#{d},#{e},#{f})"
  return newval


edittags = (subs, sel) ->
  meta, styles = karaskel.collect_head(subs, false)
  line = subs[sel[1]]
  karaskel.preproc_line(subs, meta, styles, line)

  text = line.text
  text = text\gsub "{(\\[^}]-)}{(\\[^}]-)}", "{%1%2}"         -- If there are any disjoint sets of tags, join them
  text = text\gsub "{([^\\}]-)}", "|s|%1|e|"                  -- A bit hacky way to deactivate the comments temporarily so that they are treated as text and not tags
  text = "{}#{text}" unless text\match "^{\\[^}]+}"           -- If there is no start tags, append an empty {} to avoid breaking pattern matching

  startTagExists, inlineTagExists, transformExists = false, false, false
  startSection, transform, tagOrder, tagValue, inlineSection, inlineTags = "", "", {}, {}, {}, ""

  for section in text\gmatch "{[^{}]*}[^{}]*"
    section = section\gsub("|s|", "{")\gsub("|e|", "}")       -- Revert the comments to it's former glory
    if startSection == ""
      startSection = section\gsub("\\1c", "\\c")\gsub("^{}", "")
    else
      table.insert inlineSection, section

  startTag = startSection\match("^{[^}]+}")
  startTag or= ""
  startText = startSection\gsub "^{[^}]+}", ""

  -- Check if transforms exists in selected line
  if startTag
    trns = ""
    for tr in startTag\gmatch "\\t%b()"
      trns ..= tr
    if trns != ""
      transformExists = true
      transform = trns\gsub("\\", "\n\\")\gsub("(\\t%b())", "%1\n")\gsub("^\n", "")
    startTag = startTag\gsub "\\t%b()", ""

  -- Collect start tags
  if startTag
    startTagExists = true
    for tagname, tagvalue in startTag\gmatch "\\([1-4]?[a-z]+)([^\\{}]*)"
      table.insert tagOrder, tagname
      if tagname == "alpha" or tagname == "1a" or tagname == "3a" or tagname == "4a"
        tagValue[tagname] = tagvalue\gsub("[H&]", "")
      elseif tagname == "pos" or tagname == "org" or tagname == "fad"
        tagValue[tagname.."x"], tagValue[tagname.."y"] = tagvalue\match "%(([%d%.%-]+),([%d%.%-]+)%)"
      else
        tagValue[tagname] = tagvalue

  -- Check if inlineTags exists in selected line
  if #inlineSection > 0
    inlineTagExists = true
    for section in *inlineSection
      inlineTags ..= section\gsub("}", "}\n")\gsub("\\", "\n\\")\gsub("^\n", "")\gsub("{\n", "{").."\n\n"

  -- GUI
  allTags = {"c", "3c", "4c", "i", "b", "u", "s", "bord", "shad", "fs", "fsp", "blur", "be", "fscx", "fscy", "xbord", "ybord", "xshad", "yshad", "fax", "frx", "fry", "frz", "fay", "alpha", "1a", "3a", "4a", "an", "q", "p", "fn", "fad", "pos", "org", "clip", "iclip", "move"}
  tagTop = list.slice allTags, 1, 32

  -- Define default values for GUI
  for tag in *tagTop
    continue if table_contains(tagOrder, tag)
    if tagInfo[tag] == "style"
      tagValue[tag] = switch tag
        when "c" then util.color_from_style(line.styleref.color1)
        when "3c" then util.color_from_style(line.styleref.color3)
        when "4c" then util.color_from_style(line.styleref.color4)
        when "1a" then util.alpha_from_style(line.styleref.color1)\gsub("[H&]", "")
        when "3a" then util.alpha_from_style(line.styleref.color3)\gsub("[H&]", "")
        when "4a" then util.alpha_from_style(line.styleref.color4)\gsub("[H&]", "")
        when "bord" then line.styleref.outline
        when "shad" then line.styleref.shadow
        when "fs" then line.styleref.fontsize
        when "fscx" then line.styleref.scale_x
        when "fscy" then line.styleref.scale_y
        when "frz" then line.styleref.angle
        when "an" then line.styleref.align
        when "fsp" then line.styleref.spacing
        when "i" then ibus(line.styleref.italic)
        when "b" then ibus(line.styleref.bold)
        when "u" then ibus(line.styleref.underline)
        when "s" then ibus(line.styleref.strikeout)
        when "fn" then line.styleref.fontname
    else
      tagValue[tag] = tagInfo[tag]

  dlg = {
    { x: 0, y: 0, class: "label",                         label: "  EDIT TAGS #{script_version}"                                },

    { x: 0, y: 1, class: "checkbox",   name: "c",         label: "Primary:",  value: table_contains(tagOrder, "c")              },
    { x: 1, y: 1, class: "color",      name: "cvalue",                        value: tagValue["c"]                              },
    { x: 0, y: 2, class: "checkbox",   name: "3c",        label: "Bor&der:",  value: table_contains(tagOrder, "3c")             },
    { x: 1, y: 2, class: "color",      name: "3cvalue",                       value: tagValue["3c"]                             },
    { x: 0, y: 3, class: "checkbox",   name: "4c",        label: "Shado&w:",  value: table_contains(tagOrder, "4c")             },
    { x: 1, y: 3, class: "color",      name: "4cvalue",                       value: tagValue["4c"]                             },
		{ x: 0, y: 4, class: "checkbox",   name: "b",         label: "Bold",      value: table_contains(tagOrder, "b")              },
    { x: 1, y: 4, class: "floatedit",  name: "bvalue",                        value: tagValue["b"],                             },
		{ x: 0, y: 5, class: "checkbox",   name: "i",         label: "Italic",    value: table_contains(tagOrder, "i")              },
    { x: 1, y: 5, class: "dropdown",   name: "ivalue",                        value: tagValue["i"],           items: {"0", "1"} },
		{ x: 0, y: 6, class: "checkbox",   name: "u",         label: "Underline", value: table_contains(tagOrder, "u")              },
    { x: 1, y: 6, class: "dropdown",   name: "uvalue",                        value: tagValue["u"],           items: {"0", "1"} },
		{ x: 0, y: 7, class: "checkbox",   name: "s",         label: "Strike",    value: table_contains(tagOrder, "s")              },
    { x: 1, y: 7, class: "dropdown",   name: "svalue",                        value: tagValue["s"],           items: {"0", "1"} },

    { x: 2, y: 0, class: "checkbox",   name: "bord",      label: "\\bord",    value: table_contains(tagOrder, "bord")           },
    { x: 3, y: 0, class: "floatedit",  name: "bordvalue",                     value: tagValue["bord"],                 width: 2 },
    { x: 2, y: 1, class: "checkbox",   name: "shad",      label: "\\shad",    value: table_contains(tagOrder, "shad")           },
    { x: 3, y: 1, class: "floatedit",  name: "shadvalue",                     value: tagValue["shad"],                 width: 2 },
    { x: 2, y: 2, class: "checkbox",   name: "fs",        label: "\\fs",      value: table_contains(tagOrder, "fs")             },
    { x: 3, y: 2, class: "floatedit",  name: "fsvalue",                       value: tagValue["fs"],                   width: 2 },
    { x: 2, y: 3, class: "checkbox",   name: "fsp",       label: "\\f&sp",    value: table_contains(tagOrder, "fsp")            },
    { x: 3, y: 3, class: "floatedit",  name: "fspvalue",                      value: tagValue["fsp"],                  width: 2 },
    { x: 2, y: 4, class: "checkbox",   name: "blur",      label: "\\&blur",   value: table_contains(tagOrder, "blur")           },
    { x: 3, y: 4, class: "floatedit",  name: "blurvalue",                     value: tagValue["blur"],                 width: 2 },
    { x: 2, y: 5, class: "checkbox",   name: "be",        label: "\\be",      value: table_contains(tagOrder, "be")             },
    { x: 3, y: 5, class: "floatedit",  name: "bevalue",                       value: tagValue["be"],                   width: 2 },
    { x: 2, y: 6, class: "checkbox",   name: "fscx",      label: "\\fscx",    value: table_contains(tagOrder, "fscx")           },
    { x: 3, y: 6, class: "floatedit",  name: "fscxvalue",                     value: tagValue["fscx"],                 width: 2 },
    { x: 2, y: 7, class: "checkbox",   name: "fscy",      label: "\\fscy",    value: table_contains(tagOrder, "fscy")           },
    { x: 3, y: 7, class: "floatedit",  name: "fscyvalue",                     value: tagValue["fscy"],                 width: 2 },

    { x: 5, y: 0, class: "checkbox",   name: "xbord",     label: "\\xbord",   value: table_contains(tagOrder, "xbord")          },
    { x: 6, y: 0, class: "floatedit",  name: "xbordvalue",                    value: tagValue["xbord"],                width: 2 },
    { x: 5, y: 1, class: "checkbox",   name: "ybord",     label: "\\ybord",   value: table_contains(tagOrder, "ybord")          },
    { x: 6, y: 1, class: "floatedit",  name: "ybordvalue",                    value: tagValue["ybord"],                width: 2 },
    { x: 5, y: 2, class: "checkbox",   name: "xshad",     label: "\\&xshad",  value: table_contains(tagOrder, "xshad")          },
    { x: 6, y: 2, class: "floatedit",  name: "xshadvalue",                    value: tagValue["xshad"],                width: 2 },
    { x: 5, y: 3, class: "checkbox",   name: "yshad",     label: "\\&yshad",  value: table_contains(tagOrder, "yshad")          },
    { x: 6, y: 3, class: "floatedit",  name: "yshadvalue",                    value: tagValue["yshad"],                width: 2 },
    { x: 5, y: 4, class: "checkbox",   name: "fax",       label: "\\fax",     value: table_contains(tagOrder, "fax")            },
    { x: 6, y: 4, class: "floatedit",  name: "faxvalue",                      value: tagValue["fax"],                  width: 2 },
    { x: 5, y: 5, class: "checkbox",   name: "frx",       label: "\\frx",     value: table_contains(tagOrder, "frx")            },
    { x: 6, y: 5, class: "floatedit",  name: "frxvalue",                      value: tagValue["frx"],                  width: 2 },
    { x: 5, y: 6, class: "checkbox",   name: "fry",       label: "\\fry",     value: table_contains(tagOrder, "fry")            },
    { x: 6, y: 6, class: "floatedit",  name: "fryvalue",                      value: tagValue["fry"],                  width: 2 },
    { x: 5, y: 7, class: "checkbox",   name: "frz",       label: "\\fr&z",    value: table_contains(tagOrder, "frz")            },
    { x: 6, y: 7, class: "floatedit",  name: "frzvalue",                      value: tagValue["frz"],                  width: 2 },

    { x: 8, y: 0, class: "checkbox",   name: "fay",       label: "\\fay",     value: table_contains(tagOrder, "fay")                                        },
    { x: 9, y: 0, class: "floatedit",  name: "fayvalue",                      value: tagValue["fay"],                                                       },
    { x: 8, y: 1, class: "checkbox",   name: "alpha",     label: "\\&alpha",  value:table_contains(tagOrder, "alpha")                                       },
    { x: 9, y: 1, class: "dropdown",   name: "alphavalue",                    value: tagValue["alpha"],                items: alfas(tagValue["alpha"])      },
    { x: 8, y: 2, class: "checkbox",   name: "1a",        label: "\\1a",      value:table_contains(tagOrder, "1a")                                          },
    { x: 9, y: 2, class: "dropdown",   name: "1avalue",                       value: tagValue["1a"],                   items: alfas(tagValue["1a"])         },
    { x: 8, y: 3, class: "checkbox",   name: "3a",        label: "\\3a",      value:table_contains(tagOrder, "3a")                                          },
    { x: 9, y: 3, class: "dropdown",   name: "3avalue",                       value: tagValue["3a"],                   items: alfas(tagValue["3a"])         },
    { x: 8, y: 4, class: "checkbox",   name: "4a",        label: "\\4a",      value:table_contains(tagOrder, "4a")                                          },
    { x: 9, y: 4, class: "dropdown",   name: "4avalue",                       value: tagValue["4a"],                   items: alfas(tagValue["4a"])         },
    { x: 8, y: 5, class: "checkbox",   name: "an",        label: "\\an",      value:table_contains(tagOrder, "an")                                          },
    { x: 9, y: 5, class: "dropdown",   name: "anvalue",                       value: tagValue["an"],                   items: [i for i=1, 9]                },
		{ x: 8, y: 6, class: "checkbox",   name: "q",         label: "\\&q",      value: table_contains(tagOrder, "q")                                          },
    { x: 9, y: 6, class: "dropdown",   name: "qvalue",                        value: tagValue["q"],                    items: { "0", "1", "2", "3" }        },
    { x: 8, y: 7, class: "checkbox",   name: "p",         label: "\\p",       value: table_contains(tagOrder, "p")                                          },
    { x: 9, y: 7, class: "floatedit",  name: "pvalue",                        value: tagValue["p"],                                                         },

    { x: 0, y: 8, class: "checkbox",   name: "fad",      label: "\\fad",      value: table_contains(tagOrder, "fad")                                        },
    { x: 1, y: 8, class: "floatedit",  name: "fadx",                          value: tagValue["fadx"],                 min: 0, hint: "fade in",   width: 2  },
    { x: 3, y: 8, class: "floatedit",  name: "fady",                          value: tagValue["fady"],                 min: 0, hint: "fade out",  width: 2  },
    { x: 5, y: 8, class: "checkbox",   name: "fn",        label: "\\fn",      value: table_contains(tagOrder, "fn")                                         },
    { x: 6, y: 8, class: "dropdown",   name: "fnvalue",                       value: tagValue["fn"], items:fontList(tagValue["fn"]),              width: 4  },
    { x: 0, y: 9, class: "checkbox",   name: "pos",      label: "\\pos",      value: table_contains(tagOrder, "pos")                                        },
    { x: 1, y: 9, class: "floatedit",  name: "posx",                          value: tagValue["posx"],                 hint: "x",                 width: 2  },
    { x: 3, y: 9, class: "floatedit",  name: "posy",                          value: tagValue["posy"],                 hint: "y",                 width: 2  },
    { x: 5, y: 9, class: "checkbox",   name: "org",      label: "\\org",      value: table_contains(tagOrder, "org")                                        },
    { x: 6, y: 9, class: "floatedit",  name: "orgx",                          value: tagValue["orgx"],                 hint: "x",                 width: 2  },
    { x: 8, y: 9, class: "floatedit",  name: "orgy",                          value: tagValue["orgy"],                 hint: "y",                 width: 2  },
  }
  row = 10

  -- Add clip or iclip to gui
  for klip in *{"clip", "iclip"}
    if table_contains tagOrder, klip
      dlg2 = {{x: 0, y: row, class: "checkbox", label: klip, name: klip, value: true}}
      a, b, c, d = startTag\match "\\#{klip}%(([%-%d%.]+),([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)%)"
      if a
        dlg2[#dlg2+1] = {x: 1, y: row, class: "floatedit", name: "#{klip}x1", value: a, width: 2, hint: "x1" }
        dlg2[#dlg2+1] = {x: 3, y: row, class: "floatedit", name: "#{klip}y1", value: b, width: 2, hint: "y1" }
        dlg2[#dlg2+1] = {x: 5, y: row, class: "floatedit", name: "#{klip}x2", value: c, width: 3, hint: "x2" }
        dlg2[#dlg2+1] = {x: 8, y: row, class: "floatedit", name: "#{klip}y2", value: d, width: 2, hint: "y2" }
      else
        val = startTag\match("\\#{klip}([^\\{}]*)")\gsub("[()]", "")
        dlg2[#dlg2+1] = {x: 1, y: row, class: "edit", name: "#{klip}value", value: val, width: 9 }
      dlg = list.join dlg, dlg2
      row += 1

  -- Add move to gui
  if table_contains tagOrder, "move"
    a, b, c, d, e, f = startTag\match "\\move%(([%-%d%.]+),([%-%d%.]+),([%-%d%.]+),([%-%d%.]+),([%-%d]+),([%-%d]+)%)"
    unless e
      a, b, c, d = startTag\match "\\move%(([%-%d%.]+),([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)%)"
      e, f = 0, 0
    dlg3 = {
      {x: 0, y: row, class: "checkbox",  name: "move",   value: true, label: "move",    },
      {x: 1, y: row, class: "floatedit", name: "movex1", value: a, width: 2, hint: "x1" },
      {x: 3, y: row, class: "floatedit", name: "movey1", value: b, width: 2, hint: "y1" },
      {x: 5, y: row, class: "floatedit", name: "movex2", value: c,           hint: "x2" },
      {x: 6, y: row, class: "floatedit", name: "movey2", value: d, width: 2, hint: "y2" },
      {x: 8, y: row, class: "floatedit", name: "movet1", value: e,           hint: "t1" },
      {x: 9, y: row, class: "floatedit", name: "movet2", value: f,           hint: "t2" },
    }
    dlg = list.join dlg, dlg3
    row += 1

  -- Add any other tags that has not been given it's own gui yet.
  otherTags = list.diff tagOrder, allTags
  if #otherTags > 0
    others = ""
    for tag in *otherTags
      others ..= startTag\match("\\#{tag}[^\\{}]*").."\n"
    _, height = others\gsub("\n", "")
    dlg4 = {
      {x: 0, y: row, class: "checkbox", value: true,    name: "other",      label: "Others"                         },
      {x: 1, y: row, class: "textbox",  value: others,  name: "othervalue", width: 9, height: math.ceil(height*1.1) }
    }
    dlg = list.join dlg, dlg4
    row += math.ceil(height*1.1)

  -- Add text to GUI
  dlg[#dlg+1] = {x: 0, y: row, class: "label", label: "Text" }
  dlg[#dlg+1] = {x: 1, y: row, class: "textbox", name: "maintext", value: startText, width: 9 }
  row += 1

  -- Add transforms and inline text to GUI
  if transformExists or inlineTagExists
    -- Determine the height of the box for inline and transform
    _, tr_height = transform\gsub("\n", "")
    _, inln_height = inlineTags\gsub("\n", "")
    tr_inln_height = math.min(10, math.max(tr_height*1.1, inln_height*1.1, 5))

    -- Determine the widith of the box for inline and transform
    local transformWidth, inlineWidth, inlnx
    if transformExists and inlineTagExists
      transformWidth = 5
      inlnx, inlineWidth = 5, 5
    elseif transformExists
      transformWidth = 10
    elseif inlineTagExists
      inlnx, inlineWidth = 0, 10

    if transformExists
      dlg5 = {
        { x: 0, y: row,    class: "checkbox",  value: true,      name: "transform",      label: "Transform"                            },
        { x: 0, y: row+1,  class: "textbox",   value: transform, name: "transformvalue", width: transformWidth, height: tr_inln_height }
      }
      dlg = list.join dlg, dlg5

    if inlineTagExists
      dlg6 = {
        { x: inlnx, y: row,    class: "checkbox",  value: true,        name: "inlinetags",   label: "Inline Tags"                        },
        { x: inlnx, y: row+1,  class: "textbox",   value: inlineTags,  name: "inlinevalue",  width: inlineWidth, height: tr_inln_height  }
      }
      dlg = list.join dlg, dlg6

  btn, res = aegisub.dialog.display(dlg, {"Apply", "Cancel"}, {"ok": "Apply", "cancel": "Cancel"})
  aegisub.cancel! unless btn

  -- Rebuild the line with all the tag values of the gui
  finaltag = "{}#{res["maintext"]}"
  -- Grab all tags in res["other"] field
  if res["other"]
    for tag, value in res["othervalue"]\gmatch "\\([1-4]?[a-z]+)([^\\{}]*)"
      res[tag.."value"] = value\gsub("\n", "")
      res[tag] = true
  
  finalTagList = list.join(tagOrder, allTags)
  finalTagList = list.uniq(finalTagList)
  for tag in *finalTagList
    if res[tag]
      -- logg "#{tag}\n#{newval}\n#{type(newval)}"
      newval = getnewvalues(tag, res)
      finaltag = finaltag\gsub "}", "\\#{tag}#{newval}}"

  -- Rebuild transform
  if res["transform"]
    transform = res["transformvalue"]\gsub("^ *", "")\gsub(" *$", "")\gsub("\n", "")
    finaltag = finaltag\gsub "}", "#{transform}}"

  -- Rebuild inline tags
  if res["inlinetags"]
    inlinetags = res["inlinevalue"]\gsub("^ *", "")\gsub(" *$", "")\gsub("\n", "")
    finaltag ..= inlinetags

  finaltag = finaltag\gsub "^{}", ""
  line.text = finaltag
  subs[sel[1]] = line


modifire = (subs, sel) ->
  tagTable, inlineTable, tagType = {}, {}, { general: "", scale: "", perspective: "", parenthesis: "", alpha: "", color: "" }
  newTagTable = {}
  for i in *sel
    line = subs[i]
    text = line.text
    text = text\gsub "{(\\[^}]-)}{(\\[^}]-)}", "{%1%2}"                         -- If there are any disjoint sets of tags, join them
    text = text\gsub("\\t%b()", (tr) -> tr\gsub("\\t%([^\\]*(.*)%)", "%1"))     -- Remove \\t but keep the tags inside transforms
    startTags = text\match("^{>?\\[^}]-}") or ""
    inlineText = text\gsub "^{>?\\[^}]-}", ""
    for tag, value in startTags\gmatch "\\([1-4]?[a-z]+)([^\\{}]*)"
      continue if (tag == "clip" or tag == "iclip") and not value\match "%([%-%d%.]+,[%-%d%.]+,[%-%d%.]+,[%-%d%.]+%)"       -- Vectorial clip is not shown. You'd have to be mad to edit vectorial clip this way
      tagTable[tag] or= {}
      unless table_contains tagTable[tag], "\\#{tag}#{value}"
        table.insert tagTable[tag], "\\#{tag}#{value}"
    for group in inlineText\gmatch "{%*?\\[^}]-}"
      for tagvalue in group\gmatch "\\[1-4]?[a-z]+[^\\{}]*"
        unless table_contains inlineTable, tagvalue
          table.insert inlineTable, tagvalue

  -- Add all tags to the gui
  table.sort(inlineTable, (a, b) -> a < b)
  IT = table.concat(inlineTable, "\n")
  for key, value in pairs tagTable
    table.sort(tagTable[key], (a, b) -> a < b)
    switch key
      when "pos", "org", "clip", "iclip", "fad", "fade", "move"
        tagType["parenthesis"] ..= (table.concat tagTable[key], "\n").."\n"
      when "fax", "fay", "frz", "frx", "fry"
        tagType["perspective"] ..= (table.concat tagTable[key], "\n").."\n"
      when "1c", "c", "2c", "3c", "4c"
        tagType["color"] ..= (table.concat tagTable[key], "\n").."\n"
      when "alpha", "1a", "2a", "3a", "4a"
        tagType["alpha"] ..= (table.concat tagTable[key], "\n").."\n"
      when "fs", "fsp", "fscx", "fscy"
        tagType["scale"] ..= (table.concat tagTable[key], "\n").."\n"
      else
        tagType["general"] ..= (table.concat tagTable[key], "\n").."\n"

  -- Determine the height of boxes
  _, h1 = tagType["general"]\gsub "\n", ""
  _, h2 = tagType["scale"]\gsub "\n", ""
  _, h3 = tagType["perspective"]\gsub "\n", ""
  topbox_height = math.min(math.max(math.ceil(math.max(h1, h2, h3)*0.55) + 1, 6), 12)       -- limit height between 6 and 12
  _, h4 = tagType["parenthesis"]\gsub "\n", ""
  _, h5 = tagType["alpha"]\gsub "\n", ""
  _, h6 = IT\gsub "\n", ""
  bottom_height = math.min(math.max(math.ceil(math.max(h4, h5, h6)*0.55) + 1, 6), 12)
  GUI = {
    { x: 0,   y: 0,                 class: "label",   label: "General"      },
    { x: 12,  y: 0,                 class: "label",   label: "Scale"        },
    { x: 24,  y: 0,                 class: "label",   label: "Perspective"  },
    { x: 33,  y: 0,                 class: "label",   label: "Inline"       },
    { x: 0,   y: topbox_height + 1, class: "label",   label: "Parenthesis"  },
    { x: 12,  y: topbox_height + 1, class: "label",   label: "Alpha"        },
    { x: 24,  y: topbox_height + 1, class: "label",   label: "Color"        },
    { x: 31,  y: topbox_height + 1, class: "color",                         },
    { x: 0,   y: 1,                 class: "textbox", width: 12,            height: topbox_height, name: "general",     value: tagType["general"]     },
    { x: 12,  y: 1,                 class: "textbox", width: 12,            height: topbox_height, name: "scale",       value: tagType["scale"]       },
    { x: 24,  y: 1,                 class: "textbox", width: 9,             height: topbox_height, name: "perspective", value: tagType["perspective"] },
    { x: 0,   y: topbox_height + 2, class: "textbox", width: 12,            height: bottom_height, name: "parenthesis", value: tagType["parenthesis"] },
    { x: 12,  y: topbox_height + 2, class: "textbox", width: 12,            height: bottom_height, name: "alpha",       value: tagType["alpha"]       },
    { x: 24,  y: topbox_height + 2, class: "textbox", width: 9,             height: bottom_height, name: "color",       value: tagType["color"]       },
    { x: 33,  y: 1,                 class: "textbox", width: 12,            height: bottom_height + topbox_height,      name: "inline", value: IT     },
  }
  btn, res = aegisub.dialog.display(GUI, { "Modify", "Cancel" }, {"ok": "Modify", "cancel": "Cancel"})
  if btn
    change = {}
    -- Get all the tags from the gui
    for key, _ in pairs tagType
      newTbl = string.split res[key], "\n"
      continue if #newTbl == 0
      for item in *newTbl
        tag, value = item\match "\\([1-4]?[a-z]+)(.*)"
        continue unless tag
        newTagTable[tag] or= {}
        table.insert newTagTable[tag], "\\#{tag}#{value}"
    -- Inline Tags
    newInlineTag = string.split res["inline"], "\n"

    -- Check which tags were changed in the gui
    for key, value in pairs tagTable
      for index, old in ipairs value
        new = newTagTable[key][index]
        table.insert change, "#{old}||#{new}"

    -- Change the tags in the line
    for index, i in ipairs sel
      progress(index, #sel, "Modifying...")
      line = subs[i]
      text = line.text
      startTags = text\match("^{>?\\[^}]-}") or ""
      t2 = text\gsub "^{>?\\[^}]-}", ""
      -- Start Tags
      for item in *change
        old, new = item\match "([^|]+)||(.*)"
        startTags = startTags\gsub esc(old).."([\\})])", esc(new).."%1"
      -- Inline Tags
      for index, item in ipairs newInlineTag
        continue if not item or item == ""
        t2 = t2\gsub esc(inlineTable[index]).."([\\})])", esc(item).."%1"
      text = startTags..t2
      line.text = text
      subs[i] = line

main = (subs, sel) ->
  if #sel == 1
    edittags subs, sel
  else
    modifire subs, sel

depctrl\registerMacro(main)
