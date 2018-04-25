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
; "f,b,i" - The usual Primitives: Float, Bool, Int.

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
	;"Rarity" defined for that area). They are as follows: (subject to additional types)
	;(NOTE: It is possible for some Actors to be of "mixed" type and appear in multiple lists)
	; [0] - MAIN/MIXED RANDOM - consider this like "urban" spawns, the most common type used
	;This is essentially a random list of anything and everything that would be common enough 
	;to spawn in an area.
	; [1] - URBAN - Minimal Wildlife
	; [2] - WILD - Common wild area stuff
	; [3] - RADSPAWN - Radiated areas spawns
	; [4] - HUMAN
	; [5] - MUTANT
	; [6] - WILDLIFE
	; [7] - INSECT
	; [8] - MONSTER
	; [9] - ROBOT
	; [10] - AQUATIC - Given the lack of real Aquatic spawns, this includes other things that
	;might appear in swamp/marsh/waterside etc.
	; [11] - SNIPER - This end up warranting it's own category. This is also a "Class". Any Actor type
	;that has this Class defined will be featured in this Spawntype.
	; [12] - STORY - Story Mode/Actors will not appear in the initial beta and is subject to feedback.
	;The following were dropped from being a Spawntype:
	; AMBUSH - This is still a "Class". Reasoning is that one can define specific parameters and group
	;loadouts in order to create highly customised Ambushes
	; INFESTATION/SWARM - THis has evolved into a Feature, and while bonus params can still be defined
	;on the ActorScript, it is no longer a Spawntype and can now happen at anytime (when setting active)

	String Property sSpawnTypeString Auto
	{ Fill with defining string for this SpawnType }

	SOTC:ActorQuestScript[] Property ActorLibrary Auto
	{ Initialiase with one member of None, fills dynamically }

EndGroup


;------------------------------------------------------------------------------------------------
;INITIALISATION EVENTS
;------------------------------------------------------------------------------------------------

Event OnAliasInit()

	MasterScript.SpawnTypeMasters.Insert(self, iSpawnTypeID)
	
EndEvent

;------------------------------------------------------------------------------------------------
;RETURN FUNCTIONS
;------------------------------------------------------------------------------------------------

;In the event we want to grab an Actor from this Master, we use this. 
SOTC:ActorQuestScript Function GetRandomActor()

	Int iSize = (ActorLibrary.Length) - 1 ;Get actual index count
	
	return ActorLibrary[(Utility.RandomInt(0,iSize))] ;return 1 random Actor(Quest)
	
EndFunction

;------------------------------------------------------------------------------------------------
