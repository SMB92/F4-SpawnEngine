Scriptname SOTC:SpawnTypeMasterScript extends ObjectReference
{ This script holds the Master Actor lists for a SpawnType. }
;Written by SMB92.
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

	SOTC:ActorManagerScript[] Property ActorList Auto
	{ Initialiase with one member of None, fills dynamically }
	
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


;LEGEND - CLASSES VS SPAWNTYPES
;As described in the commentary for Spawntypes, a Spawntype is essentially a category of spawns,
;and the respective scripts for them hold a list of Actor types allowed. Classes on the other hand
;are Presets for actors, based on how we are spawning them. The term "Classes" is obviously mis-
;leading, but I couldn't come up with a better word. These Classes store information on max count
;per group, how much chance each Actor in the group has to spawn (this is how we get dynamic group
;numbers) and what "GroupLoadouts" (a specified list of NPC types) that will be used when spawning.
;Some Spawntypes are what I call "Class-Based" as they fill their lists based on some information
;stored on the ActorQuest for each Actor type, such as whether they are allowed to appear in systems
;(like the Random Swarms/Infestations, Stampedes, Ambushes (static or rush the player) etc ), or
;whether they have a certain Class defined (such as the Sniper Class). As SpawnEngine also uses a
;"Rarity" based system for Regions (defines if an Actor is Common, Uncommon or Rare in a Region),
;there are three Classes (index 1-3 on ClassDetails struct property) dedicated to each Rarity level.
;Again, this is simply a preset of information. Actors do not have to have Classes defined for the
;Classes they don't need, as long as all defined Classes have the correct ID number assigned as per
;the list of Classes, this will just work. 


Bool bInit ;Security check to make sure Init events/functions don't fire again while running


;------------------------------------------------------------------------------------------------
;INITIALISATION EVENTS
;------------------------------------------------------------------------------------------------

;DEV NOTE: Init events/functions now handled by Masters creating the instances.

Function PerformFirstTimeSetup(Int aiSpawnTypeID)
	
	if !bInit
		
		iSpawnTypeID = aiSpawnTypeID
		MasterScript.SpawnTypeMasters[iSpawnTypeID] = Self
		SetBaseClassIfRequired()
		bInit = true
		
		Debug.Trace("SpawnTypeMaster creation complete")
		
	endif
	
EndFunction


;Added in version 0.12.01, only called on the "Master" instance (index 0).
;Inits ActorList array to be exact amount of Actors supported by mod. 
Function InitMasterActorList(Int aiNumOfActors)

	ActorList = new SOTC:ActorManagerScript[aiNumOfActors]
	
EndFunction


;Associates the Class of this Spawntype of it is based on one, on first time setup.
Function SetBaseClassIfRequired()

	if iSpawnTypeID == 11 ;Ambush(Rush)
		iBaseClassID = 4
	elseif iSpawnTypeID == 12 ;Snipers
		iBaseClassID == 5
	endif
	;SpawnTypes 13 & 14 (Swarm/Rampage) do not have Class Presets, so they do not get defined. 
	
EndFunction


;Used for non-master instances.
Function SafelyClearActorList()

	ActorList.Clear()
	ActorList = new SOTC:ActorManagerScript[1]
	
EndFunction


;Prepares this instance for destruction by Master
Function MasterFactoryReset()

	if iSpawnTypeID == 0 ;Master List Mode
	
		Int iCounter
		Int iSize = ActorList.Length
		
		while iCounter < iSize
			
			if ActorList[iCounter] != None ;Check for empty indexes.
				ActorList[iCounter].MasterFactoryReset()
				ActorList[iCounter].Disable()
				ActorList[iCounter].Delete()
				ActorList[iCounter] = None ;De-persist
				Debug.Trace("ActorManager instance destroyed")
			endif
			iCounter += 1

		endwhile
		
		Debug.Trace("All ActorManager instances destroyed, STM ready for destruction")
	
	else ;Non-Master mode
	
		ActorList.Clear()
		Debug.trace("SpawnTypeMaster ready for destruction")
		
	endif
	
	;Master will destroy this instance once this returns
	
EndFunction


;------------------------------------------------------------------------------------------------
;RETURN FUNCTIONS
;------------------------------------------------------------------------------------------------

;In the event we want to grab an Actor from this Master, we use this. 
SOTC:ActorManagerScript Function GetRandomActor()

	Int iSize = (ActorList.Length) - 1 ;Get actual index count
	
	return ActorList[(Utility.RandomInt(0,iSize))] ;return one random ActorManagerScript
	
EndFunction

;------------------------------------------------------------------------------------------------
