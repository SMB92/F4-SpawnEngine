;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_EncounterZoneMenu Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC:MasterQuestScript MasterScript = (MasterQuest as SOTC:MasterQuestScript)

MasterScript.iEzApplyMode = 1

MasterScript.SendMasterSingleSettingUpdateEvent("EzApplyMode", false, 0, 0.0) ;Parameters are optional
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC:MasterQuestScript MasterScript = (MasterQuest as SOTC:MasterQuestScript)

MasterScript.iEzApplyMode = 2

MasterScript.SendMasterSingleSettingUpdateEvent("EzApplyMode", false, 0, 0.0) ;Parameters are optional
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC:MasterQuestScript MasterScript = (MasterQuest as SOTC:MasterQuestScript)

MasterScript.iEzApplyMode = 0

MasterScript.SendMasterSingleSettingUpdateEvent("EzApplyMode", false, 0, 0.0) ;Parameters are optional
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_04
Function Fragment_Terminal_04(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC:MasterQuestScript MasterScript = (MasterQuest as SOTC:MasterQuestScript)

MasterScript.iEzBorderMode = 1

MasterScript.SendMasterSingleSettingUpdateEvent("EzBorderMode", false, 0, 0.0) ;Parameters are optional
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_05
Function Fragment_Terminal_05(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC:MasterQuestScript MasterScript = (MasterQuest as SOTC:MasterQuestScript)

MasterScript.iEzBorderMode = 0

MasterScript.SendMasterSingleSettingUpdateEvent("EzBorderMode", false, 0, 0.0) ;Parameters are optional
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property MasterQuest Auto Const
