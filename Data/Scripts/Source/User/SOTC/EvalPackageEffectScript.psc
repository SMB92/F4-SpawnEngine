Scriptname SOTC:EvalPackageEffectScript extends ActiveMagicEffect
{ This script is applied to Actors on spawn and simply causes applied Package to Evaluate immediately in own thread. }
;Written by SMB92
;Special thanks to J. Ostrus [BigandFlabby] for code contributions that made this mod possible.

;LEGEND - PREFIX CONVENTION
; Variables and Properties are treated the same. Script types do not have prefixes, unless they
;are explicitly received as function arguments and are multi-instance scripts.
; "a" - (Function/Event Blocks only) Variable was received as function argument OR the variable
;was created from a passed-in Struct/Var[] member
; "k" - Is an "Form/Object" as usual, whether created in a Block or defined in the empty state/a state.
; "f,b,i,s" - The usual Primitives: Float, Bool, Int, String.


;------------------------------------------------------------------------------------------------
;FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------


Event OnEffectStart(Actor akTarget, Actor akCaster)

	GoToState("DoneState")
	akTarget.EvaluatePackage()
	
EndEvent
	

;------------------------------------------------------------------------------------------------
