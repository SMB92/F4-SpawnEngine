Scriptname SOTC:AuxiliaryQuestScript extends Quest
{Ignition script for the main component}
;Written by SMB92
;Special thanks to J. Ostrus [BigandFlabby] for code contributions that made this mod possible.

;This script is attached is attached to the Auxillery Quest, which never stops while the mod is
;installed. The purpose is to act as an ignition script for the main component of the mod.

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

Quest Property SOTC_MasterQuest Auto Const Mandatory
{ Auto-fill. Will be cast to script type when necessary. }

Holotape Property SOTC_AuxMenuTape Auto Const Mandatory
{ Auto-Fills with AuxMenuTape. }

GlobalVariable Property SOTC_MasterGlobal Auto Const Mandatory
{ Auto-fill. IO status of mod. }

GlobalVariable Property SOTC_Global_MenuSettingsMode Auto Const Mandatory
{ Auto-fill. }

Quest Property MQ102 Auto Const Mandatory
{ Link to the game-start Quest. Checked upon Init, if player is in new game will defer start until exiting Vault, otherwise gives the tape straight away. }

;Variables
;----------

Int iPresetToSet ;Will be sent to MasterScript for Init.

Bool bInit ;Security measure to ensure OnInit() etc events never fire twice

Bool bSpawnEngineStarting ;Security measure to be sure we want to start

;Unlike the MasterQuestScript, we won't have a permanent link to player here. 

;------------------------------------------------------------------------------------------------
;INITIALISATION FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

;No need to use a stage fragment.
Event OnQuestInit()

	if !bInit
		
		if (MQ102.IsObjectiveCompleted(1))
			InitPreInstallState()
		else
			RegisterForRemoteEvent(MQ102, "OnStageSet")
		endif
		
		bInit == true ;Never want to receive this event again.
		
		;Debug.StartScriptProfiling("SOTC:MasterQuestScript")
		;Debug.StartScriptProfiling("SOTC:RegionManagerScript")
		;Debug.StartScriptProfiling("SOTC:SpawnTypeRegionalScript")
		;Debug.StartScriptProfiling("SOTC:ThreadControllerScript")
		;Debug.StartScriptProfiling("SOTC:AuxiliaryQuestScript")		
		
	endif
	
EndEvent


Event Quest.OnStageSet(Quest akSender, Int auiStageID, Int auiItemID)

	if (MQ102 == akSender) && (auiStageID == 10) ;Stage 10 is having left the Vault
		UnregisterForRemoteEvent(MQ102, "OnStageSet")
		InitPreInstallState()
	endif
	
EndEvent


Function InitPreInstallState()

	Utility.Wait(5.0) ;Wait 5 seconds for player to somewhat get their bearing after leaving vault. 
	Debug.MessageBox("Thank you for installing SpawnEngine. Please complete setup from the Auxiliary Holotape Menu that's been added to your inventory when ready.")
	Game.GetPlayer().AddItem(SOTC_AuxMenuTape, 1, false) ;We want to know it's been added

EndFunction


;------------------------------------------------------------------------------------------------
;SOTC AUXILLERY FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

;Get ready to start the Main Mod
Function PrepareToInitSpawnEngine(Int aiPresetToSet)
	
	iPresetToSet = aiPresetToSet
	bSpawnEngineStarting = true ;Security measure to be sure we want to start
	SOTC_Global_MenuSettingsMode.SetValue(10.0) ;Lock both menus (inc Master) ready for first setup
	RegisterForMenuOpenCloseEvent("PipboyMenu") ;Quests cannot start in menu mode, so we register
	;for the menu exit event before starting quests. Same applies to starting Timers.	

EndFunction


;Really start the main mod
Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)

	if (asMenuName == "PipboyMenu") && (!abOpening) && (bSpawnEngineStarting)
	
		UnregisterForAllMenuOpenCloseEvents()
		Game.GetPlayer().RemoveItem(SOTC_AuxMenuTape, 1, true) ;Silently remove
		InitSpawnEngine()

	endif
	
EndEvent


Function InitSpawnEngine()

	SOTC_MasterQuest.Start()
	
	Debug.Trace("MasterQuest started, performing setup")
	
	(SOTC_MasterQuest as SOTC:MasterQuestScript).PerformFirstTimeSetup(iPresetToSet)
	
	Debug.Trace("First time setup complete")
	
	bSpawnEngineStarting = false
	
	Debug.MessageBox("SpawnEngine is now initialised. Have fun!")
	
EndFunction


;Received from MasterQuest after MasterFactoryReset() has been called and data cleaned upon
Function FinaliseMasterFactoryReset()

	SOTC_MasterQuest.Stop()
	Game.GetPlayer().AddItem(SOTC_AuxMenuTape, 1, false) ;We want to know it's been added
	Debug.MessageBox("SpawnEngine has been factory reset. Uninstall option has opened on the Auxillery Menu. To restart the mod, follow the same procedure as first-installI. Should you decide to uninstall, please note that there is no guarantee your save will not be damaged.")

EndFunction


;Function UninstallSpawnEngine()

	;Currently incomplete, placeholder
	;PointPersistStore.DisableAllPersistentRefs()
	;SOTC_MasterGlobal.SetValue(3.0) ;Uninstalled state)
	;Disables all Persistent travel locations and SpawnPoints and their ChildPoints.
	
;EndFunction


;------------------------------------------------------------------------------------------------
