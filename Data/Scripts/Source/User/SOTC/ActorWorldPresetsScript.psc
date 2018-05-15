Scriptname SOTC:ActorWorldPresetsScript extends ObjectReference
{ This script is a central point of holding ActorRegionPresetScripts for each World. }
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
; "f,b,i,s" - The usual Primitives: Float, Bool, Int, String.

;------------------------------------------------------------------------------------------------
;PROPERTIES & IMPORTS
;------------------------------------------------------------------------------------------------

Group Primary

	SOTC:MasterQuestScript Property MasterScript Auto Const Mandatory
	{ Fill with MasterQuest }

	Int Property iWorldID Auto Const Mandatory
	{ Init with ID of the intended World this preset script will cover. }
	; LEGEND - WORLDS
	; [0] - COMMONWEALTH
	; [1] - FAR HARBOR
	; [2] - NUKA WORLD
	; [3] - NEW VEGAS

EndGroup


Group Dynamic

	SOTC:ActorManagerScript Property ActorManager Auto
	{ Init None, filled at runtime by the Manager. }
	
EndGroup


Group RegionPresets
{ Int arrays defining the Preset for this Actor in each Region. 3 Lists available, one
for each Preset. Limit of 3 Presets is hardcoded because of this. }

	Int[] Property iRegionPresetsP1 Auto Mandatory
	{ Initialise with Int between 0-3, with as many members as Regions for this World. }

	Int[] Property iRegionPresetsP2 Auto Mandatory
	{ Initialise with Int between 0-3, with as many members as Regions for this World. }

	Int[] Property iRegionPresetsP3 Auto Mandatory
	{ Initialise with Int between 0-3, with as many members as Regions for this World. }

EndGroup

Bool bInit ;Security check to make sure Init events/functions don't fire again while running

;DEV NOTE: Checks must be implemented properly if an Actor has no World/Region Preset defined. First
;check will compare the size of the array to the iWorldID, this will ensure the array has enough
;members that it actually includes the World, then the second check will be for "none" which will
;ensure a preset is defined for the requested iRegionID.

;------------------------------------------------------------------------------------------------
;INITIALISATION EVENTS
;------------------------------------------------------------------------------------------------

;DEV NOTE: Init events/functions now handled by Masters creating the instances.

;Manager passes self in to set instance when calling this
Function PerformFirstTimeSetup(SOTC:ActorManagerScript aActorManager)
	
	if !bInit
	
		ActorManager = aActorManager
		ActorManager.WorldPresets[iWorldID] = Self
		bInit = true
		
		Debug.Trace("ActorWorldPreset +iWorldID setup complete for +ActorManager ")
		
	endif
	
EndFunction

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
