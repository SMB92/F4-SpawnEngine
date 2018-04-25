Scriptname SOTC:RegionQuestScript extends Quest
{ Used for each Region in a World. Holds all specific properties for the Region }
;Written by SMB92
;Special thanks to J. Ostrus [BigandFlabby] for code contributions that made this mod possible.

;LEGEND - PREFIX CONVENTION
; Variables and Properties are treated the same. Script types do not have prefixes, unless they
;are explicitly received as function arguments and are multi-instance scripts.
; "a" - (Function/Event Blocks only) Variable was received as function argument OR the variable
;was created from a passed-in Struct/Var[] member
; "k" - Is an "Object" as usual, whether created in a Block or defined in the empty state/a state.
; "f,b,i" - The usual Primitives: Float, Bool, Int.

;------------------------------------------------------------------------------------------------
;PROPERTIES & IMPORTS
;------------------------------------------------------------------------------------------------

import SOTC:Struct_RegionPresetDetails

Group PrimaryProperties
{ Primary Properties Group }

	SOTC:MasterQuestScript Property MasterScript Auto Const
	{ Fill with MasterQuest }
	
	SOTC:ThreadControllerScript Property ThreadController Auto Const
	{ Fill with ThreadController Alias }

	SOTC:RegionTrackerScript Property CleanupManager Auto
	{ Initialise with one member of None. WIll dynamically fill upon Init }

	SOTC:SpawnTypeRegionalScript[] Property SpawnTypes Auto
	{ Initialise with one member of None. WIll dynamically fill upon Init }

	Int Property iWorldID Auto Const
	{ Initialise with ID No. of World this Regions intended for }
	;LEGEND - WORLD IDs
	; [0] - COMMONWEALTH
	; [1] - FAR HARBOR
	; [2] - NUKA WORLD

	Int Property iRegionID Auto Const
	{ Initialise with Region No. in World }
	
	RegionPresetDetailsStruct[] Property PresetDetails Auto

EndGroup


Group ObjectInventory
{ All In-world objects such as Spawnpoints and Travel Locs here }

	ObjectReference[] Property kTravelLocs Auto
	{ Fill with all "Travel Location" Xmarkers placed in world }

	ObjectReference[] Property kSpawnPoints Auto ;May not be necessary, or even can be moved to tracking script
	{ Fill with all SpawnPoints placed in Region (not MiniPoints) }

	ObjectReference[] Property kMiniPoints Auto ;May not be necessary, or can move to tracking script
	{ Fill with all MiniPoints, if any, in this Region }
	
	ObjectReference[] Property kPatrolPoints Auto ;May not be necessary, or can move to tracking script
	{ Fill with all PatrolPoints, if any, in this Region }

EndGroup


Group EncounterZoneProperties
{EZ Properties and settings for this Region}

	EncounterZone[] Property kRegionLevelsEasy Auto Const
	{ Fill with custom EZs to suit this Region/Difficulty }

	EncounterZone[] Property kRegionLevelsHard Auto Const
	{ Fill with custom EZs to suit this Region/Difficulty }

	EncounterZone[] Property kRegionLevelsEasyNoBorders Auto Const
	{ Fill with custom EZs to suit this Region/Difficulty }

	EncounterZone[] Property kRegionLevelsHardNoBorders Auto Const
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

	Bool Property bRegionEnabled Auto ;On/Off switch for this Region
	{ Initialise with 0. Set by Menu }

	Int Property iCurrentPreset Auto
	{ Initialise with 0. Set by Menu }

	Int Property iCurrentDifficulty Auto
	{ Initialise with 0. Set by Menu }
	;LEGEND - DIFFICULTY LEVELS
	;Same as Vanilla. Only in Bethesda games does None = 4 (value 4 is "No" difficulty, scale to player)
	; 0 - Easy
	; 1 - Medium
	; 2 - Hard
	; 3 - Very Hard ("Veteran" in SOTC)
	; 4 - NONE - Scale to player.
	
	Bool Property bCustomSettingsActive Auto
	{ Init False. Set by Menu when custom settings have been applied }

EndGroup


Group FeatureSettings
{ Settings for various features supported on the Regional level }

	Int Property iRandomSwarmChance Auto
	{ Initialise 0, set in Menu. If any value above 0, there is a chance of a random infestation }
	
	Int Property iRandomAmbushChance Auto
	{ Initialise 0, set in Menu. If any value above 0, there is a chance of a random infestation }

EndGroup


;Timers

;Moved to CleanupManager for now
;Int iRegionResetTimerID = 2 Const ;Does not need to be a Property
;Int Property iRegionResetTimerClock Auto
;{Initialise 0. Clock for Area Reset. Fills with settings from Master/Menu}
Float fTrackerWaitClock ;Wait timer based on Init order. Staggers the startup of the Trackers
;cleanup timer, in an attempt to prevent all Regions cleanup timers for firing simultaneously.


;Temp Variables
;---------------
Bool bInit ;Security check to make sure Init events don't fire again while running
;NOTE - Random events are currently not fully implemented on the Regional level.
Bool bEventThreadLockEngaged ;Used to skip/block spawn event checker
ObjectReference bEventPoint ;When an event fires, this will set with the intercepted calling point



;------------------------------------------------------------------------------------------------
;INITIALISATION & SETTINGS EVENTS
;------------------------------------------------------------------------------------------------

Event OnQuestInit()
	
	if !bInit
		MasterScript.Worlds[iWorldID].Regions.Insert(Self, iRegionID) ;Add self to Master array
		RegisterForCustomEvent(MasterScript, "PresetUpdate")
		RegisterForCustomEvent(MasterScript, "ForceResetAllSps")
		RegisterForCustomEvent(MasterScript, "MasterSingleSettingUpdate")
		fTrackerWaitClock = ThreadController.IncrementActiveRegionsCount(1) as float
		bInit = true
	endif
	
EndEvent


Event SOTC:MasterQuestScript.PresetUpdate(SOTC:MasterQuestScript akSender, Var[] akArgs)

	;Var[] PresetParams = new Var[0]
	;PresetParams = akArgs as Var[] ;Cast to copy locally, save threads - MAY NOT BE NECESSARY
	;Commented out until clarified

	if (akArgs[0] as string) == "Full"
	
		if (!bCustomSettingsActive) || (akArgs[1] as Bool) ;If not Custom or Override = true

			Bool bEnabled ;Disable the Region if ON, and prepare to turn back ON later
		
			if bRegionEnabled == true
				bRegionEnabled = false ;Turn off this Region temporarily (denies Spawnpoints)
				bEnabled = true
			endif
			;This shouldn't take so long as to affect SPs but we do this to be sure.
	
			iCurrentPreset = akArgs[3] as Int
			ReshuffleActorLists(akArgs[2] as Bool) ;(akArgs[2]) - bool to reset custom spawntype settings
			
			bRegionEnabled = bEnabled ;Leave off or turn back on
		else
		;Do Nothing
		endif
	
	elseif (akArgs[0] as string) == "SpawnTypes"
	
		Bool bEnabled ;Disable the Region if ON, and prepare to turn back ON later
		
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
	
	endif
	
	ThreadController.iEventFlagCount += 1 ;Flag as complete

EndEvent


Event SOTC:MasterQuestScript.MasterSingleSettingUpdate(SOTC:MasterQuestScript akSender, Var[] akArgs)

	if (akArgs[0] as string) == "RegionSwarmChance"
	
		iRandomSwarmChance = akArgs[1] as Int
		
	elseif (akArgs[0] as string) == "RegionAmbushChance"
	
		iRandomAmbushChance = akArgs[1] as Int
		
	elseif (akArgs[0] as string) == "SpawnTypesLootEnableDisable"
	
		EnableDisableSpawnTypesLoot(akArgs[1] as Bool)
		
	endif
	
	;Currently only supports those two settings.
	;No need for iEventFlagCount for these events.
	
EndEvent


Event SOTC:MasterQuestScript.ForceResetAllSps(SOTC:MasterQuestScript akSender, Var[] akArgs)

	;This event does not require user to exit Menu mode as it will not restart timers.
	CleanupManager.ResetSpentPoints()
	ThreadController.iEventFlagCount += 1 ;Flag as complete

EndEvent


;For the tracker to get the stagger timer. 
Float Function GetTrackerWaitClock()

	return fTrackerWaitClock
	
EndFunction
	

;This function SERIALIZES reshuffle of Spawntype Actor Lists
Function ReshuffleActorLists(Bool abForceReset)

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
	if aiPreset == 4 ;Check if it was Custom
		bCustomSettingsActive = true ;4th preset is the custom user defined.
	else
		bCustomSettingsActive = false ;Overridden with normal Preset now.
	endif
	
	ReshuffleActorLists(abForceResetSpawnTypes)
	
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
	
	;NOTE - Random events are currently not fully implemented on the Regional level.
	
	if !bRegionEnabled
		return false ;Red light.
	endif
	
	return true ;Green light.

EndFunction


;Gets a list of Travel markers within the Region.
ObjectReference[] Function GetRandomTravelLocs(int aiNumLocations)
;Sends 3 random locations in an array to SpawnPoint for Actor group to travel to.
;Note: It is possible that this function can return the same location (markers) 2 or all 3 times.
;In that event, we don't really care because they'll just sandbox the location if they get there.

	ObjectReference[] kLocListToSend = new ObjectReference[0]
	Int iSize = kTravelLocs.Length - 1
	
	Int iCounter = 0
	Int i
	
	while iCounter != aiNumLocations
		
		i = Utility.RandomInt(0,iSize)
		kLocListToSend.Add(kTravelLocs[i])
		iCounter += 1
		
	endwhile
	
	return kLocListToSend
	
EndFunction


;Gets a single random Ez from this script, based on current mode.
EncounterZone Function GetRandomEz()

	EncounterZone[] kEzListToUse ;went this direction for ease of reading
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

	
	Int iSize = (kEzListToUse.Length) - 1
	kEzToReturn = kEzListToUse[Utility.RandomInt(0, iSize)]

	return kEzToReturn

EndFunction


;Gets a list of random Ezs from this script and returns it
;UNUSED in Main Spawnpoint script, exists if needed
EncounterZone[] Function GetRandomEzList(int aiNumEzsRequired)

	EncounterZone[] kEzListToUse ;went this direction for ease of reading
	EncounterZone[] kEzListToReturn = new EncounterZone[0] ;The new list to build and return
	
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

;Random roll for Ambush - not the same as an AmbushPoint.
Bool Function RollForAmbush()

	if (Utility.RandomInt(1,100)) < iRandomAmbushChance
		return true
	else
		return false
	endif

EndFunction


;------------------------------------------------------------------------------------------------
;UNUSED/OBSOLETE FUNCTIONS
;------------------------------------------------------------------------------------------------

;Pull random ActorQuestScript from SpawnType script and return
;Moved directly to SpawnTypeRegionalScript
;ActorQuestScript Function GetRandomActor(int iSpawnType)
;
;	return SpawnTypes[iSpawnType].GetRandomActor ;May move this call direct to SpawnPoint
;	
;EndFunction
;
;
;Pull multiple ActorQuestScripts from SpawnType script and return array
;Moved directly to SpawnTypeRegionalScript
;ActorQuestScript[] Function GetMultipleRandomActors(int iSpawnType, int iActorCount)
;
;	ActorQuestScript[] ActorsToReturn = new ActorQuestScript[0] ;Init a temp array
;	
;	int iCounter = 0
;	while iCounter < iActorCount
;		ActorToReturn.Add((SpawnTypes[iSpawnType].GetRandomActor)) ;Add new member
;	endwhile
;	
;	return ActorsToReturn ;Return the list
;	
;EndFunction

;------------------------------------------------------------------------------------------------

