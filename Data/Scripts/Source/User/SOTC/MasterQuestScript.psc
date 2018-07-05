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

;DEV NOTE ON DYNAMIC ARRAY INITIALISATION:
;Over the course of development, I have found at times when initialising an array with 0 members,
;the array seems to get trashed by the engine (maybe after so much time passes?) and this leads to
;errors due to working with a "None Array" (i.e, adding/inserting logs an error that array is None).
;From 0.10.01 forward, all arrays are initialised with 1 member of None, and either after work has
; been done/array initialised, that member is removed, or items are set on that index directly. Any
;Function that has the prefix "Safely" generally means security code for arrays concerning this issue. 

;-------------------------------------------------------------------------------------------------------------------------------------------------------
;PROPERTIES & IMPORTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

Group Primary

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

	Actor Property PlayerRef Auto Const
	{ Permanent link to Player if/when needed }

EndGroup


Group Dynamic

	SOTC:ThreadControllerScript Property ThreadController Auto
	{ Init None, fills dynamically. }

	SOTC:SpawnTypeMasterScript[] Property SpawnTypeMasters Auto
	{ Initialise one member with None, fills dynamically. Member 0 is the Master Actor List. Set Size to initialise in Init function below. }
	
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
	; [14] - RAMPAGE (CLASS-BASED) - Stores all Actors that support Rampage feature.
	
	;NOTE: See "CLASSES VS SPAWNTYPES" commentary of the SpawnTypeMasterScript for more in-depth info
	
	;No longer instanced as of version 0.13.01
	;SOTC:PointPersistScript Property PointPersistStore Auto
	;{ Init None, instanced at runtime. Store all Travel Markers placed in World. }
	
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

	ObjectReference Property kMasterCellMarker Auto Const Mandatory
	{ Fill with the Master Marker in the SOTC Master Persistent Cell. }

	MiscObject Property kThreadControllerObject Auto Const Mandatory
	{ Unique }
	
	MiscObject Property kSpawnTypeMasterObject Auto Const Mandatory
	{ SpawnTypeMasterScript base objects }
	
	MiscObject[] Property kActorManagerObjects Auto Const Mandatory
	{ ActorManagerScript base objects }
	
	MiscObject[] Property kWorldManagerObjects Auto Const Mandatory
	{ WorldManagerScript base objects }
	
EndGroup
	


Group ModSettings

	Int Property iMasterSpawnChance = 100 Auto
	{ Default 100, change in Menu. Chance SpawnPoints firing, has massive effect on balance. }

	Int Property iCurrentPreset Auto Conditional ; 3 Major presets + 1 User Custom (1-4)

	;LEGEND - PRESETS
	; [1] SOTC ("Spawns of the Commonwealth" default) - Easiest, suit vanilla/passive player.
	; [2] WOTC ("War of the Commonwealth") - Higher chances of spawns and group numbers etc.
	; [3] COTC (Carnage of the Commonwealth") - What it says on the tin. 

	Int Property iCurrentDifficulty Auto Conditional ;Same as vanilla (0-4)
	
	;LEGEND - DIFFICULTY LEVELS
	;Same as Vanilla. Only in Bethesda games does None = 4 (value 4 is "No" difficulty, scale to player)
	;Only affects this mod. 
	; 0 - Easy
	; 1 - Medium
	; 2 - Hard
	; 3 - Very Hard ("Veteran" in SOTC)
	; 4 - NONE - Scale to player.

	Bool Property bVanillaMode = true Auto ;Yay or nay 
	{ Default value is TRUE. Change in Menu. Vanilla mode disables certain SpawnPoints. }

	Int Property iEzApplyMode Auto
	{ Initialise with 0. Set in Menu. 0 = None, 1 = 1x Random Ez Per Group, 2 = Per Actor }

	Int Property iEzBorderMode Auto
	{ Initialise with 0. Set in Menu. 1 = Disable Borders. }
	
	Bool Property bAllowPowerArmorGroups Auto
	{ Init false. Set in Menu. Enables/Disables groups with Power Armor units }

EndGroup


Group MenuStuff

	Int Property iMenuSettingsMode Auto ;Local version of the Global of the same purpose
	{ Init 0. Set by Menu when needed. }
	
	;LEGEND - MENU SETTINGS MODES
	;Equivalent Global for Menu: SOTC_Global_MenuSettingsMode
	;Use this to determine if menu is in Master mode, Region mode or has pending settings event
	; 0 - MASTER MODE
	; 1 - REGION MODE
	; 10 - MASTER PRESET/RESET PENDING
	; 11 - MASTER ALL SPAWNTYPES PRESET PENDING
	; 12 - FORCE RESET ALL SPs AND TIMERS. Currently not implemented as of version 0.13.01
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
	GlobalVariable Property SOTC_Global_CurrentMenuRegion Auto Const Mandatory
	{ Auto-fill }
	GlobalVariable Property SOTC_Global_RegionCount Auto Const Mandatory
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
	;Below is not needed at this time, and may never be. 
	;GlobalVariable Property SOTC_Global06 Auto Const Mandatory
	;{ Auto-fill }
	;GlobalVariable Property SOTC_Global07 Auto Const Mandatory
	;{ Auto-fill }
	;GlobalVariable Property SOTC_Global08 Auto Const Mandatory
	;{ Auto-fill }
	;GlobalVariable Property SOTC_Global09 Auto Const Mandatory
	;{ Auto-fill }
	;GlobalVariable Property SOTC_Global10 Auto Const Mandatory
	;{ Auto-fill }


EndGroup


;----------------------------------------
;Rarity Chances Preset Struct Definition
;----------------------------------------

;Rarity chances can only be defined on the Master level, no need to put in separate script for importing.
Struct RarityChancesPresetStruct

Int iCommonChance
Int iUncommonChance
;These values should be balanced so they equal less than 100 when added together, as the remainder serves as Rare Chance.

EndStruct

;----------------------------------------


Group SpawnSettings

	Int Property iRerollChance Auto
	{ Default value of 25, change in Menu. Chance of a MultiPoint rolling out another group. }

	Int Property iRerollMaxCount Auto
	{ Default value of 2, change in Menu. Maximum number of times a MultiPoint Reroll can occur. }
	
	RarityChancesPresetStruct[] Property RarityChancePresets Auto Const
	{ Fill each members struct with balanced values for Rarity chances. }

	Int Property iCommonActorChance Auto
	{ Default value of 60 (preset 4), change in Menu. Chance of Common Actor appearing in a Region. }

	Int Property iUncommonActorChance Auto
	{ Default value of 30 (preset 4), change in Menu. Chance of Uncommon Actor appearing in a Region. Above this, spawns Rare. }
	
	Int[] Property iSpPresetBonusChance Auto
	{ Members 1-3 (0 ignored) can be set from Menu to apply a bonus "chance to fire" percent value to all SpawnPoints in the Region.
Init 4 members with default values of 0 = 0, 1 = 0, 2 = 5, 3 = 10.	}

EndGroup

Int iCurrentRarityChancePreset = 3 ;Local storage of the last value selected from Menu. Default Preset = 3 (60/30/10).


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
	{ Initialise 0, set in Menu. If any value above 0, there is a chance of a random Swarm/Infestation, if the spawning Actor supports this. }
	;This setting is also defined on a Regional level
	
	Int Property iRandomRampageChance Auto
	{ Initialise 0, set in Menu. If any value above 0, there is a chance of a random Rampage/Stampede, if the spawning Actor supports this. }
	;This setting is also defined on a Regional level
	
	Int Property iRandomAmbushChance Auto
	{ Initialise 0, set in Menu. If any value above 0, there is a chance of a random Ambush, 
where all spawned Actors in a group will immediately rush for the Player. }
	;This setting is also defined on a Regional level
	
	;RANDOM EVENTS FRAMEWORK PROPERTIES
	;-----------------------------------
	
	SOTC:SpawnPointScript Property kEventPoint Auto 
	{ Init None. Fills with intercepted SpawnPoint to start events at. }
	
	Float Property fEventCooldownTimerClock = 300.0 Auto
	{ Default value of 300.0 (5 minutes). Change from Menu. }
	
	Quest[] Property kRE_BypassEvents Auto Mandatory ;Type 1
	{ Init one member of None. Dynamically fills. Events here can bypass timed locks. }
	
	Quest[] Property kRE_TimedEvents Auto Mandatory ;Type 2
	{ Init one member of None. Active timed events will fill themselves here when ready. }
	
	Quest[] Property kRE_StaticEvents Auto Mandatory ;Type 3
	{ Init one member of None. Dynamically fills. }
	
	Int Property iRE_BypassEventChance = 20 Auto
	{ Default value of 20. Change in Menu. Chance of "Bypass" Random Events firing. }
	
	;Timed events do not have chance to occur values. 
	
	Int Property iRE_StaticEventChance = 20 Auto
	{ Default value of 20. Change in Menu. Chance of "Static" Random Events firing. }
	
EndGroup

;--------------------------
;Feature Settings Variables
;--------------------------

Bool bEventLockEngaged ;Used to skip/block spawn event checker
Int iEventType ;Set when a Random Event is about to fire. Determines type of Event.

Quest[] kEventQuestsPendingStart ;Used when in Menu mode, tp append and start Event Quests on Menu Mode exit.
Quest[] kActiveEventQuests ;Used to keep a central database of active EventQuests, for uninstallation etc. 

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

;Int iEventCleanupTimerID = 10 Const ; Despawn timer for Random Events Framework SpawnPoints. 


Group DebugOptions
	
	Bool Property bSpawnWarningEnabled Auto
	{ This one enable a random, ambiguous, message to display when an SP fires. }
	
EndGroup


;-------------------------
;CUSTOM EVENT DEFINITIONS
;-------------------------

CustomEvent PresetUpdate ;Update sent to Regions and/or Spawntypes for Preset change.
CustomEvent MasterSingleSettingUpdate ;Event to send single settings updates to scripts.
CustomEvent ForceResetAllSpsAndTimers ;Reset all Regions SPs AND Timers. Not menu safe, currently not implemented (version 0.13.03). 
CustomEvent ForceResetAllSps ;Reset all Regions SPs. Does not (re)start timer, safe from Menu, but
;we will force the user to exit menu anyway as it may take some time to complete.
CustomEvent InitTravelLocs


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;INITIALISATION FUNCTIONS & EVENTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;First time Init
;Event OnQuestInit() ;Will fail if ANYTHING goes wrong at Quest start, i.e failed to fill properties
	
	;INIT NOW DONE IN MANUAL FUNCTION CALLS. 
	
;EndEvent


;Triggered after setting preset for the first time and Pipboy closed
Function PerformFirstTimeSetup(Int aiPresetToSet)

	if !bInit
		
		SetMenuSettingsMode(10)

		iCurrentPreset = aiPresetToSet
		
		;Start creating instances, starting with ThreadController. 
		
		ThreadController = (kMasterCellMarker.PlaceAtMe(kThreadControllerObject, 1 , false, false, false)) as SOTC:ThreadControllerScript
		
		Debug.Trace("ThreadController created on Master")
		
		ObjectReference kNewInstance
		
		
		;Start SpawnTypeMasters first
		Int iCounter 
		Int iSize = 15 ;Set to number of SpawnTypes supported. Currently 15 as of version 0.14.01
		
		while iCounter < iSize
			
			Debug.Trace("Creating SpawnTypeMaster")
			
			kNewInstance = kMasterCellMarker.PlaceAtMe(kSpawnTypeMasterObject, 1 , false, false, false)
			(kNewInstance as SOTC:SpawnTypeMasterScript).PerformFirstTimeSetup(iCounter)
			
			iCounter += 1
			
		endwhile
		
		Debug.Trace("All STMs created, size now: " +SpawnTypeMasters.Length)
		
		
		;Start all ActorManagers
		iCounter = 0
		iSize = kActorManagerObjects.Length
		SpawnTypeMasters[0].InitMasterActorList(iSize) ;Initialise the Master ActorList to exact amount of Actors available (0.12.01)
		Debug.Trace("Initialised Master ActorList, instancing ActorManagers now")		
		
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
		
		
		;DEV NOTE: As of version 0.14.01, Event Quests are now Start Enabled and stages used to send work
		;Events to this script.
		;Debug.Trace("Events starting")
		;SafelyStartPendingEventQuests() ;Will return immediately if no events
		
		
		;Instancing done, mod is ready.
		
		SOTC_MasterGlobal.SetValue(1.0) ;Officially turned on.
		ClearMenuVars()
		
		Debug.Trace("Sending Init event to Travel markers")
		
		;Notify TravelLoc Markers they can safely add themselves to their Regions now.
		Var[] kArgs = new Var[1]
		Bool b = true
		kArgs[0] = b
		
		SendCustomEvent("InitTravelLocs", kArgs)
		Utility.Wait(7.0) ;Wait 12 seconds for that event to complete (eeach region waits 10 seconds for all Travel Locs to self add). 
		
		PlayerRef.Additem(SOTC_MainMenuTape, 1, false) ;We want to know it's been added.
		
		Debug.Trace("Setup Complete")
	
	endif
	
	;Add more work if needed
	
EndFunction


Function FillMasterActorLists()

	Int iCounter
	
	;Ensure first member on ST Master is not None, for whatever reason, such as not being done before this was called. 
	if SpawnTypeMasters[0].ActorList[0] == None
		SpawnTypeMasters[0].ActorList.Remove(0)
	endif
	
	SOTC:ActorManagerScript CurrentActor = SpawnTypeMasters[0].ActorList[0] ;Kick it off with first member
	Int iSize = SpawnTypeMasters[0].ActorList.Length
	
	;NOTE: Remember that SpawnType 0 is the Main Random List, here we organise everything else.
	
	while iCounter < iSize
		
		AddActorToMasterSpawnTypes(CurrentActor)
		Debug.Trace("Actor was added to SpawnTypes. ID was: " +iCounter)
		;Decided 2 loops was better. Can use loop function as standalone later.
		
		iCounter += 1
		CurrentActor = SpawnTypeMasters[0].ActorList[iCounter] ;Set the next Actor
		
	endwhile
	
	Debug.Trace("All Actors added to SpawnTypes.")
	
	;Remove all first members of None, to avoid script errors. (Patch 0.09.01)
	iCounter = 1 ;Start from Urban STM, we already done [0] (Master list) above. 
	iSize = SpawnTypeMasters.Length
	
	while iCounter < iSize
	
		if ((SpawnTypeMasters[iCounter].ActorList.Length) > 1) && (SpawnTypeMasters[iCounter].ActorList[0] == None)
			SpawnTypeMasters[iCounter].ActorList.Remove(0)
			Debug.Trace("Removed remaining member of None from STM ActorList, ID was: " +iCounter)
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


;Adds a single ActorManager to all applicable Master Lists.
Function AddActorToMasterSpawnTypes(SOTC:ActorManagerScript aActorToAdd)

	Int iCounter
	Bool[] bAddToType = aActorToAdd.bAllowedSpawnTypes
	Int iSize = bAddToType.Length
		
	while iCounter < iSize

		if bAddToType[iCounter]
			SpawnTypeMasters[iCounter].ActorList.Add(aActorToAdd, 1)
			;Both bAllowed and STMasters arrays are the same in terms of index.
		endif
		
		iCounter += 1
			
	endwhile

EndFunction


;This function returns the mod to the pre-activated state, removing all dynamically produced data.
;DEV NOTE: Full uninstallation is handled by the AuxQuest/Auxillery Menu.
Function MasterFactoryReset()
	
	if ThreadController.ActiveThreadCheck() ;If currently active threads, return immediately. This will advise the Player as well. 
		ClearMenuVars()
		return
	endif
	
	;Else, continue with reset. 
	
	PlayerRef.RemoveItem(SOTC_MainMenuTape, 1) ;We want to know its been removed
	SOTC_MasterGlobal.SetValue(2.0) ;Reset State
	ThreadController.ToggleThreadKiller(true) ;Emergency stop all thread requests.
	
	Int iCounter
	Int iSize
	
	
	;First we will kill off the Region Instances and shuit down the World Managers, factory resetting all SpawnPoints and other data. 
	iSize = Worlds.Length
	while iCounter < iSize
		Worlds[iCounter].MasterFactoryReset()
		Worlds[iCounter].Disable()
		Worlds[iCounter].Delete()
		iCounter += 1
		Debug.Trace("World Deleted")
	endwhile
	Worlds.Clear() ;De-persist.
	Debug.Trace("All Worlds Cleaned up and Deleted")
	
	
	;Now we will kill all the Master SpawnTypes except the Master Actor List (0)
	iCounter = 1
	iSize = SpawnTypeMasters.Length
	while iCounter < iSize
		SpawnTypeMasters[iCounter].MasterFactoryReset()
		SpawnTypeMasters[iCounter].Disable()
		SpawnTypeMasters[iCounter].Delete()
		iCounter += 1
		Debug.Trace("SpawnType Master Deleted")
	endwhile
	Debug.Trace("All SpawnType Masters Cleaned up and Deleted, except Type 0 (Master List)")
	
	
	;Go back to SpawnTypeMasters[0] and start destroying all ActorManager instances.
	SpawnTypeMasters[0].MasterFactoryReset()
	SpawnTypeMasters[0].Disable()
	SpawnTypeMasters[0].Delete()
	SpawnTypeMasters.Clear() ;De-persist.
	Debug.Trace("Master Actor List destroyed")
	
	
	;Destroy the ThreadController and Event Monitor
	;ThreadController.MasterFactoryReset() ;Currently not needed (version 0.15.02).
	ThreadController.Disable()
	ThreadController.Delete()
	ThreadController = None ;De-persist. 
	Debug.Trace("ThreadController destroyed")
	
	
	;Clear Menu Vars before handover to AuxQuestScript
	ClearMenuVars()
	;Handover to AuxilleryQuestScript. This will stop this Quest. 
	AuxilleryQuestScript.FinaliseMasterFactoryReset()
	
EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;TIMER EVENTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;Timers for various things, including Spawn Events
Event OnTimer(Int aiTimerID)

	if aiTimerID == fEventCooldownTimerClock
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


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;MASTER SETTINGS FUNCTIONS & EVENTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;Sends the custom Master level Event according to the current MenuSettingMode. 
Function SendMasterMassEvent()

	;DEV NOTE: Do not try to declare Var arrays as a Property, the CK's UI doesn't understand it.

	Var[] Params
	string sPresetType

	if iMenuSettingsMode == 10 ;FULL PRESET
		
		Params = new Var[4]
		sPresetType = "Full"
		
		Params[0] = sPresetType ;The type of Preset change
		Params[1] = bForceResetCustomRegionSettings
		Params[2] = bForceResetCustomSpawnTypeSettings
		Params[3] = iCurrentPreset
		
		Int iTarget = ThreadController.iActiveRegionsCount
		SendCustomEvent("PresetUpdate", Params)
		Debug.Trace("Master Preset Update Sent. Waiting for event to reach target number of instances. Target is: " +iTarget)
		
		BeginEventMonitor(iTarget)
		
	elseif iMenuSettingsMode == 11 ;ALL SPAWNTYPES/ACTORS ONLY
		
		Params = new Var[3]
		sPresetType = "Spawntypes"
		
		Params[0] = sPresetType ;The type of Preset change
		Params[1] = bForceResetCustomSpawnTypeSettings
		Params[2] = iValue01
		
		Int iTarget = ThreadController.iActiveRegionsCount
		SendCustomEvent("PresetUpdate", Params)
		Debug.Trace("Master SpawnTypes-only Preset Update Sent. Waiting for event to reach target number of instances. Target is: " +iTarget)
		
		BeginEventMonitor(iTarget)
		
	elseif iMenuSettingsMode == 12 ;FORCE RESET ALL SPAWNPOINTS AND TIMERS. - (Not yet implemented).
	;This event does not require user to exit Menu as timers are not restarted. Possibly should move to Single settings event for clarity. 
		
		Int iTarget = ThreadController.iActiveRegionsCount
		SendCustomEvent("ForceResetAllSpsAndTimers") 
		Debug.Trace("Master SP + Timer Reset issued. Waiting for event to reach target number of instances. Target is: " +iTarget)
		BeginEventMonitor(iTarget)
		
	elseif iMenuSettingsMode == 13 ;SINGLE SPAWNTYPE ONLY
	
		Params = new Var[4]
		sPresetType = "SingleSpawntype"
		
		Params[0] = sPresetType
		Params[1] = iValue01 ;The ID of the Spawntype.
		Params[2] = bForceResetCustomSpawnTypeSettings
		Params[3] = iValue02 ;The Preset to set
		
		Int iTarget = ThreadController.iActiveRegionsCount
		SendCustomEvent("PresetUpdate", Params)
		Debug.Trace("Master Single SpawnType Preset Update Sent. Waiting for event to reach target number of instances. Target is: " +iTarget)
		BeginEventMonitor(iTarget)
		
	endif
	
EndFunction


;Used by the above Event issuer, checks Event flag on Threadcontroller until target is reached. 
Function BeginEventMonitor(Int aiTarget)

	Utility.Wait(1.0) ;Wait a sec, event may have possibly completed.
	while aiTarget < ThreadController.iEventFlagCount
		Utility.Wait(1.0) ;Wait another second. 
	endwhile
		
	Debug.MessageBox("Settings have been updated. You may resume as normal. The menu has been unlocked")
	ClearMenuVars()
	
EndFunction


;Used to send custom single setting changes on the Master level, from the menu directly.
Function SendMasterSingleSettingUpdateEvent(string asSetting, Bool abBool01 = false, Int aiInt01 = 0, Int aiInt02 = 0, Float aiFloat01 = 0.0) ;Parameters optional if needed

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
		
	elseif asSetting == "RegionRampageChance"
	
		SettingParams = new Var[2]
		SettingParams[0] = asSetting
		SettingParams[1] = iRandomRampageChance
		SendCustomEvent("MasterSingleSettingUpdate", SettingParams)
		
	elseif asSetting == "RegionAmbushChance"
	
		SettingParams = new Var[2]
		SettingParams[0] = asSetting
		SettingParams[1] = iRandomAmbushChance
		SendCustomEvent("MasterSingleSettingUpdate", SettingParams)
		
	elseif asSetting == "SpPresetBonusChance"
	
		SettingParams = new Var[3]
		SettingParams[0] = asSetting
		SettingParams[1] = aiInt01 ;The selected Preset to set value for. 
		SettingParams[2] = aiInt02 ;The value to set
		SendCustomEvent("MasterSingleSettingUpdate", SettingParams)
		
	elseif asSetting == "ForceResetSps"
	
		SendCustomEvent("ForceResetAllSps")
		;Menu safe as it does not reset Timers.
		
	endif
	
	;DEV NOTE: May revisit the use of the optional bool param and possibly implement override options for Regions with CustomSettings flag enabled. 
	
EndFunction


;Event for issuing the settings changes on Menus close. Used to avoid Menu lockups with latent functions.
Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)

	if (asMenuName == "PipboyMenu") && (!abOpening) ; On Pip-Boy closing
		
		if (iMenuSettingsMode >= 10) && (iMenuSettingsMode <= 30)  ;Settings events allocated to value range 10-30. Menu should be locked.
			
			Debug.Trace("Sending Master Mass Event ID: " +iMenuSettingsMode)
			SendMasterMassEvent()
			UnregisterForAllMenuOpenCloseEvents()
			bRegisteredForPipboyClose = false
			Debug.Trace("Mass Event Complete")
			
			;DEV NOTE: As of version 0.14.01, Event Quests are now Start Enabled and stages used to send work Events to those scripts.
			
		elseif iMenuSettingsMode == 100 ;Factory Reset
			
			Debug.Trace("Master Factory Reset initialising")
			MasterFactoryReset()
			bRegisteredForPipboyClose = false
			;Full uninstallation is done from AuxQuest and is called last from the above function block.
		
		endif
		
	endif

	;ClearMenuVars() - Moved to SettingsEventMonitor as that works in its own thread. 
	
EndEvent


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;MENU FUNCTIONS & EVENTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;Used for quick setting variables/Globals.

Function RegisterMasterForPipBoyCloseEvent(Int aiValue01 = 0, Int aiValue02 = 0) ;Register For Pipboy close event. Parameters optional
	
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

	iMenuSettingsMode = aiMode ;Local variable that script deals with
	SOTC_Global_MenuSettingsMode.SetValue(aiMode as float) ;Global for the Menu
	
EndFunction

;LEGEND - MENU SETTINGS MODES
;Equivalent Global for Menu: SOTC_Global_MenuSettingsMode
;Use this to determine if menu is in Master mode, Region mode or has pending settings event
; 0 - MASTER MODE
; 1 - REGION MODE
; 5 - FIRST TIME SETUP MODE
; 10 - MASTER PRESET/RESET PENDING
; 11 - MASTER ALL SPAWNTYPES PRESET PENDING
; 12 - FORCE RESET ALL SPs AND TIMERS (Currently unimplemented as of version 0.13.03)
; 13 - MASTER SINGLE SPAWNTYPE PRESET UPDATE
; Direct Region + Spawntype Preset are handled from Menu.
;Pending Events are all designated above a value of 10. Menu will detect this and lock if so.


;Ensures only the correct amount of options appear in the RegionSelectionMenu
Function SetMenuCurrentWorld(Int aiWorldID)
	
	SOTC_Global_CurrentMenuWorld.SetValue(aiWorldID as Float)
	SOTC_Global_RegionCount.SetValue(((Worlds[aiWorldID].Regions.Length) as Float)) ;We need the offset value
	Debug.Trace("Menu current World was set. Value is: " +SOTC_Global_CurrentMenuWorld.GetValue())
	Debug.Trace("Region count for World is: " +SOTC_Global_RegionCount.GetValue())
	
EndFunction


Function SetMenuCurrentRegion(Int aiRegionID)
	
	SOTC_Global_CurrentMenuRegion.SetValue(aiRegionID as float) ;This value is semi obsolete as of version 0.13.01
	MenuCurrentRegionScript = Worlds[(SOTC_Global_CurrentMenuWorld.GetValue() as Int)].Regions[aiRegionID]
	Debug.Trace("Menu current Region was set. Value is: " +SOTC_Global_CurrentMenuRegion.GetValue())
	
EndFunction


;This function either sets Menu Globals to current values before viewing a Menu option, or it sets the new value selected from said Menu. 
Function SetMenuVars(string asSetting, bool abSetValues = false, Int aiValue01 = 0)

	if asSetting == "MasterPreset"
	
		if abSetValues
			iCurrentPreset = aiValue01
		endif
		SOTC_Global01.SetValue(iCurrentPreset as Float)
		
	elseif asSetting == "MasterDifficulty"
		
		if abSetValues
			iCurrentDifficulty = aiValue01
			SendMasterSingleSettingUpdateEvent("Difficulty", iCurrentDifficulty)
		endif
		SOTC_Global01.SetValue(iCurrentDifficulty as Float)
		
	elseif asSetting == "MasterChance"
		
		if abSetValues
			iMasterSpawnChance = aiValue01
		endif
		SOTC_Global01.SetValue(iMasterSpawnChance as Float)
		
	elseif asSetting == "VanillaMode"
		
		if abSetValues
			bVanillaMode = aiValue01 as Bool
		endif
		SOTC_Global01.SetValue(bVanillaMode as Float)
		
	elseif asSetting == "SpWarning"
		
		if abSetValues
			bSpawnWarningEnabled = aiValue01 as Bool
		endif
		SOTC_Global01.SetValue(bSpawnWarningEnabled as Float)
		
	elseif asSetting == "RegionSwarmChance"
	
		if abSetValues
			iRandomSwarmChance = aiValue01
			SendMasterSingleSettingUpdateEvent("RegionSwarmChance")
		endif
		SOTC_Global01.SetValue(iRandomSwarmChance as Float)
		
	elseif asSetting == "RegionRampageChance"
	
		if abSetValues
			iRandomRampageChance = aiValue01
			SendMasterSingleSettingUpdateEvent("RegionRampageChance")
		endif
		SOTC_Global01.SetValue(iRandomRampageChance as Float)
		
	elseif asSetting == "RegionAmbushChance"
	
		if abSetValues
			iRandomAmbushChance = aiValue01
			SendMasterSingleSettingUpdateEvent("RegionAmbushChance")
		endif
		SOTC_Global01.SetValue(iRandomAmbushChance as Float)
		
	elseif asSetting == "EzApplyMode"
	
		if abSetValues
			iEzApplyMode = aiValue01
			SendMasterSingleSettingUpdateEvent("EzApplyMode")
		endif
		SOTC_Global01.SetValue(iEzApplyMode as Float)
	
	elseif asSetting == "EzBorderMode"
		
		if abSetValues
			iEzBorderMode = aiValue01
			SendMasterSingleSettingUpdateEvent("EzBorderMode")
		endif
		SOTC_Global02.SetValue(iEzBorderMode as Float)
		
	elseif asSetting == "SpPresetBonusChance"
	;Global01 is set to selected Preset in Menu. Then here we can play with the real bonus value.
	;This is required as same sub-menu is used for all 3 Preset selections.	
		
		Int i = (SOTC_Global01.GetValue()) as Int 
		if abSetValues
			iSpPresetBonusChance[i] = aiValue01
			SendMasterSingleSettingUpdateEvent("SpPresetBonusChance", i, aiValue01)
		endif
		SOTC_Global02.SetValue(iSpPresetBonusChance[i] as Float)
		
	elseif asSetting == "RarityChances"
	;DEV NOTE - Rarity chances are a bit different from other settings, only presets are given
	;for the user to select from (I.E 65/25/10 or 70/20/10 etc etc). Global01 is set to the last
	;known selected preset index in Menu, which is also stored on a variable here permanently.
		
		if abSetValues
			SetRarityChancesPreset(aiValue01)
			;Encapsulated to function for external use. 
		endif
		SOTC_Global01.SetValue(iCurrentRarityChancePreset as Float)
		
	elseif asSetting == "RerollChance"
		
		if abSetValues
			iRerollChance = aiValue01
		endif
		SOTC_Global01.SetValue(iRerollChance as Float)
		
	elseif asSetting == "RerollMaxCount"
		
		if abSetValues
			iRerollMaxCount = aiValue01
		endif
		SOTC_Global01.SetValue(iRerollMaxCount as Float)
		
	elseif asSetting == "BypassEventChance"
		
		if abSetValues
			iRE_BypassEventChance = aiValue01
		endif
		SOTC_Global01.SetValue(iRE_BypassEventChance as Float)
		
	elseif asSetting == "StaticEventChance"
		
		if abSetValues
			iRE_StaticEventChance = aiValue01
		endif
		SOTC_Global01.SetValue(iRE_StaticEventChance as Float)
	
	elseif asSetting == "EventCooldownTimer"
		
		if abSetValues
			fEventCooldownTimerClock = aiValue01 as Float
		endif
		SOTC_Global01.SetValue(fEventCooldownTimerClock)
		
	endif
	
EndFunction


Function SetRarityChancesPreset(Int aiPresetToSet)
	
	iCurrentRarityChancePreset = aiPresetToSet
	iCommonActorChance = RarityChancePresets[aiPresetToSet].iCommonChance
	iUncommonActorChance = RarityChancePresets[aiPresetToSet].iUncommonChance
	
EndFunction


;Used for wiping any custom settings when setting a Master level preset
Function SetPresetRegionOverrideMode(Bool abMode)
	bForceResetCustomRegionSettings = abMode ;Local variable that script deals with
EndFunction

;Same as above but for Regional SpawnType managers, the above overrides this.
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
	SOTC_Global_RegionCount.SetValue(0.0)
	MenuCurrentActorScript = None
	MenuCurrentRegionScript = None
	MenuCurrentRegSpawnTypeScript = None
	ThreadController.iEventFlagCount = 0 
EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;CHANCE FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;If a normal Spawn, this will return an Int between 1-3, corresponding to rarity
;Rarity levels are Common, Uncommon and Rare.
Int Function RollForRarity()

	Int i = Utility.RandomInt(1,100)
	
	if i <= iCommonActorChance
		return 1
	elseif i <= iUncommonActorChance
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


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;SPAWN UTILITY FUNCTIONS & EVENTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

Bool Function MasterSpawnCheck(ObjectReference akCallingPoint, Bool abAllowVanilla, Bool abEventSafe)

	if CheckForBypassEvents() ;Check for any events not subject to EventLock
		return true ;deny the calling point
	endif
	
	;Check all pending events if they have been flagged. This is done in priority order
	if (!bEventLockEngaged) && (abEventSafe) ;Point must be marked as safe. 
		
		akCallingPoint = kEventPoint ;Set the Point for the Event Quest to remotely access
		if CheckForEvents()
			return true ;deny the calling point
		endif
	
	endif
	
	;Vanilla Mode check
	
	if (!abAllowVanilla) && (bVanillaMode) && ((Utility.RandomInt(1,100)) <= iMasterSpawnChance)
		return true ;Denied due to vanilla mode
	endif
	
	;If we got this far than all good, SP can proceed.
	return false ;Proceed
	
EndFunction


;Show a random, passive debug message implying a SpawnPoint has fired nearby.
Function ShowSpawnWarning()

	if bSpawnWarningEnabled

		Int i = Utility.RandomInt(1,2)
		
		if i == 1
			Debug.Notification("You hear movement in the distance")
		elseif i == 2
			Debug.Notification("You sense a presence ahead")
		endif
	
	endif
	
EndFunction


;This function returns the Radroach ClassPreset[1] when a SpawnTypeRegional instance fails to produce an Actor due to empty lists. 
;This is done instead of intricate security functions and returns, and also an ode to Bethesdas own failsafe for Actors.
SOTC:ActorClassPresetScript Function GetMasterFailsafeActor()

	return SpawnTypeMasters[0].ActorList[2].ClassPresets[1] ;Radroaches, Common Preset.
	
EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;RANDOM EVENTS FRAMEWORK FUNCTIONS & EVENTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------


Bool Function CheckForBypassEvents() ;Check for any events not subject to EventLock

	if (kRE_BypassEvents[0] != None) && Utility.RandomInt(1,100) <= iRE_BypassEventChance
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
	if (kRE_StaticEvents[0] != None) && (Utility.RandomInt(1,100) <= iRE_StaticEventChance)
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
	StartTimer(fEventCooldownTimerClock, iEventCooldownTimerID)
	bEventLockEngaged = true ;Lock it up.
	
EndFunction


Function BeginStaticEvent()

	int iSize = (kRE_StaticEvents.Length) - 1 ;Get actual index count
	;Select a random member and set the Begin stage
	kRE_StaticEvents[(Utility.RandomInt(0,iSize))].SetStage(10)
	;NOTE - If this event fails to fire due to some check implemented on the Event code, nothing happens.
	
	;Start the cooldown Timer before new event can fire.
	StartTimer(fEventCooldownTimerClock, iEventCooldownTimerID)
	bEventLockEngaged = true ;Lock it up.

EndFunction


;New Event Quests being added for the first time or timed events firing/appending should use this function.
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


;The opposite of the above function. Remvoes from active list. 
Function SafelyUnregisterActiveEvent(string asEventType, Quest akEventQuest)

	;DEV NOTE: Event Arrays should always be kept initialised, with at least one member of None.
	
	Int i ;Used to set member to remove, if necessary. 
	
	if asEventType == "Bypass" ;Add a new Bypass Event active Event list

		if kRE_BypassEvents.Length == 1 ;Only one member left in array!
		;Shouldn't need to run find function if only one member, as it should be the expected. 
		;Caution should be taken when coding Events and calling this however.
			kRE_BypassEvents[0] = None 
			
		else 
			i = kRE_BypassEvents.Find(akEventQuest)
			kRE_BypassEvents.Remove(i)
		endif
		
	endif
	
	
	if asEventType == "Timed" ;Add a new Bypass Event active Event list

		if kRE_TimedEvents.Length == 1 ;Only one member left in array!
		;Shouldn't need to run find function if only one member, as it should be the expected. 
		;Caution should be taken when coding Events and calling this however.
			kRE_TimedEvents[0] = None 
			
		else 
			i = kRE_TimedEvents.Find(akEventQuest)
			kRE_TimedEvents.Remove(i)
		endif
		
	endif
	
	
	if asEventType == "Static" ;Add a new Bypass Event active Event list

		if kRE_StaticEvents.Length == 1 ;Only one member left in array!
		;Shouldn't need to run find function if only one member, as it should be the expected. 
		;Caution should be taken when coding Events and calling this however.
			kRE_StaticEvents[0] = None 
			
		else 
			i = kRE_StaticEvents.Find(akEventQuest)
			kRE_StaticEvents.Remove(i)
		endif
		
	endif

EndFunction


;DEV NOTE: As of version 0.14.01, Event Quests are now Start Enabled and stages used to send work
;Events to this script. These functions may be removed in future. 

;Append a new custom event Quest to be started and added. Event Quests will be started when Menu mode is exited.
Function SafelyAppendEventQuestForStart(Quest akEventQuest)
	
	if kEventQuestsPendingStart == None ;Ensure the array is actually initialised. Should always have one member after first init, even if that member is None. 
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


;Safely starts any pending Event Quests from the array after Menu is exited. 
Function SafelyStartPendingEventQuests()

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

;-------------------------------------------------------------------------------------------------------------------------------------------------------
