// Modified by La Truffe

init()
{
	thread StartThreads();
}

StartThreads()
{
	wait .05;
	level endon("awe_killthreads");

	thread SpawnBots();
}

SpawnBots()
{	
	level endon("awe_killthreads");

	wait 2;

	if(level.awe_debug)
		iprintln(level.awe_allplayers.size + " players found.");

	numbots = 0;
	// Catch & count running bots and start their think threads.
	for(i=0;i<level.awe_allplayers.size;i++)
	{
		if(isdefined(level.awe_allplayers[i]))
		{
			player = level.awe_allplayers[i];
			if(player.name.size==4 || player.name.size==5)
			{
				if(player.name[0] == "b" && player.name[1] == "o" && player.name[2] == "t")
				{
					player thread bot_think();
					numbots++;
				}
			}
		}
	}
	
	for(;;)
	{
		wait 3;

		// Any new bots to add?
		awe_bots = awe\_util::cvardef("awe_bots", 0, 0, 99, "int");
		newbots = awe_bots - numbots;
	
		// Any new bots to add?
		if(newbots<=0)
			continue;

		for(i = 0; i < newbots; i++)
		{
			bot = addtestclient();
// La Truffe ->
//			wait 0.5;
			wait 0.1;
// La Truffe <-
			if(isdefined(bot) && isPlayer(bot))
				bot thread bot_think();
			numbots++;
// La Truffe ->
			wait 0.5;
// La Truffe <-
		}
	}
}

bot_think()
{
	level endon("awe_boot");

	if(level.awe_debug)
		iprintln("Starting think thread for: " + self.name);

	if(isPlayer(self))
	{
		for(;;)
		{
// La Truffe ->
			if (! isdefined (self))
				return;
// La Truffe <-		
			if(!isAlive(self) && self.sessionstate != "playing")
			{
				if(level.awe_debug)
					iprintln(self.name + " is sending menu responses.");

				self notify("menuresponse", game["menu_team"], "autoassign");

				wait 0.5;	

// La Truffe ->
/*
				if(self.pers["team"]=="axis")
				{
					self notify("menuresponse", game["menu_weapon_axis"], "kar98k_mp");
				}
				else
				{
					self notify("menuresponse", game["menu_team"], "allies");
					wait 0.5;
					if(game["allies"] == "russian")
						self notify("menuresponse", game["menu_weapon_allies"], "mosin_nagant_mp");
					else
						self notify("menuresponse", game["menu_weapon_allies"], "springfield_mp");
				}
*/
				if (isdefined (self.pers["team"]))
					switch (game[self.pers["team"]])
					{
						case "american" :
							self notify ("menuresponse", game["menu_weapon_allies"], "springfield_mp");
							if (level.awe_secondaryweapon)
							{
								wait 0.5;
								self notify ("menuresponse", game["menu_weapon2_allies"], "thompson_mp");
							}
							break;

						case "british" :
							self notify ("menuresponse", game["menu_weapon_allies"], "enfield_scope_mp");
							if (level.awe_secondaryweapon)
							{
								wait 0.5;
								self notify ("menuresponse", game["menu_weapon2_allies"], "sten_mp");
							}
							break;

						case "russian" :
							self notify ("menuresponse", game["menu_weapon_allies"], "mosin_nagant_sniper_mp");
							if (level.awe_secondaryweapon)
							{
								wait 0.5;
								self notify ("menuresponse", game["menu_weapon2_allies"], "PPS42_mp");
							}
							break;

						case "german" :
							self notify ("menuresponse", game["menu_weapon_axis"], "kar98k_sniper_mp");
							if (level.awe_secondaryweapon)
							{
								wait 0.5;
								self notify ("menuresponse", game["menu_weapon2_axis"], "mp40_mp");
							}
							break;

						default :
							break;
					}
// La Truffe <-
			}
			wait 10;
		}
	}
}