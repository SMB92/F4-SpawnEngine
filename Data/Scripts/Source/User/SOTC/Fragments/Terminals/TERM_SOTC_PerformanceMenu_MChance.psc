;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_PerformanceMenu_MChance Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("MasterChance", true, 0)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("MasterChance", true, 10)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("MasterChance", true, 20)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_04
Function Fragment_Terminal_04(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("MasterChance", true, 30)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_05
Function Fragment_Terminal_05(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("MasterChance", true, 40)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_06
Function Fragment_Terminal_06(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("MasterChance", true, 50)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_07
Function Fragment_Terminal_07(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("MasterChance", true, 60)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_08
Function Fragment_Terminal_08(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("MasterChance", true, 70)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_09
Function Fragment_Terminal_09(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("MasterChance", true, 80)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_10
Function Fragment_Terminal_10(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("MasterChance", true, 90)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_11
Function Fragment_Terminal_11(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("MasterChance", true, 100)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property SOTC_MasterQuest Auto Const
