;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_SettingsMenu_MGroupMaxCount Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
UpdateMenuVars(2)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
UpdateMenuVars(3)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
UpdateMenuVars(4)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_04
Function Fragment_Terminal_04(ObjectReference akTerminalRef)
;BEGIN CODE
UpdateMenuVars(5)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

SOTC:MasterQuestScript Property MasterScript Auto Const

Function UpdateMenuVars(Int aiValue01)

	MasterScript.SetMenuVars("RerollMaxCount", true, aiValue01)

EndFunction
