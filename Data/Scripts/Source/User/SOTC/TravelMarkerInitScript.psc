Scriptname SOTC:TravelMarkerInitScript extends ObjectReference
{ Quick and drity script that adds a Travel Location Marker to Regions dynamically on first setup. }
;Written by SMB92
;Special thanks to J. Ostrus [BigandFlabby] for code contributions that made this mod possible.

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
	{ Fill with MasterQuest. }

	Int Property iWorldID Auto Const Mandatory
	{ ID of the World containing this Region. }

	Int Property iRegionID Auto Const Mandatory
	{ ID of the Region to add to. }

EndGroup

Bool bInit ;Security check to make sure Init events/functions don't fire again while running

;------------------------------------------------------------------------------------------------
;INIT FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------


;Add the Marker to the specified ID'ed RegionManager.
Event OnInit()

	if !bInit
		
		RegisterForCustomEvent(MasterScript, "InitTravelMarkers") 

	endif
	
EndEvent


Event SOTC:MasterQuestScript.InitTravelMarkers(SOTC:MasterQuestScript akSender, Var[] akArgs)

	if (akArgs as Bool) == True ;Initialise, add to RegionManager
	
		MasterScript.Worlds[iWorldID].Regions[iRegionID].kTravelLocs.Add(Self as ObjectReference, 1)
		Debug.Trace("Travel Marker Added to Region")
	
	else ;Assume false, shutdown stage, try to delete instances. Only use in absolute shutdown stage
	
		(Self as ObjectReference).Delete()
		Self.Delete()
		
	endif

EndEvent


;------------------------------------------------------------------------------------------------
