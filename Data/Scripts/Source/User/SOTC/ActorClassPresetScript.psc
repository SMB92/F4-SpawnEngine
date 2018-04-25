Scriptname SOTC:ActorClassPresetScript extends ReferenceAlias
{ Property holder for each SOTC Class supported by an Actor }
;Written by SMB92
;Special thanks to J. Ostrus [BigandFlabby] for code contributions that made this mod possible.

;This script is used to define spawn parameters for an Actor, based on a "Class". A "Class" is
;effectively a control method to define what settings to spawn an Actor with. For example Classes
;are used to define Regional Rarity spawn parameters, giving Actors different settings based on
;how dominant or likely they are to appear in that area. A Class is simply storage of parameters.

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

import SOTC:Struct_ClassDetails

SOTC:ActorQuestScript Property ActorScript Auto Const
{ Link to the owning Actor Quest }

Int Property iClassID Auto Const
{ Fill with intended Class ID }
;LEGEND - CLASSES
; [0] - NONE, DO NOT USE
; [1] - COMMON RARITY
; [2] - UNCOMMON RARITY
; [3] - RARE RARITY
; [4] - AMBUSH
; [5] - SNIPER
	
ClassDetailsStruct[] Property ClassDetails Auto
{ Fill with appropriate values for this Class. Each member represents Difficulty level (0-4) }
;LEGEND - DIFFICULTY LEVELS
;Same as Vanilla. Only in Bethesda games does None = 4 (value 4 is "No" difficulty, scale to player)
; 0 - Easy
; 1 - Medium
; 2 - Hard
; 3 - Very Hard ("Veteran" in SOTC)
; 4 - NONE - Scale to player.

SOTC:ActorGroupLoadoutScript[] Property GroupLoadouts Auto
{ Initialise one member of None. Fills dynamically }

Bool bInit ;Security check to make sure Init events don't fire again while running


;------------------------------------------------------------------------------------------------
;INITIALISATION FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

Event OnAliasInit()
	
	if !bInit
		ActorScript.ClassPresets.Insert(Self, iClassID)
		bInit = true
	endif
	
EndEvent


;Will remove any GroupLoadouts containing PA Units (bHasPowerArmorUnits bool check)
Function RemovePowerArmorGroups()

	Int iCounter
	Int iSize = GroupLoadouts.Length
	
	while iCounter < iSize
	
		if GroupLoadouts[iCounter].bHasPowerArmorUnits ;If true
			GroupLoadouts.Remove(iCounter, 1) ;Remove that member
		endif
		
	endwhile
	
EndFunction


;------------------------------------------------------------------------------------------------
;RETURN FUNCTIONS
;------------------------------------------------------------------------------------------------

;This function return a single group loadout for spawning (ActorBase[] version)
ActorBase[] Function GetRandomGroupLoadout(bool abGetBossList)

	Int iSize

	if !abGetBossList
	
		iSize = GroupLoadouts.Length - 1
		return GroupLoadouts[(Utility.RandomInt(0,iSize))].kGroupUnits
		
	else
		
		iSize = GroupLoadouts.Length - 1
		return GroupLoadouts[(Utility.RandomInt(0,iSize))].kBossGroupUnits
		
	endif
	
EndFunction


;This function return a single group loadout for spawning (Script Instance version)
;Mostly unused, but exists if needed
ActorGroupLoadoutScript Function GetRandomGroupScript(bool abGetBossList)

	Int iSize

	if !abGetBossList
	
		iSize = GroupLoadouts.Length - 1
		return GroupLoadouts[(Utility.RandomInt(0,iSize))]
		
	else
		
		iSize = GroupLoadouts.Length - 1
		return GroupLoadouts[(Utility.RandomInt(0,iSize))]
		
	endif
	
EndFunction

;------------------------------------------------------------------------------------------------

;DEV NOTE: There is another method that I could have used to do what I'm doing with this script,
;however I abandoned it in favor of simplicity for third party modders. The other method would be
;as follows:
; 1. On ActorQuestScript, have an array of ClassDetailsStruct, add a new member "GroupLoadoutsList"
; 2. Change this script to only hold an array of "GroupLoadoutsScript"
; 3. Same method as here for group loadouts.
;I deem this potentially too confusing for modders. With the current method, if it is decided to
;add a new "class", everything can be done from this one script. 
