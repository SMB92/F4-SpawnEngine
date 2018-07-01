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

import SOTC:Struct_ClassDetails ;Struct definition needs to be present

SOTC:MasterQuestScript MasterScript ;Pretty much only used here to get PlayerRef, assuming faster than Game.GetPlayer(). May see expanded use in future.
SOTC:ThreadControllerScript ThreadController

Keyword[] kPackageKeywords
;{ Fill with all Package Keywords. This is set here permanently for convenience }

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

Int iStartLoc ;Pretty much only used for Patrol mode from this script, to set the link order correctly.

;Local variables
Actor[] kGroupList
Int iLosCounter ;This will be incremented whenever a Line of sight check to Player fails. If reaches 25, spawning aborts. As we at least spawn 1 actor
;to start with, this remains safe to use (however Player may see that one actor being spawned. its just easier to live with). 
Int iHelperFireTimerID = 3 Const

;DEV NOTE: The Helper does have the ability to "expend" ChildPoints, however this should be seldom used.
ObjectReference[] kActiveChildren ;Temp list of all child markers used to delegate spawns to
Bool bChildrenActive ;This will be checked and save reinitializing above array later.



;-------------------------------------------------------------------------------------------------------------------------------------------------------
;INITIALISATION FUNCTIONS & EVENTS - HELPER SCRIPT
;-------------------------------------------------------------------------------------------------------------------------------------------------------

Function SetHelperSpawnParams(SOTC:RegionManagerScript aRegionManager, SOTC:ActorClassPresetScript aActorParamsScript, Int aiPackageMode, \
ReferenceAlias akPackage, Keyword[] akPackageKeywords, ObjectReference[] akPackageLocs, Bool abSpreadSpawns, Int aiPreset, Int aiDifficulty, Int aiStartLoc = 0)
;Int aiStartLoc was added in version 0.13.01 for Patrol packages. Starts the Group linking at the ChildPoint they spawned at so they still patrol in the 
;expected order (ChildPoint for patrols should be listed in the order of the route). Also doubles as Distance for Package Mode 3 Ambush. 
	
	
	RegionManager = aRegionManager
	MasterScript = RegionManager.MasterScript
	ThreadController = RegionManager.ThreadController ;Done this way to free up a parameter slot. 
	ActorParamsScript = aActorParamsScript
	iPackageMode = aiPackageMode
	kPackage = akPackage
	kPackageKeywords = akPackageKeywords
	kPackageLocs = akPackageLocs as ObjectReference[] ;Cast to ensure copy locally.
	bSpreadSpawnsToChildPoints = abSpreadSpawns
	iPreset = aiPreset ;Preset is passed from Spawntype script as it can be configured to be different from Region.
	iDifficulty = aiDifficulty
	
	iStartLoc = aiStartLoc ;Pretty much only used for Patrol mode from this script, to set the link order correctly. 
	
	StartTimer(0.2, iHelperFireTimerID) ;Ready to start own thread

EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;CLEANUP FUNCTIONS & EVENTS - HELPER SCRIPT
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;The owning SpawnPoint will delete this isntance when the following has returned. 

Function HelperFactoryReset()

	HelperCleanupActorRefs()
	
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

		kPackage.RemoveFromRef(kGroupList[iCounter]) ;Remove package data. Perhaps not necessary either?
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
	
	;Organise the ActorBase arrays
	;------------------------------
	
	ActorBase[] kRegularUnits = (ActorParamsScript.GetRandomGroupLoadout(false)) as ActorBase[] ;Cast to copy locally
	ActorBase[] kBossUnits
	Bool bBossAllowed = (ActorParams.iChanceBoss) as Bool
	if bBossAllowed ;Not gonna set this unless it's allowed. Later used as parameter
		kBossUnits = (ActorParamsScript.GetRandomGroupLoadout(true)) as ActorBase[] ;Cast to copy locally
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
	if (ActorManager.bSupportsSwarm) && (RegionManager.RollForSwarm())
		bApplySwarmBonus = true
	endif
	
	
	;Finally, start the correct Spawn Loop for the Package Mode selected.
	;--------------------------------------------------------------------
	
	Int iRegularActorCount ;Required for loot system
	
	if iPackageMode == 0 ;Sandbox/Hold (Single Loc with Package applied in loop)
	
		if !bSpreadSpawnsToChildPoints ;More likely false
	
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
		
;-------------------------------------------------------------------------------------------------------------------------------------------------------
	
	elseif (iPackageMode < 4) ;Travel/Patrol/Ambush (Distance-to-Player based event), can assume above failed.
	
	
		if (!bSpreadSpawnsToChildPoints) || (iPackageMode == 2)	;More likely false, unsupported for Patrols. 
			
			if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely
					
				HelperSpawnActorNoPackageLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
				kRegularUnits, kEz, bApplySwarmBonus, false, iDifficulty)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system
					
				if bBossAllowed && iLosCounter != 25 ;Check again if Boss spawns allowed for this Actors preset and LoS counter hasn't maxed.
					HelperSpawnActorNoPackageLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEz, bApplySwarmBonus, true, iDifficulty)
				endif

			else ;Randomise the Ez

				HelperSpawnActorRandomEzNoPackageLoop(ActorParams.iMaxAllowed, ActorParams.iChance, kRegularUnits, \
				kEzList, bApplySwarmBonus, false, iDifficulty)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system
					
				if bBossAllowed && iLosCounter != 25 ;Check again if Boss spawns allowed for this Actors preset and LoS counter hasn't maxed.
					HelperSpawnActorRandomEzNoPackageLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEzList, bApplySwarmBonus, true, iDifficulty)
				endif

			endif
			
			
		else ;Assume true and Package Mode 1/3. 
		
			if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely
					
				HelperSpawnActorNoPackageRandomChildLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
				kRegularUnits, kEz, bApplySwarmBonus, false, iDifficulty, false)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system
					
				if bBossAllowed && iLosCounter != 25 ;Check again if Boss spawns allowed for this Actors preset and LoS counter hasn't maxed.
					HelperSpawnActorNoPackageRandomChildLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEz, bApplySwarmBonus, true, iDifficulty, false)
				endif

			else ;Randomise the Ez

				HelperSpawnActorRandomEzNoPackageRandomChildLoop(ActorParams.iMaxAllowed, ActorParams.iChance, kRegularUnits, \
				kEzList, bApplySwarmBonus, false, iDifficulty, false)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system
					
				if bBossAllowed && iLosCounter != 25 ;Check again if Boss spawns allowed for this Actors preset and LoS counter hasn't maxed.
					HelperSpawnActorRandomEzNoPackageRandomChildLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEzList, bApplySwarmBonus, true, iDifficulty, false)
				endif

			endif
			
		endif
	
		;Finally, set the Package on all actors in quick succession.
		;------------------------------------------------------------
		
		if iPackageMode == 1 
			
			iSize = kGroupList.Length
			while iCounter < iSize
				HelperApplyPackageTravelData(kGroupList[iCounter])
				iCounter += 1
			endwhile
				
		elseif iPackageMode == 2

			;Apply loop
			iSize = kGroupList.Length
			while iCounter < iSize
				HelperApplyPackagePatrolData(kGroupList[iCounter])
				iCounter += 1
			endwhile
			
		elseif iPackageMode == 3
		
			RegisterForDistanceLessThanEvent((Game.GetPlayer()) as ObjectReference, Self as ObjectReference, iStartLoc as Float) ;No access to Master DX
				
		endif
	
;-------------------------------------------------------------------------------------------------------------------------------------------------------

	elseif iPackageMode == 4 ;Interior Mode
	;DEV NOTE: Package application for Interior Mode must be done during Spawn loop, same as Sandbox/Hold Mode. Uses SpawnActorSingleLocRandomChildLoop()
	;DEV NOTE 2: Interior Mode does not Expend ChildPoints by design. 
	
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
;DISTANCE-BASED AMBUSH FUNCTIONS & EVENTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;Package Mode 3 Handlers.

;In the case of this Helper script, Rush Package will be passed as kPackage. 
Event OnDistanceLessThan(ObjectReference akObj1, ObjectReference akObj2, float afDistance)
;DEV NOTE: Supports Ambush from this script only, no initial checks will take place.
	
	Int iCounter
	Int iSize = kGroupList.Length
	ObjectReference kPlayerRef = MasterScript.PlayerRef ;Possibly faster than Game.GetPlayer()
	
	while iCounter < iSize
		HelperApplyPackageSingleLocData(kGroupList[iCounter], kPlayerRef) ;Parameter should have been set above.
		iCounter += 1
	endwhile
	
EndEvent


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;SPAWN LOOPS - HELPER SCRIPT
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;DEV NOTE 2: From this point on, things can get confusing quick as some functions are reused for some Package Modes and are mixed and matched. 
;Basically the MultiPoint works like this:
; - Sandbox/Hold use HelperSpawnActorSingleLocLoop, which uses HelperApplyPackageSingleLocData() during loop.
; - Travel Package and Patrol Package use same SpawnLoop, but both have their own Package loops.
; - Interior Mode uses HelperSpawnActorSingleLocRandomChildLoop, which uses HelperApplyPackageSingleLocData() (during the SpawnLoop).


;SINGLE LOCATION LOOPS W/ PACKAGE APPLICATION INCLUDED ("SingleLoc" refers to the type of Package Application really)
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;DEV NOTE: kPackage/ApplyData is applied DURING these Spawn loops, as this allows each Actor to get comfortable first (i.e Sandbox/Hold). It also somewhat
;prevents the user from seeing a mob huddled together when first starting sandboxing. 

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
			HelperApplyPackageSingleLocData(kSpawned, Self)
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
			HelperApplyPackageSingleLocData(kSpawned, Self)
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
	HelperApplyPackageSingleLocData(kSpawned, kSpawnLoc)
	
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
			HelperApplyPackageSingleLocData(kSpawned, kSpawnLoc)
			
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
	HelperApplyPackageSingleLocData(kSpawned, kSpawnLoc)
	
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
			HelperApplyPackageSingleLocData(kSpawned, kSpawnLoc)
			
		endif
		
		iCounter +=1
	
	endwhile

EndFunction



;PACKAGELESS LOOPS - USE FOR TRAVEL/PATROL/STATIC PLACEMENT
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;DEV NOTE: These loops do not apply any package, they simply drop the Actor. It is expected the calling function will run ApplyPackage loop after this.

Function HelperSpawnActorNoPackageLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, \ 
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

Function HelperSpawnActorRandomEzNoPackageLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, \ 
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

;-------------------------------------------------------------------------------------------------------------------------------------------------------

;The following 2 functions are refactors of the above 2, and used to spread placement of Actors out to ChildPoints. Slower due to randomising the marker 
;to spawn at. Can optionally "expend" the marker being spawned at, in order to prevent other spawns dropping at the same marker again (will cut group Max
;Count to number of ChildPoints available if using this option).
 
Function HelperSpawnActorNoPackageRandomChildLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, \
EncounterZone akEz, Bool abApplySwarmBonus, Bool abIsBossSpawn, Int aiDifficulty, Bool abExpendPoint)
	
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
	Actor kSpawned
	ObjectReference kSpawnLoc
	Actor kPlayerRef = MasterScript.PlayerRef ;Grab for LoS checks.
	
	;First we must ensure the MaxCount received does not exceed number of ChildPoints, if we expending Points each Spawn.
	if abExpendPoint
		
		if aiMaxCount > (kPackageLocs.Length)
			aiMaxCount = (kPackageLocs.Length)
		endif
	endif
	
	;Spawn the first guaranteed Actor
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

Function HelperSpawnActorRandomEzNoPackageRandomChildLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, \ 
EncounterZone[] akEzList, Bool abApplySwarmBonus, Bool abIsBossSpawn, Int aiDifficulty, Bool abExpendPoint) ;Worlds Best function type.

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
	Actor kSpawned
	ObjectReference kSpawnLoc
	EncounterZone kEz
	Actor kPlayerRef = MasterScript.PlayerRef ;Grab for LoS checks.
	
	;First we must ensure the MaxCount received does not exceed number of ChildPoints, if we expending Points each Spawn.
	if abExpendPoint
		
		if aiMaxCount > (kPackageLocs.Length)
			aiMaxCount = (kPackageLocs.Length)
		endif
	endif
	
	;Spawn the first guaranteed Actor
	kSpawnLoc = HelperGetChildPoint(abExpendPoint) ;Place at a random marker in the cell/child cell (if exists)
	kSpawned = kSpawnLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, kEz) ;akEz can be None
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
			kSpawned = kSpawnLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, kEz) ;akEz can be None
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


;Link Actor to travel locs and send on their merry way
Function HelperApplyPackageTravelData(Actor akActor)
	
	Int iCounter
	Int iSize = kPackageLocs.Length
		
	while iCounter < iSize
			
		akActor.SetLinkedRef(kPackageLocs[iCounter], kPackageKeywords[iCounter])
		iCounter += 1
		
	endwhile

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
;UTILITY FUNCTIONS & EVENTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

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
	
		kActiveChildren.Add(kPackageLocs[i]) ;Add selected marker to active array
		kPackageLocs.Remove(i) ;Remove from original array, guaranteeing it won't be selected again this session.
		;We will move it back/reset later
		;DEV NOTE: This works on Array Properties that are non-const only.
	endif
	
	return kMarkerToReturn ;Return the temp set from earlier
	
EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------
