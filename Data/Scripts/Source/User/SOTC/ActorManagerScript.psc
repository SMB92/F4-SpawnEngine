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
	
	Bool Property bSupportsRampage Auto Mandatory
	{ Set true if this Actor can cause a Rampage/Stampede. }

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
	
	Int Property iRegularLootChance = 20 Auto
	{ Default value of 20. Change in Menu. Chance an Actor will receive a loot item }
	
	Int Property iBossLootChance = 10 Auto
	{ Default value of 10. Change in Menu. Chance an Actor will receive a loot item }
	
EndGroup

;LEGEND - LOOT SYSTEM - UPDATED FOR 0.13.01
;Spawns may have random loot item(s) given to them at spawn time, based on a configurable chance value.
;The system works by storing formlists on each of the ActorManagers, 1 for regular Actors and 1 for 
;Boss Actors. Spawnpoints will check the ActorManager after spawntime (after all actors are placed in 
;game and packages applied, preventing unnecessary slowdown in the spawnloops themselves), and if this
;system is enabled, it will send in the GroupList of that Actor type and do a loop to potentially add a
;single item from the list to each Actors inventory, based on a configurable chance value. This item can 
;be a Leveled List, and if it is marked to Use All, will add every item from that list.

;SpawnType loot system has been removed as of version 0.13.01 as new instancing methods introduced
;in version 0.10.01 made it much more difficult to setup, and it is simply not worth the effort to
;rebuild it. The main reason for extending this system to SpawnTypes was to be able to provide unique
;loot per Region, I.E having "Wildlife" in a certain area have a unique item not found elsewhere.
;On the whole however, this system would have been a bit too confusing, finicky and under-utilised
;so the decision was made to remove it entirely. It is still supported for individual Actor types
;via the ActorManager, and is useful here as we don't have to edit the Actors themselves to add any
;new loot items, or vanilla Levelled lists of any sort.

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
		Debug.Trace("Actor set on Masterlist")
		
		;Create instances of subclass objectreferences and set them up
		
		;Start WorldPreset subclasses
		Int iCounter
		Int iSize = kWorldPresetObjects.Length
		ObjectReference kNewInstance
		
		Debug.Trace("Initialising WorldPresets")
		
		while iCounter < iSize
		
			kNewInstance = akMasterMarker.PlaceAtMe(kWorldPresetObjects[iCounter], 1 , false, false, false)
			(kNewInstance as SOTC:ActorWorldPresetsScript).PerformFirstTimeSetup(Self)
			
			iCounter += 1
			
		endwhile
		
		;Start ClassPreset subclasses
		iCounter = 0
		iSize = kClassPresetObjects.Length
		
		Debug.Trace("Initialising ClassPresets")
		
		while iCounter < iSize
			;DEV NOTE: No need to check for blank members, CP base objects insert to correct index on dynamic array anyway. 
			kNewInstance = akMasterMarker.PlaceAtMe(kClassPresetObjects[iCounter], 1 , false, false, false)
			(kNewInstance as SOTC:ActorClassPresetScript).PerformFirstTimeSetup(Self)
			
			iCounter += 1
			
		endwhile
		
		;Start GroupLoadout subclasses
		iCounter = 0
		iSize = kGroupLoadoutObjects.Length
		
		Debug.Trace("Initialising GroupLoadouts")
		
		while iCounter < iSize
		
			kNewInstance = akMasterMarker.PlaceAtMe(kGroupLoadoutObjects[iCounter], 1 , false, false, false)
			(kNewInstance as SOTC:ActorGroupLoadoutScript).PerformFirstTimeSetup(Self)
			
			iCounter += 1
			
		endwhile
		
		;Remove first member of None if still present. Safe to call AFTER GL's have instanced
		if GroupLoadouts[0] == None 
			Grouploadouts.Remove(0)
			Debug.Trace("Removed remaining member of None on ActorManager GroupLoadouts array")
		endif
		
		;Now check and remove all None members from the first index of ClassPresets GroupLoadout arrays
		;There should be one GroupLoadout for each Preset!!
		iCounter = 0
		iSize = ClassPresets.Length
			
		while iCounter < iSize
			
			if (ClassPresets[iCounter] != None) ;Check if ClassPreset actually defined
				ClassPresets[iCounter].CleanGroupLoadoutsArray()
			endif
			
			iCounter += 1
			
		endwhile

		
		bInit = true
		
		Debug.Trace("ActorManager initialisation complete for: " +sActorType)
		Debug.Trace("ClassPresets defined: " +ClassPresets)
	
	endif
	
EndFunction


;Distributes Group loadouts and also cleans up arrays ready for functions. Not used in first time setup however.
Function DistributeGroupLoadouts()
	
	Bool bAllowPaGroups = MasterScript.bAllowPowerArmorGroups
	Int iCounter
	Int iSize

	
	if GroupLoadouts[0] == None ;Check if first member is None from Init (patch 0.09.01)
		GroupLoadouts.Remove(0)
		;There will always be at least one actual GL on this Manager, this is safe.
	endif
	
	;Clear first
	iSize = ClassPresets.Length
	
	while iCounter < iSize
		
		if ClassPresets[iCounter] != None
			ClassPresets[iCounter].SafelyClearGroupLoadouts() ;Clear before refilling.
			iCounter += 1
		endif
		
	endwhile
	
	;Refill/init
	iCounter = 0
	iSize = GroupLoadouts.Length
		
	while iCounter < iSize
		GroupLoadouts[iCounter].AddGroupToClassPresets(bAllowPaGroups)
		;If PA groups are disallowed, external function call returns immediately and loop continues.
		iCounter += 1
	endwhile
		
	;Now check and remove all None members from the first index of ClassPresets GroupLoadouts arrays
	;There should be one GroupLoadout for each Preset!!
	iCounter = 0
	iSize = ClassPresets.Length
		
	while iCounter < iSize

		if (ClassPresets[iCounter] != None) ;Check if ClassPreset actually defined
			ClassPresets[iCounter].CleanGroupLoadoutsArray()
		endif
		
		iCounter += 1

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

		if (ClassPresets[iCounter] != None) ;Check if ClassPreset actually defined
			ClassPresets[iCounter].CleanGroupLoadoutsArray()
		endif
		
		iCounter += 1

	endwhile
	
EndFunction


;Destroys all dynamically produced data, ready to destroy this instance.
Function MasterFactoryReset()

	Int iCounter
	Int iSize
	
	;Start with WorldPresets
	iSize = WorldPresets.Length
	while iCounter < iSize
		WorldPresets[iCounter].MasterFactoryReset()
		WorldPresets[iCounter].Disable()
		WorldPresets[iCounter].Delete()
		WorldPresets[iCounter] = None ;De-persist
		iCounter += 1
		Debug.Trace("ActorWorldPresets instance destroyed")
	endwhile
	Debug.Trace("All ActorWorldPresets instances destroyed")
	
	
	;Now do ClassPresets
	iCounter = 0
	iSize = ClassPresets.Length
	while iCounter < iSize
		if ClassPresets[iCounter] != None ;Skip empty indexes.
			
			ClassPresets[iCounter].MasterFactoryReset()
			ClassPresets[iCounter].Disable()
			ClassPresets[iCounter].Delete()
			ClassPresets[iCounter] = None ;De-persist
			Debug.Trace("ActorClassPreset instance destroyed")
		endif
		iCounter += 1
	endwhile
	Debug.Trace("All ActorClassPreset instances destroyed")

	
	;Now do GroupLoadouts
	iCounter = 0
	iSize = GroupLoadouts.Length
	while iCounter < iSize
		GroupLoadouts[iCounter].MasterFactoryReset()
		GroupLoadouts[iCounter].Disable()
		GroupLoadouts[iCounter].Delete()
		GroupLoadouts[iCounter] = None ;De-persist
		iCounter += 1
		Debug.Trace("ActorGroupLoadout instance destroyed")
	endwhile
	Debug.Trace("All ActorGroupLoadouts instances destroyed")
	
	
	Debug.Trace("ActorManager instance ready for destruction")
	
	;SpawnTypeMasters[0] will destroy this instance once returned. 

EndFunction


;------------------------------------------------------------------------------------------------
;RETURN FUNCTIONS
;------------------------------------------------------------------------------------------------

;Used for various Spawn functions that might want random set of parameters, using the Rarity-based 
;Classes (1-3, Common, Uncommon and Rare).
SOTC:ActorClassPresetScript Function GetRandomRarityBasedClass()

	Int iClass = Utility.RandomInt(1,3) ;Class to use from ClassPresets
	return ClassPresets[iClass]
	;The caller should now determine iDifficulty setting and pull the GroupLoadout.
	
EndFunction

;returns the requested ClassPreset if it exists, otherwise returns Debug Preset (0)
SOTC:ActorClassPresetScript Function GetClassPreset(Int aiClass)

	if aiClass == 777 ;Random Rarity-based
		return GetRandomRarityBasedClass()
	elseif ClassPresets[aiClass] != None ;Ensure requested Class is defined
		return ClassPresets[aiClass]
	else ;return debug Preset, print debug trace
		return ClassPresets[0]
		Debug.Trace("Requested Class not defined, returning debug preset")
	endif
	
	;DEV NOTE - All Actors should have all 3 Rarity-based Classes defined as well as Debug Preset.
	
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
