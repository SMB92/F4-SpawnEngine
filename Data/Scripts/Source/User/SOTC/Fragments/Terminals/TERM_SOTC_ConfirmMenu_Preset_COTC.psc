;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_ConfirmMenu_Preset_COTC Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC:MasterQuestScript MasterScript = MasterQuest as SOTC:MasterQuestScript
;Cast first, cannot set custom type property on terminal fragment

MasterScript.SetMenuSettingsMode(10) ;Pending Full Preset

MasterScript.iCurrentPreset = 3

MasterScript.RegisterMasterForPipBoyCloseEvent()
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
(AuxQuest as SOTC:AuxilleryQuestScript).PrepareToInitSpawnEngine(3)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property MasterQuest Auto Const

Quest Property AuxQuest Auto Const
