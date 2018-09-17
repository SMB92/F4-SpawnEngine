;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_PerformanceMenu_SpShortExp Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_01
Function Fragment_Terminal_01(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("SpShortExpiryClock", true, 60)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_02
Function Fragment_Terminal_02(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("SpShortExpiryClock", true, 120)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_03
Function Fragment_Terminal_03(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("SpShortExpiryClock", true, 180)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_04
Function Fragment_Terminal_04(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("SpShortExpiryClock", true, 240)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_05
Function Fragment_Terminal_05(ObjectReference akTerminalRef)
;BEGIN CODE
(SOTC_MasterQuest as SOTC:MasterQuestScript).ThreadController.SetMenuVars("SpShortExpiryClock", true, 300)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property SOTC_MasterQuest Auto Const
