Scriptname SOTC:SpHelperScript extends ObjectReference
{ Spawnpoint helper script, for multithreading multi-group spawns }
;Written by SMB92
;Special thanks to J. Ostrus [BigandFlabby] for code contributions that made this mod possible.

;Purpose of this script is to be tied to an Activator which will be created in game
;by a "Multi-point Spawnpoint", which will pass parameters to this script and have it
;immediately begin spawning a single group of Actors

;LEGEND - PREFIX CONVENTION
; Variables and Properties are treated the same. Script types do not have prefixes, unless they
;are explicitly received as function arguments and are multi-instance scripts.
; "a" - (Function/Event Blocks only) Variable was received as function argument OR the variable
;was created from a passed-in Struct/Var[] member
; "k" - Is an "Object" as usual, whether created in a Block or defined in the empty state/a state.
; "f,b,i" - The usual Primitives: Float, Bool, Int.

;-------------------------------------------------------------------------------------------------------------------------------------------------------
;PROPERTIES & IMPORTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

import SOTC:Struct_ClassDetails ;Struct definition needs to be present

SOTC:ThreadControllerScript Property ThreadController Auto Const
{ Fill with ThreadController script }

Keyword[] Property kPackageKeywords Auto Const
{ Fill with all Package Keywords. This is set here permanently for convenience }

;Passed in by Parent point
SOTC:RegionQuestScript RegionScript
SOTC:ActorClassPresetScript ActorParamsScript
ReferenceAlias kPackage
ObjectReference[] kPackageLocs

;Local variables
Actor[] kGroupList
Int iHelperFireTimerID = 3 Const

;-------------------------------------------------------------------------------------------------------------------------------------------------------
;SINGLE GROUP SPAWN FUNCTIONS - HELPER SCRIPT
;-------------------------------------------------------------------------------------------------------------------------------------------------------

Function SetHelperSpawnParams(SOTC:RegionQuestScript aRegionScript, SOTC:ActorClassPresetScript aActorParamsScript, \
ReferenceAlias akPackage, ObjectReference[] akPackageLocs)

	RegionScript = aRegionScript
	ActorParamsScript = aActorParamsScript
	kPackage = akPackage
	kPackageLocs = akPackageLocs as ObjectReference[] ;Cast to ensure copy locally.
	
	StartTimer(0.5, iHelperFireTimerID) ;Ready to start own thread

EndFunction


;Start own thread and do work on timer
Event OnTimer(int aiTimerID)

	if aiTimerID == iHelperFireTimerID
		
		ThreadController.ForceAddThreads(1) ;Due to random factor behind spawning groups count, this was included.
		HelperPrepareSingleGroupSpawn()
		
	endif
	
EndEvent


;Main spawning function
Function HelperPrepareSingleGroupSpawn()
;NOTE - Actor is passed in above and set in local variable, cannot get randomly from here.

	SOTC:ActorQuestScript ActorMainScript = ActorParamsScript.ActorScript
	;We'll get this now as it will have to be passed to the loop as well as various other work which makes this essential
	
	;Now we can get the actual spawn parameters
	Int iDifficulty = RegionScript.iCurrentDifficulty ;Set the difficulty level 
	ClassDetailsStruct ActorParams = ActorParamsScript.ClassDetails[iDifficulty] ;Difficulty level is used for presets on Actor Class
	
	;Get the actual ActorBase arrays
	ActorBase[] kRegularUnits = (ActorParamsScript.GetRandomGroupLoadout(false)) as ActorBase[] ;Cast to copy locally
	ActorBase[] kBossUnits
	Bool bBossAllowed = ActorParams.bAllowBoss 
	if bBossAllowed ;Not gonna set this unless it's allowed. Later used as parameter
		kBossUnits = (ActorParamsScript.GetRandomGroupLoadout(true)) as ActorBase[] ;Cast to copy locally
	endif
	
	
	EncounterZone kEz ;iEZMode 1 - Single EZ to use for Group Levels
	EncounterZone[] kEzList; If iEzApplyMode = 2, this will point to a Region list of EZs. One will be applied to each Actor at random.
	
	Int iEzMode = RegionScript.iEzApplyMode ;Store locally for reuse
	
	if iEzMode == 0 ;This exist so we can skip it, seems it is more likely players won't use it.
		;Do nothing, use NONE EZ (passed parameters will be None)
	elseif iEZMode == 1
		kEz = RegionScript.GetRandomEz()
	elseif iEzMode == 2
		kEzList = RegionScript.GetRegionCurrentEzList() ;Look directly at the Regions Ez list, based on current mode
	endif
	
	
	Bool bApplySwarmBonus ;Whether or not Swarm bonuses are applied
	;Now lets roll the dice on it
	if (ActorMainScript.bSupportsSwarm) && (RegionScript.RollForSwarm())
		bApplySwarmBonus = true
	endif
	
	Int iRegularActorCount ;Required for loot system
	
	if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely
			
		HelperSpawnActorLoop(ActorParams.iMaxAllowed, ActorParams.iChance, kRegularUnits, \
		kEz, bApplySwarmBonus, ActorMainScript, false, iDifficulty)
		
		iRegularActorCount = kGroupList.Length ;Required for loot system
			
		if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
			HelperSpawnActorLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
			kBossUnits, kEz, bApplySwarmBonus, ActorMainScript, true, iDifficulty)
		endif


	else ;Randomise the Ez

		HelperSpawnActorRandomEzLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
		kRegularUnits, kEzList, bApplySwarmBonus, ActorMainScript, false, iDifficulty)
		
		iRegularActorCount = kGroupList.Length ;Required for loot system
		
		if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
			HelperSpawnActorRandomEzLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
			kBossUnits, kEzList, bApplySwarmBonus, ActorMainScript, true, iDifficulty)
		endif
			
	endif
	
	Int iBossCount = (kGroupList.Length) - iRegularActorCount ;Also required for loot system
	
	;Now check the loot system and do the loot pass if applicable. We do this post spawn as to avoid unnecessary perfromace impact on spawnloops
	;NOTE - Helper script can only get loot for Actors, NOT from the SpawnType (it has no access to that script)
	
	if ActorMainScript.bLootSystemEnabled
		ActorMainScript.DoLootPass(kGroupList, iBossCount)
	endif

	
	;Lastly, we tell Increment the Active NPC and SP on the Thread Controller
	ThreadController.IncrementActiveNpcCount(kGroupList.Length)
	ThreadController.IncrementActiveSpCount(1)
	
	;GTFO

EndFunction

;DEV NOTE: We could look at determining the Group Max Count first instead of taking it through a chance loop as is below.

;-------------------------------------------------------------------------------------------------------------------------------------------------------
;SPAWN LOOPS - HELPER SCRIPT
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;Regular, local, single group spawn loop
Function HelperSpawnActorLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, EncounterZone akEz, \
Bool abApplySwarmBonus, SOTC:ActorQuestScript aActorMainScript, Bool abIsBossSpawn, Int aiDifficulty)

	if abApplySwarmBonus ;Apply Swarm bonus settings if true, else skip
	
		if abIsBossSpawn ;Checking if Boss first, possibly faster to switch check order here?
			aiMaxCount += aActorMainScript.iSwarmMaxCountBonus
			aiChance += aActorMainScript.iSwarmChanceBonus
		else
			aiMaxCount += aActorMainScript.iSwarmMaxCountBossBonus
			aiChance += aActorMainScript.iSwarmChanceBossBonus
		endif
		
	endif
	
	kGroupList = new Actor[0]
	
	Int iCounter = 1 ;Guarantee the first Actor
	Int iActorListSize = (akActorList.Length) - 1
	
	;Place the first Actor
	Actor akSpawned = Self.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, akEz) ;akEz can be None
	kGroupList.Add(akSpawned) ;Add to Group tracker
	HelperApplyPackageData(akSpawned)
	;Chance loop for the rest of the Group
	while iCounter != aiMaxCount ;Loop through to maximum amount allowed
	
		if (Utility.RandomInt(1,100)) < aiChance ;Makes group size dynamic by giving each member a Chance
			
			akSpawned = Self.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, akEz) ;akEz can be None
			kGroupList.Add(akSpawned) ;Add to Group tracker
			HelperApplyPackageData(akSpawned) ;Apply package from the Alias
			
		endif
		
		iCounter +=1
	
	endwhile

EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------

;Regular, local, single group spawn loop, Randomise EZs
Function HelperSpawnActorRandomEzLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, EncounterZone[] akEzList, \
Bool abApplySwarmBonus, SOTC:ActorQuestScript aActorMainScript, Bool abIsBossSpawn, Int aiDifficulty)

	if abApplySwarmBonus ;Apply Swarm bonus settings if true, else skip
	
		if abIsBossSpawn ;Checking if Boss first, possibly faster to switch check order here?
			aiMaxCount += aActorMainScript.iSwarmMaxCountBonus
			aiChance += aActorMainScript.iSwarmChanceBonus
		else
			aiMaxCount += aActorMainScript.iSwarmMaxCountBossBonus
			aiChance += aActorMainScript.iSwarmChanceBossBonus
		endif
		
	endif
	
	kGroupList = new Actor[0]
	
	Int iCounter = 1 ;Guarantee the first Actor
	Int iEzListSize = (akEzList.Length) - 1
	Int iActorListSize = (akActorList.Length) - 1
	EncounterZone kEz
	
	;Place the first Actor
	kEz = akEzList[(Utility.RandomInt(0,iEzListSize))] ;Random EZ
	Actor kSpawned = Self.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, kEz) ;kEz can be None
	kGroupList.Add(kSpawned) ;Add to Group tracker
	HelperApplyPackageData(kSpawned)
	;Chance loop for the rest of the group
	while iCounter != aiMaxCount
	
		kEz = akEzList[(Utility.RandomInt(0,iEzListSize))] ;Randomise each loop
	
		if (Utility.RandomInt(1,100)) < aiChance
			
			kSpawned = Self.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, kEz) ;kEz can be None
			kGroupList.Add(kSpawned) ;Add to Group tracker
			HelperApplyPackageData(kSpawned) ;Apply package from the Alias
			
		endif
		
		iCounter +=1
	
	endwhile

EndFunction

;Apply the package stored on alias
Function HelperApplyPackageData(Actor akActor)

	Int iCounter
	Int iSize = kPackageLocs.Length
		
	while iCounter < iSize
			
		akActor.SetLinkedRef(kPackageLocs[iCounter], kPackageKeywords[iCounter])
		iCounter += 1
	
	endwhile
	
	kPackage.ApplyToRef(akActor) ;Finally apply the data alias with package
	akActor.EvaluatePackage() ;And evaluate so no delay
	
EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;CLEANUP FUNCTIONS - HELPER SCRIPT
;-------------------------------------------------------------------------------------------------------------------------------------------------------

Function HelperFactoryReset()

	HelperCleanupActorRefs()
	;NOTE: The following could be done right after spawning if desired.
	RegionScript = None
	ActorParamsScript = None
	kPackage = None
	kPackageLocs.Clear()
	ThreadController.IncrementActiveSpCount(-1)

EndFunction


;Cleans up all Actors in GroupList
Function HelperCleanupActorRefs() ;Decided to pass the package in here. 

	int iCounter = 0
	int iSize = kGroupList.Length
	int iActorCount = iSize ;This is for incrementing ActorCount on ThreadController
        
	while iCounter < iSize

		kPackage.RemoveFromRef(kGroupList[iCounter]) ;Remove package data. Perhaps not necessary either?
		;NOTE; Removed code that removes linked refs. Unnecesary
		kGroupList[iCounter].DeleteWhenAble()
		iCounter += 1
	
	endwhile
	
	kGroupList.Clear()
	ThreadController.IncrementActiveNpcCount(-iActorCount)
	
EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------