Scriptname SOTC:Struct_RegionPresetDetails extends ScriptObject
{Base Struct definition for holding a Region Preset}
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

Struct RegionPresetDetailsStruct

Int iFeatureSwarmChance
Int iFeatureStampedeChance
Int iFeatureAmbushChance

EndStruct

;------------------------------------------------------------------------------------------------

;NOTES: 
;This struct should not include preset values for "Extra" features, only those that are intended
;for default modes. It also should not contain IO toggle for a Region.
;Spawntype toggles have been removed. They are all enabled by default. User must configure now.
