;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_PerformanceMenu_MaxTravel Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxTravelNPCs", true, 100)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxTravelNPCs", true, 150)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_04
Function Fragment_Terminal_04(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxTravelNPCs", true, 200)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_05
Function Fragment_Terminal_05(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxTravelNPCs", true, 250)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_06
Function Fragment_Terminal_06(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxTravelNPCs", true, 300)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_07
Function Fragment_Terminal_07(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxTravelNPCs", true, 400)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_08
Function Fragment_Terminal_08(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("MaxTravelNPCs", true, 500)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property SOTC_MasterQuest Auto Const
