Scriptname SOTC:RandomEvents:GhoulApocPointScript extends ObjectReference
{ Ghoul Apocalypse Helper SpawnPoint script }
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

import SOTC:Struct_ClassDetails

SOTC:RandomEvents:GhoulApocQuestScript Property Controller Auto Const
{ Fill with the Controller Quest for this Event. }

SOTC:MasterQuestScript Property MasterScript Auto Const
{ Fill with MasterQuest. }

ReferenceAlias[] Property kPackages Auto Const
{ Fill one member with a basic Sandbox package, the other a basic Travel Package (single loc).
One of these will be selected and applied to the whole group. }

Keyword Property SOTC_PackageKeyword01 Auto Const
{ Auto-fill. Default keyword used with Single Location Package. }

;Int iGhoulActorID = 10 Const ; This is the ID of Ghouls on the MasterList. 

Actor[] kGroupList ; The group of Spawned Actors
Int iSelectedPackage ;Set to the chosen Package index, for cleaning up later. 

Int iHelperFireTimerID = 3 Const
Int iEventCleanupTimerID = 10 Const ;Despawn timer for Random Events Framework SpawnPoints.
Int iLosCounter ;This will be incremented whenever a Line of sight check to Player fails. If reaches 25, spawning aborts. As we at least spawn 1 actor
;to start with, this remains safe to use (however Player may see that one actor being spawned. its just easier to live with). 

SOTC:ThreadControllerScript ThreadController ;Fills at runtime
SOTC:ActorClassPresetScript ActorParamsScript
SOTC:ActorManagerScript ActorManager ;Fills at runtime
SOTC:RegionManagerScript RegionManager ;Fills at runtime. 


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;PRE-SPAWN FUNCTION & EVENTS - GHOUL APOC
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;Function called by Controller to start the Event Spawn.
Function EventHelperBeginSpawn(Int aiRegionID) ;This script needs Region data. 

	;SetSpScriptLinks and data
	ThreadController = MasterScript.ThreadController
	ActorManager = MasterScript.SpawnTypeMasters[0].ActorList[10] ;10 is main Ghoul ID in SpawnEngine
	RegionManager = MasterScript.Worlds.Regions[aiRegionID] ;This script requires Region data. 
	
	StartTimer(0.2, iHelperFireTimerID) ;Ready to start own thread
	
EndFunction


Event OnTimer(int aiTimerID)

	if aiTimerID == iHelperFireTimerID
		
		ThreadController.ForceAddThreads(1) 
		EventHelperPrepareSingleGroupSpawn()
		ThreadController.ReleaseThreads(1) ;Spawning done, threads can be released.
		
	elseif aiTimerID == iEventCleanupTimerID ;This script has to clean itself up.
	
		EventHelperFactoryReset()
		
	endif
	
EndEvent


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;CLEANUP FUNCTIONS & EVENTS - EVENT HELPER SCRIPT - GHOUL APOC
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;The owning SpawnPoint will delete this isntance when the following has returned. 

Function EventHelperFactoryReset()

	EventHelperCleanupActorRefs()
	
	ActorParamsScript = None
	ActorManager = None
	RegionManager = None
	
	ThreadController.IncrementActiveSpCount(-1)
	ThreadController = None
	
	(Self as ObjectReference).Disable()
	(Self as ObjectReference).Delete()

EndFunction


;Cleans up all Actors in GroupList
Function EventHelperCleanupActorRefs() 

	int iCounter = 0
	int iSize = kGroupList.Length
        
	while iCounter < iSize

		kPackages[iSelectedPackage].RemoveFromRef(kGroupList[iCounter]) ;Remove package data. Perhaps not necessary either?
		;NOTE: Removed code that removes linked refs. Unnecesary.
		kGroupList[iCounter].Delete()
		iCounter += 1
	
	endwhile
	
	kGroupList.Clear()
	ThreadController.IncrementActiveNpcCount(-iSize)
	
EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;SPAWN FUNCTION & EVENTS - GHOUL APOC
;-------------------------------------------------------------------------------------------------------------------------------------------------------


Function EventHelperPrepareSingleGroupSpawn()
	
	;Get Actor params based on random rairty based Class and Region Preset.
	
	Int iRarity = Utility.RandomInt(1,3) ;Randomise rarity based ClassPreset Int. 
	Int iPreset = RegionManager.iCurrentPreset
	ActorParamsScript = ActorManager.ClassPresets[iRarity]
	ClassDetailsStruct ActorParams = ActorParamsScript.ClassDetails[RegionManager.iCurrentPreset]
	
	
	;Organise the ActorBase arrays/Get GroupLoadout.
	;------------------------------------------------
	
	SOTC:ActorGroupLoadoutScript GroupLoadout = ActorParamsScript.GetRandomGroupScript()
	
	ActorBase[] kRegularUnits = (GroupLoadout.kGroupUnits) as ActorBase[] ;Cast to copy locally
	ActorBase[] kBossUnits
	Bool bBossAllowed ;Later used as parameter.
	if (ActorParams.iChanceBoss as Bool) && (GroupLoadout.kBossGroupUnits[0] != None) ;Check if Boss allowed and there is actually Boss on this GL.
		kBossUnits = (GroupLoadout.kBossGroupUnits) as ActorBase[] ;Cast to copy locally
	endif
	
	
	;Set difficulty level from Region.
	Int iDifficulty = RegionManager.iCurrentDifficulty
	
	
	;Check and setup EncounterZone data
	;-----------------------------------
	
	EncounterZone kEz ;iEZMode 1 - Single EZ to use for Group Levels
	EncounterZone[] kEzList; If iEzApplyMode = 2, this will point to a Region list of EZs. One will be applied to each Actor at random.
	
	Int iEzMode = RegionManager.iEzApplyMode ;Store locally for reuse and speed.
	
	if iEzMode == 0 ;This exist so we can skip it, seems it is more likely players won't use it.
		;Do nothing, use NONE EZ (passed parameters will be None)
	elseif iEZMode == 1
		kEz = RegionManager.GetRandomEz()
	elseif iEzMode == 2
		kEzList = RegionManager.GetRegionCurrentEzList() ;Look directly at the Regions Ez list, based on current mode
	endif
	
	
	;Check for Swarm Event for Ghouls.
	;---------------------------------
	
	Bool bApplySwarmBonus
	if RegionManager.RollForSwarm()
		bApplySwarmBonus = true
	endif
	
	
	;Elect the Package (Sandbox or Travel)
	iSelectedPackage = Utility.RandomInt(0,1)
	
	ObjectReference kTravelLoc ;If Travelling (Selected Package 1)
	if iSelectedPackage == 1
		kTravelLoc = RegionManager.GetRandomTravelLoc()
	endif
	
	
	;Begin spawning.
	;---------------
	
	Int iRegularActorCount ;Required for loot system
	Int iCounter
	Int iSize
	
	if iSelectedPackage == 0 ;Sandbox Mode, apply Package during loop. 
	
		if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely

			EventHelperSpawnActorSingleLocLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
			kRegularUnits, kEz, bApplySwarmBonus, false, iDifficulty)
		
			iRegularActorCount = (kGroupList.Length) ;Required for loot system
					
			if bBossAllowed && iLosCounter != 25 ;Check again if Boss spawns allowed for this Actors preset and LoS counter hasn't maxed.
				EventHelperSpawnActorSingleLocLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
				kBossUnits, kEz, bApplySwarmBonus, true, iDifficulty)
			endif

		else ;Randomise the Ez

			EventHelperSpawnActorRandomEzSingleLocLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
			kRegularUnits, kEzList, bApplySwarmBonus, false, iDifficulty)
				
			iRegularActorCount = (kGroupList.Length) ;Required for loot system
					
			if bBossAllowed && iLosCounter != 25 ;Check again if Boss spawns allowed for this Actors preset and LoS counter hasn't maxed.
				EventHelperSpawnActorRandomEzSingleLocLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
				kBossUnits, kEzList, bApplySwarmBonus, true, iDifficulty)
			endif
						
		endif
		
	else ;Assume 1, Travel. Apply Package after spawn loops.
	
	
		if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely
					
			EventHelperSpawnActorNoPackageLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
			kRegularUnits, kEz, bApplySwarmBonus, false, iDifficulty)
				
			iRegularActorCount = (kGroupList.Length) ;Required for loot system
					
			if bBossAllowed && iLosCounter != 25 ;Check again if Boss spawns allowed for this Actors preset and LoS counter hasn't maxed.
				EventHelperSpawnActorNoPackageLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
				kBossUnits, kEz, bApplySwarmBonus, true, iDifficulty)
			endif

		else ;Randomise the Ez

			EventHelperSpawnActorRandomEzNoPackageLoop(ActorParams.iMaxAllowed, ActorParams.iChance, kRegularUnits, \
			kEzList, bApplySwarmBonus, false, iDifficulty)
				
			iRegularActorCount = (kGroupList.Length) ;Required for loot system
				
			if bBossAllowed && iLosCounter != 25 ;Check again if Boss spawns allowed for this Actors preset and LoS counter hasn't maxed.
				EventHelperSpawnActorRandomEzNoPackageLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
				kBossUnits, kEzList, bApplySwarmBonus, true, iDifficulty)
			endif

		endif
		
		;Apply Package to whole group now. 
		iSize = kGroupList.Length
		while iCounter < iSize
			EventHelperApplyPackageTravelData(kGroupList[iCounter], kTravelLoc)
			iCounter += 1
		endwhile
		
		
	endif
	
	
	;Check for loot pass, inform ThreadController of the spawned numbers.
	;---------------------------------------------------------------------
	
	if ActorManager.bLootSystemEnabled
		Int iBossCount = (kGroupList.Length) - iRegularActorCount ;Also required for loot system
		ActorManager.DoLootPass(kGroupList, iBossCount)
	endif
	
	;Lastly, we tell Increment the Active NPC and SP on the Thread Controller
	ThreadController.IncrementActiveNpcCount(kGroupList.Length)
	ThreadController.IncrementActiveSpCount(1)
	
		
EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;SPAWN LOOPS - EVENT HELPER SCRIPT - GHOUL APOC
;-------------------------------------------------------------------------------------------------------------------------------------------------------


Function EventHelperSpawnActorSingleLocLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, \ 
EncounterZone akEz, Bool abApplySwarmBonus, Bool abIsBossSpawn, Int aiDifficulty)
	
	if abApplySwarmBonus ;Apply Swarm bonus settings if true, else skip
	
		if !abIsBossSpawn
			aiMaxCount += ActorManager.iSwarmMaxCountBonus
			aiChance += ActorManager.iSwarmChanceBonus
		else
			aiMaxCount += ActorManager.iSwarmMaxCountBossBonus
			aiChance += ActorManager.iSwarmChanceBossBonus
		endif
		
	endif
	
	;Start placing Actors.
	
	if !abIsBossSpawn ;As SPs are designed to only spawn one group each, only init this list the first time. 
		kGroupList = new Actor[0] ;Needs to be watched for errors with arrays getting trashed when init'ed 0 members.
	endif
	
	Int iCounter = 1 ;Guarantee the first Actor
	Int iActorListSize = (akActorList.Length) - 1 ;Need actual size
	Actor kSpawned
	Actor kPlayerRef = MasterScript.PlayerRef ;Grab for LoS checks.
	
	;Spawn the first guaranteed Actor
	kSpawned = Self.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, akEz) ;akEz can be None
	kGroupList.Add(kSpawned) ;Add to Group tracker
	
	;Begin chance based placement loop for the rest of the Group
	while iCounter <= aiMaxCount
		
		;Check Line of sight to Player. 
		while kPlayerRef.HasDetectionLos(Self as ObjectReference)
			iLosCounter += 1 ;Line of sight fail counter will return this function if hits 25 (2.5 seconds wasted).
			if iLosCounter >= 25 ;Better to check now.
				return ;Stop spawning and kill the function. Player is looking too frequently.
			endif
			Utility.Wait(0.1)
		endwhile
		
		;Else continue to place Actor.
		if (Utility.RandomInt(1,100)) <= aiChance
			kSpawned = Self.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, akEz) ;akEz can be None
			kGroupList.Add(kSpawned) ;Add to Group tracker
			EventHelperApplyPackageSingleLocData(kSpawned)
		endif
		
		iCounter +=1
	
	endwhile

EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------

Function EventHelperSpawnActorRandomEzSingleLocLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, EncounterZone[] akEzList, \
Bool abApplySwarmBonus, Bool abIsBossSpawn, Int aiDifficulty) ;aiStartLoc default value = Self

	if abApplySwarmBonus ;Apply Swarm bonus settings if true, else skip
	
		if !abIsBossSpawn 
			aiMaxCount += ActorManager.iSwarmMaxCountBonus
			aiChance += ActorManager.iSwarmChanceBonus
		else
			aiMaxCount += ActorManager.iSwarmMaxCountBossBonus
			aiChance += ActorManager.iSwarmChanceBossBonus
		endif
		
	endif
	
	;Start placing Actors.
	
	if !abIsBossSpawn ;As SPs are designed to only spawn one group each, only init this list the first time. 
		kGroupList = new Actor[0] ;Needs to be watched for errors with arrays getting trashed when init'ed 0 members.
	endif
	
	Int iCounter = 1 ;Guarantee the first Actor
	Int iEzListSize = (akEzList.Length) - 1 ;Need actual size
	Int iActorListSize = (akActorList.Length) - 1 ;Need actual size
	EncounterZone kEz
	Actor kSpawned
	Actor kPlayerRef = MasterScript.PlayerRef ;Grab for LoS checks.
	
	;Spawn the first guaranteed Actor
	kSpawned = Self.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, kEz) ;akEz can be None
	kGroupList.Add(kSpawned) ;Add to Group tracker
	
	;Begin chance based placement loop for the rest of the Group
	while iCounter <= aiMaxCount
		
		;Check Line of sight to Player. 
		while kPlayerRef.HasDetectionLos(Self as ObjectReference)
			iLosCounter += 1 ;Line of sight fail counter will return this function if hits 25 (2.5 seconds wasted).
			if iLosCounter >= 25 ;Better to check now.
				return ;Stop spawning and kill the function. Player is looking too frequently.
			endif
			Utility.Wait(0.1)
		endwhile
		
		;Else continue to place Actor.
		if (Utility.RandomInt(1,100)) <= aiChance
			kEz = akEzList[(Utility.RandomInt(0,iEzListSize))] ;Randomise EZ each loop
			kSpawned = Self.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, kEz) ;akEz can be None
			kGroupList.Add(kSpawned) ;Add to Group tracker
			EventHelperApplyPackageSingleLocData(kSpawned)
		endif
		
		iCounter +=1
	
	endwhile

EndFunction


;PACKAGELESS LOOPS - USE FOR TRAVEL
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;DEV NOTE: These loops do not apply any package, they simply drop the Actor. It is expected the calling function will run ApplyPackage loop after this.

Function EventHelperSpawnActorNoPackageLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, \ 
EncounterZone akEz, Bool abApplySwarmBonus, Bool abIsBossSpawn, Int aiDifficulty) ;aiStartLoc default value = Self
	
	if abApplySwarmBonus ;Apply Swarm bonus settings if true, else skip
	
		if !abIsBossSpawn 
			aiMaxCount += ActorManager.iSwarmMaxCountBonus
			aiChance += ActorManager.iSwarmChanceBonus
		else
			aiMaxCount += ActorManager.iSwarmMaxCountBossBonus
			aiChance += ActorManager.iSwarmChanceBossBonus
		endif
		
	endif
	
	;Start placing Actors
	
	if !abIsBossSpawn ;As SPs are designed to only spawn one group each, only init this list the first time. 
		kGroupList = new Actor[0] ;Needs to be watched for errors with arrays getting trashed when init'ed 0 members.
	endif
	
	Int iCounter = 1 ;Guarantee the first Actor
	Int iActorListSize = (akActorList.Length) - 1 ;Need actual size
	Actor kSpawned
	Actor kPlayerRef = MasterScript.PlayerRef ;Grab for LoS checks. 
	
	;Spawn the first guaranteed Actor
	kSpawned = Self.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, akEz) ;akEz can be None
	kGroupList.Add(kSpawned) ;Add to Group tracker
	
	;Begin chance based placement loop for the rest of the Group
	while iCounter <= aiMaxCount
		
		;Check Line of sight to Player. 
		while kPlayerRef.HasDetectionLos(Self as ObjectReference)
			iLosCounter += 1 ;Line of sight fail counter will return this function if hits 25 (2.5 seconds wasted).
			if iLosCounter >= 25 ;Better to check now.
				return ;Stop spawning and kill the function. Player is looking too frequently.
			endif
			Utility.Wait(0.1)
		endwhile
		
		;Else continue to place Actor.
		if (Utility.RandomInt(1,100)) <= aiChance
			kSpawned = Self.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, akEz) ;akEz can be None
			kGroupList.Add(kSpawned) ;Add to Group tracker
		endif
		
		iCounter +=1
	
	endwhile

EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------

Function EventHelperSpawnActorRandomEzNoPackageLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, \ 
EncounterZone[] akEzList, Bool abApplySwarmBonus, Bool abIsBossSpawn, Int aiDifficulty) ;aiStartLoc default value = Self

	if abApplySwarmBonus ;Apply Swarm bonus settings if true, else skip
	
		if !abIsBossSpawn
			aiMaxCount += ActorManager.iSwarmMaxCountBonus
			aiChance += ActorManager.iSwarmChanceBonus
		else
			aiMaxCount += ActorManager.iSwarmMaxCountBossBonus
			aiChance += ActorManager.iSwarmChanceBossBonus
		endif
		
	endif
	
	;Start placing Actors
	
	if !abIsBossSpawn ;As SPs are designed to only spawn one group each, only init this list the first time. 
		kGroupList = new Actor[0] ;Needs to be watched for errors with arrays getting trashed when init'ed 0 members.
	endif
	
	Int iCounter = 1 ;Guarantee the first Actor
	Int iEzListSize = (akEzList.Length) - 1 ;Need actual size
	Int iActorListSize = (akActorList.Length) - 1 ;Need actual size
	EncounterZone kEz
	Actor kSpawned
	Actor kPlayerRef = MasterScript.PlayerRef ;Grab for LoS checks.
	
	;Spawn the first guaranteed Actor
	kSpawned = Self.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, kEz) ;akEz can be None
	kGroupList.Add(kSpawned) ;Add to Group tracker
	
	;Begin chance based placement loop for the rest of the Group
	while iCounter <= aiMaxCount
		
		;Check Line of sight to Player. 
		while kPlayerRef.HasDetectionLos(Self as ObjectReference)
			iLosCounter += 1 ;Line of sight fail counter will return this function if hits 25 (2.5 seconds wasted).
			if iLosCounter >= 25 ;Better to check now.
				return ;Stop spawning and kill the function. Player is looking too frequently.
			endif
			Utility.Wait(0.1)
		endwhile
		
		;Else continue to place Actor.
		if (Utility.RandomInt(1,100)) <= aiChance
			kEz = akEzList[(Utility.RandomInt(0,iEzListSize))] ;Randomise EZ each loop
			kSpawned = Self.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, kEz) ;akEz can be None
			kGroupList.Add(kSpawned) ;Add to Group tracker
		endif
		
		iCounter +=1
	
	endwhile

EndFunction


;PACKAGE APPLICATION LOOPS
;--------------------------
;From this script we are either linking to Self Object for Sandbox, or single travel marker from Region. 

Function EventHelperApplyPackageSingleLocData(Actor akActor)

	akActor.SetLinkedRef(Self as ObjectReference, SOTC_PackageKeyword01)
	kPackages[0].ApplyToRef(akActor) ;Finally apply the data alias with package
	akActor.EvaluatePackage() ;And evaluate so no delay
	
EndFunction


;Link Actor to travel locs and send on their merry way
Function EventHelperApplyPackageTravelData(Actor akActor, ObjectReference akTravelLoc)			
	
	;Actors only travel to single loc (then sandbox) from this script. 
	akActor.SetLinkedRef(akTravelLoc, SOTC_PackageKeyword01)
	kPackages[1].ApplyToRef(akActor) ;Finally apply the data alias with package
	akActor.EvaluatePackage() ;And evaluate so no delay
	
EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
