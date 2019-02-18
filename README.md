# <p align="center"> SPAWNENGINE:INTRODUCTION 
### <p align="center"> A Mod by S. “SMB92” Bradey & J. “BigAndFlabby” Ostrus 
#### <p align="center"> Written by S. Bradey 
 
 
### *What is SpawnEngine?*

Formerly known as “Spawns of the Commonwealth” during development, the goal of this project is to provide a comprehensive, balanced, widely-compatible, extensible, stable and performance friendly framework to provide spawns for Fallout 4. This is an open-source project, you can find the source code readily available on my [Github.](https://github.com/SMB92/F4-SpawnEngine) 


### *How does it work?*

The mod essentially delivers spawns through hand placed “SpawnPoints” (a scripted marker). SpawnPoints make use of the “OnCellAttach” event, which means that they begin to execute the very moment the cell they are in loads, and if they pass all their conditions/dice rolls/checks etc, will immediately begin to produce spawns, placed at the SpawnPoint itself, or possibly surrounding markers if provided (more on this later). This may sound somewhat predictable, and in a number of cases that is, but it is by far the safest approach. This is something that has been an important focus in building the mod, and much has been done to provide as much diversity as possible.  
 
So, while this may seem fairly simple, there is a massive, mostly scripted back-end that holds and provides data to these SpawnPoints, which would otherwise be “dumb” without. The SpawnPoint itself is a very powerful object/class that can be subject to a multitude of configurations including balance options, delivery methods and simple AI packages procedures. To give some loose examples of what this means for you:  
- Some SpawnPoints may not fire until the Player reaches a certain level, or a certain Preset mode is selected.  
- Some spawns may be travelling, some may be sandboxing, some may be spread across a wider area (thus requiring a different tactical approach), some may be waiting for the perfect chance to take you head off from the rooftops and some may be waiting for you to get close enough for their chance to strike (or perhaps just come running at you from out of the blue the moment they come into existence). 
- Some spawns may be much more difficult than usual (those dark and empty corners of the world may not be so empty anymore!). 
- Some spawns may appear in extremely large numbers, and you may even run into multiple groups of NPCs having it out with each other.  In short, you won’t just expect to see simple mobs of NPCs standing in the middle of the road all the time, in fact you might not see them at all until it’s all too late…. 


### *What about Performance? Aren’t scripts bad?*

While this mod is heavily, heavily scripted with thousands and thousands of lines of code, this does not necessarily equate to destroying the performance of your game or the Papyrus script engine. I am aware of the stigma surrounding “script mods” but let me assure you that Papyrus is quite capable of dealing with reasonably heavy loads and that most of the stigma is based on user experiences with poorly coded mods, and/or using far too many mods that require constantly running code. There are some things that are inevitably slow in this engine, its just a matter of how we deal with these things that makes the difference.  
 
This mod was not built with hack and slash in mind, a lot of attention has been given to performance and stability (without sacrificing the end experience).  This mod only runs code as needed, makes ample use of multi-threading, has highly configurable limits and cleans up its own trash. So if you find that things seems slow, or your PC is a potato, there are many performance options at your disposal for you to configure to your needs and taste.  


### *What about save games, bloat and persistence?*

Inevitably there are many aspects of the mod that are required to be “persistent” which means these things are always loaded in memory, and present in your save games. While the mod does actively clean up a lot of the data it produces, you will likely observe an increase in save game size once the mod is first initialised, and observe varying sizes thereafter (which is again, highly dependant on the settings you choose, such as how often clean up takes place/how long to keep spawns around etc etc). This also means that the memory usage of the game will be higher, as these things are always loaded, but this increase should not be significant from the back-end alone, however may become rather high with extremely large numbers of active spawns.  


### *So, what does this mod edit? How about Compatibility?*

This mod doesn’t edit anything in vanilla at all, except for the fact that it adds SpawnPoints to many cells in the game. A decision was made to make all SP’s persistent, meaning always loaded as mentioned above, so that cell conflicts isn’t an actual problem (when an object is persistent, it gets “placed” in a special cell which links back to the original cell, but you won’t find “conflicts” in xEdit, no patching is required). However, there may be some issues with mods that edit vanilla cells, in those cases that mod would need to be reported to me (SMB92) so that I can add them to the “Compatibility” Menu, so that you can disable the problem SpawnPoints via the settings menu in game. Aside from that, the only real issues that may arise is if some other mod deletes vanilla NPCs, or significantly unbalances them (i.e makes a regular NPC into a boss-type).  
 
So to put it short, you should be able to use any mod you wish along side this one without too much trouble, and in the case that mod might add new NPCS….. 


### *How is this mod “extensible”? Does this mean add-ons are possible?*

Absolutely! This mod was made with extensions in mind, it is very easy to integrate new NPC types complete with custom spawn settings and balance. There is also a simple “Random Events” system designed for providing unique or recurring “special” spawns without actually having to place anything in the world. There are other ideas and methods for implementing add-ons, but this is a conversation for another article, all you need to know here is that yes, this is 100% supported, and we support authors uploading add-ons on their own pages, and the ESL format is recommended.  


### *Is this mod “balanced”? Will spawns wreck my game?*

This mod has been made with a heavy vanilla focus, much care has been taken with SpawnPoint placement as to fit in with/enhance the vanilla game. On top of that, there is an included “Vanilla” mode which outright disables any SpawnPoints that may have been considered to risky to run with the vanilla experience, particularly for people on new games. There are also several SpawnPoints that won’t even work unless a certain Preset level is selected, as previously mentioned. If you find that you don’t like my default settings, you’d be please to know that just about everything is user configurable. And when I say just about everything, I mean just about everything. An in-depth, highly quality holotape menu is provided so you can edit everything to your hearts content.  


### *Installation/Uninstallation*

Install procedure is very simple. The mod includes an ESM and a BA2 packaged in a RAR file, so you may use your favourite mod manager to install or do it manually yourself. When you load up the mod in game for the first time, you’ll receive the “SOTC Auxiliary Holotape” and be prompted with a messagebox stating that you must select a Preset before the mod will be initialised (you will be provided with instructions). Once initialised from the holotape and exited, it will be removed from your inventory and you will have to wait a small period of time (about 10 seconds) for the mod to setup. When it has finished, you will receive the “SOTC Settings Menu” holotape and you are good to go. All settings have descriptions as to what they do, some even have extra “Info” pages, but extensive documentation will be provided in time.  
 
Regarding uninstall, this is currently not supported. In fact, it never will be. There is simply no way to provide a complete uninstallation, it’s never really been supported in general, and for me to even get remotely close to providing something that does work, I would have to sacrifice a large amount of the quality features this mod provides. The mod can be fully reset on the fly in game, whether you just want to reset all SpawnPoints or completely refresh the mod, but the uninstall methods provided make no guarantee of keeping your save game in good health, and almost certainly will mean you cannot install this mod again on that save thereafter. As such I will not be providing support for such problems, and such questions will be met with the same answer as provided here.  
 
 
### *Feedback/Complaints/Compliments*

Constructive criticism is welcome, compliments all the same, but trolling complaints will be met with fire and fury. I am under no obligation to provide you with support but reach out to me nicely and you’ll have a far better chance of that happening. If you are experiencing a problem with the mod I would encourage you to report it ASAP, with details of where the problem occurred, what exactly happened and if possible, Papyrus logs. If your problem/suggestion is surrounding balance then I suggest the same, minus the Papyrus logs. Again, screaming at me about something you don’t like will get you nowhere. I do recommend that you submit your feedback to my Discord server as I will probably be less active on the Nexus, and I have dedicated channels for these topics. [You can join the server here](https://discord.gg/628vCrz) (be sure to request membership on arrival). 

 
### *How long is this mod going to take?!?*

Keep in mind that I (SMB92) am I only one man, and I am a very busy man with a family and fulltime job, so progress is fairly slow, but I am committed to seeing this through. More features and more areas will be covered over time, and as I produce more documentation I suspect more addons will come too. It has been a long road, and still a long road ahead. Your patience is appreciated while work continues, as with all good things, it takes time. And it will come to an end.  

 
### *Some history about the mod & credits*

I begun this project after I was offered to take over the very large “War of the Commonwealth” project by Engager and Coreyhooe, after both very talented authors decided to move on to other life projects. After realising the shortcomings of the engine, I decided that it would be far better to start from scratch, using methods that will “just work™”, all the while learning for myself exactly what doesn’t “just work™”. While I (SMB92) am the primary author behind this mod, I have not produced this massive project alone as I was very fortunate early-on to run into fellow modder and author Jonathon “BigAndFlabby” Ostrus, a man who just understands this stuff and widely considered a guru among the mod author community. He was generous enough to reply to my help requests and thus taught/deciphered for me much of the “inside” knowledge that I have today, without which this mod would either still be in the stone age, or non-existent. As such I attribute a good majority of the credit for this project to him, and you should do the same [by leaving him kudos on his Nexus page here.](https://www.nexusmods.com/fallout4/users/14649434))  Of course there have been others who have contributed either directly or indirectly, a list of credits is being compiled and will be published in future.  

 
### *Conclusion*

Thanks for taking the time to read this article. If you have any questions or concerns, please leave a comment in the appropriate channels on the Discord server, or if urgent, send me a PM/DM. Again, your patience is appreciated while work continues. 