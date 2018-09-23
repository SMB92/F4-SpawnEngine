Scriptname SOTC:EvalPkgTrackLoadStatusEffectScript extends ActiveMagicEffect
{ This script is applied to raoming/travelling Actors on spawn and causes applied Package to Evaluate immediately in own thread
and then tracks OnCellAttach/Detach events so we can disable/enable the Actor when they are unloaded for so long/loaded again. }
;Written by SMB92
;Special thanks to J. Ostrus [BigandFlabby] for code contributions that made this mod possible.

;LEGEND - PREFIX CONVENTION
; Variables and Properties are treated the same. Script types do not have prefixes, unless they
;are explicitly received as function arguments and are multi-instance scripts.
; "a" - (Function/Event Blocks only) Variable was received as function argument OR the variable
;was created from a passed-in Struct/Var[] member
; "k" - Is an "Form/Object" as usual, whether created in a Block or defined in the empty state/a state.
; "f,b,i,s" - The usual Primitives: Float, Bool, Int, String.

;DEV NOTE: This script/effect is only applied to Actor which are roaming and otherwise hard to track
;the current location of without burdening Papyrus. For Actors that are going to remain close to their
;original SpawnPoint (i.e Sandbox spawns), we use the SpawnPoint Object for these events to reduce
;overall load/threads. 

;------------------------------------------------------------------------------------------------
;PROPERTIES & IMPORTS
;------------------------------------------------------------------------------------------------

SOTC:MasterQuestScript Property MasterScript Auto Const Mandatory
{ Fill with MasterQuest }

Actor kSelfAsActor
Int iExpiryTimerID = 3
;Bool bExpiryTimerRunning ;Check to prevent spam. 
Bool bIsDisabled ;Faster than running the latent ObjectReference function of similar type. 

;------------------------------------------------------------------------------------------------
;FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

Event OnEffectStart(Actor akTarget, Actor akCaster)
	
	kSelfAsActor = akTarget
	akTarget.EvaluatePackage()
	
EndEvent

;Starts the Expiry timer when Actor unloads. Actor will disable if TImer expires before reloading. 
;DEV NOTE: This Event is unreliable. It isn't critical this be received - it is simply an extra
;performance measure. If this works for most spawned Actors, it's done its job.
Event OnCellDetach()

	;if !bExpiryTimerRunning
	StartTimer(MasterScript.ThreadController.fSpShortExpiryTimerClock, iExpiryTimerID)
		;bExpiryTimerRunning = true
	;endif


EndEvent

;Re-enable the Actor/stop the Expiry timer. 
Event OnCellAttach()

	;if bExpiryTimerRunning
	CancelTimer(iExpiryTimerID)
		;bExpiryTimerRunning = false
	;endif

	if bIsDisabled	
		kSelfAsActor.Enable()
	endif

EndEvent

;Disables the Actor if occurs.
Event OnTimer(int aiTimerID)

	if aiTimerID == iExpiryTimerID
	
		;bExpiryTimerRunning = false
		kSelfAsActor.Disable()
		bIsDisabled = true

	endif
	
EndEvent

;------------------------------------------------------------------------------------------------
