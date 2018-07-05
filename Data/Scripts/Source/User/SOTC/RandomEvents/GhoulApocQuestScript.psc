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

;THIS IS A BYPASS EVENT. REQUIRES BEING ADDED TO MASTERSCRIPT RE_BYPASSEVENTS LIST ONINIT. BYPASS
;EVENTS ARE STATIC EVENTS THAT CAN FIRE REGARDLESS OF ANY LOCKS IN PLACE TO PREVENT THEM NORMALLY.

Group PrimaryProperties
{ Primary Properties Group }

	SOTC:MasterQuestScript Property MasterScript Auto Const Mandatory
	{ Fill with MasterQuest }
	
	Activator Property kEventHelper Auto Const Mandatory
	{ Fill with associated Object containing spawn code for this Event }
	
	GlobalVariable Property SOTC_Global_EventQuestStatus Auto Const
	{ Auto-fill. Used to tell Menu about this Quests init status. }
	
EndGroup


Float fInit ;Used here to tell if we are active, as GetStage is not reliable for repeatable stage Quests.


;------------------------------------------------------------------------------------------------
;INIT FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

;DEV NOTE: As of version 0.14.01, Event Quests are now Start Enabled and stages used to send work
;Events to this script. 


;DEV NOTE: Use MasterQuestScript function to start Event Quests in order to avoid lockups in Menu Mode. 
;Event OnQuestInit() 
	
	;if !bInit
	;	MasterScript.SafelyRegisterActiveEvent("Bypass", Self as Quest)
	;	MasterScript.SafelyRegisterActiveEvent("Bypass", Self as Quest)
	;	;This event is pended twice as it has a higher chance to occur than others.
	;endif
	
	;Won't receive while in Menu mode, but will continue when exited. 
	
;EndEvent


Event OnStageSet(Int auiStageID, int auiItemID)

	;Stage 1 is startup stage
	;Stage 5 is idle stage
	;Stage 10 is do work stage
	;Stage 100 is shutdown stage
	
	if auiStageID == 1
	
		MasterScript.SafelyRegisterActiveEvent("Bypass", Self as Quest)
		MasterScript.SafelyRegisterActiveEvent("Bypass", Self as Quest)
		;This event is pended twice as it has a higher chance to occur than others.
		fInit = 1.0
	
	elseif auiStageID == 10 
		
		BeginEvent()
	
	elseif auiStageID == 100 ;Shutdown
	
		if fInit == 1.0 ;Ensure we we're active. Startup stage is also 100. 
	
			MasterScript.SafelyUnregisterActiveEvent("Bypass", Self as Quest)
			MasterScript.SafelyUnregisterActiveEvent("Bypass", Self as Quest) 
			;This event is pended twice as it has a higher chance to occur than others.
			fInit = 0.0
		
		endif
		
	endif
	
EndEvent

;------------------------------------------------------------------------------------------------
;MENU FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

Function SetMenuVars(string asSetting, bool abSetValues = false, Int aiValue01 = 0)

	if asSetting == "InitStatus"
	
		SOTC_Global_EventQuestStatus.SetValue(fInit)
		
	endif
	
EndFunction


;------------------------------------------------------------------------------------------------
;SPAWN FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

Function BeginEvent()

	ObjectReference kPoint = MasterScript.kEventPoint
	ObjectReference kHelper = kPoint.PlaceAtMe(kEventHelper, 1, false, false, false)
	Int iRegionID = (kPoint as SOTC:SpawnPointScript).iRegionID ;Helper will require Region data. 
	(kHelper as SOTC:RandomEvents:GhoulApocPointScript).EventHelperBeginSpawn(iRegionID) ;Helper will set links to Region itself.
	;Helper will reset and delete itself after some time.
	(Self as Quest).SetStage(1) ;Reset stage, wait for next request. 

EndFunction
	

;------------------------------------------------------------------------------------------------
