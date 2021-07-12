// Modified by La Truffe and Sh0k'

init()
{

//Sh0k >>
if(ECmod\_util::isRiflesOnly(getcvar("mapname"))){

		level.awe_secondaryweapon = awe\_util::cvardef("awe_secondary_weapon", 0, 0, 2, "int");
		if(level.awe_secondaryweapon)
		{
			game["menu_weapon2_allies"] = "weapon2_rifle";
			game["menu_weapon2_axis"] = "weapon2_rifle";
			precacheMenu(game["menu_weapon2_allies"]);
			precacheMenu(game["menu_weapon2_axis"]);
		}
	

		game["menu_ingame"] = "ingame";
		game["menu_team"] = "team_" + game["allies"] + game["axis"];
		game["menu_weapon_allies"] = "weapon_rifle";
		game["menu_weapon_axis"] = "weapon_rifle";
		
		precacheMenu(game["menu_ingame"]);
		precacheMenu(game["menu_team"]);
		precacheMenu(game["menu_weapon_allies"]);
		precacheMenu(game["menu_weapon_axis"]);

}else{ //Sh0k <<

	////// Added for AWE //////
		level.awe_secondaryweapon = awe\_util::cvardef("awe_secondary_weapon", 0, 0, 2, "int");
		if(level.awe_secondaryweapon)
		{
			game["menu_weapon2_allies"] = "weapon2_" + game["allies"];
			game["menu_weapon2_axis"] = "weapon2_" + game["axis"];
			precacheMenu(game["menu_weapon2_allies"]);
			precacheMenu(game["menu_weapon2_axis"]);
		}
	///////////////////////////

		game["menu_ingame"] = "ingame";
		game["menu_team"] = "team_" + game["allies"] + game["axis"];
		game["menu_weapon_allies"] = "weapon_" + game["allies"];
		game["menu_weapon_axis"] = "weapon_" + game["axis"];
		
		precacheMenu(game["menu_ingame"]);
		precacheMenu(game["menu_team"]);
		precacheMenu(game["menu_weapon_allies"]);
		precacheMenu(game["menu_weapon_axis"]);

}


	if(!level.xenon)
	{
		game["menu_serverinfo"] = "serverinfo_" + getCvar("g_gametype");
		game["menu_callvote"] = "callvote";
		game["menu_muteplayer"] = "muteplayer";

		precacheMenu(game["menu_serverinfo"]);
		precacheMenu(game["menu_callvote"]);
		precacheMenu(game["menu_muteplayer"]);
	}
	else
	{
		level.splitscreen = isSplitScreen();
		if(level.splitscreen)
		{
			game["menu_team"] += "_splitscreen";
			game["menu_weapon_allies"] += "_splitscreen";
			game["menu_weapon_axis"] += "_splitscreen";
			game["menu_ingame_onteam"] = "ingame_onteam_splitscreen";
			game["menu_ingame_spectator"] = "ingame_spectator_splitscreen";

			precacheMenu(game["menu_team"]);
			precacheMenu(game["menu_weapon_allies"]);
			precacheMenu(game["menu_weapon_axis"]);
			precacheMenu(game["menu_ingame_onteam"]);
			precacheMenu(game["menu_ingame_spectator"]);
		}
	}

	level thread onPlayerConnect();
}

isRifleOnlyMap(){



}

onPlayerConnect()
{
	for(;;)
	{
		level waittill("connecting", player);
		player thread onMenuResponse();
	}
}

onMenuResponse()
{
//////// Added for AWE //////
	bypass = false;
	response = "";
	response2 = "";
	menu = "";
/////////////////////////////
	for(;;)
	{
// La Truffe ->
		lastmenu = menu;
// La Truffe <-
/////////// Changed for AWE ////////
		if(!bypass)
			self waittill("menuresponse", menu, response);
		bypass = false;
////////////////////////////////////
		//iprintln("^6", response);

		if(response == "back")
		{
			self closeMenu();
			self closeInGameMenu();

			if(menu == game["menu_team"])
			{
				if(level.splitscreen)
				{
					if(self.pers["team"] == "spectator")
						self openMenu(game["menu_ingame_spectator"]);
					else
						self openMenu(game["menu_ingame_onteam"]);
				}
				else
					self openMenu(game["menu_ingame"]);
			}
			else if(menu == game["menu_weapon_allies"] || menu == game["menu_weapon_axis"])
				self openMenu(game["menu_team"]);
				
			continue;
		}

		if(response == "endgame")
		{
			if(level.splitscreen)
			{
				level thread [[level.endgameconfirmed]]();
			}
			else if (level.xenon)
			{
				endparty();
				level thread [[level.endgameconfirmed]]();
			}
				
			continue;
		}

		if(response == "endround")
		{
			level thread [[level.endgameconfirmed]]();
			continue;
		}


		if(menu == game["menu_ingame"] || (level.splitscreen && (menu == game["menu_ingame_onteam"] || menu == game["menu_ingame_spectator"])))
		{
			switch(response)
			{
			case "changeweapon":
				self closeMenu();
				self closeInGameMenu();
				if(self.pers["team"] == "allies")
					self openMenu(game["menu_weapon_allies"]);
				else if(self.pers["team"] == "axis")
					self openMenu(game["menu_weapon_axis"]);
				break;	

			case "changeteam":
				self closeMenu();
				self closeInGameMenu();
				self openMenu(game["menu_team"]);
				break;

			case "muteplayer":
				if(!level.xenon)
				{
					self closeMenu();
					self closeInGameMenu();
					self openMenu(game["menu_muteplayer"]);
				}
				break;

			case "callvote":
				if(!level.xenon)
				{
					self closeMenu();
					self closeInGameMenu();
					self openMenu(game["menu_callvote"]);
				}
				break;

// La Truffe ->
			case "serverinfo" :
				self closeMenu ();
				self closeInGameMenu ();
				self openMenu (game["menu_serverinfo"]);
				break;			
// La Truffe <-
			}
		}
		else if(menu == game["menu_team"])
		{
			switch(response)
			{
			case "allies":
				self closeMenu();
				self closeInGameMenu();
				self [[level.allies]]();
				break;

			case "axis":
				self closeMenu();
				self closeInGameMenu();
				self [[level.axis]]();
				break;

			case "autoassign":
				self closeMenu();
				self closeInGameMenu();
				self [[level.autoassign]]();
				break;

			case "spectator":
				self closeMenu();
				self closeInGameMenu();
				self [[level.spectator]]();
				break;
			}
		}
		else if(menu == game["menu_weapon_allies"] || menu == game["menu_weapon_axis"])
		{
			self closeMenu();
			self closeInGameMenu();
//////// Added for AWE //////
			self closeMenu();
			self closeInGameMenu();
			if(level.awe_secondaryweapon)
			{
				// Which menu shall we open?
				if( (self.pers["team"] == "allies" && level.awe_secondaryweapon == 1) || (self.pers["team"] == "axis" && level.awe_secondaryweapon == 2) )
					menu2 = game["menu_weapon2_allies"];
				else if( (self.pers["team"] == "axis" && level.awe_secondaryweapon == 1) || (self.pers["team"] == "allies" && level.awe_secondaryweapon == 2))
					menu2 = game["menu_weapon2_axis"];
				else
					break;

				weapon = "restricted";
				while(weapon == "restricted")
				{
					// Open the menu
					self openMenu(menu2);

					// Wait for response
					self waittill("menuresponse", menu, response2);

					// Did we get a response from the correct menu?
					if(menu == menu2)
					{
						self closeMenu();
						self closeInGameMenu();
						if(response == response2)
							weapon = "restricted";
						else if(response2 == "none")
							weapon = "none";
						else
							weapon = self maps\mp\gametypes\_weapons::restrictWeaponByServerCvars(response2);
						
						if(weapon != "restricted")
						{
//							iprintlnbold(response2);
							if(weapon != "none")
								self.pers["secondaryweapon"] = weapon;
							else
								self.pers["secondaryweapon"] = undefined;
							break;
						}
					}
					else
					{
						bypass = true;
						break;
					}
				}
			}
/////////////////////////////
			self [[level.weapon]](response);
//////// Added for AWE ////////
			if(bypass)	// Restore response if we are bypassing
				response = response2;
///////////////////////////////
		}
		else if(!level.xenon)
		{
			if(menu == game["menu_quickcommands"])
				maps\mp\gametypes\_quickmessages::quickcommands(response);
			else if(menu == game["menu_quickstatements"])
				maps\mp\gametypes\_quickmessages::quickstatements(response);
			else if(menu == game["menu_quickresponses"])
				maps\mp\gametypes\_quickmessages::quickresponses(response);
			else if(menu == game["menu_serverinfo"] && response == "close")
			{
				self closeMenu();
				self closeInGameMenu();
// La Truffe ->
/*
				self openMenu(game["menu_team"]);
				self.pers["skipserverinfo"] = true;
*/
				if (lastmenu != game["menu_ingame"])
				{
					self openMenu (game["menu_team"]);
					self.pers["skipserverinfo"] = true;
				}
// La Truffe <-
			}
		}
	}
}
