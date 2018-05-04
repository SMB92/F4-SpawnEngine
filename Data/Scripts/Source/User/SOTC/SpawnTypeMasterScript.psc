Scriptname SOTC:SpawnTypeMasterScript extends ReferenceAlias
{ This script holds the Master Actor lists for a SpawnType. Attach to an Alias on MasterQuest }
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

Group PrimaryProperties

	SOTC:MasterQuestScript Property MasterScript Auto Const
	{ Fill with MasterQuest }

	Int Property iSpawnTypeID Auto
	{ Fill with intended SpawnType ID No. }
	
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

	String Property sSpawnTypeString Auto
	{ Fill with defining string for this Spawntype }

	SOTC:ActorQuestScript[] Property ActorLibrary Auto
	{ Initialiase with one member of None, fills dynamically }

EndGroup

Bool bInit ;Security check to make sure Init events don't fire again while running


;------------------------------------------------------------------------------------------------
;INITIALISATION EVENTS
;------------------------------------------------------------------------------------------------

Event OnAliasInit()
	
	if !bInit
		MasterScript.SpawnTypeMasters.Insert(self, iSpawnTypeID)
		bInit = true 
	endif
	
EndEvent

;------------------------------------------------------------------------------------------------
;RETURN FUNCTIONS
;------------------------------------------------------------------------------------------------

;In the event we want to grab an Actor from this Master, we use this. 
SOTC:ActorQuestScript Function GetRandomActor()

	Int iSize = (ActorLibrary.Length) - 1 ;Get actual index count
	
	return ActorLibrary[(Utility.RandomInt(0,iSize))] ;return one random ActorQuestScript
	
EndFunction

;------------------------------------------------------------------------------------------------
