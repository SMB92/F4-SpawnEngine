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
; "f,b,i" - The usual Primitives: Float, Bool, Int.

;DEV NOTE: This event is included in the core of the F4-SpawnEngine

;LEGEND - EVENTS FRAMEWORK
;In order for Random Events to be added on by third parties at ease, this system uses Quests to
;instantiate their controller script for the "Event" and the MasterScript simply calls a setstage
;on the Quest in order to activate it (standard stage ID is 10). This eliminates the need to be
;reliant on using a template script or single object of any sort. Controller scripts may include
;a "helper" object which can be used to place in the world to do spawning work for the Event.

;There are currently 4 types of Events supported. They are as follows:
; 1. Bypass Events - These Events can be triggered at any time, based on a chance roll. They will
;"bypass" any Event locks in place. This is good for Events like Ghoul Apocalypse mode where we
;want that always random chance of the Event occurring.
; 2. Timed/Recurring Events - As you would assume, these Events recur according to a timer, which
;is set on the code for that Event.
; 3. Static Events - This type of Event has a chance to occur at any time, based on some conditions
;that can be setup for said Event specifically. This type of Event is subject to Event locks however.
; 4. Unique Events - This type of Event only fires once, and must be coded accordingly.

;So to explain how it works behind the scenes. Events Quests must be started from a Menu (so their 
;Quest must NOT be start game enabled). Upon doing so the Event will be coded to either add itself
;to the MasterScript's arrays of Event Quests based on it's type, or in the case of Timed Events,
;begin their timers and add themselves to the pending Events array when the timer runs out. When
;a SpawnPoint fires (currently RE system ONLY supports the Main SpawnPoint type, SpGroupPoint), the
;MasterScript will check for Events in the same order as listed above. Whenever an Event fires the
;MasterScript will store the SpawnPoint and it will become the Point of the Event. The SP script
;is not used itself, it is purely a location reference. With the exception of bypass events, after
;an Event has fired a "cooldown" timer will be started and a "lock" engaged so that no more Events
;can fire until the cooldown is over. Unique Events will be removed permanently and an accompanying
;GlobalVar will be set to prevent them from starting again (at least without forcing it).
;When Events are toggled off from the Menu, their Quest will be shutdown and their entry(s) removed
;from the Master arrays. Any Events that make use of Helper Points to do spawn work must be coded
;to clean themselves up after a set amount of time.


;------------------------------------------------------------------------------------------------
;PROPERTIES & IMPORTS
;------------------------------------------------------------------------------------------------

;THIS EVENT IS A TIMED EVENT. IT DOES NOT REQUIRE ADDING TO ANY EXTERNAL ARRAYS ONINIT TO BE TRACKED.

Group PrimaryProperties
{Primary Properties Group}

	SOTC:MasterQuestScript Property MasterScript Auto Const
	{Fill with MasterQuest}

	SOTC:ThreadControllerScript Property ThreadController Auto Const
	{ Link to thread delegator, stored on RefAlias on this Quest }
	
	Activator Property kEventHelper Auto Const
	{ Fill with associated Object containing spawn code for this Event }
	
	;Holotape Property kSettingMenuTape Auto Const
	;{ Fill with settings tape if this is an external/third party addon }
	
EndGroup


Group Settings

	;Bool Property bEventEnabled Auto
	;{ Init false. Set in Menu. }
	;Timed events do not require this.
	
	Int Property iSpawnsBeforeReset Auto
	{ Int 0. Set in Menu. Times the current enemy will spawn until reset. }

	Int Property iSpawnChanceBonus Auto
	{ Initialise with balanced value. Will be multiplied by Event Counter. }

	Int Property iMaxCountBonus Auto
	{ Initialise with balanced value. Will be multiplied by Event Counter. }
	
	Int Property iEventTimerClock Auto
	{ Initialise 7 Days, but customisable if desired. }
	
EndGroup

SOTC:ActorQuestScript CurrentEnemy ;The current Actor type.

Int iEventTimerID = 7 Const ;Timer for flagging event as ready

Int iEventCounter ;Times the Event has fired

Bool bInit ;Security measure to ensure OnInit events don't fire again and again.

Bool bPending ;Quick flag that this event is waiting in MasterScript queue


;------------------------------------------------------------------------------------------------
;INIT FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

;NOTE: Event Quests are started from their Menus.

Event OnQuestInit() 

	;Because this event is started from Menu, need to start outside of Menu Mode
	RegisterForMenuOpenCloseEvent("PipboyMenu")

EndEvent

;Start the Event timer outside of Menu Mode
Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
	
	if (asMenuName == "PipboyMenu") && (!abOpening) ; On Pip-Boy closing
	
		StartTimerGameTime(iEventTimerClock, iEventTimerID)
		RefreshEvent()
		
	endif

	UnregisterForAllMenuOpenCloseEvents()

EndEvent


Event OnTimerGameTime(Int aiTimerID)

	if aiTimerID == iEventTimerID
	
		MasterScript.kRE_TimedEvents.Add(Self as Quest, 1)
		bPending = true
		
	endif
	
EndEvent


;Event that actually start the Event code
Event OnStageSet(Int auiStageID, int auiItemID)

	;Stage 1 is idle/startup stage

	if auiStageID == 10
	
		if !bPending ;If somehow we are still Pending on Master, we'll start timer again and wait again.
			BeginEvent()
		else
			StartTimerGameTime(iEventTimerClock, iEventTimerID)
		endif
		
	elseif auiStageID == 100 ;Shutdown
		
		if bPending == true ;Remove from MasterScript queue if Pending
		
			Int i = MasterScript.kRE_TimedEvents.Find(Self as Quest) 
			MasterScript.kRE_TimedEvents.Remove(i) ;Remove ourselves from Master list
		
		endif
		
		CancelTimerGameTime(iEventTimerID)
		(Self as Quest).Stop() ;Shut it down!
		
	endif
	
EndEvent


;Setup new Actor and reset counter
Function RefreshEvent()

	CurrentEnemy = MasterScript.SpawnTypeMasters[0].GetRandomActor()
	while CurrentEnemy.bIsFriendlyNeutralToPlayer ;We don't want a friendly Actor, so get a new one
		CurrentEnemy = MasterScript.SpawnTypeMasters[0].GetRandomActor()
	endwhile
	
	iEventCounter = 0 ;Reset the Event Counter
	
EndFunction


;------------------------------------------------------------------------------------------------
;SPAWN FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

Function BeginEvent()

	ObjectReference kPoint = MasterScript.kEventPoint
	
	if (kPoint as SOTC:SpGroupScript).bIsInteriorPoint || \
	(CurrentEnemy.bIsOversizedActor) && (kPoint as SOTC:SpGroupScript).bIsConfinedSpace
	;Do not proceed if Point is in Interior cell or the Actor is Oversized and Location is marked as confined space.
		MasterScript.kRE_TimedEvents.Insert(Self, 0) ;Add self back to queue.
		(Self as Quest).SetStage(1) ;Reset stage
		return ;Better luck next time.
	endif
	;else proceed as normal

	ObjectReference kHelper = kPoint.PlaceAtMe(kEventHelper, 1, false, false, false)
	;Trigger the Helper and pass in the parameters script directly. Always use "Common" Class
	(kHelper as SOTC:RandomEvents:SevenDaysPointScript).BeginSpawn(CurrentEnemy.ClassPresets[1])
	iEventCounter += 1
	;Helper will reset and delete itself after some time.
	
	if iEventCounter >= iSpawnsBeforeReset ;Check if more than also just in case
		RefreshEvent()
	endif
	(Self as Quest).SetStage(1) ;Reset stage
	StartTimerGameTime(iEventTimerClock, iEventTimerID)
	bPending = false
	
EndFunction	
	

Int Function GetMaxCountBonus() ;Gets the MaxCount bonus multiplied by Event counter

	return iMaxCountBonus * iEventCounter
	
EndFunction

Int Function GetSpawnChanceBonus() ;Gets the Chance bonus multiplied by Event counter

	return iSpawnChanceBonus * iEventCounter
	
EndFunction

	
;------------------------------------------------------------------------------------------------