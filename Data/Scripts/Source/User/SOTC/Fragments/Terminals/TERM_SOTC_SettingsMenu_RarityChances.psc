;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_SettingsMenu_RarityChances Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).iCommonActorChance = 60
(SOTC_MasterQuest as SOTC:MasterQuestScript).iUncommonActorChance = 30
(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RarityChances", true, 4)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).iCommonActorChance = 60
(SOTC_MasterQuest as SOTC:MasterQuestScript).iUncommonActorChance = 35
(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RarityChances", true, 5)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).iCommonActorChance = 65
(SOTC_MasterQuest as SOTC:MasterQuestScript).iUncommonActorChance = 30
(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RarityChances", true, 7)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_04
Function Fragment_Terminal_04(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).iCommonActorChance = 65
(SOTC_MasterQuest as SOTC:MasterQuestScript).iUncommonActorChance = 25
(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RarityChances", true, 6)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_05
Function Fragment_Terminal_05(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).iCommonActorChance = 70
(SOTC_MasterQuest as SOTC:MasterQuestScript).iUncommonActorChance = 25
(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RarityChances", true, 8)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_06
Function Fragment_Terminal_06(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).iCommonActorChance = 75
(SOTC_MasterQuest as SOTC:MasterQuestScript).iUncommonActorChance = 20
(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RarityChances", true, 9)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_07
Function Fragment_Terminal_07(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).iCommonActorChance = 55
(SOTC_MasterQuest as SOTC:MasterQuestScript).iUncommonActorChance = 30
(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RarityChances", true, 2)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_08
Function Fragment_Terminal_08(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).iCommonActorChance = 55
(SOTC_MasterQuest as SOTC:MasterQuestScript).iUncommonActorChance = 35
(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RarityChances", true, 3)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_09
Function Fragment_Terminal_09(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).iCommonActorChance = 50
(SOTC_MasterQuest as SOTC:MasterQuestScript).iUncommonActorChance = 35
(SOTC_MasterQuest as SOTC:MasterQuestScript).SetMenuVars("RarityChances", true, 1)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property SOTC_MasterQuest Auto Const
