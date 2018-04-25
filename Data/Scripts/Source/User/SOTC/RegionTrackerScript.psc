Scriptname SOTC:RegionTrackerScript extends ReferenceAlias
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
; "f,b,i" - The usual Primitives: Float, Bool, Int.

;------------------------------------------------------------------------------------------------
;PROPERTIES & IMPORTS
;------------------------------------------------------------------------------------------------

Group PrimaryProperties

	SOTC:RegionQuestScript Property RegionScript Auto Const
	{ Fill with attached Quest. Direct Link to RegionScript }

	Int Property iRegionResetTimerClock Auto
	{ Initialise 0. Clock for Area Reset. Set by Menu }

EndGroup


Int iRegionResetTimerID = 4 Const ;Does not need to be a Property


Group PointKeywords
{Auto-fill}

	Keyword Property SOTC_SpGroupKeyword Auto Const
	Keyword Property SOTC_SpMiniKeyword Auto Const
	Keyword Property SOTC_SpPatrolKeyword Auto Const
	Keyword Property SOTC_SpAmbushKeyword Auto Const
	
EndGroup

ObjectReference[] kSpentPoints1
ObjectReference[] kSpentPoints2
ObjectReference[] kSpentPoints3
ObjectReference[] kSpentPoints4

Bool bInit

;------------------------------------------------------------------------------------------------
;INITIALISATION & SETTINGS EVENTS
;------------------------------------------------------------------------------------------------

;Set ourself up on the RegionScript
Event OnAliasInit()
	
	if !bInit
		
		;Init the dynamic arrays
		kSpentPoints1 = new ObjectReference[0]
		kSpentPoints2 = new ObjectReference[0]
		kSpentPoints3 = new ObjectReference[0]
		kSpentPoints4 = new ObjectReference[0]
		
		RegionScript.CleanupManager = Self
		Utility.Wait(0.5) ;Wait 1/2 a second so RegionQuestScript should finish initialising
		
		;Now stagger the startup of the Cleanup timer, so all Regions cleanup timers have a much better
		;chance of firing at different times. All at once may cause lag.
		Utility.Wait((RegionScript.GetTrackerWaitClock()))
		
		BeginCleanupTimer()
		bInit = true
		
	endif
	
EndEvent


;Reset all active/spent Spawnpoints
Event OnTimerGameTime(int aiTimerID)

	if aiTimerID == iRegionResetTimerID
		ResetSpentPoints()
		BeginCleanupTimer()
	endif

EndEvent


;This will be called by RegionScript when its ready to begin running. Encapsulated to avoid Menu mode.
Function BeginCleanupTimer()

	StartTimerGameTime(iRegionResetTimerClock, iRegionResetTimerID)
	
EndFunction


;Add newly spent SP to arrays
Function AddSpentPoint(ObjectReference akSpentPoint)

	if kSpentPoints1.Length < 128
		kSpentPoints1.Add(akSpentPoint)
		
	elseif kSpentPoints2.Length < 128
		kSpentPoints2.Add(akSpentPoint)
		
	elseif kSpentPoints3.Length < 128
		kSpentPoints3.Add(akSpentPoint)
		
	elseif kSpentPoints4.Length < 128
		kSpentPoints4.Add(akSpentPoint)
		
	else
		Debug.MessageBox("Cleanup Manager is overloaded for Region " +RegionScript.iRegionID+", cannot add Point to arrays!")
	endif

EndFunction


;Cleanup and reset all SPs
Function ResetSpentPoints()

	if kSpentPoints1.Length >= 0
		ResetSpentPointsArrayLoop(kSpentPoints1)
	endif
	
	if kSpentPoints2.Length >= 0
		ResetSpentPointsArrayLoop(kSpentPoints2)
	endif
	
	if kSpentPoints3.Length >= 0
		ResetSpentPointsArrayLoop(kSpentPoints3)
	endif
	
	if kSpentPoints4.Length >= 0
		ResetSpentPointsArrayLoop(kSpentPoints4)
	endif

EndFunction

;Array looping function for above main function. Saves code
Function ResetSpentPointsArrayLoop(ObjectReference[] akSpentPoints)
	
	int iSize = akSpentPoints.Length
	int iCounter = 0
	
	while iCounter < iSize
	
		if akSpentPoints[iCounter].HasKeyword(SOTC_SpGroupKeyword)
			(akSpentPoints[iCounter] as SOTC:SpGroupScript).FactoryReset()
			
		;elseif akSpentPoints[iCounter].HasKeyword(SOTC_SpMiniKeyword)
			;(akSpentPoints[iCounter] as SOTC:SpMiniScript).FactoryReset()
			
		;elseif akSpentPoints[iCounter].HasKeyword(SOTC_PatrolPoint)
			;(akSpentPoints[iCounter] as SOTC:SpPatrolScript).FactoryReset()
			
		;elseif kSpentPoints[iCounter].HasKeyword(SOTC_AmbushPoint)
			;(akSpentPoints[iCounter] as SOTC:SpAmbushScript).FactoryReset()

		endif

	endwhile
	
EndFunction

;------------------------------------------------------------------------------------------------
