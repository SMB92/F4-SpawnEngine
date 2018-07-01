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

	MiscObject Property kTrackerObject Auto Const
	{ Fill with base MiscObject for the Tracker for this Region. Instanced at runtime. }
	
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
	
	SOTC:RegionTrackerScript Property CleanupManager Auto
	{ Initialise with one member of None. Fills dynamically. }

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
	
	ObjectReference[] Property kTravelLocs Auto
	{ Init one member of None, will fill dynamically at runtime. }
	
EndGroup


Group EncounterZoneProperties
{EZ Properties and settings for this Region}

	EncounterZone[] Property kRegionLevelsEasy Auto
	{ Init with one member of None. Fills from Formlist on WorldManager. }

	EncounterZone[] Property kRegionLevelsHard Auto
	{ Init with one member of None. Fills from Formlist on WorldManager. }

	EncounterZone[] Property kRegionLevelsEasyNoBorders Auto
	{ Init with one member of None. Fills from Formlist on WorldManager. }

	EncounterZone[] Property kRegionLevelsHardNoBorders Auto
	{ Init with one member of None. Fills from Formlist on WorldManager. }

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
	
	Bool Property bCustomSettingsActive Auto
	{ Init False. Flagged by Menu when custom settings have been applied. }

EndGroup


Group FeatureSettings
{ Settings for various features supported on the Regional level. }

	Int[] Property iSpPresetChanceBonusList Auto ;Can be modified from Menu
	{ Members 1-3 (0 ignored) can be set from Menu to apply a bonus "chance to fire" percent value to all SpawnPoints in the Region.
Init 4 members with default values of 0 = 0, 1 = 0, 2 = 5, 3 = 10.	}

	Int Property iRandomSwarmChance Auto
	{ Initialise 0, set in Menu. If any value above 0, there is a chance of a random swarm/infestation. }
	
	Int Property iRandomRampageChance Auto
	{ Initialise 0, set in Menu. Can only occur during a successful Swarm/Infestation, and if Actor
supports this mode. If any value above 0, there is a chance of a stampede. }
	
	Int Property iRandomAmbushChance Auto
	{ Initialise 0, set in Menu. If any value above 0, there is a chance of a random swarm/infestation. }

EndGroup


;Timers

Float fTrackerWaitClock ;Wait timer based on Init order. Staggers the startup of the Trackers
;cleanup timer, in an attempt to prevent all Regions cleanup timers from firing simultaneously.

Int iTravelLocInitWaitTimerID = 1 Const ;Timer for cleaning TravelLocs array after Init.


;Temp Variables
;---------------

Bool bInit ;Security check to make sure Init events/functions don't fire again while running

;NOTE - Random events are currently not fully implemented on the Regional level.
Bool bEventThreadLockEngaged ;Used to skip/block spawn event checker
ObjectReference kEventPoint ;When an event fires, this will set with the intercepted calling point


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;INITIALISATION FUNCTIONS & EVENTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;DEV NOTE: Init events/functions now handled by Masters creating the instances.

Function PerformFirstTimeSetup(SOTC:WorldManagerScript aWorldManager, SOTC:ThreadControllerScript aThreadController, \
ObjectReference akMasterMarker, Int aiWorldID, Int aiRegionID, Int aiPresetToSet, \
Formlist akEzEasyList, Formlist akEzHardList, Formlist akEzEasyNBList, Formlist akEzHardNBList) ;Added Ez Transfer fucntions in 0.11.01
	
	if !bInit
		
		ThreadController = aThreadController
		iWorldID = aiWorldID
		iRegionID = aiRegionID
		iCurrentPreset = aiPresetToSet
		SetPresetVars()
		aWorldManager.Regions[iRegionID] = Self ;Only needs to access it once
		
		RegisterForCustomEvent(MasterScript, "PresetUpdate")
		RegisterForCustomEvent(MasterScript, "ForceResetAllSps")
		RegisterForCustomEvent(MasterScript, "MasterSingleSettingUpdate")
		RegisterForCustomEvent(MasterScript, "InitTravelLocs") 
		
		;This timer attempots to stagger the start of Cleanup timers, in attempt to have each Region perform
		;Cleanup a different times (trying to avoid all at once)
		fTrackerWaitClock = (ThreadController.IncrementActiveRegionsCount(1)) * 1.2 as float
		
		;Create local EncounterZone lists
		TransferEzFormlistToArray(akEzEasyList, kRegionLevelsEasy)
		TransferEzFormlistToArray(akEzHardList, kRegionLevelsHard)
		TransferEzFormlistToArray(akEzEasyNBList, kRegionLevelsEasyNoBorders)
		TransferEzFormlistToArray(akEzHardNBList, kRegionLevelsHardNoBorders)
		
		Debug.Trace("Region Prepped, creating subclasses now")
		
		;This function returns the current count of Regions, so we can use this for our stagger timer.
		CleanupManager = (akMasterMarker.PlaceAtMe(kTrackerObject, 1 , false, false, false)) as SOTC:RegionTrackerScript
		CleanupManager.PerformFirstTimeSetup(Self, fTrackerWaitClock)
		
		;Create instances of spawntype objectreferences and set them up
		ObjectReference kNewInstance
		Int iCounter
		Int iSize = 16 ;Need to figure out more intuitive way, currently hard set to number of default.
		
		while iCounter < iSize
		
			Debug.Trace("Creating SpawnTypeRegional manager on Region")
		
			kNewInstance = akMasterMarker.PlaceAtMe(kSpawnTypeObject, 1 , false, false, false)
			(kNewInstance as SOTC:SpawnTypeRegionalScript).PerformFirstTimeSetup(Self, iRegionID, iWorldID, \
			ThreadController, iCounter, iCurrentPreset)
			
			iCounter += 1
			
		endwhile
		
		bInit = true
		
		Debug.Trace("Region creation complete")
		
	endif

EndFunction


;Transfer Formlist of EZs stored on WOrldManager to local arrays on instantiation. Added in ver. 0.11.01
Function TransferEzFormlistToArray(Formlist akEzFormlist, EncounterZone[] akEzArray)

	int iCounter
	Int iSize = akEzFormlist.GetSize() ;Indexing 0 based just like arrays.
	akEzArray = new EncounterZone[iSize] ;Initialise same size as Formlist, members set not added
	
	while iCounter < iSize
	
		akEzArray[iCounter] = (akEzFormlist.GetAt(iCounter)) as EncounterZone ;Cast to actual type
		iCounter += 1
		
	endwhile
	
	Debug.Trace("EncounterZone formlist successfully transferred to local array")

EndFunction


Event SOTC:MasterQuestScript.PresetUpdate(SOTC:MasterQuestScript akSender, Var[] akArgs)

	Bool bEnabled ;Disable the Region if ON, and prepare to turn back ON later
	
	if (akArgs[0] as string) == "Full"
	
		if (!bCustomSettingsActive) || (akArgs[1] as Bool) ;If not Custom or Override (akArgs[1]) = true
		
			iCurrentPreset = akArgs[3] as Int
			SetPresetVars()
			ReshuffleActorLists(akArgs[2] as Bool) ;(akArgs[2]) - bool to reset custom spawntype settings
			;DEV NOTE: Calling this function will safely reinitialise the arrays, no work need be done here.
			
		else
		;Do Nothing
		endif
	
	elseif (akArgs[0] as string) == "SpawnTypes"
		
		Int iChance = iRegionSpawnChance ;Store this value til done
		iRegionSpawnChance = 0 ;Stops all Spawns for now
		;This shouldn't take so long as to affect SPs but we do this to be sure.
	
		Int iActualPreset = iCurrentPreset ;Store the actual preset for now as a workaround/kludge.
		iCurrentPreset = akArgs[2] as Int ;And just set the intended preset for Spawntypes until loop done.
		ReshuffleActorLists(akArgs[1] as Bool) ;(akArgs[2]) - bool to reset custom spawntype settings.
		iCurrentPreset = iActualPreset ;Restore the Region's preset.
			
		iRegionSpawnChance = iChance ;return to original value
		
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
	
	if (akArgs[0] as string) == "Difficulty"
	
		iCurrentDifficulty = akArgs[1] as Int
	
	elseif (akArgs[0] as string) == "EzApplyMode"
	
		iEzApplyMode = akArgs[1] as Int

	elseif (akArgs[0] as string) == "EzBorderMode"
	
		iEzBorderMode = akArgs[1] as Int

	elseif (akArgs[0] as string) == "RegionSwarmChance"
	
		iRandomSwarmChance = akArgs[1] as Int
		bCustomSettingsActive = true
		
	elseif (akArgs[0] as string) == "RegionRampageChance"
	
		iRandomRampageChance = akArgs[1] as Int
		bCustomSettingsActive = true
		
	elseif (akArgs[0] as string) == "RegionAmbushChance"
	
		iRandomAmbushChance = akArgs[1] as Int
		bCustomSettingsActive = true
	
	endif
	
	;No need for iEventFlagCount for these events.
	
EndEvent


Event SOTC:MasterQuestScript.ForceResetAllSps(SOTC:MasterQuestScript akSender, Var[] akArgs)

	;This event does not require the user to exit Menu mode as it will not restart timers.
	CleanupManager.ResetSpentPoints()
	ThreadController.iEventFlagCount += 1 ;Flag as complete

EndEvent


;This script receives this Event as it waits some time, enough for Markers to finish adding
;themselves everywhere, and then cleans up the first Member of None on that array.
Event SOTC:MasterQuestScript.InitTravelLocs(SOTC:MasterQuestScript akSender, Var[] akArgs)

	if (akArgs as Bool) == True ;Initialise, add to RegionManager
	
		StartTimer(10, iTravelLocInitWaitTimerID)
		
	endif
	
EndEvent


Event OnTimer(Int aiTimerID)

	if aiTimerID == iTravelLocInitWaitTimerID
	
		if kTravelLocs[0] == None
			kTravelLocs.Remove(0)
			;Clean off the remianing None member on first index
			Debug.Trace("A Region initialised its kTavelLocs array")
		endif
		
	endif
	
EndEvent


;For the tracker to get the stagger timer. 
Float Function GetTrackerWaitClock()

	return fTrackerWaitClock 
	;Doesn't need to be an Property IMO but it might be faster if it was.
	
EndFunction
	

;This function SERIALIZES reshuffle of Spawntype Actor Lists. Should be safe to run in Menu mode.
Function ReshuffleActorLists(Bool abForceReset) ;All Spawntypes attached.

	Int iChance = iRegionSpawnChance ;Store this value til done
	iRegionSpawnChance = 0 ;Stops all Spawns for now
	;This shouldn't take so long as to affect SPs but we do this to be sure.

	int iCounter = 0
	int iSize = SpawnTypes.Length
	
	while iCounter < iSize
	
		Spawntypes[iCounter].ReshuffleDynActorLists(abForceReset, iCurrentPreset)
		;If SpawnType is running custom settings, will return immediately if parameter is False.
		
	endwhile
	
	iRegionSpawnChance = iChance ;return to original value
	
EndFunction


;Fully cleans up all dynamically produced data in preparation for destruction of this instance.
Function MasterFactoryReset()
	
	Int iCounter
	Int iSize = SpawnTypes.Length
	
	;First we will cleanup all SPs and kill the tracker instance
	CleanupManager.MasterFactoryReset()
	CleanupManager.Disable()
	CleanupManager.Delete()
	CleanupManager = None ;De-persist
	
	;Clear TravelLocs array
	kTravelLocs.Clear()
	
	;Now we will destroy all the SPawnTypeRegional instances
	while iCounter < iSize
		SpawnTypes[iCounter].MasterFactoryReset()
		SpawnTypes[iCounter].Disable()
		SpawnTypes[iCounter].Delete()
		SpawnTypes[iCounter] = None ;De-persist
		iCounter += 1
		Debug.Trace("SpawnTypeRegional instance destroyed")
	endwhile
	
	ThreadController = None
	
	Debug.Trace("Region instance ready for destruction")
	;WorldManager will destory this script instance once returned.

EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------
;MENU FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;As of version 0.13.01, this sets preset values for various settings instead of using the old struct
;method (previously stored struct of settings in an array with the index matching presets ID's). This
;is used for both Master Events and Menu direct setting of presets. iCurrentPreset must be set first.
;Setting from Menu will flag bCustomSettingsActive as true. Presets are hard coded.
Function SetPresetVars(Bool abSetCustomFlag = false) ;Parameter value used when custom setting from Menu.

	bCustomSettingsActive = abSetCustomFlag
	
	if iCurrentPreset == 1 ;SOTC Preset
		iRegionSpawnChance = 75
		iRandomSwarmChance = 5
		iRandomRampageChance = 5
		iRandomAmbushChance = 5
	
	elseif iCurrentPreset == 2 ;WOTC Preset
		iRegionSpawnChance = 85
		iRandomSwarmChance = 10
		iRandomRampageChance = 15
		iRandomAmbushChance = 10
	
	elseif iCurrentPreset == 3 ;COTC Preset
		iRegionSpawnChance = 100
		iRandomSwarmChance = 20
		iRandomRampageChance = 25
		iRandomAmbushChance = 15

	;else - WTF value was set?
	endif

	;Reshuffle Actor lists needs to be called from the calling function.
	
EndFunction


;This function either sets Menu Globals to current values before viewing a Menu option, or it sets
;the new value selected from said Menu. 
Function SetMenuVars(string asSetting, bool abSetValues = false, Int aiValue01 = 0)

	if asSetting == "RegionPreset"
	
		if abSetValues
			iCurrentPreset = aiValue01
			SetPresetVars(true)
			ReshuffleActorLists(true) ;Force reset, user would have been warned in Menu.
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
			bCustomSettingsActive = true
		endif
		SOTC_Global01.SetValue(iRegionSpawnChance as Float)
		
	elseif asSetting == "RegionSwarmChance"
	
		if abSetValues
			iRandomSwarmChance = aiValue01
			bCustomSettingsActive = true
		endif
		SOTC_Global01.SetValue(iRandomSwarmChance as Float)
		
	elseif asSetting == "RegionRampageChance"
	
		if abSetValues
			iRandomRampageChance = aiValue01
			bCustomSettingsActive = true
		endif
		SOTC_Global01.SetValue(iRandomRampageChance as Float)
		
	elseif asSetting == "RegionAmbushChance"
	
		if abSetValues
			iRandomAmbushChance = aiValue01
			bCustomSettingsActive = true
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
		
		Int i = (SOTC_Global01.GetValue()) as Int ;Get the selected Menu Preset stored in Global above.
		if abSetValues
			iSpPresetChanceBonusList[i] = aiValue01
		endif
		SOTC_Global02.SetValue(iSpPresetChanceBonusList[i] as Float)
		
	endif

EndFunction


Function MenuForceResetRegionSPs()
	
	;NOTE: This function will not restart the Cleanup timer, therefore it is safe to use from Menu.
	CleanupManager.ResetSpentPoints()
	
EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;SPAWNPOINT FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;Check for a pending event, check preset restriction of calling point.
Bool Function RegionSpawnCheck(ObjectReference akCallingPoint, Int aiPresetRestriction)
	
	;NOTE - Random events are currently not fully implemented on the Regional level. No code iSize
	;included here for them yet. 
	
	if ((Utility.RandomInt(1,100)) <= iRegionSpawnChance)
		return true ;Green light.
	endif
	
	return false ;Red light.

EndFunction


;Returns bonus chance value to apply to SpawnPoints in this Region, based on current Preset.
Int Function GetRegionSpPresetChanceBonus()

	return iSpPresetChanceBonusList[iCurrentPreset]
	
EndFunction


;Gets a single Travel loc from this Region.
ObjectReference Function GetRandomTravelLoc()

	Int iSize = kTravelLocs.Length - 1
	ObjectReference kLoc = kTravelLocs[(Utility.RandomInt(0,iSize))]
	
	return kLoc
	
EndFunction


;Gets a list of Travel markers within the Region.
ObjectReference[] Function GetRandomTravelLocs(int aiNumLocations)
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


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;FEATURE FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

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
