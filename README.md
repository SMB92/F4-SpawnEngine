# F4-SpawnEngine
*Fallout 4 Mod "SpawnEngine" aka "Spawns of the Commonwealth" by SMB92*

## NEWS

### Update 0.10.01.180513 fixes major design flaw, overhauled instancing methods, major changes to initialisation procedures.

[13/05/2018] Earlier last week I was preparing to drop an Alpha when I discovered that my design was hugely flawed by the fact that you cannot rely on ReferenceAliases to uniquely instance scripts. This was always a gamble I guess, however some false positives in some previous testing I did with this is what lead me down this road. I had spent so much time on focusing on scripts and functionality/features that I had not thought to check how this would work on this scale. In any case, I quickly moved to a way more reliable method of using dynamically instanced ObjectReferences (prefilled MiscObjects that will be instanced at runtime). As a result this update includes massive amounts of changes, but do know that the overall functionality/mechanics/gameplay has not really changed. See update log for more info. And yes Version 0.09.01 was skipped, this version tried another method of working with ALiases that lead to the same result. This version will not be posted as that method has been abandoned completely. 

### SpawnEngine updated to version 0.08.04.180509

[09/05/2018] Small fixes and tweaks

### SpawnEngine updated to version 0.08.03.180509

[09/05/2018] Rather critical patch to the Alpha, fixed AuxMenu terminal calling wrong function preventing proper mod startup.

### SpawnEngine updated to version 0.08.02.180508

[08/05/2018] Small additions and fixes

### SpawnEngine now in private Alpha testing, updated to version 0.08.01.180508

[08/05/2018] With the new "Mini" Spawnpoint script added and a few small changes/fixes to SpawnPoint features (such as ability to force difficulty), this version will now make the rounds as a private alpha test (no ESM present here yet). This marks a major milestone for me, now I can put a lot more focus on filling out the ESM file ready for public testing. 

### SpawnEngine updated to version 0.07.01.180507

[07/05/2018] Major update to initialisation procedures.

### SpawnEngine updated to version 0.06.02.180506

[06/05/2018] Minor updates including debug features. 

### SpawnEngine updated to version 0.06.01.180504

[04/05/2018] New features and general housekeeping/optimization. See update logs below for detailed info. 

### First Public source released!

[25/04/2018] Dubbed version 0.05.00.180425, all current source scripts have been pushed to this hub. Documentation is currently limited to what I've commented into the scripts, and no ESP file has been comitted (although compiled scripts are currently present, just to show that the source is in working order). A Notepad++ Language file is provided on the main page, which highlights all current script types, variables thereof and all Function definitions. It also includes some missing vanilla syntax. 

Please be patient while work continues on both a working test file and official documentation.

## UPDATE LOG

##### [13/05/2018] SpawnEngine updated to version 0.10.01.180513

###### HOUSEKEEPING:
- NPP language file updated to support new functions. Add missing vanilla function alias GetRef. Changed script type color to be paler.
- Added missing namespace to types on SpawnTypeRegionScript. Did not affect functionong, just good practice.
- Cleaned up some more property description and commentary. May still be some obsolete stuff left over after change over.
- Created new "Dynamic" Property grouping on scripts with dynamically set Primary properties for better organisation.

###### SCRIPT OPTIMIZATION/REVISION/FIXES:
- Added missing parameters to RR_ControllerScript for PlaceAtMe(), was using default true value for abDeleteWhenAble.
- Fixed CheckForEvents() function not checking if any Events were actually listed.
- Uncommented RegionTrackerScript SpMiniPoint detection/check for cleanup now that it is included.
- Added check to SetMenuSettingsMode function on MasterScript so that Menu doesn't kill first time setup function.
- Fixed broken setting of Menu Mode on first time startup. Added SetMenuModeCall to OnQuestOnit() on Master script.
- Fixed incomplete ResetSpentPointsLoop() on RegionTrackerScript
- Fixed wrong return and operator check from RegionSpawnCheck(), always denying SPs.
- Decided to remove kPackageKeywords as a property on the SpHelperScript and instead force pass them in. Not really a huge optimization but I didn't think it was necessary to store a list of all keywords permanently. There are now no permanent properties on this script.
- Removed SpawnTypeMasterScript Property from ActorManagerScript. Unnecessary
- Fixed array security function in wrong place on MasterScript, moved from AddActorToMasterSpawnTypes() to FillMasterActorLists()
- Removed ThreadController Property from Random Events. Currently unnecessary. Added MasterScript on helpers instead, can still access this from there.
- Changed all instances where Insert() was used to add objects/scripts dynamically as that call is not performed in serial (Papyrus queues the job, and executes out-of-order) which resulted in objects not being at their expected index as other members were being pushed around. 
- In all scripts where arrays needed to be initialised, cleared and reinitialised, I have added security measures to ensure arrays are (re)declared with one member of None, and that when they are populated that member will be destroyed. This should avoid None Array errors. New functions have been added where necessary in all applicable scripts, others altered to handle this. 
- InitResetGroupLoadouts() function changed to DistributeGroupLoadouts() - now safe as per the above.
- Added new SafelyRegisterEvent() function for Random Events framework to handle it's arrays also.

###### MAJOR/MINOR FEATURE UPDATES & ADDITIONS:
- [MAJOR] Major changes have occurred in this version, as the previous system was discovered not to work as I thought it would. No matter which method I tried, ReferenceAlias scripts could not be communicated with/manipulated as first thought, at least on the sheer scale the mod has become. It seems the first instance of a type could be, but the rest could not. This was somewhat to be expected and was a bit of a gamble to begin with. As a result I have changed over to the failsafe method of using reliable ObjectReferences in the form of (prefilled, scripted) MiscObjects which will be dynamically instanced on first install. There have been a number of changes to scripts to accomodate this, mostly with Init procedures, but the overall system has not changed drastically. Some optimizations were found in the process of refactoring, and some things got slightly slower, but overall no major damage as mentioned. Some notes as follows:
- As a result of new system, some properties and script names have changed. WorldAlias, ActorQuest and RegionQuest have become WorldManager, ActorManager and RegionManager, properties and variables thereof have changed to reflect this. Property ActorLibrary has now become ActorList (not sure why I chose that word to begin with).
- Manager/Master scripts will now create their required subclass instances on first time install, and have all had MiscObject properties added and a PerformFirstTimeSetup() function added to handle this in the right way. This function differs from script to script, some have different parameters to others, this is to speed things up during this process. <ost former alias scripts used as data containers have had their Init events replaced with the PeformFirstTimeSetup() function. There are basically no OnInit events of any sort in most scripts now. 
- SpawnPoint code was refactored for this system change, as they now have to fetch the script instances they need dynamically. New properties for IDs were added, which will be used to fetch the correct instances in a new function, SetSpScriptLinks() when needed. Random Events helper code udpated to dynamically grab the instances they need also.

###### MISC NOTES:
- Spawn function on RandomEvent helpers remain incomplete.
- Some holes are expected with new array security features. Will be plugged as necessary.
- Some commentary may still refer to older system. Will remove as discovered.
- A new method has been drawn up to safely update the mod while it is active in game. Drafts for this system have not been included in this update, but are being worked on.

##### [09/05/2018] SpawnEngine updated to version 0.08.04.180509

###### HOUSEKEEPING:
- Fixed spelling mistake in new Debug note on AuxQuestScript.
- Removed old AddTextReplacementData() call from MainMenu terminal fragment. This was left over from various tests and logging an error.

###### SCRIPT OPTIMIZATION/REVISION/FIXES:
- Increased Init timer on ActorQuestScript to 5 seconds to allow Aliases scripts a bit more time to do their thing.
- Converted arrays used for storing spent SpawnPoints from variables to arrays on RegionTrackerScript to avoid massive stack dumps from scripts being instanced before this was available. It is better the yare properties anyway, in the case we want direct access to these lists. 
- Added missing ClearMenuVars() call to MasterQuestScript so Menu unlocks properly after first time setup.

###### MISC NOTES:
- All Optional Aliases in the ESM were converted to force fill so they always instantiate their scripts as expected on Quest start. At this point it is considered to move all Quest scripts to the first Alias on Quests, as it may be friendlier to uninstall the mod (Quest script instantiate on load, whereas Alias scripts on fill, and maybe be better destroyed on unfill). 

------
##### [09/05/2018] SpawnEngine updated to version 0.08.03.180509

###### SCRIPT OPTIMIZATION/REVISION/FIXES:
- Fixed AuxMenuTape fragement calling wrong function, borking startup of the mod.
- Added missing Welcome message on first install.

------
##### [08/05/2018] SpawnEngine updated to version 0.08.02.180508

###### HOUSEKEEPING:
- Removed Mandatory flag on some optional SP properties.
- Set default value of iMasterSpawnChance and iRegionSpawnChance to 100.
- Set default values on iThreadsRequired on Spawnpoints of 1. Updated description.
- Updated description of EZ settings properties on Master.

###### MAJOR/MINOR FEATURE UPDATES & ADDITIONS:
- [MINOR] Completed EncounterZone Menu terminal fragment (now full featured).
- [MINOR] Added iRegionSpawnChance settings to RegionQuestScript so can now control overall spawnchances per Region as well. Need to add a function on Master to allow mass change of this (mostly for resetting on mass scale)

------
##### [07/05/2018] SpawnEngine updated to version 0.08.01.180508 - In private Alpha testing

###### HOUSEKEEPING:
- Some more cleanup of script commentary and property descriptions. 
- Updated NPP language file again. Some missing, some new.
- More Mandatory flags added here and there, in the scripts I was working in. 

###### SCRIPT OPTIMIZATION/REVISION/FIXES:
- Removed duplicate ReleaseThreads call from Spawnpoints. Was being called twice so would have ended up in the negatives (very bad).
- Added ReleaseThreads call to SpHelperScript, previously never released its thread when done (very bad).
- Some more progress on Terminal fragment scripts, ready for alpha release.
- Fix SpGroupScript Cleanup function attempting to cleanup wrong package if Stampede package was used (Ambush instead of Stampede). Bad copy from when I made it. 

###### MAJOR/MINOR FEATURE UPDATES & ADDITIONS:
- [MAJOR] Added new SpMiniPointScript. This is for the new "Mini" Spawnpoint, used for spawning individual actors and/or debug purposes. Very similar to the SpGroupScript (based from it). 
- [MINOR] Added new iForcedDifficulty setting to SpGroupScript (Can now force Difficulty on the main SpawnPoint, to put that in English :D).
- [MINOR] Moved getting of Difficulty level from SpHelperScript to SpGroupScript (so Multipoints can now have forced Difficulty as well, also this speeds up helper points a touch when more than one is used at a time.)
- [MINOR] Added in SingleSettingUpdateEvent for EncounterZones features. This system is almost fully functional, pending some edits to the Terminal fragments for its Menu.
- [MINOR] Added 2 new Globals to Master, for storing the current Region/World IDs while in Menu (this is the index numbers of those items on Master arrays and used to pull their respective script). Is now less confusing then was before.

------
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

###### SCRIPT OPTIMIZATION/REVISION/FIXES:
- Previously, ClassDetails[0] on ActorClassPresetsScript was unused along with the ClassPresets[0] on the ActorQuestScript (and commentary mentioned not to fill/ignore). These have now been converted to debug features, and should be defined for all Actors. Updated script descriptions/commentary accordingly.
- Removed redundant bAllowBoss flag from Struct_ClassDetailsStruct, instead we will now look at the iChanceBoss value (and cast to bool). Updated SpGroupScript and SpHelperScript accordingly.

-------
##### [04/05/2018] SpawnEngine updated to version 0.06.01.180504

###### HOUSEKEEPING:
- Corrected wrong version number in Github readme. Was 0.00.05, supposed to be 0.05.00.
- Updated Notepad++ lang file with some missing variables for scripts and arrays of and added new functions. 
- Corrected some bad commentary/grammar, removed some obsolete comments.

###### SCRIPT OPTIMIZATION/REVISION/FIXES:
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
- Increased Master Event cooldown timer to 5 minutes from 3.
- Fixed SevenDaysQuestScript startup. For some reason I must have gotten confused and coded this all wrong. Added functionality to Master to deal with pending/starting Event Quests after Pipboy is exited. 

###### MAJOR/MINOR FEATURE UPDATES & ADDITIONS:
- [MINOR] Previously Class Presets were based on Difficulty, so the harder you set this, the more enemies etc you'd get. This undermined the purpose of the major Presets, so now it is based on major Presets. This cuts amount of presets per Class from 5 to 3. Updated scripts accordingly.
- [MAJOR] Extended Spawntypes to now include Class-Based Spawntypes. While I tried to avoid making this necessary to lessen the number of properties overall, I was somewhat restricting the potential and making custom SpawnPoint code (such as the AmbushPoint) a bit more complex/less flexible. Now scripts can link directly to these Spawntype scripts and included Actors can take advantage of the "Rarity" system. The SpawnTypeRegionalScript has undergone some changes that will help it to identify if it's Class-Based and function accordingly, as previously it couldn't return any ClassPresets that weren't one of the "Rarity" based Classes. See the "Classes vs Spawntypes" in-script commentary for more in-depth information. 
- [MAJOR] Furthermore, the Ambush Class was split into two - Ambush (Rush) and Ambush (Static). The former means the actor supports waiting in place and rushing the player when ready, and the latter is for the "hidden" type of ambush, such as buried Mirelurks, Roaches and Molerats. This allows the AmbushPoint to be configured for either type.
- [MAJOR] Added new feature, Random Stampede. An extension of the random Swarm/Infestation mode, supported Actor types can now have a chance to stampede upon successful dice roll. This required a bit of modifcation to the SpGroupScript (main spawnpoint) as it requires a different package. Actors in this mode will receive a single travel location and run there, sandboxing on arrival. In general they will then prefer to run, which should somewhat emulate heard behaviours. Only works on exterior spawnpoints. Denies Random Ambush when active.

###### MISC NOTES:
- BeginSpawn functions on the included two Random Events helper points (Ghoul Apoc and SevenDaysToDie) remain incomplete until further work is done on the ESM. 
- Terminal "ConfirmPreset" subpages are not compiled pending an edit in ESM. 
