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
	
	MiscObject[] Property kRegionPersistentDataObjects Auto Const Mandatory
	{ Fill with each RegionPersistentDataStore base obejcts for each Region, in order. These do not have to be instanced. }
	
EndGroup


Group Dynamic

	SOTC:RegionManagerScript[] Property Regions Auto
	{ Init a member of None for as many Regions intended for this World. Sets dynamically. }
	
	;New in version 0.19.01, this contains all TravelLocs, EZ data and SpawnPoints for this Region. 
	
EndGroup


Bool bInit ;Security check to make sure Init events/functions don't fire again while running

;------------------------------------------------------------------------------------------------
;INITIALISATION FUNCTIONS& EVENTS
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
			
			Regions[iCounter] = (kNewInstance as SOTC:RegionManagerScript) ;Moved back here from RegionManager so thread doesn't have to bounce back and forth. 
			
			(kNewInstance as SOTC:RegionManagerScript).PerformFirstTimeSetup(Self, aThreadController, akMasterMarker, \ 
			iWorldID, iCounter, aiPresetToSet, kRegionPersistentDataObjects[iCounter])
			
			iCounter += 1
			
		endwhile
		
		bInit = true
		
		Debug.Trace("World initialised")
		
	endif
		
EndFunction


;Resets and destorys all Region instances
Function MasterFactoryReset()

	Int iCounter
	Int iSize = Regions.Length
	
	while iCounter < iSize
		Regions[iCounter].MasterFactoryReset()
		Regions[iCounter].Disable()
		Regions[iCounter].Delete()
		Regions[iCounter] = None ;De-persist.
		iCounter += 1
		Debug.Trace("Region instance destroyed")
	endwhile
	Debug.Trace("All Regions on World destroyed")
	
	;Master script will destroy this instance after this has returned. 
	
EndFunction
	

;------------------------------------------------------------------------------------------------
;RETURN FUNCTIONS
;------------------------------------------------------------------------------------------------

;Exists for if need be. 
SOTC:RegionManagerScript Function GetRegionInstance(int aiRegionID)

	return Regions[aiRegionID]
	
EndFunction

;------------------------------------------------------------------------------------------------
