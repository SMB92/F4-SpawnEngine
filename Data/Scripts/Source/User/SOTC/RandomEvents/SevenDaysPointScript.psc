Scriptname SOTC:RandomEvents:SevenDaysPointScript extends ObjectReference
{ Seven Days to Die Event SpawnPoint Script. }
;Written by SMB92.
;Special thanks to J. Ostrus [BigandFlabby] for making this mod possible.

;LEGEND - PREFIX CONVENTION
; Variables and Properties are treated the same. Script types do not have prefixes, unless they
;are explicitly received as function arguments and are multi-instance scripts.
; "a" - (Function/Event Blocks only) Variable was received as function argument OR the variable
;was created from a passed-in Struct/Var[] member
; "k" - Is an "Object" as usual, whether created in a Block or defined in the empty state/a state.
; "f,b,i,s" - The usual Primitives: Float, Bool, Int, String.

;DEV NOTE: This event is included in the core of the F4-SpawnEngine

;LEGEND - EVENTS FRAMEWORK
;In order for Random Events to be added on by third parties with ease, this system uses Quests to
;instantiate their controller script for the "Event" and the MasterScript simply calls a setstage
;on the Quest in order to activate it (standard stage ID is 10). This eliminates the need to be
;reliant on using a template script or single object of any sort. Controller scripts may include
;a "helper" object which can be used to place in the world to do spawning work for the Event.

;There are currently 4 types of Events supported. They are as follows:
; 1. Bypass Events - These Events can be triggered at any time, based on a chance roll. They will
;"bypass" any Event locks in place. This is good for Events like Ghoul Apocalypse mode where we
;want that always random chance of the Event occurring.
; 2. Timed/Recurring Events - As you would assume, these Events recur according to a timer, which
;is set on the code for that Event.
; 3. Static Events - This type of Event has a chance to occur at any time, based on some conditions
;that can be setup for said Event specifically. This type of Event is subject to Event locks however.
; 4. Unique Events - This type of Event only fires once, and must be coded accordingly. These events
;should make use of the timed events system so no extra functions need be developed. 

;So to explain how it works behind the scenes, Events Quests must be started from a Menu (so their 
;Quest must NOT be start game enabled). Upon doing so the Event will be coded to either add itself
;to the MasterScript's arrays of Event Quests based on it's type, or in the case of Timed Events,
;begin their timers/event monitors and add themselves when the timer/event monitor triggers. When
;a SpawnPoint fires (currently RE system ONLY supports the Main SpawnPoint type, SpGroupPoint), the
;MasterScript will check for Events in the same order as listed above. Whenever an Event fires the
;MasterScript will store the SpawnPoint and it will become the Point of the Event. The SP script
;is not used itself, it is purely a location reference. With the exception of bypass events, after
;an Event has fired a "cooldown" timer will be started and a "lock" engaged so that no more Events
;can fire until the cooldown is over. Unique Events will be removed permanently and an accompanying
;GlobalVar will be set to prevent them from starting again (at least without forcing it).
;When Events are toggled off from the Menu, their Quest will be shutdown and their entry(s) removed
;from the Master arrays. Any Events that make use of Helper Points to do spawn work must be coded
;to clean themselves up after a set amount of time.


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;PROPERTIES & IMPORTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

import SOTC:Struct_ClassDetails

SOTC:MasterQuestScript Property MasterScript Auto Const
{ Fill with MasterQuest. }

SOTC:RandomEvents:SevenDaysQuestScript Property Controller Auto Const
{ Fill with the Controller Quest for this Event }

ReferenceAlias Property kRushPackage Auto Const
{ Fill with the Rush Package Alias From MasterScript. }

Keyword Property SOTC_PackageKeyword01 Auto Const
{ Auto-fill. Default keyword used with Single Location Package. }

EncounterZone Property SOTC_Ez_1_0 Auto Const
{ Auto-fill. Unleveled EZ ensures spawns scale to Player. }

Actor[] kGroupList ; The group of Spawned Actors
Int iLosCounter ;This will be incremented whenever a Line of sight check to Player fails. If reaches 25, spawning aborts. As we at least spawn 1 actor
;to start with, this remains safe to use (however Player may see that one actor being spawned. its just easier to live with). 

Int iHelperFireTimerID = 3 Const

SOTC:ThreadControllerScript ThreadController ;Fills at runtime
SOTC:ActorClassPresetScript ActorParamsScript
SOTC:ActorManagerScript ActorManager ;Fills at runtime


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;SPAWN FUNCTION & EVENTS
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;Function called by Controller to start the Event Spawn.
Function EventHelperBeginSpawn(SOTC:ActorClassPresetScript aActorParamsScript)

	;SetSpScriptLinks. This script takes no consideration for Regional properies, Master level only.
	ThreadController = MasterScript.ThreadController
	ActorParamsScript = aActorParamsScript
	ActorManager = aActorParamsScript.ActorManager
	
	StartTimer(0.2, iHelperFireTimerID) ;Ready to start own thread
	
EndFunction


Event OnTimer(int aiTimerID)

	if aiTimerID == iHelperFireTimerID
		
		ThreadController.ForceAddThreads(1) 
		EventHelperPrepareSingleGroupSpawn()
		ThreadController.ReleaseThreads(1) ;Spawning done, threads can be released.
		
	endif
	
EndEvent


Function EventHelperPrepareSingleGroupSpawn()

	;Begin spawn code
	ClassDetailsStruct ActorParams = ActorParamsScript.ClassDetails[MasterScript.iCurrentPreset]
	
	
	;Organise the ActorBase arrays
	;------------------------------
	
	ActorBase[] kRegularUnits = (ActorParamsScript.GetRandomGroupLoadout(false)) as ActorBase[] ;Cast to copy locally
	ActorBase[] kBossUnits
	Bool bBossAllowed = (ActorParams.iChanceBoss) as Bool
	if bBossAllowed ;Not gonna set this unless it's allowed. Later used as parameter
		kBossUnits = (ActorParamsScript.GetRandomGroupLoadout(true)) as ActorBase[] ;Cast to copy locally
	endif
	
	;Set difficulty level from Master.
	Int iDifficulty = MasterScript.iCurrentDifficulty
	
	;Begin spawning.
	;---------------
	
	Int iRegularActorCount ;Required for loot system
	
	EventHelperSpawnActorSingleLocLoop(ActorParams.iMaxAllowed, ActorParams.iChance, kRegularUnits, false, iDifficulty)

	iRegularActorCount = (kGroupList.Length) ;Required for loot system

	if bBossAllowed && iLosCounter != 25 ;Check again if Boss spawns allowed for this Actors preset and LoS counter hasn't maxed.
		EventHelperSpawnActorSingleLocLoop(ActorParams.iMaxAllowedBoss, ActorParams.iChanceBoss, kBossUnits, true, iDifficulty)
	endif
	
	
	;Check for loot pass, inform ThreadController of the spawned numbers.
	;---------------------------------------------------------------------
	
	if ActorManager.bLootSystemEnabled
		Int iBossCount = (kGroupList.Length) - iRegularActorCount ;Also required for loot system
		ActorManager.DoLootPass(kGroupList, iBossCount)
	endif
	
	;Lastly, we tell Increment the Active NPC and SP on the Thread Controller
	ThreadController.IncrementActiveNpcCount(kGroupList.Length)
	ThreadController.IncrementActiveSpCount(1)
	
		
EndFunction


Function EventHelperSpawnActorSingleLocLoop(Int aiMaxCount, Int aiChance, ActorBase[] akActorList, Bool abIsBossSpawn, Int aiDifficulty)
	
	if !abIsBossSpawn ;As SPs are designed to only spawn one group each, only init this list the first time. 
		kGroupList = new Actor[0] ;Needs to be watched for errors with arrays getting trashed when init'ed 0 members.
		aiChance += (Controller.GetSpawnChanceBonus())
		aiMaxCount += (Controller.GetMaxCountBonus())
	endif
	
	Int iCounter = 1 ;Guarantee the first Actor
	Int iActorListSize = (akActorList.Length) - 1 ;Need actual size
	Actor kSpawned
	
	;Spawn the first guaranteed Actor
	kSpawned = Self.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, SOTC_Ez_1_0) ;Ez is unleveled here.
	kGroupList.Add(kSpawned) ;Add to Group tracker
	
	;Begin chance based placement loop for the rest of the Group
	while iCounter <= aiMaxCount
	
		if (Utility.RandomInt(1,100)) <= aiChance
			kSpawned = Self.PlaceActorAtMe(akActorList[Utility.RandomInt(0,iActorListSize)], aiDifficulty, SOTC_Ez_1_0) ;Ez is unleveled here. 
			kGroupList.Add(kSpawned) ;Add to Group tracker
			EventHelperApplyPackageSingleLocData(kSpawned)
		endif
		
		iCounter +=1
	
	endwhile

EndFunction


Function EventHelperApplyPackageSingleLocData(Actor akActor)

	akActor.SetLinkedRef(MasterScript.PlayerRef, SOTC_PackageKeyword01)
	kRushPackage.ApplyToRef(akActor) ;Finally apply the data alias with package
	akActor.EvaluatePackage() ;And evaluate so no delay
	
EndFunction


;-------------------------------------------------------------------------------------------------------------------------------------------------------
;CLEANUP FUNCTIONS & EVENTS - EVENT HELPER SCRIPT
;-------------------------------------------------------------------------------------------------------------------------------------------------------

;The owning SpawnPoint will delete this isntance when the following has returned. 

Function EventHelperFactoryReset()

	EventHelperCleanupActorRefs()
	
	ActorParamsScript = None
	ActorManager = None
	
	ThreadController.IncrementActiveSpCount(-1)
	ThreadController = None

EndFunction


;Cleans up all Actors in GroupList
Function EventHelperCleanupActorRefs() 

	int iCounter = 0
	int iSize = kGroupList.Length
        
	while iCounter < iSize

		kRushPackage.RemoveFromRef(kGroupList[iCounter]) ;Remove package data. Perhaps not necessary either?
		;NOTE: Removed code that removes linked refs. Unnecesary.
		kGroupList[iCounter].Delete()
		iCounter += 1
	
	endwhile
	
	kGroupList.Clear()
	ThreadController.IncrementActiveNpcCount(-iSize)
	
EndFunction

;-------------------------------------------------------------------------------------------------------------------------------------------------------
