Scriptname SOTC:ThreadControllerScript extends ReferenceAlias
{ Universal script for managing/counting threads }
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

SOTC:SettingsEventMonitorScript Property EventMonitor Auto
{ Init 0, sets dynamically. Link to external Event monitor }

Int Property iMaxAllowedThreads Auto
{ Initialise 0. Set in Menu. Max no of Spawnpoints allowed to be working simultaneously. }

Int Property iMaxNumActiveSps Auto
{ Initialise 0. Set in Menu. Max no of Spawnpoints allowed to be active at any one time. }

Int Property iMaxNumActiveNPCs Auto
{ Initialise 0. Set in Menu. Max no of spawned NPCs allowed to be active at any one time. }

Bool Property bMasterSpCooldownTimerEnabled Auto
{ Init false. Set in Menu. Toggle for the time limit between SPs being allowed to fire }

Int Property iMasterSpCooldownTimerClock Auto
{ Init 0. Set in Menu. Limit before another SP can fire. Has major effect on balance }

Int Property iSpCooldownTimerClock Auto ;Moved to ThreadController
{ Initialise 60 (one minute), can be set in Menu. Time to cooldown before failed point retry }


;Suppose the following could become properties as well.
Int iActiveRegionsCount ;Incremented when a Region Quest starts for the first time.
Int iActiveThreadCount ;Current Active Spawnpoints spawning (not actually active)
Int iActiveSPCount ;Number of active SpawnPoints
Int iActiveNpcCount ;Number of currently managed NPCs.

;Master Event Vars
Int Property iEventFlagCount Auto
{ Init 0. Used for Master Events (see docs/comments). }
;A highly dynamic variable used to monitor number of instances that completed an event block 
;during Master events. This number will be incremented by each instance that has completed it's 
;event block, and when it compares to the expected count will enable the User/Master Script to 
;be notified that they can resume work/play. During such events, an external monitor will run to
;compare this value until the target is reached.
;Currently only used to compare with Active Region count for Master to Region events.

Bool bCooldownActive ;Flag to deny SPs because cooldown state is active.

;Note that race conditions could cause the max counts here to exceed, ever so slightly.
;This should not cause any damage apart from slightly exceeding thresholds.

Bool bThreadKillerActive ;Emergency brake. Could reuse for bCooldownActive, but that is not as absolute as this.

Int iMasterSpCooldownTimerID = 5 Const ;Performance/balance helper. Time limit before another point can fire.


;------------------------------------------------------------------------------------------------
;RETURN FUNCTIONS
;------------------------------------------------------------------------------------------------

;Check if enough Thread available to continue functioning
Bool Function GetThread(int aiMinThreadsRequired)
	
	if iMaxNumActiveNPCs > 0 ;Likely setting will not be active so this will short circuit.
		if iActiveNpcCount > iMaxNumActiveNPCs
			return false ;Nip it in the bud
		;else continue
		endif
	endif
	
	if iMaxNumActiveSps > 0 ;Likely setting will not be active so this will short circuit.
		if iActiveSpCount > iMaxNumActiveSPs
			return false ;Nip it in the bud
		;else continue
		endif
	endif
	
	if (iActiveThreadCount > iMaxAllowedThreads) || (bThreadKillerActive) || (bCooldownActive)
		return false ;Nip it in the bud
	endif
	
	;If we got this far SP can proceed
	if bMasterSpCooldownTimerEnabled
		StartTimer(iMasterSpCooldownTimerClock, iMasterSpCooldownTimerID)
		bCooldownActive = true
	endif
	
	iActiveThreadCount += aiMinThreadsRequired ;Increment thread count
	
	return true  ;And allow to continue

EndFunction


Event OnTimer(Int aiTimerID)

	if aiTimerID == iMasterSpCooldownTimerID
	
		bCooldownActive = false
		
	endif
	
EndEvent


;This function is used to force active threads, mainly by SpHelperScript. This is because of the
;'random" number of groups spawning at a Multipoint. This deliberately can exceed iMaxThreadsCount.
Function ForceAddThreads(Int aiThreadsToAdd)

	iActiveThreadCount += aiThreadsToAdd
	
EndFunction


;Subtract threads from iActive count
Function ReleaseThreads(int aiThreadsToRelease)

	iActiveThreadCount -= aiThreadsToRelease
	
EndFunction


;Emergency stop
Function ToggleThreadKiller(bool abToggle)

	bThreadKillerActive = abToggle
	
EndFunction


;Increment Active NPC count
Function IncrementActiveNpcCount(Int aiIncrement)

	iActiveNpcCount +=  aiIncrement
	
EndFunction


;Increment Active SP count
Function IncrementActiveSpCount(Int aiIncrement)

	iActiveSpCount +=  aiIncrement
	
EndFunction

;Increment Active Regions Count
Int Function IncrementActiveRegionsCount(int aiIncrement)

	iActiveRegionsCount += aiIncrement
	return iActiveRegionsCount
	;Functions calling this do not explicitly need to do anything with return value.
	
EndFunction

;Prepare the external monitor to keep an eye on Event flag count.
Function PrepareToMonitorEvent(string asType)

	if asType == "Regions"
	
		EventMonitor.BeginMonitor(iActiveRegionsCount) ;Parameter is target count.
		
	endif
	
	;Currently only Region events defined here. Will be extended in future.
	
EndFunction


;------------------------------------------------------------------------------------------------
;DEBUG FUNCTIONS
;------------------------------------------------------------------------------------------------

;This function is used anytime User needs to be informed of active spawnpoint threads.
Function ActiveThreadCheck()
	
	if iActiveThreadCount > 0
		Debug.MessageBox("WARNING: Spawn Threads are currently active, it is recommended you exit this menu now and wait for them to finish before continuing (about 10 seconds should be fine). Current Active Thread Count is" +iActiveThreadCount)
	else
		;Nothing, continue.
	endif

EndFunction


Function DisplayModStatus()

	Debug.MessageBox("Thread Killer Status: " +bThreadKillerActive as Int+ ", Current Active Thread Count is: " +iActiveThreadCount+ ", Max allowed is: " +iMaxAllowedThreads+ ", Active SpawnPoint count is: " +iActiveSpCount+ ", Max allowed is: " +iMaxNumActiveSPs+ ", Active NPC count is: " +iActiveNpcCount+ ", Max allowed is: " +iMaxNumActiveNPCs)
	
EndFunction


;------------------------------------------------------------------------------------------------
