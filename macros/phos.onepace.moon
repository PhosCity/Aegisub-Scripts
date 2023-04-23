export script_name = "One Pace"
export script_description = "One Pace Stuff"
export script_author = "PhosCity"
export script_namespace = "phos.onepace"
export script_version = "1.1.4"

haveDepCtrl, DependencyControl = pcall(require, "l0.DependencyControl")
local depctrl
if haveDepCtrl
  depctrl = DependencyControl({
    feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/personal/DependencyControl.json",
  })
require("karaskel")
re = require("aegisub.re")

-- Check if the line is dialogue or not
lineIsDialogue = (style) ->
  stl = {"[kK]araoke", "[lL]yrics", "[kK]kanji", "[tT]ranslation", "[tT]itle", "[cC]aption", "[cC]redit"}
  for item in *stl
    return false if style\match(item)
  return true


-- Round a number to a decimal places. If noDecimalPlaces is true, it retuns without decimal
round = (num, numDecimalPlaces, noDecimalPlaces = false) ->
  mult = 10^(numDecimalPlaces or 0)
  rnd = math.floor(num * mult + 0.5) / mult
  if noDecimalPlaces
    return math.floor(rnd)
  else
    return rnd


-- Progress
progress = (msg, count, total) ->
	aegisub.progress.title(msg)
	aegisub.progress.task("Processing line "..count.."/"..total)
	aegisub.progress.set(100*count/total)


-- Comment honorifics
honorifics = (subs, sel) ->

  joinList = (...) ->
    joined, j, tbls = {}, 0, {...}
    return if #tbls == 0

    for tbl in *tbls
      for v in *tbl
        j += 1
        joined[j] = v
    return joined

  honorific_removal = {"san", "chan", "kun", "sama", "dono",
    "yoi", "waina", "chwan", "swan",
    "tan", "chaburu", "dayu", "ya",}

  honorific_italicize = {"sensei", "gara", "teia", "meow", "jamon"}

  honorific_upper = [item\gsub("^%l", string.upper) for item in *(joinList honorific_removal, honorific_italicize)]

  for i in *sel
    continue unless subs[i].class == "dialogue"
    line = subs[i]
    text, style = line.text, line.style

    continue unless lineIsDialogue(style)

    -- Make honorifics lowercase if it's first letter is uppercase
    for item in *honorific_upper
      if text\match("%-"..item.."[%s%p]")
        text = text\gsub("%-"..item, (c) -> c\lower())

    -- Comment the honorifics
    for item in *honorific_removal
      if text\match("%-"..item.."[%s%p]")
        text = text\gsub("%-".. item, "{-"..item.."}")

    -- Italicize the verbal tics
    for item in *honorific_italicize
      if text\match("%-"..item.."[%s%p]")
        if style\match("[Ff]lashbacks") or style\match("[Nn]arrator") or text\match("^{\\i1}")
          text = text\gsub("%-".. item, "-{\\i0}"..item.."{\\i1}")
        else
          text = text\gsub("%-".. item, "-{\\i1}"..item.."{\\i0}")

    line.text = text
    subs[i] = line


-- Replace terms with One Pace verified terms as well as applies common fixes
replace = (subs, sel) ->
  replacements = {
    -- Attacks
    "First Gear": "Gear First", 
    "Second Gear": "Gear Second", 
    "Third Gear": "Gear Third",
    "Fourth Gear": "Gear Fourth", 
    "(First)(... )(Gear)": "%3%2%1", 
    "(Second)(... )(Gear)": "%3%2%1",
    "(Third)(... )(Gear)": "%3%2%1", 
    "(Fourth)(... )(Gear)": "%3%2%1", 
    "(%w*)( Swords? Style)": "%1-Sword Style",
    "(Tower Climb)": "Toro", 
    "([fF]leurs)": "Fleur", 
    "(Ikoku Sovereignty)": "Hegemony",
    "(Hakoku Sovereignty)": "Dominion",
    "(Concasser)": "Concassé",
    "(%w+)([-%s]Brick Fist)": "%1 Tile Fist",
    "([fF]ortieth dan punch)": "40th-degree punch",
    "([Ee]paule)": "Épaule",
    "(Cotelette)": "Côtelette",
    "(Special Attack)": "Lethal",
    "(Sure%-?Kill)": "Lethal",
    "(Warrior’s Might)": "Dominion",
    "(Nation’s Might)": "Hegemony",
    "(Plague Rounds)": "excite rounds",
    "(Plague Shot)": "excite shot",

    -- People's name, epithet, nicknames
    "(Hawk%-Eye)": "Hawk Eye",
    "(Tra%-guy)": "Traf",
    "(Traffy)": "Traf",
    "(Ben Beckman)": "Benn Beckman",
    "(Coby)": "Koby",
    "([mM]oss[%-%s][hH]ead)": "Moss Head",
    "([mM]arimo)": "Moss Head",
    "([Oo]%-[Nn]ami)": "Onami",
    "([Oo]%-[rR]obi)": "Orobi",
    "([Oo]%-[tT]ama)": "Otama",
    "([Oo]%-[tT]suru)": "Otsuru",
    "([Oo]%-[kK]iku)": "Okiku",
    "(Black Foot)": "Black Leg",
    "(Blackleg)": "Black Leg",
    "(Red Foot)": "Red Leg",
    "([Bb]ellemere)": "Bell-mère",
    "(Ji[nm]bei)": "Jinbe",
    "(Don Quixote Doflamingo)": "Donquixote Doflamingo",
    "(Iceberg)": "Iceburg",
    "(Ice Pops)": "Iceboss",
    "(Stelly)": "Sterry",
    "(Baby Five)": "Baby 5",
    "(Dogstorm)": "Inuarashi",
    "(Cat Viper)": "Nekomamushi",
    "(Stupid%-berg)": "Stupid-burg",
    "(Corgy)": "Corgi",
    "(Red%-Haired)": "Red Hair",
    "(Broggy)": "Brogy",
    "(Shelly)": "Cherie",
    "(Usopp'n)": "Usopp-un",
    "(Heracles'n)": "Heracles-un",
    "(Bon Clay)": "Bon Kurei",
    "(Eneru)": "Enel",
    "(Calgara)": "Kalgara",
    "(Laki)": "Raki",
    "(the Revolutionary Dragon)": "Dragon the Revolutionary",
    "(Moriah)": "Moria",
    "(Shiryuu)": "Shiryu",

    -- Location, landmarks etc
    "(Corvo)": "Colubo",
    "(Tower of Law)": "Tower of Justice",
    "(judicial island)": "Judicial Island",
    "(Alabasta)": "Arabasta",
    "(Whiskey Peak)": "Whisky Peak",
    "(Cherry Blossom Kingdom)": "Sakura Kingdom",
    "(Raftel)": "Laugh Tale",
    "([pP]aradise [fF]arm)": "eutopia farm",
    "(Atamayama)": "Mount Atama",
    "(Mariejois)": "Mary Geoise",
    "(Mariejoa)": "Mary Geoise",
    "(Windmill Village)": "Foosha Village",
    "(the shipbuilding island)": "Shipyard Island",
    "(city of water)": "City of Water",
    "(the Liguria Square)": "Liguria Plaza",
    "(Dock #1)": "Dock 1",
    "(Bulgemore)": "Baldimore",
    "(Excavation Labor Camp)": "Prisoner Mining Camp",
    "(Illusion Forest)": "Bewildering Forest",
    "(Shandora)": "Shandia",
    "(Maiden Island)": "Isle of Women",
    "(Ruskaina)": "Luscaina",

    -- Devil Fruit
    "(Gum%sGum)": "Gum-Gum",
    "(Rubber%-Rubber)": "Gum-Gum",
    "(Rubber%sRubber)": "Gum-Gum",
    "(Tremor%-Tremor)": "Quake-Quake",
    "(Chop%-Chop)": "Part-Part",
    "(Fish-[Mm]an)": "Fishman",
    "(G1)": "G-1",
    "(Pacifistas)": "Pacifista",

    -- Group
    "(Kouzuki)": "Kozuki",
    "(Aigis)": "Aegis",
    "(navy)": "Navy",
    "(Akazaya Nine)": "Nine Red Scabbards",
    "(Akazaya )": "Red Scabbards ",
    "(Lead Performer)": "superstar",

    --Objects
    "([sS]ea [pP]rism [sS]tone)": "seastone",
    "(Clima Takt)": "Clima-Tact",
    "([bB]lack [sS]word)": "black blade",
    "([rR]oad [pP]oneglyph)": "lode poneglyph",
    "([rR]oad)( [pP]onegliff)": "lode poneglyph",
    "([sS]nail [pP]hone)": "transponder snail",
    "([Pp]onegliff)": "poneglyph",
    "(Vivre Card)": "vivre card",
    "(Log Pose)": "log pose",

    -- Miscellaneous
    "(Buster Call)": "buster call",
    "([bB]erry)": "belly",
    "([bB]e[rl]i[%s])": "belly",
    "([bB]e[rl]i[%.])": "belly.",
    "([bB]erries)": "belly",
    "(Blank Century)": "Void Century",
    "(power holders)": "ability users",
    "(a power holder)": "an ability user",
    "(Paramount War)": "Summit War",
    "(War of the Best)": "Summit War",
    "(Yagara)": "yagara",
    "(Ball Ordeal)": "Ordeal of Balls",
    "(%-%-)": "–",
    "^%.%.%.": "",
  }

  for i in *sel
    continue unless subs[i].class == "dialogue"
    line = subs[i]
    text, style = line.text, line.style

    continue unless lineIsDialogue(style)
    for key, value in pairs replacements
      text = text\gsub(key, value)

    -- Make "Government" lowercase unless it's "World Government". Also make "world government" uppercase while we're at it.
    if text\match("Government")
      if text\match("[Ww]orld [Gg]overnment")
        text = text\gsub("[Ww]orld [Gg]overnment", "{*WG}")
      text = text\gsub("Government", "government")\gsub("{%*WG}", "World Government")

    line.text = text
    subs[i] = line


-- Apply fade to attacks
attack = (subs, sel) ->
  for i in *sel
    line = subs[i]
    if lineIsDialogue(line.style) and not line.text\match("{\\fad%([%d%.%,%s]-%)}")
      line.text = "{\\fad(150,150)}" .. line.text
    subs[i] = line


-- Fix common errors
fixErrors = (subs, sel) ->
  meta, styles = karaskel.collect_head(subs, false)
  for count, i in ipairs sel
    aegisub.cancel! if aegisub.progress.is_cancelled!
    progress("Fixing Errors", count, #sel)
    line = subs[i]
    text, style  = line.text, line.style
    continue unless lineIsDialogue(style)

    karaskel.preproc_line(subs, meta, styles, line)

    -- Don't use Impress BT in English subs
    if line.styleref.fontname == "Impress BT"
      line.effect ..= "Use Impress BT Pace"

    -- Removes the alignment tag if it's the same as the style.
    if text\match("{?\\an[1-9]}?")
      style_align = "\\an" .. line.styleref.align
      line_align = text\match("\\an[1-9]")
      if style_align == line_align
        text = text\gsub("{\\an[1-9]}", "")\gsub("\\an[1-9]", "")

    -- Removes some errors that I noticed in base/old subs that we have.
    replacements = {
      rep1: { "-%s+{\\i[01]?}(%w+){\\i[01]?}%s+(%p)", "%-%1%2" }        --    - {\i1}sama{\i0} !
      rep2: { "-%s+{\\i[01]?}(%w+){\\i[01]?}", "%-%1" }                 --    - {\i1}sama{\i0}
      rep3: { "-[%s+]?{\\i[01]?}(%w+){\\i[01]?}(!?)", "%-%1%2" }        --    - {\i1}sama{\i0}!
      rep4: { "-[%s+]?{\\i[01]?}(%w+!){\\i[01]?}", "%-%1" }             --    - {\i1}sama!{\i}
    }

    for i = 1, 4
      key = replacements["rep"..i][1]
      value = replacements["rep"..i][2]
      if text\match(key)
        text = text\gsub(key, value)

    -- Removes italics tag at the end
    text = text\gsub("{\\i[01]?}$", "")

    -- If fade tag is used at the end of the line, I've found that libass skips the fade. So shifting it to front.
    text = text\gsub("(.+)({\\fad%((%d+),(%d+)%)})$", "%2%1")

    -- Shifts {\an} to front.
    text = text\gsub("(.+)({\\an%d})$", "%2%1")

    line.text =text
    subs[i] = line
  honorifics(subs, sel)


preprocessing = (subs, sel) ->

  parseLineFold = (line) ->
    return if not line.extra
    info = line.extra["_aegi_folddata"]
    return if not info
    side, collapsed, id = info\match("^(%d+);(%d+);(%d+)$")
    return {:side, :collapsed, :id}

  fixErrors(subs, sel)                          -- Fix common errors in pace subs
  subtable = {}
  highestFoldId = 0
  for i = 1, #subs
    continue unless subs[i].class == "dialogue"
    line = subs[i]
    text = line.text
    text = text\gsub("{\\i[10]?}", "")          -- Since we're looping through all lines, remove all italics as italics are handled by styles
    line.text = text

    -- Collect fold data
    foldData = parseLineFold line
    highestFoldId = math.max(highestFoldId, foldData.id) if foldData

    -- Put lines into table for later sorting
    table.insert subtable, line
    subs[i] = line
  foldId = highestFoldId + 1

  -- =================SORTING=======================
  --sort lines by time
  table.sort(subtable, (a,b) ->
    return a.start_time<b.start_time or (a.start_time==b.start_time and a.end_time<b.end_time))
  
  -- put sorted lines back
  count = 1
  for i = 1, #subs
    continue unless subs[i].class == "dialogue"
    line = subtable[count]
    count += 1
    subs[i] = line

  -- ==========SCRIPT INFO==================
  --Get the information about the video
  xres, yres, _, _ = aegisub.video_size()
  unless xres         -- Video is not loaded
    btn, res = aegisub.dialog.display({
      { x: 0, y: 0, class: "label",    label: "It appears that video is not loaded so choose the resolution:", width: 10 },
      { x: 0, y: 1, class: "dropdown", name: "resol", value: "", items: {"1920x1080", "1440x1080"}},
    }, {"OK", "Cancel"}, {"ok": "OK", "cancel": "Cancel"})

    if btn
      if res.resol == "1920x1080"
        xres = 1920
        yres = 1080
      elseif res.resol == "1440x1080"
        xres = 1440
        yres = 1080

  unless xres
    aegisub.log ("You neither have video loaded. Nor did you choose any option. I give up.")
    aegisub.cancel!

  infoIndex, infoLine = 0, {}
  for i = 1, #subs
    if subs[i].class == "info"
      line = subs[i]
      infoIndex = i
      infoLine = line
      line.value = tostring(xres) if line.key == "PlayResX"
      line.value = tostring(yres) if line.key == "PlayResY"
      line.value = "TV.709" if line.key == "YCbCr Matrix"
      line.value = "yes" if line.key == "ScaledBorderAndShadow"
      line.value = tostring(0) if line.key == "WrapStyle"
      subs[i] = line
    break if subs[i].class=="dialogue"

  infoLine.key, infoLine.value = "LayoutResY", tostring(yres)
  subs.insert(infoIndex, infoLine)
  infoLine.key, infoLine.value = "LayoutResX", tostring(xres)
  subs.insert(infoIndex, infoLine)

  -- ==========MANAGE STYLES==================
  for i = 1, #subs
    if subs[i].class == "style"
      style = subs[i].name
      if style\match("[Mm]ain") or style\match("[Tt]houghts") or style\match("[Ff]lashbacks") or style\match("[Nn]arrator") or style\match("[Kk]araoke") or style\match("[Cc]aption")
        btn, res = aegisub.dialog.display({
          { x: 0, y: 0, class: "label",    label: "It appears that this file already has styles added."},
          { x: 0, y: 1, class: "label",    label: "It is not recommended to run this in a script that has already been timed/edited.", width: 10 },
          { x: 0, y: 2, class: "label",    label: "The script will replace all styles and add new muxer markers.", width: 10 },
          { x: 0, y: 3, class: "label",    label: "Do you want to proceed?", width: 10 },
        }, {"Yes", "No"})
        return if btn == "No"
        break
    break if subs[i].class=="dialogue"

  -- ==========DELETE ALL OLD STYLES==================
  for i = 1, #subs
    if subs[i].class == "style"
      subs.delete(i)
    break if subs[i].class=="dialogue"

  -- ==========ADD NEW STYLES==================
  stl = {
    "207+": {
      main:      { fontname: "Impress BT Pace",       italic: false, color2: "&H000000FF&", margin_t: 27,  color4: "&H78000000&", fontsize: 82, color3: "&H00000000&", class: "style", spacing: 0,   strikeout: false, encoding: 1, margin_r: 300, angle: 0, bold: false, scale_y: 100, margin_b: 27,  color1: "&H00FFFFFF&", margin_l: 300, align: 2, scale_x: 100, section: "[V4+ Styles]", borderstyle: 1, outline: 3.8, underline: false, name: "Main-207+",       shadow: 3.8 },
      flashback: { fontname: "Impress BT Pace",       italic: true,  color2: "&H00FFFFFF&", margin_t: 27,  color4: "&H78000000&", fontsize: 82, color3: "&H00525252&", class: "style", spacing: 0,   strikeout: false, encoding: 1, margin_r: 300, angle: 0, bold: false, scale_y: 100, margin_b: 27,  color1: "&H00FFFFFF&", margin_l: 300, align: 2, scale_x: 100, section: "[V4+ Styles]", borderstyle: 1, outline: 4.2, underline: false, name: "Flashbacks-207+", shadow: 3.8 },
      thought:   { fontname: "Impress BT Pace",       italic: false, color2: "&H00FFFFFF&", margin_t: 27,  color4: "&H78000000&", fontsize: 82, color3: "&H00525252&", class: "style", spacing: 0,   strikeout: false, encoding: 1, margin_r: 300, angle: 0, bold: false, scale_y: 100, margin_b: 27,  color1: "&H00FFFFFF&", margin_l: 300, align: 2, scale_x: 100, section: "[V4+ Styles]", borderstyle: 1, outline: 4.2, underline: false, name: "Thoughts-207+",   shadow: 3.8 },
      secondary: { fontname: "Impress BT Pace",       italic: false, color2: "&H00FFFFFF&", margin_t: 27,  color4: "&H78000000&", fontsize: 82, color3: "&H00000000&", class: "style", spacing: 0,   strikeout: false, encoding: 1, margin_r: 300, angle: 0, bold: false, scale_y: 100, margin_b: 27,  color1: "&H00D6D6D6&", margin_l: 300, align: 2, scale_x: 100, section: "[V4+ Styles]", borderstyle: 1, outline: 3.8, underline: false, name: "Secondary-207+",  shadow: 3.8 },
      narrator:  { fontname: "Impress BT Pace",       italic: true,  color2: "&H000000FF&", margin_t: 27,  color4: "&H78000000&", fontsize: 82, color3: "&H00000000&", class: "style", spacing: 0,   strikeout: false, encoding: 1, margin_r: 300, angle: 0, bold: false, scale_y: 100, margin_b: 27,  color1: "&H00FFFFFF&", margin_l: 300, align: 8, scale_x: 100, section: "[V4+ Styles]", borderstyle: 1, outline: 3.8, underline: false, name: "Narrator-207+",   shadow: 3.8 },
      title:     { fontname: "M+ 1c",                 italic: false, color2: "&H000000FF&", margin_t: 360, color4: "&H00000000&", fontsize: 95, color3: "&H00000000&", class: "style", spacing: 0,   strikeout: false, encoding: 1, margin_r: 15,  angle: 0, bold: true,  scale_y: 100, margin_b: 360, color1: "&H00FEFEFE&", margin_l: 15,  align: 2, scale_x: 100, section: "[V4+ Styles]", borderstyle: 1, outline: 2.5, underline: false, name: "Title-207+",      shadow: 0   },
      captions:  { fontname: "FOT-Greco Std DB Strp", italic: false, color2: "&H000000FF&", margin_t: 30,  color4: "&H00000000&", fontsize: 56, color3: "&H00000000&", class: "style", spacing: 0,   strikeout: false, encoding: 1, margin_r: 15,  angle: 0, bold: false, scale_y: 100, margin_b: 30,  color1: "&H00FFFFFF&", margin_l: 15,  align: 2, scale_x: 100, section: "[V4+ Styles]", borderstyle: 1, outline: 3,   underline: false, name: "Captions-207+",   shadow: 0   },
      credits:   { fontname: "FOT-Greco Std DB Strp", italic: false, color2: "&H000000FF&", margin_t: 15,  color4: "&H00000000&", fontsize: 55, color3: "&H00000000&", class: "style", spacing: 1.5, strikeout: false, encoding: 1, margin_r: 15,  angle: 0, bold: false, scale_y: 105, margin_b: 15,  color1: "&H00FFFFFF&", margin_l: 15,  align: 7, scale_x: 105, section: "[V4+ Styles]", borderstyle: 1, outline: 3.7, underline: false, name: "Credits-207+",    shadow: 0   },
      warning:   { fontname: "Impress BT Pace",       italic: false, color2: "&H000000FF&", margin_t: 10,  color4: "&H00000000&", fontsize: 90, color3: "&H00000000&", class: "style", spacing: 0,   strikeout: false, encoding: 1, margin_r: 10,  angle: 0, bold: false, scale_y: 100, margin_b: 10,  color1: "&H00FFFFFF&", margin_l: 10,  align: 2, scale_x: 100, section: "[V4+ Styles]", borderstyle: 1, outline: 2.0, underline: false, name: "Warning",         shadow: 2.0 },
      },
    "207-": {
      main:      { fontname: "Impress BT Pace",       italic: false, color2: "&H00002EFF&", margin_t: 27,  color4: "&H78000000&", fontsize: 82, color3: "&H00000000&", class: "style", spacing: 0,   strikeout: false, encoding: 1, margin_r: 180, angle: 0, bold: false, scale_y: 100, margin_b: 27,  color1: "&H00FFFFFF&", margin_l: 180, align: 2, scale_x: 100, section: "[V4+ Styles]", borderstyle: 1, outline: 3.8, underline: false, name: "Main-207-",       shadow: 3.8 },
      flashback: { fontname: "Impress BT Pace",       italic: true,  color2: "&H00FFFFFF&", margin_t: 27,  color4: "&H78000000&", fontsize: 82, color3: "&H00525252&", class: "style", spacing: 0,   strikeout: false, encoding: 1, margin_r: 180, angle: 0, bold: false, scale_y: 100, margin_b: 27,  color1: "&H00FFFFFF&", margin_l: 180, align: 2, scale_x: 100, section: "[V4+ Styles]", borderstyle: 1, outline: 3.8, underline: false, name: "Flashbacks-207-", shadow: 3.8 },
      thought:   { fontname: "Impress BT Pace",       italic: false, color2: "&H00FFFFFF&", margin_t: 27,  color4: "&H78000000&", fontsize: 82, color3: "&H00525252&", class: "style", spacing: 0,   strikeout: false, encoding: 1, margin_r: 180, angle: 0, bold: false, scale_y: 100, margin_b: 27,  color1: "&H00FFFFFF&", margin_l: 180, align: 2, scale_x: 100, section: "[V4+ Styles]", borderstyle: 1, outline: 4.4, underline: false, name: "Thoughts-207-",   shadow: 3.8 },
      secondary: { fontname: "Impress BT Pace",       italic: false, color2: "&H00FFFFFF&", margin_t: 27,  color4: "&H78000000&", fontsize: 82, color3: "&H00000000&", class: "style", spacing: 0,   strikeout: false, encoding: 1, margin_r: 180, angle: 0, bold: false, scale_y: 100, margin_b: 27,  color1: "&H00D6D6D6&", margin_l: 180, align: 2, scale_x: 100, section: "[V4+ Styles]", borderstyle: 1, outline: 3.8, underline: false, name: "Secondary-207-",  shadow: 3.8 },
      narrator:  { fontname: "Impress BT Pace",       italic: true,  color2: "&H000000FF&", margin_t: 27,  color4: "&H78000000&", fontsize: 82, color3: "&H00000000&", class: "style", spacing: 0,   strikeout: false, encoding: 1, margin_r: 180, angle: 0, bold: false, scale_y: 100, margin_b: 27,  color1: "&H00FFFFFF&", margin_l: 180, align: 8, scale_x: 100, section: "[V4+ Styles]", borderstyle: 1, outline: 3.8, underline: false, name: "Narrator-207-",   shadow: 3.8 },
      title:     { fontname: "M+ 1c",                 italic: false, color2: "&H00002EFF&", margin_t: 383, color4: "&H00000000&", fontsize: 95, color3: "&H00000000&", class: "style", spacing: 0,   strikeout: false, encoding: 1, margin_r: 15,  angle: 0, bold: true,  scale_y: 100, margin_b: 383, color1: "&H00FEFEFE&", margin_l: 15,  align: 2, scale_x: 100, section: "[V4+ Styles]", borderstyle: 1, outline: 2.5, underline: false, name: "Title-207-",      shadow: 0   },
      captions:  { fontname: "Chinacat",              italic: false, color2: "&H000019FF&", margin_t: 27,  color4: "&H00000000&", fontsize: 99, color3: "&H00000000&", class: "style", spacing: 5,   strikeout: false, encoding: 1, margin_r: 16,  angle: 0, bold: true,  scale_y: 100, margin_b: 27,  color1: "&H00FFFFFF&", margin_l: 16,  align: 2, scale_x: 100, section: "[V4+ Styles]", borderstyle: 1, outline: 3.4, underline: false, name: "Captions-207-",   shadow: 0   },
      credits:   { fontname: "FOT-Greco Std B Strp",  italic: false, color2: "&H00002EFF&", margin_t: 16,  color4: "&H00000000&", fontsize: 50, color3: "&H00000000&", class: "style", spacing: 1.6, strikeout: false, encoding: 1, margin_r: 16,  angle: 0, bold: true,  scale_y: 100, margin_b: 16,  color1: "&H00FFFFFF&", margin_l: 16,  align: 7, scale_x: 95,  section: "[V4+ Styles]", borderstyle: 1, outline: 3,   underline: false, name: "Credits-207-",    shadow: 0   }
      warning:   { fontname: "Impress BT Pace",       italic: false, color2: "&H000000FF&", margin_t: 10,  color4: "&H00000000&", fontsize: 90, color3: "&H00000000&", class: "style", spacing: 0,   strikeout: false, encoding: 1, margin_r: 10,  angle: 0, bold: false, scale_y: 100, margin_b: 10,  color1: "&H00FFFFFF&", margin_l: 10,  align: 2, scale_x: 100, section: "[V4+ Styles]", borderstyle: 1, outline: 2.0, underline: false, name: "Warning",         shadow: 2.0 },
    },
  }

  st = switch xres
    when 1440 then stl["207-"]
    when 1920 then stl["207+"]
  for i = 1, #subs
    count = i-1
    if subs[i].class == "dialogue"
      for _, value in pairs st
        subs.insert(count, value)
        count += 1
      break

  -- ==========CHANGE ALL LINES TO STYLES MAIN==================
  mainStyle = st.main.name
  for i = 1, #subs
    continue unless subs[i].class == "dialogue"
    line = subs[i]
    line.style = mainStyle
    subs[i] = line

  -- ==========ADD CHAPTER AND KARAOKE MARKERS==================
  line_top = {
    line1: { actor: "", class: "dialogue", comment: true, effect: "", start_time: 0, end_time: 0, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: "========================CHAPTERS AND OPENINGS====================="}
  }
  filename = aegisub.file_name!
  if filename\match("[Rr]omance") or filename\match("[Rr][Dd]") or filename\match("[Oo]range") or filename\match("[Ss]yrup") or filename\match("[Gg]aimon") or filename\match("[Bb]aratie") or filename\match("[Aa]rlong") or filename\match("[Ll]oguetown")
    line_top["line2"] = { actor: "chptr", class: "dialogue", comment: true, effect: "", start_time: 0,      end_time: 20,     layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: "{Opening}"}
    line_top["line3"] = { actor: "chptr", class: "dialogue", comment: true, effect: "", start_time: 110170, end_time: 110210, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: "{Episode}"}
    line_top["line4"] = { actor: "OP",    class: "dialogue", comment: true, effect: "", start_time: 47900,  end_time: 48030,  layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: ""}

  elseif filename\match("[Rr]everse") or filename\match("[Ww]hisky") or filename\match("[Ll]ittle") or filename\match("[Ll][Gg]") or filename\match("[Dd]rum") or filename\match("[Dd][iI]") or filename\match("[Aa]rabasta")
    line_top["line2"] = { actor: "chptr", class: "dialogue", comment: true, effect: "", start_time: 0,      end_time: 0,      layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: "{Opening}"}
    line_top["line3"] = { actor: "chptr", class: "dialogue", comment: true, effect: "", start_time: 109920, end_time: 110130, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: "{Episode}"}
    line_top["line4"] = { actor: "OP",    class: "dialogue", comment: true, effect: "", start_time: 41060,  end_time: 41100,  layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: ""}

  elseif filename\match("[Jj]aya") or filename\match("[Ss]kypiea")
    line_top["line2"] = { actor: "chptr", class: "dialogue", comment: true, effect: "", start_time: 0,      end_time: 0,      layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: "{Opening}"}
    line_top["line3"] = { actor: "chptr", class: "dialogue", comment: true, effect: "", start_time: 109710, end_time: 109760, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: "{Episode}"}
    line_top["line4"] = { actor: "OP",    class: "dialogue", comment: true, effect: "", start_time: 25420,  end_time: 25460,  layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: ""}

  elseif filename\match("[Dd]avy") or filename\match("[Dd][Bb][Ff]") or filename\match("[Rr]ing") or filename\match("[lL][Rr][Rr][Ll]") or filename\match("[Ww]ater") or filename\match("[wW]7")
    line_top["line2"] = { actor: "chptr", class: "dialogue", comment: true, effect: "", start_time: 110090, end_time: 110180, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: "{Episode}"}
    line_top["line3"] = { actor: "chptr", class: "dialogue", comment: true, effect: "", start_time: 0,      end_time: 0,      layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: "{Opening}"}
    line_top["line4"] = { actor: "OP",    class: "dialogue", comment: true, effect: "", start_time: 26260,  end_time: 26340,  layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: ""}

  elseif filename\match("[Ee]nies") or filename\match("[eE][Ll]")
    line_top["line2"] = { actor: "chptr", class: "dialogue", comment: true, effect: "", start_time: 109840, end_time: 109880, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: "{Episode}"}
    line_top["line3"] = { actor: "chptr", class: "dialogue", comment: true, effect: "", start_time: 0,      end_time: 20,     layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: "{Opening}"}
    line_top["line4"] = { actor: "OP",    class: "dialogue", comment: true, effect: "", start_time: 1940,   end_time: 1980,   layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: ""}

  -- elseif filename\match("[Tt]hriller")
  --   line_top["line2"] =
  --   line_top["line3"] =
  --   line_top["line4"] =

  -- elseif filename\match("[Ii]mpel") or filename\match("[Ii][dD]")
  --   line_top["line2"] =
  --   line_top["line3"] =
  --   line_top["line4"] =

  -- elseif filename\match("[Mm]arineford")
  --   line_top["line2"] =
  --   line_top["line3"] =
  --   line_top["line4"] =

  elseif filename\match("[Pp]ostwar") or filename\match("[Pp][Ww]")
    line_top["line2"] = { actor: "chptr", class: "dialogue", comment: true, effect: "", start_time: 0,      end_time: 151000, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: "{Opening}"}
    line_top["line3"] = { actor: "chptr", class: "dialogue", comment: true, effect: "", start_time: 151000, end_time: 151040, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: "{Episode}"}
    line_top["line4"] = { actor: "OP",    class: "dialogue", comment: true, effect: "", start_time: 3620,   end_time: 3650,   layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: ""}

  elseif filename\match("[Rr]eturn") or filename\match("[Rr][Tt][Ss]") or filename\match("[Ff]ishmen") or filename\match("[Ff][Ii]") or filename\match("[Ff]ishman")
    line_top["line2"] = { actor: "OP",    class: "dialogue", comment: true, effect: "", start_time: 38920,  end_time: 39020,  layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: ""}
    line_top["line3"] = { actor: "chptr", class: "dialogue", comment: true, effect: "", start_time: 113200, end_time: 156070, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: "{Episode}"}
    line_top["line4"] = { actor: "chptr", class: "dialogue", comment: true, effect: "", start_time: 0,      end_time: 20,     layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: "{Opening}"}

  -- elseif filename\match("[Dd]ressrosa")
  --   line_top["line2"] =
  --   line_top["line3"] =
  --   line_top["line4"] =

  -- elseif filename\match("[Zz]ou")
  --   line_top["line2"] =
  --   line_top["line3"] =
  --   line_top["line4"] =

  -- elseif filename\match("[Ww]hole") or filename\match("[Ww][Cc][Ii]")
  --   line_top["line2"] =
  --   line_top["line3"] =
  --   line_top["line4"] =

  -- elseif filename\match("[Rr]everie")
  --   line_top["line2"] =
  --   line_top["line3"] =
  --   line_top["line4"] =

  elseif filename\match("[Ww]ano")
    line_top["line2"] = { actor: "chptr", class: "dialogue", comment: true, effect: "", start_time: 0,      end_time: 0,      layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: "{Opening}"}
    line_top["line3"] = { actor: "chptr", class: "dialogue", comment: true, effect: "", start_time: 101870, end_time: 101960, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: "{Episode}"}
    line_top["line4"] = { actor: "OP",    class: "dialogue", comment: true, effect: "", start_time: 9990,   end_time: 10030,  layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: ""}

  else
    -- TODO: Maybe prompt user in this case?
    line_top["line2"] = { actor: "chptr", class: "dialogue", comment: true, effect: "", start_time: 0, end_time: 0, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: "{Opening}"}
    line_top["line3"] = { actor: "chptr", class: "dialogue", comment: true, effect: "", start_time: 0, end_time: 0, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: "{Episode}"}
    line_top["line4"] = { actor: "OP",    class: "dialogue", comment: true, effect: "", start_time: 0, end_time: 0, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: ""}

  line_top["line5"] = { actor: "", class: "dialogue", comment: false, effect: "", start_time: 0,      end_time: 9990,   layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: "Warning", text: "{\\fscx0\\fscy0\\clip(0,0,0,0)}Your media player does not support the subtitle format used in this episode.\\NSubtitles will likely not function properly.\\NPlease use one of the recommended video players, preferably mpv:\\Nhttps://mpv.io"}
  line_top["line6"] = { actor: "", class: "dialogue", comment: false, effect: "", start_time: 152510, end_time: 162500, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: "Warning", text: "{\\fscx0\\fscy0\\clip(0,0,0,0)}Your media player does not support the subtitle format used in this episode.\\NSubtitles will likely not function properly.\\NPlease use one of the recommended video players, preferably mpv:\\Nhttps://mpv.io"}
  line_top["line7"] = { actor: "", class: "dialogue", comment: true,  effect: "", start_time: 0,      end_time: 0,      layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: "========================CHAPTERS AND OPENINGS====================="}
  line_top["line8"] = { actor: "", class: "dialogue", comment: true,  effect: "", start_time: 0,      end_time: 0,      layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle, text: "===============================DIALOGUE============================"}

  line_bottom = {
    line1: { actor: "", class: "dialogue", comment: true,  effect: "", start_time: 0, end_time: 0, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle,       text: "===============================DIALOGUE============================"}
    line2: { actor: "", class: "dialogue", comment: true,  effect: "", start_time: 0, end_time: 0, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle,       text: "============================SIGNS AND TITLE========================="}
    line3: { actor: "", class: "dialogue", comment: false, effect: "", start_time: 0, end_time: 0, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: st.title.name,   text: ""}
    line4: { actor: "", class: "dialogue", comment: true,  effect: "", start_time: 0, end_time: 0, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle,       text: "============================SIGNS AND TITLE========================="}
    line5: { actor: "", class: "dialogue", comment: true,  effect: "", start_time: 0, end_time: 0, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle,       text: "===============================CREDITS=============================="}
    line6: { actor: "", class: "dialogue", comment: false, effect: "", start_time: 0, end_time: 0, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: st.credits.name, text: ""}
    line7: { actor: "", class: "dialogue", comment: true,  effect: "", start_time: 0, end_time: 0, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: mainStyle,       text: "===============================CREDITS=============================="}
  }

  for i = 1, #subs
    if subs[i].class == "dialogue"
      count = i
      for x = 1, 8
        if x == 1 or x == 8
          line_top["line"..x]["extra"] or= {}
          line_top["line"..x]["extra"]["_aegi_folddata"] = "0;1;#{foldId}"
        elseif x == 7
          line_top["line"..x]["extra"] or= {}
          line_top["line"..x]["extra"]["_aegi_folddata"] = "1;1;#{foldId}"
          foldId += 1
        current_line = line_top["line"..x]
        subs.insert(count, current_line)
        count += 1
      break
  for x = 1, 7
    if x == 2 or x == 5
      line_bottom["line"..x]["extra"] or= {}
      line_bottom["line"..x]["extra"]["_aegi_folddata"] = "0;1;#{foldId}"
    elseif x == 1 or x == 4 or x == 7
      line_bottom["line"..x]["extra"] or= {}
      line_bottom["line"..x]["extra"]["_aegi_folddata"] = "1;1;#{foldId}"
      foldId += 1
    current_line = line_bottom["line"..x]
    subs.insert(#subs+1, current_line)


-- Removes line-breakers for all cases except in double dash lines. Stolen from ua's Linebreaker.
lineUnbreaker = (subs, sel) ->
  for i in *sel
    line = subs[i]
    text, style  = line.text, line.style
    continue unless lineIsDialogue(style)
    if text\match("\\N") and not text\match("^%-%-.+\\N%-%-.+") and not text\match("^%–%s.+\\N%–%s.+")
      text = text\gsub(" *{\\i0}\\N{\\i1} *", " ")
      text = text\gsub("\\N", "\n")
      text = text\gsub(" *\n+ *", " ")
      text = text\gsub("(%w)— (%w)", "%1—%2")
    line.text =text
    subs[i] = line


-- Splits a line with 2 dialogues with em dashes or dash in the beginning
split = (subs, sel) ->
  for i in *sel
    line = subs[i]
    line2 = line
    text, style, text2 = line.text, line.style, line2.text
    continue unless lineIsDialogue(style)
    if text\match("^%-%-.+\\N%-%-.+") or text\match("^%–%s.+\\N%–%s.+")
      text = text\gsub("(%-%-)(.+)(\\N%-%-.+)", "%2")\gsub("(%–%s)(.+)(\\N%–%s.+)", "%2")
      text2 = text2\gsub("(%-%-.+\\N%-%-)(.+)", "%2")\gsub("(%–%s.+\\N%–%s)(.+)", "%2")
      line2.text = text2
      subs.insert(i + 1, line2)
    line.text = text
    subs[i] = line


-- Add music notes to the end of line
music_note = (subs, sel) ->
  for i in *sel
    line = subs[i]
    text, style  = line.text, line.style
    continue unless lineIsDialogue(style)
    unless text\match("^♪")
      line.text = "♪#{line.text}♪"
    subs[i] = line


-- Applies fade to color
transform_color = (subs, sel) ->
  meta, styles = karaskel.collect_head(subs, false)

  -- Figure out framerate of the video
  ref_ms = 100000000                    -- 10^8 ms ~~ 27.7h
  ref_frame = aegisub.frame_from_ms(ref_ms)
  local framerate
  if ref_frame                          -- Video is open
    framerate = ref_frame / ref_ms      -- in frames/ms
    framerate = round(framerate, 6)

  btn, res = aegisub.dialog.display({
    { x: 0, y: 0, class: "label",     label: "Color:",         },
    { x: 1, y: 0, class: "color",     name: "color",           width:2 },
    { x: 0, y: 1, class: "checkbox",  name: "transform_start", label: "Start:", },
    { x: 1, y: 1, class: "floatedit", name: "start",           min: 0,          width: 2  },
    { x: 0, y: 2, class: "checkbox",  name: "transform_end",   label: "End:",   },
    { x: 1, y: 2, class: "floatedit", name: "end",             min: 0,          width: 2},
  }, {"OK", "Cancel"}, {"ok": "OK", "Cancel": "Cancel"})

  if btn
    unless res.color
      aegisub.log "You have not chosen any color."
      aegisub.cancel!
    for i in *sel
      line = subs[i]
      continue unless lineIsDialogue(line.style)
      duration = line.end_time - line.start_time
      karaskel.preproc_line(subs, meta, styles, line)
      color =  res.color\gsub("#(%x%x)(%x%x)(%x%x)", "&H%3%2%1&")
      chosen_colors = "\\c"..color.."\\3c"..color.."\\4c"..color
      style1 = "\\c"..line.styleref.color1\gsub("&H%d%d", "&H")
      style3 = "\\3c"..line.styleref.color3\gsub("&H%d%d", "&H")
      style4 = "\\4c"..line.styleref.color4\gsub("&H%d%d", "&H")
      style_colors = style1..style3..style4

      if res.transform_end
        if res.end == 0
          aegisub.log "The end time cannot be 0!"
          aegisub.cancel!
        line.text = "{\\t(#{duration-res.end},0,1,#{chosen_colors})}#{line.text}"

      if res.transform_start
        if res.start == 0
          aegisub.log "The start time cannot be 0!"
          aegisub.cancel!
        --Determine the time of the first frame of line relative to start time
        start_left = 0
        if framerate
          frameNumber = line.start_time * framerate
          diff = math.ceil(frameNumber)-frameNumber
          start_left = math.floor(diff/framerate)
        line.text = "{#{chosen_colors}\\t(#{start_left},#{res.start},1,#{style_colors})}#{line.text}"

      subs[i] = line


japanese = (subs, sel, action) ->
  for i in *sel
    line = subs[i]
    if action == "cleanup"
      line.text = line.text\gsub("%([^\\}]-%)", "")\gsub("^%s", "")\gsub("^\\N", "")\gsub("・", "")
      line.text = re.sub(line.text, "（[^）]+）", "")
    elseif action == "remove_before"
      line.text = line.text\gsub("^.+\\N", "")
    elseif action == "remove_after"
      line.text = line.text\gsub("\\N.+$", "")
    subs[i] = line


onepace = (subs, sel) ->
  dlg = {
    { x: 0, y: 0, class: "label", label: script_name .. " by " .. script_author .. "\n", },
    { x: 1, y: 0, class: "label", label: "(ver. " .. script_version .. ")\n", },
    { x: 0, y: 1, class: "checkbox", name: "preprocessing",     label: "Preprocessing",             hint: "Preprocesses script to make it ready for working.", },
    { x: 1, y: 1, class: "checkbox", name: "linebreaker",       label: "Line Unbreaker",            hint: "Removes line breaker except in double-dash lines",  },
    { x: 2, y: 1, class: "checkbox", name: "split",             label: "Split",                     hint: "Splits those anything dashed lines",                },
    { x: 0, y: 2, class: "label",    label: "Only use the features\n" },
    { x: 1, y: 2, class: "label",    label: "above before timing.\n" },
    { x: 0, y: 3, class: "checkbox", name: "honorific",         label: "Honorifics",                hint: "Italicize honorifics",                       },
    { x: 1, y: 3, class: "checkbox", name: "replace",           label: "Replace",                   hint: "Various sub fixes",                          },
    { x: 2, y: 3, class: "checkbox", name: "fadetocolor",       label: "Fade to color",             hint: "Fade from/to black/white",                   },
    { x: 0, y: 4, class: "checkbox", name: "attack",            label: "Attack",                    hint: "Apply fade to attacks",                      },
    { x: 1, y: 4, class: "checkbox", name: "fixerrors",         label: "Fix common errors",         hint: "Perform final checks in the script",         },
    { x: 2, y: 4, class: "checkbox", name: "musicnote",         label: "Music Note",                hint: "Add music note to characters singing songs", },
    { x: 0, y: 5, class: "label",    label: "Japanese Subs:" },
    { x: 0, y: 6, class: "checkbox", name: "jpn_cleanup",       label: "Cleanup",                   hint: "Removes extraneous stuff in japanese subs",  },
    { x: 1, y: 6, class: "checkbox", name: "jpn_remove_before", label: "Remove before linebreaker", hint: "Remove text before line breaker",            },
    { x: 2, y: 6, class: "checkbox", name: "jpn_remove_after",  label: "Remove after linebreaker",  hint: "Remove text after line breaker",             },
  }
  buttons = { "Apply", "Apply All", "Cancel" }
  btn, res = aegisub.dialog.display(dlg, buttons)
  switch btn
    when "Cancel" then aegisub.cancel!
    when "Apply All"            -- Fix Error is part of preprocessing function and Honorific is part of fix error function so both of them are executed as well. 
      lineUnbreaker subs, sel
      split subs, sel
      preprocessing subs, sel
      replace subs, sel
    when "Apply"
      lineUnbreaker subs, sel if res.linebreaker
      split subs, sel if res.split
      preprocessing subs, sel if res.preprocessing
      honorifics subs, sel if res.honorific
      replace subs, sel if res.replace
      attack subs, sel if res.attack
      fixErrors subs, sel if res.fixerrors
      music_note subs, sel if res.musicnote
      transform_color subs, sel if res.fadetocolor
      japanese subs, sel, "cleanup" if res.jpn_cleanup
      japanese subs, sel, "remove_before" if res.jpn_remove_before
      japanese subs, sel, "remove_after" if res.jpn_remove_after

if haveDepCtrl
  depctrl\registerMacro(onepace)
else
  aegisub.register_macro(script_name, script_description, onepace)
