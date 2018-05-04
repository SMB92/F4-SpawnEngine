Scriptname SOTC:AuxilleryQuestScript extends Quest
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

Quest Property SOTC_MasterQuest Auto Const
{ Auto-fills }

Holotape Property SOTC_AuxMenuTape Auto Const
{ Auto-Fills with AuxMenuTape }

Quest[] Property ActorQuests Auto
{ Fill with all default Actor Quests. Index order is not essential. }

Quest[] Property RegionQuests Auto
{ Fill with all default Region Quests. Index order is not essential. }

GlobalVariable Property SOTC_MasterGlobal Auto Const
{ Auto-fill. IO status of mod }

GlobalVariable Property SOTC_Global_MenuSettingsMode Auto Const
{ Auto-fill }

;Int the default mod, there won't be more than 128 of either of the above, so therefore using arrays
;here is okay. Addons should have their own auxillery controller. 

;Variables
;----------

Bool bInit ;Security measure to ensure OnInit() etc events never fire twice

Bool bSpawnEngineStarting ;Security measure to be sure we want to start

;Unlike the MasterQuestScript, we won't have a permanent link to player here. 

;------------------------------------------------------------------------------------------------
;INITIALISATION FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

;No need to use a stage fragment.
Event OnQuestInit()

	if !bInit
		bInit == true ;Never want to receive this event again.
		Game.GetPlayer().AddItem(SOTC_AuxMenuTape, 1, false) ;We want to know it's been added
	endif
	
EndEvent

;------------------------------------------------------------------------------------------------
;SOTC AUXILLERY FUNCTIONS & EVENTS
;------------------------------------------------------------------------------------------------

;Get ready to start the Main Mod
Function PrepareToInitSpawnEngine()

	bSpawnEngineStarting = true ;Security measure to be sure we want to start
	SOTC_Global_MenuSettingsMode.SetValue(10.0) ;Lock menu. 
	RegisterForMenuOpenCloseEvent("PipboyMenu") ;Quests cannot start in menu mode, so we register
	;for the menu exit event before starting quests. Same applies to starting Timers.	

EndFunction


;Really start the main mod
Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)

	if (asMenuName == "PipboyMenu") && (!abOpening) && (bSpawnEngineStarting)
	
		Game.GetPlayer().RemoveItem(SOTC_AuxMenuTape, 1, true) ;Silently remove
		InitSpawnEngine()
		;UnregisterForAllMenuOpenCloseEvents() ;Calling Stop in above function call instead.
		
	endif
	
EndEvent


Function InitSpawnEngine()

	SOTC_MasterQuest.Start()
	
	int iCounter = 0
	;Init ActorQuests first
	int iSize = ActorQuests.Length
	
	while iCounter < iSize
	
		ActorQuests[iCounter].Start()
		Utility.Wait(0.2) ;Allowing a small amount of time to Init
		iCounter += 1

	endwhile

	iCounter = 0 ;Reset ready for next loop
	iSize = RegionQuests.Length
	
	while iCounter < iSize
	
		RegionQuests[iCounter].Start()
		Utility.Wait(0.2) ;Allowing a small amount of time to Init
		iCounter += 1

	endwhile
	
	;DEV NOTE: This script will need to be updated to include Random Event framework Quests
	
	Debug.MessageBox("SpawnEngine is now initialised. You will need to set a Preset in order to complete setup. Until you do this, no spawns will occur. Instructions are included in the Holotape Menu that has been added to your inventory.")
	
	SOTC_Global_MenuSettingsMode.SetValue(1.0) ;Put menu into first start state
	
	(Self as Quest).Stop() ;Shutdown this auxillery quest. 
	
EndFunction

;------------------------------------------------------------------------------------------------
