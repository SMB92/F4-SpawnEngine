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

;------------------------------------------------------------------------------------------------
;PROPERTIES & IMPORTS
;------------------------------------------------------------------------------------------------

Group Primary
{ Primary Properties Group }

	SOTC:MasterQuestScript Property MasterScript Auto Const Mandatory
	{ Fill with MasterQuest. }

	MiscObject Property kTrackerObject Auto Const
	{ Fill with base MiscObject for the Tracker for this Region. Instanced at runtime. }
	
	MiscObject Property kSpawnTypeObject Auto Const
	{ Fill with base MiscObject containing the SpawnTypeRegionalScript. }
	;DEV NOTE: Only STR's with a BaseClassID need unique base objects, the rest of the members can be the same base object
	
	FormList[] Property kSpawnTypeRegLootLists Auto Const Mandatory
	{ Fill with each Regular loot list for each SpawnType, in order. Will be passed to corresponding instance per member. }
	
	FormList[] Property kSpawnTypeBossLootLists Auto Const Mandatory
	{ Fill with each Boss loot list for each SpawnType, in order. Will be passed to corresponding instance per member. }
	;as they will be setup with all other data required data from here.

EndGroup


Group Dynamic

	SOTC:ThreadControllerScript Property ThreadController Auto
	{ Init None. Fills dynamically. }
	
	SOTC:RegionTrackerScript Property CleanupManager Auto
	{ Initialise with one member of None. Fills dynamically. }

	SOTC:SpawnTypeRegionalScript[] Property SpawnTypes Auto
	{ Initialise with one member of None. Fills dynamically. }
	
	Int Property iWorldID Auto
	{ Init 0, filled at runtime. }
	;LEGEND - WORLD IDs
	; [0] - COMMONWEALTH
	; [1] - FAR HARBOR
	; [2] - NUKA WORLD

	Int Property iRegionID Auto
	{ Init 0, filled at runtime.. }
	
	ObjectReference[] Property kTravelLocs Auto
	{ Init one member of None, will fill dynamically at runtime. }
	
EndGroup


Group EncounterZoneProperties
{EZ Properties and settings for this Region}

	EncounterZone[] Property kRegionLevelsEasy Auto
	{ Fill with custom EZs to suit this Region/Difficulty }

	EncounterZone[] Property kRegionLevelsHard Auto
	{ Fill with custom EZs to suit this Region/Difficulty }

	EncounterZone[] Property kRegionLevelsEasyNoBorders Auto
	{ Fill with custom EZs to suit this Region/Difficulty }

	EncounterZone[] Property kRegionLevelsHardNoBorders Auto
	{ Fill with custom EZs to suit this Region/Difficulty }

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

	Bool Property bRegionEnabled Auto Mandatory ;On/Off switch for this Region
	{ Initialise true. Set in Menu. Disables the mod in this Region if set false. }
	
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
	
	Bool Property bCustomSettingsActive Auto
	{ Init False. Flagged by Menu when custom settings have been applied. }

EndGroup


Group FeatureSettings
{ Settings for various features supported on the Regional level. }

	Int Property iRandomSwarmChance Auto
	{ Initialise 20, set in Menu. If any value above 0, there is a chance of a random swarm/infestation. }
	
	Int Property iRandomStampedeChance Auto
	{ Initialise 10, set in Menu. Can only occur during a successful Swarm/Infestation, and if Actor
supports this mode. If any value above 0, there is a chance of a stampede. }
	
	Int Property iRandomAmbushChance Auto
	{ Initialise 5, set in Menu. If any value above 0, there is a chance of a random swarm/infestation. }

EndGroup


;Timers

Float fTrackerWaitClock ;Wait timer based on Init order. Staggers the startup of the Trackers
;cleanup timer, in an attempt to prevent all Regions cleanup timers from firing simultaneously.


;Temp Variables
;---------------

Bool bInit ;Security check to make sure Init events/functions don't fire again while running
;NOTE - Random events are currently not fully implemented on the Regional level.

Bool bEventThreadLockEngaged ;Used to skip/block spawn event checker
ObjectReference kEventPoint ;When an event fires, this will set with the intercepted calling point


;------------------------------------------------------------------------------------------------
;INITIALISATION & SETTINGS EVENTS
;------------------------------------------------------------------------------------------------

;DEV NOTE: Init events/functions now handled by Masters creating the instances.

Function PerformFirstTimeSetup(SOTC:WorldManagerScript aWorldManager, SOTC:ThreadControllerScript aThreadController, \
ObjectReference akMasterMarker, Int aiWorldID, Int aiRegionID, Int aiPresetToSet)
	
	if !bInit
		
		ThreadController = aThreadController
		iWorldID = aiWorldID
		iRegionID = aiRegionID
		iCurrentPreset = aiPresetToSet
		aWorldManager.Regions[iRegionID] = Self ;Only needs to access it once
		
		RegisterForCustomEvent(MasterScript, "PresetUpdate")
		RegisterForCustomEvent(MasterScript, "ForceResetAllSps")
		RegisterForCustomEvent(MasterScript, "MasterSingleSettingUpdate")
		
		ObjectReference kNewInstance
		
		;Create tracker first
		fTrackerWaitClock = (ThreadController.IncrementActiveRegionsCount(1)) * 1.2 as float
		
		Debug.Trace("Region +iRegionID on World +iWorldID Prepped")
		
		;This function returns the current count of Regions, so we can use this for our stagger timer.
		kNewInstance = akMasterMarker.PlaceAtMe(kTrackerObject, 1 , false, false, false)
		(kNewInstance as SOTC:RegionTrackerScript).PerformFirstTimeSetup(Self, fTrackerWaitClock)
		
		;Create instances of spawntype objectreferences and set them up
		Int iCounter
		Int iSize = 16 ;Need to figure out more intuitive way, currently hard set to number of default.
		
		while iCounter < iSize
		
			Debug.Trace("Creating SpawnTypeRegional manager +iCounter on Region +iRegionID on World +iWorldID")
		
			kNewInstance = akMasterMarker.PlaceAtMe(kSpawnTypeObject, 1 , false, false, false)
			(kNewInstance as SOTC:SpawnTypeRegionalScript).PerformFirstTimeSetup(Self, iRegionID, iWorldID, \
			ThreadController, iCounter, kSpawnTypeRegLootLists[iCounter], kSpawnTypeBossLootLists[iCounter], iCurrentPreset)
			
			iCounter += 1
			
		endwhile
		
		bInit = true
		
		Debug.Trace("Region +iRegionID on World +iWorldID creation complete")
		
	endif
	
	
EndFunction


Event SOTC:MasterQuestScript.PresetUpdate(SOTC:MasterQuestScript akSender, Var[] akArgs)

	Bool bEnabled ;Disable the Region if ON, and prepare to turn back ON later
	
	if (akArgs[0] as string) == "Full"
	
		if (!bCustomSettingsActive) || (akArgs[1] as Bool) ;If not Custom or Override = true
		
			if bRegionEnabled == true
				bRegionEnabled = false ;Turn off this Region temporarily (denies Spawnpoints)
				bEnabled = true
			endif
			;This shouldn't take so long as to affect SPs but we do this to be sure.
	
			iCurrentPreset = akArgs[3] as Int
			ReshuffleActorLists(akArgs[2] as Bool) ;(akArgs[2]) - bool to reset custom spawntype settings
			;DEV NOTE: Calling this function will safely reinitialise the arrays, no work need be done here.
			
			bRegionEnabled = bEnabled ;Leave off or turn back on
		else
		;Do Nothing
		endif
	
	elseif (akArgs[0] as string) == "SpawnTypes"
		
		if bRegionEnabled == true
			bRegionEnabled = false ;Turn off this Region temporarily (denies Spawnpoints)
			bEnabled = true
		endif
		;This shouldn't take so long as to affect SPs but we do this to be sure.
	
		Int iActualPreset = iCurrentPreset ;Store the actual preset for now as a workaround/kludge.
		iCurrentPreset = akArgs[2] as Int ;And just set the intended preset for Spawntypes until loop done.
		ReshuffleActorLists(akArgs[1] as Bool) ;(akArgs[2]) - bool to reset custom spawntype settings.
		iCurrentPreset = iActualPreset ;Restore the Region's preset.
			
		bRegionEnabled = bEnabled ;Leave off or turn back on
		
	elseif (akArgs[0] as string) == "SingleSpawntype"

		;Not worth temp disabling for this one. 
		
		bEnabled = SpawnTypes[(akArgs[1] as Int)].bSpawntypeEnabled ;Remember this
		SpawnTypes[(akArgs[1] as Int)].bSpawntypeEnabled = false ;Temp disable if not already
		SpawnTypes[(akArgs[1] as Int)].ReshuffleDynActorLists(akArgs[2] as Bool, akArgs[3] as Int)
		;(akArgs[2]) = Custom settings override flag
		;(akArgs[3]) = Preset to Set
		SpawnTypes[(akArgs[1] as Int)].bSpawntypeEnabled = bEnabled ;Set back to what it was.

	endif
	
	ThreadController.iEventFlagCount += 1 ;Flag as complete

EndEvent


Event SOTC:MasterQuestScript.MasterSingleSettingUpdate(SOTC:MasterQuestScript akSender, Var[] akArgs)

	if (akArgs[0] as string) == "EzApplyMode"
	
		iEzApplyMode = akArgs[1] as Int

	elseif (akArgs[0] as string) == "EzBorderMode"
	
		iEzBorderMode = akArgs[1] as Int

	elseif (akArgs[0] as string) == "RegionSwarmChance"
	
		iRandomSwarmChance = akArgs[1] as Int
		
	elseif (akArgs[0] as string) == "RegionStampedeChance"
	
		iRandomStampedeChance = akArgs[1] as Int
		
	elseif (akArgs[0] as string) == "RegionAmbushChance"
	
		iRandomAmbushChance = akArgs[1] as Int
		
	elseif (akArgs[0] as string) == "SpawnTypesLootEnableDisable"
	
		EnableDisableSpawnTypesLoot(akArgs[1] as Bool)
		
	endif
	
	;No need for iEventFlagCount for these events.
	
EndEvent


Event SOTC:MasterQuestScript.ForceResetAllSps(SOTC:MasterQuestScript akSender, Var[] akArgs)

	;This event does not require the user to exit Menu mode as it will not restart timers.
	CleanupManager.ResetSpentPoints()
	ThreadController.iEventFlagCount += 1 ;Flag as complete

EndEvent


;For the tracker to get the stagger timer. 
Float Function GetTrackerWaitClock()

	return fTrackerWaitClock 
	;Doesn't need to be an Property IMO but it might be faster if it was.
	
EndFunction
	

;This function SERIALIZES reshuffle of Spawntype Actor Lists. Should be safe to run in Menu mode.
Function ReshuffleActorLists(Bool abForceReset) ;All Spawntypes attached.

	Bool bEnabled
	
	if bRegionEnabled == true ;Just like the event block, we'll shut off if needed.
		bRegionEnabled = false 
		bEnabled = true
	endif
	;This shouldn't take so long as to affect SPs but we do this to be sure.

	int iCounter = 0
	int iSize = SpawnTypes.Length
	
	while iCounter < iSize
	
		Spawntypes[iCounter].ReshuffleDynActorLists(abForceReset, iCurrentPreset)
		;If SpawnType is running custom settings, will return immediately if parameter is False.
		
	endwhile
	
	bRegionEnabled = bEnabled ;And turn back on if necessary
	
EndFunction


;Enable or disable the Loot systems for all attached Spawntypes
Function EnableDisableSpawnTypesLoot(Bool abEnable)

	Int iCounter
	Int iSize = SpawnTypes.Length
	
	while iCounter < iSize
	
		SpawnTypes[iCounter].bLootSystemEnabled = abEnable
		iCounter += 1
		
	endwhile
	
EndFunction


;Set a preset directly from Menu. This does not start any timers and is safe to set without exiting Menu.
Function MenuSetPreset(Int aiPreset, Bool abForceResetSpawnTypes)

	;NOTE: Menu will warn if Region is running custom settings and ask before Overwriting so no check here.
	
	iCurrentPreset = aiPreset ;Set the Preset Int
	if aiPreset == 4 ;Check if it was set as Custom now.
		bCustomSettingsActive = true ;4th preset is the custom user defined.
	else
		bCustomSettingsActive = false ;Overridden with normal Preset now.
	endif
	
	ReshuffleActorLists(abForceResetSpawnTypes) ;Optionally forcing reset despite any custom settings.
	
EndFunction


;Force Reset SPs in this Region from Menu
Function MenuForceResetRegion()
	
	;NOTE: This function will not restart the Cleanup timer, therefore it is safe to use from Menu.
	CleanupManager.ResetSpentPoints()
	
EndFunction


;------------------------------------------------------------------------------------------------
;SPAWNPOINT FUNCTIONS
;------------------------------------------------------------------------------------------------

;Check for a pending event, check preset restriction of calling point.
Bool Function RegionSpawnCheck(ObjectReference akCallingPoint, Int aiPresetRestriction)
	
	;NOTE - Random events are currently not fully implemented on the Regional level. No code iSize
	;included here for them yet. 
	
	if !bRegionEnabled && ((Utility.RandomInt(1,100)) < iRegionSpawnChance)
		return true ;Red light.
	endif
	
	return false ;Green light.

EndFunction


;Gets a list of Travel markers within the Region.
ObjectReference[] Function GetRandomTravelLocs(int aiNumLocations)
;Sends 3 random locations in an array to SpawnPoint for Actor group to travel to.
;Note: It is possible that this function can return the same location (markers) 2 or all 3 times.
;In that event, we don't really care because they'll just sandbox that location, if they get there.

	ObjectReference[] kLocListToSend = new ObjectReference[1]
	Int iSize = kTravelLocs.Length - 1
	
	Int iCounter = 0
	Int i
	
	while iCounter != aiNumLocations
		
		i = Utility.RandomInt(0,iSize)
		kLocListToSend.Add(kTravelLocs[i])
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
			kEzListToUse = kRegionLevelsEasy
			
		else ;Use the harder list, even for Difficulty of 4 (NONE in Bethesdaland)
			kEzListToUse = kRegionLevelsHard
			
		endif
			
	else ;Outright assume == 1, use lists with borders disabled (enemies follow player indoors)
	
		if iCurrentDifficulty < 2 ;0/1 is easy/medium, use "easy" list
			kEzListToUse = kRegionLevelsEasyNoBorders
			
		else ;Use the harder list, even for Difficulty of 4 (NONE in Bethesdaland)
			kEzListToUse = kRegionLevelsHardNoBorders
			
		endif

	endif

	Int iSize = (kEzListToUse.Length) - 1 ;Get actual index count
	kEzToReturn = kEzListToUse[Utility.RandomInt(0, iSize)]

	return kEzToReturn

EndFunction


;Gets a list of random Ezs from this script and returns it, if needed.
EncounterZone[] Function GetRandomEzList(int aiNumEzsRequired)

	EncounterZone[] kEzListToUse
	EncounterZone[] kEzListToReturn = new EncounterZone[1] ;The new list to build and return
	
	if iEzBorderMode == 0 ;Default mode, uses normal list (enemies don't follow indoors)
	;Assume this mode first, more likely the user will have this mode on
	
		if iCurrentDifficulty < 2 ;0/1 is easy/medium, use "easy" list
			kEzListToUse = kRegionLevelsEasy
			
		else ;Use the harder list, even for Difficulty of 4 (NONE in Bethesdaland)
			kEzListToUse = kRegionLevelsHard
			
		endif
			
	else ;Outright assume == 1, use lists with borders disabled (enemies follow player indoors)
	
		if iCurrentDifficulty < 2 ;0/1 is easy/medium, use "easy" list
			kEzListToUse = kRegionLevelsEasyNoBorders
			
		else ;Use the harder list, even for Difficulty of 4 (NONE in Bethesdaland)
			kEzListToUse = kRegionLevelsHardNoBorders
			
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
			return kRegionLevelsEasy
			
		else ;Use the harder list, even for Difficulty of 4 (NONE in Bethesdaland)
			return kRegionLevelsHard
			
		endif
			
	else ;Outright assume == 1, use lists with borders disabled (enemies follow player indoors)
	
		if iCurrentDifficulty < 2 ;0/1 is easy/medium, use "easy" list
			return kRegionLevelsEasyNoBorders
			
		else ;Use the harder list, even for Difficulty of 4 (NONE in Bethesdaland)
			return kRegionLevelsHardNoBorders
			
		endif

	endif

EndFunction


;------------------------------------------------------------------------------------------------
;FEATURE FUNCTIONS
;------------------------------------------------------------------------------------------------

;Random roll for Infestation/Swarm
Bool Function RollForSwarm()

	if (Utility.RandomInt(1,100)) < iRandomSwarmChance
		return true
	else
		return false
	endif

EndFunction

;Random roll for Stampede, following a successful roll for Swarm
Bool Function RollForStampede()

	if (Utility.RandomInt(1,100)) < iRandomStampedeChance
		return true
	else
		return false
	endif

EndFunction

;Random roll for Ambush - not the same as an AmbushPoint.
Bool Function RollForAmbush()

	if (Utility.RandomInt(1,100)) < iRandomAmbushChance
		return true
	else
		return false
	endif

EndFunction


;------------------------------------------------------------------------------------------------