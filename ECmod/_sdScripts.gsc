/** Sh0k'
Pregame manages a freezetime before any s&d game starts. It holds players until both sides are ready.
The admin initializes the game by modifying the startGame cvar. 
 */
pregame(){
    if (isDefined(level.doneHalftime) || game["pregame"] == false)
        return;

    if (getcvarint("startGame") != 0)
        return;

    //Announce waiting
    level.admin_wait = newHudElem();
    level.admin_wait.x = 320;
    level.admin_wait.y = 100;
    level.admin_wait.alignX = "center";
    level.admin_wait.alignY = "middle";
    level.admin_wait.fontscale = 1.3;
	level.admin_wait setText(game["adminWait"]);

	level.admin_start = newHudElem();
    level.admin_start.x = 320;
    level.admin_start.y = 115;
    level.admin_start.alignX = "center";
    level.admin_start.alignY = "middle";
    level.admin_start.fontscale = 1;
	level.admin_start setText(game["adminStart"]);

    //hold all players
    setcvar("g_speed", 0);

    //wait until startGame is updated
    while (getcvarint("startGame") == 0){
        wait 0.1;
    }
    
    if (getcvarint("startGame") != 0){
        
        //Destroy waiting HUDs
        level.admin_wait destroy();
        level.admin_start destroy();
        
        
        //Announce game starting
        level.print_starting = newHudElem();
        level.print_starting.x = 320;
        level.print_starting.y = 100;
        level.print_starting.alignX = "center";
        level.print_starting.alignY = "middle";
        level.print_starting.fontscale = 1.3;
        level.print_starting setText(game["printStarting"]);
       
        wait 4;

        level.print_starting destroy();
        /*
        //Announce Live
        level.print_live = newHudElem();
        level.print_live.x = 320;
        level.print_live.y = 100;
        level.print_live.alignX = "center";
        level.print_live.alignY = "middle";
        level.print_live.fontscale = 1.3;
        level.print_live setText(game["matchLive"]);

        wait 1.8;        

        level.print_live destroy();
        */

        //unfreeze
        setcvar("g_speed", 190);
        game["pregame"] = false;

        
    }

    return;

}

/** Sh0k'
Manages the halftime functionality. Switches sides halfway through the map. Logic for the switch is adapted
from PAM v2.04. HUD elements are custom. 
 */
halftime(){
    //Let the game know that the next stratTime should be extended
    game["halftimeStratTime"] = true;

    level.doneHalftime = 1;


    //HUDs
    level.halftime_top = newHudElem();
    level.halftime_top.x = 320;
    level.halftime_top.y = 100;
    level.halftime_top.alignX = "center";
    level.halftime_top.alignY = "middle";
    level.halftime_top.fontscale = 1.3;
	level.halftime_top setText(game["halftime1"]);

	level.loser_bottom = newHudElem();
    level.loser_bottom.x = 320;
    level.loser_bottom.y = 115;
    level.loser_bottom.alignX = "center";
    level.loser_bottom.alignY = "middle";
    level.loser_bottom.fontscale = 1;
	level.loser_bottom setText(game["halftime2"]);

    wait 6 * level.ec_fpsMultiplier;

    level.halftime_top destroy();
    level.loser_bottom destroy();
    

    /* From PAM v2.04 */
    //Swapping scores
    temp = game["alliedscore"];
    game["alliedscore"] = game["axisscore"];
    game["axisscore"] = temp;

    setTeamScore("axis", game["axisscore"]);
    setTeamScore("allies", game["alliedscore"]);

    //Storing models
    axismodel = undefined;
    alliedmodel = undefined;

    playerList = getentarray("player", "classname");

    //For all players
    for (i = 0; i < playerList.size; i++){
        player = playerList[i];


        //Switch teams
        if ((isDefined(player.pers["team"])) && (player.pers["team"] == "axis")){
            player.pers["team"] = "allies";
            axismodel = player.pers["savedmodel"];        
        }else if ((isDefined(player.pers["team"])) && (player.pers["team"] == "allies")){
            player.pers["team"] = "axis";
            alliedmodel = player.pers["savedmodel"];       
        }

        //Swap Models
		if ( (isdefined(player.pers["team"]) ) && (player.pers["team"] == "axis") )
			 player.pers["savedmodel"] = axismodel;
		else if ( (isdefined(player.pers["team"])) && (player.pers["team"] == "allies") )
			player.pers["savedmodel"] = alliedmodel;


        //drop weapons and make spec
		player.pers["weapon"] = undefined;
		player.pers["weapon1"] = undefined;
        player.pers["weapon2"] = undefined;
		player.pers["spawnweapon"] = undefined;
		player.pers["selectedweapon"] = undefined;
		player.archivetime = 0;
		player.reflectdamage = undefined;

		player unlink();
		player enableWeapon();

        //change headicons (should they be enabled)
		if(level.drawfriend)
		{
			if(player.pers["team"] == "allies")
			{
				player.headicon = game["headicon_allies"];
				player.headiconteam = "allies";
			}
			else
			{
				player.headicon = game["headicon_axis"];
				player.headiconteam = "axis";
			}
		}

    }
   
return;

   
}
/** Sh0k'
Freezes players for a set length of time at the beginning of every round to allow discussion of 
strategy, as well as allow players to switch their weapons in preparation of the round. 
 */
stratTime(time){
    //the time we will have to wait for accounting for increased sv_fps
    strattime = time * level.ec_fpsMultiplier;
    
    //if this round is a halftime round, set the next round to be a default round
    if (time == level.ec_sdFirstRoundStratTime)
        game["halftimeStratTime"] = false; 

    //let the game know to wait before starting the round
    game["stratTime"] = true;

    //freeze players
    setcvar("g_speed", 0);

    //HUDs
    level.strat_time = newHudElem();
    level.strat_time.x = 320;
    level.strat_time.y = 100;
    level.strat_time.alignX = "center";
    level.strat_time.alignY = "middle";
    level.strat_time.fontscale = 1.6;
	level.strat_time setText(game["strattime"]);

	level.strat_clock = newHudElem();
    level.strat_clock.x = 320;
    level.strat_clock.y = 115;
    level.strat_clock.alignX = "center";
    level.strat_clock.alignY = "middle";
    level.strat_clock.fontscale = 1.3;
	level.strat_clock setTimer(time);

    wait strattime;

    level.strat_time destroy();
    level.strat_clock destroy();

    //strat time over, start the round
    game["stratTime"] = false;
    //unfreeze
    setcvar("g_speed", 190);

}

endMatch(){
    game["winnerScreen"] = true;

    if(game["alliedscore"] > game["axisscore"])
        winner = "allies";
    else
        winner = "axis";

    players = getentarray("player", "classname");

    for (i = 0; i < players.size; i++){
        player = players[i];

        if (winner == "allies"){
            if (player.pers["team"] == "allies"){
                //player thread displayWinnerHuds(1); //allies win i'm allies
                player iprintlnbold("^2-=VICTORY=-");
                player iprintlnbold("Good work soldier!");
                
            }                
            else{
                //player thread displayWinnerHuds(0); //allies win i'm axis
                player iprintlnbold("^1-=DEFEAT=-");
                player iprintlnbold("Better luck next time");
                 
            }
                
        }else{
            if (player.pers["team"] == "allies"){
                //player thread displayWinnerHuds(0); //axis win i'm allies
                player iprintlnbold("^1-=DEFEAT=-");
                player iprintlnbold("Better luck next time");
                
            }
                
            else{
                //player thread displayWinnerHuds(1); //axis win i'm axis
                player iprintlnbold("^2-=VICTORY=-");
                player iprintlnbold("Good work soldier!");
                
            }
                
        }   

    }
    wait 10;
    game["winnerScreen"] = false;
    return;
}


