Scriptname SOTC:ActorWorldPresetsScript extends ReferenceAlias
{ This script is a central point of holding ActorRegionPresetScripts for each World }
;Written by SMB92
;Special thanks to J. Ostrus [BigandFlabby] for code contributions that made this mod possible.

;Stores Preset values for each Region, for each major mod Preset.
;This script no longer uses 3 other script instances to store these values, instead using this one
;script instance only, with 3 arrays. Therefore, the 3 "major Preset" limit is hardcoded.

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

	SOTC:ActorQuestScript Property ActorScript Auto Const
	{ Link to the owning ActorQuest, fill with this }

	Int Property iWorldID Auto Const
	{ Initialise with ID of the World intended }
	; LEGEND - WORLDS
	; [0] - COMMONWEALTH
	; [1] - FAR HARBOR
	; [2] - NUKA WORLD
	; [3] - NEW VEGAS

EndGroup


Group RegionPresets
{Int arrays defining Preset for this Actor in each Region. 3 Lists available, one
for each Preset. Limit of 3 Presets is hardcoded}

	Int[] Property iRegionPresetsP1 Auto
	{ Initialise with Int between 0-3, with as many members as Regions for this World }

	Int[] Property iRegionPresetsP2 Auto
	{ Initialise with Int between 0-3, with as many members as Regions for this World }

	Int[] Property iRegionPresetsP3 Auto
	{ Initialise with Int between 0-3, with as many members as Regions for this World }

EndGroup

;DEV NOTE: Checks must be implemented properly if an Actor has no World/Region Preset defined. First
;check will compare the size of the array to the iWorldID, this will ensure the array has enough
;members that it actually includes the World, then the second check will be for "none" which will
;ensure a preset is defined or not for the requested iRegionID.

;------------------------------------------------------------------------------------------------
;INITIALISATION EVENTS
;------------------------------------------------------------------------------------------------

Event OnAliasInit()

	ActorScript.WorldPresets.Insert(Self, iWorldID)
	
EndEvent

;------------------------------------------------------------------------------------------------
;RETURN FUNCTIONS
;------------------------------------------------------------------------------------------------

;Return entire World Regions preset list. Not used in default, exists if needed
Int[] Function GetActorRegionPresetList(int aiPresetToGet)
	
	if aiPresetToGet == 1
		return iRegionPresetsP1 ;SOTC Preset
	elseif aiPresetToGet == 2
		return iRegionPresetsP2 ;WOTC Preset
	elseif aiPresetToGet == 3
		return iRegionPresetsP3 ;COTC Preset
	endif
	
EndFunction

;Return single Int value for specific Region
Int Function GetActorRegionPreset(int aiRegionID, int aiPresetToGet)
	
		if aiPresetToGet == 1
		return iRegionPresetsP1[aiRegionID] ;SOTC Preset
	elseif aiPresetToGet == 2
		return iRegionPresetsP2[aiRegionID] ;WOTC Preset
	elseif aiPresetToGet == 3
		return iRegionPresetsP3[aiRegionID] ;COTC Preset
	endif
	
EndFunction

;------------------------------------------------------------------------------------------------
