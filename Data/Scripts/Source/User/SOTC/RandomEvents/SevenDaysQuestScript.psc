Scriptname SOTC:RandomEvents:SevenDaysQuestScript extends Quest
{ Seven Days to Die Event Script }
;Written by SMB92.
;Special thanks to J. Ostrus [BigandFlabby] for making this mod possible.

;LEGEND - PREFIX CONVENTION
; Variables and Properties are treated the same. Script types do not have prefixes, unless they
;are explicitly received as function arguments and are multi-instance scripts.
; "a" - (Function/Event Blocks only) Variable was received as function argument OR the variable
;was created from a passed-in Struct/Var[] member
; "k" - Is an "Object" as usual, whether created in a Block or defined in the empty state/a state.
; "f,b,i,s" - The usual Primitives: Float, Bool, Int, String.

;DEV NOTE: This event is included in the core of the F4-SpawnEngine

;LEGEND - EVENTS FRAMEWORK (UPDATED FOR VERSION 0.14.01)
;In order for Random Events to be added on by third parties with ease, this system uses Quests to
;instantiate their controller script for the "Event" and the MasterScript simply calls a setstage
;on the Quest in order to send the script work events via OnStageSet. This eliminates the need to
;be reliant on using a template script or single object of any sort. 

;So to explain how it works behind the scenes, Events Quests will include a "Helper" object (a custom
;SpawnPoint) of which will be instanced at any compatible SpawnPoint (which is elected as the "Event
;Point" on the Master, this is any SOTC:SpawnPointScript with the "bEventSafe" flagged True). Event
;scripts may pass their "Helper" any number of parameters and then trigger them to start spawning via
;a timer on that Helper's script, thus starting it in its own thread. The default configuration for
;staging an Event quest is as follows:
; - Stage 1 is the "Startup" stage - this will run the Init code for the Event and will be set when the
;Event is either enabled for the first time, or reset. 
; - Stage 5 is the idle stage, nothing happens here. Simply waiting for a trigger to set the next stage
; - Stage 10 is the "work" stage, when triggered any spawn code should run here and the Event fire up.
; - Stage 100 is the Shutdown stage, the Event will pack up here. 
;Event Quests as of version 0.14.01 should be Start Game Enabled and never stopped (unless uninstalling).
;This allows settings to be reliably configured before enabling the Event. 

;There are currently 4 types of Events supported. They are as follows:
; 1. Bypass Events - These Events can be triggered at any time, based on a chance roll. They will
;"bypass" any Event locks in place. This is good for Events like Ghoul Apocalypse mode where we
;want that always random chance of the Event occurring.
; 2. Timed/Recurring Events - As you would assume, these Events recur according to a timer, which
;is set on the code for that Event.
; 3. Static Events - This type of Event has a chance to occur at any time, based on some conditions
;that can be setup for said Event specifically. This type of Event is subject to Event locks however.
; 4. Unique Events - This type of Event only fires once, and must be coded accordingly. These events
;should make use of the Timed events system so no extra functions need be developed. 

 
;------------------------------------------------------------------------------------------------
;PROPERTIES & IMPORTS
;------------------------------------------------------------------------------------------------

;THIS EVENT IS A TIMED EVENT. IT DOES NOT REQUIRE ADDING TO ANY EXTERNAL ARRAYS ONINIT TO BE TRACKED.

Group Primary


	SOTC:MasterQuestScript Property MasterScript Auto Const Mandatory
	{ Fill with MasterQuest. }
	
	Activator Property kEventHelper Auto Const Mandatory
	{ Fill with associated Object containing spawn code for this Event }
	
	GlobalVariable Property SOTC_Global_EventQuestStatus Auto Const
	{ Auto-fill. Used to tell Menu about this Quests init status. }
	
	GlobalVariable Property SOTC_Global01 Auto Const Mandatory
	{ Auto-fill. Used for settings Menu. }
	
	GlobalVariable Property SOTC_Global02 Auto Const Mandatory
	{ Auto-fill. Used for settings Menu. }
	
EndGroup


Group Settings

	;Bool Property bEventEnabled Auto
	;{ Init false. Set in Menu. }
	;Timed events do not require this.
	;Should use function on Master to find/remove from arrays, then Stop quest. 
	
	;DEV NOTE: This currently does not support increased BOSS spawns. 
	
	Int Property iSpawnsBeforeReset = 7 Auto
	{ Default value of 7. Change in Menu. Times the current enemy will spawn until reset. }

	Int Property iSpawnChanceBonus = 5 Auto
	{ Default value of 5%. Change in Menu. Will be multiplied by Event Counter. }

	Int Property iMaxCountBonus = 1 Auto
	{ Default value of 1. Change in Menu. Will be multiplied by Event Counter. }
	
	Float Property fEventTimerClock = 168.0 Auto
	{ Default value of 168.0 (7 days), customisable in Menu if desired. }

EndGroup

SOTC:ActorManagerScript CurrentEnemy ;The current Actor type.

Int iEventTimerID = 7 Const ;Timer for flagging event as ready

Int iEventCleanupTimerID = 10 Const ;Despawn timer for Random Events Framework SpawnPoints.

Int iEventCounter ;Times the Event has fired

Float fInit ;Used here to tell if we are active, as GetStage is not reliable for repeatable stage Quests.

Bool bPending ;Quick flag that this event is waiting in MasterScript queue

ObjectReference kActiveHelper ;Point to the current active helper so we can cleanup later. 


;------------------------------------------------------------------------------------------------
;INIT FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

;DEV NOTE: As of version 0.14.01, Event Quests are now Start Enabled and stages used to send work
;Events to this script. 

;DEV NOTE: Use MasterQuestScript function SafelyAppendEventQuestForStart() to start Event Quests in order to 
;avoid lockups in Menu Mode. Call from Menu passing this Quest as the parameter.
;Event OnQuestInit() 
	
	;Quest should be started after Pipboy exited or the Menu could hang.
	
	;if !bInit
	;	StartTimerGameTime(fEventTimerClock, iEventTimerID)
	;	RefreshEvent()
	;	bInit = true
	;endif
	
;EndEvent


Event OnTimerGameTime(Int aiTimerID)

	if aiTimerID == iEventCleanupTimerID
	
		(kActiveHelper as SevenDaysPointScript).EventHelperFactoryReset()
		kActiveHelper.Disable()
		kActiveHelper.Delete()
		kActiveHelper = None ;De-persist.

	elseif aiTimerID == iEventTimerID ;Pend the event.
	
		MasterScript.SafelyRegisterActiveEvent("Timed", Self as Quest)
		bPending = true
		
	endif
	
EndEvent


;Event that actually start the Event code
Event OnStageSet(Int auiStageID, int auiItemID)

	;Stage 1 is startup stage
	;Stage 5 is idle stage
	;Stage 10 is do work stage
	;Stage 100 is shutdown stage
	
	if auiStageID == 1 ;Startup/refresh
	
		StartTimerGameTime(fEventTimerClock, iEventTimerID)
		RefreshEvent()
		fInit = 1.0

	elseif auiStageID == 10 ;Begin event
	
		if !bPending ;If somehow we are still pending on Master, we'll start timer again and wait.
			BeginEvent()
		else
			StartTimerGameTime(fEventTimerClock, iEventTimerID)
		endif
		
	elseif auiStageID == 100 ;Shutdown
		
		if bPending == true ;Remove from MasterScript queue if Pending
			
			MasterScript.SafelyUnregisterActiveEvent("Timed", Self as Quest)

		endif
		
		iEventCounter = 0
		CancelTimerGameTime(iEventTimerID)
		fInit = 0.0
		
	endif
	
EndEvent


;Setup new Actor and reset counter
Function RefreshEvent()

	CurrentEnemy = MasterScript.SpawnTypeMasters[0].GetRandomActor()
	while CurrentEnemy.bIsFriendlyNeutralToPlayer ;We don't want a friendly Actor, so get a new one.
		CurrentEnemy = MasterScript.SpawnTypeMasters[0].GetRandomActor()
	endwhile
	
	iEventCounter = 0 ;Reset the Event Counter
	
	;DEV NOTE: Starting timers moved out of this block.
	
EndFunction


;------------------------------------------------------------------------------------------------
;MENU FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

;This function either sets Menu Globals to current values before viewing a Menu option, or it sets the new value selected from said Menu.
Function SetMenuVars(string asSetting, bool abSetValues = false, Int aiValue01 = 0)

	if asSetting == "InitStatus"
	
		SOTC_Global_EventQuestStatus.SetValue(fInit)

	elseif asSetting == "SpawnsBeforeReset"
		
		if abSetValues
			iSpawnsBeforeReset = aiValue01
		endif
		SOTC_Global01.SetValue(iSpawnsBeforeReset as Float)
		
	elseif asSetting == "SpawnChanceBonus"

		if abSetValues
			iSpawnChanceBonus = aiValue01
		endif
		SOTC_Global01.SetValue(iSpawnChanceBonus as Float)
		
	elseif asSetting == "MaxCountBonus"

		if abSetValues
			iMaxCountBonus = aiValue01
		endif
		SOTC_Global01.SetValue(iMaxCountBonus as Float)
		
	elseif asSetting == "EventClock"

		if abSetValues
			fEventTimerClock = aiValue01 as Float
		endif
		SOTC_Global01.SetValue(fEventTimerClock)
		
	endif
	
EndFunction
	
	
;------------------------------------------------------------------------------------------------
;SPAWN FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

Function BeginEvent()

	ObjectReference kPoint = MasterScript.kEventPoint

	kActiveHelper = kPoint.PlaceAtMe(kEventHelper, 1, false, false, false)
	;Trigger the Helper and pass in the parameters script directly. Always use "Common" Class.
	(kActiveHelper as SOTC:RandomEvents:SevenDaysPointScript).EventHelperBeginSpawn(CurrentEnemy.ClassPresets[1])
	iEventCounter += 1
	;Helper will reset and delete itself after some time.
	
	if iEventCounter >= iSpawnsBeforeReset ;Check if more than also just in case.
		(Self as Quest).SetStage(1) ;Reset/startup stage
	endif
	
	(Self as Quest).SetStage(5) ;idle stage
	StartTimerGameTime(24.0, iEventCleanupTimerID) ;24 hour cleanup cycle for Event spawns.
	StartTimerGameTime(fEventTimerClock, iEventTimerID)
	bPending = false
	
EndFunction	
	

Int Function GetMaxCountBonus() ;Gets the MaxCount bonus multiplied by Event counter

	return (iMaxCountBonus * iEventCounter)
	
EndFunction

Int Function GetSpawnChanceBonus() ;Gets the Chance bonus multiplied by Event counter

	return (iSpawnChanceBonus * iEventCounter)
	
EndFunction

	
;------------------------------------------------------------------------------------------------
