Scriptname SOTC:ActorClassPresetScript extends ObjectReference
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
; "f,b,i,s" - The usual Primitives: Float, Bool, Int, String.

;------------------------------------------------------------------------------------------------
;PROPERTIES & IMPORTS
;------------------------------------------------------------------------------------------------

import SOTC:Struct_ClassDetails


Group Primary

	Int Property iClassID Auto Const Mandatory
	{ Fill with intended Class ID (Will become index on ClassPresets array on ActorManagerScript).
	Member 0 is used for debug, set only one ClassDetails struct member on this one. }

	;LEGEND - CLASSES
	; [0] - DEBUG AS OF VERSION 0.06.02.180506
	; [1] - COMMON RARITY
	; [2] - UNCOMMON RARITY
	; [3] - RARE RARITY
	; [4] - AMBUSH - RUSH (Wait for and rush the player)
	; [5] - AMBUSH - STATIC (for "hidden" ambushes such as Mirelurks and Molerats)
	; [6] - SNIPER
	; [X] - SWARM/INFESTATION (no need to actually define a Class!)
	; [X] - STAMPEDE (no need to actually define a Class!)

	;NOTE: See "CLASSES VS SPAWNTYPES" commentary of the SpawnTypeMasterScript for more in-depth info
		
	ClassDetailsStruct[] Property ClassDetails Auto Mandatory
	{ Fill member 0 (debug) with 100% chance values and balanced MaxCounts. Init and fill members 1-3 with balanced values. }

	;LEGEND - PRESETS
	; [1] SOTC ("Spawns of the Commonwealth" default) - Easiest, suit vanilla/passive player.
	; [2] WOTC ("War of the Commonwealth") - Higher chances of spawns and group numbers etc.
	; [3] COTC (Carnage of the Commonwealth") - What it says on the tin.

	;LEGEND - DIFFICULTY LEVELS
	;Same as Vanilla. Only in Bethesda games does None = 4 (value 4 is "No" difficulty, scale to player)
	;Only affects this mod. 
	; 0 - Easy
	; 1 - Medium
	; 2 - Hard
	; 3 - Very Hard ("Veteran" in SOTC)
	; 4 - NONE - Scale to player.
	
EndGroup


Group Dynamic

	SOTC:ActorManagerScript Property ActorManager Auto
	{ Init None, filled at runtime by the Manager. }

	SOTC:ActorGroupLoadoutScript[] Property GroupLoadouts Auto
	{ Initialise one member of None. Fills dynamically. }

EndGroup


Bool bInit ;Security check to make sure Init events/functions don't fire again while running


;------------------------------------------------------------------------------------------------
;INITIALISATION FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

;DEV NOTE: Init events/functions now handled by Masters creating the instances.

;Manager passes self in to set instance when calling this
Function PerformFirstTimeSetup(SOTC:ActorManagerScript aActorManager) 
	
	if !bInit
		
		ActorManager = aActorManager
		ActorManager.ClassPresets[iClassID] = Self
		bInit = true
		
		Debug.Trace("ActorClassPreset Init completed")
		
	endif
	
EndFunction


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


Function SafelyClearGroupLoadouts()

	GroupLoadouts.Clear()
	GroupLoadouts = new SOTC:ActorGroupLoadoutScript[1]
	
EndFunction

	

;------------------------------------------------------------------------------------------------
;RETURN FUNCTIONS
;------------------------------------------------------------------------------------------------

;This function returns a single group loadout for spawning (ActorBase[] version)
ActorBase[] Function GetRandomGroupLoadout(bool abGetBossList)

	Int iSize

	if !abGetBossList
	
		iSize = GroupLoadouts.Length - 1 ;Get actual index count
		return GroupLoadouts[(Utility.RandomInt(0,iSize))].kGroupUnits
		
	else
		
		iSize = GroupLoadouts.Length - 1 ;Get actual index count
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
