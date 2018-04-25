;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_AuxMenu_ConfirmON Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
(AuxQuest as SOTC:AuxilleryQuestScript).InitSpawnEngine()

SOTC_MasterGlobal.SetValue(1.0)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property AuxQuest Auto Const

GlobalVariable Property SOTC_MasterGlobal Auto Const
