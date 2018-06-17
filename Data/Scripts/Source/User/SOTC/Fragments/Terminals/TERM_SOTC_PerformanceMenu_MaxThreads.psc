;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_PerformanceMenu_MaxThreads Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxThreads", true, 4)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxThreads", true, 5)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxThreads", true, 6)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_04
Function Fragment_Terminal_04(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxThreads", true, 7)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_05
Function Fragment_Terminal_05(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxThreads", true, 8)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_06
Function Fragment_Terminal_06(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxThreads", true, 1)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_08
Function Fragment_Terminal_08(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxThreads", true, 2)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_09
Function Fragment_Terminal_09(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxThreads", true, 3)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property SOTC_MasterQuest Auto Const
