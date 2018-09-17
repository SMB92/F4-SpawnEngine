Scriptname SOTC:SpHelperScript extends ObjectReference
{ Spawnpoint helper script, for multithreading multi-group spawns }
;Written by SMB92
;Special thanks to J. Ostrus [BigandFlabby] for code contributions that made this mod possible.

;Purpose of this script is to be tied to an Activator which will be created in game by a "Multi-point Spawnpoint", which will pass parameters to this 
;script and have it immediately begin spawning a single group of Actors. This script is a fair bit more "primitive" then the main SP script, it has
;less access to features so some Package modes 

;LEGEND - PREFIX CONVENTION
; Variables and Properties are treated the same. Script types do not have prefixes, unless they
;are explicitly received as function arguments and are multi-instance scripts.
; "a" - (Function/Event Blocks only) Variable was received as function argument OR the variable
;was created from a passed-in Struct/Var[] member
; "k" - Is an "Object" as usual, whether created in a Block or defined in the empty state/a state.
; "f,b,i,s" - The usual Primitives: Float, Bool, Int, String.

;All functions on this script are prefixed with "Helper" so they are always distinguishable from the main SP functions. 

;-------------------------------------------------------------------------------------------------------------------------------------------------------
;PROPERTIES & IMPORTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

Spell Property kEvalPackageSpell Auto Const Mandatory
{ Fill with SOTC_EvalPackageSpell on the base form. Forces EvaluatePackage on spawns in own thread. }

Keyword[] Property kPackageKeywords Auto Const Mandatory
{ Fill with SOTC_PackageKeywords (10 by default). Add more if needed. Used for linking to package marker(s). }

import SOTC:Struct_ClassDetails ;Struct definition needs to be present

SOTC:MasterQuestScript MasterScript ;Pretty much only used here to get PlayerRef, assuming faster than Game.GetPlayer(). May see expanded use in future.
SOTC:ThreadControllerScript ThreadController

;Passed in by Parent point
SOTC:RegionManagerScript RegionManager
SOTC:ActorClassPresetScript ActorParamsScript
SOTC:ActorManagerScript ActorManager ;Not set by Pass-in, set in Prepare() function.
Int iPackageMode
ReferenceAlias kPackage
ObjectReference[] kPackageLocs
Bool bSpreadSpawnsToChildPoints ;Added in version 0.13.01, works just like main script, only for Package Mode 0 & 1. 
Int iPreset
Int iDifficulty

Int iStartLoc ;Used only for Patrol Mode to set the link order correctly or Ambush Mode for Distance setting.

;Local variables
Actor[] kGroupList
Int iLosCounter ;This will be incremented whenever a Line of sight check to Player fails. If reaches 25, spawning aborts. As we at least spawn 1 actor
;to start with, this remains safe to use (however Player may see that one actor being spawned. its just easier to live with). 
Int iHelperFireTimerID = 3 Const

;DEV NOTE: The Helper does have the ability to "expend" ChildPoints, however this should be seldom used.
ObjectReference[] kActiveChildren ;Temp list of all child markers used to delegate spawns to
Bool bChildrenActive ;This will be checked and save reinitializing above array later.
Int[] iChildPointElectionTracker ;Tracks the elected ChildPoints when using bSpreadSpawnsToChildPoints. Integers stored are used to correlate to correct
;ChildPoint to link to when applying Packages. Necessary evil now that Packages are all applied after spawn loops. 


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;INITIALISATION FUNCTIONS & EVENTS - HELPER SCRIPT
;-------------------------------------------------------------------------------------------------------------------------------------------------------

Function SetHelperSpawnParams(SOTC:RegionManagerScript aRegionManager, SOTC:ActorClassPresetScript aActorParamsScript, Int aiPackageMode, \
ReferenceAlias akPackage, ObjectReference[] akPackageLocs, Bool abSpreadSpawns, Int aiPreset, Int aiDifficulty, Int aiStartLoc = 0)
;Int aiStartLoc was added in version 0.13.01 for Patrol packages. Starts the Group linking at the ChildPoint they spawned at so they still patrol in the 
;expected order (ChildPoint for patrols should be listed in the order of the route). Also doubles as Distance for Package Mode 3 Ambush. 
	
	
	RegionManager = aRegionManager
	MasterScript = RegionManager.MasterScript
	ThreadController = RegionManager.ThreadController ;Done this way to free up a parameter slot. 
	ActorParamsScript = aActorParamsScript
	iPackageMode = aiPackageMode
	kPackage = akPackage
	kPackageLocs = akPackageLocs as ObjectReference[] ;Cast to ensure copy locally.
	bSpreadSpawnsToChildPoints = abSpreadSpawns
	iPreset = aiPreset ;Preset is passed from Spawntype script as it can be configured to be different from Region.
	iDifficulty = aiDifficulty
	
	iStartLoc = aiStartLoc ;Used only for Patrol Mode to set the link order correctly or Ambush Mode for Distance setting. 
	
	StartTimer(0.2, iHelperFireTimerID) ;Ready to start own thread

EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;CLEANUP FUNCTIONS & EVENTS - HELPER SCRIPT
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;The owning SpawnPoint will delete this isntance when the following has returned. 

Function HelperFactoryReset()

	HelperCleanupActorRefs()
	
	if bSpreadSpawnsToChildPoints
		iChildPointElectionTracker.Clear()
	endif
	
	RegionManager = None
	ActorParamsScript = None
	ActorManager = None
	kPackage = None
	kPackageLocs.Clear()
	kPackageLocs = None
	
	ThreadController.IncrementActiveSpCount(-1)
	ThreadController = None

EndFunction


;Cleans up all Actors in GroupList
Function HelperCleanupActorRefs() 

	int iCounter = 0
	int iSize = kGroupList.Length
        
	while iCounter < iSize

		;No longer removing alias data, should be deleted with Actor. 
		;NOTE: Removed code that removes linked refs. Unnecesary.
		kGroupList[iCounter].Delete()
		iCounter += 1
	
	endwhile
	
	kGroupList.Clear()
	ThreadController.IncrementActiveNpcCount(-iSize)
	
EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;SINGLE GROUP SPAWN FUNCTIONS & EVENTS - HELPER SCRIPT
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;Start own thread and do work on timer
Event OnTimer(int aiTimerID)

	if aiTimerID == iHelperFireTimerID
		
		ThreadController.ForceAddThreads(1) ;Due to random factor behind spawning groups count, threads are force added instead of requested. 
		HelperPrepareSingleGroupSpawn()
		ThreadController.ReleaseThreads(1) ;Spawning done, threads can be released.
		
	endif
	
EndEvent



;Main spawning function
Function HelperPrepareSingleGroupSpawn()
;NOTE - Actor is passed in above and set in local variable, cannot get randomly from here.
	
	;Values used throughout block
	Int iCounter
	Int iSize
	
	ActorManager = ActorParamsScript.ActorManager
	;We'll get this now as it will have to be passed to the loop as well as various other work which makes this essential
	
	;Now we can get the actual spawn parameters
	ClassDetailsStruct ActorParams = ActorParamsScript.ClassDetails[iPreset]
	
	
	;Organise the ActorBase arrays/Get GroupLoadout.
	;------------------------------------------------
	
	SOTC:ActorGroupLoadoutScript GroupLoadout = ActorParamsScript.GetRandomGroupLoadout()
	
	ActorBase[] kRegularUnits = (GroupLoadout.kGroupUnits) as ActorBase[] ;Cast to copy locally
	ActorBase[] kBossUnits
	Bool bBossAllowed ;Later used as parameter.
	if (ActorParams.iChanceBoss as Bool) && (GroupLoadout.kBossGroupUnits[0] != None) ;Check if Boss allowed and there is actually Boss on this GL.
		kBossUnits = (GroupLoadout.kBossGroupUnits) as ActorBase[] ;Cast to copy locally
		bBossAllowed = true
	endif
	
	
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
	
	
	;Check for bonus events & setup Package locations if necessary
	;--------------------------------------------------------------
	;DEV NOTE: Rampage and Random Ambush not supported for MultiPoint
	
	Bool bApplySwarmBonus ;Whether or not Swarm bonuses are applied
	;Now lets roll the dice on it
	if iPackageMode != 4 && (ActorManager.bSupportsSwarm) && (RegionManager.RollForSwarm()) ;Not supported for HoldPosition Mode. 
		bApplySwarmBonus = true
	endif
	
	
	;Finally, start the correct Spawn Loop for the Package Mode selected.
	;--------------------------------------------------------------------
	
	Int i ;Used as needed.
	Int iRegularActorCount ;Required for loot system

	if iPackageMode < 5 ;Sandbox/Travel/Patrol/Ambush
	
		if !bSpreadSpawnsToChildPoints || iPackageMode == 2 || iPackageMode == 3 ;More likely false/Patrols and Ambushes must use this method.
	
			if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely

				HelperSpawnActorSingleLocLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
				kRegularUnits, kEz, bApplySwarmBonus, false, iDifficulty)
		
				iRegularActorCount = (kGroupList.Length) ;Required for loot system
					
				if bBossAllowed && iLosCounter != 25 ;Check again if Boss spawns allowed for this Actors preset and LoS counter hasn't maxed.
					HelperSpawnActorSingleLocLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEz, bApplySwarmBonus, true, iDifficulty)
				endif

			else ;Randomise the Ez

				HelperSpawnActorRandomEzSingleLocLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
				kRegularUnits, kEzList, bApplySwarmBonus, false, iDifficulty)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system
					
				if bBossAllowed && iLosCounter != 25 ;Check again if Boss spawns allowed for this Actors preset and LoS counter hasn't maxed.
					HelperSpawnActorRandomEzSingleLocLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEzList, bApplySwarmBonus, true, iDifficulty)
				endif
						
			endif
			
			
		else ;Assume true
		
			iChildPointElectionTracker = new Int [1] ;Necessary evil so linking of Package can be done correctly.
		
			if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely
					
				HelperSpawnActorSingleLocRandomChildLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
				kRegularUnits, kEz, bApplySwarmBonus, false, iDifficulty, false)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system
					
				if bBossAllowed && iLosCounter != 25 ;Check again if Boss spawns allowed for this Actors preset and LoS counter hasn't maxed.
					HelperSpawnActorSingleLocRandomChildLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEz, bApplySwarmBonus, true, iDifficulty, false)
				endif

			else ;Randomise the Ez

				HelperSpawnActorRandomEzSingleLocRandomChildLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
				kRegularUnits, kEzList, bApplySwarmBonus, false, iDifficulty, false)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system
					
				if bBossAllowed && iLosCounter != 25 ;Check again if Boss spawns allowed for this Actors preset and LoS counter hasn't maxed.
					HelperSpawnActorRandomEzSingleLocRandomChildLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEzList, bApplySwarmBonus, true, iDifficulty, false)
				endif
					
			endif
			
		endif
		
		;Set the Package on all actors in quick succession.
		;--------------------------------------------------
		iCounter = 0 ;To be sure to be sure.
		iSize = kGroupList.Length 
		
		if iPackageMode == 0 || iPackageMode == 4 ;Sandbox/Hold
		
			if bSpreadSpawnsToChildPoints
			
				iChildPointElectionTracker.Remove(0) ;Remove the first member used for initialising. 
				
				while iCounter < iSize
					i = iChildPointElectionTracker[iCounter]
					HelperApplyPackageSingleLocData(kGroupList[iCounter], kPackageLocs[i])
					iCounter += 1
				endwhile
				
			else ;Use Self. 
			
				while iCounter < iSize
					HelperApplyPackageSingleLocData(kGroupList[iCounter], Self as ObjectReference)
					iCounter += 1
				endwhile
				
			endif
		
		
		elseif iPackageMode == 1 
			
			iSize = kGroupList.Length
			while iCounter < iSize
				HelperApplyPackageSingleLocData(kGroupList[iCounter], kPackageLocs[0])
				iCounter += 1
			endwhile
			
			;DEV NOTE: MultPoint mode does not support multiple travel locs. Only one is passed and linked. 

		elseif iPackageMode == 2

			;Apply loop
			iSize = kGroupList.Length
			while iCounter < iSize
				HelperApplyPackagePatrolData(kGroupList[iCounter]) ;IStartLoc value is reused as Distance. 
				iCounter += 1
			endwhile
			
		elseif iPackageMode == 3 ;Ambush Mode. Should always use this function and not the above Event inclusive one. 

			HelperApplyGroupSneakState()
			RegisterForDistanceLessThanEvent(MasterScript.PlayerRef, Self as ObjectReference, iStartLoc) ;Possibly faster then Game.GetPlayer()

		endif
	
;-------------------------------------------------------------------------------------------------------------------------------------------------------

	elseif iPackageMode == 5 ;Interior Mode
	;DEV NOTE 2: Interior Mode does not Expend ChildPoints by design. 
	
		iChildPointElectionTracker = new Int [1] ;Necessary evil so linking of Package can be done correctly.
	
		if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely
	
			HelperSpawnActorSingleLocRandomChildLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
			kRegularUnits, kEz, bApplySwarmBonus, false, iDifficulty, false)
			
			iRegularActorCount = (kGroupList.Length) ;Required for loot system
				
			if bBossAllowed && iLosCounter != 25 ;Check again if Boss spawns allowed for this Actors preset and LoS counter hasn't maxed.
				HelperSpawnActorSingleLocRandomChildLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
				kBossUnits, kEz, bApplySwarmBonus, true, iDifficulty, false)
			endif

		else ;Randomise the Ez

			HelperSpawnActorRandomEzSingleLocRandomChildLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
			kRegularUnits, kEzList, bApplySwarmBonus, false, iDifficulty, false)
			
			iRegularActorCount = (kGroupList.Length) ;Required for loot system
	
			if bBossAllowed && iLosCounter != 25 ;Check again if Boss spawns allowed for this Actors preset and LoS counter hasn't maxed.
				HelperSpawnActorRandomEzSingleLocRandomChildLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
				kBossUnits, kEzList, bApplySwarmBonus, true, iDifficulty, false)
			endif

		endif
		
		iCounter = 0 ;To be sure to be sure.
		iSize = kGroupList.Length 
		;Set Linked refs and Packages. 
		iChildPointElectionTracker.Remove(0) ;Remove the first member used for initialising. 
		
		while iCounter < iSize
			i = iChildPointElectionTracker[iCounter]
			HelperApplyPackageSingleLocData(kGroupList[iCounter], kPackageLocs[i])
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
	
	;GTFO

EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;SPAWN LOOPS - HELPER SCRIPT
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;DEV NOTE: From version 0.20.01 onwards, all Packages are applied after spawning.

Function HelperSpawnActorSingleLocLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, \ 
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
		endif
		
		iCounter +=1
	
	endwhile

EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------

Function HelperSpawnActorRandomEzSingleLocLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, EncounterZone[] akEzList, \
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
			
		endif
		
		iCounter +=1
	
	endwhile

EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------

;The following 2 functions are refactors of the above 2, and used to spread placement of Actors out to ChildPoints. Slower due to randomising the marker 
;to spawn at. These 2 are used by Interiors in order to achieve a relatively even distribution of actors throughout an interior cell. Can optionally 
;"expend" the marker being spawned at, in order to prevent other spawns dropping at the same marker again (will cut group Max Count to number of 
;ChildPoints available if using this option).

Function HelperSpawnActorSingleLocRandomChildLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, EncounterZone akEz, \
Bool abApplySwarmBonus, Bool abIsBossSpawn, Int aiDifficulty, Bool abExpendPoint)

	if (abApplySwarmBonus) && (!abExpendPoint) ;Apply Swarm bonus settings if true AND Not expending ChildPoints, else skip.
	
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
	Int iSpawnLocListSize = (kPackageLocs.Length) - 1 ;Need actual size
	Actor kSpawned
	ObjectReference kSpawnLoc
	Actor kPlayerRef = MasterScript.PlayerRef ;Grab for LoS checks.
	
	;First we must ensure the MaxCount received does not exceed number of ChildPoints, if we expending Points each Spawn.
	if abExpendPoint
		if aiMaxCount > (kPackageLocs.Length)
			aiMaxCount = (kPackageLocs.Length)
		endif
	endif
	
	;Spawn the guaranteed first Actor
	kSpawnLoc = HelperGetChildPoint(abExpendPoint) ;Place at a random marker in the cell/child cell (if exists)
	kSpawned = kSpawnLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, akEz) ;akEz can be None
	kGroupList.Add(kSpawned) ;Add to Group tracker
	
	;Begin chance based placement loop for the rest of the Group
	while iCounter <= aiMaxCount
		
		kSpawnLoc = HelperGetChildPoint(abExpendPoint) ;Place at a random marker in the cell/child cell (if exists)
		
		;Check Line of sight to Player. 
		while kPlayerRef.HasDetectionLos(kSpawnLoc)
			iLosCounter += 1 ;Line of sight fail counter will return this function if hits 25 (2.5 seconds wasted).
			if iLosCounter >= 25 ;Better to check now.
				return ;Stop spawning and kill the function. Player is looking too frequently.
			endif
			Utility.Wait(0.1)
		endwhile
		
		;Else continue to place Actor.	
		if (Utility.RandomInt(1,100)) <= aiChance
			
			kSpawned = kSpawnLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, akEz) ;akEz can be None
			kGroupList.Add(kSpawned) ;Add to Group tracker
			
		endif
		
		iCounter +=1
	
	endwhile

EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------

Function HelperSpawnActorRandomEzSingleLocRandomChildLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, EncounterZone[] akEzList, \
Bool abApplySwarmBonus, Bool abIsBossSpawn, Int aiDifficulty, Bool abExpendPoint)

	if (abApplySwarmBonus) && (!abExpendPoint) ;Apply Swarm bonus settings if true AND Not expending ChildPoints, else skip.
	
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
	Int iSpawnLocListSize = (kPackageLocs.Length) - 1 ;Need actual size
	EncounterZone kEz
	Actor kSpawned
	ObjectReference kSpawnLoc
	Actor kPlayerRef = MasterScript.PlayerRef ;Grab for LoS checks.
	
	;First we must ensure the MaxCount received does not exceed number of ChildPoints, if we expending Points each Spawn.
	if abExpendPoint
		if aiMaxCount > (kPackageLocs.Length)
			aiMaxCount = (kPackageLocs.Length)
		endif
	endif
	
	;Spawn the guaranteed first Actor
	kEz = akEzList[(Utility.RandomInt(0,iEzListSize))] ;Randomise each loop
	kSpawnLoc = HelperGetChildPoint(abExpendPoint) ;Place at a random marker in the cell/child cell (if exists)
	kSpawned = kSpawnLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, kEz) ;kEz can be None
	kGroupList.Add(kSpawned) ;Add to Group tracker
	
	;Begin chance based placement loop for the rest of the Group
	while iCounter <= aiMaxCount
	
		kSpawnLoc = HelperGetChildPoint(abExpendPoint) ;Place at a random marker in the cell/child cell (if exists)
		
		;Check Line of sight to Player. 
		while kPlayerRef.HasDetectionLos(kSpawnLoc)
			iLosCounter += 1 ;Line of sight fail counter will return this function if hits 25 (2.5 seconds wasted).
			if iLosCounter >= 25 ;Better to check now.
				return ;Stop spawning and kill the function. Player is looking too frequently.
			endif
			Utility.Wait(0.1)
		endwhile
		
		;Else continue to place Actor.
		if (Utility.RandomInt(1,100)) <= aiChance
			
			kEz = akEzList[(Utility.RandomInt(0,iEzListSize))] ;Randomise each loop
			kSpawned = kSpawnLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, kEz) ;kEz can be None
			kGroupList.Add(kSpawned) ;Add to Group tracker
			
		endif
		
		iCounter +=1
	
	endwhile

EndFunction


;-----------------------------------------------------------------------------------------------------------------------------------------
;PACKAGE APPLICATION LOOPS - HELPER SCRIPT
;-----------------------------------------------------------------------------------------------------------------------------------------
;DEV NOTE: Same as main script essentially, some parameters removed.


;Used for a multitude of Packages only needing to link to single point, I.E
;Sandbox/Hold, Rush, Interiors (Sandbox)
Function HelperApplyPackageSingleLocData(Actor akActor, ObjectReference akPackageLoc)

	akActor.SetLinkedRef(akPackageLoc, kPackageKeywords[0])
	kPackage.ApplyToRef(akActor) ;Finally apply the data alias with package
	akActor.EvaluatePackage() ;And evaluate so no delay
	
EndFunction


;Links Actor to each ChildPoint, in order specified (optionally starting at a different location in the array), for Patrol.
Function HelperApplyPackagePatrolData(Actor akActor)
	
	;Starts at iStartLoc, loops back if necessary to keep links in order.
	Int iCounter  = iStartLoc
	Int iSize = kPackageLocs.Length
	Int iKeywordCounter = 0
		
	while iCounter < iSize
	
		akActor.SetLinkedRef(kPackageLocs[iCounter], kPackageKeywords[iKeywordCounter])
		;WARNING: Must be as many Keywords defined as ChildPoints
		iCounter += 1
		iKeywordCounter += 1

	endwhile
		
	iCounter = 0
		
	while iCounter < iStartLoc
		
		akActor.SetLinkedRef(kPackageLocs[iCounter], kPackageKeywords[iKeywordCounter])
		;WARNING: Must be as many Keywords defined as ChildPoints
		iCounter += 1
		iKeywordCounter += 1
		
	endwhile
		
	kPackage.ApplyToRef(akActor) ;Finally apply the data alias with package
	akActor.EvaluatePackage() ;And evaluate so no delay	

EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;DISTANCE-BASED AMBUSH FUNCTIONS & EVENTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;Package Mode 3 Handlers.

;In the case of this Helper script, Rush Package will be passed as kPackage. 
Event OnDistanceLessThan(ObjectReference akObj1, ObjectReference akObj2, float afDistance)
;DEV NOTE: Supports Ambush from this script only, no initial checks will take place.
	
	Int iCounter
	Int iSize = kGroupList.Length
	ObjectReference kPlayerRef = MasterScript.PlayerRef ;Possibly faster than Game.GetPlayer()
	
	HelperApplyGroupSneakState() ;Removes sneak state previously set. 
	
	while iCounter < iSize
		HelperApplyPackageSingleLocData(kGroupList[iCounter], kPlayerRef) ;Parameter should have been set above.
		kGroupList[iCounter].SetLinkedRef(Self as ObjectReference, kPackageKeywords[1]) ;Sets sandbox link to spawn loc so if Player escapes, Actors return here. 
		iCounter += 1
	endwhile
	
EndEvent


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;UTILITY FUNCTIONS & EVENTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;Sets all Actors in the Group to start sneaking (or not if called again after).
Function HelperApplyGroupSneakState()
	
	Int iSize
	Int iCounter
	
	while iCounter < iSize
		
		kGroupList[iCounter].StartSneaking()
		iCounter += 1
		
	endwhile
	
EndFunction


;Used from this script in a similar way to the main, but using kPackageLocs passed in array (which will be ChildPoints from main SP).
ObjectReference Function HelperGetChildPoint(Bool abExpendPoint) ;Parameter added in version 0.13.01 tells function to remove point so cannot be used again this session.

	int iSize = kPackageLocs.Length - 1  ;Get random member
	int i = Utility.RandomInt(0,iSize)

	ObjectReference kMarkerToReturn = kPackageLocs[i]  ;Get a direct link to Object in array
	
	if abExpendPoint ;Only expend the Marker if true
	
		if !bChildrenActive ;Initialise if not already
			kActiveChildren = new ObjectReference[0] ;This needs to be watched for bugs mentioned in Master with arrays initialised as empty.
			bChildrenActive = true
		endif
	
		kActiveChildren.Add(kPackageLocs[i]) ;Add selected marker to active array (this array is non-const).
		kPackageLocs.Remove(i) ;Remove from original array, guaranteeing it won't be selected again this session.
		;We will move it back/reset later
		
	else ;We track the index of each elected ChildPoint for later linking of Packages
		iChildPointElectionTracker.Add(i) ;should have been initialised before this function was called. First member of None to be removed later.	
	endif
	
	return kMarkerToReturn ;Return the temp set from earlier
	
EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------
