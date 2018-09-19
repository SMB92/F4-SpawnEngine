Scriptname SOTC:RegionManagerScript extends ObjectReference
{ Used for each Region in a World. Holds all specific properties for the Region }
;Written by SMB92
;Special thanks to J. Ostrus [BigandFlabby] for code contributions that made this mod possible.

;LEGEND - PREFIX CONVENTION
; Variables and Properties are treated the same. Script types do not have prefixes, unless they
;are explicitly received as function arguments and are multi-instance scripts.
; "a" - (Function/Event Blocks only) Variable was received as function argument OR the variable
;was created from a passed-in Struct/Var[] member
; "k" - Is an "Object" as usual, whether created in a Block or defined in the empty state/a state.
; "f,b,i,s" - The usual Primitives: Float, Bool, Int, String.

;-------------------------------------------------------------------------------------------------------------------------------------------------------
;PROPERTIES & IMPORTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

Group Primary
{ Primary Properties Group }

	SOTC:MasterQuestScript Property MasterScript Auto Const Mandatory
	{ Fill with MasterQuest. }
	
	MiscObject Property kSpawnTypeObject Auto Const
	{ Fill with base MiscObject containing the SpawnTypeRegionalScript. }
	
	GlobalVariable Property SOTC_Global01 Auto Const Mandatory
	{ Auto-fill }
	GlobalVariable Property SOTC_Global02 Auto Const Mandatory
	{ Auto-fill }
	GlobalVariable Property SOTC_Global03 Auto Const Mandatory
	{ Auto-fill }

EndGroup


Group Dynamic

	SOTC:ThreadControllerScript Property ThreadController Auto
	{ Init None. Fills dynamically. }
	
	SOTC:RegionPersistentDataScript Property RegionPersistentDataStore Auto
	{ Init None, fills dynamically. }

	SOTC:SpawnTypeRegionalScript[] Property SpawnTypes Auto
	{ Initialise None on as many members as there are SpawnTypes. Sets dynamically. }
	
	Int Property iWorldID Auto
	{ Init 0, filled at runtime. }
	;LEGEND - WORLD IDs
	; [0] - COMMONWEALTH
	; [1] - FAR HARBOR
	; [2] - NUKA WORLD

	Int Property iRegionID Auto
	{ Init 0, filled at runtime. }

EndGroup


Group EncounterZoneProperties
{EZ Properties and settings for this Region}

	;DEV NOTE: As of version 0.19.01 EZ arrays have moved to the new RegionPersistentDataScript and are filled via editor.
	;Accessing this data will be done via this new instance stored on this script at runtime.

	Int Property iEzApplyMode Auto
	{ Initialise with 0. Set in Menu }
	;LEGEND - iEzMode
	; [0] - OFF, USE DEFAULT AREA (FASTEST?)
	; [1] - ON, USE ONE EZ PER GROUP (RECOMMENDED)
	; [2] - ON, USE ONE EZ PER INDIVIDUAL ACTOR (SLOWEST)

	Int Property iEzBorderMode Auto
	{ Initialise with 0. Set in Menu }
	;LEGEND - iEzMode
	; [0] - OFF, NPCS WON'T FOLLOW (RECOMMENDED)
	; [1] - ON, NPCS FOLLOW (USES LIST WITH BORDERS DISABLED)

EndGroup


Group RegionSettings
{ Various settings for this Region }
	
	Int Property iRegionSpawnChance = 100 Auto
	{ Default 100, change in Menu. Chance SpawnPoints firing in this Region, has massive effect on balance. }

	Int Property iCurrentPreset Auto
	{ Initialise 0. Set by Menu/Preset. }

	Int Property iCurrentDifficulty Auto
	{ Initialise 0. Set in Menu. }
	;LEGEND - DIFFICULTY LEVELS
	;Same as Vanilla. Only in Bethesda games does None = 4 (value 4 is "No" difficulty, scale to player)
	; 0 - Easy
	; 1 - Medium
	; 2 - Hard
	; 3 - Very Hard ("Veteran" in SOTC)
	; 4 - NONE - Scale to player.
	
	Float Property fSpResetTimerClock = 168.0 Auto
	{ Clock for SpawnPoint reset, applies to all SpawnPoints in Region. Default value of 7 days (Game Time). Set by Menu.}
	

EndGroup


Group FeatureSettings
{ Settings for various features supported on the Regional level. }

	Int[] Property iSpPresetChanceBonusList Auto ;Can be modified from Menu
	{ Members 1-3 (0 is debug) can be set from Menu to apply a bonus "chance to fire" percent value to all SpawnPoints in the Region.
Init 4 members with default values of 0 = 100, 1 = 5, 2 = 10, 3 = 20.	}

	Int Property iRandomSwarmChance Auto
	{ Initialise 0, set in Menu. If any value above 0, there is a chance of a random swarm/infestation. }
	
	Int Property iRandomRampageChance Auto
	{ Initialise 0, set in Menu. Can only occur during a successful Swarm/Infestation, and if Actor
supports this mode. If any value above 0, there is a chance of a stampede. }
	
	Int Property iRandomAmbushChance Auto
	{ Initialise 0, set in Menu. If any value above 0, there is a chance of a random swarm/infestation. }

EndGroup


;Temp Variables
;---------------

Bool bInit ;Security check to make sure Init events/functions don't fire again while running

;NOTE - Random events are currently not fully implemented on the Regional level as of 0.19.01, added for future use.
Bool bEventThreadLockEngaged ;Used to skip/block spawn event checker
SOTC:SpawnPointScript kEventPoint ;When an event fires, this will set with the intercepted calling point


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;INITIALISATION FUNCTIONS & EVENTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;DEV NOTE: Init events/functions now handled by Masters creating the instances.

Function PerformFirstTimeSetup(SOTC:WorldManagerScript aWorldManager, SOTC:ThreadControllerScript aThreadController, \
ObjectReference akMasterMarker, Int aiWorldID, Int aiRegionID, Int aiPresetToSet, MiscObject akRegionPersistentDataObject) 
;DEV NOTE: As of version 0.19.01 EZ arrays have moved to the new RegionPersistentDataScript and are filled via editor.
;Accessing this data will be done via this new instance passed. created and stored here.
	
	if !bInit
		
		ThreadController = aThreadController 
		
		iWorldID = aiWorldID
		iRegionID = aiRegionID
		iCurrentPreset = aiPresetToSet
		;SetPresetVars() Temporaily removed in version 0.18.01
		
		RegisterForCustomEvent(MasterScript, "PresetUpdate")
		RegisterForCustomEvent(MasterScript, "MasterSingleSettingUpdate")
		
		Debug.Trace("Region master data set, creating dynamic instances now")
		
		;Create instances of spawntype objectreferences and set them up
		ObjectReference kNewInstance
		
		;New in version 0.19.01, this contains all TravelLocs, EZ data and SpawnPoints for this Region.
		kNewInstance = akMasterMarker.PlaceAtMe(akRegionPersistentDataObject, 1 , false, false, false)
		RegionPersistentDataStore = kNewInstance as SOTC:RegionPersistentDataScript
		
		Int iCounter
		Int iSize = MasterScript.SpawnTypeMasters.Length
		
		while iCounter < iSize
		
			Debug.Trace("Creating SpawnTypeRegional manager on Region")
		
			kNewInstance = akMasterMarker.PlaceAtMe(kSpawnTypeObject, 1 , false, false, false)
			(kNewInstance as SOTC:SpawnTypeRegionalScript).PerformFirstTimeSetup(Self, iRegionID, iWorldID, \
			ThreadController, iCounter, iCurrentPreset)
			;Object self sets onto tracking array on this instance. 
			
			iCounter += 1
			
		endwhile
		
		ThreadController.IncrementActiveRegionsCount(1)
		bInit = true
		
		Debug.Trace("Region creation complete")
		
	endif

EndFunction


Event SOTC:MasterQuestScript.PresetUpdate(SOTC:MasterQuestScript akSender, Var[] akArgs)

	Bool bEnabled ;Disable the Region if ON, and prepare to turn back ON later
	;NOTE: Master script is handling Thread Killer. 
	
	if (akArgs[0] as string) == "Full"
		
		iCurrentPreset = akArgs[1] as Int
		ReshuffleActorLists()
		;DEV NOTE: Calling this function will safely reinitialise the arrays, no work need be done here.
	
	elseif (akArgs[0] as string) == "SingleSpawntype"

		;(akArgs[1]) = SpawnType to update
		SpawnTypes[(akArgs[1] as Int)].ReshuffleDynActorLists(akArgs[2] as Int)
		;(akArgs[2]) = Preset to Set

	endif
	
	ThreadController.iEventFlagCount += 1 ;Flag as complete
	Debug.Trace("Region flagged Master Preset Update as complete. ID was: " +iRegionID)

EndEvent


Event SOTC:MasterQuestScript.MasterSingleSettingUpdate(SOTC:MasterQuestScript akSender, Var[] akArgs)
	
	;NOTE: Event Monitor does not monitor settings events. No need. Menu safe.
	
	if (akArgs[0] as string) == "Difficulty"
	
		iCurrentDifficulty = akArgs[1] as Int
	
	elseif (akArgs[0] as string) == "EzApplyMode"
	
		iEzApplyMode = akArgs[1] as Int

	elseif (akArgs[0] as string) == "EzBorderMode"
	
		iEzBorderMode = akArgs[1] as Int

	elseif (akArgs[0] as string) == "RegionSwarmChance"
	
		iRandomSwarmChance = akArgs[1] as Int
		
	elseif (akArgs[0] as string) == "RegionRampageChance"
	
		iRandomRampageChance = akArgs[1] as Int
		
	elseif (akArgs[0] as string) == "RegionAmbushChance"
	
		iRandomAmbushChance = akArgs[1] as Int
		
	elseif (akArgs[0] as string) == "SpPresetChanceBonus"
		
		Int i = akArgs[1] as Int
		iSpPresetChanceBonusList[i] = akArgs[2] as Int
		;[1] = index, [2] = value to set. 
		
	elseif (akArgs[0] as string) == "SpResetClock"
		
		fSpResetTimerClock = akArgs[1] as Float
		
	endif
	
EndEvent
	

;This function SERIALIZES reshuffle of Spawntype Actor Lists. Should be safe to run in Menu mode.
Function ReshuffleActorLists() ;All Spawntypes attached.
	
	;NOTE: ThreadKiller should be engaged before calling this for safety reasons. 
	
	Debug.Trace("Reshuffling Region Actor lists for all SpawnTypes on Region: " +iRegionID)

	int iCounter = 0
	int iSize = SpawnTypes.Length
	
	while iCounter < iSize
		
		Spawntypes[iCounter].ReshuffleDynActorLists(iCurrentPreset)
		;If SpawnType is running custom settings, will return immediately if parameter is False.
		Debug.Trace("Region SpawnType Actor lists reshuffled for SpawnType ID: " +iCounter)
		iCounter += 1
		
	endwhile
	
EndFunction


;Fully cleans up all dynamically produced data in preparation for destruction of this instance.
Function MasterFactoryReset()
	
	Int iCounter
	Int iSize = SpawnTypes.Length
	
	;Now we will destroy all the SPawnTypeRegional instances
	while iCounter < iSize
		SpawnTypes[iCounter].MasterFactoryReset()
		SpawnTypes[iCounter].Disable()
		SpawnTypes[iCounter].Delete()
		SpawnTypes[iCounter] = None ;De-persist
		iCounter += 1
		Debug.Trace("SpawnTypeRegional instance destroyed")
	endwhile
	
	RegionPersistentDataStore.Disable()
	RegionPersistentDataStore.Delete()
	RegionPersistentDataStore = None ;De-persist
	
	ThreadController = None
	
	Debug.Trace("Region instance ready for destruction")
	;WorldManager will destory this script instance once returned.

EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------
;MENU FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------------------------------


Function SetPresetVars() ;Parameter value used when custom setting from Menu. Preset Integer should be set first.

	;THIS FUNCTIONS CONTENTS HAS BEEN COMMENTED OUT IN VERSION 0.18.01. BETTER METHODS FOR RESETTING PRESET VALUES ARE BEING TABLED.

	
	;if iCurrentPreset == 1 ;SOTC Preset
	;	iRandomSwarmChance = 5
	;	iRandomRampageChance = 5
	;	iRandomAmbushChance = 5
	;
	;elseif iCurrentPreset == 2 ;WOTC Preset
	;	iRandomSwarmChance = 10
	;	iRandomRampageChance = 5
	;	iRandomAmbushChance = 5
	;
	;elseif iCurrentPreset == 3 ;COTC Preset
	;	iRandomSwarmChance = 10
	;	iRandomRampageChance = 10
	;	iRandomAmbushChance = 10

	;else - WTF value was set?
	;endif

	;Reshuffle Actor lists should be called from the calling function.
	
EndFunction


;This function either sets Menu Globals to current values before viewing a Menu option, or it sets
;the new value selected from said Menu. 
Function SetMenuVars(string asSetting, bool abSetValues = false, Int aiValue01 = 0)

	if asSetting == "RegionPreset"
	
		if abSetValues
			iCurrentPreset = aiValue01
			SetPresetVars()
			ReshuffleActorLists() ;Force reset, user would have been warned in Menu.
		endif
		SOTC_Global01.SetValue(iCurrentPreset as Float)
	
	elseif asSetting == "RegionDifficulty"
		
		if abSetValues
			iCurrentDifficulty = aiValue01
			;This is not a setting affected by Presets, so custom settings flag not enabled
		endif
		SOTC_Global01.SetValue(iCurrentDifficulty as Float)
		
	elseif asSetting == "RegionChance"
		
		if abSetValues
			iRegionSpawnChance = aiValue01
		endif
		SOTC_Global01.SetValue(iRegionSpawnChance as Float)
		
	elseif asSetting == "RegionSwarmChance"
	
		if abSetValues
			iRandomSwarmChance = aiValue01
		endif
		SOTC_Global01.SetValue(iRandomSwarmChance as Float)
		
	elseif asSetting == "RegionRampageChance"
	
		if abSetValues
			iRandomRampageChance = aiValue01
		endif
		SOTC_Global01.SetValue(iRandomRampageChance as Float)
		
	elseif asSetting == "RegionAmbushChance"
	
		if abSetValues
			iRandomAmbushChance = aiValue01
		endif
		SOTC_Global01.SetValue(iRandomAmbushChance as Float)
		
	elseif asSetting == "EzApplyMode"
	
		if abSetValues
			iEzApplyMode = aiValue01
		endif
		SOTC_Global01.SetValue(iEzApplyMode as Float)
	
	elseif asSetting == "EzBorderMode"
		
		if abSetValues
			iEzBorderMode = aiValue01
		endif
		SOTC_Global02.SetValue(iEzBorderMode as Float)

	elseif asSetting == "SpPresetChanceBonus"
	;Global01 is set to selected Preset in Menu. Then here we can play with the real bonus value.
	;This is required as same sub-menu is used for all 3 Preset selections.
		
		Int i = (SOTC_Global01.GetValue()) as Int ;Get the selected Menu Preset stored in Global above.
		if abSetValues
			iSpPresetChanceBonusList[i] = aiValue01
		endif
		SOTC_Global02.SetValue(iSpPresetChanceBonusList[i] as Float)
		
	elseif asSetting == "SpResetClock"
	
		if abSetValues
			fSpResetTimerClock = aiValue01 as Float
		endif
		
		SOTC_Global01.SetValue(fSpResetTimerClock as Float)
		
	endif

EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;SPAWNPOINT FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;Check for a pending event, check preset restriction of calling point.
Bool Function RegionSpawnCheck(SOTC:SpawnPointScript akCallingPoint, Int aiPresetRestriction)
	
	;NOTE - Random events are currently not fully implemented on the Regional level. No code
	;included here for them yet. 
	
	if ((Utility.RandomInt(1,100)) <= iRegionSpawnChance)
		return false ;Green light.
	endif
	
	return true ;Red light.

EndFunction


;Returns bonus chance value to apply to SpawnPoints in this Region, based on current Preset.
Int Function GetRegionSpPresetChanceBonus()

	return iSpPresetChanceBonusList[iCurrentPreset]
	
EndFunction


;Gets a single Travel loc from this Region.
ObjectReference Function GetRandomTravelLoc()

	Int iSize = RegionPersistentDataStore.kTravelLocs.Length - 1
	ObjectReference kLoc = RegionPersistentDataStore.kTravelLocs[(Utility.RandomInt(0,iSize))]
	
	return kLoc
	
EndFunction


;Gets a list of Travel markers within the Region.
ObjectReference[] Function GetRandomTravelLocs(int aiNumLocations)
;Note: It is possible that this function can return the same location (markers) 2 or all 3 times.
;In that event, we don't really care because they'll just sandbox that location, if they get there.

	ObjectReference[] kLocListToSend = new ObjectReference[1]
	Int iSize = RegionPersistentDataStore.kTravelLocs.Length - 1
	
	Int iCounter = 0
	Int i
	
	while iCounter != aiNumLocations
		
		i = Utility.RandomInt(0,iSize)
		kLocListToSend.Add(RegionPersistentDataStore.kTravelLocs[i])
		iCounter += 1
		
	endwhile
	
	if kLocListToSend[0] == None ;Security measure
		kLocListToSend.Remove(0)
	endif
	
	return kLocListToSend
	
EndFunction


;Gets a single random Ez from this script, based on current mode.
EncounterZone Function GetRandomEz()

	EncounterZone[] kEzListToUse
	EncounterZone kEzToReturn

	
	if iEzBorderMode == 0 ;Default mode, uses normal list (enemies don't follow indoors)
	;Assume this mode first, more likely the user will have this mode on
	
		if iCurrentDifficulty < 2 ;0/1 is easy/medium, use "easy" list
			kEzListToUse = RegionPersistentDataStore.kRegionLevelsEasy
			
		else ;Use the harder list, even for Difficulty of 4 (NONE in Bethesdaland)
			kEzListToUse = RegionPersistentDataStore.kRegionLevelsHard
			
		endif
			
	else ;Outright assume == 1, use lists with borders disabled (enemies follow player indoors)
	
		if iCurrentDifficulty < 2 ;0/1 is easy/medium, use "easy" list
			kEzListToUse = RegionPersistentDataStore.kRegionLevelsEasyNoBorders
			
		else ;Use the harder list, even for Difficulty of 4 (NONE in Bethesdaland)
			kEzListToUse = RegionPersistentDataStore.kRegionLevelsHardNoBorders
			
		endif

	endif

	Int iSize = (kEzListToUse.Length) - 1 ;Get actual index count
	kEzToReturn = kEzListToUse[Utility.RandomInt(0, iSize)]

	return kEzToReturn

EndFunction


;Gets a list of random Ezs from this script and returns it, if needed.
EncounterZone[] Function GetRandomEzList(int aiNumEzsRequired)

	EncounterZone[] kEzListToUse
	EncounterZone[] kEzListToReturn = new EncounterZone[1] ;The new list to build and return. Init with one member of None to avoid array errors.
	
	if iEzBorderMode == 0 ;Default mode, uses normal list (enemies don't follow indoors)
	;Assume this mode first, more likely the user will have this mode on
	
		if iCurrentDifficulty < 2 ;0/1 is easy/medium, use "easy" list
			kEzListToUse = RegionPersistentDataStore.kRegionLevelsEasy
			
		else ;Use the harder list, even for Difficulty of 4 (NONE in Bethesdaland)
			kEzListToUse = RegionPersistentDataStore.kRegionLevelsHard
			
		endif
			
	else ;Outright assume == 1, use lists with borders disabled (enemies follow player indoors)
	
		if iCurrentDifficulty < 2 ;0/1 is easy/medium, use "easy" list
			kEzListToUse = RegionPersistentDataStore.kRegionLevelsEasyNoBorders
			
		else ;Use the harder list, even for Difficulty of 4 (NONE in Bethesdaland)
			kEzListToUse = RegionPersistentDataStore.kRegionLevelsHardNoBorders
			
		endif
		
	endif
	
	
	Int iCounter
	Int iSize = (kEzListToUse.Length) - 1
	
	while iCounter < aiNumEzsRequired
	
		kEzListToReturn.Add(kEzListToUse[Utility.RandomInt(0,iSize)], 1)
		iCounter += 1
		
	endwhile
	
	if kEzListToReturn[0] == None ;Security measure
		kEzListToReturn.Remove(0)
	endif
	
	return kEzListToReturn

EndFunction


;Return one of the Regions whole Ez[], based on the current mode/difficulty
;This is used in spawnpoints to point at a list here.
EncounterZone[] Function GetRegionCurrentEzList()

	if iEzBorderMode == 0 ;Default mode, uses normal list (enemies don't follow indoors)
	;Assume this mode first, more likely the user will have this mode on
	
		if iCurrentDifficulty < 2 ;0/1 is easy/medium, use "easy" list
			return RegionPersistentDataStore.kRegionLevelsEasy
			
		else ;Use the harder list, even for Difficulty of 4 (NONE in Bethesdaland)
			return RegionPersistentDataStore.kRegionLevelsHard
			
		endif
			
	else ;Outright assume == 1, use lists with borders disabled (enemies follow player indoors)
	
		if iCurrentDifficulty < 2 ;0/1 is easy/medium, use "easy" list
			return RegionPersistentDataStore.kRegionLevelsEasyNoBorders
			
		else ;Use the harder list, even for Difficulty of 4 (NONE in Bethesdaland)
			return RegionPersistentDataStore.kRegionLevelsHardNoBorders
			
		endif

	endif

EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;FEATURE FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;DEV NOTE: Can be made into a single universal function, however this is easier to read. 


;Random roll for Infestation/Swarm
Bool Function RollForSwarm(Int aiBonus = 1) ;Parameter added in version 0.13.01 for SP bonuses

	if (Utility.RandomInt(aiBonus,100)) <= iRandomSwarmChance
		return true
	else
		return false
	endif

EndFunction

;Random roll for Stampede, following a successful roll for Swarm
Bool Function RollForRampage(Int aiBonus = 1) ;Parameter added in version 0.13.01 for SP bonuses

	if (Utility.RandomInt(aiBonus,100)) <= iRandomRampageChance
		return true
	else
		return false
	endif

EndFunction

;Random roll for Ambush - not the same as an AmbushPoint.
Bool Function RollForAmbush(Int aiBonus = 1) ;Parameter added in version 0.13.01 for SP bonuses

	if (Utility.RandomInt(aiBonus,100)) <= iRandomAmbushChance
		return true
	else
		return false
	endif

EndFunction


;------------------------------------------------------------------------------------------------
