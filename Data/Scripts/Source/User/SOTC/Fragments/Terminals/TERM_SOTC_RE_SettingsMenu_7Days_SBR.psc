;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_RE_SettingsMenu_7Days_SBR Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_RE_SevenDaysControllerQuest as SOTC:RandomEvents:SevenDaysQuestScript).SetMenuVars("SpawnsBeforeReset", true, 1)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_RE_SevenDaysControllerQuest as SOTC:RandomEvents:SevenDaysQuestScript).SetMenuVars("SpawnsBeforeReset", true, 2)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_RE_SevenDaysControllerQuest as SOTC:RandomEvents:SevenDaysQuestScript).SetMenuVars("SpawnsBeforeReset", true, 3)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_04
Function Fragment_Terminal_04(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_RE_SevenDaysControllerQuest as SOTC:RandomEvents:SevenDaysQuestScript).SetMenuVars("SpawnsBeforeReset", true, 4)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_05
Function Fragment_Terminal_05(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_RE_SevenDaysControllerQuest as SOTC:RandomEvents:SevenDaysQuestScript).SetMenuVars("SpawnsBeforeReset", true, 5)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_06
Function Fragment_Terminal_06(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_RE_SevenDaysControllerQuest as SOTC:RandomEvents:SevenDaysQuestScript).SetMenuVars("SpawnsBeforeReset", true, 6)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_07
Function Fragment_Terminal_07(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_RE_SevenDaysControllerQuest as SOTC:RandomEvents:SevenDaysQuestScript).SetMenuVars("SpawnsBeforeReset", true, 7)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property SOTC_RE_SevenDaysControllerQuest Auto Const
