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

	Bool[] Property bClassesToApply Auto Mandatory ;SEE NOTES BELOW Mandatory
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
		
		Debug.Trace("ActorGroupLoadout Init completed")
		
	endif

EndFunction

;Use this add this GroupLoadout script to as many Classes as desired/supported
Function AddGroupToClassPresets(Bool abAllowPowerArmorGroups)

	if (!bHasPowerArmorUnits) || (abAllowPowerArmorGroups) ;If doesn't OR assume does and parameter is true
	
		int iCounter = 0
		;iCounter actually equals iClass
		int iSize = bClassesToApply.Length ;This array must have exact number of members as classes supported. 
		
		while iCounter < iSize
			
			if bClassesToApply[iCounter]
				ActorManager.ClassPresets[iCounter].GroupLoadouts.Add(Self)
				;If ActorManager does not have this class defined, this will fail and log an error.
				Debug.Trace("GroupLoadout added to ClassPreset")
				;DEV NOTE: Security checks could be placed here to remove first member of None
				;if present on ClassPreset's GroupLoadout arrays, however this may be the slower
				;option, therefore this check is being done on the calling functions after this.
				;It should be noted that if calling this from some other script (such as an addon)
				;care should be taken in regard to this.
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
