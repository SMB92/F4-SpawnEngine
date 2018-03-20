## SOTC - Script Source Inventory

**1. Global/Definition Scripts (Unattached)**
* Struct_ClassDetails (extends ScriptObject)
* Struct_RegionPresetDetails (extends ScriptObject)
-------------------------------------------------------


**2. Master Level Scripts (Attached to the Master Quest)**
* AuxilleryQuestScript (extends Quest)
* MasterQuestScript (extends Quest)
* ThreadControllerScript (extends RefAlias)
* WorldAliasScript (extends RefAlias)
* SpawnTypeMasterScript (extends RefAlias)
-------------------------------------------------------
 
 
**3. Region Level Scripts (Attached to each Region Quest)**
* RegionQuestScript (extends Quest)
* RegionTrackerScript (extends RefAlias)
* SpawnTypeRegionalScript (extends RefAlias)
-------------------------------------------------------


**4. Actor Level Scripts (Attached to each Actor Quest)**
* ActorQuestScript (extends Quest)
* ActorWorldPresetsScript (extends RefAlias)
* ActorClassPresetsScript (extends RefAlias)
* ActorGroupLoadoutScript (extends RefAlias)
-------------------------------------------------------
 
 
**5. Spawnpoint Scripts (Attached to Activators)**
* SpGroupScript (extends ObjectRef)
* SpHelperScript (extends ObjectRef)
-------------------------------------------------------


**6. Feature Scripts (Attached to various)**
* RR_ControllerQuestScript (extends Quest)
* RR_DynamicAliasScript (extends RefAlias)
* SpSevenDaysScript (extends ObjectRef)
-------------------------------------------------------


**7. Terminal Fragments**

-------------------------------------------------------
