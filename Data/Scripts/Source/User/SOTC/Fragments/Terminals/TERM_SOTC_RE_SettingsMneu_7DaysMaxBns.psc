;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_RE_SettingsMneu_7DaysMaxBns Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_RE_SevenDaysControllerQuest as SOTC:RandomEvents:SevenDaysQuestScript).SetMenuVars("MaxCountBonus", true, 1)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_RE_SevenDaysControllerQuest as SOTC:RandomEvents:SevenDaysQuestScript).SetMenuVars("MaxCountBonus", true, 2)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_RE_SevenDaysControllerQuest as SOTC:RandomEvents:SevenDaysQuestScript).SetMenuVars("MaxCountBonus", true, 3)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_04
Function Fragment_Terminal_04(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_RE_SevenDaysControllerQuest as SOTC:RandomEvents:SevenDaysQuestScript).SetMenuVars("MaxCountBonus", true, 0)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property SOTC_RE_SevenDaysControllerQuest Auto Const
