Scriptname SOTC:SpGroupScript extends ObjectReference
{ Main Spawnpoint script, attached to Activator (preconfigured per Region or custom instance) }
;Written by SMB92
;Special thanks to J. Ostrus [BigandFlabby] for code contributions that made this mod possible.

;Primary/Main Spawnpoint script. This will be the most common instance used in the mod. 

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

Group RelevantScriptLinks
{ Links to relevant Master and Global scripts }

	SOTC:MasterQuestScript Property MasterScript Auto Const
	{ Fill with Master Script }

	SOTC:ThreadControllerScript Property ThreadController Auto Const
	{ Fill with ThreadController script }

	SOTC:RegionQuestScript Property RegionScript Auto Const
	{ Fill with this Region's Master Script }
	
	SOTC:RegionTrackerScript Property CleanupManager Auto Const
	{ Fill with RefAlias attached to above RegionQuest }
	
	SOTC:SpawnTypeRegionalScript Property SpawnTypeScript Auto Const
	{ Fill with desired Spawntype script for this Region }
	;LEGEND - SPAWNTYPES (REGIONAL)
	; [0] - MAIN RANDOM

EndGroup


Group PrimaryProperties
{ Critical Properties defining this Spawnpoint }

	Int Property iChanceToFire Auto Const
	{ Use this define an extra chance/dice roll for this SP or set 100 for always }

	ReferenceAlias Property kPackage Auto Const
	{ Fill with the desired package }
	
	ReferenceAlias Property kPackageAmbush Auto Const Mandatory
	{ Fill with SOTC_AmbushPackageRandom01. This gets filled the same on EVERY instance of this marker. }
	
	;LEGEND - PACKAGE TYPES (ALL)
	; [0] - TRAVEL - RANDOM SPAWN (2 RANDOM LOCATIONS)
	; [1] - SANDBOX AND GUARD
	; [2] - HOLD POSITION/SNIPER
	; [3] - PATROL (USE CUSTOM LOC MARKERS, NOT IDLE MARKERS)

	Keyword[] Property kPackageKeywords Auto Const
	{ Fill with as many package keywords as needed (even if just 1). Used for linking to package marker(s) }
	
	Int Property iNumPackageLocs Auto Const
	{ Set 0 to use Self as Package location, or set to number of locations expected by the Package set above }
	
	Bool Property bTravelling Auto Const
	{ If Package is travelling, set True }

	Bool Property bAllowVanilla Auto Const
	{ Set true if only wanting this point to be allowed in Vanilla Mode }

	Int Property iPresetRestriction Auto Const
	{ Fill this (1-3) if it is desired to restrict this point to a certain Master preset level }
	
	Int Property iRarityOverride Auto ;Left auto in case we might want to manipulate later
	{ Fill this 1-3, if wanting to force grab a certain "rarity" of actor }
	
	Bool Property bIsMultiPoint Auto Const
	{ Set true if using child markers to randomise placement of groups. DO NOT USE IN CONFINED SPACES }
	;WARNING: DO NOT USE MULTIPOINTS IN CONFINED SPACES WITH SPAWNTYPES THAT HAVE OVERSIZED ACTORS - USE MULTIPLE SINGLE POINTS INSTEAD

	Bool Property bIsInteriorPoint Auto Const
	{ Set true if interior cell, will behave differently with child markers }
	
	Bool Property bIsConfinedSpace Auto Const
	{ If the SP is placed in a confined area, set True so Oversized Actors will not spawn here.
	And yes, this is required for interiors as not all interiors are confined. }

	Activator Property kMultiPointHelper Auto Const
	{ Fill with generic helper script object to instance if bMultiPoint is true, other wise None }
	;NOTE: This will have to be cast to it's script type in functions, after creation

	ObjectReference[] Property kChildMarkers Auto ;AUTO so can be modified at runtime
	{ If using child markers, fill with these from render window, or initialise with one member of None.
	This can also be used to set up a separate package location(s) from this SPs location. }
	
	Int Property iThreadsRequired Auto
	{ Fill with a score value of 1 - 3, depending how busy this point is expected to be }
	;NOTE: Will be released immediately if Master intercepts for a Random Event

EndGroup

;LEGEND - HOW PACKAGES WORK (MAIN SPAWNPOINT)
;Basically there are 2 types of Packages - Travel and Non Travel
;However, Multigroup spawns are only given ONE destination to travel as to emulate an imminent battle.
; SINGLE GROUP MODE:
; FOR NON TRAVEL PACKAGES:
; 1. 1. Set iNumPackageLocs to number of Locations defined on the filled Alias Property's Package.
;This will usually be 0 and will use this marker (self) as the location. Set bTravelling False
;2. IF above is anything other than 0, define Package loc markers in the kChildMarkers array. This array
;serves dual purposes, in Multigroup mode it holds spawn locations around this marker (self).
; FOR TRAVEL PACKAGES (Supported by Moth SIngle/Multi Point modes):
; 1. Set iNumPackageLocs to number of Locations defined on the filled Alias Property's Package
; 2. Set bTravelling to true. This will cause the ApplyPackageData function to NOT look at the
;kChildMarkers array, but instead get a random list of destinations from the RegionScript
; MULTI GROUP MODE - MUST HAVE SINGLE TRAVEL LOC PACKAGE SET
;Multigroup spawns are deliberately designed to create spawning "battles", therefore they are all given
;a single travel destination so they will run into each other. All other Package parameters will be
;ignored, however the script will still get a random location marker from the RegionScript. Survivors
;will still go to their destination and Sandbox there. 
; MULTI POINT HELPER SCRIPT:
;Although the Multigroup spawn mode/functions on the main SP script are designed to only have one travel
;location, the "Multigroup Helper Object/Script" is actually less specific and therefore more flexible.
;The Helper code only looks at the size of the passed in kPackageLocs array when applying linked refs to
;Actors spawned, therefore it is possible to use this elsewhere/pass in a multi-location sandbox package. 
;It is imperative that the passed-in kPackageLocs have equal number of members to the number of locations 
;defined on the passed-in package.
; RANDOM AMBUSH PACKAGE (Single Group Mode ONLY)
;It is possible to allow a random chance that a single spawned group come directly after the player. Not
;the same as the as the more specific SpAmbushPointScript however, but entirely optional (defined on a per
;Region basis). This package is defined on every SpGroupPointScript, and will simply send the group running
;from their spawned location straight to the player where they will likely engage in combat. Survivors will
;return to the original spawnpoint location and sandbox a wide area. There is also a setting defined on each
;ActorQuestScript for each Actor that can define/turn them friendly to player, preventing this feature from
;ever occurring on a known friendly Actor/faction group.


;------------------------------------------------------------------------------------------------------------

;--------------
;TempVariables
;--------------

;TimerIDs
Int iStaggerStartupTimerID = 1 Const
Int iSpCooldownTimerID = 2 Const

Bool bSpawnpointActive ;Condition check. Once SP is activated this is set true.

ActorClassPresetScript ActorParamsScript
;NOTE: We never get the ActorQuestScript, we go straight for the Class in order to get parameters.
;The GetRandomActor(s) function on the SpawnTypeRegionalScript returns this. 

Actor[] kGrouplist ;Stores all Actors spawned on this instance

;Multipoint variables
ObjectReference[] kActiveChildren ;Temp list of all child markers used to delegate spawns to
Bool bChildrenActive ;This will be checked and save reinitializing above array later.
ObjectReference[] kActiveHelpers ;Actual SpawnHelper instances placed at child markers

;Spawn Info, listed in expect order of setting. Not all are required, depending on SpawnType etc
Bool bRandomiseEZs ;Used in spawn loop to check if random EZ needs to be randomised (iEzApplyMode = 2)

Bool bApplyAmbushPackage ;Quick flag is Random Ambush mode has been enabled
;Was placed into empty state due to needing to check which package to remove at cleanup time.


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
		if (!Self.IsDisabled()) && (!bSpawnpointActive) ;INITAL CHECK
		;Check if we are enabled, currently running
		
			;NOTE: Master and Regional checks are done before GetThread, so it is possible for an event to intercept before ThreadController can deny
			;Events are usually exempt from ThreadController checks, although they do count towards any of the limits.
		
			;Master Level checks/intercepts
			if MasterScript.MasterSpawnCheck(Self as ObjectReference, bAllowVanilla) ;MASTER CHECK: If true, denied
				;Master script assuming control, kill this thread and disable
				Self.Disable()
				CleanupManager.AddSpentPoint(Self as ObjectReference) ;All points can be added by Object rather than script type				
				return
			endif
			
			;Region Level checks/intercept
			;NOTE - This will send in local spawn parameters if no intercept takes place.
			if RegionScript.RegionSpawnCheck(Self as ObjectReference, iPresetRestriction) ;REGION CHECK: If true, denied
				;Region script assuming control, kill this thread and disable
				Self.Disable()
				CleanupManager.AddSpentPoint(Self as ObjectReference) ;All points can be added by Object rather than script type
				return
			endif
			
			if (SpawnTypeScript.bSpawnTypeEnabled) && (ThreadController.GetThread(iThreadsRequired)) && \
			((Utility.RandomInt(1,100)) < iChanceToFire) ;LOCAL CHECK
				PrepareLocalSpawn() ;Do Spawning
				ThreadController.ReleaseThreads(iThreadsRequired) ;We're done here. Free this thread.
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

Function PrepareLocalSpawn() ;Determine how we need to proceed

	if bIsInteriorPoint ;Distributes the group across different parts of the Interior
	;NOTE - Master Random Events framework can spawn in Interiors UNLESS it is coded not to.
		if (Self as ObjectReference).GetCurrentLocation().IsCleared()
			PrepareInteriorSpawn()
		else ;Nip it in the bud
			ThreadController.ReleaseThreads(iThreadsRequired)
			Self.Disable()
			StartTimer(ThreadController.iSpCooldownTimerClock, iSpCooldownTimerID)
		endif
		
	elseif bIsMultiPoint ;Uses helper objects to create multi group spawns
	
		PrepareMultiGroupSpawn()
		
	else ;Start a regular spawn at this marker
	
		PrepareSingleGroupSpawn()
	
	endif
	
	Self.Disable()
	bSpawnpointActive = true
	CleanupManager.AddSpentPoint(Self as ObjectReference) ;All points can be added by Object rather than script type
	;Cleanup will be handled by the CleanupManager upon Region reset timer firing.
	ThreadController.ReleaseThreads(iThreadsRequired) ;Spawning done, threads can be released.
	;NOTE - Thinking of implementing 2 other options on ThreadController - one for Max active SPs and max number of NPCs
	
EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------
;CLEANUP FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;NOTE - We should not have to remove linked refs as only Marker remains persistent
;NOTE - Remove Alias Data regardless.

;Cleanup all active data produced by this SP
Function FactoryReset()

	if bIsMultiPoint ;No groups stored here.
		CleanupHelperRefs()
		ResetChildMarkers()
		
	else ;Single and Interior modes can both use this.
		if bApplyAmbushPackage ;Properly check this value.
			CleanupActorRefs(kPackageAmbush)
		else
			CleanupActorRefs(kPackage)
		endif
		
	endif
	
	ThreadController.IncrementActiveSpCount(-1)

EndFunction
 
 
;Cleans up all Actors in GroupList
Function CleanupActorRefs(ReferenceAlias akPackage) ;Decided to pass the package in here. 

	int iCounter = 0
	int iSize = kGroupList.Length
        
	while iCounter < iSize

		akPackage.RemoveFromRef(kGroupList[iCounter]) ;Remove package data. Perhaps not necessary either?
		;NOTE; Removed code that removes linked refs. Unnecesary
		kGroupList[iCounter].DeleteWhenAble()
		iCounter += 1
	
	endwhile
	
	ThreadController.IncrementActiveNpcCount(-iSize)
	kGroupList.Clear()
	
EndFunction


;Commands any Helper instances to begin Cleanup
Function CleanupHelperRefs()

	int iCounter = 0
	int iSize = kActiveHelpers.Length
	
	while iCounter < iSize
	
		(kActiveHelpers[iCounter] as SOTC:SpHelperScript).HelperFactoryReset() ;Possibly better to use a variable instead?
		kActiveHelpers[iCounter].DeleteWhenAble()
		iCounter += 1
		
	endwhile

	kActiveHelpers.Clear()
	
EndFunction


;Revert the ChildMarker arrays back to normal
Function ResetChildMarkers()

	int iCounter = 0
	int iSize = kActiveChildren.Length
	
	while iCounter < iSize
	
		kChildMarkers.Add(kActiveChildren[iCounter]) ;Add it back from the active list
		iCounter += 1
		
	endwhile
	
	kActiveChildren.Clear() ;Then empty it
	
EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------
;SINGLE GROUP SPAWN EVENTS & FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

Function PrepareSingleGroupSpawn()
	
	;Get a random Actor, pulling the ClassPresetScript directly.
	if iRarityOverride > 0 && iRarityOverride < 4 ;Security measure, cannot get rarity outside 1-3
		ActorParamsScript = SpawnTypeScript.GetRandomActor(True, iRarityOverride) ;ActorClassPresetType
	else 
		ActorParamsScript = SpawnTypeScript.GetRandomActor(false, 0)
	endif
	
	;Create direct links to ActorQuestScript and ClassDetailsStruct
	
	SOTC:ActorQuestScript ActorMainScript = ActorParamsScript.ActorScript
	;We'll get this now as it will have to be passed to the loop as well as various other work which makes this essential
	
	;Now we'll check if we are in a confined space and Actor is oversized
	while (bIsConfinedSpace) && (ActorMainScript.bIsOversizedActor)
		if iRarityOverride > 0 && iRarityOverride < 4 ;Security measure, cannot get rarity outside 1-3
			ActorParamsScript = SpawnTypeScript.GetRandomActor(True, iRarityOverride) ;ActorClassPresetType
		else 
			ActorParamsScript = SpawnTypeScript.GetRandomActor(false, 0)
		endif
		ActorMainScript = ActorParamsScript.ActorScript
	endwhile
		
	;Now we can get the actual spawn parameters
	Int iDifficulty = RegionScript.iCurrentDifficulty ;Set the difficulty level 
	ClassDetailsStruct ActorParams = ActorParamsScript.ClassDetails[iDifficulty] ;Difficulty level is used for presets on Actor Class

	;The variable names here should be so confusing by your now head is caved in
	
	;Get the actual ActorBase arrays
	ActorBase[] kRegularUnits = (ActorParamsScript.GetRandomGroupLoadout(false)) as ActorBase[] ;Cast to copy locally
	ActorBase[] kBossUnits
	Bool bBossAllowed = ActorParams.bAllowBoss 
	if bBossAllowed ;Not gonna set this unless it's allowed. Later used as parameter
		kBossUnits = (ActorParamsScript.GetRandomGroupLoadout(true)) as ActorBase[] ;Cast to copy locally
	endif
	
	;Check and setup EncounterZone data
	
	EncounterZone kEz ;iEZMode 1 - Single EZ to use for Group Levels
	EncounterZone[] kEzList; If iEzApplyMode = 2, this will point to a Region list of EZs. One will be applied to each Actor at random.
	
	Int iEzMode = RegionScript.iEzApplyMode ;Store locally for reuse
	if iEzMode == 0 ;This exist so we can skip it, seems it is more likely players won't use it.
		;Do nothing, use NONE EZ (passed parameters will be None)
	elseif iEZMode == 1
		kEz = RegionScript.GetRandomEz()
	elseif iEzMode == 2
		kEzList = RegionScript.GetRegionCurrentEzList() ;Look directly at the Regions Ez list, based on current mode.
	endif
	
	;Check for bonus events/setup Package locations if necessary
	
	Bool bApplySwarmBonus ;Whether or not Swarm bonuses are applied
	;Now lets roll the dice on it
	if (ActorMainScript.bSupportsSwarm) && (RegionScript.RollForSwarm())
		bApplySwarmBonus = true
	endif
	
	ObjectReference[] kPackageLocs = new ObjectReference[0] ;Create it, because even if we skip it, it still has to be passed to loop
	
	;Roll dice on Random AMbush feature
	if (!ActorMainScript.bIsFriendlyNeutralToPlayer) && (RegionScript.RollForAmbush()) ;Supported for all Actor types
		bApplyAmbushPackage = true
	endif
	
	;Check if we are ambushing, if not, check if we traveling and need locations
	if (!bApplyAmbushPackage) && (bTravelling)
		kPackageLocs = RegionScript.GetRandomTravelLocs(iNumPackageLocs) ;Should I cast to copy locally seem the function will clear it? 
	endif
	
	;Finally, begin loops.

	Int iRegularActorCount ;Required for loot system
	
	if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely
			
		SpawnActorLoop(ActorParams.iMaxAllowed, ActorParams.iChance, kRegularUnits, kEz, \
		bApplySwarmBonus, ActorMainScript, kPackageLocs, false, iDifficulty)
		
		iRegularActorCount = (kGroupList.Length) ;Required for loot system
			
		if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
			SpawnActorLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, kBossUnits, \
			kEz, bApplySwarmBonus, ActorMainScript, kPackageLocs, true, iDifficulty)
		endif

	else ;Randomise the Ez

		SpawnActorRandomEzLoop(ActorParams.iMaxAllowed, ActorParams.iChance, kRegularUnits, \
		kEzList, bApplySwarmBonus, ActorMainScript, kPackageLocs, false, iDifficulty)
		
		iRegularActorCount = (kGroupList.Length) ;Required for loot system
			
		if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
			SpawnActorRandomEzLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
			kBossUnits, kEzList, bApplySwarmBonus, ActorMainScript, kPackageLocs, true, iDifficulty)
		endif
			
	endif
	
	Int iBossCount = (kGroupList.Length) - iRegularActorCount ;Also required for loot system
	
	;Now check the loot system and do the loot pass if applicable. We do this post spawn as to avoid unnecessary perfromace impact on spawnloops.
	
	if SpawnTypeScript.bLootSystemEnabled ;Spawntype loot system first. Regional Spawntypes may have different loot to the next.
		SpawnTypeScript.DoLootPass(kGroupList, iBossCount)
	endif
	
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
;SINGLE GROUP SPAWN LOOPS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;For the purposes of SPEED, I have create many functions to do specific things.

;Regular, local, single group spawn loop
Function SpawnActorLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, EncounterZone akEz, Bool abApplySwarmBonus, \
SOTC:ActorQuestScript aActorMainScript, ObjectReference[] akPackageLocs, Bool abIsBossSpawn, Int aiDifficulty)

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
	Int iActorListSize = (akActorList.Length) - 1 ;Need actual size
	Actor kSpawned
	
	;Spawn the first guaranteed Actor
	kSpawned = Self.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, akEz) ;akEz can be None
	kGroupList.Add(kSpawned) ;Add to Group tracker

	if !bApplyAmbushPackage ;More likely to be false
		ApplyPackageData(kSpawned, akPackageLocs) ;Apply the package from Alias
	else
		ApplyPackageAmbushData(kSpawned) ;Apply the package from Alias
	endif
	
	;Begin chance loop for the rest of the Group
	while iCounter != aiMaxCount
	
		if (Utility.RandomInt(1,100)) < aiChance
			
			kSpawned = Self.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, akEz) ;akEz can be None
			kGroupList.Add(kSpawned) ;Add to Group tracker
			
			if !bApplyAmbushPackage ;More likely to be false
				ApplyPackageData(kSpawned, akPackageLocs) ;Apply the package from Alias
			else
				ApplyPackageAmbushData(kSpawned) ;Apply the package from Alias
			endif		
			
		endif
		
		iCounter +=1
	
	endwhile

EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------

;Regular, local, single group spawn loop, Randomise EZs
Function SpawnActorRandomEzLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, EncounterZone[] akEzList, Bool abApplySwarmBonus, \
SOTC:ActorQuestScript aActorMainScript, ObjectReference[] akPackageLocs, Bool abIsBossSpawn, Int aiDifficulty)

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
		ApplyPackageAmbushData(kSpawned) ;Apply the package from Alias
	endif
	
	;Begin chance loop for the rest of the Group
	while iCounter != aiMaxCount
	
		kEz = akEzList[(Utility.RandomInt(0,iEzListSize))] ;Randomise EZ each loop
	
		if (Utility.RandomInt(1,100)) < aiChance
			
			kSpawned = Self.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, kEz) ;akEz can be None
			kGroupList.Add(kSpawned) ;Add to Group tracker
			
			if !bApplyAmbushPackage ;More likely to be false
				ApplyPackageData(kSpawned, akPackageLocs) ;Apply the package from Alias
			else
				ApplyPackageAmbushData(kSpawned) ;Apply the package from Alias
			endif
			
		endif
		
		iCounter +=1
	
	endwhile

EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;MULTIPOINT SPAWN EVENTS & FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

Function PrepareMultiGroupSpawn()
	
	;WARNING: DO NOT USE MULTIPOINTS IN CONFINED SPACES WITH SPAWNTYPES THAT HAVE OVERSIZED ACTORS - USE MULTIPLE SINGLE POINTS INSTEAD
	
	;Get random list of actors
	Int iGroupsToSpawn = MasterScript.RollGroupsToSpawnCount(((kChildMarkers.Length) - 1)) ;Number of members on kChildMarker array is the limit
	SOTC:ActorClassPresetScript[] ActorParamsScriptList = SpawnTypeScript.GetRandomActors(false, 0, iGroupsToSpawn)
	
	ObjectReference[] kPackageLocs = RegionScript.GetRandomTravelLocs(iNumPackageLocs) ;Will be 1 for MultiPoint, still expects array on helper as it is capable of more.
	;Should I cast to copy locally seem the function will clear it? 
	
	Int iCounter
	ObjectReference kSpawnPoint
	ObjectReference kHelper
	
	while iCounter < iGroupsToSpawn
	
		kSpawnPoint = GetChildMarker()
		kHelper = kSpawnPoint.PlaceAtMe(kMultiPointHelper) ;Place worker
		(kHelper as SOTC:SpHelperScript).SetHelperSpawnParams(RegionScript, ActorParamsScriptList[iCounter], kPackage, kPackageLocs) ;Will auto fire after this function in it's own thread via timer
		kActiveHelpers.Add(kHelper) ;Track worker
		
		iCounter += 1
	
	endwhile

EndFunction


;If SP is a MultiPoint, this function gets a random child marker each time its called, without ever getting the same marker twice because we move it temporarily after
;Interior spawns can and are designed to potentially spawn at previously selected markers.
ObjectReference Function GetChildMarker()

	if !bChildrenActive ;Initialise if not already
		kActiveChildren = new ObjectReference[0]
		bChildrenActive = true
	endif
	
	int iSize = kChildMarkers.Length - 1  ;Get random member
	int i = Utility.RandomInt(0,iSize)

	ObjectReference kMarkerToReturn = kChildMarkers[i]  ;Get a direct link to Object in array
	
	kActiveChildren.Add(kChildMarkers[i]) ;Add selected marker to active array
	kChildMarkers.Remove(i) ;Remove from original array, guaranteeing it won't be selected again
	;We will move it back later
	
	;NOTE - Need to investigate where removing a filled property on an array and moving it back will actually work as expected.
	;If not will have to try a different method - possibly iterate thru the list instead of picking randoms.
	;NOTE: Works on AUTO property arrays only.
	
	return kMarkerToReturn ;Return the temp set from earlier
	
EndFunction


;UNUSED - Left for reference
;Create a new SpawnHelper instance at a child marker and passes spawn parameters to it
;Function CreateNewWorkerPoint(ObjectReference akSpawnPoint)

	;Was about to turn this into an ObjectReference Function. Decided it was easier to move code to where it was needed in Multipoint function.

	;int iCurrentChild = kActiveChildren.Length - 1 ;Get the last added child - old method
	;ObjectReference kHelper = kActiveChildren[iCurrentChild].PlaceAtMe(kMultiPointHelper) ;Place worker
	
	;akSpawnPoint.PlaceAtMe(kMultiPointHelper) ;Place worker
	;kActiveHelpers.Add(kHelper) ;Track worker
	
	;Delegate spawn params to Helper and immediately put it to work
	
;EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;INTERIOR SPAWN EVENTS & FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;NOTE - INTERIOR SPAWNS ONLY DESIGNED TO SPAWN 1 GROUP!

;In order to achieve a relatively even distribution of actors throughout an interior cell, we place Actors at random markers scattered through the cell.
;The iRarityOverride is still present here, but Random Ambush mode is NOT supported (Use Ambush points for that if desired). Random Swarm is supported.
;This also expects the Interior Sandbox package to be set (has a tighter sandbox radius and patrols between 2 predetermined, random points every so often)
Function PrepareInteriorSpawn()
	
	;Get a random Actor, pulling the ClassPresetScript directly.
	if iRarityOverride > 0 && iRarityOverride < 4 ;Security measure, cannot get rarity outside 1-3
		ActorParamsScript = SpawnTypeScript.GetRandomActor(True, iRarityOverride) ;ActorClassPresetType
	else 
		ActorParamsScript = SpawnTypeScript.GetRandomActor(false, 0)
	endif
	
	;Create direct links to ActorQuestScript and ClassDetailsStruct
	
	SOTC:ActorQuestScript ActorMainScript = ActorParamsScript.ActorScript
	;We'll get this now as it will have to be passed to the loop as well as various other work which makes this essential
	
	;Now we'll check if we are in a confined space and Actor is oversized. Not all interior spaces are confined so same check applies.
	while (bIsConfinedSpace) && (ActorMainScript.bIsOversizedActor)
		if iRarityOverride > 0 && iRarityOverride < 4 ;Security measure, cannot get rarity outside 1-3
			ActorParamsScript = SpawnTypeScript.GetRandomActor(True, iRarityOverride) ;ActorClassPresetType
		else 
			ActorParamsScript = SpawnTypeScript.GetRandomActor(false, 0)
		endif
		ActorMainScript = ActorParamsScript.ActorScript
	endwhile
	
	;Now we can get the actual spawn parameters
	Int iDifficulty = RegionScript.iCurrentDifficulty ;Set the difficulty level 
	ClassDetailsStruct ActorParams = ActorParamsScript.ClassDetails[iDifficulty] ;Difficulty level used for presets on Actor Class

	;The variable names here should be so confusing by your now head is caved in
	;Organise the actual ActorBase arrays
	
	ActorBase[] kRegularUnits = (ActorParamsScript.GetRandomGroupLoadout(false)) as ActorBase[] ;Cast to copy locally
	ActorBase[] kBossUnits
	Bool bBossAllowed = ActorParams.bAllowBoss 
	if bBossAllowed ;Not gonna set this unless it's allowed. Later used as parameter
		kBossUnits = (ActorParamsScript.GetRandomGroupLoadout(true)) as ActorBase[] ;Cast to copy locally
	endif
	
	;Check and setup EncounterZone data
	
	EncounterZone kEz ;iEZMode 1 - Single EZ to use for Group Levels
	EncounterZone[] kEzList; If iEzApplyMode = 2, this will point to a Region list of EZs. One will be applied to each Actor at random.
	
	Int iEzMode = RegionScript.iEzApplyMode ;Store locally for reuse
	
	if iEzMode == 0 ;This exist so we can skip it, seems it is more likely players won't use it.
		;Do nothing, use NONE EZ (passed parameters will be None)
	elseif iEZMode == 1
		kEz = RegionScript.GetRandomEz()
	elseif iEzMode == 2
		kEzList = RegionScript.GetRegionCurrentEzList() ;Look directly at the Regions Ez list, based on current mode.
	endif
	
	;Check for bonus events/setup Package locations if necessary
	
	Bool bApplySwarmBonus ;Whether or not Swarm bonuses are applied
	;Now lets roll the dice on it
	if (ActorMainScript.bSupportsSwarm) && (RegionScript.RollForSwarm())
		bApplySwarmBonus = true
	endif
	
	;Finally, begin loops.
	
	Int iRegularActorCount ;Required for loot system
	
	if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely
			
		SpawnActorInteriorLoop(ActorParams.iMaxAllowed, ActorParams.iChance, kRegularUnits, \
		kEz, bApplySwarmBonus, ActorMainScript, false, iDifficulty)
		
		iRegularActorCount = (kGroupList.Length) ;Required for loot system
			
		if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
			SpawnActorInteriorLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
			kBossUnits, kEz, bApplySwarmBonus, ActorMainScript, true, iDifficulty)
		endif

	else ;Randomise the Ez

		SpawnActorRandomEzInteriorLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
		kRegularUnits, kEzList, bApplySwarmBonus, ActorMainScript, false, iDifficulty)
		
		iRegularActorCount = (kGroupList.Length) ;Required for loot system
			
		if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
			SpawnActorRandomEzInteriorLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
			kBossUnits, kEzList, bApplySwarmBonus, ActorMainScript, true, iDifficulty)
		endif
			
	endif
	
	Int iBossCount = (kGroupList.Length) - iRegularActorCount ;Also required for loot system
	
	;Now check the loot system and do the loot pass if applicable. We do this post spawn as to avoid unnecessary perfromace impact on spawnloops.
	
	if SpawnTypeScript.bLootSystemEnabled ;Spawntype loot system first. Regional Spawntypes may have different loot to the next.
		SpawnTypeScript.DoLootPass(kGroupList, iBossCount)
	endif
	
	if ActorMainScript.bLootSystemEnabled
		ActorMainScript.DoLootPass(kGroupList, iBossCount)
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
			ApplyPackageInteriorData(kSpawned, kSpawnLoc) ;Apply the package from Alias
			
		endif
		
		iCounter +=1
	
	endwhile

EndFunction


;Interior spawn loop
Function SpawnActorRandomEzInteriorLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, EncounterZone[] akEzList, \
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
			ApplyPackageInteriorData(kSpawned, kSpawnLoc) ;Apply the package from Alias
			
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


;Ambush version of the above, only travel to Player to attack
Function ApplyPackageAmbushData(Actor akActor) ;This will send all Actors in the Grouplist after the player immediately

	;NOTE: A change may be made here, to have this loop the whole group at the end and send them
	;all after the player in quicker succession. This may be better in terms of how the group
	;appears to mob the player, i.e spread out vs  virtually all at once

	akActor.SetLinkedRef(Game.GetPlayer(), kPackageKeywords[0])
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


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;INTERCEPT - MASTER/REGION SPECIAL SPAWN EVENTS & FUNCTIONS - Currently unplanned, left for reference
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;Currently no events/functions defined here. 

;-------------------------------------------------------------------------------------------------------------------------------------------------------