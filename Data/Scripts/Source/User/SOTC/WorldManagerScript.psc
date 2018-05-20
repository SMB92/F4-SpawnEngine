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
	
	MiscObject Property kRegionManagerObject Auto Const Mandatory
	{ RegionManagerScript base objects }
	
	Formlist[] Property kRegionEzLists_Easy Auto Const
	{ Fill each member with the Formlist of EncounterZones for the corresponding Region. } 
	Formlist[] Property kRegionEzLists_Hard Auto Const
	{ Fill each member with the Formlist of EncounterZones for the corresponding Region. }
	Formlist[] Property kRegionEzLists_EasyNoBorders Auto Const
	{ Fill each member with the Formlist of EncounterZones for the corresponding Region. }
	Formlist[] Property kRegionEzLists_HardNoBorders Auto Const
	{ Fill each member with the Formlist of EncounterZones for the corresponding Region. }
	
EndGroup


Group Dynamic

	SOTC:RegionManagerScript[] Property Regions Auto
	{ Init a member of None for as many Regions intneded for this World. Sets dynamically. }
	
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
		Int iSize = Regions.Length ;Must be initialised with as many members of None as there are going to be Regions.
		
		Debug.Trace("World initialising")
		
		while iCounter < iSize
		
			kNewInstance = akMasterMarker.PlaceAtMe(kRegionManagerObject, 1 , false, false, false)
			(kNewInstance as SOTC:RegionManagerScript).PerformFirstTimeSetup(Self, aThreadController, akMasterMarker, \ 
			iWorldID, iCounter, aiPresetToSet, kRegionEzLists_Easy[iCounter], kRegionEzLists_Hard[iCounter], \
			kRegionEzLists_EasyNoBorders[iCounter], kRegionEzLists_HardNoBorders[iCounter])
			
			iCounter += 1
			
		endwhile
		
		bInit = true
		
		Debug.Trace("World initialised")
		
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
