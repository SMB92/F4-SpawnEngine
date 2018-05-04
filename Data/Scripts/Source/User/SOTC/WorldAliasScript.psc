Scriptname SOTC:WorldAliasScript extends ReferenceAlias
{ Master script for each Worldspace supported. Links to Regions }
;Written by SMB92
;Special thanks to J. Ostrus [BigandFlabby] for code contributions that made this mod possible.

;Alias version of this script. Maybe better than using a whole new Quest
;UPDATE MARCH 2018 - Now using Alias on MasterQuest for WorldScript instances. Much better.

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

SOTC:MasterQuestScript Property MasterScript Auto Const
{ Fill with MasterQuest }

Int Property iWorldID Auto Const
{ Initialise with ID number of the World. Will be inserted on MasterScript array at this Index }

;LEGEND - WORLD IDs
; [0] - COMMONWEALTH
; [1] - FAR HARBOR
; [2] - NUKA WORLD

String Property sWorldName Auto Const
{ Fill with name of Worldspace. May be used to display. }

Quest[] Property Regions Auto
{ Init one member of None. Fills dynamically. }

Bool bInit ;Security check to make sure Init events don't fire again while running

;------------------------------------------------------------------------------------------------
;INITIALISATION EVENTS
;------------------------------------------------------------------------------------------------

Event OnAliasInit()
	
	if !bInit
		MasterScript.Worlds.Insert(Self, iWorldID) ;Pass as this script, not Quest
		bInit = true
	endif
		
EndEvent

;------------------------------------------------------------------------------------------------
;RETURN FUNCTIONS
;------------------------------------------------------------------------------------------------

;Exists for if need be. 
Quest Function GetRegionInstance(int aiRegionID)

	return Regions[aiRegionID]
	
EndFunction

;------------------------------------------------------------------------------------------------
