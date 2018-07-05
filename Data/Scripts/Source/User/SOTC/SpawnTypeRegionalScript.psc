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

	SOTC:SpawnTypeMasterScript Property SpawnTypeMaster Auto
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
	{ Init True. Change in Menu. Enables or Disables this ST in this Region. }
	
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
	; [12] - SNIPER (CLASS-BASED) - Stores all Actor that support Sniper Class
	; [13] - SWARM/INFESTATION (CLASS-BASED) - Stores all Actors that support Swarm/Infestation
	; [14] - STAMPEDE (CLASS-BASED) - Stores all Actors that support extended Swarm feature Stampede.
	
	;NOTE: See "CLASSES VS SPAWNTYPES" commentary of the SpawnTypeMasterScript for more in-depth info
	
	Int Property iBaseClassID Auto
	{ Init 0. Filled at runtime if required. }
	
	;LEGEND - CLASSES
	; [0] - DEBUG AS OF VERSION 0.06.02.180506
	; [1] - COMMON RARITY
	; [2] - UNCOMMON RARITY
	; [3] - RARE RARITY
	; [4] - AMBUSH - RUSH (Wait for and rush the player)
	; [5] - SNIPER
	; [X] - SWARM/INFESTATION (no need to actually define a Class!)
	; [X] - STAMPEDE (no need to actually define a Class!)

EndGroup


Bool bInit ;Security check to make sure Init events/functions don't fire again while running


;------------------------------------------------------------------------------------------------
;INITIALISATION FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

;DEV NOTE: Init events/functions now handled by Masters creating the instances.

;Manager passes self in to set instance when calling this
Function PerformFirstTimeSetup(SOTC: RegionManagerScript aRegionManager, Int aiRegionID, Int aiWorldID, \
SOTC:ThreadControllerScript aThreadController, Int aiSpawntypeID, Int aiPresetToSet)

	if !bInit
		
		ThreadController = aThreadController
		
		RegionManager = aRegionManager
		iRegionID = aiRegionID
		iWorldID = aiWorldID
		iSpawnTypeID = aiSpawntypeID
		
		iCurrentPreset = aiPresetToSet
		
		SpawnTypeMaster = MasterScript.SpawnTypeMasters[iSpawnTypeID]
		RegionManager.SpawnTypes[iSpawnTypeID] = Self
		
		SetBaseClassIfRequired()
		
		FillDynActorLists()
		
		bInit = true
		
		Debug.Trace("SpawnType on Region created")
		
	endif
	
EndFunction


;Associates the Class Preset of Actor with this Spawntype of it is based on one, on first time setup.
Function SetBaseClassIfRequired()

	if iSpawnTypeID == 11 ;Ambush(Rush)
		iBaseClassID = 4
	elseif iSpawnTypeID == 12 ;Snipers
		iBaseClassID == 5
	endif
	;SpawnTypes 13 & 14 (Swarm/Rampage) do not have Class Presets, so they do not get defined. 
	
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

	SOTC:ActorManagerScript[] ActorList = SpawnTypeMaster.ActorList ;Link to master array for this ST
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


;Nullifies all dynamic data variables ready for destruction of this instance
Function MasterFactoryReset()

	SpawnTypeMaster = None
	CommonActorList.Clear()
	UncommonActorList.Clear()
	RareActorList.Clear()
	ThreadController = None
	RegionManager = None
	
	Debug.Trace("SpawnTypeRegional instance ready for destruction")
	;RegionManager will destroy this instance once returned. 
	
EndFunction
	

;------------------------------------------------------------------------------------------------
;RETURN FUNCTIONS
;------------------------------------------------------------------------------------------------

;Return single instance of ActorClassPresetScript (single Actor).
;NOTE - This returns class presets directly, as this saves storing/determining "rarity" elsewhere.
;We can still access the ActorManagerScript in the calling script from here.
SOTC:ActorClassPresetScript Function GetRandomActor(Int aiForcedRarity, Bool abForceClassPreset, Int aiForcedClassPreset)
;WARNING - Using "forced" params can only be used to get "Rarity" based Classes from here as it has
;no way to know if an Actor supports other classes without having to perform slow checks and rerolls.
;It can however force use of a different rarity-based Class Preset (will revert if trying to force a
;Class other than a Rarity-based one however).
;NOTE: If this Spawntype is based on a specific Class, I.E Sniper or Ambush, and we are not forcing
;the use of a specific ClassPreset, then this function will always pull that ClassPreset.

	int iRarity ;which list to use
	Int iClass ;Which ClassPreset to pull, if not Forced will use iRarity value.
		
	if aiForcedRarity > 0 ;Check if we are forcing a specific rarity list to be used
		iRarity = aiForcedRarity
	else
		iRarity = MasterScript.RollForRarity() ;Roll if not
		;This remains on MasterScript as the Chance settings are defined and stored there (Can only be set on Master level)
	endif
	
	
	if !abForceClassPreset ;Short circuit for speed, as this is the most likely setting.
		iClass = iRarity
	elseif abForceClassPreset && aiForcedClassPreset <= 3 ;Security check, if user entered more than 3, revert to iRarity value.
		iClass = aiForcedClassPreset
	elseif iBaseClassID > 0 ;If SpawnType based on Class, use that Class, if not forced above.
		iClass = iBaseClassID
	else ;Absolute failsafe, same as first check, in the event everything fails.
		iClass = iRarity
	endif
	
	
	if iRarity == 1
	
		;Check list actually has something\
		if CommonActorList[0] != None ;It's not empty, else fail to Uncommon list.
			return GetCommonActor(iClass)
		elseif UncommonActorList[0] != None ;It's not empty, else fail to Rare list.
			return GetUncommonActor(iClass)
		elseif (RareActorList[0] != None) ;It's not empty, else FAIL ENTIRELY.
			GetRareActor(iClass)
		else ;WOE, WOE IS YE! MELTDOWN BEGINS
			Debug.Trace("MAJOR ERROR: SPAWNTYPE REGIONAL LISTS EMPTY, SPAWNPOINT MELTDOWN UNDERWAY, PAPYRUS ERRORS TO ENSUE! ID was:" +iSpawnTypeID)
			;SPAWNPOINT WILL NOW FIRE ON NOTHING, PAPYRUS LOG WILL BE FULL OF ERRORS, SAVE GAME BROKEN AND PC CATCH FIRE!
			Debug.Trace("PSYCH! RETURNING RADROACHES INSTEAD! KEKEKEKEK!")
			return MasterScript.GetMasterFailsafeActor()
			
		endif ;ENDTIMES!
		
		
	elseif iRarity == 2
	
		if UncommonActorList[0] != None ;It's not empty, else fail to Rare list first.
			return GetUncommonActor(iClass)
		elseif (RareActorList[0] != None) ;It's not empty, else fail to Common list last.
			GetRareActor(iClass)
		elseif CommonActorList[0] != None ;It's not empty, else FAIL ENTIRLEY.
			return GetCommonActor(iClass)
		else ;WOE, WOE IS YE! MELTDOWN BEGINS
			Debug.Trace("MAJOR ERROR: SPAWNTYPE REGIONAL LISTS EMPTY, SPAWNPOINT MELTDOWN UNDERWAY, PAPYRUS ERRORS TO ENSUE! ID was:" +iSpawnTypeID)
			;SPAWNPOINT WILL NOW FIRE ON NOTHING, PAPYRUS LOG WILL BE FULL OF ERRORS, SAVE GAME BROKEN AND PC CATCH FIRE!
			Debug.Trace("PSYCH! RETURNING RADROACHES INSTEAD! KEKEKEKEK!")
			return MasterScript.GetMasterFailsafeActor()
			
		endif ;ENDTIMES!


	else ;Not going to bother checking for 3, if somehow its not 1, 2 or 3, Rare will be selected.
		
		if RareActorList[0] != None ;It's not empty, else fail to Uncommon list.
			return GetUncommonActor(iClass)
		elseif (UncommonActorList[0] != None) ;It's not empty, else fail to Common list last.
			GetRareActor(iClass)
		elseif CommonActorList[0] != None ;It's not empty, else FAIL ENTIRLEY.
			return GetCommonActor(iClass)
		else ;WOE, WOE IS YE! MELTDOWN BEGINS
			Debug.Trace("MAJOR ERROR: SPAWNTYPE REGIONAL LISTS EMPTY, SPAWNPOINT MELTDOWN UNDERWAY, PAPYRUS ERRORS TO ENSUE! ID was:" +iSpawnTypeID)
			;SPAWNPOINT WILL NOW FIRE ON NOTHING, PAPYRUS LOG WILL BE FULL OF ERRORS, SAVE GAME BROKEN AND PC CATCH FIRE!
			Debug.Trace("PSYCH! RETURNING RADROACHES INSTEAD! KEKEKEKEK!")
			return MasterScript.GetMasterFailsafeActor()
			
		endif ;ENDTIMES!

		
	endif
	
EndFunction

;The following functions were encapsulated as of version 0.13.01. If the requested list is empty
;it will default to the next, more common, list. Common list should ALWAYS have something in it. 

;Gets a Common Actor type for this Region
SOTC:ActorClassPresetScript Function GetCommonActor(Int aiClass)
	
	;Common list should ALWAYS have something in it.
	
	Int iSize = CommonActorList.Length - 1
	return CommonActorList[(Utility.RandomInt(0,iSize))].ClassPresets[aiClass]

EndFunction

;Gets a Uncommon Actor type for this Region
SOTC:ActorClassPresetScript Function GetUncommonActor(Int aiClass)
	
	Int iSize = UncommonActorList.Length - 1
	
	if  (UncommonActorList[0] != None) ;Check the list is initialised and has something on it. 
		return UncommonActorList[(Utility.RandomInt(0,iSize))].ClassPresets[aiClass]
	else ;Otherwise default to Common list
		return GetCommonActor(aiClass)
	endif
	
EndFunction

;Gets a Rare Actor type for this Region
SOTC:ActorClassPresetScript Function GetRareActor(Int aiClass)
	
	Int iSize = RareActorList.Length - 1
	
	if  (RareActorList[0] != None) ;Check the list is initialised and has something on it. 
		return UncommonActorList[(Utility.RandomInt(0,iSize))].ClassPresets[aiClass]
	else ;Otherwise default to Uncommon list
		return GetUncommonActor(aiClass)
	endif
	
EndFunction


;Return array of ActorClassPresetScript (multiple Actors).
;NOTE - This returns class presets directly, as this saves storing/determining "rarity" elsewhere.
;We can still access the ActorManagerScript in the calling script from here.
SOTC:ActorClassPresetScript[] Function GetRandomActors(int aiForcedRarity, Bool abForceClassPreset, Int aiForcedClassPreset, int aiNumActorsRequired)
;WARNING - Using "forced" params to get ClassPresets not based on Rarity (1-3) should be used with caution
;(if only from the SpMiniPointScript) as this 
;It can however force use of a different rarity-based Class Preset (will revert if trying to force a
;Class other than a Rarity-based one however).
;NOTE: If this Spawntype is based on a specific Class, I.E Sniper or Ambush, and we are not forcing
;the use of a specific ClassPreset, then this function will always pull that ClassPreset.
	
	ActorClassPresetScript[] ActorListToReturn = new ActorClassPresetScript[1] ;Temp array used to send back
	Int iRarity ;which list to use
	Int iClass ;Which ClassPreset to pull, if not Forced will use iRarity value.
	Int iCounter = 0 ;Count up to required amount
		
	if aiForcedRarity > 0 ;Check if we are forcing a specific rarity list to be used
		iRarity = aiForcedRarity 
	else
		iRarity = MasterScript.RollForRarity() ;Roll if not
		;This remains on MasterScript as the Chance settings are defined and stored there (Can only be set on Master level)
	endif
	
	
	if !abForceClassPreset ;Short circuit for speed, as this is the most likely setting.
		iClass = iRarity
	elseif abForceClassPreset && aiForcedClassPreset <= 3 ;Security check, if user entered more than 3, revert to iRarity value.
		iClass = aiForcedClassPreset
	elseif iBaseClassID > 0 ;If SpawnType based on Class, use that Class, if not forced above.
		iClass = iBaseClassID
	else ;Absolute failsafe, same as first check, in the event everything fails.
		iClass = iRarity
	endif
	
	
	while iCounter < aiNumActorsRequired ;Maximum of 5 in default mod. Modders may use more.
		
		if iRarity == 1
			ActorListToReturn.Add((GetCommonActor(iClass)))
		elseif iRarity == 2
			ActorListToReturn.Add((GetUncommonActor(iClass)))
		else ;Not going to bother checking for 3, if somehow its not 1, 2 or 3, Rare will be selected.
			ActorListToReturn.Add((GetRareActor(iClass)))
		endif
		
	endwhile
	
	ActorListToReturn.Remove(0) ;Remove first member of None.
	
	return ActorListToReturn ;GTFO
	
EndFunction

;DEV NOTE - All functionality for random swarms and ambushes is moved to SpawnPoint/RegionManager scripts.

;------------------------------------------------------------------------------------------------
