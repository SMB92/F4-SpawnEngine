Scriptname SOTC:Struct_ClassDetails extends ScriptObject
{Base Struct definition for use with Actor Class values and presets}
;Written by SMB92.
;Special thanks to J. Ostrus [BigandFlabby] for making this mod possible.

;------------------------------------------------------------------------------------------------
;PROPERTIES & IMPORTS
;------------------------------------------------------------------------------------------------

Struct ClassDetailsStruct

bool bAllowBoss
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
