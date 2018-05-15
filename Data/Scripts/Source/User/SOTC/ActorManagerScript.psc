Scriptname SOTC:ActorManagerScript extends ObjectReference
{ Represents an Actor Type, managing all subclasses and data. }
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

	String Property sActorType Auto Const Mandatory
	{ Fill with generic name for this Actor (i.e Raider), used for sorting/displaying. }

	Int Property iActorID Auto Const Mandatory
	{ Permanent ID number of this Actor. Index of this Actor on the MasterActorList array. }

	Bool[] Property bAllowedSpawnTypes Auto Const Mandatory
	{ Set true or false on each member for each SpawnType to include this Actor in. }
	
	;Array fill order for the below does not matter
	
	MiscObject[] Property kWorldPresetObjects Auto Const Mandatory
	{ Fill with base MiscObjects containing WorldPreset scripts for this Actor. Instanced at runtime. }
	
	MiscObject[] Property kClassPresetObjects Auto Const Mandatory
	{ Fill with base MiscObjects containing ClassPreset scripts for this Actor. Instanced at runtime. }
	
	MiscObject[] Property kGroupLoadoutObjects Auto Const Mandatory
	{ Fill with base MiscObjects containing GroupLoadout scripts for this Actor. Instanced at runtime. }

EndGroup


Group Dynamic

	SOTC:ActorWorldPresetsScript[] Property WorldPresets Auto
	{ Initialise one member of None. Fills dynamically. Used for Region preset storage. }

	SOTC:ActorClassPresetScript[] Property ClassPresets Auto
	{ Initialise one member of None. Fills dynamically. Used for Class preset storage. }

	SOTC:ActorGroupLoadoutScript[] Property GroupLoadouts Auto
	{ Init one member of None. Fills dynamically. All GroupLoadouts scripts will add themselves here }
	;This particular property exists so that Alias fill order for Class Presets and Group Loadouts does
	;NOT have to be in any specific order.
	
EndGroup


Group Config
{ Properties used in spawning etc }

	Bool Property bActorEnabled Auto Mandatory
	{ Init true. Change in Menu. Will not appear in random spawns if set false }

	Bool Property bIsFriendlyNeutralToPlayer Auto Mandatory
	{ Init with correct starting value for this Actor. Used to prevent random hostile events }
	
	Bool Property bIsOversizedActor Auto Mandatory
	{ Set true if this Actor is unsafe to spawn in confined areas. }

	Bool Property bSupportsSwarm Auto Mandatory
	{ Set true if this Actor can cause an Infestation/Swarm. }
	
	Bool Property bSupportsStampede Auto Mandatory
	{ Set true if this Actor can cause a Stampede. }

	;NOTE: Could have used a struct here for Swarm properties

	Int Property iSwarmMaxCountBonus Auto
	{ If this actor supports swarm, set balanced value here. Else, fill 0 }

	Int Property iSwarmChanceBonus Auto
	{ If this actor supports swarm, set balanced value here. Else, fill 0 }

	Int Property iSwarmMaxCountBossBonus Auto
	{ If this actor supports swarm, set balanced value here. Else, fill 0 }

	Int Property iSwarmChanceBossBonus Auto
	{ If this actor supports swarm, set balanced value here. Else, fill 0 }
	
	;Loot system properties

EndGroup


Group LootConfig

	Bool Property bLootSystemEnabled Auto Mandatory
	{ Init false. Set in Menu. When on, spawned Actors of this type may possibly 
	receive a loot item from one of the Formlists below }
	
	Formlist Property kRegularLootList Auto Const Mandatory
	{ Fill with Formlist made for this Actor Type's regular loot }
	
	Formlist Property kBossLootList Auto Const Mandatory
	{ Fill with Formlist made for this Actor Type's boss loot }
	
	Int Property iRegularLootChance Auto
	{ Init 20. Change in Menu. Chance an Actor will receive a loot item }
	
	Int Property iBossLootChance Auto
	{ Init 10. Change in Menu. Chance an Actor will receive a loot item }
	
EndGroup

;LEGEND - LOOT SYSTEM
;There are 2 ways to provide random spawns with a random loot item (or more if using an "Use All" 
;flagged Leveled List) - through the SpawnTypeRegionalScript or the ActorQuestScript. Both systems
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
;Loot on the ActorQuestScript is obviously so we can supply highly specific loot for each Actor type. 
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
;INITIALISATION FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

;DEV NOTE: Init events/functions now handled by Masters creating the instances.

;Creates all the instances to data container miscobjects
Function PerformFirstTimeSetup(ObjectReference akMasterMarker)

	if !bInit

		MasterScript.SpawnTypeMasters[0].ActorList[iActorID] = Self ;Set self on Master
		Debug.Trace("+iActorID +sActorType set on Masterlist")
		
		;Create instances of subclass objectreferences and set them up
		
		;Start WorldPreset subclasses
		Int iCounter
		Int iSize = kWorldPresetObjects.Length
		ObjectReference kNewInstance
		
		Debug.Trace("Initialising WorldPresets for +iActorID +sActorType")
		
		while iCounter < iSize
		
			kNewInstance = akMasterMarker.PlaceAtMe(kWorldPresetObjects[iCounter], 1 , false, false, false)
			(kNewInstance as SOTC:ActorWorldPresetsScript).PerformFirstTimeSetup(Self)
			
			iCounter += 1
			
		endwhile
		
		;Start ClassPreset subclasses
		iCounter = 0
		iSize = kClassPresetObjects.Length
		
		Debug.Trace("Initialising ClassPresets for +iActorID +sActorType")
		
		while iCounter < iSize
		
			kNewInstance = akMasterMarker.PlaceAtMe(kClassPresetObjects[iCounter], 1 , false, false, false)
			(kNewInstance as SOTC:ActorClassPresetScript).PerformFirstTimeSetup(Self)
			
			iCounter += 1
			
		endwhile
		
		;Start GroupLoadout subclasses
		iCounter = 0
		iSize = kGroupLoadoutObjects.Length
		
		Debug.Trace("Initialising GroupLoadouts for +iActorID +sActorType")
		
		while iCounter < iSize
		
			kNewInstance = akMasterMarker.PlaceAtMe(kGroupLoadoutObjects[iCounter], 1 , false, false, false)
			(kNewInstance as SOTC:ActorGroupLoadoutScript).PerformFirstTimeSetup(Self)
			
			iCounter += 1
			
		endwhile
		
		bInit = true
		
		Debug.Trace(" +iActorID +sActorType init complete")
	
	endif
	
EndFunction


;Distributes Group loadouts and also cleans up arrays ready for functions.
Function DistributeGroupLoadouts()
	
	Bool bAllowPaGroups = MasterScript.bAllowPowerArmorGroups
	Int iCounter
	Int iSize

	
	if GroupLoadouts[0] == None ;Check if first member is None from Init (patch 0.09.01)
		GroupLoadouts.Remove(0)
	endif
	
	;Clear first
	iSize = ClassPresets.Length
	Debug.Notification("About to add Group to Class, length of Classes is " +ClassPresets.Length)
	Debug.Notification("About to clear " +ClassPresets)
	
	while iCounter < iSize
		
		if ClassPresets[iCounter] != None
			ClassPresets[iCounter].SafelyClearGroupLoadouts() ;Clear before refilling.
			iCounter += 1
		endif
		
	endwhile
	
	Debug.Notification("Clearing Done " +ClassPresets)
	
	;Refill/init
	iCounter = 0
	iSize = GroupLoadouts.Length
		
	while iCounter < iSize
		GroupLoadouts[iCounter].AddGroupToClassPresets(bAllowPaGroups)
		;If PA groups are disallowed, external function call returns immediately and loop continues.
		iCounter += 1
	endwhile
	
	Debug.Notification("Distribution Done " +ClassPresets)
		
	;Now check and remove all None members from the 1st index of ClassPresets
	;There should be one GroupLoadout for each Preset!!
	iCounter = 0
	iSize = ClassPresets.Length
		
	while iCounter < iSize
		
		if (ClassPresets[iCounter] != None) && (ClassPresets[iCounter].GroupLoadouts[0] == None) && (ClassPresets[iCounter].GroupLoadouts.Length >= 2)
		;Check if Actor has CP, first member is None and if any more members in the list, if so, remove first member. 
			ClassPresets[iCounter].GroupLoadouts.Remove(0)
		endif
			
	endwhile
	
EndFunction


;Add or remove Power Armor units from Class Presets
Function AddRemovePowerArmorGroups(Bool abRemove)

	Int iCounter
	Int iSize

	if !abRemove ;Add
	
		iSize = GroupLoadouts.Length
		
		while iCounter < iSize
		
			if GroupLoadouts[iCounter].bHasPowerArmorUnits
				GroupLoadouts[iCounter].AddGroupToClassPresets(true)
			endif

			iCounter += 1
		
		endwhile
		
	else ;Assume remove
	
		iSize = ClassPresets.Length
		
		while iCounter < iSize
			ClassPresets[iCounter].RemovePowerArmorGroups()
			iCounter += 1
		endwhile
		
	endif
	
	;Now check and remove all None members from the 1st index of ClassPresets
	;There should be one GroupLoadout for each Preset!!
	iCounter = 0
	iSize = ClassPresets.Length
		
	while iCounter < iSize
		
		if (ClassPresets[iCounter] != None) && (ClassPresets[iCounter].GroupLoadouts[0] == None) && (ClassPresets[iCounter].GroupLoadouts.Length >= 2)
		;Check if Actor has CP, first member is None and if any more members in the list, if so, remove first member. 
			ClassPresets[iCounter].GroupLoadouts.Remove(0)
		endif
			
	endwhile
	
EndFunction


;------------------------------------------------------------------------------------------------
;RETURN FUNCTIONS
;------------------------------------------------------------------------------------------------

;Used for various Spawn function that might want random set of parameters, using the first 3 Classes
;(the ones based on Rarity levels 1-3, Common, Uncommon and Rare)
SOTC:ActorClassPresetScript Function GetRandomRarityBasedClass()

	Int iClass = Utility.RandomInt(1,3) ;Class to use from ClassPresets
	return ClassPresets[iClass]
	;The caller should now determine iDifficulty setting and pull the GroupLoadout.
	
EndFunction


;------------------------------------------------------------------------------------------------
;LOOT FUNCTIONS
;------------------------------------------------------------------------------------------------

;Run a chance loop on a Spawnpoints Grouplist, potentially adding a loot item to each Actor in the list.
Function DoLootPass(Actor[] akGroupList, Int aiBossCount)
	
	Int iCounter 
	Int iGroupSize = akGroupList.Length
	Int iLootListSize = (kRegularLootList.GetSize()) -1 ;Actual index count
	Form kLootItem
	
	;Regular Actors inlcuding Bosses if present
	
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
