init()
{
	// Show team status on hud
	level.awe_showteamstatus	= awe\_util::cvardef("awe_show_team_status", 0, 0, 1, "int");

	// Check for duplicate player names and change them
	level.awe_dupecheck		= awe\_util::cvardef("awe_dupecheck", 0, 0, 1, "int");

	if(level.awe_teamplay && level.awe_showteamstatus)
	{
		game["headicon_axis"] = "headicon_" + game["axis"];
		game["headicon_allies"] = "headicon_" + game["allies"];
		// Precache
		if(!isdefined(game["gamestarted"]))
		{
			precacheShader(game["headicon_allies"]);
			precacheShader(game["headicon_axis"]);
			precacheShader("hud_status_dead");
		}
	}

	thread StartThreads();
}

StartThreads()
{
	wait .05;

	level endon("awe_killthreads");

	thread UpdateTeamStatus();

}

UpdateTeamStatus()
{
	level endon("awe_killthreads");

	for(;;)
	{
		wait 1;

		// Update player array
		level.awe_allplayers = getentarray("player", "classname");

		if(level.awe_dupecheck)
		{
			for(i = 0; i < (level.awe_allplayers.size-1); i++)
			{
				player = level.awe_allplayers[i];  
				for(j = (i+1); j < level.awe_allplayers.size; j++)
			  	{
					player2 = level.awe_allplayers[j];
					if (player.name == player2.name)
					{
						player2 setClientCvar("name", player2.name + "<DUPE>");
						player2 iprintlnbold(&"AWE_DUPLICATE_PLAYER_NAMES");
					}
				}
			}
		}

		if(!level.awe_showteamstatus || !level.awe_teamplay)
			continue;

		color = (1,1,0);
		deadcolor = (1,0,0);
		if(!isdefined(level.awe_axisicon))
		{
			level.awe_axisicon = newHudElem();	
			level.awe_axisicon.x = 624;
			level.awe_axisicon.y = 20;
			level.awe_axisicon.alignX = "center";
			level.awe_axisicon.alignY = "middle";
			level.awe_axisicon.alpha = 0.7;
			level.awe_axisicon setShader(game["headicon_axis"],16,16);
		}
		if(!isdefined(level.awe_axisnumber))
		{
			level.awe_axisnumber = newHudElem();	
			level.awe_axisnumber.x = 624;
			level.awe_axisnumber.y = 36;
			level.awe_axisnumber.alignX = "center";
			level.awe_axisnumber.alignY = "middle";
			level.awe_axisnumber.alpha = 0.8;
			level.awe_axisnumber.fontscale = 1.0;
			level.awe_axisnumber.color = color;
			level.awe_axisnumber setValue(0);
		}
		if(!isdefined(level.awe_deadaxisicon))
		{
			level.awe_deadaxisicon = newHudElem();	
			level.awe_deadaxisicon.x = 592;
			level.awe_deadaxisicon.y = 52;
			level.awe_deadaxisicon.alignX = "center";
			level.awe_deadaxisicon.alignY = "middle";
			level.awe_deadaxisicon.alpha = 0.7;
			level.awe_deadaxisicon setShader("hud_status_dead",16,16);
		}
		if(!isdefined(level.awe_deadaxisnumber))
		{
			level.awe_deadaxisnumber = newHudElem();	
			level.awe_deadaxisnumber.x = 624;
			level.awe_deadaxisnumber.y = 52;
			level.awe_deadaxisnumber.alignX = "center";
			level.awe_deadaxisnumber.alignY = "middle";
			level.awe_deadaxisnumber.alpha = 0.8;
			level.awe_deadaxisnumber.fontscale = 1.0;
			level.awe_deadaxisnumber.color = deadcolor;
			level.awe_deadaxisnumber setValue(0);
		}
		if(!isdefined(level.awe_alliedicon))
		{
			level.awe_alliedicon = newHudElem();	
			level.awe_alliedicon.x = 608;
			level.awe_alliedicon.y = 20;
			level.awe_alliedicon.alignX = "center";
			level.awe_alliedicon.alignY = "middle";
			level.awe_alliedicon.alpha = 0.7;
			level.awe_alliedicon setShader(game["headicon_allies"],16,16);
		}
		if(!isdefined(level.awe_alliednumber))
		{
			level.awe_alliednumber = newHudElem();	
			level.awe_alliednumber.x = 608;
			level.awe_alliednumber.y = 36;
			level.awe_alliednumber.alignX = "center";
			level.awe_alliednumber.alignY = "middle";
			level.awe_alliednumber.alpha = 0.8;
			level.awe_alliednumber.fontscale = 1.0;
			level.awe_alliednumber.color = color;
			level.awe_alliednumber setValue(0);
		}
		if(!isdefined(level.awe_deadalliednumber))
		{
			level.awe_deadalliednumber = newHudElem();	
			level.awe_deadalliednumber.x = 608;
			level.awe_deadalliednumber.y = 52;
			level.awe_deadalliednumber.alignX = "center";
			level.awe_deadalliednumber.alignY = "middle";
			level.awe_deadalliednumber.alpha = 0.8;
			level.awe_deadalliednumber.fontscale = 1.0;
			level.awe_deadalliednumber.color = deadcolor;
			level.awe_deadalliednumber setValue(0);
		}
		allies = [];
		axis = [];
		deadallies = [];
		deadaxis = [];
		for(i = 0; i < level.awe_allplayers.size; i++)
		{
			if(level.awe_allplayers[i].sessionstate == "playing" && level.awe_allplayers[i].sessionteam == "allies")
				allies[allies.size] = level.awe_allplayers[i];
			if(level.awe_allplayers[i].sessionstate != "playing" && level.awe_allplayers[i].sessionteam == "allies")
				deadallies[deadallies.size] = level.awe_allplayers[i];
			if(level.awe_allplayers[i].sessionstate == "playing" && level.awe_allplayers[i].sessionteam == "axis")
				axis[axis.size] = level.awe_allplayers[i];
			if(level.awe_allplayers[i].sessionstate != "playing" && level.awe_allplayers[i].sessionteam == "axis")
				deadaxis[deadaxis.size] = level.awe_allplayers[i];
		}
		level.awe_axisnumber setValue(axis.size);
		level.awe_alliednumber setValue(allies.size);
		level.awe_deadaxisnumber setValue(deadaxis.size);
		level.awe_deadalliednumber setValue(deadallies.size);
	}
}
