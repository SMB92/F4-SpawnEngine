Scriptname SOTC:RegionPersistentDataScript extends ObjectReference
{ Stores all SpawnPoints, Travel Location Markers and EncounterZone arrays for a Region. }
;Written by SMB92
;Special thanks to J. Ostrus [BigandFlabby] for code contributions that made this mod possible.

;This script does not have to be instanced. Only tied to a MiscObject and accessed at runtime.
;All Properties here are constant. 

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
;DEV NOTE: As of version 0.13.01, all SpawnPoints are permanently persistent via storage on this
;script. The main reason is due to cell conflicts, altough regardless it was somewhat impossible
;to delete them at runtime anyway. 

;DEV NOTE 2: As of version 0.19.01 This script has changed to RegionPersistentDataStore. SP's and
;Travel locs for each Region will still be stored here, as well as EncounterZone arrays (the previous
;transfer of formlists method has been made redundant). As this implies, this is now a multi-instance
;script/object, one per Region. As it is not expected to Encounter heavy multi-thread traffic, all
;relevant Properties on RegionManager have been moved here. Any return functions will remain on the
;RegionManager for now. 

Group PersistentData

	SOTC:MasterQuestScript Property MasterScript Auto Const
	{ Fill with the MasterQuest }

	ObjectReference[] Property kTravelLocs Auto Const
	{ Fill with placed Travel Markers! }

	ObjectReference[] Property kSpawnPoints Auto Const
	{ Fill with placed SpawnPoints of any sort! }
	
EndGroup


Group EncounterZoneProperties
{EZ Properties and settings for this Region}

	EncounterZone[] Property kRegionLevelsEasy Auto Const
	{ Init with one member of None. Fills from Formlist on WorldManager. }

	EncounterZone[] Property kRegionLevelsHard Auto Const
	{ Init with one member of None. Fills from Formlist on WorldManager. }

	EncounterZone[] Property kRegionLevelsEasyNoBorders Auto Const
	{ Init with one member of None. Fills from Formlist on WorldManager. }

	EncounterZone[] Property kRegionLevelsHardNoBorders Auto Const
	{ Init with one member of None. Fills from Formlist on WorldManager. }
	
EndGroup


;------------------------------------------------------------------------------------------------
;SP RESET FUNCTIONS
;------------------------------------------------------------------------------------------------

;Called via the RegionManager. 
Function ResetAllActiveSps(Bool abForceReset) ;Only resets the active ones. 

	Int iSize
	Int iCounter
	
	while iCounter < iSize
	
		(kSpawnPoints[iCounter] as SOTC:SpawnPointScript).FactoryReset(abForceReset)
		iCounter += 1
	
	endwhile
	
EndFunction


;------------------------------------------------------------------------------------------------
