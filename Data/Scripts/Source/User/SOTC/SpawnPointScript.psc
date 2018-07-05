Scriptname SOTC:SpawnPointScript extends ObjectReference
{ Main Spawnpoint script, attached to Activator (preconfigured per Region or custom instance). }
;Written by SMB92
;Special thanks to J. Ostrus [BigandFlabby] for code contributions that made this mod possible.

;Primary/Main Spawnpoint script. This is the most common instance used in the mod. 

;LEGEND - PREFIX CONVENTION
; Variables and Properties are treated the same. Script types do not have prefixes, unless they
;are explicitly received as function arguments and are multi-instance scripts.
; "a" - (Function/Event Blocks only) Variable was received as function argument OR the variable
;was created from a passed-in Struct/Var[] member
; "k" - Is an "Object" as usual, whether created in a Block or defined in the empty state/a state.
; "f,b,i,s" - The usual Primitives: Float, Bool, Int, String.

;DEV NOTE: As of version 0.13.01, with the introduction of new "Package Modes", this script could probably stand to benefit from the use of States.
;This may help to keep it more legible to new readers. However, with the mix and matching of certain features supported by varying modes, this is not
;currently being investigated, and subject to loose thinking only. 

;DEV NOTE 2: When placing SpawnPoints and ChildPoints in CK render window, best practice is to place them a good few units off the ground. WHile this
;script does not use PlaceAtMe() which can and does place object somewhat below the object (often leading to them falling through the map and CTDing
;the game), this is still best practice to ensure the types of errors as noted do not occur. Furthermore, it was observed in testing that PlaceAtme()
;still caused crashes in fast succession, even when Points were a fair distance off the ground. PlaceActorAtMe() has never suffered such problems. 

;-------------------------------------------------------------------------------------------------------------------------------------------------------
;PROPERTIES & IMPORTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;DEV NOTE: Most Properties on this script are const, and should be setup properly. This should allow alterations later to be picked up without resetting.

import SOTC:Struct_ClassDetails ;Struct definition needs to be present


Group Primary

	SOTC:MasterQuestScript Property MasterScript Auto Const Mandatory
	{ Fill with MasterQuest }
	
	Activator Property kMultiPointHelper Auto Const
	{ Fill with MultiPoint helper Base Object. }
	;NOTE: This will have to be cast to it's script type in functions, after creation.
	
	Int Property iWorldID Auto Const Mandatory
	{ Fill with the World ID where this SP is placed. }
	; LEGEND - WORLDS
	; [0] - COMMONWEALTH
	; [1] - FAR HARBOR
	; [2] - NUKA WORLD

	Int Property iRegionID Auto Const Mandatory
	{ Fill with the RegionID where this SP is placed. }
	
	Int Property iSpawnMode Auto Const Mandatory
	{ 0 = Random from SpawnType, 1 = Specific Actor. Fill ID number below accordingly. }
	
	Int Property iSpawnTypeOrActorID Auto Const Mandatory
	{ Fill with ID (index) of SpawnType or Actor type. See script commentary for ID No. legend. }
	
	Int Property iClassToSpawn Auto Const Mandatory
	{ Set the ClassPreset to use if spawning a specific Actor type (iSpawnMode = 1, ignored if not, use overrides below for that). 
Enter 777 to randomise main 1-3 rarity-based Class Presets, 0 is debug, 1-3 Rarity based, 4 Amush (Rush), 5 Sniper. 
Actor must have this Class Preset defined or this will return Debug Preset (0). }
	
	Int Property iPackageMode Auto Const Mandatory
	{ 0 = Sandbox/Hold, 1 = Travel, 2 = Patrol, 3 = Ambush (distance based), 4 = Interior(Random ChildPoint Sandbox) ). 
See Package legend in script for details. }

	;LEGEND - PACKAGE MODES (added version 0.13.01, replaces previous notes.)
	;A number of different package modes are available. User must provide correct package that matches the data
	;set on the SpawnPoint (or weird things may happen). They are as follows:
	; BOOL FLAG - BISMULTIPOINT: In this mode, the Parent SP will create "Helper" SpawnPoints at "ChildPoints" around
	;the Parent which are defined by the user in the ChildPoints array. The Parent passes data to each Helper which
	;then does the spawning of a group. This mostly exists to spawn enemy groups in parallel for emulating battles,
	;but not strictly. The number of groups to spawn can be forced, or randomised (based on the number of ChildPoints
	;defined). Some Package modes may not work with this, or work differently. See below.
	; 0 - SANDBOX: Actors will sandbox at the SpawnPoint, or a ChildPoint if provided. Use this for "Hold" packages
	;as well(such as for "Snipers"). Works with MultiPoint mode.
	; 1 - TRAVEL: Spawns will travel to random locations markers in the Region. Set iNumPackageLocsRequired to the
	;number of locations expected by the Package. Works with MultiPoint mode.
	; 2 - PATROL: Spawns will travel to ("patrol") each ChildPoint as set out in that array, in the order they are
	;listed. While this also works with MultiPoint mode (in such case they will start at the random ChildPoint they
	;started at, and still patrol in the same order as normal) care should be taken when using with random Actor
	;groups, as this was mainly intended for multiple groups of the same Actor type. Must have minimum number of
	;ChildPoints defined as the Package expects. Can have breaks/stops in the Package if desired, these will work
	;with MultiPoint mode too as keywords are linked in the correct order.
	; 3 - AMBUSH (DISTANCE BASED): This is a very simple mode, when selected the script will register for distance
	;less than on the player, and when the threshold is met, the group will rush at the Player. Simply uses the same
	;Package already set for the "Random Ambush" feature in the other modes, although a Hold package (prefereably in 
	;Sneak mode) should be given to start with, for quality reasons.  Works with MultiPoint mode, but should only be
	;used with same Actor type. Using this mode will force the use of Spawntype[11] (Ambush - Rush).
	; 4 - INTERIOR (Can be used in exteriors, forces certain function path): This mode will place spawns at a random
	;ChildPoint defined in the cell, and sandbox there. This mode doesn't strictly have to be used in an Interior,
	;it was purpose made to emulate pre-placed spawns in Interior as per vanilla. Other packages can be used instead
	;if desired (Ambush can be a good choice). Works in MultiPoint mode, which can be good for spawning battles among
	;random groups, or multithreading large numbers of the same Actor type.
	;RUSH PACKAGE: Used for both the Rampage and Random Ambush features. The Rampage feature causes spawns to "run"
	;to a single location and sandbox there, which is useful for a stampede of Radstag for instance, among others.
	;The same logic is applied to attacking the Player. This mode can also be useful in emulating a "planned" battle
	;or attack, by causing groups to either run at each other before they can enter combat, or a location as above.
	
	
	Bool Property bIsMultiPoint Auto Const
	{ Set true if using child markers to randomise placement of groups. USE WISELY, AND DO NOT USE IN CONFINED SPACES. }
	;WARNING: DO NOT USE MULTIPOINTS IN CONFINED SPACES WITH SPAWNTYPES THAT HAVE OVERSIZED ACTORS - USE MULTIPLE SINGLE POINTS INSTEAD.
	
	Bool Property bIsConfinedSpace Auto Const
	{ If the SP is placed in a confined area, set True so Oversized Actors will not spawn here.
And yes, this is required for interiors as not all interiors are confined. }

	Bool Property bIsInteriorPoint Auto Const ;Re-added in version 0.13.02, to be sued in conjuction with Player distance check.
	{ Set true if this Point is inside of an Interior. Interior Points should not be placed near entry points to the cell, for best effect. }

	ReferenceAlias Property kPackage Auto Const Mandatory
	{ Fill with the Alias holding the Package, according to Package Mode selected. Not required for Mode 3 (uses Rush Package). }
	
	ReferenceAlias Property kPackageRush Auto Const Mandatory
	{ Fill with SOTC_RushPackage01. This gets filled the same on EVERY instance of this marker. Used for Ramapage/Random Ambush features. }
	
	Keyword[] Property kPackageKeywords Auto Const Mandatory
	{ Fill with as many package keywords as needed (even if just 1). Used for linking to package marker(s) i.e Travel Locations. }
	
	Int Property iNumPackageLocsRequired Auto Const Mandatory
	{ If using Travel Package (Mode 1), set to the number of travel locations required by the Package. You can also use this with Sandbox(Mode 0) 
by setting to 1 and giving the SP a single ChildPoint to use as an external spawn location. Ignored if using bRandomiseStartLoc for Mode 0. }
	
	ObjectReference[] Property kChildPoints Auto ;AUTO so can be modified at runtime.
	{ If using child markers, fill with these from render window. This is used for Patrols/Interiors/MultiPoints/Randomised Start Locs or if we 
want to define a Sandbox location away from this SpawnPoint. Do not use this for other purposes unless you know what you are doing. If using the
iForceGroupsToSpawn override, must have that many ChildPoints. Length of this array doubles as maximum no. of Groups for MultiPoint otherwise. }

	Bool Property bSpreadSpawnsToChildPoints Auto Const
	{ If set true, spawned Actors will be placed at random ChildPoints (which must be defined) around the SpawnPoint, so they are spread apart.
ChildPoints should be placed in same cell as this SP, use at own risk otherwise. Causes bRandomiseStartLoc override and iNumPackageLocs
for Package Mode 0 (Sandbox/Hold) to be ignored. This setting is ignored for Packages Modes 2 and 5, and MultiPoint mode. }

	Int Property iChanceToSpawn = 100 Auto Mandatory ;AUTO so can be modified at runtime, particularly if made a Property of a Menu. 
	{ Use this define an extra chance/dice roll for this SP or set 100 for always. Default is 100
in case user forgets to se this. Property is non-const as can be changed, particularly if the
point is configurable from Menu (i.e Interior Points.) }
	
	Int Property iThreadsRequired = 1 Auto Const Mandatory
	{ Default value of 1. Set more if feel the need to (i.e large single groups/multiple groups). }
	;NOTE: Will be released immediately if Master intercepts for a Random Event. MultiPoint helpers will force add threads
	;on instantation, which can intentionally exceed the max thread threshold.
	
	Bool Property bAllowVanilla Auto Const Mandatory
	{ Set true if wanting this point to be allowed in Vanilla Mode. }
	
	Bool Property bEventSafe Auto Const Mandatory
	{ Set True if this SpawnPoint can be safely used by Random Events Framework. }

EndGroup


Group Overrides

	Int Property iPlayerLevelRestriction = 0 Auto Const
	{ Can be used to set a Player level requirement if desired. }

	Int Property iPresetRestriction Auto Const 
	{ Fill this (1-3) if it is desired to restrict this point to a certain Master preset level. }
	
	Bool Property bBlockLocalRandomEvents Auto Const
	{ Set true to ignore local events, such as Swarm, Rampage and Ambush. This will be slightly faster as forces the use of a function
that does not include these checks.	}

	Bool Property bRandomiseStartLoc Auto Const
	{ This can be used to randomise the initial placement of spawned groups with certain Package Modes. One must define a number of
ChildPoints around this SP in order for this to work. ChildPoints should be placed in same cell as this SP, use at own risk 
otherwise. Supported Package Modes are 0, 1 and 2. For Mode 0 (Sandbox/Hold), this overrides the use of iNumPackageLocs if set.
This is somehwat the equivalent of Interior Mode's spawn method for Modes 0-2. Ignored in MultiPoint Mode. }

	Float Property fSafeDistanceFromPlayer = 8192.0 Auto Const
	{ Default value of 8192.0 (2 exterior cell lengths), safe distance to spawn from Player. Change if desired. }

	Float Property fAmbushDistance = 800.0 Auto Const
	{ Default of 800.0 units, distance target from Player before Ambush (Mode 3) activates. Enter override value if desired. }

	Int Property iForceUseRarityList Auto Const
	{ Fill this 1-3, if wanting to force grab a certain "rarity" of actor in this Region (i.e force use Rarity list). }
	
	Bool Property bForceClassPreset Auto Const
	{ Set True if wanting to force a Rarity-Based Class Preset, optional to the above. Can be used in MultiPoint mode. }
	
	Int Property iForcedClassPreset Auto Const
	{ If above is set True, set this to a value of 0-3 (can only use Rarity-based CPs). 0 is debug CP. }
	
	Bool Property bForceMasterPreset Auto Const
	{ Use if wanting to force a Master Preset to be used when grabbing params from ClassPreset. }
	
	Int Property iForcedMasterPreset Auto Const
	{ Leave 0 if above is false. Otherwise set 0-3 (0 is debug preset). Set 777 to randomise Preset. }
	
	Bool Property bForceDifficulty Auto Const
	{ If desired to force a Difficulty level, set true. }
	
	Int Property iForcedDifficulty Auto Const
	{ Set 0-4 if above is true. As per Vanilla Difficulty settings. }
	
	Int Property iForceGroupsToSpawnCount Auto Const
	{ If wanting to force the number of Groups to spawn at a MultiPoint, set this above 0, or will be randomised.
Be careful with this value if not using with Interior/Patrol modes. }
	
	;Local Event chance bonuses:
	
	Int Property iPointSwarmBonus = 1 Auto Const
	{ Enter a value above 0 if wanting to give this Point a "Swarm" chance bonus. Ignored for MultiPoint. }
	
	Int Property iPointRampageBonus = 1 Auto Const
	{ Enter a value above 0 if wanting to give this Point a "Rampage" chance bonus. Ignored for MultiPoint. }
	
	Int Property iPointRandomAmbushBonus = 1 Auto Const
	{ Enter a value above 0 if wanting to give this Point a "Random Ambush" chance bonus. Ignored for MultiPoint. }

EndGroup


Group MenuGlobals
{ Can be used for Menu and future functions. }

	GlobalVariable Property SOTC_Global01 Auto Const Mandatory
	{ Auto-fill }
	GlobalVariable Property SOTC_Global02 Auto Const Mandatory
	{ Auto-fill }
	GlobalVariable Property SOTC_Global03 Auto Const Mandatory
	{ Auto-fill }
	
	;Added 3 Globals, sop in the event we actually need more, won't have to stress so much about adding more. 
	
EndGroup


;----------------
;Local Variables
;----------------

;TimerIDs
Int iStaggerStartupTimerID = 1 Const
Int iFailedSpCooldownTimerID = 2 Const

Bool bSpawnpointActive ;Condition check. Once SP is activated this is set true.

SOTC:ThreadControllerScript ThreadController
;{ Init None, fills OnCellAttach. }

SOTC:RegionManagerScript RegionManager
;{ Init None, fills OnCellAttach. }
	
SOTC:RegionTrackerScript CleanupManager
;{ Init None, fills OnCellAttach. }
	
SOTC:SpawnTypeRegionalScript SpawnTypeScript
;{ Init None, fills OnCellAttach. }

SOTC:ActorManagerScript ActorManager
;{ Init None, fills OnCellAttach. Set ID accordingly. }

ActorClassPresetScript ActorParamsScript
;NOTE: We never get the ActorManagerScript first, we go straight for the ClassPresetScript in order to get parameters.
;We can and will still access the ActorManagerScript from here. 

Actor[] kGrouplist ;Stores all Actors spawned on this instance
;DEV NOTE: GROUP LEADERSHIP. 
;It could be considered to add another variable here for a "Group Leader" of sorts. At this time (version 0.13.01), there is no plan in place for this.
Int iLosCounter ;This will be incremented whenever a Line of sight check to Player fails. If reaches 25, spawning aborts. As we at least spawn 1 actor
;to start with, this remains safe to use (however Player may see that one actor being spawned. its just easier to live with). 

;Multipoint/Interior variables
ObjectReference[] kActiveChildren ;Temp list of all child markers used to delegate spawns to
Bool bChildrenActive ;This will be checked and save reinitializing above array later.
ObjectReference[] kActiveHelpers ;Actual SpawnHelper instances placed at child markers

;Spawn Info, listed in expect order of setting. Not all are required, depending on SpawnType etc
Bool bRandomiseEZs ;Used in spawn loop to check if random EZ needs to be randomised (iEzApplyMode = 2)

Bool bApplyRushPackage ;If flagged, will Apply the Rush package, used for Rampages/Random Ambush features.


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;PRE-SPAWN EVENTS & FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

Event OnCellAttach()
	;Inital check, is not active, chance is not None (as could be nulled by Menu for example).
	if (!bSpawnpointActive) && (iChanceToSpawn as Bool) 
		;Staggering the startup might help to randomise SPs in an area when Threads are scarce
		StartTimer((Utility.RandomFloat(0.15,0.35)), iStaggerStartupTimerID)
	endif
	
EndEvent


Event OnTimer(int aiTimerID)

	if aiTimerID == iStaggerStartupTimerID

		;Initial checks - If Interior continue, else check distance from Player is greater than bSafeDistance Property and Player level restriction is exceeded.  
		if (bIsInteriorPoint) || ((GetDistance(MasterScript.PlayerRef)) > fSafeDistanceFromPlayer) && ((MasterScript.PlayerRef.GetLevel()) >= iPlayerLevelRestriction)
		;DEV NOTE: GetDistance check is only safe when comparing Object (namely this self object in this case) to Actor as parameter (namely Player in this case). 
		
			;NOTE: Master and Regional checks are done before GetThread, so it is possible for an event to intercept before ThreadController can deny
			;Events are usually exempt from ThreadController checks, although they do count towards any of the limits.
			
			Debug.Trace("SpawnPoint firing, setting script links")
			SetSpScriptLinks()
		
			;Master Level checks/intercepts
			if MasterScript.MasterSpawnCheck(Self as ObjectReference, bAllowVanilla, bEventSafe) ;MASTER CHECK: If true, denied
				;Master script assuming control, kill this thread and disable
				Debug.Trace("SpawnPoint denied by Master check")
				if ThreadController.fFailedSpCooldownTimerClock > 0.0
					bSpawnpointActive = true
					StartTimer(ThreadController.fFailedSpCooldownTimerClock, iFailedSpCooldownTimerID)
					;DEV NOTE: If the Fail Cooldown Timer is off, this will spam if constantly in and out of the cell.
				endif				
				return ;Nip in the bud
			endif
			
			Debug.Trace("SpawnPoint passed Master Check")
			
			;Region Level checks/intercept. This will send in local spawn parameters if no intercept takes place.
			;NOTE: as of version 0.06.01, no events are defined on RegionManager, will always return false. 
			if RegionManager.RegionSpawnCheck(Self as ObjectReference, iPresetRestriction) ;REGION CHECK: If true, denied
				;Region script assuming control, kill this thread and disable
				Debug.Trace("MiniPoint denied by Region check")
				if ThreadController.fFailedSpCooldownTimerClock > 0.0
					bSpawnpointActive = true
					StartTimer(ThreadController.fFailedSpCooldownTimerClock, iFailedSpCooldownTimerID)
					;DEV NOTE: If the Fail Cooldown Timer is off, this will spam if constantly in and out of the cell.
				endif
				return ;Nip in the bud
			endif
			
			Debug.Trace("SpawnPoint passed Region Check")
			
			if (SpawnTypeScript.bSpawnTypeEnabled) && (ThreadController.GetThread(iThreadsRequired)) && \
			((Utility.RandomInt(1,100)) <= ((iChanceToSpawn) + (RegionManager.GetRegionSpPresetChanceBonus()))) ;LOCAL CHECK
				Debug.Trace("SpawnPoint Spawning")
				PrepareLocalSpawn() ;Do Spawning
				Debug.Trace("SpawnPoint successfully spent")
			else
				;Denied by dice, Disable and wait some time before trying again.
				Debug.Trace("SpawnPoint denied by dice or Spawntype disabled, cooling off before next attempt allowed")
				if ThreadController.fFailedSpCooldownTimerClock > 0.0
					bSpawnpointActive = true
					StartTimer(ThreadController.fFailedSpCooldownTimerClock, iFailedSpCooldownTimerID)
					;DEV NOTE: If the Fail Cooldown Timer is off, this will spam if constantly in and out of the cell.
				endif
				
			endif
			
		;else
			;Do nothing
		endif

	elseif aiTimerID == iFailedSpCooldownTimerID
	
		bSpawnpointActive = false ;Return to armed state. 
	
	endif
	
EndEvent



Function SetSpScriptLinks()
	
	;Since patch 0.10.01, all instances are created at runtime (first install). Necessary evil.
	ThreadController = MasterScript.ThreadController
	RegionManager = MasterScript.Worlds[iWorldID].Regions[iRegionID]
	CleanupManager = RegionManager.CleanupManager
	
	if iSpawnMode == 0 ;Random actor from SpawnType
		
		if iPackageMode == 3 ;Ambush (distance based) Force use of SpawnType 11.
			SpawnTypeScript = RegionManager.Spawntypes[11]
		else
			SpawnTypeScript = RegionManager.Spawntypes[iSpawnTypeOrActorID]
		endif
		
	elseif iSpawnMode == 1 ;Specific Actor from Master
		ActorManager = MasterScript.SpawntypeMasters[0].ActorList[iSpawnTypeOrActorID]
	endif
	
EndFunction



Function PrepareLocalSpawn() ;Determine how to proceed
	
	;Check set Package Mode is expected. Shouldn't be required but I made this mistake once. 
	if iPackageMode > 4 || iPackageMode < 0;FAILURE
		Debug.Trace("Unexpected Package mode detected on SpawnPoint, returning immediately, function FAILED. Mode was set to: " +iPackageMode)
		bSpawnpointActive = true
		CleanupManager.AddSpentPoint(Self) ;All points are added by Object rather than script type.
		;Cleanup will be handled by the CleanupManager upon Region reset timer firing.
		ThreadController.ReleaseThreads(iThreadsRequired) ;Spawning done, threads can be released.
		return
	endif
	
	;Proceed if above passes. 
	Debug.Trace("Preparing Local Spawn")
	MasterScript.ShowSpawnWarning() ;Only displays if enabled, this is quicker than "check and/then do".
	
	
	if bIsMultiPoint ;Uses helper objects to create multi-group spawns.  

		Debug.Trace("MultiPoint Spawning")
		PrepareMultiGroupSpawn()
		
	elseif iPackageMode < 3 ;Start spawning single group at/on this Point. Modes 0, 1 and 2. 
	
		Debug.Trace("SpawnPoint spawning single group")
		
		if bBlockLocalRandomEvents 
			PrepareSingleGroupNoEventSpawn()
		else
			PrepareSingleGroupSpawn()
		endif
		
	elseif iPackageMode == 3 ;Ambush - distance-based.
		
		PrepareSingleGroupNoEventSpawn() ;Only function that supports this mode, ignores local events by default.
		;This function will be cut short and return in this mode, after Registration for distance is done. 
	
	elseif iPackageMode == 4 ;Interior mode, distributes the group across different parts of the Interior.
	;DEV NOTE - Master Random Events framework needs an update for interiors.
		
		if (Self as ObjectReference).GetCurrentLocation().IsCleared()
			
			Debug.Trace("SpawnPoint Interior spawning")
			if bBlockLocalRandomEvents 
				PrepareSingleGroupNoEventSpawn()
			else
				PrepareSingleGroupSpawn()
			endif
			
		else ;Nip it in the bud
			
			if ThreadController.fFailedSpCooldownTimerClock > 0.0
				bSpawnpointActive = true
				StartTimer(ThreadController.fFailedSpCooldownTimerClock, iFailedSpCooldownTimerID)
			endif
			;DEV NOTE: If the Fail Cooldown Timer is off, this will spam if constantly in and out of the cell.
			Debug.Trace("Interior SpawnPoint denied due to location not being cleared")
			ThreadController.ReleaseThreads(iThreadsRequired)
			
			return
			
		endif

		
	endif
	
	bSpawnpointActive = true
	CleanupManager.AddSpentPoint(Self)
	;Cleanup will be handled by the CleanupManager upon Region reset timer firing.
	ThreadController.ReleaseThreads(iThreadsRequired) ;Spawning done, threads can be released.
	
	Debug.Trace("SpawnPoint spawning complete")
	
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
		
		if bApplyRushPackage
			CleanupActorRefs(kPackageRush)
		else
			CleanupActorRefs(kPackage)
		endif
		
	endif
	
	;Delink scripts in case the instances may be changed later (i.e mod reset) which may cause errors to log.
	ActorManager = None
	SpawnTypeScript = None
	RegionManager = None
	CleanupManager = None
	
	ThreadController.IncrementActiveSpCount(-1)
	ThreadController = None
	iLosCounter = 0
	bSpawnpointActive = false

EndFunction
 

Function CleanupActorRefs(ReferenceAlias akPackage) ;Decided to pass the package in here. 

	int iCounter = 0
	int iSize = kGroupList.Length
        
	while iCounter < iSize

		akPackage.RemoveFromRef(kGroupList[iCounter]) ;Remove package data. Perhaps not necessary?
		;NOTE; Removed code that removes linked refs. Unnecesary.
		kGroupList[iCounter].Delete()
		iCounter += 1
	
	endwhile
	
	ThreadController.IncrementActiveNpcCount(-iSize)
	kGroupList.Clear()
	
EndFunction


Function CleanupHelperRefs()

	int iCounter = 0
	int iSize = kActiveHelpers.Length
	
	while iCounter < iSize
	
		(kActiveHelpers[iCounter] as SOTC:SpHelperScript).HelperFactoryReset()
		kActiveHelpers[iCounter].Disable()
		kActiveHelpers[iCounter].Delete()
		iCounter += 1
		
	endwhile

	kActiveHelpers.Clear()
	
EndFunction


;Revert the ChildPoint arrays back to normal
Function ResetChildMarkers()
	
	;DEV NOTE: Currently this array is initialised empty as it is added to very shortly after being created, lessening the chance of it being trashed.
	;Therefore this call is not actually necessary. This still needs to be monitored in case we need change it, so this remains.
	;if kActiveChildren[0] == None ; Security measure removes first member of None.
		;kActiveChildren.Remove(0)
	;endif

	int iCounter = 0
	int iSize = kActiveChildren.Length
	
	while iCounter < iSize
	
		kChildPoints.Add(kActiveChildren[iCounter]) ;Add it back from the active list
		iCounter += 1
		
	endwhile
	
	kActiveChildren.Clear() ;Then empty it
	
EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;MENU FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;Added here for ease of use with SPs that may be controllable by Menu. 
Function SetMenuVars(string asSetting, bool abSetValues = false, Int aiValue01 = 0)

	if asSetting == "ChanceToSpawn"
	
		if abSetValues
			iChanceToSpawn = aiValue01
		endif
		SOTC_Global01.SetValue(iClassToSpawn as Float)
		
	endif
	
EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;SINGLE GROUP SPAWN EVENTS & FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

Function PrepareSingleGroupSpawn()
	
	;Values used throughout block
	Int iCounter
	Int iSize
	
	;Get the Actor data for spawning
	;--------------------------------

	if iSpawnMode == 0 ;Random spawn from SpawnType
	
		;Get a random Actor, pulling the ClassPresetScript directly.
		if iForceUseRarityList > 0 && iForceUseRarityList < 4 ;Security measure, cannot get rarity outside 1-3
			ActorParamsScript = SpawnTypeScript.GetRandomActor(iForceUseRarityList, bForceClassPreset, iForcedClassPreset) ;returns ActorClassPresetScript
			;Security check for iForcedClassPreset is done on STRegionalScript
		else ;Use debug preset if above failed. 
			ActorParamsScript = SpawnTypeScript.GetRandomActor(0, bForceClassPreset, iForcedClassPreset) ;returns ActorClassPresetScript
		endif
		
		;Create direct links to ActorManagerScript and ClassDetailsStruct
		
		ActorManager = ActorParamsScript.ActorManager
		;We'll get this now as it will have to be passed to the loop as well as various other work which makes this essential
		
		;Now we'll check if we are in a confined space and Actor is oversized
		while (bIsConfinedSpace) && (ActorManager.bIsOversizedActor) ;While true and rolled actor is oversized (get another)
			if iForceUseRarityList > 0 && iForceUseRarityList < 4 ;Security measure, cannot get rarity outside 1-3
				ActorParamsScript = SpawnTypeScript.GetRandomActor(iForceUseRarityList, bForceClassPreset, iForcedClassPreset) ;returns ActorClassPresetScript
				;Security check for iForcedClassPreset is done on STRegionalScript
			else ;Use debug preset if above failed. 
				ActorParamsScript = SpawnTypeScript.GetRandomActor(0, bForceClassPreset, iForcedClassPreset) ;returns ActorClassPresetScript
			endif
			ActorManager = ActorParamsScript.ActorManager
		endwhile
		
		
	elseif iSpawnMode == 1 ;Specific Actor
	
		;Link with ClassPresetScript to use. 
		ActorParamsScript = ActorManager.GetClassPreset(iClassToSpawn) ;If ClassToSpawn entered is not defined for the Actor, returns the debug preset.
	
	endif
		
	
	;Now we get the spawn parameters according to Preset & Difficulty
	;-----------------------------------------------------------------
	
	Int iPreset
	if bForceMasterPreset
	
		if iForcedMasterPreset == 777 ;Check if wanting to randomise
			iPreset = Utility.RandomInt(1,3)
		else
			iPreset = iForcedMasterPreset
		endif
		
	else
	
		if iSpawnMode == 0
			iPreset = SpawnTypeScript.iCurrentPreset
		elseif iSpawnMode == 1
			iPreset = RegionManager.iCurrentPreset
		endif
		
	endif
	ClassDetailsStruct ActorParams = ActorParamsScript.ClassDetails[iPreset]
	
	;Set difficulty for spawning.
	Int iDifficulty
	if bForceDifficulty
		iDifficulty = iForcedDifficulty
	else
		iDifficulty = RegionManager.iCurrentDifficulty
	endif


	;Organise the ActorBase arrays/Get GroupLoadout.
	;------------------------------------------------
	
	SOTC:ActorGroupLoadoutScript GroupLoadout = ActorParamsScript.GetRandomGroupScript()
	
	ActorBase[] kRegularUnits = (GroupLoadout.kGroupUnits) as ActorBase[] ;Cast to copy locally
	ActorBase[] kBossUnits
	Bool bBossAllowed ;Later used as parameter.
	if (ActorParams.iChanceBoss as Bool) && (GroupLoadout.kBossGroupUnits[0] != None) ;Check if Boss allowed and there is actually Boss on this GL.
		kBossUnits = (GroupLoadout.kBossGroupUnits) as ActorBase[] ;Cast to copy locally
	endif
	
	
	;Check and setup EncounterZone data
	;-----------------------------------
	
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
	
	
	;Check for bonus local events
	;-----------------------------
	
	ObjectReference[] kPackageLocs = new ObjectReference[1] ;Create it, even if it is unused later.
	;Initialised with one member for security reasons. This member of None is removed later, if required.
	Int iStartLoc = -1 ;Used if randomising the ChildPoint to spawn at. Default value = Self.
	
	
	;Roll on Swarm feature if supported
	Bool bApplySwarmBonus
	if (ActorManager.bSupportsSwarm) && (RegionManager.RollForSwarm(iPointSwarmBonus))
		bApplySwarmBonus = true
	endif
	
	
	;Roll on Rampage feature if supported, and Ambush feature if hostile group.
	Bool bRushThePlayer
	;DEV NOTE: Rush Package for Ambush and Rampage is the same now. Actors will Rush to the Point and Sandbox (in the case of the Player, enter combat first).
	
	if iPackageMode == 0 || iPackageMode == 1 ;Supported for these modes only.
	
		if (ActorManager.bSupportsRampage) && (RegionManager.RollForRampage(iPointRampageBonus)) ;Roll dice if supported and NOT Interior mode.
			bApplyRushPackage = true
		endif
		
		;Roll dice on Random Ambush feature
		if (!ActorManager.bIsFriendlyNeutralToPlayer) && (RegionManager.RollForAmbush(iPointRandomAmbushBonus)) ;Supported for all Actor types.
			bRushThePlayer = true
		endif
		
	endif
	
	
	;Finally, set the Package locations if required.
	;------------------------------------------------
	
	if iPackageMode > 2; Short-circuit, the below is not supported for Package Modes above this. 
		;Skip All
		
	elseif bRushThePlayer 
		kPackageLocs[0] = (MasterScript.PlayerRef) as ObjectReference ;Probably better/faster then Game.GetPlayer()
		
	elseif bApplyRushPackage ;Above check assumes this is true because Ambush.
		
		kPackageLocs = RegionManager.GetRandomTravelLocs(1)
		
		if bRandomiseStartLoc ;Place spawned group at random ChildPoint around the SP.
			iSize = (kChildPoints.Length) - 1
			iStartLoc = Utility.RandomInt(-1,iSize)	; -1 uses Self	instead of ChildPoint.
		endif
	
	elseif iPackageMode == 0 ;Sandbox/Hold
	
		if !bSpreadSpawnsToChildPoints ;This setting takes precedence over the below. 
		
			if bRandomiseStartLoc ;Place spawned group at random ChildPoint around the SP.
				iSize = (kChildPoints.Length) - 1 ;Need actual index length
				iStartLoc = Utility.RandomInt(-1,iSize)	; -1 uses Self	instead of ChildPoint.
				
			elseif iNumPackageLocsRequired > 0 ;Only checks if greater than 0, but only uses 1 location which should be defined on kChildPoints[0].
				iStartLoc = 0 ;First member of ChildPoints expected to be filled.
				
			endif
			
		endif
		
	elseif iPackageMode == 1 ;Travel mode, get locations required
	;DEV NOTE: Although we are just checking this value (for speed), only works with Package mode 0 and 1 (Sandbox and Travel).
		
		kPackageLocs = RegionManager.GetRandomTravelLocs(iNumPackageLocsRequired)
		
		;Check if we will randomise start loc before any loop can begin.
		if (!bSpreadSpawnsToChildPoints) && (bRandomiseStartLoc) ;Place spawned group at random ChildPoint around the SP.
			iSize = (kChildPoints.Length) - 1
			iStartLoc = Utility.RandomInt(-1,iSize)	; -1 uses Self	instead of ChildPoint
		endif
		
	elseif iPackageMode == 2 ;Patrol Mode.
		
		;Check if we will randomise start loc before any loop can begin.
		if bRandomiseStartLoc ;Patrol mode ignores bSpreadSpawnsToChildPoints flag. 
			iSize = (kChildPoints.Length) - 1
			iStartLoc = Utility.RandomInt(0,iSize)
		endif

	endif ;If none of the above resolved, we won't be using TravelLocs. ApplyPackage loops deal with this accordingly.
	
	;Security check on kPackageLocs array, in case we used it in a way that requires this.
	if kPackageLocs[0] == None
		kPackageLocs.Remove(0)
	endif

	
	;Finally, start the correct Spawn Loop for the Package Mode selected.
	;--------------------------------------------------------------------
	
	;DEV NOTE: Most of the below could be consolidated into one function at the cost of repeated checks during SpawnActor while loops on the
	;Package mode. I would much prefer having indivdiual functions that just do what they need to instead of running this check each loop.
	
	;DEV NOTE 2: From this point on, things can get confusing quick as some functions are reused for some Package Modes and are mixed and matched. 
	;Basically it works like this:
	; - Sandbox/Hold use SpawnActorSingleLocLoop, and uses ApplyPackageSingleLocData()
	; - Travel Package and Patrol Package use same SpawnLoop, but both have their own Package Loops.
	; - Interior Mode has it's own SpawnLoop, but uses ApplyPackageSingleLocData() (during the SpawnLoop)
	; - Rush Package is always checked first as it supports a few modes (and overrides them), uses same SpawnLoop as Travel/Patrol, but uses ApplyPackageSingleLocData()
	; - Mode 3 Ambush (Distance based) uses ApplyPackageSingleLocData() from it's event block.
	; - Mode 5 Ambush does not use an ApplyPackage loop at all, but uses SpawnActorNoPackageRandomChildLoop to spawn.
	
	
	Int iRegularActorCount ;Required for loot system

;-------------------------------------------------------------------------------------------------------------------------------------------------------
	
	if bApplyRushPackage ;Check this first.
	;DEV NOTE: Although this effectively uses same code as Travel/Patrol below, it is supported in other modes so easier to check first.
	;and encapsulate like so.
	
		if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely

			SpawnActorNoPackageLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
			kRegularUnits, kEz, bApplySwarmBonus, iStartLoc, false, iDifficulty)
			
			iRegularActorCount = (kGroupList.Length) ;Required for loot system

			if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
				SpawnActorNoPackageLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
				kBossUnits, kEz, bApplySwarmBonus, iStartLoc, true, iDifficulty)
			endif

		else ;Randomise the Ez

			SpawnActorRandomEzNoPackageLoop(ActorParams.iMaxAllowed, ActorParams.iChance, kRegularUnits, \
			kEzList, bApplySwarmBonus, iStartLoc, false, iDifficulty)
			
			iRegularActorCount = (kGroupList.Length) ;Required for loot system

			if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
				SpawnActorRandomEzNoPackageLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
				kBossUnits, kEzList, bApplySwarmBonus, iStartLoc, true, iDifficulty)
			endif

		endif
		
		
		iSize = kGroupList.Length
		while iCounter < iSize
			ApplyPackageSingleLocData(kPackageRush, kGroupList[iCounter], kPackageLocs[0]) ;Parameter should have been set above.
			iCounter += 1
		endwhile
	
;-------------------------------------------------------------------------------------------------------------------------------------------------------	
	
	elseif iPackageMode == 0 ;Sandbox Mode
	;DEV NOTE: Sandbox Package is applied DURING the Spawn loop (not after), as this allows each Actor to get comfortable first. It also somewhat
	;prevents the user from seeing a mob huddled together when first starting sandboxing. 
		
		If !bSpreadSpawnsToChildPoints ;More likely false
			
			if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely
					
				SpawnActorSingleLocLoop(ActorParams.iMaxAllowed, ActorParams.iChance, kRegularUnits, \
				kEz, bApplySwarmBonus, iStartLoc, false, iDifficulty)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system
					
				if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
					SpawnActorSingleLocLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEz, bApplySwarmBonus, iStartLoc, true, iDifficulty)
				endif

			else ;Randomise the Ez

				SpawnActorRandomEzSingleLocLoop(ActorParams.iMaxAllowed, ActorParams.iChance, kRegularUnits, \
				kEzList, bApplySwarmBonus, iStartLoc, false, iDifficulty)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system

				if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
					SpawnActorRandomEzSingleLocLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEzList, bApplySwarmBonus, iStartLoc, true, iDifficulty)
				endif
					
			endif
			
		else ;Assume true
		
			if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely

				SpawnActorSingleLocRandomChildLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
				kRegularUnits, kEz, bApplySwarmBonus, false, iDifficulty, false)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system

				if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
					SpawnActorSingleLocRandomChildLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEz, bApplySwarmBonus, true, iDifficulty, false)
				endif

			else ;Randomise the Ez

				SpawnActorRandomEzSingleLocRandomChildLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
				kRegularUnits, kEzList, bApplySwarmBonus, false, iDifficulty, false)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system
					
				if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
					SpawnActorRandomEzSingleLocRandomChildLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEzList, bApplySwarmBonus, true, iDifficulty, false)
				endif

			endif
			
		endif
	
;-------------------------------------------------------------------------------------------------------------------------------------------------------
	
	elseif iPackageMode < 4 ;Travel/Patrol Mode, can assume above failed. 
	;DEV NOTE: As of version 0.13.01, ApplyPackage Travel/Patrol loops are done after spawn placement as this seems to allow groups to travel closer together.
	;Also improves performance of SpawnLoops as latent calls are done after in quick succession. Both of these use the NoPackage Spawn Loop. 
	
		if (!bSpreadSpawnsToChildPoints) || (iPackageMode == 2)	;More likely false, unsupported for Patrols. 
			
			if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely

				SpawnActorNoPackageLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
				kRegularUnits, kEz, bApplySwarmBonus, iStartLoc, false, iDifficulty)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system
					
				if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
					SpawnActorNoPackageLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEz, bApplySwarmBonus, iStartLoc, true, iDifficulty)
				endif

			else ;Randomise the Ez

				SpawnActorRandomEzNoPackageLoop(ActorParams.iMaxAllowed, ActorParams.iChance, kRegularUnits, \
				kEzList, bApplySwarmBonus, iStartLoc, false, iDifficulty)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system
					
				if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
					SpawnActorRandomEzNoPackageLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEzList, bApplySwarmBonus, iStartLoc, true, iDifficulty)
				endif

			endif
			
			
		else ;Assume true and Package Mode 1/3. 
		
			if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely

				SpawnActorNoPackageRandomChildLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
				kRegularUnits, kEz, bApplySwarmBonus, false, iDifficulty, false)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system
					
				if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
					SpawnActorNoPackageRandomChildLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEz, bApplySwarmBonus, true, iDifficulty, false)
				endif

			else ;Randomise the Ez

				SpawnActorRandomEzNoPackageRandomChildLoop(ActorParams.iMaxAllowed, ActorParams.iChance, kRegularUnits, \
				kEzList, bApplySwarmBonus, false, iDifficulty, false)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system
					
				if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
					SpawnActorRandomEzNoPackageRandomChildLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEzList, bApplySwarmBonus, true, iDifficulty, false)
				endif

			endif
			
		endif
		
		
		;Finally, set the Package on all actors in quick succession.
		;------------------------------------------------------------
		
		iSize = kGroupList.Length
		
		if iPackageMode == 1 
			
			iSize = kGroupList.Length
			while iCounter < iSize
				ApplyPackageTravelData(kGroupList[iCounter], kPackageLocs)
				iCounter += 1
			endwhile
				
		elseif iPackageMode == 2

			;Apply loop
			iSize = kGroupList.Length
			while iCounter < iSize
				ApplyPackagePatrolData(kGroupList[iCounter], iStartLoc)
				iCounter += 1
			endwhile

		endif
		
;-------------------------------------------------------------------------------------------------------------------------------------------------------
	
	elseif iPackageMode == 4 ;Interior Mode
	;DEV NOTE: Package application for Interior Mode must be done during Spawn loop, same as Sandbox/Hold Mode. Uses SpawnActorSingleLocRandomChildLoop()
	;DEV NOTE 2: Interior Mode does not Expend ChildPoints by design. 
	
		if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely
	
			SpawnActorSingleLocRandomChildLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
			kRegularUnits, kEz, bApplySwarmBonus, false, iDifficulty, false)
			
			iRegularActorCount = (kGroupList.Length) ;Required for loot system
				
			if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
				SpawnActorSingleLocRandomChildLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
				kBossUnits, kEz, bApplySwarmBonus, true, iDifficulty, false)
			endif

		else ;Randomise the Ez

			SpawnActorRandomEzSingleLocRandomChildLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
			kRegularUnits, kEzList, bApplySwarmBonus, false, iDifficulty, false)
			
			iRegularActorCount = (kGroupList.Length) ;Required for loot system
	
			if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
				SpawnActorRandomEzSingleLocRandomChildLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
				kBossUnits, kEzList, bApplySwarmBonus, true, iDifficulty, false)
			endif
				
		endif

	
	endif
	
;-------------------------------------------------------------------------------------------------------------------------------------------------------

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


;Similar to the above function, but simpler. Skips random events and other intricacies. This is the only function that supports Package Mode 5. 
;DEV NOTE: This function may not really be necessary and an extra check could be added to the above. However, I enjoy the idea of having it anyway. 
Function PrepareSingleGroupNoEventSpawn()

	;Values used throughout block
	Int iCounter
	Int iSize

	;Get the Actor data for spawning
	;--------------------------------

	if iSpawnMode == 0 ;Random spawn from SpawnType
	
		;Get a random Actor, pulling the ClassPresetScript directly.
		if iForceUseRarityList > 0 && iForceUseRarityList < 4 ;Security measure, cannot get rarity outside 1-3
			ActorParamsScript = SpawnTypeScript.GetRandomActor(iForceUseRarityList, bForceClassPreset, iForcedClassPreset) ;returns ActorClassPresetScript
			;Security check for iForcedClassPreset is done on STRegionalScript
		else 
			ActorParamsScript = SpawnTypeScript.GetRandomActor(0, bForceClassPreset, iForcedClassPreset) ;returns ActorClassPresetScript
		endif
		
		;Create direct links to ActorManagerScript and ClassDetailsStruct
		
		ActorManager = ActorParamsScript.ActorManager
		;We'll get this now as it will have to be passed to the loop as well as various other work which makes this essential
		
		;Now we'll check if we are in a confined space and Actor is oversized
		while (bIsConfinedSpace) && (ActorManager.bIsOversizedActor) ;While true and rolled actor is oversized (get another)
			if iForceUseRarityList > 0 && iForceUseRarityList < 4 ;Security measure, cannot get rarity outside 1-3
				ActorParamsScript = SpawnTypeScript.GetRandomActor(iForceUseRarityList, bForceClassPreset, iForcedClassPreset) ;returns ActorClassPresetScript
				;Security check for iForcedClassPreset is done on STRegionalScript
			else 
				ActorParamsScript = SpawnTypeScript.GetRandomActor(0, bForceClassPreset, iForcedClassPreset) ;returns ActorClassPresetScript
			endif
			ActorManager = ActorParamsScript.ActorManager
		endwhile
		
		
	elseif iSpawnMode == 1 ;Specific Actor
	
		;Link with ClassPresetScript to use. Remember, ActorManager was set in SetSpScriptLinks() block. 
		ActorParamsScript = ActorManager.GetClassPreset(iClassToSpawn) ;If ClassToSpawn entered is not defined for the Actor, returns the debug preset.
	
	endif
		
	
	;Now we get the spawn parameters according to Preset & Difficulty
	;-----------------------------------------------------------------
	
	Int iPreset
	if bForceMasterPreset
	
		if iForcedMasterPreset == 777 ;Check if wanting to randomise
			iPreset = Utility.RandomInt(1,3)
		else
			iPreset = iForcedMasterPreset
		endif
		
	else
	
		if iSpawnMode == 0
			iPreset = SpawnTypeScript.iCurrentPreset
		elseif iSpawnMode == 1
			iPreset = RegionManager.iCurrentPreset
		endif
		
	endif
	ClassDetailsStruct ActorParams = ActorParamsScript.ClassDetails[iPreset]
	
	;Set difficulty for spawning.
	Int iDifficulty
	if bForceDifficulty
		iDifficulty = iForcedDifficulty
	else
		iDifficulty = RegionManager.iCurrentDifficulty
	endif


	;Organise the ActorBase arrays/Get GroupLoadout.
	;------------------------------------------------
	
	SOTC:ActorGroupLoadoutScript GroupLoadout = ActorParamsScript.GetRandomGroupScript()
	
	ActorBase[] kRegularUnits = (GroupLoadout.kGroupUnits) as ActorBase[] ;Cast to copy locally
	ActorBase[] kBossUnits
	Bool bBossAllowed ;Later used as parameter.
	if (ActorParams.iChanceBoss as Bool) && (GroupLoadout.kBossGroupUnits[0] != None) ;Check if Boss allowed and there is actually Boss on this GL.
		kBossUnits = (GroupLoadout.kBossGroupUnits) as ActorBase[] ;Cast to copy locally
	endif
	
	
	;Check and setup EncounterZone data
	;-----------------------------------
	
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
	
	
	;Set PackageLocs if required
	;----------------------------
	
	ObjectReference[] kPackageLocs = new ObjectReference[1] ;Create it, even if it is unused later.
	;Initialised with one member for security reasons. This member of None is removed later, if required.
	Int iStartLoc = -1 ;Used if randomising the ChildPoint to spawn at. Default value = Self.
	
	if iPackageMode > 2; Short-circuit, the below is not supported for Package Modes above this. 
		;Skip All
	
	elseif iPackageMode == 0 ;Sandbox/Hold
	
		if !bSpreadSpawnsToChildPoints ;This setting takes precedence over the below. 
		
			if bRandomiseStartLoc ;Place spawned group at random ChildPoint around the SP.
				iSize = (kChildPoints.Length) - 1
				iStartLoc = Utility.RandomInt(-1,iSize)	; -1 uses Self	instead of ChildPoint.
				
			elseif iNumPackageLocsRequired > 0 ;Only checks if greater than 0, but only uses 1 location which should be defined on kChildPoints[0].
				iStartLoc = 0 ;First member of ChildPoints expected to be filled.
				
			endif
			
		endif
		
	elseif iPackageMode == 1 ;Travel mode, get locations required
	;DEV NOTE: Although we are just checking this value (for speed), only works with Package mode 0 and 1 (Sandbox and Travel).
		
		kPackageLocs = RegionManager.GetRandomTravelLocs(iNumPackageLocsRequired)
		
		;Check if we will randomise start loc before any loop can begin.
		if (!bSpreadSpawnsToChildPoints) && (bRandomiseStartLoc) ;Place spawned group at random ChildPoint around the SP.
			iSize = (kChildPoints.Length) - 1
			iStartLoc = Utility.RandomInt(-1,iSize)	; -1 uses Self	instead of ChildPoint
		endif
		
	elseif iPackageMode == 2 ;Patrol Mode.
		
		;Check if we will randomise start loc before any loop can begin.
		if bRandomiseStartLoc ;Patrol mode ignores bSpreadSpawnsToChildPoints flag. 
			iSize = (kChildPoints.Length) - 1
			iStartLoc = Utility.RandomInt(0,iSize)
		endif
	
	endif ;If none of the above resolved, we won't be using TravelLocs. ApplyPackage loops deal with this accordingly.

	
	;Finally, begin spawning.
	;-------------------------------------------------------------------------------
	
	;DEV NOTE: Most of the below could be consolidated into one function at the cost of repeated checks during SpawnActor while loops on the
	;Package mode. I would much prefer having indivdiual functions that just do what they need to instead of running this check each loop.
	
	;DEV NOTE 2: From this point on, things can get confusing quick as some functions are reused for some Package Modes and are mixed and matched. 
	;Basically it works like this:
	; - Sandbox/Hold use SpawnActorSingleLocLoop, and uses ApplyPackageSingleLocData()
	; - Travel Package and Patrol Package use same SpawnLoop, but both have their own Package Loops.
	; - Interior Mode has it's own SpawnLoop, but uses ApplyPackageSingleLocData() (during the SpawnLoop)
	; - Rush Package is always checked first as it supports a few modes (and overrides them), uses same SpawnLoop as Travel/Patrol, but uses ApplyPackageSingleLocData()
	; - Mode 3 Ambush (Distance based) uses ApplyPackageSingleLocData() from it's event block.
	; - Mode 5 Ambush does not use an ApplyPackage loop at all, but uses SpawnActorNoPackageRandomChildLoop to spawn.
	
	
	Int iRegularActorCount ;Required for loot system
	
	
	if iPackageMode == 0 ;Sandbox Mode
	;DEV NOTE: Sandbox Package is applied DURING the Spawn loop (not after), as this allows each Actor to get comfortable first. It also somewhat
	;prevents the user from seeing a mob huddled together when first starting sandboxing. 
		
		if !bSpreadSpawnsToChildPoints ;More likely false
		
			if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely

				SpawnActorSingleLocLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
				kRegularUnits, kEz, false, iStartLoc, false, iDifficulty)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system

				if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
					SpawnActorSingleLocLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEz, false, iStartLoc, true, iDifficulty)
				endif

			else ;Randomise the Ez

				SpawnActorRandomEzSingleLocLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
				kRegularUnits, kEzList, false, iStartLoc, false, iDifficulty)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system

				if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
					SpawnActorRandomEzSingleLocLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEzList, false, iStartLoc, true, iDifficulty)
				endif

			endif
			
			
		else ;Assume true
		
			if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely
			
				SpawnActorSingleLocRandomChildLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
				kRegularUnits, kEz, false, false, iDifficulty, false)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system

				if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
					SpawnActorSingleLocRandomChildLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEz, false, true, iDifficulty, false)
				endif

			else ;Randomise the Ez

				SpawnActorRandomEzSingleLocRandomChildLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
				kRegularUnits, kEzList, false, false, iDifficulty, false)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system

				if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
					SpawnActorRandomEzSingleLocRandomChildLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEzList, false, true, iDifficulty, false)
				endif

			endif
			
		endif
	
;-------------------------------------------------------------------------------------------------------------------------------------------------------
	
	elseif iPackageMode < 4 ;Travel/Patrol/Ambush(distance-based) Modes, can assume above failed.
	;DEV NOTE: As of version 0.13.01, ApplyPackage Travel/Patrol loops are done after spawn placement as this seems to allow groups to travel closer together.
	;Also improves performance of SpawnLoops as latent calls are done after in quick succession. Both of these use the NoPackage Spawn Loop. 
	
		if (!bSpreadSpawnsToChildPoints) || (iPackageMode == 2)	;More likely false, unsupported for Patrols.
	
			if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely

				SpawnActorNoPackageLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
				kRegularUnits, kEz, false, iStartLoc, false, iDifficulty)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system
	
				if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
					SpawnActorNoPackageLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEz, false, iStartLoc, true, iDifficulty)
				endif

			else ;Randomise the Ez

				SpawnActorRandomEzNoPackageLoop(ActorParams.iMaxAllowed, ActorParams.iChance, kRegularUnits, \
				kEzList, false, iStartLoc, false, iDifficulty)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system

				if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
					SpawnActorRandomEzNoPackageLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEzList, false, iStartLoc, true, iDifficulty)
				endif

			endif
			
			
		else ;Assume true and Package Mode 1/3. 
		
			if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely

				SpawnActorNoPackageRandomChildLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
				kRegularUnits, kEz, false, false, iDifficulty, false)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system

				if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
					SpawnActorNoPackageRandomChildLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEz, false, true, iDifficulty, false)
				endif

			else ;Randomise the Ez

				SpawnActorRandomEzNoPackageRandomChildLoop(ActorParams.iMaxAllowed, ActorParams.iChance, kRegularUnits, \
				kEzList, false, false, iDifficulty, false)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system
	
				if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
					SpawnActorRandomEzNoPackageRandomChildLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEzList, false, true, iDifficulty, false)
				endif

			endif
			
		endif
		
		
		;Finally, set the Package on all actors in quick succession.
		iSize = kGroupList.Length
		
		if iPackageMode == 1 
			
			iSize = kGroupList.Length
			while iCounter < iSize
				ApplyPackageTravelData(kGroupList[iCounter], kPackageLocs)
				iCounter += 1
			endwhile

		elseif iPackageMode == 2

			;Apply loop
			iSize = kGroupList.Length
			while iCounter < iSize
				ApplyPackagePatrolData(kGroupList[iCounter], iStartLoc)
				iCounter += 1
			endwhile
			
		elseif iPackageMode == 3
		
			RegisterForDistanceLessThanEvent(MasterScript.PlayerRef, Self as ObjectReference, fAmbushDistance) ;Possibly faster then Game.GetPlayer()

		endif
		
;-------------------------------------------------------------------------------------------------------------------------------------------------------
	
	elseif iPackageMode == 4 ;Interior Mode
	;DEV NOTE: Package application for Interior Mode must be done during Spawn loop, same as Sandbox/Hold Mode. 
	
		if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely
	
			SpawnActorSingleLocRandomChildLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
			kRegularUnits, kEz, false, false, iDifficulty, false)
			
			iRegularActorCount = (kGroupList.Length) ;Required for loot system

			if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
				SpawnActorSingleLocRandomChildLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
				kBossUnits, kEz, false, true, iDifficulty, false)
			endif

		else ;Randomise the Ez

			SpawnActorRandomEzSingleLocRandomChildLoop(ActorParams.iMaxAllowed, ActorParams.iChance, \
			kRegularUnits, kEzList, false, false, iDifficulty, false)
			
			iRegularActorCount = (kGroupList.Length) ;Required for loot system
	
			if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
				SpawnActorRandomEzSingleLocRandomChildLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
				kBossUnits, kEzList, false, true, iDifficulty, false)
			endif

		endif
		
	endif
	
;-------------------------------------------------------------------------------------------------------------------------------------------------------


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
;SPAWN LOOPS
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;DEV NOTE: Most of the below can be consolidated into one function at the cost of repeated checks during SpawnActor while loops on the Package mode. 
;I would much prefer having indivdiual functions that just do what they need to instead of running this check each loop.

;DEV NOTE 2: From this point on, things can get confusing quick as some functions are reused for some Package Modes and are mixed and matched. 
;Basically it works like this:
; - Sandbox/Hold use SpawnActorSingleLocLoop, which uses ApplyPackageSingleLocData() during loop.
; - Travel Package and Patrol Package use same SpawnLoop, but both have their own Package Loops.
; - Interior Mode uses SpawnActorSingleLocRandomChildLoop, which uses ApplyPackageSingleLocData() (during the SpawnLoop).
; - Rush Package is always checked first as it supports a few modes (and overrides them), uses same SpawnLoop as Travel/Patrol, but uses ApplyPackageSingleLocData().
; - Mode 3 Ambush (Distance based) uses ApplyPackageSingleLocData() from it's event block.
; - Mode 5 Ambush does not use an ApplyPackage loop at all, but uses SpawnActorNoPackageRandomChildLoop to spawn. 



;SINGLE LOCATION LOOPS W/ PACKAGE APPLICATION INCLUDED ("SingleLoc" refers to the type of Package Application really)
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;DEV NOTE: kPackage/ApplyData is applied DURING these Spawn loops, as this allows each Actor to get comfortable first (i.e Sandbox/Hold). It also somewhat
;prevents the user from seeing a mob huddled together when first starting sandboxing. 

Function SpawnActorSingleLocLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, EncounterZone akEz, \
Bool abApplySwarmBonus, Int aiStartLoc, Bool abIsBossSpawn, Int aiDifficulty) ;aiStartLoc default value = Self
	
	if abApplySwarmBonus ;Apply Swarm bonus settings if true, else skip
	
		if !abIsBossSpawn
			aiMaxCount += ActorManager.iSwarmMaxCountBonus
			aiChance += ActorManager.iSwarmChanceBonus
		else
			aiMaxCount += ActorManager.iSwarmMaxCountBossBonus
			aiChance += ActorManager.iSwarmChanceBossBonus
		endif
		
	endif
	
	;Determine initial location to spawn at
	ObjectReference kStartLoc
	if aiStartLoc == -1 ;Use Self
		kStartLoc = Self as ObjectReference
	else ;Use ChildPoint location
		kStartLoc = kChildPoints[aiStartLoc]
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
	kSpawned = kStartLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, akEz) ;akEz can be None
	kGroupList.Add(kSpawned) ;Add to Group tracker
	
	;Begin chance based placement loop for the rest of the Group
	while iCounter <= aiMaxCount
		
		;Check Line of sight to Player. 
		while kPlayerRef.HasDetectionLos(kStartLoc)
			iLosCounter += 1 ;Line of sight fail counter will return this function if hits 25 (2.5 seconds wasted).
			if iLosCounter >= 25 ;Better to check now.
				return ;Stop spawning and kill the function. Player is looking too frequently.
			endif
			Utility.Wait(0.1)
		endwhile
		
		;Else continue to place Actor.	
		if (Utility.RandomInt(1,100)) <= aiChance
			kSpawned = kStartLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, akEz) ;akEz can be None
			kGroupList.Add(kSpawned) ;Add to Group tracker
			ApplyPackageSingleLocData(kPackage, kSpawned, kStartLoc)
		endif
		
		iCounter +=1
	
	endwhile

EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------

Function SpawnActorRandomEzSingleLocLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, EncounterZone[] akEzList, \
Bool abApplySwarmBonus, Int aiStartLoc, Bool abIsBossSpawn, Int aiDifficulty) ;aiStartLoc default value = Self

	if abApplySwarmBonus ;Apply Swarm bonus settings if true, else skip
	
		if !abIsBossSpawn 
			aiMaxCount += ActorManager.iSwarmMaxCountBonus
			aiChance += ActorManager.iSwarmChanceBonus
		else
			aiMaxCount += ActorManager.iSwarmMaxCountBossBonus
			aiChance += ActorManager.iSwarmChanceBossBonus
		endif
		
	endif
	
	;Determine initial location to spawn at
	ObjectReference kStartLoc
	if aiStartLoc == -1 ;Use Self
		kStartLoc = Self as ObjectReference
	else ;Use ChildPoint location
		kStartLoc = kChildPoints[aiStartLoc]
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
	kSpawned = kStartLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, kEz) ;akEz can be None
	kGroupList.Add(kSpawned) ;Add to Group tracker
	
	;Begin chance based placement loop for the rest of the Group
	while iCounter <= aiMaxCount
		
		;Check Line of sight to Player. 
		while kPlayerRef.HasDetectionLos(kStartLoc)
			iLosCounter += 1 ;Line of sight fail counter will return this function if hits 25 (2.5 seconds wasted).
			if iLosCounter >= 25 ;Better to check now.
				return ;Stop spawning and kill the function. Player is looking too frequently.
			endif
			Utility.Wait(0.1)
		endwhile
		
		;Else continue to place Actor.	
		if (Utility.RandomInt(1,100)) <= aiChance
			kEz = akEzList[(Utility.RandomInt(0,iEzListSize))] ;Randomise EZ each loop
			kSpawned = kStartLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, kEz) ;akEz can be None
			kGroupList.Add(kSpawned) ;Add to Group tracker
			ApplyPackageSingleLocData(kPackage, kSpawned, kStartLoc)
		endif
		
		iCounter +=1
	
	endwhile

EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------

;The following 2 functions are refactors of the above 2, and used to spread placement of Actors out to ChildPoints. Slower due to randomising the marker 
;to spawn at. These 2 are used by Interiors in order to achieve a relatively even distribution of actors throughout an interior cell. Can optionally 
;"expend" the marker being spawned at, in order to prevent other spawns dropping at the same marker again (will cut group Max Count to number of 
;ChildPoints available if using this option).

Function SpawnActorSingleLocRandomChildLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, EncounterZone akEz, \
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
	Actor kSpawned
	ObjectReference kSpawnLoc
	Actor kPlayerRef = MasterScript.PlayerRef ;Grab for LoS checks.
	
	;First we must ensure the MaxCount received does not exceed number of ChildPoints, if we expending Points each Spawn.
	if abExpendPoint
		
		if aiMaxCount > (kChildPoints.Length)
			aiMaxCount = (kChildPoints.Length)
		endif
	endif
	
	;Spawn the guaranteed first Actor
	kSpawnLoc = GetChildPoint(abExpendPoint) ;Place at a random marker in the cell/child cell (if exists)
	kSpawned = kSpawnLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, akEz) ;akEz can be None
	kGroupList.Add(kSpawned) ;Add to Group tracker
	ApplyPackageSingleLocData(kPackage, kSpawned, kSpawnLoc)
	
	;Begin chance based placement loop for the rest of the Group
	while iCounter <= aiMaxCount
		
		kSpawnLoc = GetChildPoint(abExpendPoint) ;Place at a random marker in the cell/child cell (if exists)
		
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
			ApplyPackageSingleLocData(kPackage, kSpawned, kSpawnLoc)
			
		endif
		
		iCounter +=1
	
	endwhile

EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------

Function SpawnActorRandomEzSingleLocRandomChildLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, EncounterZone[] akEzList, \ 
Bool abApplySwarmBonus, Bool abIsBossSpawn, Int aiDifficulty, Bool abExpendPoint) ;For lack of better name :D

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
	EncounterZone kEz
	Actor kSpawned
	ObjectReference kSpawnLoc
	Actor kPlayerRef = MasterScript.PlayerRef ;Grab for LoS checks.
	
	;First we must ensure the MaxCount received does not exceed number of ChildPoints, if we expending Points each Spawn.
	if abExpendPoint
		
		if aiMaxCount > (kChildPoints.Length)
			aiMaxCount = (kChildPoints.Length)
		endif
	endif
	
	;Spawn the guaranteed first Actor
	kEz = akEzList[(Utility.RandomInt(0,iEzListSize))] ;Randomise each loop
	kSpawnLoc = GetChildPoint(abExpendPoint) ;Place at a random marker in the cell/child cell (if exists)
	kSpawned = kSpawnLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, kEz) ;kEz can be None
	kGroupList.Add(kSpawned) ;Add to Group tracker
	ApplyPackageSingleLocData(kPackage, kSpawned, kSpawnLoc)
	
	;Begin chance based placement loop for the rest of the Group
	while iCounter <= aiMaxCount
		
		kSpawnLoc = GetChildPoint(abExpendPoint) ;Place at a random marker in the cell/child cell (if exists)
		
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
			ApplyPackageSingleLocData(kPackage, kSpawned, kSpawnLoc)
			
		endif
		
		iCounter +=1
	
	endwhile

EndFunction



;PACKAGELESS LOOPS - USE FOR TRAVEL/PATROL/STATIC PLACEMENT
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;DEV NOTE: These loops do not apply any package, they simply drop the Actor. It is expected the calling function will run ApplyPackage loop after this.

Function SpawnActorNoPackageLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, EncounterZone akEz, \
Bool abApplySwarmBonus, Int aiStartLoc, Bool abIsBossSpawn, Int aiDifficulty) ;aiStartLoc default value = Self
	
	if abApplySwarmBonus ;Apply Swarm bonus settings if true, else skip
	
		if !abIsBossSpawn 
			aiMaxCount += ActorManager.iSwarmMaxCountBonus
			aiChance += ActorManager.iSwarmChanceBonus
		else
			aiMaxCount += ActorManager.iSwarmMaxCountBossBonus
			aiChance += ActorManager.iSwarmChanceBossBonus
		endif
		
	endif
	
	;Determine initial location to spawn at
	ObjectReference kStartLoc
	if aiStartLoc == -1 ;Use Self
		kStartLoc = Self as ObjectReference
	else ;Use ChildPoint location
		kStartLoc = kChildPoints[aiStartLoc]
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
	kSpawned = kStartLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, akEz) ;akEz can be None
	kGroupList.Add(kSpawned) ;Add to Group tracker
	
	;Begin chance based placement loop for the rest of the Group
	while iCounter <= aiMaxCount
		
		;Check Line of sight to Player. 
		while kPlayerRef.HasDetectionLos(kStartLoc)
			iLosCounter += 1 ;Line of sight fail counter will return this function if hits 25 (2.5 seconds wasted).
			if iLosCounter >= 25 ;Better to check now.
				return ;Stop spawning and kill the function. Player is looking too frequently.
			endif
			Utility.Wait(0.1)
		endwhile
		
		;Else continue to place Actor.	
		if (Utility.RandomInt(1,100)) <= aiChance
			kSpawned = kStartLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, akEz) ;akEz can be None
			kGroupList.Add(kSpawned) ;Add to Group tracker
		endif
		
		iCounter +=1
	
	endwhile

EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------

Function SpawnActorRandomEzNoPackageLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, EncounterZone[] akEzList, \
Bool abApplySwarmBonus, Int aiStartLoc, Bool abIsBossSpawn, Int aiDifficulty) ;aiStartLoc default value = Self

	if abApplySwarmBonus ;Apply Swarm bonus settings if true, else skip
	
		if !abIsBossSpawn
			aiMaxCount += ActorManager.iSwarmMaxCountBonus
			aiChance += ActorManager.iSwarmChanceBonus
		else
			aiMaxCount += ActorManager.iSwarmMaxCountBossBonus
			aiChance += ActorManager.iSwarmChanceBossBonus
		endif
		
	endif
	
	;Determine initial location to spawn at
	ObjectReference kStartLoc
	if aiStartLoc == -1 ;Use Self
		kStartLoc = Self as ObjectReference
	else ;Use ChildPoint location
		kStartLoc = kChildPoints[aiStartLoc]
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
	kSpawned = kStartLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, kEz) ;akEz can be None
	kGroupList.Add(kSpawned) ;Add to Group tracker
	
	;Begin chance based placement loop for the rest of the Group
	while iCounter <= aiMaxCount
		
		;Check Line of sight to Player. 
		while kPlayerRef.HasDetectionLos(kStartLoc)
			iLosCounter += 1 ;Line of sight fail counter will return this function if hits 25 (2.5 seconds wasted).
			if iLosCounter >= 25 ;Better to check now.
				return ;Stop spawning and kill the function. Player is looking too frequently.
			endif
			Utility.Wait(0.1)
		endwhile
		
		;Else continue to place Actor.	
		if (Utility.RandomInt(1,100)) <= aiChance
			kEz = akEzList[(Utility.RandomInt(0,iEzListSize))] ;Randomise EZ each loop
			kSpawned = kStartLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, kEz) ;akEz can be None
			kGroupList.Add(kSpawned) ;Add to Group tracker
		endif
		
		iCounter +=1
	
	endwhile

EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------

;The following 2 functions are refactors of the above 2, and used to spread placement of Actors out to ChildPoints. Slower due to randomising the marker 
;to spawn at. Can optionally "expend" the marker being spawned at, in order to prevent other spawns dropping at the same marker again (will cut group Max 
;Count to number of ChildPoints available if using this option).
 
Function SpawnActorNoPackageRandomChildLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, \
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
		
		if aiMaxCount > (kChildPoints.Length)
			aiMaxCount = (kChildPoints.Length)
		endif
	endif
	
	;Spawn the first guaranteed Actor
	kSpawnLoc = GetChildPoint(abExpendPoint) ;Place at a random marker in the cell/child cell (if exists)
	kSpawned = kSpawnLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, akEz) ;akEz can be None
	kGroupList.Add(kSpawned) ;Add to Group tracker
	
	;Begin chance based placement loop for the rest of the Group
	while iCounter <= aiMaxCount
		
		kSpawnLoc = GetChildPoint(abExpendPoint) ;Place at a random marker in the cell/child cell (if exists)
		
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

Function SpawnActorRandomEzNoPackageRandomChildLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, \
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
	Int iActorListSize = (akActorList.Length) - 1 ;Need actual size
	Int iEzListSize = (akEzList.Length) - 1 ;Need actual size
	Actor kSpawned
	ObjectReference kSpawnLoc
	EncounterZone kEz
	Actor kPlayerRef = MasterScript.PlayerRef ;Grab for LoS checks.
	
	;First we must ensure the MaxCount received does not exceed number of ChildPoints, if we expending Points each Spawn.
	if abExpendPoint
		
		if aiMaxCount > (kChildPoints.Length)
			aiMaxCount = (kChildPoints.Length)
		endif
	endif
	
	;Spawn the first guaranteed Actor
	kSpawnLoc = GetChildPoint(abExpendPoint) ;Place at a random marker in the cell/child cell (if exists)
	kSpawned = kSpawnLoc.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, kEz) ;akEz can be None
	kGroupList.Add(kSpawned) ;Add to Group tracker
	
	;Begin chance based placement loop for the rest of the Group
	while iCounter <= aiMaxCount
		
		kSpawnLoc = GetChildPoint(abExpendPoint) ;Place at a random marker in the cell/child cell (if exists)
		
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
;PACKAGE APPLICATION LOOPS
;-----------------------------------------------------------------------------------------------------------------------------------------

;Used for a multitude of Packages only needing to link to single point, I.E
;Sandbox/Hold, Rush, Interiors (Sandbox)
Function ApplyPackageSingleLocData(ReferenceAlias akPackage, Actor akActor, ObjectReference akPackageLoc)
;Package must be passed to this one, as it can be used for any Package with only single linked ref requirement.

	
	akActor.SetLinkedRef(akPackageLoc, kPackageKeywords[0])
	akPackage.ApplyToRef(akActor) ;Finally apply the data alias with package
	akActor.EvaluatePackage() ;And evaluate so no delay
	
EndFunction


;Link Actor to travel locs and send on their merry way
Function ApplyPackageTravelData(Actor akActor, ObjectReference[] akPackageLocs)
	
	Int iCounter
	Int iSize = akPackageLocs.Length
		
	while iCounter < iSize
			
		akActor.SetLinkedRef(akPackageLocs[iCounter], kPackageKeywords[iCounter])
		iCounter += 1
		
	endwhile

	kPackage.ApplyToRef(akActor) ;Finally apply the data alias with package
	akActor.EvaluatePackage() ;And evaluate so no delay
	
EndFunction


;Links Actor to each ChildPoint, in order specified (optionally starting at a different location in the array), for Patrol.
Function ApplyPackagePatrolData(Actor akActor, Int aiStartLoc)
	
	;Starts at aiStartLoc, loops back if necessary to keep links in order.
	Int iCounter  = aiStartLoc
	Int iSize = kChildPoints.Length
	Int iKeywordCounter = 0
		
	while iCounter < iSize
	
		akActor.SetLinkedRef(kChildPoints[iCounter], kPackageKeywords[iKeywordCounter])
		;WARNING: Must be as many Keywords defined as ChildPoints
		iCounter += 1
		iKeywordCounter += 1

	endwhile
		
	iCounter = 0
		
	while iCounter < aiStartLoc
		
		akActor.SetLinkedRef(kChildPoints[iCounter], kPackageKeywords[iKeywordCounter])
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

Event OnDistanceLessThan(ObjectReference akObj1, ObjectReference akObj2, float afDistance)
;DEV NOTE: Supports Ambush from this script only, no initial checks will take place.
	
	Int iCounter
	Int iSize = kGroupList.Length
	ObjectReference kPlayer = (MasterScript.PlayerRef) as ObjectReference ;Possibly faster than Game.GetPlayer()
	
	while iCounter < iSize
		ApplyPackageSingleLocData(kPackageRush, kGroupList[iCounter], kPlayer) ;Parameter should have been set above.
		iCounter += 1
	endwhile
	
EndEvent


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;MULTIPOINT MODE SPAWN FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;DEV NOTE: This function creates new instances of the SpHelperScript, and gives each instance all the information needed to do it's own Spawning. These
;new instances are created at "ChildPoints", or Markers, which have been placed nearby the SpawnPoint, and listed in the above array Property. 

Function PrepareMultiGroupSpawn()
	
	;WARNING: DO NOT USE MULTIPOINTS IN CONFINED SPACES WITH SPAWNTYPES THAT HAVE OVERSIZED ACTORS - USE MULTIPLE SINGLE POINTS INSTEAD
	
	;Get Random list of Actors OR predefined Actor.
	;----------------------------------------------
	
	Int iGroupsToSpawn
	SOTC:ActorClassPresetScript[] ActorParamsScriptList
	
	if iSpawnMode == 0 ;Randomise
		
		if iForceGroupsToSpawnCount == 0 ;This is more likely, check first
			iGroupsToSpawn = MasterScript.RollGroupsToSpawnCount(((kChildPoints.Length) - 1)) ;Number of members on kChildPoints array is the limit
		else ;Safely assume we are forcing the amount
			iGroupsToSpawn = iForceGroupsToSpawnCount
		endif
		ActorParamsScriptList = SpawnTypeScript.GetRandomActors(iForceUseRarityList, bForceClassPreset, iForcedClassPreset, iGroupsToSpawn)
		
	elseif iSpawnMode == 1
		
		ActorParamsScriptList = new SOTC:ActorClassPresetScript[1]
		ActorParamsScriptList[0] = ActorManager.GetClassPreset(iClassToSpawn) ;If ClassToSpawn entered is not defined for the Actor, returns the debug preset.
		
	endif
	
	
	;Now we get the spawn parameters according to Preset & Difficulty
	;-----------------------------------------------------------------
	
	Int iPreset
	if bForceMasterPreset
	
		if iForcedMasterPreset == 777 ;Check if wanting to randomise
			iPreset = Utility.RandomInt(1,3)
		else
			iPreset = iForcedMasterPreset
		endif
		
	else
	
		if iSpawnMode == 0
			iPreset = SpawnTypeScript.iCurrentPreset
		elseif iSpawnMode == 1
			iPreset = RegionManager.iCurrentPreset
		endif
		
	endif
		
	;Set difficulty for spawning.
	Int iDifficulty
	if bForceDifficulty
		iDifficulty = iForcedDifficulty
	else
		iDifficulty = RegionManager.iCurrentDifficulty ;Set difficulty for spawning.
		
	endif
	
	
	;Now check/get Package locations if required
	;--------------------------------------------
	
	ObjectReference[] kPackageLocs = new ObjectReference[0] ;Create it, because even if we skip it, it still has to be passed to loop

	if (bSpreadSpawnsToChildPoints) || (iPackageMode == 2) ;Patrol Mode, use ChildPoints array.
		kPackageLocs = kChildPoints
	elseif iNumPackageLocsRequired < 0
		kPackageLocs = RegionManager.GetRandomTravelLocs(iNumPackageLocsRequired)
	endif ;If nothing returned here, we must be using Sandbox package (Helpers will use Self as loc). If not weird things may happen.
	
	
	;Finally start creating Helper instances and giving them params. 
	;---------------------------------------------------------------
	
	Int iCounter
	ObjectReference kSpawnPoint
	ObjectReference kHelper
	kActiveHelpers = new ObjectReference[1] ;Init with one member, as Papyrus may trash it if not and we take too long.
	Bool bExpendPoint = false
	
	
	if (!bSpreadSpawnsToChildPoints) && (iPackageMode != 2)	;Expends Points if NOT spreading spawns and Patrol Mode.
		bExpendPoint = true ;Saves more expensive check in loops below.
	endif
	
	;Due to Package Mode 3, this is necessary as uses Rush Package. 
	ReferenceAlias kPackageToSend
	if iPackageMode == 3
		kPackageToSend = kPackageRush
	else
		kPackageToSend = kPackage
	endif
	
	
	Int iStartLoc ;Only used if Package Mode 2 - Patrol. 
	
	if iSpawnMode == 0 ;Random mode
	;DEV NOTE: Faster to check for SP Mode now, rather than in while loops below. Difference is only index of ActorParamsScriptList passed.
		
		while iCounter < iGroupsToSpawn
			
			kSpawnPoint = GetChildPoint(bExpendPoint)
			if iPackageMode == 2 ;We will need to determine the Int index of the ChildPoint received if in Patrol Mode, so Helper can link in correct order.
				iStartLoc = kChildPoints.Find(kSpawnPoint)
			elseif iPackageMode == 3 ;We will send AMbush Distance setting as the iStartLoc instead
				iStartLoc = fAmbushDistance as Int
			endif
			
			kHelper = kSpawnPoint.PlaceAtMe(kMultiPointHelper) ;Place worker
			;Will auto fire after this function in it's own thread via timer
			(kHelper as SOTC:SpHelperScript).SetHelperSpawnParams(RegionManager, ActorParamsScriptList[iCounter], iPackageMode, \
			kPackageToSend, kPackageKeywords, kPackageLocs, bSpreadSpawnsToChildPoints, iPreset, iDifficulty, iStartLoc)
			;NOTE: Calling this function activates the trigger timer on the helper.
			;DEV NOTE: Passing of ThreadController was removed in version 0.13.01 to free up a parameter slot. Gets from Region now.
			
			kActiveHelpers.Add(kHelper) ;Track worker
			iCounter += 1
		
		endwhile
		
	elseif iSpawnMode == 1 ;Specific Actor mode.
	
		while iCounter < iGroupsToSpawn
			
			kSpawnPoint = GetChildPoint(bExpendPoint)
			if iPackageMode == 2 ;We will need to determine the Int index of the ChildPoint received if in Patrol Mode, so Helper can link in correct order.
				iStartLoc = kChildPoints.Find(kSpawnPoint)
			elseif iPackageMode == 3 ;We will send AMbush Distance setting as the iStartLoc instead
				iStartLoc = fAmbushDistance as Int
			endif
			
			kHelper = kSpawnPoint.PlaceAtMe(kMultiPointHelper) ;Place worker
			;Will auto fire after this function in it's own thread via timer
			(kHelper as SOTC:SpHelperScript).SetHelperSpawnParams(RegionManager, ActorParamsScriptList[0], iPackageMode, \
			kPackageToSend, kPackageKeywords, kPackageLocs, bSpreadSpawnsToChildPoints, iPreset, iDifficulty, iStartLoc)
			;NOTE: Calling this function activates the trigger timer on the helper.
			;DEV NOTE: Passing of ThreadController was removed in version 0.13.01 to free up a parameter slot. Gets from Region now. 
			
			kActiveHelpers.Add(kHelper) ;Track worker
			iCounter += 1
		
		endwhile
		
	endif
	
	
	if kActiveHelpers[0] == None ; Security measure removes first member of None. See notes on Master as to why we do this.
		kActiveHelpers.Remove(0)
	endif
	
	;Still need to inform ThreadController of this particular SP. 
	ThreadController.IncrementActiveSpCount(1)
	
	;GTFO

EndFunction



;-------------------------------------------------------------------------------------------------------------------------------------------------------
;UTILITY FUNCTIONS & EVENTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;Mainly used for MultiPoints to randomise location of Multi-group spawns, using ChildPoints attached to this SP.
ObjectReference Function GetChildPoint(Bool abExpendPoint) ;Parameter added in version 0.13.01 tells function to remove point so cannot be used again this session.

	int iSize = kChildPoints.Length - 1  ;Get random member
	int i = Utility.RandomInt(0,iSize)

	ObjectReference kMarkerToReturn = kChildPoints[i]  ;Get a direct link to Object in array
	
	if abExpendPoint ;Only expend the Marker if true
	
		if !bChildrenActive ;Initialise if not already
			kActiveChildren = new ObjectReference[0] ;This needs to be watched for bugs mentioned in Master with arrays initialised as empty.
			;It is only left like this because the Adds that will occur are very shortly after this so it probably won't get trashed. 
			bChildrenActive = true
		endif
	
		kActiveChildren.Add(kChildPoints[i]) ;Add selected marker to active array
		kChildPoints.Remove(i) ;Remove from original array, guaranteeing it won't be selected again this session.
		;We will move it back/reset later
		;DEV NOTE: This works on Array Properties that are non-const only.
	endif
	
	return kMarkerToReturn ;Return the temp set from earlier
	
EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
