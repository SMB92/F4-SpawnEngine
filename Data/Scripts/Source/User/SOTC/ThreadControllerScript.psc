Scriptname SOTC:ThreadControllerScript extends ObjectReference
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

;DEV NOTE: This script does not need a link back to the MasterScript. 

Group Dynamic
	
	SOTC:SettingsEventMonitorScript Property EventMonitor Auto
	{ Init None, fills at runtime. }
	
	GlobalVariable Property SOTC_Global01 Auto Const Mandatory
	{ Auto-fill }
	GlobalVariable Property SOTC_Global02 Auto Const Mandatory
	{ Auto-fill }
	GlobalVariable Property SOTC_Global03 Auto Const Mandatory
	{ Auto-fill }
	
EndGroup


Group Settings

	Int Property iMaxAllowedThreads = 8 Auto
	{ Initialise 8 (Default). Set in Menu. Max no of Spawnpoints allowed to be working simultaneously. }

	Int Property iMaxNumActiveSps = 1000 Auto
	{ Initialise 1000 (Default). Set in Menu. Max no of Spawnpoints allowed to be active at any one time. }

	Int Property iMaxNumActiveNPCs = 5000 Auto
	{ Initialise 5000 (Default). Set in Menu. Max no of spawned NPCs allowed to be active at any one time. }

	Float Property fNextSpCooldownTimerClock = 0.0 Auto
	{ Init 0 by default (Disabled). Set in Menu. Limit before another SP can fire. Has major effect on balance. }

	Float Property fFailedSpCooldownTimerClock = 300.0 Auto ;Moved to ThreadController
	{ Initialise 300.0 (5 Mins), can be set in Menu. Time to cooldown before failed point retry }
	
EndGroup


;Suppose the following could become properties as well.
Int iActiveRegionsCount ;Incremented when a Region Quest starts for the first time.
Int iActiveThreadCount ;Current Active Spawnpoints spawning right now if any
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

Int iNextSpCooldownTimerID = 5 Const ;Performance/balance helper. Time limit before another point can fire.

Bool bInit ;Security check to make sure Init events/functions don't fire again while running


;------------------------------------------------------------------------------------------------
;MENU FUNCTIONS
;------------------------------------------------------------------------------------------------

;This function either sets Menu Globals to current values before viewing a Menu option, or it sets
;the new value selected from said Menu. 
Function SetMenuVars(string asSetting, bool abSetValues = false, Int aiValue01 = 0)

	if asSetting == "MaxThreads"
	
		if abSetValues
			iMaxAllowedThreads = aiValue01
		endif
		SOTC_Global01.SetValue(iMaxAllowedThreads as Float)
		
	elseif asSetting == "MaxNPCs"
		
		if abSetValues
			iMaxNumActiveNPCs = aiValue01
		endif
		SOTC_Global01.SetValue(iMaxNumActiveNPCs as Float)
		
	elseif asSetting == "MaxSPs"
	
		if abSetValues
			iMaxNumActiveSPs = aiValue01
		endif
		SOTC_Global01.SetValue(iMaxNumActiveSPs as Float)
		
	elseif asSetting == "FailedSpCdTimer"
	
		if abSetValues
			fFailedSpCooldownTimerClock = aiValue01 as Float
		endif
		
		SOTC_Global01.SetValue(fFailedSpCooldownTimerClock)
	
	elseif asSetting == "NextSpCdTimer"
	
		if abSetValues
			fNextSpCooldownTimerClock = aiValue01 as Float
		endif
		
		SOTC_Global01.SetValue(fNextSpCooldownTimerClock)
		
	endif
	
EndFunction

;------------------------------------------------------------------------------------------------
;RUNTIME FUNCTIONS
;------------------------------------------------------------------------------------------------

;DEV NOTE: As this is intended to be a uniquely instanced script, no Init function is present.
;Master will set this instance when it creates it, Event Monitor will set itself when ready.

;Check if enough Thread available to continue functioning
Bool Function GetThread(int aiMinThreadsRequired)
	
	if (iActiveThreadCount > iMaxAllowedThreads) || iActiveNpcCount > iMaxNumActiveNPCs || iActiveSpCount > iMaxNumActiveSPs \
	|| (bThreadKillerActive) || (bCooldownActive)
		return false ;Nip it in the bud
	endif
	
	;If we got this far SP can proceed
	if fNextSpCooldownTimerClock > 0
		StartTimer(fNextSpCooldownTimerClock, iNextSpCooldownTimerID)
		bCooldownActive = true
	endif
	
	iActiveThreadCount += aiMinThreadsRequired ;Increment thread count
	
	return true  ;And allow to continue

EndFunction


Event OnTimer(Int aiTimerID)

	if aiTimerID == iNextSpCooldownTimerID
	
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
		Debug.Notification("TC Called Event Mon." +iActiveRegionsCount)
		
	endif
	
	;Currently only Region events defined here. May be extended in future.
	
EndFunction


;Prepares this instance for deletion, simply deletes EventMonitor.
Function MasterFactoryReset()

	EventMonitor.Disable()
	EventMonitor.Delete()
	EventMonitor = None ;De-persist
	
	;Master will proceed to delete this instance once this returns.
	
EndFunction


;------------------------------------------------------------------------------------------------
;DEBUG FUNCTIONS
;------------------------------------------------------------------------------------------------

;This function is used anytime User needs to be informed of active spawnpoint threads.
Bool Function ActiveThreadCheck()
	
	if iActiveThreadCount > 0
		Debug.MessageBox("WARNING: Spawn Threads are currently active, it is recommended you exit this menu now and wait for them to finish before continuing (about 10 seconds should be fine). Current Active Thread Count is" +iActiveThreadCount)
		return true
	else
		return false
	endif

EndFunction


Function DisplayModStatus()

	Debug.MessageBox("Thread Killer Status: " +bThreadKillerActive as Int+ ", Current Active Thread Count is: " +iActiveThreadCount+ ", Max allowed is: " +iMaxAllowedThreads+ ", Active SpawnPoint count is: " +iActiveSpCount+ ", Max allowed is: " +iMaxNumActiveSPs+ ", Active NPC count is: " +iActiveNpcCount+ ", Max allowed is: " +iMaxNumActiveNPCs)
	
EndFunction


;------------------------------------------------------------------------------------------------
