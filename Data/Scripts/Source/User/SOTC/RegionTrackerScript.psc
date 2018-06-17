Scriptname SOTC:RegionTrackerScript extends ObjectReference
{ Tracks Regional activity and cleans it up }

;Written by SMB92
;Special thanks to J. Ostrus [BigandFlabby] for code contributions that made this mod possible.

;Purpose of this script is to lessen the load on the Region script by offloading
;dynamic accumulating arrays of spent Spawnpoints to this script, as well as the
;code for resetting/cleaning up these points. Can handle 512 Points of any sort.

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

	Int Property iRegionResetTimerClock = 168 Auto
	{ Clock for Area Reset. Default value of 7 days (Game Time). Set by Menu. }
	
	;DEV NOTE: This script does nopt need to communicate with the ThreadController. SPs will do that.

EndGroup


Group Dynamic

	SOTC:RegionManagerScript Property RegionManager Auto
	{ Init None, filled at runtime. }
	
EndGroup


Group SpentPointArrays
{ 4 Dynamic arrays can store 512 Points per Region total. }
;DEV NOTE: These must be initialised with one member of None in case Papyrus trashes them before
;we can add anything later (as per bug notes at top of MasterScript). 

	SOTC:SpawnPointScript[] Property kSpentPoints1 Auto 
	{ Init one member of None. }
	SOTC:SpawnPointScript[] Property kSpentPoints2 Auto
	{ Init one member of None. }
	SOTC:SpawnPointScript[] Property kSpentPoints3 Auto
	{ Init one member of None. }
	SOTC:SpawnPointScript[] Property kSpentPoints4 Auto
	{ Init one member of None. }

EndGroup


Int iRegionResetTimerID = 4 Const
Bool bInit ;Security check to make sure Init events/functions don't fire again while running


;------------------------------------------------------------------------------------------------
;INITIALISATION FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

;DEV NOTE: Init events/functions now handled by Masters creating the instances.

Function PerformFirstTimeSetup(SOTC:RegionManagerScript aRegionManager, float afWaitClock)

	if !bInit
	
		RegionManager = aRegionManager
		Utility.Wait(afWaitClock) ;Staggers start of timers on Trackers, in attempt to prevent many
		;instances from trying to perform cleanup at the same time.
		BeginCleanupTimer()
		
		bInit = true
		
		Debug.Trace("Region Tracker Created")
		
	endif
	
EndFunction


;Force cleanup SpawnPoints and stop timers, in preparation for the destruction of this instance.
Function MasterFactoryReset()

	CancelTimerGameTime(iRegionResetTimerID)
	ResetSpentPoints()
	;RegionManager will destroy this instance once returned. 
	
EndFunction


;------------------------------------------------------------------------------------------------
;RUNTIME FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------


;Reset all active/spent Spawnpoints
Event OnTimerGameTime(int aiTimerID)

	if aiTimerID == iRegionResetTimerID
		ResetSpentPoints()
		BeginCleanupTimer()
	endif

EndEvent


;This will be called by RegionManager when its ready to begin running. Encapsulated to avoid Menu mode.
Function BeginCleanupTimer()

	StartTimerGameTime(iRegionResetTimerClock, iRegionResetTimerID)
	
EndFunction


;Add newly spent SP to arrays
Function AddSpentPoint(SOTC:SpawnPointScript akSpentPoint)

	if kSpentPoints1.Length < 128
		kSpentPoints1.Add(akSpentPoint)
		
	elseif kSpentPoints2.Length < 128
		kSpentPoints2.Add(akSpentPoint)
		
	elseif kSpentPoints3.Length < 128
		kSpentPoints3.Add(akSpentPoint)
		
	elseif kSpentPoints4.Length < 128
		kSpentPoints4.Add(akSpentPoint)
		
	else

	Debug.Trace("Cleanup Manager is overloaded for Region " + RegionManager.iRegionID + ", cannot add Point to arrays!")
	;With 512 points possible to be tracked per Region, this message should never get shown. 
		
	endif

EndFunction


;Cleanup and reset all SPs
Function ResetSpentPoints()

	if kSpentPoints1.Length >= 0
		ResetSpentPointsArrayLoop(kSpentPoints1)
		SafelyClearSpentPointsArray(kSpentPoints1)
	endif
	
	if kSpentPoints2.Length >= 0
		ResetSpentPointsArrayLoop(kSpentPoints2)
		SafelyClearSpentPointsArray(kSpentPoints2)
	endif
	
	if kSpentPoints3.Length >= 0
		ResetSpentPointsArrayLoop(kSpentPoints3)
		SafelyClearSpentPointsArray(kSpentPoints3)
	endif
	
	if kSpentPoints4.Length >= 0
		ResetSpentPointsArrayLoop(kSpentPoints4)
		SafelyClearSpentPointsArray(kSpentPoints4)
	endif

EndFunction


;Array looping function for above main function.
Function ResetSpentPointsArrayLoop(SOTC:SpawnPointScript[] akSpentPoints)
	
	int iCounter = 0
	
	if akSpentPoints[0] == None ;Security measure to avoid errors
		akSpentPoints.Remove(0)
	endif
	
	int iSize = akSpentPoints.Length - 1
	
	while iCounter < iSize ;Should end immediately if above caused size to hit 0/-1.
		
		akSpentPoints[iCounter].FactoryReset()	
		iCounter += 1

	endwhile
	
EndFunction


Function SafelyClearSpentPointsArray(SOTC:SpawnPointScript[] akSpentPoints)

	akSpentPoints.Clear()
	akSpentPoints = new SOTC:SpawnPointScript[1]
	
EndFunction


;------------------------------------------------------------------------------------------------
