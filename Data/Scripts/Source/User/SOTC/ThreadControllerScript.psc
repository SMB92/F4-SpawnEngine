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
	
	GlobalVariable Property SOTC_Global01 Auto Const Mandatory
	{ Auto-fill }
	GlobalVariable Property SOTC_Global02 Auto Const Mandatory
	{ Auto-fill }
	GlobalVariable Property SOTC_Global03 Auto Const Mandatory
	{ Auto-fill }
	
	Int Property iActiveRegionsCount Auto 
	{ Incremented when a Region Quest starts for the first time. }
	
	Int Property iActiveThreadCount Auto 
	{ Current Active Spawnpoints spawning right now if any. }
	
	Int Property iActiveSpCount Auto 
	{ Number of active SpawnPoints. }
	
	Int Property iActiveNpcCount Auto 
	{ Number of currently active NPCs. }
	
	Int Property iActiveTravellingNpcCount Auto
	{ Number of currently active travelling NPCs. }
	
	Int Property iEventFlagCount Auto
	{ Init 0. Used for Master Events, instances can use this to flag themselves as completed event blocks. }

EndGroup


Group Settings

	Int Property iMaxAllowedThreads = 4 Auto
	{ Initialise 4 (Default). Set in Menu. Max no of Spawnpoints allowed to be working simultaneously. }

	Int Property iMaxNumActiveSps = 300 Auto
	{ Initialise 300 (Default). Set in Menu. Max no. of Spawnpoints allowed to be active at any one time. }

	Int Property iMaxNumActiveNPCs = 1000 Auto
	{ Initialise 1000 (Default). Set in Menu. Max no. of spawned NPCs allowed to be active at any one time. }
	
	Int Property iMaxNumTravellingNPCs = 200 Auto
	{ Initialise 200 (Default). Set in Menu. Max no. of Travelling NPCs allowed. }

	Float Property fNextSpCooldownTimerClock = 0.0 Auto
	{ Init 0 by default (Disabled). Set in Menu. Limit before another SP can fire. Has major effect on balance.
Effectively this is equal to MaxThreads of 1 with a timer to expire before another SP thread is allowed.	}

	Float Property fFailedSpCooldownTimerClock = 300.0 Auto ;Moved to ThreadController
	{ Initialise 300.0 (5 Mins), can be set in Menu. Time to cooldown before failed point attempts to retry another spawn. }
	
	Float Property fSpShortExpiryTimerClock = 180.0 Auto
	{ Default value of 180.0 (3 Minutes). This Timer on the SpawnPoint will disable all spawned Actors if the SP
is no longer in the loaded area. If the Player re-enters before the Long Timer below, Actors will be re-enabled. }

EndGroup


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
		
	elseif asSetting == "MaxTravelNPCs"
		
		if abSetValues
			iMaxNumTravellingNPCs = aiValue01
		endif
		SOTC_Global01.SetValue(iMaxNumTravellingNPCs as Float)
		
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
		
	elseif asSetting == "SpShortExpiryClock"
	
		if abSetValues
			fSpShortExpiryTimerClock = aiValue01 as Float
		endif
		
		SOTC_Global01.SetValue(fSpShortExpiryTimerClock)

	endif
	
EndFunction

;------------------------------------------------------------------------------------------------
;RUNTIME FUNCTIONS
;------------------------------------------------------------------------------------------------

;DEV NOTE: As this is intended to be a uniquely instanced script, no Init function is present.
;Master will set this instance when it creates it, Event Monitor will set itself when ready.

;Check if enough Thread available to continue functioning
Bool Function GetThread(int aiMinThreadsRequired)
	
	if (iActiveThreadCount >= iMaxAllowedThreads) || iActiveNpcCount > iMaxNumActiveNPCs || iActiveSpCount > iMaxNumActiveSPs \
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


;DEV NOTE: All of the below functions exist mainly for better tracking/readability of workflow concerning this script in other scripts. 


;Emergency stop
Function ToggleThreadKiller(bool abToggle)

	bThreadKillerActive = abToggle
	
EndFunction


;This function is used to force active threads, mainly by SpHelperScript. This is because of the
;'random" number of groups spawning at a Multipoint. This deliberately can exceed iMaxThreadsCount.
Function ForceAddThreads(Int aiThreadsToAdd)

	iActiveThreadCount += aiThreadsToAdd
	
EndFunction


;Subtract threads from iActive count
Function ReleaseThreads(int aiThreadsToRelease)

	iActiveThreadCount -= aiThreadsToRelease
	
EndFunction


;Added in version 0.21.01 to reduce calls to this script from a single SpawnPoint. A SP now passes all info in one call. 
Function ProcessActiveSpawnPoint(Int aiThreadCount, Int aiNpcCount, Bool abIncrementTravellingNpcCount, Bool abIncrementEventFlag)
	
	iActiveSpCount += 1
	iActiveNpcCount +=  aiNpcCount
	if abIncrementTravellingNpcCount
		iActiveTravellingNpcCount += aiNpcCount
	endif
	
	iActiveThreadCount -= aiThreadCount
	
	if abIncrementEventFlag ;Added to this function also so stil la single call for all uses on SpawnPoint. 
		iEventFlagCount += 1
	endif
	
EndFunction


;Saves multiple calls to TC when an SP fails to spawn and needs to release threads and get the fail cooldown timer clock. 
Float Function ProcessFailedSpawnPoint(Bool abReleaseThreads, Int iThreadCount)

	if abReleaseThreads
		ReleaseThreads(iThreadCount)
	endif
	
	return fFailedSpCooldownTimerClock
	
EndFunction


Int Function IncrementActiveNpcCount(Int aiIncrement) ;Increment 0 to simply return the value. 

	iActiveNpcCount +=  aiIncrement
	return iActiveNpcCount
	;Functions calling this do not explicitly need to do anything with return value.
	
EndFunction


Int Function IncrementActiveTravellingNpcCount(Int aiIncrement) ;Increment 0 to simply return the value. 

	iActiveTravellingNpcCount +=  aiIncrement
	return iActiveTravellingNpcCount
	;Functions calling this do not explicitly need to do anything with return value.
	
EndFunction


Int Function IncrementActiveSpCount(Int aiIncrement) ;Increment 0 to simply return the value. 

	iActiveSpCount +=  aiIncrement
	return iActiveSPCount
	;Functions calling this do not explicitly need to do anything with return value.
	
EndFunction


Int Function IncrementActiveRegionsCount(int aiIncrement) ;Increment 0 to simply return the value. 

	iActiveRegionsCount += aiIncrement
	return iActiveRegionsCount
	;Functions calling this do not explicitly need to do anything with return value.
	
EndFunction


Function MasterFactoryReset()

	;Currently nothing here. May be reused in future. 
	
EndFunction


;------------------------------------------------------------------------------------------------
;DEBUG FUNCTIONS
;------------------------------------------------------------------------------------------------

;This function is used anytime User needs to be informed of active spawnpoint threads.
Bool Function ActiveThreadCheck()
	
	if iActiveThreadCount > 0
	;Notify the user that they need to wait for threads to finish before continuing with the function they were trying to invoke. 
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
