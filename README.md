# F4-SpawnEngine
*Fallout 4 Mod "SpawnEngine" aka "Spawns of the Commonwealth" by SMB92*

## NEWS

### SpawnEngine updated to version 0.07.01.180507

[07/05/2018] Major update to initialisation procedures.

### SpawnEngine updated to version 0.06.02.180506

[06/05/2018] Minor updates including debug features. 

### SpawnEngine updated to version 0.06.01.180504

[04/05/2018] New features and general housekeeping/optimization. See update logs below for detailed info. 

### First Public source released!

[25/04/2018] Dubbed version 0.05.00.180425, all current source scripts have been pushed to this hub. Documentation is currently limited to what I've commented into the scripts, and no ESP file has been comitted (although compiled scripts are currently present, just to show that the source is in working order). A Notepad++ Language file is provided on the main page, which highlights all current script types, variables thereof and all Function definitions. It also includes some missing vanilla syntax. 

Please be patient while work continues on both a working test file and official documentation.

## UPDATES

##### [07/05/2018] SpawnEngine updated to version 0.07.01.180507

###### HOUSEKEEPING:
- Updated NPP lang file to current version.
- Added comments to SpawnTypeRegionalScript ReshuffleDynActorLists() function on how to use from Menu. 

###### SCRIPT OPTIMIZATION & REVISION:
- Fairly large changes to initialisation procedures when the mod first starts. I must have been drunk when I wrote this. Changes significant enough to warrant minor version change. Streamlined this to be much more straightforward, added new functions, removed redundant/erroneous crap and fixed/compiled Preset terminal menu fragments. Shutdown events still not fully implemented. 
- Updated Random Events framework functions to better handle the kEventsPendingStart array (clearing it without leaving one member of None presents some problems in Papyrus) and also support starting events when the mod starts, properly.
- Removed SingleSpawnTypePresetUpdate event out of SpawnTypeRegionalScript and onto RegionQuestScript, changing it to be like the other preset update events. 

-------
##### [06/05/2018] SpawnEngine updated to version 0.06.02.180506

###### HOUSEKEEPING:
- Started Adding Mandatory flags to some properties. Might seem pointless but I find it useful.
- A couple spelling/grammar fixes in commentary. 
- Added Classes vs Spawntypes commentary that was missing from previous release. 

###### SCRIPT OPTIMIZATION & REVISION:
- Previously, ClassDetails[0] on ActorClassPresetsScript was unused along with the ClassPresets[0] on the ActorQuestScript (and commentary mentioned not to fill/ignore). These have now been converted to debug features, and should be defined for all Actors. Updated script descriptions/commentary accordingly.
- Removed redundant bAllowBoss flag from Struct_ClassDetailsStruct, instead we will now look at the iChanceBoss value (and cast to bool). Updated SpGroupScript and SpHelperScript accordingly.

-------
##### [04/05/2018] SpawnEngine updated to version 0.06.01.180504

###### HOUSEKEEPING:
- Corrected wrong version number in Github readme. Was 0.00.05, supposed to be 0.05.00.
- Updated Notepad++ lang file with some missing variables for scripts and arrays of and added new functions. 
- Corrected some bad commentary/grammar, removed some obsolete comments.

###### SCRIPT OPTIMIZATION & REVISION:
- Added missing bInit security flag to SpawntypeMasterScript
- Added missing bInit security flag to ActorWorldPresetsScript
- Added missing bInit security flag to WorldAliasScript
- Added missing bInit security flag to RR_ControllerQuestScript
- Added missing "a" prefix to some parameters
- Removed unnecessary check from SpawnTypeRegionalScript SingleUpdate Event block
- Fixed bad indentation in ActorWorldPresetScript
- Fixed variable name kEventPoint from bEventPoint on RegionQuestScript
- Removed obsolete GetRandomActor(s) functions from RegionQuestScript.
- Uncommented a function in GroupLoadouts script, while likely remaining unused it could still prove useful later
- Commented out Spawnpoint object arrays in RegionQuestScript. Currently not planning to track them in this way.
- Optimized SpawnTypeRegionScript GetRandomActor(s) functions by removing unnecessary bool check (now checks if Int is more than 0)
- Corrected SpawnTypeRegionalScript returning Common Actor instead of Uncommon Actor.
- Uncommented bSpawnWarningEnabled Property on MasterQUestScript and added a function that can be used by SPs. This will show the user 1 of 3 messages whenever a SpawnPoint fires nearby, such as "You hear distant movement"
- Updated ThreadController DisplayModStatus function to show active NPC and SP counts.
- Added MasterGlobal and iMenuSettingsMode Global to AuxilleryQuestScript so menu can lock properly and mod IO status update accordingly. 
- Added more generic Globals to the MasterScript for Menu use (now 10)
- Increased Master Event colldown timer to 5 minutes from 3.
- Fixed SevenDaysQuestScript startup. For some reason I must have gotten confused and coded this all wrong. Added functionality to Master to deal with pending/starting Event Quests after Pipboy is exited. 

###### MAJOR FEATURE UPDATES:
- Previously Class Presets were based on Difficulty, so the harder you set this, the more enemies etc you'd get. This undermined the purpose of the major Presets, so now it is based on major Presets. This cuts amount of presets per Class from 5 to 3. Updated scripts accordingly.
- Extended Spawntypes to now include Class-Based Spawntypes. While I tried to avoid making this necessary to lessen the number of properties overall, I was somewhat restricting the potential and making custom SpawnPoint code (such as the AmbushPoint) a bit more complex/less flexible. Now scripts can link directly to these Spawntype scripts and included Actors can take advantage of the "Rarity" system. The SpawnTypeRegionalScript has undergone some changes that will help it to identify if it's Class-Based and function accordingly, as previously it couldn't return any ClassPresets that weren't one of the "Rarity" based Classes. See the "Classes vs Spawntypes" in-script commentary for more in-depth information. 
- Furthermore, the Ambush Class was split into two - Ambush (Rush) and Ambush (Static). The former means the actor supports waiting in place and rushing the player when ready, and the latter is for the "hidden" type of ambush, such as buried Mirelurks, Roaches and Molerats. This allows the AmbushPoint to be configured for either type.
- Added new feature, Random Stampede. An extension of the random Swarm/Infestation mode, supported Actor types can now have a chance to stampede upon successful dice roll. This required a bit of modifcation to the SpGroupScript (main spawnpoint) as it requires a different package. Actors in this mode will receive a single travel location and run there, sandboxing on arrival. In general they will then prefer to run, which should somewhat emulate heard behaviours. Only works on exterior spawnpoints. Denies Random Ambush when active.

###### MISC NOTES:
- BeginSpawn functions on the included two Random Events helper points (Ghoul Apoc and SevenDaysToDie) remain incomplete until further work is done on the ESM. 
- Terminal "ConfirmPreset" subpages are not compiled pending an edit in ESM. 
