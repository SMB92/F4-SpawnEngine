Scriptname SOTC:SpawnTypeRegionalScript extends ObjectReference
{ Tempalte script for Regions, holds dynamic Actor lists for a "Spawntype" in that Region. }
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

Group Primary

	SOTC:MasterQuestScript Property MasterScript Auto Const Mandatory
	{ Fill with MasterQuest }

EndGroup


Group Dynamic

	SOTC:ThreadControllerScript Property ThreadController Auto
	{ Init None, fills at runtime. }

	SOTC:SpawnTypeMasterScript Property ActorListScript Auto
	{ Init None, fills at runtime. }

	SOTC:RegionManagerScript Property RegionManager Auto
	{ Init None, fills at runtime. }
	
	Int Property iRegionID Auto
	{ Init 0, fills at runtime. }
	
	Int Property iWorldID Auto
	{ Init 0, fills at runtime. }
	; LEGEND - WORLDS
	; [0] - COMMONWEALTH
	; [1] - FAR HARBOR
	; [2] - NUKA WORLD
	
	Bool Property bSpawnTypeEnabled Auto
	{ Init True. Change in Menu. }
	
	Int Property iCurrentPreset Auto
	{ Initialise 0. Set by Menu/Preset. Determines each Actors Rarity in this Spawntype/Region }
	
	Bool Property bCustomSettingsActive Auto
	{ Init False. Set by Menu when custom settings have been applied. }

	SOTC:ActorManagerScript[] Property CommonActorList Auto
	{ Initialise one member of None. Fills dynamically. }

	SOTC:ActorManagerScript[] Property UncommonActorList Auto
	{ Initialise one member of None. Fills dynamically. }

	SOTC:ActorManagerScript[] Property RareActorList Auto
	{ Initialise one member of None. Fills dynamically. }
	
	Int Property iSpawnTypeID Auto
	{ Init 0, filled at runtime. }
	
	;LEGEND - SPAWNTYPES
	;Spawntypes are essentially "categories" of spawns and species. These are used to provide
	;variety of spawns in different locations. Each SpawnType has a Master Script, which holds
	;the Master list of all Actor types in that category, as well as a Regional script, which
	;defines which Actors of that Spawntype are allowed in that Region (and can also have their
	;"Rarity" defined for that area). They are as follows: (subject to additional types in future)
	
	;(NOTE: It is possible for some Actors to be of "mixed" type and appear in multiple lists)
	; [0] - MAIN/MIXED RANDOM - consider this like "urban" spawns, the most common type used
	;This is essentially a random list of anything and everything that would be common enough 
	;to spawn in a Region.
	; [1] - URBAN - Minimal Wildlife
	; [2] - WILD - Common wild area stuff
	; [3] - RADSPAWN - Radiated areas spawns
	; [4] - HUMAN
	; [5] - MUTANT
	; [6] - FAUNA
	; [7] - INSECT
	; [8] - MONSTER
	; [9] - ROBOT
	; [10] - AQUATIC - Given the lack of real Aquatic spawns, this includes other things that
	;might appear in swamp/marsh/waterside etc.
	; [11] - AMBUSH - RUSH (CLASS-BASED) - Stores all Actors that support rushing the player
	;style of ambush
	; [12] - AMBUSH - STATIC (CLASS-BASED) - Stores all Actors that support rushing the player
	;style of ambush
	; [13] - SNIPER (CLASS-BASED) - Stores all Actor that support Sniper Class
	; [14] - SWARM/INFESTATION (CLASS-BASED) - Stores all Actors that support Swarm/Infestation
	; [15] - STAMPEDE (CLASS-BASED) - Stores all Actors that support extended Swarm feature Stampede.
	
	;NOTE: See "CLASSES VS SPAWNTYPES" commentary of the SpawnTypeMasterScript for more in-depth info
	
	Int Property iBaseClassID Auto
	{ Init 0. Filled at runtime if required. }
	
	;LEGEND - CLASSES
	; [0] - DEBUG AS OF VERSION 0.06.02.180506
	; [1] - COMMON RARITY
	; [2] - UNCOMMON RARITY
	; [3] - RARE RARITY
	; [4] - AMBUSH - RUSH (Wait for and rush the player)
	; [5] - AMBUSH - STATIC (for "hidden" ambushes such as Mirelurks and Molerats)
	; [6] - SNIPER
	; [X] - SWARM/INFESTATION (no need to actually define a Class!)
	; [X] - STAMPEDE (no need to actually define a Class!)

EndGroup


Group LootSystemProperties

	Bool Property bLootSystemEnabled Auto
	{ Init False. Set in Menu. When on, spawned Actors of this type may possibly 
receive a loot item from one of the Formlists below }
	
	Formlist Property kRegularLootList Auto
	{ Fill with Formlist made for this Actor Type's regular loot }
	
	Formlist Property kBossLootList Auto
	{ Fill with Formlist made for this Actor Type's boss loot }
	
	Int Property iRegularLootChance = 20 Auto
	{ Init 20. Change in Menu. Chance an Actor will receive a loot item. }
	
	Int Property iBossLootChance = 10 Auto
	{ Init 10. Change in Menu. Chance an Actor will receive a loot item. }

EndGroup

;LEGEND - LOOT SYSTEM
;There are 2 ways to provide random spawns with a random loot item (or more if using an "Use All" 
;flagged Leveled List) - through the SpawnTypeRegionalScript or the ActorManagerScript. Both systems
;are identical in function and setup, but can operate independantly. The system works by storing
;formlists on each of the scripts, 1 for regular Actors and 1 for Boss Actors. Spawnpoints will
;check both scripts after spawntime (after all actors are placed in game and packages applied,
;preventing unnecessary slowdown in the spawnloops themselves), and if this system is enabled, it
;will send in the GroupList for that Spawnpoint and do a loop to add a single item from the list to
;each Actors inventory, based on a configurable chance value. The single item can be a Leveled List, 
;and if it is marked to Use All, will add every item from that list.

;Loot on the Spawntype script should be applicable to all Actors in that Spawntype, this is intended
;to be a generalised loot table. The reason why this system is included on the Region Spawntype 
;script, and not the Master Spawntype, is so we can specify different loot per Region if we wish.
;Loot on the ActorManagerScript is obviously so we can supply highly specific loot for each Actor type. 
;As mentioned above, either can be enabled/disabled, they are independant from each other. Chance of
;loot values can be defined for both Regular and Boss Actors independantly on each script as well. 

;Fun fact: It was originally an idea to provide loot by using a RefCollectionAlias with specified
;Leveled Lists, and then add Actors to this collection so they'd automatically get the loot without
;any coding necessary. However, this posed some complications for third-party addons as far as using
;scripts to add loot, and thus I developed the formlist approach, so that now addons can both safely
;add and remove loot items from the list via script. It is also useful in the same sense for adding
;temporary loot to the lists, in case we want to do so for some event such as a quest etc. 


Bool bInit ;Security check to make sure Init events/functions don't fire again while running


;------------------------------------------------------------------------------------------------
;INITIALISATION & SETTINGS EVENTS
;------------------------------------------------------------------------------------------------

;DEV NOTE: Init events/functions now handled by Masters creating the instances.

;Manager passes self in to set instance when calling this
Function PerformFirstTimeSetup(SOTC: RegionManagerScript aRegionManager, Int aiRegionID, Int aiWorldID, \
SOTC:ThreadControllerScript aThreadController, Int aiSpawntypeID, Formlist akRegLoot, Formlist akBossLoot, Int aiPresetToSet)

	if !bInit
		
		ThreadController = aThreadController
		
		RegionManager = aRegionManager
		iRegionID = aiRegionID
		iWorldID = aiWorldID
		iSpawnTypeID = aiSpawntypeID
		kRegularLootList = akRegLoot
		kBossLootList = akBossLoot
		
		iCurrentPreset = aiPresetToSet
		
		ActorListScript = MasterScript.SpawnTypeMasters[iSpawnTypeID]
		RegionManager.SpawnTypes[iSpawnTypeID] = Self
		
		SetBaseClassIfRequired()
		
		FillDynActorLists()
		
		bInit = true
		
		Debug.Trace("SpawnType on Region +iRegionID on World +iWorldID creation complete")
		
	endif
	
EndFunction


;Associates the Class of this Spawntype of it is based on one, on first time setup.
Function SetBaseClassIfRequired()

	if iSpawnTypeID == 11 ;Ambush(Rush)
		iBaseClassID = 4
	elseif iSpawnTypeID == 12 ;Ambush(Static)
		iBaseClassID = 5
	elseif iSpawnTypeID == 13 ;Snipers
		iBaseClassID == 6
	endif
	
EndFunction


;Usually called by Region script during Preset changes
Function ReshuffleDynActorLists(Bool abForceReset, int aiPreset)

	;This function can be called directly from menu to set a custom preset choice. Set parameters
	;(true, preset) and then flag bCustomSettingsActive as true. No need for checks as user is
	;intending for this to happen. Menu can also force a reset by passing (true, 0) to this function.

	if (bCustomSettingsActive) && (!abForceReset)
		return ;DENIED, return immediately. 
	endif
	;else continue.
	
	if aiPreset > 0 ;If 0, just reshuffle as normal. While likely unused, exists if needed.
		iCurrentPreset = aiPreset ;Set the Preset here
	endif
	
	SafelyClearDynActorLists()
	FillDynActorLists()

EndFunction


;Fill Actor lists on this script, placing into correct lists as per Preset. 
Function FillDynActorLists()

	SOTC:ActorManagerScript[] ActorList = ActorListScript.ActorList ;Link to master array for this ST
	;We won't store this in a permanent variable, we only need to know about it here
	
	;Security check, mainly for Alpha purposes, to skip this function if no Actors are declared on Master Spawntype
	if ActorList[0] == None
		Debug.Trace("Regional SpawnType script detected empty Master version list, skipping filling of dynamic lists")
		return
	endif

	int iSize = ActorList.Length 
	int iCounter = 0
	Int iActorPreset
	
	while iCounter < iSize ;Won't overshoot
	
		iActorPreset = ActorList[iCounter].WorldPresets[iWorldID].GetActorRegionPreset(iRegionID, iCurrentPreset)
		
		if iActorPreset == 1 ;Common
			CommonActorList.Add(ActorList[iCounter])
		elseif iActorPreset == 2 ;Uncommon
			UncommonActorList.Add(ActorList[iCounter])
		elseif iActorPreset == 3 ;Rare
			RareActorList.Add(ActorList[iCounter])
		;else
			;Do nothing, Actor is disabled in this Region or unexpected Int returned
		endif
		
		iCounter += 1
	
	endwhile
	
	;Detect and remove first member of None on filled lists, if it exists.
	
	if (CommonActorList.Length > 1) && (CommonActorList[0] == None)
		CommonActorList.Remove(0)
	endif
	
	if (UncommonActorList.Length > 1) && (UncommonActorList[0] == None)
		UncommonActorList.Remove(0)
	endif
	
	if (RareActorList.Length > 1) && (RareActorList[0] == None)
		RareActorList.Remove(0)
	endif
	
EndFunction


;Clear all Actor lists on this script
Function SafelyClearDynActorLists()

	CommonActorList.Clear()
	CommonActorList = new SOTC:ActorManagerScript[1]
	UncommonActorList.Clear()
	UncommonActorList = new SOTC:ActorManagerScript[1]
	RareActorList.Clear()
	RareActorList = new SOTC:ActorManagerScript[1]
	
EndFunction


;------------------------------------------------------------------------------------------------
;RETURN FUNCTIONS
;------------------------------------------------------------------------------------------------

;Return single instance of ActorClassPresetScript (single Actor).
;NOTE - This returns class presets directly, as this saves storing/determining "rarity" elsewhere.
;We can still access the ActorManagerScript in the calling script from here.
SOTC:ActorClassPresetScript Function GetRandomActor(int aiForcedRarity)
;WARNING - Using "forced" params can only be used to get "Rarity" based Classes from here as it has
;no way to know if an Actor supports other classes without having to perform slow checks and rerolls.

	int iRarity ;which list to use
	int iSize ;size of list to use
		
	if aiForcedRarity > 0 ;Check if we are forcing a specific rarity list to be used
		iRarity = aiForcedRarity
	else
		iRarity = MasterScript.RollForRarity() ;Roll if not
	endif
	
	
	if iRarity == 1
		
		iSize = CommonActorList.Length - 1
		if iBaseClassID == 0 ;More likely to be 0 so check this first for speed. 
			return CommonActorList[(Utility.RandomInt(0,iSize))].ClassPresets[iRarity]
		else ;Shouldn't need to check, will fail/return wrong Class if Int not set correctly
			return CommonActorList[(Utility.RandomInt(0,iSize))].ClassPresets[iBaseClassID]
		endif
			
		
	elseif iRarity == 2
		
		iSize = UncommonActorList.Length - 1
		if iBaseClassID == 0 ;More likely to be 0 so check this first for speed. 
			return UncommonActorList[(Utility.RandomInt(0,iSize))].ClassPresets[iRarity]
		else ;Shouldn't need to check, will fail/return wrong Class if Int not set correctly
			return UncommonActorList[(Utility.RandomInt(0,iSize))].ClassPresets[iBaseClassID]
		endif
		
	else ;Not going to bother checking for 3, if somehow its not 1, 2 or 3, Rare will be selected
		
		iSize = RareActorList.Length - 1
		if iBaseClassID == 0 ;More likely to be 0 so check this first for speed. 
			return RareActorList[(Utility.RandomInt(0,iSize))].ClassPresets[3]
		else ;Shouldn't need to check, will fail/return wrong Class if Int not set correctly
			return RareActorList[(Utility.RandomInt(0,iSize))].ClassPresets[iBaseClassID]
		endif
		
	endif
	
EndFunction


;Return array of ActorClassPresetScript (multiple Actors).
;NOTE - This returns class presets directly, as this saves storing/determining "rarity" elsewhere.
;We can still access the ActorManagerScript in the calling script from here.
SOTC:ActorClassPresetScript[] Function GetRandomActors(int aiForcedRarity, int aiNumActorsRequired)
;WARNING - Using "forced" params can only be used to get "Rarity" based Classes from here as it has
;no way to know if an Actor supports other classes without having to perform slow checks and rerolls.
	
	ActorClassPresetScript[] ActorListToReturn = new ActorClassPresetScript[1] ;Temp array used to send back
	int iRarity ;which list to use
	int iSize ;size of list to use
	int iCounter = 0 ;Count up to required amount
	
	;if RegionScript.bRandomInfestEnabled ETC ETC
	
	while iCounter < aiNumActorsRequired ;Maximum of 5 in default mod. Modders may use more.
		
		if aiForcedRarity > 0 ;;Check if we are forcing a specific rarity list to be used
			iRarity = aiForcedRarity
		else
			iRarity = MasterScript.RollForRarity() ;Roll each time
		endif
		
		if iRarity == 1
			
			iSize = CommonActorList.Length - 1
			if iBaseClassID == 0 ;More likely to be 0 so check this first for speed. 
				ActorListToReturn.Add((CommonActorList[(Utility.RandomInt(0,iSize))]).ClassPresets[iRarity])
			else ;Shouldn't need to check, will fail/return wrong Class if Int not set correctly
				ActorListToReturn.Add((CommonActorList[(Utility.RandomInt(0,iSize))]).ClassPresets[iBaseClassID])
			endif
				
		elseif iRarity == 2
			
			iSize = UncommonActorList.Length - 1
			if iBaseClassID == 0 ;More likely to be 0 so check this first for speed. 
				ActorListToReturn.Add((UncommonActorList[(Utility.RandomInt(0,iSize))]).ClassPresets[iRarity])
			else ;Shouldn't need to check, will fail/return wrong Class if Int not set correctly
				ActorListToReturn.Add((UncommonActorList[(Utility.RandomInt(0,iSize))]).ClassPresets[iBaseClassID])
			endif
			
		else ;Not going to bother checking for 3, if somehow its not 1,2 or 3, Rare will be selected
			iSize = RareActorList.Length - 1
			if iBaseClassID == 0 ;More likely to be 0 so check this first for speed. 
				ActorListToReturn.Add((RareActorList[(Utility.RandomInt(0,iSize))]).ClassPresets[3])
			else ;Shouldn't need to check, will fail/return wrong Class if Int not set correctly
				ActorListToReturn.Add((RareActorList[(Utility.RandomInt(0,iSize))]).ClassPresets[iBaseClassID])
			endif
			
		endif
		
	endwhile
	
	ActorListToReturn.Remove(0) ;Remove first member of None.
	
	return ActorListToReturn ;GTFO
	
EndFunction

;NOTE - All functionality for random swarms and ambushes is moved to SpawnPoint scripts. It remains
;possible the code could be moved back to here if a nicer method is found or it becomes necessary for
;at least some types of SpawnPoints.


;------------------------------------------------------------------------------------------------
;LOOT FUNCTIONS
;------------------------------------------------------------------------------------------------

;Run a chance loop on a Spawnpoints Grouplist, potentially adding a loot item to each Actor in the list.
Function DoLootPass(Actor[] akGroupList, Int aiBossCount)
	
	Int iCounter 
	Int iGroupSize = akGroupList.Length
	Int iLootListSize = (kRegularLootList.GetSize()) -1 ;Actual index count
	Form kLootItem
	
	;Regular Actors including Bosses if present
	
	while iCounter < iGroupSize
		
		if (Utility.RandomInt(1,100)) < iRegularLootChance
			kLootItem = kRegularLootList.GetAt((Utility.RandomInt(0, iLootListSize))) ;Select random item
			akGroupList[iCounter].AddItem(kLootItem, 1, true) ;Add to this Actor
		endif
			
		iCounter += 1
			
	endwhile
		
	if aiBossCount > 0 ;Check if any Bosses and do their loot pass
	
		iLootListSize = (kBossLootList.GetSize()) -1 ;Actual index count
		iCounter = (iGroupSize) - (aiBossCount) ;Start Counter where Bosses start on the list
		
		while iCounter < iGroupSize
		
			if (Utility.RandomInt(1,100)) < iBossLootChance
				kLootItem = kBossLootList.GetAt((Utility.RandomInt(0, iLootListSize))) ;Select random item
				akGroupList[iCounter].AddItem(kLootItem, 1, true) ;Add to this Actor
			endif
			
			iCounter += 1
			
		endwhile
		
	endif

EndFunction


;------------------------------------------------------------------------------------------------
