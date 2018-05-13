Scriptname SOTC:SpMiniPointScript extends ObjectReference
{ Script for the "Mini" Spawnpoint, used for spawning specific Actors and Debug. }
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

import SOTC:Struct_ClassDetails ;Struct definition needs to be present


SOTC:ThreadControllerScript ThreadController
;{ Init None, fills OnCellAttach. }

SOTC:RegionManagerScript RegionManager
;{ Init None, fills OnCellAttach.  Set ID accordingly. }
	
SOTC:RegionTrackerScript CleanupManager
;{ Init None, fills OnCellAttach. }
	
SOTC:ActorManagerScript ActorManager
;{ Init None, fills OnCellAttach. Set ID accordingly. }


Group Primary

	SOTC:MasterQuestScript Property MasterScript Auto Const Mandatory
	{ Fill with MasterQuest }
	
	Int Property iWorldID Auto Const Mandatory
	{ Fill with the World ID where this SP is placed. }
	; LEGEND - WORLDS
	; [0] - COMMONWEALTH
	; [1] - FAR HARBOR
	; [2] - NUKA WORLD

	Int Property iRegionID Auto Const Mandatory
	{ Fill with the RegionID where this SP is placed. }
	
	Int Property iActorID Auto Const Mandatory
	{ Fill with the Master ID of the Actor to spawn. See docs for a list of IDs. }
	
	Int Property iClassToSpawn Auto Const Mandatory
	{Set the Class Preset ID. 0 is debug, 1-3 Rarity based, 4 Amush (Rush), 5 Ambush (Static), 6 Sniper.
Actor must have this Class Preset defined or this will return None. }

	ReferenceAlias Property kPackage Auto Const Mandatory
	{ Fill with the desired package, typically SOTC_TravelPackage02. }
	
	ReferenceAlias Property kPackageAmbush Auto Const Mandatory
	{ Fill with SOTC_AmbushPackageRandom01. This gets filled the same on EVERY instance of this marker. }
	
	ReferenceAlias Property kPackageStampede Auto Const Mandatory
	{ Fill with SOTC_AmbushPackageStampede01. This gets filled the same on EVERY instance of this marker. }
	;This package is different as it causes the Actors to run to a single location and sandbox there. 
	
	;LEGEND - PACKAGE TYPES (ALL)
	; TRAVEL - RANDOM SPAWN (2 OR MORE RANDOM LOCATIONS)
	; SANDBOX (AND GUARD IF APPLICABLE)
	; HOLD POSITION (SNIPER)
	; PATROL (USE CUSTOM LOC MARKERS OR IDLE MARKERS)
	; AMBUSH - RUSH THE PLAYER (EITHER ON SPAWN OR WAIT)
	
	Keyword[] Property kPackageKeywords Auto Const Mandatory
	{ Fill with as many package keywords as needed (even if just 1). Used for linking to package marker(s) i.e Travel Locations. }
	
	Int Property iNumPackageLocs Auto Const Mandatory
	{ Set 0 to use Self as Package location, or set to number of locations expected by the Package set above }
	
	Bool Property bTravelling Auto Const Mandatory
	{ If Package is travelling, set True (most common use). }
	
EndGroup


Group Config

	Int Property iChanceToFire Auto Const Mandatory
	{ Use this define an extra chance/dice roll for this SP or set 100 for always. }
	
	Bool Property bForcePreset Auto Const
	{ If desired to force a Preset from the Class list, set this true. }
	
	Int Property iForcedPreset Auto Const
	{ Leave 0 if above is false. Otherwise set 0-3 (0 is debug preset). Set 4 to randomise main presets. }	
	
	Bool Property bForceDifficulty Auto Const
	{ If desired to force a Difficulty level, set true. }
	
	Int Property iForcedDifficulty Auto Const
	{ Set 0-4 if above is true. As per Vanilla Difficulty settings.}

	Bool Property bAllowVanilla Auto Const Mandatory
	{ Set true only if wanting this point to be allowed in Vanilla Mode. }

	Int Property iPresetRestriction Auto Const
	{ Fill this (1-3) if it is desired to restrict this point to a certain Master preset level. }

	Bool Property bIsInteriorPoint Auto Const
	{ Set true if placed in an interior cell, will behave differently with child markers distribution.
	Can be used in exterior cells if desired, i.e open buildings. }
	
	ObjectReference[] Property kChildMarkers Auto ;AUTO so can be modified at runtime.
	{ Used for Interiors only from this script, fill with the markers placed around the Interior in use. }
	
	Int Property iThreadsRequired = 1 Auto Mandatory
	{ Default value of 1. Set more if feel the need to (i.e large single group max counts). }
	;NOTE: Will be released immediately if Master intercepts for a Random Event. MultiPoint helpers will force add threads
	;on instantation, which can intentionally exceed the max thread threshold.
	
	;NOTE: bIsConfinedSpace Property removed from here, common sense says you wouldn't place an Oversized Actor SP in a confined space!

EndGroup


;---------------
;LocalVariables
;---------------

;TimerIDs
Int iStaggerStartupTimerID = 1 Const
Int iSpCooldownTimerID = 2 Const

Bool bSpawnpointActive ;Condition check. Once SP is activated this is set true.

ActorClassPresetScript ActorParamsScript

Actor[] kGrouplist ;Stores all Actors spawned on this instance

;Spawn Info, listed in expect order of setting. Not all are required, depending on SpawnType etc
Bool bRandomiseEZs ;Used in spawn loop to check if random EZ needs to be randomised (iEzApplyMode = 2)

Bool bApplyAmbushPackage ;Quick flag to set Random Ambush enabled
Bool bApplyStampedePackage ;Quick flag to set Random Stampede enabled
;Placed into empty state due to needing to check which package to remove at cleanup time.

;-------------------------------------------------------------------------------------------------------------------------------------------------------
;PRE-SPAWN EVENTS & FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

Event OnCellAttach()
	
	;Staggering the startup might help to randomise SPs in an area when Threads are scarce
	StartTimer((Utility.RandomFloat(0.2,0.5)), iStaggerStartupTimerID)

EndEvent


Event OnTimer(int aiTimerID)

	if aiTimerID == iStaggerStartupTimerID

		;Initial checks
		if (!Self.IsDisabled()) && (!bSpawnpointActive) ;INITIAL CHECK
		;Check if we are enabled, currently running
		
			;NOTE: Master and Regional checks are done before GetThread, so it is possible for an event to intercept before ThreadController can deny
			;Events are usually exempt from ThreadController checks, although they do count towards any of the limits.
			
			SetSpScriptLinks()
		
			;Master Level checks/intercepts
			if MasterScript.MasterSpawnCheck(Self as ObjectReference, bAllowVanilla) ;MASTER CHECK: If true, denied
				;Master script assuming control, kill this thread and disable
				Self.Disable()
				CleanupManager.AddSpentPoint(Self as ObjectReference) ;All points are added by Object rather than script type				
				return
			endif
			
			Debug.Notification("Passed Master Check")
			
			;Region Level checks/intercept. This will send in local spawn parameters if no intercept takes place.
			;NOTE: as of version 0.06.01, no events are defined on RegionManager, will always return false. 
			if RegionManager.RegionSpawnCheck(Self as ObjectReference, iPresetRestriction) ;REGION CHECK: If true, denied
				;Region script assuming control, kill this thread and disable
				Self.Disable()
				CleanupManager.AddSpentPoint(Self as ObjectReference) ;All points can be added by Object rather than script type
				return
			endif
			
			Debug.Notification("Passed Region Check")
			
			if (ActorManager.bActorEnabled) && (ThreadController.GetThread(iThreadsRequired)) && \
			((Utility.RandomInt(1,100)) < iChanceToFire) ;LOCAL CHECK
				Debug.Notification("Spawning")
				PrepareLocalSpawn() ;Do Spawning
			Endif
			
		else
			;Denied, Disable and wait some time before trying again.
			Self.Disable()
			StartTimer(ThreadController.iSpCooldownTimerClock, iSpCooldownTimerID)
		endif

	elseif aiTimerID == iSpCooldownTimerID
	
		Self.Enable()
	
	endif
	
EndEvent


Function SetSpScriptLinks()
	
	;Since patch 0.10.01, all instances are created at runtime (first install). Necessary evil.
	ThreadController = MasterScript.ThreadController
	RegionManager = MasterScript.Worlds[iWorldID].Regions[iRegionID]
	CleanupManager = RegionManager.CleanupManager
	ActorManager = MasterScript.SpawntypeMasters[0].ActorList[iActorID]
	
EndFunction


Function PrepareLocalSpawn() ;Determine how to proceed

	if bIsInteriorPoint ;Distributes the group across different parts of the Interior
	;DEV NOTE - Master Random Events framework needs an update for interiors.
		if (Self as ObjectReference).GetCurrentLocation().IsCleared()
			PrepareInteriorSpawn()
		else ;Nip it in the bud
			ThreadController.ReleaseThreads(iThreadsRequired)
			Self.Disable()
			StartTimer(ThreadController.iSpCooldownTimerClock, iSpCooldownTimerID)
		endif

	else ;Start a regular spawn at this marker
	
		PrepareSingleGroupSpawn()
	
	endif
	
	Self.Disable()
	bSpawnpointActive = true
	CleanupManager.AddSpentPoint(Self as ObjectReference) ;All points are added by Object rather than script type
	;Cleanup will be handled by the CleanupManager upon Region reset timer firing.
	ThreadController.ReleaseThreads(iThreadsRequired) ;Spawning done, threads can be released.

EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;CLEANUP FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;NOTE - We should not have to remove linked refs as only Marker remains persistent
;NOTE - Remove Alias Data regardless.

;Cleanup all active data produced by this SP
Function FactoryReset()

	if bApplyAmbushPackage
		CleanupActorRefs(kPackageAmbush)
	elseif bApplyStampedePackage
		CleanupActorRefs(kPackageStampede)
	else
		CleanupActorRefs(kPackage)
	endif
	
	ThreadController.IncrementActiveSpCount(-1)
	
EndFunction


Function CleanupActorRefs(ReferenceAlias akPackage) ;Decided to pass the package in here. 

	int iCounter = 0
	int iSize = kGroupList.Length
        
	while iCounter < iSize

		akPackage.RemoveFromRef(kGroupList[iCounter]) ;Remove package data. Perhaps not necessary?
		;NOTE; Removed code that removes linked refs. Unnecesary.
		kGroupList[iCounter].DeleteWhenAble()
		iCounter += 1
	
	endwhile
	
	ThreadController.IncrementActiveNpcCount(-iSize)
	kGroupList.Clear()
	
EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;SINGLE GROUP SPAWN EVENTS & FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

Function PrepareSingleGroupSpawn()
	
	;Link with ClassPresetScript to use. 
	ActorParamsScript = ActorManager.ClassPresets[iClassToSpawn]
	
	;Now we can get the actual spawn parameters
	ClassDetailsStruct ActorParams
	if bForcePreset
	
		if iForcedPreset == 4 ;Assuming it is more likely this mode will be selected over specific preset, for now
			Int iPreset = Utility.RandomInt(1,3)
			ActorParams = ActorParamsScript.ClassDetails[iPreset]
		else
			ActorParams = ActorParamsScript.ClassDetails[iForcedPreset]
		endif
		
	else
		ActorParams = ActorParamsScript.ClassDetails[RegionManager.iCurrentPreset]
	endif
	
	;Set difficulty for spawning.
	Int iDifficulty
	if bForceDifficulty
		iDifficulty = iForcedDifficulty
	else
		iDifficulty = RegionManager.iCurrentDifficulty
	endif
	
	;Organise the actual ActorBase arrays
	ActorBase[] kRegularUnits = (ActorParamsScript.GetRandomGroupLoadout(false)) as ActorBase[] ;Cast to copy locally
	ActorBase[] kBossUnits
	Bool bBossAllowed = (ActorParams.iChanceBoss) as Bool
	if bBossAllowed ;Set if allowed. Later used as parameter.
		kBossUnits = (ActorParamsScript.GetRandomGroupLoadout(true)) as ActorBase[] ;Cast to copy locally
	endif
	
	;Check and setup EncounterZone data
	
	EncounterZone kEz ;iEZMode 1 - Single EZ to use for Group Levels
	EncounterZone[] kEzList; If iEzApplyMode = 2, this will point to a Region list of EZs. One will be applied to each Actor at random.
	
	Int iEzMode = RegionManager.iEzApplyMode ;Store locally for reuse
	if iEzMode == 0 ;This exists so we can skip it, seems it is more likely players won't use it.
		;Do nothing, use NONE EZ (passed parameters will be None)
	elseif iEZMode == 1
		kEz = RegionManager.GetRandomEz()
	elseif iEzMode == 2
		kEzList = RegionManager.GetRegionCurrentEzList() ;Look directly at the Regions Ez list, based on current mode.
	endif
	
	;Check for bonus events/setup Package locations if necessary
	
	Bool bApplySwarmBonus ;Whether or not Swarm bonuses are applied
	;Now lets roll the dice on it
	if (ActorManager.bSupportsSwarm) && (RegionManager.RollForSwarm())
		
		bApplySwarmBonus = true
		
		;Roll for Stampede if supported
		if (ActorManager.bSupportsStampede) && (RegionManager.RollForStampede())
			bApplyStampedePackage = true
		endif
		
	endif
	
	ObjectReference[] kPackageLocs = new ObjectReference[0] ;Create it, because even if we skip it, it still has to be passed to loop
	
	;Roll dice on Random Ambush feature
	if (!bApplyStampedePackage) && (!ActorManager.bIsFriendlyNeutralToPlayer) && (RegionManager.RollForAmbush()) ;Supported for all Actor types
		bApplyAmbushPackage = true
	endif
	
	;Check if we are ambushing or stampeding
	if (!bApplyAmbushPackage) && (bTravelling) ;More likely we are not
		kPackageLocs = RegionManager.GetRandomTravelLocs(iNumPackageLocs)
	else ;But if we are we need 1 location
		kPackageLocs = RegionManager.GetRandomTravelLocs(1)
	endif
	
	;Finally, begin loops.

	Int iRegularActorCount ;Required for loot system
	
	if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely
			
		SpawnActorLoop(ActorParams.iMaxAllowed, ActorParams.iChance, kRegularUnits, kEz, \
		bApplySwarmBonus, kPackageLocs, false, iDifficulty)
		
		iRegularActorCount = (kGroupList.Length) ;Required for loot system
			
		if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
			SpawnActorLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, kBossUnits, \
			kEz, bApplySwarmBonus, kPackageLocs, true, iDifficulty)
		endif

	else ;Randomise the Ez

		SpawnActorRandomEzLoop(ActorParams.iMaxAllowed, ActorParams.iChance, kRegularUnits, \
		kEzList, bApplySwarmBonus, kPackageLocs, false, iDifficulty)
		
		iRegularActorCount = (kGroupList.Length) ;Required for loot system
			
		if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
			SpawnActorRandomEzLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
			kBossUnits, kEzList, bApplySwarmBonus, kPackageLocs, true, iDifficulty)
		endif
			
	endif
	
	Int iBossCount = (kGroupList.Length) - iRegularActorCount ;Also required for loot system
	
	;Now check the loot system and do the loot pass if applicable. We do this post spawn as to avoid unnecessary performace impact in spawnloops.
	
	if ActorManager.bLootSystemEnabled
		ActorManager.DoLootPass(kGroupList, iBossCount)
	endif
	
	;Lastly, we tell Increment the Active NPC and SP on the Thread Controller
	ThreadController.IncrementActiveNpcCount(kGroupList.Length)
	ThreadController.IncrementActiveSpCount(1)
	
	;GTFO

EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;SINGLE GROUP SPAWN LOOPS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;Regular, local, single group spawn loop
Function SpawnActorLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, EncounterZone akEz, Bool abApplySwarmBonus, \
ObjectReference[] akPackageLocs, Bool abIsBossSpawn, Int aiDifficulty)

	if abApplySwarmBonus ;Apply Swarm bonus settings if true, else skip
	
		if abIsBossSpawn ;Checking if Boss first, possibly faster to switch check order here?
			aiMaxCount += ActorManager.iSwarmMaxCountBonus
			aiChance += ActorManager.iSwarmChanceBonus
		else
			aiMaxCount += ActorManager.iSwarmMaxCountBossBonus
			aiChance += ActorManager.iSwarmChanceBossBonus
		endif
		
	endif
	
	kGroupList = new Actor[0]
	
	Int iCounter = 1 ;Guarantee the first Actor
	Int iActorListSize = (akActorList.Length) - 1 ;Need actual size
	Actor kSpawned
	
	;Spawn the first guaranteed Actor
	kSpawned = Self.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, akEz) ;akEz can be None
	kGroupList.Add(kSpawned) ;Add to Group tracker

	if !bApplyAmbushPackage ;More likely to be false
		ApplyPackageData(kSpawned, akPackageLocs) ;Apply the package from Alias
	else
		ApplyPackageAmbushData(kSpawned, akPackageLocs) ;Apply the package from Alias
	endif
	
	;Begin chance loop for the rest of the Group
	while iCounter != aiMaxCount
	
		if (Utility.RandomInt(1,100)) < aiChance
			
			kSpawned = Self.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, akEz) ;akEz can be None
			kGroupList.Add(kSpawned) ;Add to Group tracker
			
			if !bApplyAmbushPackage ;More likely to be false
				ApplyPackageData(kSpawned, akPackageLocs) ;Apply the package from Alias
			elseif bApplyStampedePackage
				ApplyPackageStampedeData(kSpawned, akPackageLocs)
			elseif bApplyAmbushPackage
				ApplyPackageAmbushData(kSpawned, akPackageLocs) ;Apply the package from Alias
			endif		
			
		endif
		
		iCounter +=1
	
	endwhile

EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------

;Regular, local, single group spawn loop, Randomise EZs
Function SpawnActorRandomEzLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, EncounterZone[] akEzList, Bool abApplySwarmBonus, \
ObjectReference[] akPackageLocs, Bool abIsBossSpawn, Int aiDifficulty)

	if abApplySwarmBonus ;Apply Swarm bonus settings if true, else skip
	
		if abIsBossSpawn ;Checking if Boss first, possibly faster to switch check order here?
			aiMaxCount += ActorManager.iSwarmMaxCountBonus
			aiChance += ActorManager.iSwarmChanceBonus
		else
			aiMaxCount += ActorManager.iSwarmMaxCountBossBonus
			aiChance += ActorManager.iSwarmChanceBossBonus
		endif
		
	endif
	
	kGroupList = new Actor[0]
	
	Int iCounter = 1 ;Guarantee the first Actor, seems we come this far
	Int iEzListSize = (akEzList.Length) - 1 ;Need actual size
	Int iActorListSize = (akActorList.Length) - 1 ;Need actual size
	EncounterZone kEz
	Actor kSpawned
	
	;Spawn the first guaranteed Actor
	kEz = akEzList[(Utility.RandomInt(0,iEzListSize))] ;Random EZ
	kSpawned = Self.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, kEz) ;akEz can be None
	kGroupList.Add(kSpawned) ;Add to Group tracker

	if !bApplyAmbushPackage ;More likely to be false
		ApplyPackageData(kSpawned, akPackageLocs) ;Apply the package from Alias
	else
		ApplyPackageAmbushData(kSpawned, akPackageLocs) ;Apply the package from Alias
	endif
	
	;Begin chance loop for the rest of the Group
	while iCounter != aiMaxCount
	
		kEz = akEzList[(Utility.RandomInt(0,iEzListSize))] ;Randomise EZ each loop
	
		if (Utility.RandomInt(1,100)) < aiChance
			
			kSpawned = Self.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, kEz) ;akEz can be None
			kGroupList.Add(kSpawned) ;Add to Group tracker
			
			if !bApplyAmbushPackage ;More likely to be false
				ApplyPackageData(kSpawned, akPackageLocs)
			elseif bApplyStampedePackage
				ApplyPackageStampedeData(kSpawned, akPackageLocs)
			elseif bApplyAmbushPackage
				ApplyPackageAmbushData(kSpawned, akPackageLocs)
			endif	
			
		endif
		
		iCounter +=1
	
	endwhile

EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;INTERIOR SPAWN EVENTS & FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;NOTE - INTERIOR SPAWNS ONLY DESIGNED TO SPAWN 1 GROUP!

;In order to achieve a relatively even distribution of actors throughout an interior cell, we place Actors at random markers scattered through the cell.
;The iRarityOverride is still present here, but Random Ambush mode is NOT supported (Use Ambush points for that if desired). Random Swarm is supported.
;This also expects the Interior Sandbox package to be set (has a tighter sandbox radius and patrols between 2 predetermined, random points every so often)
Function PrepareInteriorSpawn()
	
	;Link with ClassPresetScript to use. 
	ActorParamsScript = ActorManager.ClassPresets[iClassToSpawn]
	
	;Now we can get the actual spawn parameters
	ClassDetailsStruct ActorParams
	if bForcePreset
	
		if iForcedPreset == 4 ;Assuming it is more likely this mode will be selected over specific preset, for now
			Int iPreset = Utility.RandomInt(1,3)
			ActorParams = ActorParamsScript.ClassDetails[iPreset]
		else
			ActorParams = ActorParamsScript.ClassDetails[iForcedPreset]
		endif
		
	else
		ActorParams = ActorParamsScript.ClassDetails[RegionManager.iCurrentPreset]
	endif
	
	Int iDifficulty
	if bForceDifficulty
		iDifficulty = iForcedDifficulty
	else
		iDifficulty = RegionManager.iCurrentDifficulty ;Set difficulty for spawning. 
	endif
	
	;Organise the actual ActorBase arrays
	ActorBase[] kRegularUnits = (ActorParamsScript.GetRandomGroupLoadout(false)) as ActorBase[] ;Cast to copy locally
	ActorBase[] kBossUnits
	Bool bBossAllowed = (ActorParams.iChanceBoss) as Bool
	if bBossAllowed ;Not gonna set this unless it's allowed. Later used as parameter
		kBossUnits = (ActorParamsScript.GetRandomGroupLoadout(true)) as ActorBase[] ;Cast to copy locally
	endif
	
	;Check and setup EncounterZone data
	
	EncounterZone kEz ;iEZMode 1 - Single EZ to use for Group Levels
	EncounterZone[] kEzList; If iEzApplyMode = 2, this will point to a Region list of EZs. One will be applied to each Actor at random.
	
	Int iEzMode = RegionManager.iEzApplyMode ;Store locally for reuse
	
	if iEzMode == 0 ;This exist so we can skip it, seems it is more likely players won't use it.
		;Do nothing, use NONE EZ (passed parameters will be None)
	elseif iEZMode == 1
		kEz = RegionManager.GetRandomEz()
	elseif iEzMode == 2
		kEzList = RegionManager.GetRegionCurrentEzList() ;Look directly at the Regions Ez list, based on current mode.
	endif
	
	;Check for bonus events. Stampede and Ambush not in supported in Interior mode.
	
	Bool bApplySwarmBonus ;Whether or not Swarm bonuses are applied
	;Now lets roll the dice on it
	if (ActorManager.bSupportsSwarm) && (RegionManager.RollForSwarm())
		bApplySwarmBonus = true
	endif
	
	;Finally, begin loops.
	
	Int iRegularActorCount ;Required for loot system
	
	if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely
			
		SpawnActorInteriorLoop(ActorParams.iMaxAllowed, ActorParams.iChance, kRegularUnits, \
		kEz, bApplySwarmBonus, false, iDifficulty)
		
		iRegularActorCount = (kGroupList.Length) ;Required for loot system
			
		if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
			SpawnActorInteriorLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
			kBossUnits, kEz, bApplySwarmBonus, true, iDifficulty)
		endif

	else ;Randomise the Ez

		SpawnActorRandomEzInteriorLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
		kRegularUnits, kEzList, bApplySwarmBonus, false, iDifficulty)
		
		iRegularActorCount = (kGroupList.Length) ;Required for loot system
			
		if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
			SpawnActorRandomEzInteriorLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
			kBossUnits, kEzList, bApplySwarmBonus, true, iDifficulty)
		endif
			
	endif
	
	Int iBossCount = (kGroupList.Length) - iRegularActorCount ;Also required for loot system
	
	;Now check the loot system and do the loot pass if applicable. We do this post spawn as to avoid unnecessary performace impact in spawnloops.
	
	if ActorManager.bLootSystemEnabled
		ActorManager.DoLootPass(kGroupList, iBossCount)
	endif

	;Lastly, we tell Increment the Active NPC and SP on the Thread Controller
	ThreadController.IncrementActiveNpcCount(kGroupList.Length)
	ThreadController.IncrementActiveSpCount(1)
	
	;GTFO

EndFunction




;---------------
;INTERIOR LOOPS
;---------------

;Interior spawn loop
Function SpawnActorInteriorLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, EncounterZone akEz, \
Bool abApplySwarmBonus, Bool abIsBossSpawn, Int aiDifficulty)

	if abApplySwarmBonus ;Apply Swarm bonus settings if true, else skip
	
		if abIsBossSpawn ;Checking if Boss first, possibly faster to switch check order here?
			aiMaxCount += ActorManager.iSwarmMaxCountBonus
			aiChance += ActorManager.iSwarmChanceBonus
		else
			aiMaxCount += ActorManager.iSwarmMaxCountBossBonus
			aiChance += ActorManager.iSwarmChanceBossBonus
		endif
		
	endif
	
	kGroupList = new Actor[0]
	
	Int iCounter = 1 ;Guarantee the first Actor
	Int iActorListSize = (akActorList.Length) - 1 ;Need actual size
	Int iSpawnLocListSize = (kChildMarkers.Length) - 1 ;Need actual size
	Actor kSpawned
	ObjectReference kSpawnLoc
	
	;Spawn the guaranteed first Actor
	kSpawnLoc = kChildMarkers[Utility.RandomInt(0,iSpawnLocListSize)] ;Place at a random marker in the cell/child cell (if exists)
	kSpawned = kSpawnLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, akEz) ;akEz can be None
	kGroupList.Add(kSpawned) ;Add to Group tracker
	ApplyPackageInteriorData(kSpawned, kSpawnLoc)
	;Chance loop for the rest of the Group
	while iCounter != aiMaxCount
	
		if (Utility.RandomInt(1,100)) < aiChance
			
			kSpawnLoc = kChildMarkers[Utility.RandomInt(0,iSpawnLocListSize)] ;Place at a random marker in the cell/child cell (if exists)
			kSpawned = kSpawnLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, akEz) ;akEz can be None
			kGroupList.Add(kSpawned) ;Add to Group tracker
			ApplyPackageInteriorData(kSpawned, kSpawnLoc)
			
		endif
		
		iCounter +=1
	
	endwhile

EndFunction


;Interior spawn loop
Function SpawnActorRandomEzInteriorLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, EncounterZone[] akEzList, \
Bool abApplySwarmBonus, Bool abIsBossSpawn, Int aiDifficulty)

	if abApplySwarmBonus ;Apply Swarm bonus settings if true, else skip
	
		if abIsBossSpawn ;Checking if Boss first, possibly faster to switch check order here?
			aiMaxCount += ActorManager.iSwarmMaxCountBonus
			aiChance += ActorManager.iSwarmChanceBonus
		else
			aiMaxCount += ActorManager.iSwarmMaxCountBossBonus
			aiChance += ActorManager.iSwarmChanceBossBonus
		endif
		
	endif
	
	kGroupList = new Actor[0]
	
	Int iCounter = 1 ;Guarantee the first Actor
	Int iEzListSize = (akEzList.Length) - 1 ;Need actual size
	Int iActorListSize = (akActorList.Length) - 1 ;Need actual size
	Int iSpawnLocListSize = (kChildMarkers.Length) - 1 ;Need actual size
	EncounterZone kEz
	Actor kSpawned
	ObjectReference kSpawnLoc
	
	;Spawn the guaranteed first Actor
	kEz = akEzList[(Utility.RandomInt(0,iEzListSize))] ;Randomise each loop
	kSpawnLoc = kChildMarkers[Utility.RandomInt(0,iSpawnLocListSize)] ;Place at a random marker in the cell/child cell (if exists)
	kSpawned = kSpawnLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, kEz) ;kEz can be None
	kGroupList.Add(kSpawned) ;Add to Group tracker
	ApplyPackageInteriorData(kSpawned, kSpawnLoc)
	;Chance loop for the rest of the Group
	
	while iCounter != aiMaxCount
	
		kEz = akEzList[(Utility.RandomInt(0,iEzListSize))] ;Randomise each loop
	
		if (Utility.RandomInt(1,100)) < aiChance
			
			kSpawnLoc = kChildMarkers[Utility.RandomInt(0,iSpawnLocListSize)] ;Place at a random marker in the cell/child cell (if exists)
			kSpawned = kSpawnLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, kEz) ;kEz can be None
			kGroupList.Add(kSpawned) ;Add to Group tracker
			ApplyPackageInteriorData(kSpawned, kSpawnLoc)
			
		endif
		
		iCounter +=1
	
	endwhile

EndFunction

;----------------
;UNIVERSAL LOOPS
;----------------

;Main function, supports the regular types
Function ApplyPackageData(Actor akActor, ObjectReference[] akPackageLocs)

	if bTravelling ;More likely to be traveling, so check this first
		
		Int iCounter
		Int iSize = akPackageLocs.Length
		
		while iCounter < iSize
			
			akActor.SetLinkedRef(akPackageLocs[iCounter], kPackageKeywords[iCounter])
			iCounter += 1
		
		endwhile
	
	elseif iNumPackageLocs == 0 ;Next, it is more likely to be using self as Package loc if not traveling
	
		akActor.SetLinkedRef(Self as ObjectReference, kPackageKeywords[0])
		
	else ;Outright assume there is more than 1 package loc and kChildMarkers has content (if not will fail)
		
		Int iCounter
		
		while iCounter < iNumPackageLocs ;iCounter starts at 0, does not require <= operator (this is a sanity note)
			
			akActor.SetLinkedRef(kChildMarkers[iCounter], kPackageKeywords[iCounter])
			iCounter += 1
		
		endwhile
		
	endif
	
	kPackage.ApplyToRef(akActor) ;Finally apply the data alias with package
	akActor.EvaluatePackage() ;And evaluate so no delay
	
EndFunction


;Stampede pacakge, travel to a single location and sandbox at running speed.
Function ApplyPackageStampedeData(Actor akActor, ObjectReference[] akPackageLocs) 

	akActor.SetLinkedRef(akPackageLocs[0], kPackageKeywords[0])
	kPackageAmbush.ApplyToRef(akActor) ;Finally apply the data alias with package
	akActor.EvaluatePackage() ;And evaluate so no delay
	
EndFunction


;Ambush version of the above, only travel to Player to attack
Function ApplyPackageAmbushData(Actor akActor, ObjectReference[] akPackageLocs) 
;This will send all Actors in the Grouplist after the player immediately, then travel to one location after if they survive.

	;NOTE: A change may be made here, to have this loop the whole group at the end and send them
	;all after the player in quicker succession. This may be better in terms of how the group
	;appears to mob the player, i.e spread out vs  virtually all at once

	akActor.SetLinkedRef(Game.GetPlayer(), kPackageKeywords[0])
	akActor.SetLinkedRef(akPackageLocs[0], kPackageKeywords[1]) ;Location to travel if combat ends with player and Actor survives.
	kPackageAmbush.ApplyToRef(akActor) ;Finally apply the data alias with package
	akActor.EvaluatePackage() ;And evaluate so no delay
	
EndFunction


;Specifically for the Interior spawns, quick and specific
Function ApplyPackageInteriorData(Actor akActor, ObjectReference akSpawnLoc)
;Interior Package is simple, link to kSpawnLoc to sandbox and pick some other marker in the cell as potential travel/patrol point.
;If the same marker is selected the actor will just stay put!
	
	Int iSize = (kChildMarkers.Length) - 1 ;Need actual size
	
	ObjectReference kSecondaryLoc = kChildMarkers[Utility.RandomInt(0,iSize)]
	akActor.SetLinkedRef(akSpawnLoc, kPackageKeywords[0])
	akActor.SetLinkedRef(akSpawnLoc, kPackageKeywords[1]) ;Expecting 2 Keywords to be filled at least!
	
	kPackage.ApplyToRef(akActor) ;Finally apply the data alias with package
	akActor.EvaluatePackage() ;And evaluate so no delay
	
EndFunction


;------------------------------------------------------------------------------------------------
