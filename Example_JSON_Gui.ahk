#Include %A_LineFile%\..\JSON.ahk
#SingleInstance,Force
	SetTitleMatchMode,Regex
	SetKeyDelay,-1
json_str =
(
{
	"str": "Hello World",
	"num": 12345,
	"float": 123.5,
	"true": true,
	"false": false,
	"null": null,
	"array": [
		"Auto",
		"Hot",
		"key"
	],
	"object": {
		"A": "Auto",
		"H": "Hot",
		"K": "key"
	}
}
)
	;--------------------------------------------------
	; * gui defined
	;--------------------------------------------------
		Gui, Destroy
		Gui, +AlwaysOnTop
		Gui,Font,s9,Open Sans
	;--------------------------------------------------
	; ** define basic layout
	;--------------------------------------------------
		marginTop     = 10
		marginLeft    = 10
		xCol1         = 90
		xCol2         = 460
		ew     = 400
		bH            = 26 ; button height
		Gui, Add, Text,      section x10           w80  ,Input JSON:
		Gui, Add, Edit,      xs ys+20    h500  w400 Wrap Multi vInput hwndInput,%json_str%
		Gui, Add, Button,           ym ys+20 w75   gcmd_Parsed, &Parsed
		Gui, Add, Button,            w75   gcmd_Stringified, &Stringified
		Gui, Add, Text,       ym w80 x+10 section ,Output:
		Gui, Add, Edit, xs    ys+20 w400 h500 Wrap Multi vOutput hwndOutput
;/* ===BUTTON=== */
		Gui, Add, Button, w60 section default h%bH% gOK, &OK
		Gui, Add, Button, w60 ys h%bH% gClose, &Cancel
		Gui, Show,, PowerShell CSV Output Script
		GuiControl, Focus, filename
		return  ; End of auto-execute section. The script is idle until the user does something.
	ControlSetText,, %filename_code%, ahk_id %filename%
		Return
;/* ===SUBMIT OK BUTTON=== */
GuiSubmit:
OK:
			ControlGetText,sInput  ,,ahk_id %Input%
			ControlSetText,, %sInput%, ahk_id %Output%
Return
	GuiEscape:
		Gui, Destroy
	Return
Close:
	Gui, Destroy
Return
cmd_Parsed:
	ControlGetText,sInput  ,,ahk_id %Input%
	parsed := JSON.Load(sInput)
	parsed_out := Format("
	(Join`r`n
	String: {}
	Number: {}
	Float:  {}
	true:   {}
	false:  {}
	null:   {}
	array:  [{}, {}, {}]
	object: {{}A:""{}"", H:""{}"", K:""{}""{}}
	)"
	, parsed.str, parsed.num, parsed.float, parsed.true, parsed.false, parsed.null
	, parsed.array[1], parsed.array[2], parsed.array[3]
	, parsed.object.A, parsed.object.H, parsed.object.K)


	ControlSetText,, %parsed_out%, ahk_id %Output%
Return
cmd_Stringified:
	ControlGetText,sInput  ,,ahk_id %Input%
	parsed := JSON.Load(sInput)
	stringified := JSON.Dump(parsed,, 4)
	stringified := StrReplace(stringified, "`n", "`r`n") ; for display purposes only

	ControlSetText,, %stringified%, ahk_id %Output%
Return
