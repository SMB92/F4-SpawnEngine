Scriptname SOTC:RR_ControllerQuestScript extends Quest
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

Bool bInit ;Security check to make sure Init events don't fire again while running

;------------------------------------------------------------------------------------------------
;FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

Event OnQuestInit()
	
	if !bInit
		akDistanceTracker = PlayerRef.PlaceAtMe(akDistanceTracker) ;Create the tracker object
		RegisterForDistanceGreaterThanEvent(PlayerRef, akDistanceTracker, 2048) ;About half a cell @2048
		bInit = true
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

Function Uninstall()

	akDistanceTracker.DeleteWhenAble()
	SOTC_RandomRoachesDynamicQuest.Stop()
	(Self as Quest).Stop()
	
EndFunction

;------------------------------------------------------------------------------------------------
