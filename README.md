# Easy Company Call of Duty 2 Mod
## Purpose
ECMod was created to bring back and refresh the pure Call of Duty 2 Multiplayer experience that so many people fell in love with in the late 2000s. CoD2 has a history of being very modder-friendly, 
and over the years many sophisticated game-changing mods increased in popularity - bringing the game further away from it's pure vanilla experience. Nowadays, the only popular servers
that still exist run extremely overworked modpacks which make the game play nothing like the CoD2 that so many of us remember and love. 

CoD2 was loved for its simplicity and responsiveness. It was a game that rewarded the player for their precision, reaction time, and game knowledge/experience. Heavy modpacks sacrifice these
elements in their quest to add features that mimic more modern FPS titles. They do this by adding clunky scripts (that oftentimes create hundreds of concurrent threads) that bog down the game engine causing lag and poor hit-detection. 
To compensate for the newly introduced lag, these mods oftentimes apply huge damage and fire-rate modifications to their weapons, add "killstreak" features like airstrikes, and increase the number of grenades allowed on the map. 
These changes appeal to the lesser-skilled players who take the game less seriously, but for those of us who love the game in its competitive sense, a lot is missing.

And thus, the desire was there. We wanted to create something that was as close to vanilla as possible, that had perfect hit-detection and response time. We wanted to include
small QOL features that we enjoyed using in the early days of CoD2 mods such as sprinting and weapon restrictions. Most importantly, we wanted to offer the highest performance as possible,
which involved "overclocking" the game in a sense. 

By default, CoD2 servers are coded to run at a `sv_fps` value of 20, or 20 server updates per second. The game engine, however, allows for this value to be increased up to 30 updates per second. 
This increase in tickrate provides better server responsiveness, smoothness, and hit detection. 
Modern server and PC hardware can easily handle this increase in tickrate, however the game is not coded with this in mind, and thus increasing the server tickrate causes a lot of internal
timing issues within the game code. Making such a change requires significant modifications to the game's source code in order to compensate for the game running at 133% clock speed. 
This was the first goal that we set to accomplish with the ECMod, and all other additions and tweaks happened as our excitement to play the game again grew. 

## Goals
 - Maximize performance with `sv_fps = 30`
 - Keep all weapons stock (except for minor nerfs to weapons deemed overpowered by default)
 - Include minor QOL additions (primarily those found in the AWE mod)
 - Completely custom Search and Destroy features to facilitate competitive play (heavily inspired by the CoD2 PAM mod as well as other competitive FPS titles)

## Key Features
  ### From AWEv3CE
    - Sprinting
    - Grenade cooking
    - Enabling secondary weapons
    - MG overheat timers
    - Map vote system
  ### Custom
    - Overhaul of gamemode timings to account for increased `sv_fps`
    - Weapon balancing (Shotgun nerf, BAR/Bren buff)
    - Custom all-weapons menus
    - Custom rifles-only menus, and the ability to designate maps as rifles-only from the server config
    - Removal of ambient effects
    - Custom maps
    - Search and Destroy:
      - Halftime attacker/defender switch
      - Pregame freeze time
      - Preround freeze time (strat time)
      - Configurable round times and round limits
      - Disabling carryover weapons into new rounds
      - Displaying winner/loser at game end
      
## Challenges
 - Due to the game coming out in 2005 and most modders stopping working on the game by the early 2010s, there is a severe lack of documentation and modding resources for CoD2. We went in with nothing. All knowledge about how the game runs needed to be self-taught through trial-and-error testing, studying source code/developer comments, and studying the source code of other released mods. It took dozens of hours to get our first console logs to work, and It took dozens more to become even moderately comfortable with making changes to the game.
 - CoD2 runs on a modified version of the id Tech 3 engine which is referred to as the IW2.0 engine. This amount of work that this engine handles is laughably small compared to modern game engines. 
 This archaic version of the IW engine basically only handles player movement, bullet trajectories, hit detection, and basic physics. Because of this, the game has an absurdly large amount of source code which made understanding
 how the game works very difficult. On top of this, if you ever wanted to find out how a certain game feature was coded for reference, you had thousands of source files to search through. Fun Fact: Every Call of Duty title since CoD2 runs on a version of the same IW Engine that has been used since CoD2 in 2005. Instead of building a new engine, the devs have just been adding functionality to the existing IW engine for 15+ years in order to handle their modern titles. 
 - There is no debugger, no handy IDE that catches your foolish mistakes, no access to a compiler, and no access to any engine code whatsoever. If you make one mistake, everything breaks. Getting too confident and changing too many things at once before testing usually was followed by numerous hours rewinding your changes to find that pesky `;` that you omitted.  
 - The build process is horribly slow and tedious. First you make a change in code, then you must then re-zip the mod package, upload it to the server, restart the server, join the server, login to remote-console, and then finally restart the map in order to see if your changes did anything, or if the server was completely broken.  
 - The game is simply, old - and the people who worked on it are impossible to get in touch with. It was difficult to find any resources to ease the modding process. We were oftentimes stuck on simple problems for days, if not weeks - forced to spend many hours painstakingly making tiny changes and testing until we could find a solution or a work-around. 
 
## Try it out on our server
-=EC=- All Weapons : `/connect 162.248.88.202:28960`

## Want to play with us?
Join our [discord](https://discord.gg/jxXwQRfNSn) server!

## Special Thanks
 - `-=EC=-Nitemare` for spending countless hours with me developing new menus, testing, researching, brainstorming ideas, and fixing bugs.
 - `-=EC=-Artorias` and `-=EC=-Gimp` for their help testing and coming up with ideas for new features and changes.
 - `BeerGolem` for his help and support in testing, as well as providing critical information and suggestions in the early days of the project. 
 - `Broaconstrictor` for hopping on at the drop of a hat to help me test S&D features when nobody else was online. 
 - Other members of the CoD2 community for their help testing, suggestions, and feedback throughout the development of the project. 
 - The `Easy Company Gaming` community for all of the good times. 
