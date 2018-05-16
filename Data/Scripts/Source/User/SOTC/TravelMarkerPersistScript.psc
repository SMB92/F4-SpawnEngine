Scriptname SOTC:TravelMarkerPersistScript extends ObjectReference
{ Store all Travel Markers in arrays here, keeps them persistent. }
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

;This is just here to ensure this script initialises properly.
SOTC:MasterQuestScript Property MasterScript Auto Const
{ Fill with the MasterQuest }

ObjectReference[] Property kTravelMarkersList01 Auto Const
{ Fill with placed Travel Markers! }
ObjectReference[] Property kTravelMarkersList02 Auto Const
{ Fill with even more placed Travel Markers! }


;------------------------------------------------------------------------------------------------
