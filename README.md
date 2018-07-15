# F4-SpawnEngine
*Fallout 4 Mod "SpawnEngine" aka "Spawns of the Commonwealth" by SMB92*

- NOTE THAT THIS REPO DOES NOT CURRENTLY CONTAIN A PLAYABLE PLUGIN/RELEASE CANDIDATE. THERE IS CURRENTLY NO UP TO DATE DOCUMENTATION EITHER AT THIS TIME. PLEASE BE PATIENT WHILE WORK CONTINUES. ALSO TAKE NOTE THAT ANY PLUGIN FILES PRODUCED BY ME WILL NOT BE SUBJECT TO OPEN SOURCE LICENSE, AND WILL REQUIRE MY EXPLICIT PERMISSION TO USE. LICENSING WILL BE UPDATED TO REFLECT THIS IN DUE TIME.

## NEWS

### Version 0.16.03 published to closed testing group. 

[15/07/2018] After the 0.15.02 private alpha, a few more issues were identified, and this version is a collective of these fixes, thus the skipping through to version 0.16.03. New methods were also implemented to speed up AI evaluation and more advanced methods are being investigated for Sandbox AI. 

### Quick patch to version 0.15.02.180706.

[06/07/2018] More polish, biggest things to note in this update, blew away the "Settings Event Monitor" script, as no longer needed with new methods on MasterScript, and also fixed an infinite loop on the SpawnTypeRegionalScript (no counter). 

### Update 0.15.01 brings further refinements before Alpha.

[05/07/2018] While I did say the last update would probably be the last, as it would be a number of optimizations and fixes were found while polishing the files. Big kudos to Jostrus yet again for stellar ideas/methods/optimizations! Not going to call this the last update before Alpha again, but I do consider the framework for it complete at this stage.  

### Another major milestone reached, SpawnEngine updated to version 0.14.01. 

[01/07/2018] Intended to be the final update before the next Alpha release (which is looking to be public), this updates brings significant amounts of new terminal Menus, completes the code for the included Random Events (Seven Days to Die, Ghoul Apocalypse and Random Roaches), a few more bug fixes and a few more minor features added here and there for better effect. Now I have started dropping and configuring SpawnPoints across Commonwealth Region 1, and as soon as that is done we'll have our first REAL taste of what this mod will deliver!  

### Patch 0.13.02 to fix fast travel pop in issues.

[19/06/2018] Thanks to alpha testers (namely KKTheBeast) for pointing out that spawns were popping in on fast travel as no distance checks were in place in exterior cells (as I do not fast travel personally, I completely overlooked that fact). Added distance check and new Property to define safe distance on a per SP basis. 

### Update 0.13.01 brings monumental changes to the SpawnPoint, implements full runtime reset functionality, permanent SpawnPoint persistence, more Menus and more fixes.

[17/06/2018] I have been hard at work over the last few weeks since the 0.12.01 Alpha, with one of the main focuses of this update being the SpawnPoint and working in new methods for use with different Package styles. All code has been converged into one single class now, the SpawnPointScript. Suffice to say this update presents a huge update to the spawn code, beyond which I intended even. I am currently working on documentation that explain how the new SpawnPoint works, and how to use it yourself in add-ons, and will advise when ready. I have also added in the ability to fully reset/cleanup all dynamically produced data from the mod in this update, returning it to "factory fresh" state (yes I feel like a factory, lmao). The other big news is, as of this update, all SpawnPoints placed in the World will become permanently persistent. The biggest reason behind this decision was cell conflicts, but with respect to uninstallation factor of the mod, it was going to be impossible to remove CK placed objects completely anyway. Now that they are persistent via a single script that stores them (SOTC:PointPersistScript), we will be able to at least iterate each one of them and disable them, with hope F4 will clean them up later. Not sure why anyone would want to uninstall this mod though :D. A new alpha file is being worked on, and this will be a proper test file with a full featured Region in the Commonwealth (Region 1). Following this, if all is well, this test file will be released tothe public on the Discord dev server. Stay tuned for more updates! 

### SpawnEngine updated to version 0.12.01, Alpha proves solid

[27/05/2018] This version was released as the second Alpha RC for private testing and has proven to be working optimally. This update kills off a number of gremlins in the code, mostly oversights in Init procedures which led to errors in SpawnPoints. The next update will likely be a public alpha demo, however I am also working on some new methods for the Random Events Framework.

### Update 0.11.01 fixes EncounterZone system, transfer to Region instances

[20/05/2018] As noted in the Issues section previously, the change in instancing methods broke the EncounterZone system. 4 arrays of Formlists are now stored on the WorldManager, and passed accordingly to a RegionManager when it is created. 

### Hotfix 0.10.04 makes Travel Markers persistent

[17/05/2018] I made a slight oversight in that spawns never Traveled because Travel Markers never received their Init events... cos they weren't persistent. I've made a new script that will be used to store them in arrays. This will be expanded upon later.

### SpawnEngine re-enters Alpha status for the first time since August 2017 with update 0.10.03.180516, SpawnPoints now functional in game.

[16/05/2018] Today marks the first day since the August 21 Alpha, made with the first iteration of the mod, that SpawnEngine has entered a fully functioning in-game state. Spawning over 100 Super Mutants using the wonderful SuperMutant Redux mod in the blink of an eye (at least on my system). This version will now enter private testing and we can start batting out SpawnPoints all over the map! 

### Completing the dynamic initialisation design in update 0.10.02.180515

[15/05/2018] This update focuses on the new Init procedures introduced in 0.10.01, further refining them and making the mod much simpler to create new data for Actors and Regions. While there may be a few little holes left to plug, I'm very happy with the changes. 

### Update 0.10.01.180513 fixes major design flaw, overhauled instancing methods, major changes to initialisation procedures.

[13/05/2018] Earlier last week I was preparing to drop an Alpha when I discovered that my design was hugely flawed by the fact that you cannot rely on ReferenceAliases to uniquely instance scripts. This was always a gamble I guess, however some false positives in some previous testing I did with this is what lead me down this road. I had spent so much time on focusing on scripts and functionality/features that I had not thought to check how this would work on this scale. In any case, I quickly moved to a way more reliable method of using dynamically instanced ObjectReferences (prefilled MiscObjects that will be instanced at runtime). As a result this update includes massive amounts of changes, but do know that the overall functionality/mechanics/gameplay has not really changed. See update log for more info. And yes Version 0.09.01 was skipped, this version tried another method of working with Aliases that lead to the same result. This version will not be posted as that method has been abandoned completely. 

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

[25/04/2018] Dubbed version 0.05.00.180425, all current source scripts have been pushed to this hub. Documentation is currently limited to what I've commented into the scripts, and no ESP file has been committed (although compiled scripts are currently present, just to show that the source is in working order). A Notepad++ Language file is provided on the main page, which highlights all current script types, variables thereof and all Function definitions. It also includes some missing vanilla syntax. 

Please be patient while work continues on both a working test file and official documentation.

## UPDATE LOG

##### [15/07/2018] SpawnEngine updated to version 0.16.03.180715

###### HOUSEKEEPING:
- Update Notepad++ Lang file again. 
- Made some Property descriptions for overrides on SpawnPointScript a bit more transparent. 

###### MAJOR/MINOR FEATURE UPDATES/CHANGES/ADDITIONS:
- [MINOR] Added bHasOversizedUnits() Properties to GroupLoadouts script for both Regular Unit list and Boss Unit list. This extra granularity ensures large actors don't appear in confined spaaces that maybe some varieties of an NPC type can fit in (think, Mirelurks etc). Not yet implemented to Spawn code, coming next version. 
- [MAJOR] Implemented new method to speed up initial Evaluation of applied AI packages. A new class, SOTC:EvalPackageEffectScript has been added. SpawnPoint will now cast a simple spell/magic effect to each Actor which has a simple script to call EvaluatePackage() when applied. This allows such call to be run in own thread while the serialised work of the SpawnPoint finishes much faster due to this call being so latent. Credits to Jostrus for the idea.

###### SCRIPT OPTIMIZATION/REVISION/FIXES:
- Fix infinite loop on RegionManager
- Fix typing of GetGroupLoadout() functions (as noted a few versions ago, these were mixed up). 
- Fix bad strings in SetMenuVars functions on Master, and RegionManager SingleSettingsUpdate event for Sp Preset Chance Bonus setting. Wasn't being set because of this. 
- Updated Master and Region Spawn Check functions to pass SpawnPoints as script type, not ObjectRef, and fixed bad logic. 
- Fix SpawnPoints always trying to check SpawnTypeScript if enable, even in Mode 1 (which does not make use of ST's, only Actors directly). Added extra check for mode. 
- Add new function to SpawnPointScript, InitFailProcedure(), to shorten the Init block when fails by moving common code here. 
- Fix bad building of returning array in GetRandomActors() function on SpawnTypeRegionalScript.
- Add extra security check to SpawnPoint when attempting to cleanup PackageLocs array, should no longer produce an error in logs. 
- Fix SpawnTypes based on ClassPreset not returning the correct ClassPreset by default (when not forcing the value).
- Fix ThreadController granting an extra thread than the max allowed, due to comparison operator only checking > instead of >=. 
- Fix SpawnTypeRegionalScript not returning Rare Actors for that Region properly.

###### MISC NOTES:
- For the purpose of this release, as no Menu option has been implemented to prompt the user if they want to "override custom settings", when setting a Preset all settings will be refreshed to that of the Presets, if applicable (which isn't that many a side from the NPC distribution). 
- Sandbox methods need to be vastly improved, particularly for Human NPCs. Creatures/wildlife seem fine but humans tend to stand around and do nothing if there is little to no furniture items to use. A number of methods are being investigated at this time. 
- AI evaluation for travelling groups after arriving at their first destination is very slow. This is a game engine issue and not something I can easily fix with out manually controlling the whole process. It is not a major problem as the player will likely kill the majority of spawns before this ever happens, but worth noting. 

------
##### [06/07/2018] SpawnEngine updated to version 0.15.02.180706

###### SCRIPT OPTIMIZATION/REVISION/FIXES:
- Add experimental ApplyStartSneaking() function to SpawnPointScript for Ambush spawns. This puts spawns in sneak mode until they are ready to rush the player. Needs much testing, as Package may not override when applied.
- Fix confusing Property description for bRandomiseStartLoc on SpawnPointScript. 
- Removed obsolete value check from SetMenuSettingsMode() on MasterScript
- Fix Static and Bypass events still firing on setting of 0. 
- Move reset of EventFlagCounter from Event Monitor back to ThreadController as this had to return there anyway. 
- Changed Debug Notif on ThreadController to Trace, which it was meant to be. 
- Add more debug traces around.
- Add 5 second timer to mod start, so player can get bearings first. 
- Made some changes to PerformFirstTimeSetup() function on Master for better effect. Now a mandatory 7 second wait for all Regions to init travel locs dynamically. Maybe extreme, but better safe then sorry. 
- Fix never ending loop on RegionManager, reshuffling actor list. 
- REMOVED SettingsEventMonitorScript and objects/instances from mod. Better method found. Now handled by MasterScript. 

------
##### [05/07/2018] SpawnEngine updated to version 0.15.01.180705

###### HOUSEKEEPING:
- Update Notepad++ lang file again.
- Add some debug traces here and there on MasterScript. 

###### MAJOR/MINOR FEATURE UPDATES/CHANGES/ADDITIONS:
- [MINOR] Added ability (and Menu) to set SpPresetChanceBonus on the Master level (as in all Regions at once).
- [MINOR] Added SetMenuVars() function to SpawnPointScript, along with 3 Globals as Properties (only one in use, but future proofing). Necessary for future Menus for "contested" SPs that are toggleable from Menu.  

###### SCRIPT OPTIMIZATION/REVISION/FIXES:
- Optimize a number fo terminal fragments to use single common function where possible, and fix a few big/small issues (special thanks to Jostrus again for help with this). 
- Removed hard-coded setting of Region/Master SpawnChance values now that SpBonusChnace is implemented.  
- Revamped security measures on SpawnTypeRegionalScript's GetRandomActor() function regarding if certain Actor lists are empty. Functions will check the next applicable list for content, and if or some reason the yare all empty, will activate a failsafe on MasterScript. 
- Added new function to Master, GetMasterFailsafeActor() which will pull Radraoches to spawn if the ST script lists are empty (just like vanilla failback! :D ). 
- Rename Property ActorListScript on SpawnTypeRegionalScript to SpawnTypeMaster for clarity. 
- Fix major issue left over from many versions ago with grabbing GroupLoadout data. Had intended to change over to returning entire GroupLoadoutScript to SpawnPoints, so Regular unit list and Boss list can go hand in hand (whereas currently/previously, was grabbing either list at random each time, major problem if intended group had no bosses defined with the way things were setup). Function was already written, just had to change SpawnPoint scripts to use this instead and run an additional check. 
- Slightly changed instantation method of ActorClassPresetScripts, no longer checking for blank members on base object array on ActorManager. Not necessary as they set themselves to correct index anyway. 
- Change RegionManager to grab size of SpawnTypeMasters list from MasterScript instead of using hard coded number. 
- Fix Random Event quests running shutdown code on startup (added check). 
- Add default values to some Properties on Master and RegionManager (and update descriptions).
- Fix initialisation error with FillMasterActorLists() on MasterScript overshooting by 1. 
- Recompile all Terminal fragments to fix errors with extra parameter added to Menu function in previous version (which was since removed again). This logged Papyrus errors of "Incorrect number of parameters" as some fragments were compiled without this change, and caused menu item conditions to not work properly interestingly enough. 
- Fix Difficulty settings Menu terminal fragment running unnecessary function call (double handling).
- Fix MasterSingleSettingsUpdate() mix up with "Random Ambush" chance and "Sp Preset Chance bonus" settings. Had entered code in wrong spot after copying. 
- Change Master Init function to add SOTC Main Menu tape AFTER setup completes.
- Removed setting of EventQuestStatus global OnStageSet in GhoulApocQuestScript. This may lead to race conditions in future, so now Menu must explicitly call SetMenuVars() to update the value when necessary. 
- Set default value of bVanillaMode to TRUE on MasterScript. Predict there will be less problems this way if user doesn't flag this manually after installing.

------
##### [01/07/2018] SpawnEngine updated to version 0.14.01.180701

###### HOUSEKEEPING:
- Add/fix/remove some commentary.
- Add "CustomEvent" from vanilla to Notepad++ lang file, along with new functions/script/object types.
- Changed Uninstall() to UninstallSpawnEngine() for extra clarity (mainly because Notepad++ lang file).
- Expanded Property description for bBlockLocalRandomEvents on SpawnPointScript.
- Moved RandomRoaches feature scripts to RandomEvents namespace.
- Changed Property name of LvlRadRoachAmbush to LvlRadRoach on RandomRoaches Dynamic Alias script for extra cliarty (does not use actual ambush system).
- Removed descriptions from Property groups on Master. Unnecesary.
- Added "EventHelper" Prefix to Random Event helper SpawnPoint functions. 

###### MAJOR/MINOR FEATURE UPDATES/CHANGES/ADDITIONS:
- [MAJOR] Significant number of new Menus added to this version, in preparation for next Alpha. New terminal fragments included in source. 
- [MINOR] Added Int array Property on RegionManager, iSpPresetChanceBonusList. This can be used to apply bonus chance to fire to SpawnPoints based on current preset, with members 1-3 correlating to the current Preset. Int function added to RegionManager to return this correctly. Value is set from Menu, although default values were given in editor (Menu was added as well). Considering adding similar facility to MasterScript, although not needed at this time. 
- [MINOR] Added optional Player level requirement property and check to SpawnPointScript. 
- [MINOR] Stripped out Static Ambush related spawns/options across the mod (Package Mode 5/SpawnType 12/Class Preset 5). Been a long time since I last looked into it, forgot about all the furntiure markers and what not involved in making that happen. I will revisit this at a later time, I had started a separate SP/script for this purpose some time ago, however I am leaning towards an addon for this rather than including it in the core, for compatibility reasons.  
- [MAJOR] Completed SevenDaysToDie Random Event and added Menus as well. 
- [MAJOR] Completed Ghoul Apocalypse Random Event. Menus added as well.
- [MINOR] Added Line of Sight to Player checks in all spawn loops on all SpawnPoint scripts. While this will make these loops slightly slower, if this check gets flagged 25 times during an active spawn (there is a 0.1 sec wait each time it returns true, right before an Actor is placed) the SP will stop all spawning. This equates to roughly 3 seconds of time allowed to be wasted on LoS before halting the SP entirely.  
- [MAJOR] Changed how Random Event Quests are handled, they are now start game enabled and Menu will use the stages provided to configure status. This change means settings can be configured before an Event is started. Previously Menu would have to start these Quests, which meant that Player must exit Menu before being able to configure. 
- [MINOR] Added Player Level Restriction to ActorGroupLoadoutScript. Can now set a level requirement before a group can be allowed to appear. ActorClassPresetScript functions updated accordingly. 

###### SCRIPT OPTIMIZATION/REVISION/FIXES:
- Fixed indentation of Property descriptions on ActorManager and MasterScript.
- Gave default values to LootChance Properties on Actor Manager. 
- Moved ForceResetAllSPs Master custom event to the MasterSingleSettingsUpdate() function, as it does not require user to exit Menu (timers are not restarted).
- Fix SetMenuVars() on Master and RegionManager not setting value of iEzBorderMode on correct Global. 
- Changed SP cleanup functions DeleteWhenAble() call to Delete() so it is no longer latent as such, this was an oversight as I forgot which call was the wrong one when I wrote that. 
- Changed handling/setting of EventPoint on Master, bEventSafe flag is now passed as parameter to MasterSpawnCheck() instead of casting back to check.
- Changed order of initial PackageMode checks on SpawnPointScript, moved mode 3 and 4 to lower priority order.
- Renamed AppendEventQuest() to SafelyAppendEventQuestForStart() and also StartPendingEventQuests() to SafelyStartPendingEventQuests() for extra clarity ("Safely" tag denotes security code exists for arrays). Added commentary at top of Master script about Safely tag.  
- Removed the two remaining, obsolete debug option Properties on MasterScript. 
- Added line-of-sight checks to RandomRoaches scripts. Now roaches will only be placed when player isn't looking. 
- Made checks on RR DynamicAliasScript more specific by comparing GetRef to None, also added the same check to non-workshop-checker mode (previously the script would just assume it was filled, not sure why I did that). 
- Added Rush Package to RR DynamicAliasScript, roaches will now rush at the Player. Combined with the new LoS checks, this should work to great effect.
- Changed SevenDaysQuestScript to make use of Master function SafelyRegisterActiveEvent() instead of dealing with Master array Property directly.
- Removed SpawnPointScript checks from SevenDaysQuestScript, no longer necessary. 
- Added cleanup code to SevenDaysQuestScript and made some changes to suit. Event will clean itself up after 24 hours. 
- Added SafelyUnregisterActiveEvent() function to MasterScript. 
- Fixed majorly glaring issue with SpawnPoints clearing GroupList array when Boss spawns are called/allowed (function was calling "new" on the Grouplist array without checking it had already been in use). 
- Added code to SpawnPointScript to de-link dynamic script instances, just in case errors arise from not resetting them and instances change later (i.e mod reset). 
- Added GetRandomTravelLoc() ObjectReference function to RegionManager, simply to grab a single location instead of array. Forgot to add this some time ago and needed it now. 
- Fix ActorClassPresetScript GetRandomGroupScript() function from checking Boss list when not necessary at all. Function not used anywhere yet anyway.  
- Gave Random Event chances (Bypass and Static Events) a default chance value of 20%. 

###### MISC NOTES:
- It should be noted that RandomRoaches features relies on finding an object (namely a static) in a formlist in the nearby area. While there are 10 of these aliases implemented in the ESM, most statics are part of precombined meshes. Further testing needs to be done as to how viable this feature will be. This feature is currently not turned in the the 0.14.01 Alpha anyway. 
 
------
##### [19/06/2018] SpawnEngine updated to version 0.13.02.180619

###### SCRIPT OPTIMIZATION/REVISION/FIXES:
- Added GetDistance checks to Player to prevent SpawnPoints from firing when to close to the player, namely in the event of fast travel and only when bIsInteriorPoint is not flagged. Readded bIsInteriorPoint property to SPs for this purpose (was removed last update due to new "Package Modes"). This is used instead of IsInterior() as that is too explicit and we may want to use this elsewhere. 
- Moved/optimized SP initial chance check (check if local chance is above 0) to the OnCellAttach() block from the OnTimer block.
- Fix SP PrepareSpawn functions not checking value of 777 for random preset ( was still using old value of 4, had forgot to change them).

###### MISC NOTES:
- Looking at potential Line-of-Sight issues in tests and methods to mitigate if issues arise. In general should not be too bad of an issue, especially now above patch was added to check player distance. 

------
##### [17/06/2018] SpawnEngine updated to version 0.13.01.180617

###### HOUSEKEEPING:
- Update NPP Lang file to include new/remove old functions.
- Add/fix some commentary.
- Changed/fixed some Property descriptions
- Removed obsolete, commented-out function from SpGroupScript MultiPoint section.
- Fix property description indentation on SpGroupScript and SpMiniPointScript so it displays properly in CK.
- Added "Note on Dynamic Array Initialisation" at top of MasterScript.
- Changed some function and script names for better effect. 

###### MAJOR/MINOR FEATURE UPDATES/CHANGES/ADDITIONS:
- [MINOR] (MENU) Performance Menu, World/Region Selection and Region Settings Menu added/completed (fragments). Added, consolidated and optimized functions to deal with setting of vars on all relevant scripts, mainly via new SetMenuVars() function that now appears in relevant scripts, as mentioned above.
- [MINOR] (MENU) Debug Menu and options (Properties) were removed. Mod will feature Traces where necessary and won't be controllable by the user. "Spawn Warning" moved to Performance Menu.
- [MINOR] REMOVED Loot system support for SpawnTypes entirely. New instancing methods introduced in version 0.10.01 made this a lot more difficult to deal with, and it is simply not worth the hassle to redo. Supporting loot for SpawnTypes was always a bit iffy, the only reason it was potentially worth doing was to have special loots on a per Region basis (I.E imagine if some wildlife in a certain area were able to have a unique item on them not found elsewhere). I may revist this in future and reimplement a dumbed down version for that purpose. System remains untouched for individual Actor types.
- [MAJOR] Consolidated all SpawnPoint code into one script, now renamed as "SpawnPointScript". This class will now assume all the roles required, which have also been added. Initially the concern with this was speed, but most of the extra checks that have to be done now are local and speed is not adversely affected as such. A good chunk of this script has been modified to suit, particularly its Properties. SpawnPoint capabilities/roles have been expanded, and now includes all the intended modes (Sandbox/Hold, Travel, Patrol, Amush (distance-to-player based), Interior, Ambush (Static/Hidden)) and MultiPoint mode support has been added for many of these new modes. Many functions have been refactored for this change (SpawnPoint script is nearly doubled in size), I have added notes thoughout the script on how/what to use/expect.
- [MINOR] Added new iForceGroupsToSpawnCount Property to SpawnPoint. This can be used to force the number of Groups at a MultiPoint. While mainly introduced for use with Interior and Patrol Points, can be used for other means (with caution).
- [MINOR] Added new "ForceClassPreset" parameter to SpawnTypeRegionalScript's GetRandomActor() functions and added Property to Spawnpoints. Can now force grab a Rarity-Based Class Preset regardless of the Rarity of Actor rolled by dice, in addition to being able to force the Rarity.
- [MINOR] Added ability to randomise ClassPreset on SpawnPoints in "Specific Actor Mode" by entering 777 as the value. This will pull a random Rarity based preset between 1-3.
- [MAJOR] Decided to make all SpawnPoints permanently persistent. A few reasons for this: 1. No longer have to deal with cell conflicts (major influence on this decision). 2. SPs can have "Child Points" (which are required to be persistent properties on those SPs) and Travel Markers are also required to be persistent by nature, and 3. Calling Delete from script on CK placed objects does not work. This change is in major contrast to the initial scope of the mod to not have permanently persistent data, however there is simply no avoiding it when considering the level of quality this mod needs to provide. Uninstallation factor was never going to be perfect for other reasons, but in the case of persistent/ck-placed objects in cells, one would need to wait for/do a cell reset on affected cells regardless.
- [MINOR] Random "Rampage" feature was seggregated from the "Swarm" feature and now works on it's own (not just when rolling a "Swarm").
- [MINOR] "Random Ambush" and "Rampage" (formerly "Stampede") features for Sandbox/Travel mode SpawnPoints now supported together (now uses same package, the "Rush" package). Now you can have "Swarm" (when/if rolled) rush at the Player. Masochists need only enable.
- [MINOR] Added ability to use to use "ChildPoints" to randomise the initial spawn point of groups. New Property bRandomiseStartLoc added to SpawnPoint. When used and also defining "ChildPoints" around the main SpawnPoint, the SP will elect a random point to start spawning at. This can be useful for a variety of things, but likely not standard practice. Parameters have been added to Spawn loops to deal with this. 
- [MINOR] Added ability to "spread" spawns to ChildPoints via new Property on SpawnPoint. Dedicated new SpawnLoops with the "RandonChild" type in them will spawn actors at random, defined, ChildPoints around the main SpawnPoint, which gives the effect of spread out spawns of course. Saves doing heavy math and navmesh checks at the cost of memory. Using this will cause the above new feature to be ignored, and is only supported for Package Mode 0 and 1 (Sandbox/Travel). This is technically a refactor of the previous "Interior" spawn functions (replaces this). 
- [MINOR] Added ability to define "Bonuses" for local events on SpawnPoints (Swarm, Rampage and Random Ambush). Added new parameters to RegionManager local event dice-roll functions to handle this. 
- [MAJOR] Implemented full reset functionality, MasterFactoryReset(). The mod can now cleanup all dynamic instances, returning it to the first-installed state. This starts on the MasterScript, and serialises down through other class instances in the appropriate order. Uninstall options will open up on the Auxillery Menu after the first time this reset is run (not yet implemented). 

###### SCRIPT OPTIMIZATION/REVISION/FIXES:
- Renamed MenuForceResetRegion() function on RegionManager to MenuForceResetRegionSPs(), for better clarity as that is all it does.
- Made optional "Spawn warnings" a bit more ambigous and reduced to only 2 messages instead of 3.
- Removed bMasterCooldownTimerEnabled Property removed from ThreadController (check value of clock is more than 0 instead, saving a tiny bit of memory). 
- iMasterSPCooldownTimerClock on ThreadController converted to Float and renamed to fNextSpCooldownTimerClock for better clarity.
- Changed iSpCooldownTimerClock Property to fFailedSpCooldownTimerClock (converted to Float) for extra clarity.
- Updated SpawnPoint scripts to reflect changes to timers above.
- Removed SPs being "spent" when denied by Master or Region dice rolls and instead use ThreadController Cooldown timer if enabled. If not enabled, will try to spawn again every OnCellAttach().
- Fix "Spawn Warning" only firing after Master Check, instead of when SP actually was successful. This was something I had been meaning to change for a while but forgot. 
- Removed bRegionEnabled setting/Property from RegionManagerScript. Use RegionMasterChance value check instead , more memory efficient.
- Added security measures to SpawnTypeRegionalScript GetRandomActor() function in the event there are no Actors defined on a Rarity-based list. If this happens, will revert to the list above the requested (the more "common" option). This resulted in encapsulting the Actor return functions into their own functions.
- Somewhat removed the hard coded limitation that if a SpawnType was based on a certain Class, it would only return that ClassPreset for the Actor. This can now work with the new ForceClassPreset setting. Will still pull base ClassPreset for the Spawntype if ForceClassPreset is not used.
- Extended/refactored same functionality to GetRandomActors() (return multiple actors) function on SpawnTypeRegionalScript.
- Added failsafe to SpawnPoint, if ClassToSpawn entered is not available or expected value, will use debug preset instead (0). Added function GetClassPreset() to ActorManager to deal with/return this (no longer calls the ClassPreset direct)
- Added security check to SpHelperScript, if kPackageLocs array is None will default to Self as location. Package may still produce errors if not setup correctly.
- Fix SP kActiveHelpers local array never being initialised at all.
- Fix SP kActiveChildren local arrays likely/maybe not initialising properly due to being empty (Papyrus/Creation seems to like trashing arrays that are initialised as empty on occasion).
- Added SetMenuVars() function to a number of scripts, this is the new standard method when setting something from Menu. This function takes a string and an Int parameter, used to set the correct setting to the new value and update Globals for the current Menu page conditions.
- Changed function MenuSetPreset() on RegionManagerScript to SetMenuVars(), inline with other scripts.
- Fix RegionManager dice rolls for included events (Ambush, Swarm, Stampede) being denied on a roll of 100 (was only checking < instead of <=).
- Fix same dice roll bug on SpawnPoint final dice roll on itself.
- Gave RegisterMasterForPipBoyCloseEvent() function parameters default values so they do not have to be declared.
- Added new struct to Master for presetting "Rarity Chances" (the values for CommonActorChance/UncommonActorChance). Added an array of this struct to store these presets. User can only select presets for this option in Menu for ease of use as it could become confusing/unbalanced easily. Also added a local variable to store the last selected preset.
- Struct_RegionPresetDetails script was completely removed in this version (was obsoleted a few version ago). Preset settings values are hard coded, and new function "SetPresetVars()" has been added to MasterScript and RegionManager. Was simply no need to use the struct apart from making the function look pretty/overly sophisticated.
- Renamed "ChildMarker" to "ChildPoint" on SpawnPoint, not only for better clarity, but it sounds better too. 
- Renamed TravelMarkerInitScript to TravelLocationInitScript for the thrill of it. 
- Inline with the above changes to "Marker" names and persisting SPs, TravelMarkerStoreScript was renamed to PointPersistentScript. This also had 2 arrays for TravelMarkers, I had forgot editor filled arrays are not limited to 128 members. Second array converted to use for SPs.
- Removed instancing of PointPersistScript from Master and moved to AuxilleryQuestScript. Also added Master Marker Property to AuxQuestScript. Upon on uninstall, the PointPersistScript will be called to iterate and disable all persistent refs stored on it. This is the best that can be done if the user is serious about an uninstall, in regard to these persistent objects.
- Fix TravelLocationInitScript not setting security bool flag bInit after receiving OnInit().
- Renamed Var array variable in Master event function from "PresetParams" to just "Params" for better clarity (can be used for stuff other than Preset setting).
- Removed an obsolete debug notif from Spawnpoint script.
- SpawnPoints now do applying of Travel and Patrol Package data AFTER spawn loops (after ALL Actors in the group spawning are placed) and not during the loop. This seems to keep them closer together when spawned. Sandbox remains during the loop as this fits that better in terms of AI evaluation. 
- Slightly optimized SpawnActorRandomEzInteriorLoop() on SpawnPoint, moved randomising of EZ inside of chance block. This function remains mostly unchanged despite the overhaul of of the SP script. 
- Fix Swarm bonus numbers being applied the wrong way around (boss to regular and vice versa).
- Fix comparison operators in SpawnLoops() not checking <= (was doing != for MaxCount while check and just < for chance comparison, which causes rolls of 100 to fail as mentioned previously).
- Reduced SpHelperScript Init ("Fire") timer from 0.5 seconds to 0.2 seconds.
- Reduced StaggerStartup Timer random range on SpawnPointScript from 0.2-0.5 to 0.15-0.35.
- RegionTrackerScript updated for new SpawnPoint changes, removed many now unnecessary Properties and checks.
- Removed obsolete Debug.Notification from RegionTracker. 
- Fix MasterQuestScript not actually sending Settings Event 10 (Full preset change) due to bad check (> instead of >=). 
- ThreadController ActiveThreadCheck() was changed to be a Bool function, as it should have been. 
- Changed Master Property iEventCooldownTimerClock from Int to Float. 
- kEventPoint on Master is now of SOTC:SpawnPointScript type (no longer ObjectReference only). Event scripts can now directly access the instance. Master script now checks "bEventSafe" Property on SP before assigning as EventPoint. 
- Removed "iActorCount" variable from Cleanup functions in SpawnPointScript/SpHelperScript. Realised that it wasn't needed, can just use "iSize" variable set beforehand. 
- Added disable call before calling delete on SpHelpers in SpawnPointScript. More proper way to do it. 
- ShutdownSpawnEngine() function removed from AuxQuestScript. Will be replaced with Uninstall() in near future. 

###### MISC NOTES:
- I am currently considering removing the RegionTrackerScript. The purpose of this script is to deal with resetting SpawnPoints after the RegionResetTimer expires, rather than having each individual point having its own timer. However it may be better to do just that. Currently when these RegionTrackers are first instanced, I attempt to stagger the startup of their timers so that not all Regions will try to cleanup at the same time (potentially causing script lag). While I can implement some extra security measures on the ThreadController to further deal with this problem, I might just so away with it entirely and let the SPs deal with themselves. Also considering adding a new timer system, where the user can specify a "minimum" and "maximum" time for reset to occur, which might help with the "randomisation" factor. 
- Not all fixes and changes are listed above as changes to SpawnPoint code as mentioned are fairly large. Had tried to list what I thought was important when I could. Just so you are all aware of that fact.
- I have every intention of writing a proper debug/user logging feature in the near future. As that is a pretty big job of it's own, for now Traces remain where needed. 
- MasterFactoryReset options have not been extended to Event Quests, as Random Events Framework methods are being looked at again.
- The two included Random Events, Ghoul Apocalypse and Seven Days to Die mode have not had their spawn code completed yet. 

------
##### [27/05/2018] SpawnEngine updated to version 0.12.01.180527

###### HOUSEKEEPING:
- Update NPP Lang file to include new functions
- Add/fix some commentary.

###### SCRIPT OPTIMIZATION/REVISION/FIXES:
- Fixed MasterScript AddActorToMasterSpawnTypes() function not calling from Master Spawntype from index (how this was allowed to compile, I am not sure, guess it's one of those obscurities).
- Fixed never ending loops on security functions on ActorManagerScript trying to clean up first member of None on GroupLoadouts arrays on ClassPresets. This was due to me forgetting to increment the counter, but a local function was added to the ActorClassPresetsScript to deal with this anyway. This is probably better/faster overall.
- Fixed never ending loop on RemovePowerArmorGroups() on ActorClassPresetsScript.
- Fixed/Changed Spawn Chance checks (dice rolls) to check if <= rather than just <, as a roll of 100 on 100% chance SPs (which is oddly quite common) would cause denial. 
- Fixed SpawnPoints not disabling/flagging as Active after successful Spawn, which caused shitloads of Spawns and spam. 
- Removed all instances of Disable/Enable/IsDisabled from Spawnpoints. Unnecesary, can just use bSpawnpointActive flag for all use cases.
- Fixed Spawnpoints not entering cooldown state when denied at the proper time (when denied by dice roll).
- Changed how the Master instance of the SpawnTypeMasterScript ActorList is initialised, will now be initialised to the exact amount of Actors supported by the mod. This fixes the problems with filling ActorLists and the errors seen on Spawnpoints because of this.
- Fixed RegionManager not actually setting created instance of RegionTrackerScript as CleanupManager.

------
##### [20/05/2018] SpawnEngine updated to version 0.11.01.180520

###### HOUSEKEEPING:
- Removed obsolete variable types from Traces leftover from when they were in-game Notifications.
- Some more changes of commentary, property descriptions here and there.
- Updated Notepad++ Lang file for new functions.
- Removed an obsolete, commented out, function on the Master script. 
- Changed parameter order on SpawnTypeRegionalScript, moved aiPresetToSet up a few so it looks better organised.
- Added Trace to ActorGroupLoadoutScript AddGroupToClassPresets() function to log when Group successfully added to ClassPreset.

###### SCRIPT OPTIMIZATION/REVISION/FIXES:
- Fixed array security check on ActorManager's GroupLoadout functions, was checking if list size was greater than 2, only needed to check if greater than 1.
- Added missing security feature from DistributeGroupLoadouts() function on ActorManager to the PerformFirstTimeSetup() function, to remove first member of None if present on ClassPreset's GroupLoadout arrays.
- Fixed bad initialisation of Var arrays on MasterSingleSettings Events, was initialising array with 1 member, needed 2.  

###### MAJOR/MINOR FEATURE UPDATES & ADDITIONS:
- [MINOR] Added Difficulty change as an Event to the MasterSingleSettingsUpdate Event. Was an oversight that this wasn't added earlier, as ClassPresets were based on Difficulty but since changed to be based on Master Preset, so nothing special is required anymore.
- [MAJOR] Fixed EncounterZone system, added 4 arrays of Formlists to the WorldManager and 4 new parameters to the RegionManager's PerformFirstTimeSetup() function. WorldManager will now pass a formlist from each array to the RegionManager, and a new function on the RegionManager is used to transfer the contents to local arrays for permanent storage during first time setup.

------
##### [17/05/2018] SpawnEngine updated to version 0.10.04.180517

###### SCRIPT OPTIMIZATION/REVISION/FIXES:
- Added new script to store Travel Markers in arrays, in order to keep them persistent. This is one object that really needs to be, not much choice in that.
- Added instantiation code for above new Object to Master. 

------
##### [16/05/2018] SpawnEngine updated to version 0.10.03.180516

###### HOUSEKEEPING:
- Fixed bad prefix on bClassesToApply Property on ActorGroupLoadoutScript. Was iClassesToApply.
- Removed obsolete forcing of Counter start at 1 on GroupLoadoutScript AddGroupToClassPresets(), 0 is now debug preset and all groups apply to it.
- Adpated some Property descriptions on RegionManager for new system.

###### SCRIPT OPTIMIZATION/REVISION/FIXES:
- Changed SpawnTypeMaster base MiscObject Property on Master to be single not array, now that is single base object.
- Added security check and removal of None members on GroupLoadouts array on ActorManager before calling AddGroupToClasses()
- Added new EncounterZone formlist array Properties to WorldManager, this will handle transferring of lists to Regions when instances created.
- Added/fixed first time setup of ClassPresets on ActorManager, was not checking if Class was defined or not (if array member was None or not). Added check and Trace if skipped.
- Added same iBaseClassID Property to SpawnTypeMaster, and same SetBaseClassIfRequired() function from the Regional counterpart.
- Fixed Master instancing of EventMonitor, was creating another ThreadController (bad copy!)
- Removed "new" Property iNumOfRegions from WorldManager, this was a brainfart. Instead will init the actual (dynamic instances) Regions array with as many members of None as there are intended Regions, and check the length of it. 
- Added security check on SpawnTypeRegionalScript, to skip filling of dynamic actor lists if no Actors are declared on the Master version. Mainly for the purposes of the Alpha, eventually there will be actors on all Types.

------
##### [15/05/2018] SpawnEngine updated to version 0.10.02.180515

###### HOUSEKEEPING:
- More cleaning/additions to commentary etc
- Update NPP lang file.
- Trace added to all Init procedures. This will be permanent, not just for debug. 

###### SCRIPT OPTIMIZATION/REVISION/FIXES:
- Expanded upon the new "Init-by-function" procedures, rendering the RegionManger, WorldManager and SpawnType scripts (both Master and Regional) into one base object, making setup so much easier. Now the mod will create as many instances as needed and fill each one out with required data
- As a result of the above, many more properties have been made "dynamic" and moved to such property groups. 

------
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
- Manager/Master scripts will now create their required subclass instances on first time install, and have all had MiscObject properties added and a PerformFirstTimeSetup() function added to handle this in the right way. This function differs from script to script, some have different parameters to others, this is to speed things up during this process. Most former alias scripts used as data containers have had their Init events replaced with the PeformFirstTimeSetup() function. There are basically no OnInit events of any sort in most scripts now. 
- SpawnPoint code was refactored for this system change, as they now have to fetch the script instances they need dynamically. New properties for IDs were added, which will be used to fetch the correct instances in a new function, SetSpScriptLinks() when needed. Random Events helper code updated to dynamically grab the instances they need also.

###### MISC NOTES:
- Spawn function on RandomEvent helpers remain incomplete.
- Some holes are expected with new array security features. Will be plugged as necessary.
- Some commentary may still refer to older system. Will remove as discovered.
- A new method has been drawn up to safely update the mod while it is active in game. Drafts for this system have not been included in this update, but are being worked on.

------
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
