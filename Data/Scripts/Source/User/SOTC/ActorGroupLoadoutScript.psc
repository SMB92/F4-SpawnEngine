Scriptname SOTC:ActorGroupLoadoutScript extends ReferenceAlias
{ Group Variants array definition to be stored on ActorClassPresetScript. Using this
script we are able to define many variations of group loadouts. }
;Written by SMB92
;Special thanks to J. Ostrus [BigandFlabby] for code contributions that made this mod possible.

;This script is mostly storage for an array of ActorBase (LvlNPCs) that can be used to create custom
;squads/groups of NPCs to spawn. Can be used as many times as necessary and placed into multiple
;ClassPresetScript instances.

;NOTE: Alias order of GroupLoadouts vs ClassPresets is no longer an issue

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

SOTC:ActorQuestScript Property ActorScript Auto Const
{ Fill with intended ActorQuest }

ActorBase[] Property kGroupUnits Auto Const
{ Fill with ActorBase intended for this Actor Type and Class }

ActorBase[] Property kBossGroupUnits Auto Const
{ Fill with ActorBase intended for this Actor Type and Class }

Bool Property bHasPowerArmorUnits Auto Const
{ If either ActorBase array above has PA Units, sets this true } 

Bool[] Property iClassesToApply Auto Const ;SEE NOTES BELOW
{ Initialise members True on index matching ID No. of Classes this group can be added to.
Set false for Classes not desired. Only add to Classes that exist for this Actor. }
;NOTE: THIRD PARTY MODS can modify this property directly if they want, but it is left Const so
;that the value will be updated upon a reshuffle.
;REFERENCE LEGEND - CLASSES
; [0] - NONE, LEAVE BLANK ALWAYS
; [1] - COMMON, REGULAR SPAWN CLASS
; [2] - UNCOMMON, REGULAR SPAWN CLASS
; [3] - RARE, REGULAR SPAWN CLASS
; [4] - AMBUSH CLASS
; [5] - SNIPER CLASS
;Note: Not all Actors have to support each Class. Fill accordingly.

Bool bInit ;Security check to make sure Init events don't fire again while running


;------------------------------------------------------------------------------------------------
;INITIALISATION FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

Event OnAliasInit()
	
	if !bInit
		ActorScript.GroupLoadouts.Add(Self, 1) ;New method.
		;To prevent Alias Fill order problems, this will now add itself to an array on the 
		;ActorQuestScript, which will initiate the AddGroupToClassPresets() function when ready.
		bInit = true
	endif

EndEvent

;Use this add this GroupLoadout script to as many Classes as desired/supported
Function AddGroupToClassPresets(Bool abAllowPowerArmorGroups)

	if (!bHasPowerArmorUnits) || (abAllowPowerArmorGroups) ;If doesn't OR assume does and parameter is true
	
		int iCounter = 1 ;MUST START AT ONE FOR THIS SCRIPT, INDEX 0 ON CLASSPRESETS IS ALWAYS NONE.
		;iCounter actually equals iClass
		int iSize = iClassesToApply.Length
		
		while iCounter < iSize
			
			if iClassesToApply[iCounter]
				ActorScript.ClassPresets[iCounter].GroupLoadouts.Add(Self)
			endif
			
			iCounter += 1
			
		endwhile

	endif
	
EndFunction

;------------------------------------------------------------------------------------------------
;RETURN FUNCTIONS
;------------------------------------------------------------------------------------------------

;Return one of the above Grouplists. Used rarely from this script, if at all. Best to get from
;ActorClassPresetScript functions instead (as that is passed directly to SpawnPoints anyway).
ActorBase[] Function GetGroupLoadout(bool abGetBossList)

	if !abGetBossList
		return kGroupUnits
	else
		return kBossGroupUnits
	endif
	
EndFunction

;------------------------------------------------------------------------------------------------
