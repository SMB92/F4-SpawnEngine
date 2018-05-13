Scriptname SOTC:ActorGroupLoadoutScript extends ObjectReference
{ Used to define a unique loadout of NPC variants for an Actor type. }
;Written by SMB92
;Special thanks to J. Ostrus [BigandFlabby] for code contributions that made this mod possible.

;This script is mostly storage for an array of ActorBase (LvlNPCs) that can be used to create custom
;squads/groups of NPCs to spawn. Can be used as many times as necessary and placed into multiple
;ClassPresetScript instances.

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

	ActorBase[] Property kGroupUnits Auto Const Mandatory
	{ Fill with ActorBase intended for this Actor Type and Class }

	ActorBase[] Property kBossGroupUnits Auto Const Mandatory
	{ Fill with ActorBase intended for this Actor Type and Class }

	Bool Property bHasPowerArmorUnits Auto Const Mandatory
	{ If either ActorBase array above has PA Units, sets this true } 

	Bool[] Property iClassesToApply Auto Mandatory ;SEE NOTES BELOW Mandatory
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
	
EndGroup


Group Dynamic

	SOTC:ActorManagerScript Property ActorManager Auto
	{ Init None, filled at runtime by the Manager. }
	
EndGroup


Bool bInit ;Security check to make sure Init events/functions don't fire again while running


;------------------------------------------------------------------------------------------------
;INITIALISATION FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

;DEV NOTE: Init events/functions now handled by Masters creating the instances.

;Manager passes self in to set instance when calling this
Function PerformFirstTimeSetup(SOTC:ActorManagerScript aActorManager)
	
	;DEV NOTE: ClassPresets must be Inited first, or this will fail to AddGroupToClassPresets
	
	if !bInit
		ActorManager = aActorManager
		ActorManager.GroupLoadouts.Add(Self, 1)
		AddGroupToClassPresets(true) ;PA units enabled by default.
		bInit = true
		
	endif

EndFunction

;Use this add this GroupLoadout script to as many Classes as desired/supported
Function AddGroupToClassPresets(Bool abAllowPowerArmorGroups)

	if (!bHasPowerArmorUnits) || (abAllowPowerArmorGroups) ;If doesn't OR assume does and parameter is true
	
		int iCounter = 1 ;MUST START AT ONE FOR THIS SCRIPT, INDEX 0 ON CLASSPRESETS IS ALWAYS NONE.
		;iCounter actually equals iClass
		int iSize = iClassesToApply.Length
		
		while iCounter < iSize
			
			if iClassesToApply[iCounter]
				ActorManager.ClassPresets[iCounter].GroupLoadouts.Add(Self)
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
