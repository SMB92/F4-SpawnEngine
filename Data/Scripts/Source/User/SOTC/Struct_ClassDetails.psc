Scriptname SOTC:Struct_ClassDetails extends ScriptObject
{Base Struct definition for use with Actor Class values and presets}
;Written by SMB92.
;Special thanks to J. Ostrus [BigandFlabby] for making this mod possible.

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

Struct ClassDetailsStruct

Int iMaxAllowed
Int iMaxAllowedBoss
Int iChance
Int iChanceBoss

EndStruct

;------------------------------------------------------------------------------------------------

;NOTES: 
;iDiffculty setting was removed, this will be a per system, per region based setting now.
;iRerollMaxCount and iRerollChance were moved to the Master script. One setting for whole mod now.
;iAllowedClass moved to an Int array stored on Actor Preset.
;Encounter Zone settings moved to the Regional level (RegionalQuestScript).
;Removed bBossAllowed in version 0.06.02, now casting iChanceBoss to Bool. 
