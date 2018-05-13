Scriptname SOTC:WorldManagerScript extends ObjectReference
{ Master script for each Worldspace supported. Links to Regions }
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
	
	MiscObject[] Property kRegionManagerObjects Auto Const Mandatory
	{ RegionManagerScript base objects }
	
EndGroup


Group Dynamic

	SOTC:RegionManagerScript[] Property Regions Auto
	{ Init one member of None. Fills dynamically. }
	
EndGroup


Bool bInit ;Security check to make sure Init events/functions don't fire again while running

;------------------------------------------------------------------------------------------------
;INITIALISATION EVENTS
;------------------------------------------------------------------------------------------------

;DEV NOTE: Init events/functions now handled by Masters creating the instances.

Function PerformFirstTimeSetup(SOTC:ThreadControllerScript aThreadController, ObjectReference akMasterMarker, Int aiPresetToSet)
	
	if !bInit	
		
		MasterScript.Worlds[iWorldID] = Self
		
		;Create all RegionManager instances, initialising each of them as we go.
		ObjectReference kNewInstance
		Int iCounter
		Int iSize = kRegionManagerObjects.Length
		
		while iCounter < iSize
		
			kNewInstance = akMasterMarker.PlaceAtMe(kRegionManagerObjects[iCounter], 1 , false, false, false)
			(kNewInstance as SOTC:RegionManagerScript).PerformFirstTimeSetup(Self, aThreadController, akMasterMarker, aiPresetToSet)
			
			iCounter += 1
			
		endwhile
		
		bInit = true
		
	endif
		
EndFunction

;------------------------------------------------------------------------------------------------
;RETURN FUNCTIONS
;------------------------------------------------------------------------------------------------

;Exists for if need be. 
SOTC:RegionManagerScript Function GetRegionInstance(int aiRegionID)

	return Regions[aiRegionID]
	
EndFunction

;------------------------------------------------------------------------------------------------
