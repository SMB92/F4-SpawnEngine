;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_RandomEventsMainMenu Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_RE_SevenDaysControllerQuest as SOTC:RandomEvents:SevenDaysQuestScript).SetMenuVars("InitStatus")
; A variable on the script stores whehtehr or not the Event is active, as GetStage is not reliable for repeatable stage Quests.
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_05
Function Fragment_Terminal_05(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_RE_SevenDaysControllerQuest as SOTC:RandomEvents:GhoulApocQuestScript).SetMenuVars("InitStatus")
; A variable on the script stores whehtehr or not the Event is active, as GetStage is not reliable for repeatable stage Quests.
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property SOTC_RE_SevenDaysControllerQuest Auto Const

Quest Property SOTC_RE_GhoulApocControllerQuest Auto Const

GlobalVariable Property SOTC_Global_EventQuestStatus Auto Const
