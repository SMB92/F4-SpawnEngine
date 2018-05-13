Scriptname SOTC:SettingsEventMonitorScript extends ObjectReference
{ External monitor for the Thread Controller to flag a Master settings event as complete }
;Written by SMB92
;Special thanks to J. Ostrus [BigandFlabby] for code contributions that made this mod possible.

;LEGEND - PREFIX CONVENTION
; Variables and Properties are treated the same. Script types do not have prefixes, unless they
;are explicitly received as function arguments and are multi-instance scripts.
; "a" - (Function/Event Blocks only) Variable was received as function argument OR the variable
;was created from a passed-in Struct/Var[] member
; "k" - Is an "Object" as usual, whether created in a Block or defined in the empty state/a state.
; "f,b,i,s" - The usual Primitives: Float, Bool, Int, String.

;------------------------------------------------------------------------------------------------
;PROPERTIES & IMPORTS
;------------------------------------------------------------------------------------------------

Group Primary

	SOTC:MasterQuestScript Property MasterScript Auto Const Mandatory
	{ Fill with MasterQuest }

EndGroup


Group Dynamic

	SOTC:ThreadControllerScript Property ThreadController Auto
	{ Init None, fills dynamically.  }
	
EndGroup


Bool bInit ;Security check to make sure Init events/functions don't fire again while running


;------------------------------------------------------------------------------------------------
;FUNCTIONS
;------------------------------------------------------------------------------------------------

;DEV NOTE: Init events/functions now handled by Masters creating the instances.

Function PerformFirstTimeSetup(SOTC:ThreadControllerScript aThreadController)
	
	if !bInit
		
		ThreadController = aThreadController
		ThreadController.EventMonitor = Self
		bInit = true
		
	endif
	
EndFunction	


;Keep checking the current flag count vs the target every so often.
Function BeginMonitor(Int aiTarget)

	while ThreadController.iEventFlagCount < aiTarget
	
		Utility.Wait(1.0) ;1 second should suffice, if not overkill
		
	endwhile
	
	;NOTE: Menu Vars are now reset by this script instead of in Master's Menu event block.
	MasterScript.ClearMenuVars()
	
	;Tell the user the Event has completed and play/work can resume
	Debug.MessageBox("Settings have been updated. You may resume as normal. The menu has been unlocked")
	ThreadController.iEventFlagCount = 0 ;Reset the counter

EndFunction


;------------------------------------------------------------------------------------------------
