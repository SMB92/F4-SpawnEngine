Scriptname SOTC:RandomEvents:RR_ControllerQuestScript extends Quest
{Controller Script}
;Written by SMB92
;Designed by request of Keith [KKTheBeast]
;Special Thanks to Dylan [Cancerous1] for example code

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

Actor Property PlayerRef Auto
{ Yours truly, if needed }

Static Property SOTC_RR_DistanceTracker Auto Const
{ Object that follows the player around and executes refresh of spawn aliases. }

Quest Property SOTC_RandomRoachesDynamicQuest Auto Const
{ The other Quest containing dynamic aliases. }

ObjectReference akWorkshop

ObjectReference akDistanceTracker
;The actual instance of create tracker

Float fInit ;Used here to tell if we are active, as GetStage is not reliable for repeatable stage Quests.

;------------------------------------------------------------------------------------------------
;FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

;DEV NOTE: As of version 0.14.01, Event Quests are now Start Enabled and stages used to send work
;Events to this script. 

;Event OnQuestInit()
	
	;if !bInit
		;akDistanceTracker = PlayerRef.PlaceAtMe(akDistanceTracker, 1, true, false, false) ;Create the tracker object
		;RegisterForDistanceGreaterThanEvent(PlayerRef, akDistanceTracker, 4096) ;Full cell size @4096
		;bInit = true
	;endif
	
;EndEvent

Event OnStageSet(int auiStageID, Int auiItemID)
	
	;This Event does not use Stage 1 or 5, it is either on or off)
	
	if auiStageID == 10 ;Work
	
		akDistanceTracker = PlayerRef.PlaceAtMe(akDistanceTracker, 1, true, false, false) ;Create the tracker object
		RegisterForDistanceGreaterThanEvent(PlayerRef, akDistanceTracker, 4096) ;Full cell size @4096
		fInit = 1.0
		
	elseif auiStageID == 100
		
		akDistanceTracker.Disable()
		akDistanceTracker.Delete()
		
		if akWorkshop != None ;Must be WS detected
			UnregisterForDistanceEvents(PlayerRef, akWorkshop)
		endif
		SOTC_RandomRoachesDynamicQuest.Stop()
		fInit = 0.0
		
	endif
		
		
EndEvent


Event OnDistanceGreaterThan(ObjectReference akObj1, ObjectReference akObj2, float afDistance)

	if akObj2 == akDistanceTracker

		akDistanceTracker.MoveTo(PlayerRef)
		SOTC_RandomRoachesDynamicQuest.Stop()
		SOTC_RandomRoachesDynamicQuest.Start()
		
	else ;Assume Workshop
		
		SOTC_RandomRoachesDynamicQuest.Start()
		UnregisterForDistanceEvents(PlayerRef, akWorkshop)
		;NOTE - We may have to re-register the other event, this may unregister the player entirely
		;RegisterForDistanceGreaterThanEvent(Player, akDistanceTracker, 2048) ;About half a cell @2048
		akWorkshop = None
		
	endif
	
EndEvent


Function WorkshopDetected(ObjectReference akNearbyWorkshop)
	
	akWorkshop = akNearbyWorkshop
	SOTC_RandomRoachesDynamicQuest.Stop()
	RegisterForDistanceGreaterThanEvent(PlayerRef, akWorkshop, 10000) ;Until really out of settlement
	
EndFunction


;------------------------------------------------------------------------------------------------
