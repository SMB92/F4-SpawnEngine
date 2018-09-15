Scriptname SOTC:TravelLocScript extends ObjectReference
{ Quick and drity script that adds a Travel Location Marker to Regions dynamically on first setup. }
;Written by SMB92
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

	;Various Properties are obsoleted in version 0.19.01 as these are now tracked properly from editor. 
	
	ObjectReference[] Property kPropParents Auto Const
	{ Default value of None on each member. If using an Enable Parent object to enable any Props, fill this with any of those objects. The index of this
array correlates with the Integer ID on the GroupLoadout script as to the primary Race/Type of the Actor. ID's are: 0 = Always None (required for checks),
1 = Human (camp/furniture etc), 2 = SuperMutant (gore etc), 3 = Predator Mutant/Animal (dead bodies etc). If ID passed is None in this array, will be ignored. }

EndGroup

Bool bInit ;Security check to make sure Init events/functions don't fire again while running

Int iCurrentlyEnabledPropParent ;This will flag this point as having enabled "props" if not 0
;( meaning one of the enable parents above is enabled) instead of running latent checks. If one 
;set is enabled, another set cannot be enabled until the last activated has been disabled. 

;------------------------------------------------------------------------------------------------
;INIT FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

;OBSOLETED IN 0.19.01

;------------------------------------------------------------------------------------------------
;PROP FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------
;As of version 0.19.01, functionality has been given to enable "props" from the travel marker.
;First SpawnPoint that calls it and successfully has a prop parent enabled here will deny all
;other SPs until the first is finished with it (so no more than one prop parent can be enabled
;at any one time). 

Function AttemptToEnableProps(Int aiType)

	if iCurrentlyEnabledPropParent > 0 && kPropParents[aiType] != None ;Deny if a parent is already active or doesn't exist
		kPropParents[aiType].Enable()
	endif
	
EndFunction


Function DisableProps()

	kPropParents[iCurrentlyEnabledPropParent].Disable()
	
EndFunction


;------------------------------------------------------------------------------------------------
