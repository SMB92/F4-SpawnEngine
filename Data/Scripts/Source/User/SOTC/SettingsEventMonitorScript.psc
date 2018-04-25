Scriptname SOTC:SettingsEventMonitorScript extends ReferenceAlias
{ External monitor for the Thread Controller to flag a Master settings event as complete }
;Written by SMB92
;Special thanks to J. Ostrus [BigandFlabby] for code contributions that made this mod possible.

;LEGEND - PREFIX CONVENTION
; Variables and Properties are treated the same. Script types do not have prefixes, unless they
;are explicitly received as function arguments and are multi-instance scripts.
; "a" - (Function/Event Blocks only) Variable was received as function argument OR the variable
;was created from a passed-in Struct/Var[] member
; "k" - Is an "Object" as usual, whether created in a Block or defined in the empty state/a state.
; "f,b,i" - The usual Primitives: Float, Bool, Int.

;DEV NOTE: REALLY considering putting a Max number of active SPs counter and Active NPC counter.

;------------------------------------------------------------------------------------------------
;PROPERTIES & IMPORTS
;------------------------------------------------------------------------------------------------

SOTC:ThreadControllerScript Property ThreadController Auto Const
{ Link to thread delegator, stored on RefAlias on this Quest }

SOTC:MasterQuestScript Property MasterScript Auto Const
{ Fill with MasterQuest }

Bool bInit ;Security flag to prevent unwanted events firing again.

;------------------------------------------------------------------------------------------------
;FUNCTIONS
;------------------------------------------------------------------------------------------------

Event OnAliasInit()
	
	if !bInit
		ThreadController.EventMonitor = Self
		bInit = true
	endif
	
EndEvent	

;Keep checking the current flag count vs the target every so often.
Function BeginMonitor(Int aiTarget)

	while ThreadController.iEventFlagCount < aiTarget
	
		Utility.Wait(2.0) ;2 seconds should suffice
		
	endwhile
	
	;NOTE: Menu Vars are now reset by this script instead of in Master's Menu event block.
	MasterScript.ClearMenuVars()
	
	;Tell the user the Event has completed and play/work can resume
	Debug.MessageBox("Settings have been updated. You may resume as normal. The menu has been unlocked")
	ThreadController.iEventFlagCount = 0 ;Reset the counter

EndFunction


;------------------------------------------------------------------------------------------------
