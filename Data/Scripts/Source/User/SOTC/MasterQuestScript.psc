Scriptname SOTC:MasterQuestScript extends Quest Conditional
{ Master script, central to everything }
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
{Primary Properties Group}

	Quest Property SOTC_MasterQuest Auto Const Mandatory
	{ Auto-fills. Link to own Quest }
	
	SOTC:AuxilleryQuestScript Property AuxilleryQuestScript Auto Const Mandatory
	{ Fill with Auxillery Controller Quest. }
	
	SOTC:WorldManagerScript[] Property Worlds Auto Mandatory
	{ Initialise one member with None. Fills dynamically. }

	Holotape Property SOTC_MainMenuTape Auto Const Mandatory
	{ Auto-Fills with MainMenuTape }

	Holotape Property SOTC_AuxMenuTape Auto Const Mandatory
	{ Auto-Fills with AuxMenuTape }

	Actor Property Player Auto Const
	{ Permanent link to Player if/when needed }

EndGroup


Group Dynamic

	SOTC:ThreadControllerScript Property ThreadController Auto
	{ Init None, fills dynamically. }

	SOTC:SpawnTypeMasterScript[] Property SpawnTypeMasters Auto
	{ Initialise one member with None, fills dynamically. Member 0 is the Master Actor List. }
	
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
	
	SOTC:TravelMarkerPersistScript Property TravelMarkerStore Auto
	{ Init None, instanced at runtime. Store all Travel Markers placed in World. }
	
EndGroup


;THIS was deemed unnecessary and removed. Left for reference. Region settings stored on own struct per Region.
;Group PresetStructs
;{Fill out each Preset with balanced values}


;NOTE - I have hardcoded this mod to only ever have 3 major presets. Therefore instead of using
;yet another script to store each "Preset" settings and placing into an array, a function will
;have to be used to get the desired list/struct 

;These properties can be configured by the user. 

	;PresetDetailsStruct[] Property PresetDetails Auto ;All
	;{Master Preset settings structs. Fill with balanced settings for each preset.
	;0 = Unused, Init with 0/None always, 1 = SOTC, 2 = WOTC, 3 = COTC, 4 = CUSTOM, Init with 0/None}

;EndGroup


Group InstanceBaseObjects
{Fill all accordingly}

	ObjectReference Property kMasterCellMarker Auto Const Mandatory
	{ Fill with the Master Marker in the SOTC Master Persistent Cell. }

	MiscObject Property kThreadControllerObject Auto Const Mandatory
	{ Unique }
	
	MiscObject Property kEventMonitorObject Auto Const Mandatory
	{ Unique }
	
	MiscObject Property kTravelMarkerStoreObject Auto Const Mandatory
	{ Unique }
	
	MiscObject Property kSpawnTypeMasterObject Auto Const Mandatory
	{ SpawnTypeMasterScript base objects }
	
	MiscObject[] Property kActorManagerObjects Auto Const Mandatory
	{ ActorManagerScript base objects }
	
	MiscObject[] Property kWorldManagerObjects Auto Const Mandatory
	{ WorldManagerScript base objects }
	
EndGroup
	


Group ModSettings
{ Settings properties. Initialise 0/None/False, set by menu }

	Int Property iMasterSpawnChance = 100 Auto
	{ Default 100, change in Menu. Chance SpawnPoints firing, has massive effect on balance. }

	Int Property iCurrentPreset Auto ; 3 Major presets + 1 User Custom (1-4)

	;LEGEND - PRESETS
	; [1] SOTC ("Spawns of the Commonwealth" default) - Easiest, suit vanilla/passive player.
	; [2] WOTC ("War of the Commonwealth") - Higher chances of spawns and group numbers etc.
	; [3] COTC (Carnage of the Commonwealth") - What it says on the tin. 

	Int Property iCurrentDifficulty Auto ;Same as vanilla (0-4)
	
	;LEGEND - DIFFICULTY LEVELS
	;Same as Vanilla. Only in Bethesda games does None = 4 (value 4 is "No" difficulty, scale to player)
	;Only affects this mod. 
	; 0 - Easy
	; 1 - Medium
	; 2 - Hard
	; 3 - Very Hard ("Veteran" in SOTC)
	; 4 - NONE - Scale to player.

	Bool Property bVanillaMode Auto ;Yay or nay 
	{ Init false. Vanilla mode disables certain SpawnPoints }

	Int Property iEzApplyMode Auto
	{ Initialise with 0. Set in Menu. 0 = None, 1 = 1x Random Ez Per Group, 2 = Per Actor }

	Int Property iEzBorderMode Auto
	{ Initialise with 0. Set in Menu. 1 = Disable Borders. }
	
	Bool Property bAllowPowerArmorGroups Auto
	{ Init false. Set in Menu. Enables/Disables groups with Power Armor units } 

EndGroup


Group MenuStuff
{ Menu specific things }

	Int Property iMenuSettingsMode Auto ;Local version of the Global of the same purpose
	{ Init 0. Set by Menu when needed. }
	
	;LEGEND - MENU SETTINGS MODES
	;Equivalent Global for Menu: SOTC_Global_MenuSettingsMode
	;Use this to determine if menu is in Master mode, Region mode or has pending settings event
	; 0 - MASTER MODE
	; 1 - REGION MODE
	; 5 - FIRST TIME STARTUP MODE
	; 10 - MASTER PRESET/RESET PENDING
	; 11 - MASTER ALL SPAWNTYPES PRESET PENDING
	; 12 - FORCE RESET ALL SPs.
	; 13 - MASTER SINGLE SPAWNTYPE PRESET UPDATE
	; Direct Region + Spawntype Preset are handled from Menu.
	;Pending Events are all designated above a value of 10. Menu will detects this and lock Menu if above 10.

	SOTC:RegionManagerScript Property MenuCurrentRegionScript Auto
	{ Initialise none. Set by menu when needed }

	SOTC:SpawnTypeRegionalScript Property MenuCurrentRegSpawnTypeScript Auto
	{ Initialise none. Set by menu when needed }

	SOTC:ActorManagerScript Property MenuCurrentActorScript Auto
	{ Initialise none. Set by menu when needed }
	
	;The above 3 are required to be Properties for ease of access in Menu. 

EndGroup

;Temp Vars for Menu
Bool bForceResetCustomRegionSettings
Bool bForceResetCustomSpawnTypeSettings
Int iValue01 ;A temp variable that can be used for CustomEvents if needed.
Int iValue02 ;A temp variable that can be used for CustomEvents if needed.
	
;-------------------------------------


Group SettingsGlobals
{ Auto-fill }

	GlobalVariable Property SOTC_MasterGlobal Auto Const Mandatory
	{ Auto-fill. IO status of mod }
	GlobalVariable Property SOTC_Global_MenuSettingsMode Auto Const Mandatory ;Highly reused
	{ Auto-fill }
	GlobalVariable Property SOTC_Global_CurrentMenuWorld Auto Const Mandatory
	{ Auto-fill }
	GlobalVariable Property SOTC_Global_CurrentMenuRegion Auto Const Mandatory ;Highly reused
	{ Auto-fill }
	
	;Generic Variables for promiscuous use in Menu
	;----------------------------------------------
	
	GlobalVariable Property SOTC_Global01 Auto Const Mandatory
	{ Auto-fill }
	GlobalVariable Property SOTC_Global02 Auto Const Mandatory
	{ Auto-fill }
	GlobalVariable Property SOTC_Global03 Auto Const Mandatory
	{ Auto-fill }
	GlobalVariable Property SOTC_Global04 Auto Const Mandatory
	{ Auto-fill }
	GlobalVariable Property SOTC_Global05 Auto Const Mandatory
	{ Auto-fill }
	GlobalVariable Property SOTC_Global06 Auto Const Mandatory
	{ Auto-fill }
	GlobalVariable Property SOTC_Global07 Auto Const Mandatory
	{ Auto-fill }
	GlobalVariable Property SOTC_Global08 Auto Const Mandatory
	{ Auto-fill }
	GlobalVariable Property SOTC_Global09 Auto Const Mandatory
	{ Auto-fill }
	GlobalVariable Property SOTC_Global10 Auto Const Mandatory
	{ Auto-fill }


EndGroup


Group SpawnSettings
{ Settings used in spawn code. Initialise all 0/None/False, set in menu. }

	Int Property iRerollChance Auto
	{ Initialise with 0, set by Menu. Chance of a supported Spawnpoint rolling out another group }

	Int Property iRerollMaxCount Auto
	{ Initialise with 0, set by Menu. Maximum number of times a Reroll can occur }

	Int Property iCommonChance Auto
	{ Initialise with 0, set by Menu. Chance of Common Actor appearing in a Region }

	Int Property iUncommonChance Auto
	{ Initialise with 0, set by Menu. Chance of Common Actor appearing in a Region. Above this, spawns Rare }

EndGroup


;------------------------------
;Master Story Faction Settings
;------------------------------
;NOTE - MAY move to own Quest
;{Master level settings for Story Factions control}

;Bool Property bAllowStoryFactionSpawns Auto Conditional
;{Initialise false. Changing this mid game will cause all Story SpawnType
;dynamic Actor lists to reset}

;Bool Property bAllowInstituteOverride Auto Conditional
;{Initialise false. Override setting for the above setting for Institute only}


;Int Property iFactionStatus_Brotherhood Auto Conditional
;{Initialise 0. Will be set on Mod initialisation. Sets story status of faction}

;Int Property iFactionStatus_Minutemen Auto Conditional
;{Initialise 0. Will be set on Mod initialisation. Sets story status of faction}

;Int Property iFactionStatus_Institute Auto Conditional
;{Initialise 0. Will be set on Mod initialisation. Sets story status of faction}

;Int Property iFactionStatus_Railroad Auto Conditional
;{Initialise 0. Will be set on Mod initialisation. Sets story status of faction}

;Int Property iFactionStatus_Automatron Auto Conditional
;{Initialise 0. Will be set on Mod initialisation. Sets story status of faction}

;Int Property iFactionStatus_Arcadia Auto Conditional
;{Initialise 0. Will be set on Mod initialisation. Sets story status of faction}



Group FeatureSettings
{ Settings for extra features. Most will initialise with 0/None/False etc, set by menu }

	;BUILT-IN FEATURES PROPERTIES
	;-----------------------------

	Int Property iRandomSwarmChance Auto
	{ Initialise 0, set in Menu. If any value above 0, there is a chance of a random Swarm/Infestation }
	;This setting is also defined on a Regional level
	
	Int Property iRandomStampedeChance Auto
	{ Initialise 0, set in Menu. If any value above 0, there is a chance of a random 
	Stampede upon successful Swarm, if the Actor supports this. }
	;This setting is also defined on a Regional level
	
	Int Property iRandomAmbushChance Auto
	{ Initialise 0, set in Menu. If any value above 0, there is a chance of a random infestation }
	;This setting is also defined on a Regional level
	
	;RANDOM EVENTS FRAMEWORK PROPERTIES
	;-----------------------------------
	
	ObjectReference Property kEventPoint Auto 
	{ Init None. Fills with intercepted SpawnPoint to start events at. }
	
	Int Property iEventCooldownTimerClock Auto
	{ Init 300 (5 minutes default). Change from Menu. }
	
	Quest[] Property kRE_BypassEvents Auto Mandatory ;Type 1
	{ Init one member of None. Dynamically fills. Events here can bypass timed locks. }
	
	Quest[] Property kRE_TimedEvents Auto Mandatory ;Type 2
	{ Init one member of None. Active timed events will fill themselves here when ready. }
	
	Quest[] Property kRE_StaticEvents Auto Mandatory ;Type 3
	{ Init one member of None. Dynamically fills. }
	
	Int Property iRE_BypassEventChance Auto
	{ Init 20 by default. Change in Menu. Chance of "Bypass" Random Events firing. }
	
	Int Property iRE_StaticEventChance Auto
	{ Init 20 by default. Change in Menu. Chance of "Static" Random Events firing. }
	
EndGroup

;--------------------------
;Feature Settings Variables
;--------------------------

Bool bEventLockEngaged ;Used to skip/block spawn event checker
Int iEventType ;Set when a Random Event is about to fire. Determines type of Event.

Quest[] kEventQuestsPendingStart ;Used when in Menu mode, tp append and start Event Quests on Menu Mode exit. 

;--------------------------


Bool bInit ;Security check to make sure Init events/functions don't fire again while running
Bool bRegisteredForPipboyClose ;Flag the script if this event is pending. 


;-----------
;Timer IDs
;-----------

;All timers listed here for convenience, whether commented out or in use on this script

;Int iStaggerStartupTimerID = 1 Const  ;Used to randmoise fire up of simultaneous SPs. Realtime
;Featured on standalone SPs. No defined clock, usually set at 0.2-0.5 seconds.

;Int iSpCooldownTimerID = 2 Const  ;Time before a failed SP can fire again. Realtime
;Featured on standalone SPs. Clock property defined on ThreadController

;Int iHelperFireTimerID = 3 Const ;Timer to start Helper point own thread. Realtime
;See SpHelperScript. Has no defined clock, balanced as used

;Int iRegionResetTimerID = 4 Const ;Interval between each Region Reset of all SPs. Per Region. Game Time
;See RegionManagerScript. Clock Property on script

;Int iMasterSpCooldownTimerID = 5 Const ;Performance/balance helper. Time limit before another point can fire.
;Moved to ThreadController. Clock Property on ThreadController

;Int iEventTimerID = 7 Const ;Timer for flagging event as ready, stored on Event scripts

Int iEventCooldownTimerID = 8 Const ;Cooldown timer between allowing Random Events.

Int iEventFireTimerID = 9 Const ;If CheckforEvents = true, starts Event code in own thread.


Group DebugOptions
{Options for displaying debug messages/traces. Initialise 0/None/False, set in menu}

	Bool Property bDebugMessagesEnabled Auto
	{ Initialise false. Set in Menu. }
	
	Bool Property bDebugMessagesEnabledSPsOnly Auto
	{ Initialise false. Set in Menu. }
	
	Bool Property bSpawnWarningEnabled Auto
	{ This one enabled messages to display when a SP fires }
	
EndGroup


;-------------------------
;CUSTOM EVENT DEFINITIONS
;-------------------------

CustomEvent PresetUpdate ;Update sent to Regions and/or Spawntypes for Preset change.
CustomEvent MasterSingleSettingUpdate ;Event to send single settings updates to scripts.
CustomEvent ForceResetAllSps ;Reset all Regions SPs. Does not (re)start timer, safe from Menu, but
;we will force the user to exit menu anyway as it may take some time to complete.
CustomEvent InitTravelMarkers


;------------------------------------------------------------------------------------------------
;INITIALISATION FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

;First time Init
;Event OnQuestInit() ;Will fail if ANYTHING goes wrong at Quest start, i.e failed to fill properties
	
	;INIT NOW DONE IN MANUAL FUNCTION CALLS. 
	
;EndEvent


;Triggered after setting preset for the first time and Pipboy closed
Function PerformFirstTimeSetup(Int aiPresetToSet)

	if !bInit
		
		SetMenuSettingsMode(10)
		Player.Additem(SOTC_MainMenuTape, 1, false) ;We want to know it's been added.

		iCurrentPreset = aiPresetToSet
		
		;Start creating instances
		
		ThreadController = (kMasterCellMarker.PlaceAtMe(kThreadControllerObject, 1 , false, false, false)) as SOTC:ThreadControllerScript
		
		Debug.Trace("ThreadController created on Master")
		
		ObjectReference kNewInstance

		kNewInstance = kMasterCellMarker.PlaceAtMe(kEventMonitorObject, 1 , false, false, false)
		(kNewInstance as SOTC:SettingsEventMonitorScript).PerformFirstTimeSetup(ThreadController)
		
		Debug.Trace("EventMonitor created on ThreadController")
		
		kNewInstance = kMasterCellMarker.PlaceAtMe(kTravelMarkerStoreObject, 1 , false, false, false)
		TravelMarkerStore = (kNewInstance as SOTC:TravelMarkerPersistScript)
		Debug.Trace("TravelMarkerStore created on Master")
		
		;Start SpawnTypeMaster first
		Int iCounter 
		Int iSize = 16
		
		while iCounter < iSize
			
			Debug.Trace("Creating SpawnTypeMaster")
			
			kNewInstance = kMasterCellMarker.PlaceAtMe(kSpawnTypeMasterObject, 1 , false, false, false)
			(kNewInstance as SOTC:SpawnTypeMasterScript).PerformFirstTimeSetup(iCounter)
			
			iCounter += 1
			
		endwhile
		
		
		;Start all ActorManagers
		iCounter = 0
		iSize = kActorManagerObjects.Length
		
		while iCounter < iSize
		
			Debug.Trace("Initialising ActorManager on Master")
		
			kNewInstance = kMasterCellMarker.PlaceAtMe(kActorManagerObjects[iCounter], 1 , false, false, false)
			(kNewInstance as SOTC:ActorManagerScript).PerformFirstTimeSetup(kMasterCellMarker) 
			;This will start all subclasses for the Actor, may take some time.
			
			iCounter += 1
			
		endwhile
		
		;Fill Master Actor Lists
		
		Debug.Trace("Filling Master SpawnType Actor lists")
		FillMasterActorLists()
		Debug.Trace("Master SpawnType Actor lists filled")
		
		
		;Start Worlds & Regions
		iCounter = 0
		iSize = kWorldManagerObjects.Length
		
		while iCounter < iSize
		
			Debug.Trace("Initialising WorldManager")
		
			kNewInstance = kMasterCellMarker.PlaceAtMe(kWorldManagerObjects[iCounter], 1 , false, false, false)
			(kNewInstance as SOTC:WorldManagerScript).PerformFirstTimeSetup(ThreadController, kMasterCellMarker, iCurrentPreset) 
			;This will start corresponding Regions, may take some time
			
			iCounter += 1
			
		endwhile
		
		
		Debug.Trace("Events starting")
		StartPendingEventQuests() ;Will return immediately if no events
		
		;Instancing done, mod is ready.
		
		SOTC_MasterGlobal.SetValue(1.0) ;Officially turned on.
		ClearMenuVars()
		
		Debug.Trace("Sending Init event to Travel markers")
		
		;Notify TravelLoc Markers they can safely add themselves to their Regions now.
		Var[] kArgs = new Var[1]
		Bool b = true
		kArgs[0] = b
		
		SendCustomEvent("InitTravelMarkers", kArgs)
		
		Debug.Trace("Setup Complete")
	
	endif
	
	;Add more work if needed
	
EndFunction


Function FillMasterActorLists()

	Int iCounter = 1 ;Start from Urban spawntype. 0 is Master list.
	
	Int iSize = SpawnTypeMasters[0].ActorList.Length
	SOTC:ActorManagerScript CurrentActor = SpawnTypeMasters[0].ActorList[0] ;Kick it off with first member
	
	;NOTE: Remember that SpawnType 0 is the Main Random List, here we organise everything else.
	
	while iCounter < iSize
		
		AddActorToMasterSpawnTypes(CurrentActor)
		;Decided 2 loops was better. Can use loop function as standalone later.
		
		iCounter += 1
		CurrentActor = SpawnTypeMasters[0].ActorList[iCounter] ;Set the next Actor
		
	endwhile
	
	;Remove all first members of None, to avoid script errors. (Patch 0.09.01)
	iCounter = 0
	iSize = SpawnTypeMasters.Length
	
	while iCounter < iSize
	
		if (SpawnTypeMasters[iCounter].ActorList.Length > 1) && (SpawnTypeMasters[iCounter].ActorList[0] == None)
			SpawnTypeMasters[iCounter].ActorList.Remove(0)
		endif
		
		iCounter += 1
		
	endwhile
	
EndFunction


Function SafelyClearMasterActorLists()

	Int iCounter = 1 ;Start at 1, 0 is MasterList
	Int iSize = SpawnTypeMasters.Length
		
	while iCounter < iSize ;Clear all the lists
		
		SpawnTypeMasters[iCounter].SafelyClearActorList()
		
	endwhile
	
EndFunction


Function ResetMasterActorLists()

	SafelyClearMasterActorLists()
	FillMasterActorLists()
	
EndFunction


;Adds a single ActorManager to all applicable Master Lists
Function AddActorToMasterSpawnTypes(SOTC:ActorManagerScript aActorToAdd)

	Int iCounter
	Bool[] bAddToType = aActorToAdd.bAllowedSpawnTypes
	Int iSize = bAddToType.Length
		
	while iCounter < iSize

		if bAddToType[iCounter]
			SpawnTypeMasters.ActorList.Add(aActorToAdd, 1)
		endif
		
		iCounter += 1
			
	endwhile

EndFunction
	

;------------------------------------------------------------------------------------------------
;TIMER EVENTS
;------------------------------------------------------------------------------------------------

;Timers for various things, including Spawn Events
Event OnTimer(Int aiTimerID)

	if aiTimerID == iEventCooldownTimerClock
		bEventLockEngaged = false
	
	elseif aiTimerID == iEventFireTimerID
	
		if iEventType == 1
			BeginBypassEvent()
		elseif iEventType == 2
			BeginTimedEvent()
		elseif iEventType == 3
			BeginStaticEvent()
		endif
		
	endif

EndEvent


;------------------------------------------------------------------------------------------------
;MASTER SETTINGS FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

;Create a new Var array from PresetDetails struct and send custom event
Function SendMasterMassEvent()

	;DEV NOTE: Do not try to declare Var arrays as a Property, the CK's UI doesn't understand it.

	Var[] PresetParams
	string sPresetType

	if iMenuSettingsMode == 10 ;FULL PRESET
		
		PresetParams = new Var[4]
		sPresetType = "Full"
		
		PresetParams[0] = sPresetType ;The type of Preset change
		PresetParams[1] = bForceResetCustomRegionSettings
		PresetParams[2] = bForceResetCustomSpawnTypeSettings
		PresetParams[3] = iCurrentPreset
		
		ThreadController.PrepareToMonitorEvent("Regions") 
		;String parameter to tell what script type will be receiving the event
		
		SendCustomEvent("PresetUpdate", PresetParams)
		
	elseif iMenuSettingsMode == 11 ;ALL SPAWNTYPES/ACTORS ONLY
		
		PresetParams = new Var[3]
		sPresetType = "Spawntypes"
		
		PresetParams[0] = sPresetType ;The type of Preset change
		PresetParams[1] = bForceResetCustomSpawnTypeSettings
		PresetParams[2] = iValue01
		
		ThreadController.PrepareToMonitorEvent("Regions") 
		;String parameter to tell what script type will be receiving the event		
		
		SendCustomEvent("PresetUpdate", PresetParams)
		
	elseif iMenuSettingsMode == 12 ;FORCE RESET ALL SPAWNPOINTS
		
		ThreadController.PrepareToMonitorEvent("Regions") 
		;String parameter to tell what script type will be receiving the event
		
		SendCustomEvent("ForceResetAllSps")
		
	elseif iMenuSettingsMode == 13 ;SINGLE SPAWNTYPE ONLY
	
		ThreadController.PrepareToMonitorEvent("Regions") 
		;String parameter to tell what script type will be receiving the event
		
		PresetParams = new Var[4]
		sPresetType = "SingleSpawntype"
		
		PresetParams[0] = sPresetType
		PresetParams[1] = iValue01 ;The ID of the Spawntype.
		PresetParams[2] = bForceResetCustomSpawnTypeSettings
		PresetParams[3] = iValue02 ;The Preset to set
		
		SendCustomEvent("PresetUpdate", PresetParams)
		
	endif
	
EndFunction


;Used to send custom single setting changes on the Master level, from the menu directly.
Function SendMasterSingleSettingUpdateEvent(string asSetting, Bool abBool01, Int aiInt01, Float aiFloat01) ;Parameters optional if needed

	;NOTE: Here we use strings for the first Var[] member so that this one event can be universal.
	;Will be received by all scripts that registered, but ignored if it isn't for them.
	;Safe to call directly from Menu. Unsafe functions should be moved to Mass Events.
	
	Var[] SettingParams
	
	if asSetting == "Difficulty"
	
		SettingParams = new Var[2]
		SettingParams[0] = asSetting
		SettingParams[1] = iCurrentDifficulty
		SendCustomEvent("MasterSingleSettingUpdate", SettingParams)
	
	elseif asSetting == "EzApplyMode"
	
		SettingParams = new Var[2]
		SettingParams[0] = asSetting
		SettingParams[1] = iEzApplyMode
		SendCustomEvent("MasterSingleSettingUpdate", SettingParams)
		
	elseif asSetting == "EzBorderMode"
	
		SettingParams = new Var[2]
		SettingParams[0] = asSetting
		SettingParams[1] = iEzBorderMode
		SendCustomEvent("MasterSingleSettingUpdate", SettingParams)
	
	elseif asSetting == "RegionSwarmChance"
	
		SettingParams = new Var[2]
		SettingParams[0] = asSetting
		SettingParams[1] = iRandomSwarmChance
		SendCustomEvent("MasterSingleSettingUpdate", SettingParams)
		
	elseif asSetting == "RegionAmbushChance"
	
		SettingParams = new Var[2]
		SettingParams[0] = asSetting
		SettingParams[1] = iRandomAmbushChance
		SendCustomEvent("MasterSingleSettingUpdate", SettingParams)
		
	elseif asSetting == "SpawnTypesLootEnableDisable"
	
		SettingParams = new Var[2]
		SettingParams[0] = asSetting
		SettingParams[1] = abBool01
		
	endif
	
EndFunction


;Event for issuing the settings changes on Menus close. Used to avoid Menu lockups with latent functions.
Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)

	if (asMenuName == "PipboyMenu") && (!abOpening) ; On Pip-Boy closing
		
		if iMenuSettingsMode > 10 ;All settings events deferred to 10+ at this stage.
		
			SendMasterMassEvent() ;This will "lock" the menu and require player to exit Menu Mode.
		
		endif
		
	endif
	
	;Check if Random Events pending start.
	if kEventQuestsPendingStart[0] != None ;Array is initialized 0, if first member is not none, invoke start.
		StartPendingEventQuests()
	endif
	
	;ClearMenuVars() - Moved to SettingsEventMonitor
	UnregisterForAllMenuOpenCloseEvents()
	
EndEvent


;------------------------------------------------------------------------------------------------
;MENU FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------
;Used for quick setting variables/Globals.

Function RegisterMasterForPipBoyCloseEvent(Int aiValue01, Int aiValue02) ;Register For Pipboy close event. Parameters optional
	
	iValue01 = aiValue01 ;A temp value that can be used by events if needed.
	iValue02 = aiValue02 ;A temp value that can be used by events if needed.
	
	;Pending major settings updates will take place after this event
	if !bRegisteredForPipboyClose ;Security check is intended for other functions rather than this one.
		RegisterForMenuOpenCloseEvent("PipboyMenu")
		bRegisteredForPipboyClose = true ;Prevent unnecessary re-registration. 
	endif

	;NOTE: May disable player controls in future
	
EndFunction


Function SetMenuSettingsMode(int aiMode)
	if iMenuSettingsMode != 5 ;Ensure first time settings mode does not get killed
		iMenuSettingsMode = aiMode ;Local variable that script deals with
		SOTC_Global_MenuSettingsMode.SetValue(aiMode as float) ;Global for the Menu
	endif
EndFunction

;LEGEND - MENU SETTINGS MODES
;Equivalent Global for Menu: SOTC_Global_MenuSettingsMode
;Use this to determine if menu is in Master mode, Region mode or has pending settings event
; 0 - MASTER MODE
; 1 - REGION MODE
; 5 - FIRST TIME SETUP MODE
; 10 - MASTER PRESET/RESET PENDING
; 11 - MASTER ALL SPAWNTYPES PRESET PENDING
; 12 - FORCE RESET ALL SPs.
; 13 - MASTER SINGLE SPAWNTYPE PRESET UPDATE
; Direct Region + Spawntype Preset are handled from Menu.
;Pending Events are all designated above a value of 10. Menu will detect this and lock if so.

Function SetPresetRegionOverrideMode(Bool abMode)
	bForceResetCustomRegionSettings = abMode ;Local variable that script deals with
EndFunction


Function SetPresetSpawnTypeOverrideMode(Bool abMode)
	bForceResetCustomSpawnTypeSettings = abMode ;Local variable that script deals with
EndFunction


;Reset the menu for next use
Function ClearMenuVars() 
	iMenuSettingsMode = 0
	SOTC_Global_MenuSettingsMode.SetValue(0.0)
	bForceResetCustomRegionSettings = false
	bForceResetCustomSpawnTypeSettings = false
	SOTC_Global_CurrentMenuWorld.SetValue(0.0)
	SOTC_Global_CurrentMenuRegion.SetValue(0.0)
EndFunction


;------------------------------------------------------------------------------------------------
;CHANCE FUNCTIONS
;------------------------------------------------------------------------------------------------

;If a normal Spawn, this will return an Int between 1-3, corresponding to rarity
;Rarity levels are Common, Uncommon and Rare.
Int Function RollForRarity()

	Int i = Utility.RandomInt(1,100)
	
	if i <= iCommonChance
		return 1
	elseif i <= iUncommonChance
		return 2
	else  ;Failing the above, must be Rare. If not an Int, must be bad CPU :D
		return 3
	endif
	
	;Example how this works: Common = 75, Uncommon = 95
	;Therefore Common has 75% chance, Uncommon has 20% chance, Rare has 5%

EndFunction


;Used by Multipoints to get the total number of groups to spawn.
Int Function RollGroupsToSpawnCount(int aiMaxCount)
	
	int iNumGroupsToSpawn = 1 ;This must at least be one, or no spawn! Guarantee the first Group.
	int i = Utility.RandomInt(1,100) ;First dice roll
	
	while (i <= iRerollChance) && (iNumGroupsToSpawn < iRerollMaxCount) && (iNumGroupsToSpawn < aiMaxCount)
	;in English - while Dice roll says yes, reroll count doesn't exceed max setting and max requested
		iNumGroupsToSpawn += 1 ;Increment the count on success
		i = Utility.RandomInt(1,100) ;Roll dice again
	endwhile
	
	return iNumGroupsToSpawn

EndFunction


;------------------------------------------------------------------------------------------------
;SPAWN FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

Bool Function MasterSpawnCheck(ObjectReference akCallingPoint, Bool abAllowVanilla)

	if CheckForBypassEvents() ;Check for any events not subject to EventLock
		return true ;deny the calling point
	endif
	
	;Check all pending events if they have been flagged. This is done in priority order
	if (!bEventLockEngaged) && (akCallingPoint is SOTC:SpGroupScript) ;Only main points can have events.
	
		if CheckForEvents()
			return true ;deny the calling point
		endif
	
	endif
	
	;Vanilla Mode check
	
	if (!abAllowVanilla) && (bVanillaMode) && ((Utility.RandomInt(1,100)) < iMasterSpawnChance)
		return true ;Denied due to vanilla mode
	endif
	
	;If we got this far than all good, SP can proceed, optionally displaying a debug message
	if bSpawnWarningEnabled
		ShowSpawnWarning()
	endif
	
	return false ;Proceed
	
EndFunction


;Show a random, passive debug message iumpying a SpawnPoint has fired nearby.
Function ShowSpawnWarning()

	Int i = Utility.RandomInt(1,3)
	
	if i == 1
		Debug.Notification("You hear movement in the distance")
	elseif i == 2
		Debug.Notification("You suddenly get the feeling things are about to go south")
	elseif i ==3
		Debug.Notification("You feel danger drawing near")
	endif
	
EndFunction


;------------------------------------------------------------------------------------------------
;RANDOM EVENTS FRAMEWORK FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------


Bool Function CheckForBypassEvents() ;Check for any events not subject to EventLock

	if (kRE_BypassEvents[0] != None) && Utility.RandomInt(0,100) <= iRE_BypassEventChance
		iEventType = 1
		return true
	else
		return false
	endif

EndFunction


Function BeginBypassEvent()

	int iSize = (kRE_BypassEvents.Length) - 1 ;Get actual index count
	;Select a random member and set the Begin stage
	kRE_BypassEvents[(Utility.RandomInt(0,iSize))].SetStage(10)
	;That's all folks!
	
EndFunction


Bool Function CheckForEvents()
	
	;Check for recurring timed event first
	if kRE_TimedEvents[0] != None
		iEventType = 2
		StartTimer(1, iEventFireTimerID) ;Starts event code in own thread
		return true
	endif
	
	;Failing the above, roll for a static event
	if (kRE_StaticEvents[0] != None) && (Utility.RandomInt(0,100) <= iRE_StaticEventChance)
		iEventType = 3
		StartTimer(1, iEventFireTimerID) ;Starts event code in own thread
		return true
	endif
	
	;Otherwise
	return false

EndFunction


Function BeginTimedEvent()

	kRE_TimedEvents[0].SetStage(10) ;Standard Begin stage
	kRE_TimedEvents.Remove(0) ;Remove from the array, allow next event to come forward (if any)
	;NOTE: If the Event fails to fire due to some check on implemented on the Event code, it will/
	;should be reinserted at index 0. 
	
	;Start the cooldown Timer before new event can fire.
	StartTimer(iEventCooldownTimerClock, iEventCooldownTimerID)
	bEventLockEngaged = true ;Lock it up.
	
EndFunction


Function BeginStaticEvent()

	int iSize = (kRE_StaticEvents.Length) - 1 ;Get actual index count
	;Select a random member and set the Begin stage
	kRE_StaticEvents[(Utility.RandomInt(0,iSize))].SetStage(10)
	;NOTE - If this event fails to fire due to some check implemented on the Event code, nothing happens.
	
	;Start the cooldown Timer before new event can fire.
	StartTimer(iEventCooldownTimerClock, iEventCooldownTimerID)
	bEventLockEngaged = true ;Lock it up.

EndFunction


;Append a new custom event to be started and added. Event Quests will be started when Menu mode is exited.
Function AppendEventQuest(Quest akEventQuest)
	
	if kEventQuestsPendingStart == None ;Ensure the array is actually initialised
		kEventQuestsPendingStart = new Quest[1] ;Ensure one member to avoid erroneous size return etc
	endif

	if kEventQuestsPendingStart[0] != None ;Security measure to avoid errors.
		kEventQuestsPendingStart.Add(akEventQuest)
	else ;First member is still none due to list empty
		kEventQuestsPendingStart[0] = akEventQuest
	endif
	
	;Will start the Event Quest safely out of Menu Mode
	if !bRegisteredForPipboyClose
		RegisterForMenuOpenCloseEvent("PipboyMenu")
		bRegisteredForPipboyClose = true ;Prevent unnecessary re-registration. 
	endif
	
EndFunction


Function StartPendingEventQuests()

	if kEventQuestsPendingStart == None ;Security measure ensures array is initialised (will do if not and return immediately)
		kEventQuestsPendingStart = new Quest[1]
		Debug.Trace("Pending new Events array was uninitialised and reset. Function returned, new array size is now: " +kEventQuestsPendingStart.Length)
		return
	endif

	if kEventQuestsPendingStart[0] != None ;Security measure, if there is items in here this should not be None.

		Int iSize = kEventQuestsPendingStart.Length
		Int iCounter
		
		while iCounter < iSize
		
			kEventQuestsPendingStart[iCounter].Start()
			iCounter += 1
			
		endwhile
		
	endif
	
	kEventQuestsPendingStart.Clear()
	kEventQuestsPendingStart = new Quest[1] ;Ensure one member to avoid erroneous size return etc
	Debug.Trace("New Events started successfully. Array reset, size now: " +kEventQuestsPendingStart.Length)
	
EndFunction


;New Event Quests being started for the first time or timed events firing/appending should use this function.
Function SafelyRegisterActiveEvent(string asEventType, Quest akEventQuest)

	;DEV NOTE: Event Arrays should always be kept initialised, with at least one member of None.
	
	if asEventType == "Bypass" ;Add a new Bypass Event active Event list

		if kRE_BypassEvents[0] != None ;First member is still none due to list empty
			kRE_BypassEvents.Add(akEventQuest)
		else 
			kRE_BypassEvents[0] = akEventQuest
		endif
		
	endif
	
	
	if asEventType == "Timed" ;Add a new Bypass Event active Event list

		if kRE_TimedEvents[0] != None
			kRE_TimedEvents.Add(akEventQuest)
		else ;First member is still none due to list empty
			kRE_TimedEvents[0] = akEventQuest
		endif
		
	endif
	
	
	if asEventType == "Static" ;Add a new Bypass Event active Event list

		if kRE_StaticEvents[0] != None
			kRE_StaticEvents.Add(akEventQuest)
		else ;First member is still none due to list empty
			kRE_StaticEvents[0] = akEventQuest
		endif
		
	endif

EndFunction


;------------------------------------------------------------------------------------------------
