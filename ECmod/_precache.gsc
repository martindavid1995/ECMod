/** Sh0k'
Used for precaching all strings used in custom HUD elements
 */
init(){
    game["adminWait"] = &"^1-=Waiting for Admin to start game=-";
	precacheString(game["adminWait"]);

    game["adminStart"] = &"Admin, start the game with command: /rcon startGame 1";
    precacheString(game["adminStart"]);

    game["printStarting"] = &"^3-=Match Starting=-";
    precacheString(game["printStarting"]);

    game["matchLive"] = &"^2-=MATCH LIVE=-";
    precacheString(game["matchLive"]);

    game["halftime1"] = &"^1-=HALFTIME=-";
    precacheString(game["halftime1"]);

    game["halftime2"] = &"Switching sides";
    precacheString(game["halftime2"]);

    game["strattime"] = &"^3-=Strat Time=-";
    precacheString(game["strattime"]);

    game["winningTeam1"] = &"^2-=VICTORY=-";
    precacheString(game["winningTeam1"]);

    game["winningTeam2"] = &"Good work soldier!";
    precacheString(game["winningTeam2"]);

    game["losingTeam1"] = &"^1-=DEFEAT=-";
    precacheString(game["losingTeam1"]);

    game["losingTeam2"] = &"Better luck next time";
    precacheString(game["losingTeam2"]);
    
}
