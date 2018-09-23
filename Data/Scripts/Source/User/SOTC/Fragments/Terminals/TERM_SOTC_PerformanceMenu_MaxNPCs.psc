;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_PerformanceMenu_MaxNPCs Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxNPCs", true, 100)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxNPCs", true, 150)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_04
Function Fragment_Terminal_04(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxNPCs", true, 200)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_05
Function Fragment_Terminal_05(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxNPCs", true, 250)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_06
Function Fragment_Terminal_06(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxNPCs", true, 300)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_07
Function Fragment_Terminal_07(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxNPCs", true, 400)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_08
Function Fragment_Terminal_08(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxNPCs", true, 500)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_09
Function Fragment_Terminal_09(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxNPCs", true, 750)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_10
Function Fragment_Terminal_10(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxNPCs", true, 1000)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_11
Function Fragment_Terminal_11(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxNPCs", true, 1500)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_12
Function Fragment_Terminal_12(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxNPCs", true, 2000)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property SOTC_MasterQuest Auto Const
