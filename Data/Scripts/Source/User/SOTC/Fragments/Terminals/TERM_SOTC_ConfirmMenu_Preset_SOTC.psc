;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_ConfirmMenu_Preset_SOTC Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC:MasterQuestScript MasterScript = MasterQuest as SOTC:MasterQuestScript
;Cast first, cannot set custom type property on terminal fragment

MasterScript.SetMenuSettingsMode(10) ;Pending Full Preset

MasterScript.iCurrentPreset = 1

MasterScript.RegisterMasterForPipBoyCloseEvent(0, 0)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property MasterQuest Auto Const
