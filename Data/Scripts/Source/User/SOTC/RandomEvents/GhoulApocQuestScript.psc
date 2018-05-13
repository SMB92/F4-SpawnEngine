Scriptname SOTC:RandomEvents:GhoulApocQuestScript extends Quest
{ Ghoul Apocalypse Static Random Event Script }
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

;LEGEND - EVENTS FRAMEWORK
;In order for Random Events to be added on by third parties with ease, this system uses Quests to
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
; 4. Unique Events - This type of Event only fires once, and must be coded accordingly. These events
;should make use of the timed events system so no extra functions need be developed. 

;So to explain how it works behind the scenes, Events Quests must be started from a Menu (so their 
;Quest must NOT be start game enabled). Upon doing so the Event will be coded to either add itself
;to the MasterScript's arrays of Event Quests based on it's type, or in the case of Timed Events,
;begin their timers/event monitors and add themselves when the timer/event monitor triggers. When
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

;THIS IS A BYPASS EVENT. REQUIRES BEING ADDED TO MASTERSCRIPT RE_BYPASSEVENTS LIST ONINIT. BYPASS
;EVENTS ARE STATIC EVENTS THAT CAN FIRE REGARDLESS OF ANY LOCKS IN PLACE TO PREVENT THEM NORMALLY.

Group PrimaryProperties
{ Primary Properties Group }

	SOTC:MasterQuestScript Property MasterScript Auto Const
	{ Fill with MasterQuest }
	
	Activator Property kEventHelper Auto Const
	{ Fill with associated Object containing spawn code for this Event }
	
	;Holotape Property kSettingMenuTape Auto Const
	;{ Fill with settings tape if this is an external/third party addon }
	;DEV NOTE: This should really be included on an auxillery controlelr provided by the addon.
	
EndGroup


Group Settings

	Bool Property bEventEnabled Auto
	{ Init false. Set in Menu. }
	
EndGroup

Bool bInit ;Security measure to ensure OnInit events don't fire again and again.


;------------------------------------------------------------------------------------------------
;INIT FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

;DEV NOTE: Use MasterQuestScript function to start Event Quests in order to avoid lockups in Menu Mode. 

Event OnQuestInit() 
	
	if !bInit
		MasterScript.kRE_BypassEvents.Add(Self as Quest, 1)
	endif
	
	;Won't receive while in Menu mode, but will continue when exited. 
	
EndEvent


Event OnStageSet(Int auiStageID, int auiItemID)

	;Stage 1 is idle/startup stage

	if auiStageID == 10 
		
		BeginEvent()
	
	elseif auiStageID == 100 ;Shutdown
	
		Int i = MasterScript.kRE_BypassEvents.Find(Self as Quest)
		MasterScript.kRE_BypassEvents.Remove(i) ;Remove ourselves from Master list
		(Self as Quest).Stop() ;Shut it down!
		
	endif
	
EndEvent


;------------------------------------------------------------------------------------------------
;SPAWN FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

Function BeginEvent()

	ObjectReference kPoint = MasterScript.kEventPoint
	ObjectReference kHelper = kPoint.PlaceAtMe(kEventHelper, 1, false, false, false)
	(kHelper as SOTC:RandomEvents:GhoulApocPointScript).BeginSpawn()
	;Helper will reset and delete itself after some time.
	(Self as Quest).SetStage(1) ;Reset stage

EndFunction
	

;------------------------------------------------------------------------------------------------
