Scriptname SOTC:RR_DynamicAliasScript extends ReferenceAlias
{Dynamic Alias delegate. Can assume role of Workshop checker or Spawner}
;Written by SMB92
;Designed by request of Keith [KKTheBeast]
;Special Thanks to Dylan [Cancerous1] for example code

;------------------------------------------------------------------------------------------------
;PROPERTIES & IMPORTS
;------------------------------------------------------------------------------------------------

SOTC:RR_ControllerQuestScript Property Controller Auto Const
{Link to Controller Quest, really only needed for Workshop checker Alias, else Init None}

Bool Property bIsWorkshopChecker Auto Const
{Only initialise as True on the alias looking for Workshops}

ActorBase Property LvlRadroachAmbush Auto Const
{Fill on Spawn alias only, or Init with None}

;Int Property iSpawnChance Auto
;If you wanted to add a further chance variable to the spawns

;------------------------------------------------------------------------------------------------
;FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

Event OnAliasInit()

	Utility.Wait(1) ;Wait 1 second to see if we fill

	if bIsWorkshopChecker
	
		if Self.GetRef()
			RegisterForDistanceLessThanEvent(Game.GetPlayer(), Self.GetRef(), 4096) ;Full Cell away @ 4096
		endif
		
	else ;Can only assume we are a spawn alias
	
		RegisterForDistanceLessThanEvent(Game.GetPlayer(), Self.GetRef(), 256) ;Short distance for Ambush
		
	endif

EndEvent


Event OnDistanceLessThan(ObjectReference akObj1, ObjectReference akObj2, float afDistance)

	if !bIsWorkshopChecker
	
		;Dice roll if we want
		;if Utility.RandomInt(1,100) <= iSpawnChance
		akObj2.PlaceActorAtMe(LvlRadroachAmbush)
		;if the above doesn't work, cahnge akObj2 to Self.GetRef()
		;endif
		
	else ;Assume Workshop detected
	
		Controller.WorkshopDetected(akObj2)
		
	endif
	
EndEvent

;------------------------------------------------------------------------------------------------
