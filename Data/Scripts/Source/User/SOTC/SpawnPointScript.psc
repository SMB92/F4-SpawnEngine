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
{ Not all Mandatory Properties are required. Set this way so author can double check all required Proeprties are set for the selected Mode. }

	SOTC:MasterQuestScript Property MasterScript Auto Const Mandatory
	{ Fill with MasterQuest }
	
	Activator Property kMultiPointHelper Auto Const Mandatory
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
	{ 0 = Random from SpawnType, 1 = Specific Actor, 2 = Use ID list. Fill ID number(s) below accordingly. }
	
	Int Property iSpawnTypeOrActorID Auto Const Mandatory
	{ Fill with ID (index) of SpawnType or Actor type for use in Modes 0 and 1. See commentary for ID No. legend. }
	
	Int[] Property iModeTwoActorList Auto Const
	{ If using SpawnMode 2, define a list of Actor IDs here to use in spawning. }
	;DEV NOTE: This had to be made a new Property as opposed to converting the Proeprty above it to an array as this would break
	;many already placed SpawnPoints as of version 0.19.01. 
	
	Int Property iClassToSpawn Auto Const Mandatory
	{ Set the ClassPreset to use if spawning a specific Actor type (iSpawnMode = 1, ignored if not, use overrides below for that). 
Enter 777 to randomise main 1-3 rarity-based Class Presets, 0 is debug, 1-3 Rarity based, 4 Amush (Rush), 5 Sniper. 
Actor must have this Class Preset defined or this will return Debug Preset (0). }
	
	Int Property iPackageMode Auto Const Mandatory
	{ 0 = Sandbox, 1 = Travel, 2 = Patrol, 3 = Ambush (distance based), 4 = HoldPosition (Sniper etc) 5 = Interior(Random ChildPoint Sandbox, 
can be used in exteriors, check bIsInterior flag if using in Interior). See Package legend in script/docs for details. }

	;LEGEND - PACKAGE MODES (added version 0.13.01, replaces previous notes.)
	;A number of different package modes are available. User must provide correct package that matches the data
	;set on the SpawnPoint (or weird things may happen). They are as follows:
	; BOOL FLAG - BISMULTIPOINT: In this mode, the Parent SP will create "Helper" SpawnPoints at "ChildPoints" around
	;the Parent which are defined by the author in the ChildPoints array. The Parent passes data to each Helper which
	;then does the spawning of a group. This mostly exists to spawn enemy groups in parallel for emulating battles,
	;but not strictly. The number of groups to spawn can be forced, or randomised (based on the number of ChildPoints
	;defined). Some Package modes may not work with this, or work differently. See below.
	; 0 - SANDBOX: Actors will sandbox at the SpawnPoint, or a ChildPoint if provided. Works with MultiPoint mode.
	; 1 - TRAVEL: Spawns will travel to random locations markers in the Region. Set iNumPackageLocsRequired to the
	;number of locations desired. Works with MultiPoint mode, but will only use a single location.
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
	;used with same Actor type. Using this mode will force the use of Spawntype[11] (Ambush - Rush). If the Player 
	;escapes, Actors will return and sandbox at spawn location.
	; 4 - HOLD POSITION: This was separated from Mode 0 in version 0.20.01. Best used with Snipers as it will make the
	;Actors stay in the one location.
	; 5 - INTERIOR (Can be used in exteriors, forces certain function path): This mode will place spawns at a random
	;ChildPoint defined in the cell, and sandbox there. This mode doesn't strictly have to be used in an Interior,
	;it was purpose made to emulate pre-placed spawns in Interiors as per vanilla. Other packages can be used instead
	;if desired (Ambush can be a good choice). Works in MultiPoint mode, which can be good for spawning battles among
	;random groups, or multithreading large numbers of the same Actor type.
	;RUSH PACKAGE: Used for both the Rampage and Random Ambush features. The Rampage feature causes spawns to "run"
	;to a single location and sandbox there, which is useful for a stampede of Radstag for instance, among others.
	;The same logic is applied to attacking the Player. This mode can also be useful in emulating a "planned" battle
	;or attack, by causing groups to either run at each other before they can enter combat, or a location as above.
	;In the case of rushing the Player, if the Player escapes, Actors will return and sandbox at spawn location.
	
	
	Bool Property bIsMultiPoint Auto Const
	{ Set true if using child markers to randomise placement of groups. USE WISELY, AND DO NOT USE IN CONFINED SPACES. }
	;WARNING: DO NOT USE MULTIPOINTS IN CONFINED SPACES WITH SPAWNTYPES THAT HAVE OVERSIZED ACTORS - USE MULTIPLE SINGLE POINTS INSTEAD.
	
	Bool Property bIsConfinedSpace Auto Const
	{ If the SP is placed in a confined area, set True so Oversized Actors will not spawn here.
And yes, this is required for interiors as not all interiors are confined. }

	Bool Property bIsInteriorPoint Auto Const ;Re-added in version 0.13.02, to be sued in conjuction with Player distance check.
	{ Set true if this Point is inside of an Interior. Interior Points should not be placed near entry points to the cell, for best effect. }

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



Group PackageData
{ Not all Mandatory Properties are required. Set this way so author can double check all required Proeprties are set for the selected Mode. }
	
	Int Property iSandboxRadiusLevel Auto Const Mandatory
	{ Correlates to the Sandbox Package Alias stored on array below. 0 = 512, 1 = 1024, 2 = 2048, 3 = 3072 Sanboxing radiuses.
This can also be used for Package Mode 5 (Interiors/Spread), will use Level 0 by default. }
	
	Int Property iNumPackageLocsRequired = 1 Auto Const Mandatory
	{ If using Travel or Patrol Package Modes (1/2), set to the number of travel/patrol locations desired. Note that using more than 1 location in
Travel mode will be harder on Papyrus (due hand-holding the AI). You may also consider setting the bIgnoreExpiry flag true so that Actors
aren't disabled midway through their travel. Default value of 1 in case it is forgotten. }
	
	ReferenceAlias[] Property kSandboxPackages Auto Const Mandatory
	{ Fill with SOTC_SandboxPackage Aliases. 0 = 512, 1 = 1024, 2 = 2048, 3 = 3072 Sanboxing radiuses. }
	
	ReferenceAlias[] Property kPatrolPackages Auto Const Mandatory
	{ Fill with SOTC_PatrolPackage Aliases on base. iNumPackageLocsRequired will correlate to correct package here (i.e 2 = 2 patrol locs). }
	
	ReferenceAlias Property SOTC_HoldPackageAlias_Basic Auto Const Mandatory
	{ Auto-fill on base. }
	
	ReferenceAlias Property SOTC_TravelPackageAlias_Basic Auto Const Mandatory
	{ Auto-fill on base. This Package has no Sandboxing by default - if using single Travel Destination, change this to use SOTC_TravelPackageAlias_Sandbox00. }
	
	Package Property SOTC_TravelPackageBasic Auto Const Mandatory 
	{ Auto-fill on base. Required for multi-destination travel procedures. }
	
	ReferenceAlias Property SOTC_RushPackageAlias_Basic Auto Const Mandatory
	{ Auto-fills on base. Used for Rampage/Random Ambush features. }
	
	Keyword[] Property kPackageKeywords Auto Const Mandatory
	{ Fill with SOTC_PackageKeywords (10 by default). Add more if needed. Used for linking to package marker(s). }
	
	Spell Property SOTC_EvalPackageSpell Auto Const Mandatory
	{ Auto-fills on the base form. Forces EvaluatePackage on spawns in own thread. }
	
	Spell Property SOTC_EvalPkgTrackLoadStatusSpell Auto Const Mandatory
	{ Auto-fills on the base form. Forces EvaluatePackage on spawns in own thread and then tracks the Actors OnCellAttach/Detach events
so they can be disabled when unloaded for some time/enabled when reloaded. May help AI performance. }
	
	ObjectReference[] Property kChildPoints Auto ;AUTO so can be modified at runtime.
	{ If using child markers, fill with these from render window. This is used for Patrols/Interiors/MultiPoints/Randomised Start Locs or if we 
want to define a Sandbox location away from this SpawnPoint. Do not use this for other purposes unless you know what you are doing. If using the
iForceGroupsToSpawn override, must have that many ChildPoints. Length of this array doubles as maximum no. of Groups for MultiPoint otherwise. }

	Bool Property bSpreadSpawnsToChildPoints Auto Const
	{ If set true, spawned Actors will be placed at random ChildPoints (which must be defined) around the SpawnPoint, so they are spread apart.
ChildPoints should be placed in same cell as this SP, use at own risk otherwise. Causes bRandomiseStartLoc override and iNumPackageLocs
for Package Mode 0 (Sandbox/Hold) and Package Mode 2 (Patrols) to be ignored. }

	Bool Property bRandomiseStartLoc Auto Const
	{ This can be used to randomise the initial placement of entire spawned groups with certain Package Modes (0, 1 and 2). It is different from
the setting bSpreadSpawnsToChildPoints as this applies to whole group, not individuals. One must define a number of ChildPoints around
this SP in order for this to work. ChildPoints should be placed in same cell as this SP, use at own risk otherwise. For Mode 0 (Sandbox/Hold),
overrides iNumPackageLocs if set. This is somewhat the equivalent of Interior Mode's spawn method for Modes 0-2. Ignored in MultiPoint Mode. }

	Float Property fNextLocationTimerClock = 180.0 Auto Const
	{ Default value of 180.0 (3 Minutes). Time Actors will Sandbox at travel destination before moving on. }

	Float Property fAmbushDistance = 800.0 Auto Const
	{ Pacakge Mode 3 only. Default of 800.0 units, distance target from Player before Ambush activates. Enter override value if desired. }

EndGroup



Group Overrides
{ Read descs. of each as to which modes these overrides apply. }

	Int Property iPlayerLevelRestriction = 0 Auto Const
	{ All modes. Can be used to set a Player level requirement if desired. }

	Int Property iPresetRestriction Auto Const 
	{ All modes. Fill this (1-3) if it is desired to restrict this point to a certain Master preset level. }
	
	Bool Property bBlockLocalRandomEvents Auto Const
	{ All Modes except Package Mode 3. Set true to ignore local events, such as Swarm, Rampage and Ambush. This will be slightly faster as 
forces the use of a function that does not include these checks. }

	Bool Property bIgnoreExpiry Auto Const
	{ If this flag is set true then SP will never start expiry timers/Actor will not use tracking Package (if roaming etc), 
only resetting when full reset timer expires. }

	Float Property fSafeDistanceFromPlayer = 4096.0 Auto Const
	{ All modes. Default value of 4096.0 (2 exterior cell lengths), safe distance to spawn from Player. Change if desired. }

	Int Property iForceUseRarityList Auto Const
	{ Spawn Mode 0 only. Fill this 1-3, if wanting to force grab a certain "rarity" of actor in this Region (i.e force use Rarity list). }
	
	Bool Property bForceClassPreset Auto Const
	{ Spawn Mode 0 only. Set True if wanting to force a Rarity-Based Class Preset, optional to the above. }
	
	Int Property iForcedClassPreset Auto Const
	{ Spawn Mode 0 only. If above is set True, set this to a value of 0-3 (can only use Rarity-based CPs). 0 is debug CP. }
	
	Bool Property bForceMasterPreset Auto Const
	{ All modes. Use if wanting to force a Master Preset to be used when grabbing params from ClassPreset. }
	
	Int Property iForcedMasterPreset Auto Const
	{ Leave 0 if above is false. Otherwise set 0-3 (0 is debug preset). Set 777 to randomise Preset. }
	
	Bool Property bForceDifficulty Auto Const
	{ All Modes. If desired to force a Difficulty level, set true. }
	
	Int Property iForcedDifficulty Auto Const
	{ Set 0-4 if above is true. As per Vanilla Difficulty settings. }
	
	Int Property iForceGroupsToSpawnCount Auto Const
	{ MultiPoint only. If wanting to force the number of Groups to spawn at a MultiPoint, set this above 0, or will be randomised.
Be careful with this value if not using with Interior/Patrol modes. }
	
	;Local Event chance bonuses:
	
	Int Property iPointSwarmBonus Auto Const
	{ All Modes. Enter a value above 0 if wanting to give this Point a "Swarm" chance bonus. Ignored for MultiPoint. }
	
	Int Property iPointRampageBonus Auto Const
	{ All Modes. Enter a value above 0 if wanting to give this Point a "Rampage" chance bonus. Ignored for MultiPoint. }
	
	Int Property iPointRandomAmbushBonus Auto Const
	{ All Modes. Enter a value above 0 if wanting to give this Point a "Random Ambush" chance bonus. Ignored for MultiPoint. }

EndGroup


Group BonusStuff

	ObjectReference[] Property kPropParents Auto Const
	{ Default value of None on each member. If using an Enable Parent object to enable any Props, fill this with any of those objects according to index IDs as follows: 
ID relates to primary Race/Type of the Actor as per GroupLoadout script). ID's are: 0 = Always None (required for checks), 1 = Human (camp/furniture etc),
2 = SuperMutant (gore etc), 3 = Predator Mutant/Animal (dead bodies etc), 4 = Robots/machines (parts, scrapped bots/machines etc. 
If ID passed is None in this array, will be ignored. }
	
EndGroup


Group MenuGlobals
{ Can be used for Menu and future functions. }

	GlobalVariable Property SOTC_Global01 Auto Const Mandatory
	{ Auto-fill }
	GlobalVariable Property SOTC_Global02 Auto Const Mandatory
	{ Auto-fill }
	GlobalVariable Property SOTC_Global03 Auto Const Mandatory
	{ Auto-fill }
	
	;Added 3 Globals, so in the event we actually need more, won't have to stress so much about adding more. 
	
EndGroup


;----------------
;Local Variables
;----------------

;TimerIDs
Int iStaggerStartupTimerID = 1 Const
Int iFailedSpCooldownTimerID = 2 Const
Int iSpShortExpiryTimerID = 3
Int iSpResetTimerID = 4
Int iNextLocationTimerID = 5 

Bool bUseTravelSpellOrIgnoreExpiry = false ;Flags SP not to use local expiry timer, as either we are using Travel spell for this purpose or is MultiPoint. 
;Also used to notify ThreadController to increment Travelling NPC count. As of version 0.21.01 this is safe to use as no function uses this in a way that
;would affecct this functionality. MultiPoint mode will pass a count of 0 from this script. 

;Bool bShortExpiryTimerRunning ;Exists to stop log spam when cancelling a timer thats not running. May not be necessary.

Bool bGroupIsDisabled ;Faster then running latent check of similar type. 

Bool bFailTimerRunning ;This has to exist so things don't confused if we force a Reset Event etc. 
;These bools are for checking and flagging Expiry timers for functions that need this info.

Int iPropsEnabled
;Set to the value of iActorRaceTypeID if Props are enabled, for cleaning up later. 0 is None/Disabled.

Bool bSpawnpointActive ; Main condition check. Once SP is activated this is set true.

SOTC:ThreadControllerScript ThreadController
;{ Init None, fills OnCellAttach. }

SOTC:RegionManagerScript RegionManager
;{ Init None, fills OnCellAttach. }
	
SOTC:SpawnTypeRegionalScript SpawnTypeScript
;{ Init None, fills OnCellAttach. }

SOTC:ActorManagerScript ActorManager
;{ Init None, fills OnCellAttach. Set ID accordingly. }

ActorClassPresetScript ActorParamsScript
;NOTE: We never get the ActorManagerScript first, we go straight for the ClassPresetScript in order to get parameters.
;We can and will still access the ActorManagerScript from here. 

Actor[] kGrouplist ;Stores all Actors spawned on this instance until cleaned up.
Actor[] kTravelLocGroupList ;For travelling Actors (ver. 0.19.01). When these Actors reach a travel loc, they Sandbox (if Package used is setup for this properly) 
;and this point will receive their OnPackageEnd event and add them to this array. The first to reach the location will trigger a 3 minute timer. When this timer
;expires, all Actors who made it to the location within the 3 minutes are assinged the next location (if alive). If some Actors strggle outside the 3 minutes, they
;will simply stay at the first destination until killed or cleaned up. Only used if iNumPackageLocsRequired > 1 with iPackageMode = 1 (travel package).

ObjectReference[] kPackageLocs ;Now tracked in empty state. Used for storing locations, in the event we use multiple travel locations, this needs to be
;looked at for tracking purposes, and also for Prop purposes as these now have PropParents tied to them for use with Sandboxing. 

Int iCurrentLocation ;Used for tracking which location of the travel loc list Actors are currently at. 
Bool bPackageEventLockEngaged ;For use with multi-destination travel. Triggered by the first Actor to reach the Travel location, locks some functionality from
;running again unnecessarily. 

;DEV NOTE: GROUP LEADERSHIP. 
;It could be considered to add another variable here for a "Group Leader" of sorts. At this time (version 0.13.01), there is no plan in place for this.

Int iLosCounter ;This will be incremented whenever a Line of sight check to Player fails. If reaches 25 (2.5 secs), spawning aborts. As we at least spawn
;1 actor to start with, this remains safe to use (however Player may see that one actor being spawned. its just easier to live with). 

;Multipoint/Interior/ChildPoint variables
ObjectReference[] kActiveChildren ;Temp list of all child markers used to delegate spawns to.
Bool bChildrenActive ;This will be checked and save reinitializing above array later.
ObjectReference[] kActiveHelpers ;Actual SpawnHelper instances placed at child markers.
Int[] iChildPointElectionTracker ;Tracks the elected ChildPoints when using bSpreadSpawnsToChildPoints. Integers stored are used to correlate to correct
;ChildPoint to link to when applying Packages. Necessary evil now that Packages are all applied after spawn loops. 
Bool bApplyRushPackage ;If flagged, will Apply the Rush package, used for Rampages/Random Ambush features.


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;PRE-SPAWN EVENTS & FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------------------------------


Event OnCellAttach()

	;Inital check, is not active, chance is not None (as could be nulled by Menu for example).
	if (!bSpawnpointActive) && (!bFailTimerRunning) && (iChanceToSpawn as Bool) 
		;Staggering the startup might help to randomise SPs in an area when Threads are scarce
		StartTimer((Utility.RandomFloat(0.015,0.035)), iStaggerStartupTimerID)
	
	elseif bSpawnpointActive
		
		if bGroupIsDisabled	;Timer has expired. 
			EnableActorRefs()
		else ;if bShortExpiryTimerRunning
			CancelTimer(iSpShortExpiryTimerID)
			;bShortExpiryTimerRunning = false
		endif
		
	endif
	
EndEvent


Event OnCellDetach()

	if bIgnoreExpiry || bUseTravelSpellOrIgnoreExpiry ;Latter is reused for a number of modes. 
		return ;Ignore local expiry timer
	else
		StartTimer(ThreadController.fSpShortExpiryTimerClock, iSpShortExpiryTimerID)
		;bShortExpiryTimerRunning = true
	endif
	
EndEvent


Event OnTimer(int aiTimerID)

	if aiTimerID == iStaggerStartupTimerID
	
		ThreadController = MasterScript.ThreadController; Link to Thread Controller now. 
	
		if (ThreadController.GetThread(iThreadsRequired)) ;Make sure we can get a thread first. 
		
			;Initial checks - If Interior continue, else check distance from Player is greater than bSafeDistance Property and Player level restriction is exceeded.  
			if ((GetDistance(MasterScript.PlayerRef)) > fSafeDistanceFromPlayer) && ((MasterScript.PlayerRef.GetLevel()) >= iPlayerLevelRestriction)
			;DEV NOTE: GetDistance check is only safe when comparing Object (namely this self object in this case) to Actor as parameter (namely Player in this case). 
				
				if bIsInteriorPoint && !CheckSpLocationSafe()
					;Trace will be done by function if it fails.
					InitFailProcedure()			
					return ;Nip in the bud
				endif
				;else continue
				
				;Master Level checks/intercepts
				if MasterScript.MasterSpawnCheck(Self, bAllowVanilla, bEventSafe) ;MASTER CHECK: If true, denied
					;Master script dice roll failed or is assuming control with an Event, kill this thread.
					Debug.Trace("SpawnPoint denied by Master check")
					InitFailProcedure()			
					return ;Nip in the bud
				endif
				;else continue
				
				Debug.Trace("SpawnPoint passed Master Check, setting script links")
				SetSpScriptLinks()
				
				if RegionManager.RegionSpawnCheck(Self, iPresetRestriction) ;REGION CHECK: If true, denied
					;Region script assuming control, kill this thread and disable
					Debug.Trace("SpawnPoint denied by Region check")
					InitFailProcedure()
					return ;Nip in the bud
				endif
				;else continue
				
				Debug.Trace("SpawnPoint passed Region Check")
				
				;Check SpawnType or Actor if enabled
				if (iSpawnMode == 0) && (SpawnTypeScript.bSpawnTypeEnabled) && ((Utility.RandomInt(1,100)) <= ((iChanceToSpawn) + (RegionManager.GetRegionSpPresetChanceBonus()))) ;LOCAL CHECK
					Debug.Trace("SpawnPoint Spawning")
					PrepareLocalSpawn() ;Do Spawning
					Debug.Trace("SpawnPoint successfully spent")
					
				elseif (iSpawnMode == 1) && (ActorManager.bActorEnabled) && ( (Utility.RandomInt(1,100)) <= ((iChanceToSpawn) + (RegionManager.GetRegionSpPresetChanceBonus())) ) ;LOCAL CHECK
					Debug.Trace("SpawnPoint Spawning")
					PrepareLocalSpawn() ;Do Spawning
					Debug.Trace("SpawnPoint successfully spent")
					
				else ;Denied.
					Debug.Trace("SpawnPoint denied by dice or Spawntype/Actor disabled")
					InitFailProcedure()
				endif
				
			else ;Failed distance/level check. 
				InitFailProcedure()
			endif
			
		else ;Could not GetThread, denied.
			InitFailProcedure(false)
		endif
		

	elseif aiTimerID == iFailedSpCooldownTimerID
	
		bFailTimerRunning = false
		
	elseif aiTimerID == iSpShortExpiryTimerID
		
		DisableActorRefs() ;May fail, checks own conditions now. 
		
	elseif aiTimerID == iSpResetTimerID
	
		if FactoryReset(false) ;Not forcing reset. If returns false, restart timers. If true/successfully reset, re-arm the point. 
			bSpawnpointActive = false
		else ;Assume false/failed to reset due to conditions
			StartTimer(RegionManager.fSpResetTimerClock, iSpResetTimerID)
		endif
		
	elseif aiTimerID == iNextLocationTimerID
	
		PrepareNextTravelLocation()
	
	endif
	
EndEvent



Function SetSpScriptLinks()
	
	;Since patch 0.10.01, all instances are created at runtime (first install). Necessary evil.
	RegionManager = MasterScript.Worlds[iWorldID].Regions[iRegionID]
	
	if iSpawnMode == 0 ;Random actor from SpawnType
		
		if iPackageMode == 3 ;Ambush (distance based) Force use of SpawnType 11.
			SpawnTypeScript = RegionManager.Spawntypes[11]
		else
			SpawnTypeScript = RegionManager.Spawntypes[iSpawnTypeOrActorID]
		endif
		
	elseif iSpawnMode == 1 ;Specific Actor from Master
		ActorManager = MasterScript.SpawntypeMasters[0].ActorList[iSpawnTypeOrActorID]
		
	elseif iSpawnMode == 2 ;Use predefined list, get random Actor from that
		
		Int iSize = (iModeTwoActorList.Length) - 1
		Int iActorToSpawn = iModeTwoActorList[(Utility.RandomInt(0,iSize))]
		ActorManager = MasterScript.SpawntypeMasters[0].ActorList[iActorToSpawn]
		
	endif
	
EndFunction



Function PrepareLocalSpawn() ;Determine how to proceed
	
	;Check set Package Mode is expected. Shouldn't be required but I made this mistake once. 
	if iPackageMode > 4 || iPackageMode < 0;FAILURE
		Debug.Trace("Unexpected Package mode detected on SpawnPoint, returning immediately, function FAILED. Mode was set to: " +iPackageMode +" " + Self)
		InitFailProcedure()
		return
	endif

	MasterScript.ShowSpawnWarning() ;Has to be done here, but only shows if enabled on Master. 
	
	Int iNpcCount ;Use for notifying ThreadController of spawn numbers
	
	if bIsMultiPoint ;Uses helper objects to create multi-group spawns.  
		iNpcCount = 0 ;Actors only present on Helpers. 
		PrepareMultiGroupSpawn()
	
	elseif bBlockLocalRandomEvents || iPackageMode == 3 || iPackageMode == 4 ;Use "No Event" method if any are true.
		PrepareSingleGroupNoEventSpawn() ;Enforced for Mode 3 Ambush and Mode 4 Hold.
		iNpcCount = kGroupList.Length
	else
		PrepareSingleGroupSpawn()
		iNpcCount = kGroupList.Length
	endif
	
	bSpawnpointActive = true
	
	;Encapsulated to a single function call as of version 0.21.01. 
	ThreadController.ProcessActiveSpawnPoint(iThreadsRequired, iNpcCount, bUseTravelSpellOrIgnoreExpiry, false)
	
	StartTimer(RegionManager.fSpResetTimerClock, iSpResetTimerID)
	
	Debug.Trace("A SpawnPoint has successfully finished spawning: " +Self)
	
EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;CLEANUP/PERFORMANCE FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;Added in version 0.16.01. Simply calls the ThreadController to see if fail cooldown timer needs to be run. 
Function InitFailProcedure(Bool abReleaseThreads = true) ;Param is true cos too lazy to enter it in all instances written bar the one that requires false. 
	
	Float fFailTimerClock = ThreadController.ProcessFailedSpawnPoint(abReleaseThreads, iThreadsRequired) ;Saves an extra call to ThreadController later.
	
	if fFailTimerClock > 0.0 ;By default this timer is set to 5 minutes.
		StartTimer(fFailTimerClock, iFailedSpCooldownTimerID)
		bFailTimerRunning = true
		;DEV NOTE: If the Fail Cooldown Timer is off, Point will continuously try to spawn every CellAttach Event it receives. 
	endif

EndFunction


Function CancelAllTimers()
	
	;WARNING: ONLY USE WHEN FULLY RESETTING MANUALLY.
	CancelTimer(iSpResetTimerID)
	;if bShortExpiryTimerRunning
	CancelTimer(iSpShortExpiryTimerID)
	;endif
	
EndFunction


;When Short Expiry timer expires and SP is not in the loaded area, disable Actors.
Function DisableActorRefs()

	Int iSize
	Int iCounter
	
	if bIsMultiPoint
	
		iSize = kActiveHelpers.Length
		while iCounter < iSize
			(kActiveHelpers[iCounter] as SOTC:SpHelperScript).HelperDisableActorRefs() ;Safe to call, will be ignored if not needed.
			iCounter += 1
		endwhile
		bGroupIsDisabled = true
		;DEV NOTE: It could be possible that if OnCellAttach/Detached are received quickly in succession, this loop may not have finished.
		;As such, flag is set after disabling/enabling so if such event occurs, it is ignored. For MultiPoints, Helpers ignore if not needed.
	
	elseif !bGroupIsDisabled && !TestActorsInLoadedArea() ;OnCellDetach is unreliable, test if Actors loaded before disabling only. 
	
		iSize = kGroupList.Length
		while iCounter < iSize
			
			kGroupList[iCounter].Disable()
			iCounter += 1
				
		endwhile
		bGroupIsDisabled = true
		;DEV NOTE: It could be possible that if OnCellAttach/Detached are received quickly in succession, this loop may not have finished.
		;As such, flag is set after disabling/enabling so if such event occurs, it is ignored.
	
	endif
	
EndFunction


;If Player re-enters the area before Long Expiry, re-enable the Actors. 
Function EnableActorRefs()
	
	Int iSize
	Int iCounter
	
	if bIsMultiPoint
	
		iSize = kActiveHelpers.Length
		while iCounter < iSize
			(kActiveHelpers[iCounter] as SOTC:SpHelperScript).HelperEnableActorRefs() ;Safe to call, will be ignored if not needed.
			iCounter += 1
		endwhile
		bGroupIsDisabled = false
		;DEV NOTE: It could be possible that if OnCellAttach/Detached are received quickly in succession, this loop may not have finished.
		;As such, flag is set after disabling/enabling so if such event occurs, it is ignored. For MultiPoints, Helpers ignore if not needed.
	
	elseif bGroupIsDisabled
	
		iSize = kGroupList.Length
		while iCounter < iSize
			kGroupList[iCounter].Enable()
			iCounter += 1
		endwhile
		bGroupIsDisabled = false
		;DEV NOTE: It could be possible that if OnCellAttach/Detached are received quickly in succession, this loop may not have finished.
		;As such, flag is set after disabling/enabling so if such event occurs, it is ignored. 
	
	endif
	;DEV NOTE: This should probably be followed by a call to restart the expiry timers whenever this function is called. 
	
EndFunction


;Event from MAster script, force a Reset. 
Event SOTC:MasterQuestScript.ResetAllActiveSps(SOTC:MasterQuestScript akSender, Var[] akArgs)

	if FactoryReset((akArgs[0] as Bool), true) ;IF returns true/successfully reset. akArgs is "Force" parameter, "true" is to mark as Event reset. 
		bSpawnpointActive = false
		CancelAllTimers() ;Shitcan any running timers.
	endif

EndEvent


;Cleanup all active data produced by this SP.
Bool Function FactoryReset(Bool abForceReset = false, Bool abSendEventFlag = false)
	
	if !bSpawnpointActive
		return true ;Return true as we are inactive and should be clean. 
	endif
	
	if !abForceReset ;Force will ignore ANY current conditions (except the above).
		
		if TestActorsInLoadedArea() ;Currently loaded, leave it be, restart reset timer. 
			return false
			;Next call should be to restart timers etc if necessary (depending where called from). 
		endif
		
	endif
	
	;Continue with full reset.
	Int iNpcCount = 0 ;Use for notifying ThreadController of spawn numbers
	
	;Reset/default most Vars now. Shouldn't be leaving this thread so shouldn't be any race conditions.
	if bPackageEventLockEngaged ;The TravelGroup array must be initialized.
		kTravelLocGroupList.Clear()
		bPackageEventLockEngaged = false
	endif
	
	iCurrentLocation = 0
	iLosCounter = 0
	bApplyRushPackage = false
	
	;Cleanup data. 
	if bIsMultiPoint ;No groups stored here.
		
		CleanupHelperRefs()
		ResetChildMarkers()
		
	else ;Single and Interior modes can both use this.
		
		if iPackageMode == 3 ;Registration only occurs in Package Mode 3. 
			UnregisterForDistanceEvents(MasterScript.PlayerRef, Self as ObjectReference)
		endif
		
		iNpcCount = CleanupActorRefs() ;Package Alias is no longer removed. Should disappear with the Actors. 
		bGroupIsDisabled = false
		
	endif
	
	if bSpreadSpawnsToChildPoints
		iChildPointElectionTracker.Clear()
	endif
	
	if iPropsEnabled > 0
		kPropParents[iPropsEnabled].Disable()
		iPropsEnabled = 0
	endif
	
	;Delink scripts in case the instances may be changed later (i.e mod reset) which may cause errors to log.
	ActorManager = None
	SpawnTypeScript = None
	RegionManager = None
	
	ThreadController.ProcessActiveSpawnPoint(0, -iNpcCount, bUseTravelSpellOrIgnoreExpiry, abSendEventFlag)
	bUseTravelSpellOrIgnoreExpiry = false
	ThreadController = None

	kPackageLocs.Clear() ;Needs to be done everytime now that it's a variable in empty state. 
	
	;bSpawnpointActive = false
	;This is now reset upon SpResetTimer/Force Reset only, since RegionalTrackerScript/CleanupManager has been scrapped. (version 0.19.01)
	
	return true ;Flag that we successfully reset. 
	
EndFunction

 
Int Function CleanupActorRefs() ;Package Alias is no longer removed. Should disappear with the Actors.

	int iCounter = 0
	int iSize = kGroupList.Length
        
	while iCounter < iSize
		;Actors may already be disabled due to Short Expiry timer. Either way we won't disable here. 
		kGroupList[iCounter].DispelAllSpells()
		;Added in 0.21.01 to ensure any constant effect spells I may apply don't end up orphaned. May be more added in future so we do all spells.
		kGroupList[iCounter].Delete()
		iCounter += 1
	endwhile
	
	kTravelLocGroupList.Clear() ;De-persist so Delete can succeed.
	kGroupList.Clear() ;De-persist so Delete can succeed. 
	return iSize ;FactoryReset() will notify ThreadCOntroller of numbers. 
	
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

	kActiveHelpers.Clear() ;De-persist so Delete can finish. 
	
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
;DEV NOTE: Currently the below function are a catch all for any mode, but this involves having to do some local checks a few times either. This is mainly
;for shortening the code and making it a bit more readable, however this may change in future and each Package Mode divided into own blocks. Speed is not
;currently a concern however. (V.0.19.01).


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
		
		
	else ;Must be specific Actor. This was set correctly in SetSpScriptLinks function. 
	
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
	
	SOTC:ActorGroupLoadoutScript GroupLoadout = ActorParamsScript.GetRandomGroupLoadout()
	
	ActorBase[] kRegularUnits = (GroupLoadout.kGroupUnits) as ActorBase[] ;Cast to copy locally
	ActorBase[] kBossUnits
	Bool bBossAllowed ;Later used as parameter.
	if (ActorParams.iChanceBoss as Bool) && (GroupLoadout.kBossGroupUnits[0] != None) ;Check if Boss allowed and there is actually Boss on this GL.
		kBossUnits = (GroupLoadout.kBossGroupUnits) as ActorBase[] ;Cast to copy locally
		bBossAllowed = true
	endif
	
	;Check if the GroupLoadout has any Props to use at this SP based on the iActorRaceTypeID value, and enable them via enable parent here. 
	iPropsEnabled = GroupLoadout.iActorRaceTypeID
	if kPropParents[iPropsEnabled] != None ;If The value above was returned 0 (None) this is still safe. 
		kPropParents[iPropsEnabled].Enable()
	else 
		iPropsEnabled = 0 ;Reset to 0 if SP does not have. 
	endif
	;We've done it this way to avoid multiple calls to GroupLoadout script, keeping checks faster locally. 
	
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
	
	kPackageLocs = new ObjectReference[1] ;Create it, even if it is unused later. Now a variable in empty state as of version 0.19.01
	;Initialised with one member for security reasons. This member of None is removed later, if required.
	Int iStartLoc = -1 ;Used if randomising the ChildPoint to spawn at. Default value of -1 = Self.
	
	;Roll on Swarm feature if supported
	Bool bApplySwarmBonus
	if iPackageMode != 4 && (ActorManager.bSupportsSwarm) && (RegionManager.RollForSwarm(iPointSwarmBonus)) ;Not supported for Hold Package.
		bApplySwarmBonus = true
	endif
	
	;Roll on Rampage feature if supported, and Ambush feature if hostile group.
	Bool bRushThePlayer
	;DEV NOTE: Rush Package for Ambush and Rampage is the same now. Actors will Rush to the Point and Sandbox (in the case of the Player, enter combat first).
	
	if iPackageMode == 0 || iPackageMode == 1 ;Supported for these modes only.
	
		if (ActorManager.bSupportsRampage) && (RegionManager.RollForRampage(iPointRampageBonus))
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
	
		if !bSpreadSpawnsToChildPoints && bRandomiseStartLoc ;Place spawned group at random ChildPoint around the SP.

			iSize = (kChildPoints.Length) - 1 ;Need actual index length
			iStartLoc = Utility.RandomInt(-1,iSize)	; -1 uses Self	instead of ChildPoint.

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
	if kPackageLocs.Length > 0 && kPackageLocs[0] == None
		kPackageLocs.Remove(0)
	endif

	
	;Finally, begin spawning.
	;------------------------
	;DEV NOTE: From version 0.20.01 onwards, all Packages are applied after spawning. 
	
	Int i ;Used as needed.
	Int iRegularActorCount ;Required for loot system
	
	if iPackageMode < 5 || bApplyRushPackage
	
		If !bSpreadSpawnsToChildPoints || (iPackageMode == 2) ;More likely false/Force if Patrolling.
			
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
		
			iChildPointElectionTracker = new Int [1] ;Necessary evil so linking of Package can be done correctly.
		
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
		
		;Set the Package on all actors in quick succession.
		;--------------------------------------------------
		iCounter = 0 ;To be sure to be sure.
		iSize = kGroupList.Length 
		
		if iPackageMode == 0 ;Sandbox
		
			if bSpreadSpawnsToChildPoints
			
				iChildPointElectionTracker.Remove(0) ;Remove the first member used for initialising. 
				
				while iCounter < iSize
					i = iChildPointElectionTracker[iCounter]
					ApplyPackageSingleLocData(kSandboxPackages[iSandboxRadiusLevel], kGroupList[iCounter], kChildPoints[i])
					iCounter += 1
				endwhile
				
			else ;Use Self. 
			
				while iCounter < iSize
					ApplyPackageSingleLocData(kSandboxPackages[iSandboxRadiusLevel], kGroupList[iCounter], Self as ObjectReference)
					iCounter += 1
				endwhile
				
			endif
		
		elseif iPackageMode == 1 ;Travel Mode
			
			bUseTravelSpellOrIgnoreExpiry = true ;Regardless of whether it's used (due to bIgnoreExpiry override it may not) it is quicker to set it anyway.
			
			while iCounter < iSize
				ApplyPackageTravelData(SOTC_TravelPackageAlias_Basic, kGroupList[iCounter], kPackageLocs[0])
				iCounter += 1
			endwhile
			
			if iNumPackageLocsRequired > 1
				PrepareForMultipleTravelLocs()
			endif
				
		elseif iPackageMode == 2 ;Patrol Mode

			while iCounter < iSize
				ApplyPackagePatrolData(kGroupList[iCounter], iStartLoc)
				iCounter += 1
			endwhile
			
		elseif bApplyRushPackage ;New measures added in V.0.20.01 to send Actors back to spawn loc after rushing the Player in an Ambush, if player escapes etc.
			
			ObjectReference kSandboxLoc ;The location/linked ref these Actors will go to to Sandbox after Rush stage is complete. 
			
			if bRushThePlayer ;Sets sandbox link to spawn loc so if Player escapes, Actors return here.
				kSandboxLoc = Self as ObjectReference
			else ;Link to same loc that we a re "rushing" to so we sandbox there.
				kPackageLocs[0]
				bUseTravelSpellOrIgnoreExpiry = true
			endif
		
			while iCounter < iSize
				ApplyPackageRushData(kGroupList[iCounter], kPackageLocs[0], kSandboxLoc, bUseTravelSpellOrIgnoreExpiry) ;Locations were set correctly above.
				iCounter += 1
			endwhile

		endif
		
;-------------------------------------------------------------------------------------------------------------------------------------------------------
	
	elseif iPackageMode == 5 ;Interior Mode
	;DEV NOTE: Interior Mode does not expend ChildPoints by design. 
	
		iChildPointElectionTracker = new Int [1] ;Necessary evil so linking of Package can be done correctly.
	
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
		
		iCounter = 0 ;To be sure to be sure.
		iSize = kGroupList.Length 
		;Set Linked refs and Packages. 
		iChildPointElectionTracker.Remove(0) ;Remove the first member used for initialising. 
		
		while iCounter < iSize
			i = iChildPointElectionTracker[iCounter]
			ApplyPackageSingleLocData(kSandboxPackages[iSandboxRadiusLevel], kGroupList[iCounter], kChildPoints[i])
			iCounter += 1
		endwhile

	endif


	;Check for loot pass, inform ThreadController of the spawned numbers.
	;---------------------------------------------------------------------
	
	if ActorManager.bLootSystemEnabled
		Int iBossCount = (kGroupList.Length) - iRegularActorCount ;Also required for loot system
		ActorManager.DoLootPass(kGroupList, iBossCount)
	endif

	;GTFO
	
EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------


;Similar to the above function, but faster/simpler. Skips random events and other intricacies. This is the only function that supports Package Mode 5. 
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
		
		
	else ;Must be specific Actor. This was set correctly in SetSpScriptLinks function. 
	
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
	
	SOTC:ActorGroupLoadoutScript GroupLoadout = ActorParamsScript.GetRandomGroupLoadout()
	
	ActorBase[] kRegularUnits = (GroupLoadout.kGroupUnits) as ActorBase[] ;Cast to copy locally
	ActorBase[] kBossUnits
	Bool bBossAllowed ;Later used as parameter.
	if (ActorParams.iChanceBoss as Bool) && (GroupLoadout.kBossGroupUnits[0] != None) ;Check if Boss allowed and there is actually Boss on this GL.
		kBossUnits = (GroupLoadout.kBossGroupUnits) as ActorBase[] ;Cast to copy locally
		bBossAllowed = true
	endif
	
	;Check if the GroupLoadout has any Props to use at this SP based on the iActorRaceTypeID value, and enable them via enable parent here.
	;---------------------------------------------------------------------------------------------------------------------------------------
	
	iPropsEnabled = GroupLoadout.iActorRaceTypeID
	if kPropParents[iPropsEnabled] != None ;If The value above was returned 0 (None) this is still safe. 
		kPropParents[iPropsEnabled].Enable()
	else 
		iPropsEnabled = 0 ;Reset to 0 if SP does not have. 
	endif
	;We've done it this way to avoid multiple calls to GroupLoadout script, keeping checks faster locally. 
	
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
	
	kPackageLocs = new ObjectReference[1] ;Create it, even if it is unused later. Now a variable in empty state as of version 0.19.01
	;Initialised with one member for security reasons. This member of None is removed later, if required.
	Int iStartLoc = -1 ;Used if randomising the ChildPoint to spawn at. Default value = Self.
	
	if iPackageMode > 2; Short-circuit, the below is not supported for Package Modes above this. 
		;Skip All
	
	elseif iPackageMode == 0 ;Sandbox/Hold
	
		if !bSpreadSpawnsToChildPoints && bRandomiseStartLoc ;Place spawned group at random ChildPoint around the SP.

			iSize = (kChildPoints.Length) - 1 ;Need actual index length
			iStartLoc = Utility.RandomInt(-1,iSize)	; -1 uses Self	instead of ChildPoint.
			
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
	;------------------------
	;DEV NOTE: From version 0.20.01 onwards, all Packages are applied after spawning. 
	
	Int i ;Used as needed. 
	Int iRegularActorCount ;Required for loot system
	
	if iPackageMode < 5

		If !bSpreadSpawnsToChildPoints || (iPackageMode == 2) ;More likely false/Force if Patrolling.
			
			if iEzMode != 2 ;If NOT Randomising EZ - this is maybe more likely
					
				SpawnActorSingleLocLoop(ActorParams.iMaxAllowed, ActorParams.iChance, kRegularUnits, \
				kEz, false, iStartLoc, false, iDifficulty)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system
					
				if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
					SpawnActorSingleLocLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEz, false, iStartLoc, true, iDifficulty)
				endif

			else ;Randomise the Ez

				SpawnActorRandomEzSingleLocLoop(ActorParams.iMaxAllowed, ActorParams.iChance, kRegularUnits, \
				kEzList, false, iStartLoc, false, iDifficulty)
				
				iRegularActorCount = (kGroupList.Length) ;Required for loot system

				if bBossAllowed ;Check again if Boss spawns allowed for this Actors preset
					SpawnActorRandomEzSingleLocLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, \
					kBossUnits, kEzList, false, iStartLoc, true, iDifficulty)
				endif
					
			endif
			
		else ;Assume true
		
			iChildPointElectionTracker = new Int [1] ;Necessary evil so linking of Package can be done correctly.
		
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
		
		;Set the Package on all actors in quick succession.
		;--------------------------------------------------
		iCounter = 0 ;To be sure to be sure.
		iSize = kGroupList.Length 
		
		if iPackageMode == 0 || iPackageMode == 4 ;Sandbox/Hold
		
			if bSpreadSpawnsToChildPoints
			
				iChildPointElectionTracker.Remove(0) ;Remove the first member used for initialising. 
				
				while iCounter < iSize
					i = iChildPointElectionTracker[iCounter]
					ApplyPackageSingleLocData(kSandboxPackages[iSandboxRadiusLevel], kGroupList[iCounter], kChildPoints[i])
					iCounter += 1
				endwhile
				
			else ;Use Self. 
			
				while iCounter < iSize
					ApplyPackageSingleLocData(kSandboxPackages[iSandboxRadiusLevel], kGroupList[iCounter], Self as ObjectReference)
					iCounter += 1
				endwhile
				
			endif
		
		elseif iPackageMode == 1 
		
			bUseTravelSpellOrIgnoreExpiry = true ;Regardless of whether it's used (due to bIgnoreExpiry override it may not) it is quicker to set it anyway.
			
			while iCounter < iSize
				ApplyPackageTravelData(SOTC_TravelPackageAlias_Basic, kGroupList[iCounter], kPackageLocs[0])
				iCounter += 1
			endwhile
			
			if iNumPackageLocsRequired > 1
				PrepareForMultipleTravelLocs()
			endif

		elseif iPackageMode == 2

			;Apply loop
			while iCounter < iSize
				ApplyPackagePatrolData(kGroupList[iCounter], iStartLoc)
				iCounter += 1
			endwhile
			
		elseif iPackageMode == 3 ;Ambush Mode. Should always use this function and not the above Event inclusive one (PrepareSingleGroupSpawn()). 
			
			ApplyGroupSneakState()
			RegisterForDistanceLessThanEvent(MasterScript.PlayerRef, Self as ObjectReference, fAmbushDistance) ;Possibly faster then Game.GetPlayer()
			
		endif
		
;-------------------------------------------------------------------------------------------------------------------------------------------------------
	
	elseif iPackageMode == 5 ;Interior Mode
		
		iChildPointElectionTracker = new Int [1] ;Necessary evil so linking of Package can be done correctly.
		
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
		
		iCounter = 0 ;To be sure to be sure.
		iSize = kGroupList.Length 
		;Set Linked refs and Packages. 
		iChildPointElectionTracker.Remove(0) ;Remove the first member used for initialising. 
		
		while iCounter < iSize
			i = iChildPointElectionTracker[iCounter]
			ApplyPackageSingleLocData(kSandboxPackages[iSandboxRadiusLevel], kGroupList[iCounter], kChildPoints[i])
			iCounter += 1
		endwhile
		
	endif


	;Check for loot pass, inform ThreadController of the spawned numbers.
	;---------------------------------------------------------------------
	
	if ActorManager.bLootSystemEnabled
		Int iBossCount = (kGroupList.Length) - iRegularActorCount ;Also required for loot system
		ActorManager.DoLootPass(kGroupList, iBossCount)
	endif

EndFunction



;-------------------------------------------------------------------------------------------------------------------------------------------------------
;SPAWN LOOPS
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;DEV NOTE: From version 0.20.01 onwards, all Packages are applied after spawning.


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
		kStartLoc = kChildPoints[aiStartLoc] ;This number was randomised earlier. 
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

		endif
		
		Utility.Wait(0.1) ;Artificial wait added in v0.21.01 may help with spawned Actor render stutter. 
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
	
	;Determine initial location to spawn or link to.
	ObjectReference kStartLoc

	if aiStartLoc == -1 ;Use Self
		kStartLoc = Self as ObjectReference
	else ;Use ChildPoint location
		kStartLoc = kChildPoints[aiStartLoc] ;This number was randomised earlier.
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
			
		endif
		
		Utility.Wait(0.1) ;Artificial wait added in v0.21.01 may help with spawned Actor render stutter. 
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
	
	;Begin chance based placement loop for the rest of the Group.
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
		
		Utility.Wait(0.1) ;Artificial wait added in v0.21.01 may help with spawned Actor render stutter. 
		iCounter +=1
	
	endwhile

EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------

Function SpawnActorRandomEzSingleLocRandomChildLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, EncounterZone[] akEzList, \ 
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
	
	;Begin chance based placement loop for the rest of the Group.
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
			
		endif
		
		Utility.Wait(0.1) ;Artificial wait added in v0.21.01 may help with spawned Actor render stutter. 
		iCounter +=1
	
	endwhile

EndFunction


;DEV NOTE: PACKAGE LOOPS REMOVED IN 0.19.01. NO LONGER NECESSARY. PARAMETER ADDED TO SINGLELOC TYPE FUNCTIONS INSTEAD. 


;-----------------------------------------------------------------------------------------------------------------------------------------
;PACKAGE APPLICATION LOOPS
;-----------------------------------------------------------------------------------------------------------------------------------------

;Used for a multitude of Packages only needing to link to single point, I.E
;Sandbox, Hold, Interiors (Sandbox)
Function ApplyPackageSingleLocData(ReferenceAlias akPackage, Actor akActor, ObjectReference akPackageLoc)
;Package must be passed to this one, as it can be used for any Package with only single linked ref requirement.

	akActor.SetLinkedRef(akPackageLoc, kPackageKeywords[0])
	akPackage.ApplyToRef(akActor) ;Finally apply the data alias with package
	;As of version 0.16.02, cast spell to Actor to run EvaluatePacakge call in own thread. 
	SOTC_EvalPackageSpell.Cast(akActor, akActor)
	
EndFunction


;Same as the above, but uses/cast the new (v0.21.01) SOTC_EvalPkgTrackLoadStatusSpell to track Cell attach/detach events for the Actor.
Function ApplyPackageTravelData(ReferenceAlias akPackage, Actor akActor, ObjectReference akPackageLoc)
;Package must be passed to this one, as it can be used for any Package with only single linked ref requirement.

	akActor.SetLinkedRef(akPackageLoc, kPackageKeywords[0])
	akPackage.ApplyToRef(akActor) ;Finally apply the data alias with package
	
	;As of version 0.16.02, cast spell to Actor to run EvaluatePacakge call in own thread. This one also track cell attach/detach events.
	if !bIgnoreExpiry
		SOTC_EvalPkgTrackLoadStatusSpell.Cast(akActor, akActor)
	else
		SOTC_EvalPackageSpell.Cast(akActor, akActor)
	endif
	
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
		
	kPatrolPackages[iNumPackageLocsRequired].ApplyToRef(akActor) ;Finally apply the data alias with package
	
	;As of version 0.16.02, cast spell to Actor to run EvaluatePacakge call in own thread. 
	;akActor.EvaluatePackage() ;And evaluate so no delay
	SOTC_EvalPackageSpell.Cast(akActor, akActor)

EndFunction


;For the Rush Package we apply two linked refs, one for the target location and possibly another if we want Actors to return to a different location
;(i.e we want them to return to their starting location to sandbox once they've reached the Player and maybe the Player escapes the Ambush). 
Function ApplyPackageRushData(Actor akActor, ObjectReference akRushLoc, ObjectReference akSandboxLoc, Bool abUseTravelSpellOrIgnoreExpiry)

	akActor.SetLinkedRef(akRushLoc, kPackageKeywords[0])
	akActor.SetLinkedRef(akSandboxLoc, kPackageKeywords[1])
	SOTC_RushPackageAlias_Basic.ApplyToRef(akActor) ;Finally apply the data alias with package
	
	if abUseTravelSpellOrIgnoreExpiry && !bIgnoreExpiry
		SOTC_EvalPkgTrackLoadStatusSpell.Cast(akActor, akActor)
	else
		SOTC_EvalPackageSpell.Cast(akActor, akActor)
	endif
	
EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;MULTI-DESTINATION TRAVEL FUNCTIONS & EVENTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;Added in version 0.19.01. This area deals with Actors travelling to multiple locations. Due to the sheer latency of the AI engine, we will now hold its
;hand throughout this entire process. It should be noted that multi-destination travelling spawns should be kept to a limit throughout the entire mod as
;these are the most expensive Papyrus wise. What we will do is issue a basic, single-location, travel destination to begin with, and then register for
;OnPackageEnd for each Actor. When the Actors arrive at the location they will be given a basic Sandbox package. The first Actor to reach the location 
;will trigger a timer here, with each Actor that makes it being added to a separate/new array from the GroupList. When the Timer expires, those that made
;it and now being tracked in this new array, will be assigned a new travel location and all evaluated via the scripted spell method (used above) as usual.
;This process then repeats infinitely. 

Function PrepareForMultipleTravelLocs()

	Int iSize = kGroupList.Length
	Int iCounter
	
	while iCounter < iSize
		RegisterForRemoteEvent(kGroupList[iCounter], "OnPackageEnd")
		iCounter += 1
	endwhile
	
EndFunction


Function PrepareNextTravelLocation() ;Send all Actors that made it to last destination, to new destination, if alive now. 
	
	Int iSize = kTravelLocGroupList.Length
	Int iCounter
	
	while iCounter < iSize
		
		if !kTravelLocGroupList[iCounter].IsDead() ;Ignore if dead.
		
			kTravelLocGroupList[iCounter].SetLinkedRef(kPackageLocs[iCurrentLocation], kPackageKeywords[0])
			SwapActorPackageData(kTravelLocGroupList[iCounter], kSandboxPackages[2], SOTC_TravelPackageAlias_Basic) ;Always use basic travel.
			
		endif
		
		iCounter += 1
		
	endwhile
	
	kTravelLocGroupList.Clear()
	bPackageEventLockEngaged = false 

EndFunction


Event Actor.OnPackageEnd(Actor akSender, Package akOldPackage)

	if akOldPackage == SOTC_TravelPackageBasic && !bPackageEventLockEngaged ;If false, this is the first Actor to make it. 
		
		bPackageEventLockEngaged = true
		kTravelLocGroupList = new Actor[1] ;Init with one member to avoid false array errors.
		kTravelLocGroupList[0] = akSender
		StartTimer(fNextLocationTimerClock, iNextLocationTimerID)
		
		if (iCurrentLocation + 1) == iNumPackageLocsRequired ;If so we've been to all locs, restart from start of location list.
			iCurrentLocation = 0
		else
			iCurrentLocation += 1
		endif
		
	elseif akOldPackage == SOTC_TravelPackageBasic ;Need to be certain getting right Package (assume bool was true). 
		 
		kTravelLocGroupList.Add(akSender)
		
	endif
	
	SwapActorPackageData(akSender, SOTC_TravelPackageAlias_Basic, kSandboxPackages[2]) ;Always use 2048 radius package.

EndEvent


;Re-enstated in version 0.19.02.
Function SwapActorPackageData(Actor akActor, ReferenceAlias akPackageAliasToRemove, ReferenceAlias akPackageAliasToApply)

	akPackageAliasToRemove.RemoveFromRef(akActor)
	akPackageAliasToApply.ApplyToRef(akActor)
	SOTC_EvalPackageSpell.Cast(akActor, akActor) ;Force Evaluate in own thread.

EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;DISTANCE-BASED AMBUSH FUNCTIONS & EVENTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;Package Mode 3 Only. Rush Events are handled above. 

Event OnDistanceLessThan(ObjectReference akObj1, ObjectReference akObj2, float afDistance) ;Player and SP = parameters. 
	
	Int iCounter
	Int iSize = kGroupList.Length
	
	ApplyGroupSneakState() ;Removes sneak state previously set. 
	
	while iCounter < iSize
		ApplyPackageRushData(kGroupList[iCounter], akObj1, akObj2, false) ;Actors will return to this SP if Player escapes etc. 
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
	
	Bool bExpendPoint = false
	kPackageLocs = new ObjectReference[1] ;Create it, even if it is unused later. Now a variable in empty state as of version 0.19.01
	;Need to keep an eye on this in case it spits errors about being an empty array/Papyrus trashing it. 

	if iPackageMode == 1
		kPackageLocs[0] = RegionManager.GetRandomTravelLoc()
	elseif (bSpreadSpawnsToChildPoints) || (iPackageMode == 2) ;Patrol Mode, use ChildPoints array.
		kPackageLocs = kChildPoints
		iChildPointElectionTracker = new Int [1] ;Necessary evil so linking of Package can be done correctly.
	else
		bExpendPoint = true ;We won't want to place another group at same ChildPoint. 
	endif ;If nothing returned here, we must be using Sandbox package (Helpers will use Self as loc). If not weird things may happen.
	
	
	;Finally start creating Helper instances and giving them params. 
	;---------------------------------------------------------------
	
	Int iCounter
	ObjectReference kSpawnPoint
	ObjectReference kHelper
	kActiveHelpers = new ObjectReference[1] ;Init with one member, as Papyrus may trash it if not and we take too long.
	
	;Set the correct Package to send to Helper. 
	ReferenceAlias kPackageToSend
	
	if iPackageMode == 0 || iPackageMode == 5 ;Send same Package for Interiors, likely use default 512 radius (level 0). 
		kPackageToSend = kSandboxPackages[iSandboxRadiusLevel]
	elseif iPackageMode == 1
		kPackageToSend = SOTC_TravelPackageAlias_Basic
		bUseTravelSpellOrIgnoreExpiry = true
	elseif iPackageMode == 2
		kPackageToSend = kPatrolPackages[iNumPackageLocsRequired]
	elseif iPackageMode == 3
		kPackageToSend = SOTC_RushPackageAlias_Basic
	elseif iPackageMode == 4
		kPackageToSend = SOTC_HoldPackageAlias_Basic
	endif
	
	;DEV NOTE: Due to a limitation with the way expiry conditions are setup, Helpers cannot ignore expiry for travelling Actors. This is not an issue
	;as such as we prefer to apply as many performance measures as possible to MultiPoints. Most Actors will probably be dead before travelling anyway. 
	
	Int iStartLoc ;Only used if Package Mode 2 - Patrol. 
	
	if iSpawnMode == 0 ;Random mode
	;DEV NOTE: Faster to check for SP Mode now, rather than in while loops below. Difference is only index of ActorParamsScriptList passed.
		
		while iCounter < iGroupsToSpawn
			
			kSpawnPoint = GetChildPoint(bExpendPoint)
			if iPackageMode == 2 ;We will need to determine the Int index of the ChildPoint received if in Patrol Mode, so Helper can link in correct order.
				iStartLoc = kChildPoints.Find(kSpawnPoint)
			elseif iPackageMode == 3 ;We will send Ambush Distance setting as the iStartLoc instead
				iStartLoc = fAmbushDistance as Int
			endif
			
			kHelper = kSpawnPoint.PlaceAtMe(kMultiPointHelper) ;Place worker
			
			(kHelper as SOTC:SpHelperScript).SetHelperSpawnParams(RegionManager, ActorParamsScriptList[iCounter], iPackageMode, \
			kPackageToSend, kPackageLocs, bSpreadSpawnsToChildPoints, iPreset, iDifficulty, iStartLoc, bUseTravelSpellOrIgnoreExpiry)
			;Will auto fire the helper after this function call in it's own thread via timer there.
			
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
			kPackageToSend, kPackageLocs, bSpreadSpawnsToChildPoints, iPreset, iDifficulty, iStartLoc, bUseTravelSpellOrIgnoreExpiry)
			
			kActiveHelpers.Add(kHelper) ;Track worker
			iCounter += 1
		
		endwhile
		
	endif
	

	if kActiveHelpers[0] == None ; Security measure removes first member of None. See notes on Master as to why we do this.
		kActiveHelpers.Remove(0)
	endif
	
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
	
		kActiveChildren.Add(kChildPoints[i]) ;Add selected marker to active array (this array is non-const)
		kChildPoints.Remove(i) ;Remove from original array, guaranteeing it won't be selected again this session.
		;We will move it back/reset later
		
	else ;We track the index of each elected ChildPoint for later linking of Packages
		iChildPointElectionTracker.Add(i) ;should have been initialised before this function was called. First member of None to be removed later.
	endif
	
	return kMarkerToReturn ;Return the temp set from earlier
	
EndFunction


;Sets all Actors in the Group to start sneaking (or not if called again after).
Function ApplyGroupSneakState()
	
	Int iSize
	Int iCounter
	
	while iCounter < iSize
		
		kGroupList[iCounter].StartSneaking()
		iCounter += 1
		
	endwhile
	
EndFunction


;Test if Actors have 3d loaded. Added due to certain events being unreliable. 
Bool Function TestActorsInLoadedArea()

	int iCounter = 0
	int iSize = kGroupList.Length
	
	while iCounter < iSize
		
		if kGroupList[iCounter].Is3dLoaded() ;If true, Actor is loaded and we will return immediately flagging unsafe to reset.
			return true
		endif
		
		iCounter += 1
		
	endwhile
	
	return false ;Safe to reset if we got this far. 

EndFunction


;Tests if the Location data of the SPs cell is valid and cleared. 
Bool Function CheckSpLocationSafe()

	Location kCurrentLoc = (Self as ObjectReference).GetCurrentLocation()
	
	if kCurrentLoc != None && kCurrentLoc.IsCleared()
		return true
	else
		Debug.Trace("Interior Point denied as either location data is not set or it is not cleared. SpawnPoint ID was : " +Self as ObjectReference +" Location was: " +kCurrentLoc)
		return false
	endif
	
EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------
