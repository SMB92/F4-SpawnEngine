;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname SOTC:Fragments:Terminals:TERM_SOTC_RE_SettingsMenu_GAMain Extends Terminal Hidden Const

;BEGIN FRAGMENT Fragment_Terminal_05
Function Fragment_Terminal_05(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC_RE_GhoulApocControllerQuest.SetStage(1)
Controller.SetMenuVars("InitStatus")
;Activate stage
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_Terminal_06
Function Fragment_Terminal_06(ObjectReference akTerminalRef)
;BEGIN CODE
SOTC_RE_GhoulApocControllerQuest.SetStage(100)
Controller.SetMenuVars("InitStatus")
;Shutdown stage
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property SOTC_RE_GhoulApocControllerQuest Auto Const

SOTC:RandomEvents:GhoulApocQuestScript Property Controller Auto Const
