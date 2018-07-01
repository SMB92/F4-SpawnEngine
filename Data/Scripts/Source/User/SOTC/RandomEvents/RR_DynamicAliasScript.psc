Scriptname SOTC:RandomEvents:RR_DynamicAliasScript extends ReferenceAlias
{ Dynamic Alias delegate. Can assume role of Workshop checker or Spawner. }
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

SOTC:RandomEvents:RR_ControllerQuestScript Property Controller Auto Const
{ Link to Controller Quest, really only needed for Workshop checker Alias, else Init None. }

Bool Property bIsWorkshopChecker Auto Const
{ Only initialise as True on the alias looking for Workshops. }

ActorBase Property LvlRadroach Auto Const
{ Fill on Spawn alias only, or Init with None. }

ReferenceAlias Property kRushPackage Auto Const
{ Fill with the Rush Package from SOTC_MasterQuest. Roaches will rush the Player when spawned. }

;Int Property iSpawnChance Auto
;If we wanted to add a further chance variable to the spawns

;------------------------------------------------------------------------------------------------
;FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

Event OnAliasInit()

	Utility.Wait(1) ;Wait 1 second to see if we fill

	if bIsWorkshopChecker
	
		if Self.GetRef() != None
			RegisterForDistanceLessThanEvent(Game.GetPlayer(), Self.GetRef(), 4096) ;Full Cell away @ 4096
		endif
		
	else ;Can only assume we are a spawn alias
		
		if Self.GetRef() != None
			RegisterForDistanceLessThanEvent(Game.GetPlayer(), Self.GetRef(), 256) ;Short distance for Ambush
		endif
		
	endif

EndEvent


Event OnDistanceLessThan(ObjectReference akObj1, ObjectReference akObj2, float afDistance)

	if !bIsWorkshopChecker ;Ensures this instance isn't the workshop checker. 
		
		Actor kPlayerRef = Controller.PlayerRef ;Possibly faster than Game.GetPlayer()
		;Do Line-of-sight check against Player
		while kPlayerRef.HasDetectionLOS(Self.GetRef())
			Utility.Wait(0.5)
			;Just keep waiting until out of sight. 0.5 value should be fair. 
		endwhile
	
		;Dice roll if we want
		;if Utility.RandomInt(1,100) <= iSpawnChance
		
		Actor kRoach = akObj2.PlaceActorAtMe(LvlRadroach)
		;if the above doesn't work, change akObj2 to Self.GetRef()
		;endif
		
		;Now apply the Rush package and evaluate
		kRushPackage.ApplyToRef(kRoach)
		kRoach.Evaluatepackage()
		
		;Done
		
	else ;Assume Workshop detected
	
		Controller.WorkshopDetected(akObj2)
		
	endif
	
EndEvent


;DEV NOTE: Cleanup is not required from this script as Actors are never made persistent. 

;------------------------------------------------------------------------------------------------
