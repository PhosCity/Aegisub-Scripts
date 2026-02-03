export script_name = "Test AegiGui"
export script_description = "Test AegiGui"
export script_version = "0.0.1"
export script_author = "PhosCity"
export script_namespace = "phos.TestAegiGui"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
  feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
  {
    {"phos.AegiGui", version: "0.0.1", url: "https://github.com/PhosCity/Aegisub-Scripts",
      feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json"},
  },
}
AegiGui = depctrl\requireModules!

main = (sub, sel) ->
  str = "
  | label, Label 1          | label, Label 2          | label, Label 3 |
  | label, Label of width 3 |                         |                |
  |                         | label, Label of width 2 |                |
  | label, Label of width 1 | null                    |                |
  "

  gui = AegiGui.create str
  aegisub.dialog.display gui

  -----------------------------------------------------------------------------------------------

  lblStr = "This is a string in variable."
  str = "
  | label, #{lblStr}                                   |
  | label, [[Escaping illegal characters like , or |]] |
  "
  btn = "Button1, Button2"
  AegiGui.open str, btn

  -----------------------------------------------------------------------------------------------

  str = "
  | label, Basic intedit class          |
  | intedit, int1, 10                   |
  | label, With alias                   |
  | int, int2, 10                       |
  | label, with minimum value           |
  | int, int3, 10, 0                    |
  | label, with maximum value           |
  | int, int4, 10, _, 100               |
  | label, with both max and min value  |
  | int, int5, 10, 0, 100               |
  | label, with hint                    |
  | int, int6, 10, _, _, This is a hint |
  "
  btn = "Button1:ok, Button2:cancel"
  AegiGui.open str, btn

  -----------------------------------------------------------------------------------------------

  str = "
  | label, Basic floatedit class                |
  | floatedit, float1, 1.5                      |
  | label, With alias                           |
  | float, float2, 1.5                          |
  | label, with minimum value                   |
  | float, float3, 1.5, 0                       |
  | label, with maximum value                   |
  | float, float4, 1.5, _, 10.5                 |
  | label, with both max and min value          |
  | float, float5, 1.5, 0, 10.5                 |
  | label, [[with both max,min and step value]] |
  | float, float6, 1.5, 0, 10.5, 0.5            |
  | label, with hint                            |
  | float, float7, 1.5, _, _, _, This is a hint |
  "
  AegiGui.open str

  -----------------------------------------------------------------------------------------------

  str = "
  | label, Basic checkbox class                 |
  | checkbox, chk1, Checkbox 1                  |
  | label, With alias                           |
  | check, chk2, Checkbox 2                     |
  | label, Force true value                     |
  | check, chk3, Checkbox 3, true               |
  | label, Force false value                    |
  | check, chk4, Checkbox 4, false              |
  | label, With hints                           |
  | check, chk5, Checkbox 5, _, This is a hint. |
  "
  AegiGui.open str

  -----------------------------------------------------------------------------------------------

  str = "
  | label, Basic dropdown class |
  | dropdown, drp1, 1::2::1, 1  |
  | label, With alias           |
  | drop, drp2, item1::item2    |
  "
  AegiGui.open str


  alfa = {"00","20","30","40","50","60","70","80","90","A0","B0","C0","D0","F0"}
  drop_alfa = table.concat(alfa,"::")..","..alfa[8]

  layer = {"-5","-4","-3","-2","-1","+1","+2","+3","+4","+5"}
  drop_layer = table.concat(layer,"::")..","..layer[6]

  -----------------------------------------------------------------------------------------------

  str = "
  | label, alpha | drop, alpha, #{drop_alfa}  |
  | label, layer | drop, layer, #{drop_layer} |
  "
  AegiGui.open str

  textboxValue = "My name is Yoshikage Kira. I'm 33 years old. My house is in the northeast section of Morioh, where all the villas are, and I am not married. I work as an employee for the Kame Yu department stores, and I get home every day by 8 PM at the latest. I don't smoke, but I occasionally drink. I'm in bed by 11 PM, and make sure I get eight hours of sleep, no matter what. After having a glass of warm milk and doing about twenty minutes of stretches before going to bed, I usually have no problems sleeping until morning. Just like a baby, I wake up without any fatigue or stress in the morning. I was told there were no issues at my last check-up. I'm trying to explain that I'm a person who wishes to live a very quiet life. I take care not to trouble myself with any enemies, like winning and losing, that would cause me to lose sleep at night. That is how I deal with society, and I know that is what brings me happiness. Although, if I were to fight I wouldn't lose to anyone."

  -----------------------------------------------------------------------------------------------

  str = "
  | label, Textbox with value        | null  | label, Using variable as value     |
  | text, txt1, 5, This is some text | pad,5 |text, txt2, 5, [[#{textboxValue}]] |
  null
  null
  null
  null
  "
  AegiGui.open str

  -----------------------------------------------------------------------------------------------

  str = "
  | edit, edit1 |
  "
  AegiGui.open str

  -----------------------------------------------------------------------------------------------

  str = "
  | label, It's width also depends on other elements of row|
  | edit, edit1, Value inside edit box                     |
  "
  AegiGui.open str

  -----------------------------------------------------------------------------------------------

  str = "
  | label, Empty coloralpha value is valid  | coloralpha, cl1              |
  | label, ABGR value can be used like this | coloralpha, cl2, &HAA0405F7& |
  "
  AegiGui.open str

  -----------------------------------------------------------------------------------------------

  str = "
  | label,-Config-----                                         |                                 |                                |
  | check,commentconfig,Comments around fold                   |                                 |                                |
  null
  | label,-Selection-----                                      | label,-Deletion-----            |                                |
  | check,select,Select current fold                           | check,delete,Delte current fold |                                |
  null
  | label,-Comment----                                         |                                 |                                |
  | check,comment,Comment                                      | check,uncomment,Uncomment       |                                |
  null
  | label,-Cut-Copy-Paste-----                                 |                                 |                                |
  | check,cut,Cut curent fold                                  | check,copy,Copy current fold    | check,paste,Paste current fold |
  null
  | label,-Others-----                                         |                                 |                                |
  | check,create,Create a new named fold around selected lines |                                 |                                |
  "
  AegiGui.open str

  -----------------------------------------------------------------------------------------------

  str = "
  | text,data,5,[[have ass, will typeset]] ||                  |        |                   |        |                           |        |
  null
  null
  null
  null
  | check,drawing,drawing           | pad,10 | check,clip,clip | pad,10 | check,iclip,iclip | pad,10 | check,pasteover,pasteover | pad,10 |
  "
  AegiGui.open str

depctrl\registerMacro main
