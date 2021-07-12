// Modified by La Truffe

/*
	==============
	 Conquest TDM
	==============
	Objective: 	Score points and take ground for your team by eliminating players on the 
	opposing team and advancing spawn points.
	Map ends:	When one team reaches the score limit, or time limit is reached
	Respawning:	No wait / Near teammates based on objectives. Players generally spawn 
	behind their teammates relative to the direction of enemies, but the areas 
	that are used for spawning are determined by the current objective that was last taken.

	Original Developers:
  
    innocent bystander
    admin, after hourz
    bystander@after-hourz.com
  
	Visit www.after-hourz.com for kickass public COD servers and a great community.
  
  Credits:
  * Mark 'Slyk' Dittman - Mapper extrodanaire and the initial developer of 
    Conquest TDM on Spearhead.
  * [MC]Hammer - Some utility string transform code is incorporated, and his
    CoDaM HUD code was used and modifed for this gametype.
  * The whole After Hourz community, but especially Painkiller, Fart, Shep, 
    Kamikazee Driver, Poopybuttocks, and Shep for ideas, motivation and friendship.
  * Last but not least, many members of the COD community with help in learning this
    language and patiently answering my questions, including [MC]Hammer, 
    ScorpioMidget, Ravir, [IW]HkySk8r187, and others I probably fail to mention. 
    
    Thanks to you all!
    
	Level requirements
	------------------
		Spawnpoints:
			classname	=	mp_teamdeathmatch_spawn
			script_gameobjectname = cnq or conquest (optional). Set if you only want 
			these spawns used for the conquest game type, otherwise all TDM-spawn 
			gametypes will use it as well. targetname = Either "defenders#" or 
			"attackers#", where # is the objective you want this set of spawns to 
			be associated with, for example "attackers1", "defenders2". This is 
			the group number of the spawns, and is tied directly to the spawn 
			objective's script_idnumber (see below).Spawnpoints are team-based, 
			unlike regular TDM spawns. This is done through setting	a targetname. 
			Obtaining an objective with a particular idnumber will mean that all 
			the team spawns with this matching script_idnumber will be chosen to 
			spawn the player, and the script will place them near their team from 
			among the spawns in this numerical grouping.

		Spectator Spawnpoints:
			classname		mp_teamdeathmatch_intermission
			Spectators spawn from these and intermission is viewed from these positions.
			At least one is required, any more and they are randomly chosen between.

	  Objectives:
	    There are 2 types of objectives, spawn objectives and optional 
	    bonus objectives. All Objectives must be controlled in linear order, 
	    meaning you must control previous objectives to take other objectives. 
	    Spawn objectives allow teams to move their spawns forward toward the 
	    enemy base, while at the same time pushing back their opponents spawns.
	    Bonus objectives, if used in a given map, are at the ends of each chain 
	    and give a team a point bonus, and are not used to move spawn positions.
	  
	    Creating Spawn Objectives
	    =========================
	    
      Spawn Objective Triggers
      ------------------------
      Triggers are placed where you want players to take objectives. Typical
      triggers are modeled as switches, or some other player-activated thing.
      But you can really make it whatever you want that fits your map's style.
      Place the trigger in the map position you want it.
      
      * classname = trigger_use or trigger_multiple (depending on your map). 
        Most CNQ maps use trigger_use.
      * script_gameobjectname = cnq or conquest
      * delay = (time in sections between triggers OPTIONAL) - If you want to 
        delay an objective from being retaken, put an integer value in for this
        reprenting the number of seconds before the objective can be retaken by
        the other team. Default is immediately if not provided.
      * hintstring = (your descriptive text) This tells players what to do if 
        you choose to use trigger_use classes. Typical text would be something
        like "Press [Use} to take this objective!"
      
	    Spawn Objectives
	    ----------------	  
	    * classname = script_model
			* script_gameobjectname = cnq or conquest
			* targetname = spawnobjective
			* script_idnumber = an integer number. This is the numeric order of the 
			  spawn objective. Typically there are a number of spawn objectives that 
			  number starting with 1 and increasing	to the number of objectives in 
			  your map. Most CNQ maps have between 3 and 5 spawn objectives, but 
			  there's no real limit other than there must be at least 1. The number 
			  you give this sets the path of the battle in your map, as teams will 
			  have to progress up and down the chain of	spawn objectives.
			* script_objective_name = (your descriptive text) - Used in game 
			  messages to tell players the name of their next objective. If not 
			  supplied a default name is used.
			
			Targeting the trigger
			---------------------
			Select a script_model representing the objective. Then select the trigger
			you want it associated with, and press Control+K. This should draw a target
			line from the script_model to the trigger. Place the trigger where you want
			the playere to take their objective, and move the script model to be in the
			same position so it will appear in the players compass as the correct 
			location. You have just created an objective.	Repeat this process for more 
			objectives, just remember to increment the script_model.script_idnumber 
			with each new objective.

	    Creating Bonus Objectives
	    =========================
      Bonus Objectives are entirely option, and up to the mapper. They are not 
      used at all in spawn logic, but basically represent a point bonus to the 
      team that takes it. Typically they are placed in the final spawn 
      location of the opposing team, since there is no place to push them back.

			Bonus Objective Triggers
			----------------
      Triggers are placed where you want players to take objectives. Typical
      triggers are modeled as switches, or some other player-activated thing.
      But you can really make it whatever you want that fits your map's style.
      Place the trigger in the map position you want it.
      
      * classname = trigger_use or trigger_multiple (depending on your map). 
        Most CNQ maps use trigger_use.
      * script_gameobjectname = cnq or conquest
      * delay = (time in sections between triggers OPTIONAL) - If you want to 
        delay an bonus from being achieved again, put an integer value in for this
        reprenting the number of seconds before the bonus can be earned again.
        Default is 60 seconds if not provided.
      * hintstring = (your descriptive text) This tells players what to do if 
        you choose to use trigger_use classes. Typical text would be something
        like "Press [Use} to take this objective!"
			
	    Bonus Objectives
	    ----------------	  
	    * classname = script_model
			* script_gameobjectname = cnq or conquest
			* targetname = bonusobjective
			* script_team = defenders or attackers - Defines who's bonus objective this
			  is. There can be one per team.
			* script_objective_name = (your descriptive text) - Used in game 
			  messages to tell players the name of their next objective. If not 
			  supplied a default name is used.
	    		
			Targeting the trigger
			---------------------
			Select a script_model representing the objective. Then select the trigger
			you want it associated with, and press Control+K. This should draw a target
			line from the script_model to the trigger. Place the trigger where you want
			the playere to take their objective, and move the script model to be in the
			same position so it will appear in the players compass as the correct 
			location. You have just created an objective.	There can only be one bonus
			objective per team, created in this manner. 
			
	Level script requirements
	-------------------------
		Team Definitions:
			game["allies"] = "american";
			game["axis"] = "german";
			This sets the nationalities of the teams. Allies can be american, british, 
			or russian. Axis can be german.
	
			game["attackers"] = "allies";
			game["defenders"] = "axis";
			This sets which team is attacking and which team is defending. Attackers 
			take objectives, defenders take them back. 
	
		If using minefields or exploders:
			maps\mp\_load::main();
		
	Optional level script settings
	------------------------------
	  Custom callbacks:
	    A variety of callbacks exist so that mappers can have hooks into the game
	    logic for their own animations or other map-specific effects in the map 
	    script file. These are completely optional, and you do not have to 
	    provide them unless you desire such control.

      If you want this capability, in your map file create lines similar to 
      this for each callback you want to use:
      
      level.cnqCallbackSpawnObjectiveComplete = ::Your_Specific_Function_Name;
      level.cnqCallbackBonusObjectiveComplete =  ::Your_Other_Function_Name;

    Available callbacks are:
    
	level.cnqCallbackStartMap() - if defined, called at the start of the map
    level.cnqCallbackEndMap() - if defined, called at the start of the map
    level.cnqCallbackSpawnObjectiveComplete(objective, player) - if defined, called
      when a player completes an objective. The callback will be passed a 
      handle to the objective that was taken, and the player than did it.
    level.cnqCallbackSpawnObjectiveRegen (objective) - if defined, called when
      a spawn objective is available to be taken again.
    level.cnqCallbackBonusObjectiveComplete(objective, player) - if defined, called
      when a player completes a bonus objective. The callback will be passed a 
      handle to the objective that was taken, and the player than did it.
    level.cnqCallbackBonusObjectiveRegen (objective) - if defined, called when
      a bonus objective is available to be taken again.
*/

/*----------------------------------------------------------------
	Port Over to COD2:
	------------------
	Tally & UncleBone
--------------------------------------------------------------------*/

main()
{
	level.callbackStartGameType = ::Callback_StartGameType;
	level.callbackPlayerConnect = ::Callback_PlayerConnect;
	level.callbackPlayerDisconnect = ::Callback_PlayerDisconnect;
	level.callbackPlayerDamage = ::Callback_PlayerDamage;
	level.callbackPlayerKilled = ::Callback_PlayerKilled;
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();

	level.autoassign = ::menuAutoAssign;
	level.allies = ::menuAllies;
	level.axis = ::menuAxis;
	level.spectator = ::menuSpectator;
	level.weapon = ::menuWeapon;
	level.endgameconfirmed = ::endMap;
}

Callback_StartGameType()
{
	level.splitscreen = isSplitScreen();

	// defaults if not defined in level script
/*	if(!isDefined(game["allies"]))
		game["allies"] = "american";
	if(!isDefined(game["axis"]))
		game["axis"] = "german";*/

	// server cvar overrides
	if(getCvar("scr_allies") != "")
		game["allies"] = getCvar("scr_allies");
	if(getCvar("scr_axis") != "")
		game["axis"] = getCvar("scr_axis");
	//#################################################
	
	if (getcvar("scr_cnq_campaign") != "1") // Campaign mode, admin setting
	{
		setcvar("scr_cnq_lastwinner", "");
		setcvar("scr_cnq_campaign", "0"); //off by default
	}    
		
	if (getcvar("scr_cnq_campaign") == "1") 
	{
		if (isdefined(getcvar("scr_cnq_lastwinner")) && (getcvar("scr_cnq_lastwinner") != "")) //ok, campaign mode. Last winner attacks, loser defends
		{      
			if (getcvar("scr_cnq_lastwinner") == "allies") 
			{	
				if(!isdefined(game["attackers"]))
					game["attackers"] = "allies";
				if(!isdefined(game["defenders"]))
					game["defenders"] = "axis";
			} 
			else 
			{
				game["attackers"] = "axis";
				game["defenders"] = "allies";
			}
		} 
		else //they want campaign, but it's the first map
		{ 
			if(!isdefined(game["attackers"]))
				game["attackers"] = "allies";
			if(!isdefined(game["defenders"]))
				game["defenders"] = "axis";
		}
	} 
	else if (getcvar("scr_cnq_campaign") == "0")
	{
		if(!isdefined(game["attackers"]))
			game["attackers"] = "allies";
		if(!isdefined(game["defenders"]))
			game["defenders"] = "axis";
   	}

	level.compassflag_allies = "compass_flag_" + game["allies"];
	level.compassflag_axis = "compass_flag_" + game["axis"];
	level.objpointflag_allies = "objpoint_flag_" + game["allies"];
	level.objpointflag_axis = "objpoint_flag_" + game["axis"];
	level.hudflag_allies = "compass_flag_" + game["allies"];
	level.hudflag_axis = "compass_flag_" + game["axis"];

	precacheStatusIcon("hud_status_dead");
	precacheStatusIcon("hud_status_connecting");
	precacheRumble("damage_heavy");
	precacheShader(level.compassflag_allies);
	precacheShader(level.compassflag_axis);
	precacheShader(level.objpointflag_allies);
	precacheShader(level.objpointflag_axis);
	precacheShader(level.hudflag_allies);
	precacheShader(level.hudflag_axis);
	precacheShader(level.objpointflag_allies);
	precacheShader(level.objpointflag_axis);
	
	//#######
	if(isDefined(game["allies"]))
	{
		switch(game["allies"]) //Setup the hud icons
		{
			case "american":
				game["objecticon_allies"] = "hud_flag_american";
				break;
			case "british":
				game["objecticon_allies"] = "hud_flag_british";
				break;
			case "russian":
				game["objecticon_allies"] = "hud_flag_russian";
				break;
		}
	}
	
	if(isDefined(game["axis"]))
	{
		switch(game["axis"])
		{
			case "german":
				game["objecticon_axis"] = "hud_flag_german";
				break;
		}
	}
	
	precacheShader(game["objecticon_allies"]);
	precacheShader(game["objecticon_axis"]);

	precacheShader("objpoint_star");
	precacheShader("death_suicide");
	//#######
	
	precacheString(&"MP_TIME_TILL_SPAWN");
	precacheString(&"PLATFORM_PRESS_TO_SPAWN");
	
	//###############
	precacheString(&"MP_KILL_AXIS_PLAYERS");
	precacheString(&"MP_KILL_ALLIED_PLAYERS");
	precacheString(&"MP_ALLIES_KILL_AXIS_PLAYERS");
	
	if(!isdefined(game["cnq_attackers_obj_text"])) 
	{
		if ( game["attackers"] == "allies" )
			game["cnq_attackers_obj_text"] = (&"MP_KILL_AXIS_PLAYERS");
		else 
			game["cnq_attackers_obj_text"] = (&"MP_KILL_ALLIED_PLAYERS");
	}
	
	if(!isdefined(game["cnq_defenders_obj_text"])) 
	{
		if ( game["defenders"] == "allies" )
			game["cnq_defenders_obj_text"] = (&"MP_KILL_AXIS_PLAYERS");
		else 
			game["cnq_defenders_obj_text"] = (&"MP_KILL_ALLIED_PLAYERS");
	}
	
	if(!isdefined(game["cnq_neutral_obj_text"]))
		game["cnq_neutral_obj_text"] = (&"MP_ALLIES_KILL_AXIS_PLAYERS");
	//###############

	thread maps\mp\gametypes\_menus::init();
	thread maps\mp\gametypes\_serversettings::init();
	thread maps\mp\gametypes\_clientids::init();
	thread maps\mp\gametypes\_teams::init();
	thread maps\mp\gametypes\_weapons::init();
	thread maps\mp\gametypes\_scoreboard::init();
	thread maps\mp\gametypes\_killcam::init();
	thread maps\mp\gametypes\_shellshock::init();
	thread maps\mp\gametypes\_hud_teamscore::init();
	thread maps\mp\gametypes\_deathicons::init();
	thread maps\mp\gametypes\_damagefeedback::init();
	thread maps\mp\gametypes\_healthoverlay::init();
	thread maps\mp\gametypes\_friendicons::init();
	thread maps\mp\gametypes\_spectating::init();
	thread maps\mp\gametypes\_grenadeindicators::init();

	level.xenon = (getcvar("xenonGame") == "true");
	if(level.xenon) // Xenon only
		thread maps\mp\gametypes\_richpresence::init();
	else // PC only
		thread maps\mp\gametypes\_quickmessages::init();

	setClientNameMode("auto_change");

	spawnpointname = "mp_tdm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	allowed[0] = "cnq";
	allowed[1] = "conquest";
	maps\mp\gametypes\_gameobjects::main(allowed);

	if(getCvar("scr_cnq_timelimit") == "")		// Time limit per map
		setCvar("scr_cnq_timelimit", "30");
	else if(getCvarFloat("scr_cnq_timelimit") > 1440)
		setCvar("scr_cnq_timelimit", "1440");
	level.timelimit = getCvarFloat("scr_cnq_timelimit");
// La Truffe ->
/*
	setCvar("ui_cnq_timelimit", level.timelimit);
	makeCvarServerInfo("ui_cnq_timelimit", "30");
*/
	setCvar("ui_timelimit", level.timelimit);
	makeCvarServerInfo("ui_timelimit", "30");
// La Truffe <-

	if(getCvar("scr_cnq_scorelimit") == "")		// Score limit per map
		setCvar("scr_cnq_scorelimit", "100");
	level.scorelimit = getCvarInt("scr_cnq_scorelimit");
// La Truffe ->
/*
	setCvar("ui_cnq_scorelimit", level.scorelimit);
	makeCvarServerInfo("ui_cnq_scorelimit", "100");
*/
	setCvar("ui_scorelimit", level.scorelimit);
	makeCvarServerInfo("ui_scorelimit", "100");
// La Truffe <-

	// Force respawning
	if(getCvar("scr_forcerespawn") == "")
		setCvar("scr_forcerespawn", "0");
		
		//############################		
	if(getcvar("scr_cnq_debug") == "")		// Debug messages
		setcvar("scr_cnq_debug", "0");
		
	if(getcvar("scr_cnq_player_objective_points") == "")		// Points to award player for achieving objective
		setcvar("scr_cnq_player_objective_points", "0");
	level.player_obj_points = getcvarint("scr_cnq_player_objective_points");

	if(getcvar("scr_cnq_team_objective_points") == "")		// Points to award team for achieving objective
		setcvar("scr_cnq_team_objective_points", "10");
	level.team_obj_points = getcvarint("scr_cnq_team_objective_points");

	if(getcvar("scr_cnq_player_bonus_points") == "")		// Points to award player for achieving bonus objective
		setcvar("scr_cnq_player_bonus_points", "0");
	level.player_bonus_points = getcvarint("scr_cnq_player_bonus_points");

	if(getcvar("scr_cnq_team_bonus_points") == "")		// Points to award team for achieving bonus objective
		setcvar("scr_cnq_team_bonus_points", "25");
	level.team_bonus_points = getcvarint("scr_cnq_team_bonus_points");

	if(getCvar("scr_cnq_respawn_wave_time") == "")	
		setCvar("scr_cnq_respawn_wave_time", "10");
	//else if(getCvar("scr_cnq_respawn_wave_time") == "00")
	//	setCvar("scr_cnq_respawn_wave_time", "2")
	level.respawndelay = getCvarint("scr_cnq_respawn_wave_time");
	
	if(getCvar("scr_show_obj_hud") == "")	
		setCvar("scr_show_obj_hud", "1");
	level.showobj_hud = getCvarInt("scr_show_obj_hud", 1);
		

	  //############################

	if(!isDefined(game["state"]))
		game["state"] = "playing";

	level.mapended = false;

	level.team["allies"] = 0;
	level.team["axis"] = 0;
	
	//########
	level.objectivearray = [];
	level.objCount = [];
	level.objCount["attackers"] = 0;
	level.objCount["defenders"] = 0;
	//#######

	thread startGame();
	thread updateGametypeCvars();
//	thread startHud(); to do: fix this damn thing!!
	thread startObjectives();	
	thread maps\mp\gametypes\_teams::addTestClients();
}

dummy()
{
	waittillframeend;

	if(isdefined(self))
		level notify("connecting", self);
}

Callback_PlayerConnect()
{
	thread dummy();

	self.statusicon = "hud_status_connecting";
	self waittill("begin");
	self.statusicon = "";

	level notify("connected", self);

	if(!level.splitscreen)
		iprintln(&"MP_CONNECTED", self);

	lpselfnum = self getEntityNumber();
	lpGuid = self getGuid();
	logPrint("J;" + lpGuid + ";" + lpselfnum + ";" + self.name + "\n");

	if(game["state"] == "intermission")
	{
		spawnIntermission();
		return;
	}

	level endon("intermission");

	if(level.splitscreen)
		scriptMainMenu = game["menu_ingame_spectator"];
	else
		scriptMainMenu = game["menu_ingame"];

	if(isDefined(self.pers["team"]) && self.pers["team"] != "spectator")
	{
		self setClientCvar("ui_allow_weaponchange", "1");

		if(self.pers["team"] == "allies")
			self.sessionteam = "allies";
		else
			self.sessionteam = "axis";

		if(isDefined(self.pers["weapon"]))
			spawnPlayer();
		else
		{
			spawnSpectator();

			if(self.pers["team"] == "allies")
			{
				self openMenu(game["menu_weapon_allies"]);
				scriptMainMenu = game["menu_weapon_allies"];
			}
			else
			{
				self openMenu(game["menu_weapon_axis"]);
				scriptMainMenu = game["menu_weapon_axis"];
			}
		}
	}
	else
	{
		self setClientCvar("ui_allow_weaponchange", "0");

		if(!level.xenon)
		{
			if(!isdefined(self.pers["skipserverinfo"]))
				self openMenu(game["menu_serverinfo"]);
		}
		else
			self openMenu(game["menu_team"]);

		self.pers["team"] = "spectator";
		self.sessionteam = "spectator";

		spawnSpectator();
	}

	self setClientCvar("g_scriptMainMenu", scriptMainMenu);
}

Callback_PlayerDisconnect()
{
	if(!level.splitscreen)
		iprintln(&"MP_DISCONNECTED", self);

	if(isdefined(self.pers["team"]))
	{
		if(self.pers["team"] == "allies")
			setplayerteamrank(self, 0, 0);
		else if(self.pers["team"] == "axis")
			setplayerteamrank(self, 1, 0);
		else if(self.pers["team"] == "spectator")
			setplayerteamrank(self, 2, 0);
	}

	lpselfnum = self getEntityNumber();
	lpGuid = self getGuid();
	logPrint("Q;" + lpGuid + ";" + lpselfnum + ";" + self.name + "\n");
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(self.sessionteam == "spectator")
		return;

	// Don't do knockback if the damage direction was not specified
	if(!isDefined(vDir))
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	friendly = undefined;

	// check for completely getting out of the damage
	if(!(iDFlags & level.iDFLAGS_NO_PROTECTION))
	{
		if(isPlayer(eAttacker) && (self != eAttacker) && (self.pers["team"] == eAttacker.pers["team"]))
		{
			if(level.friendlyfire == "0")
			{
				return;
			}
			else if(level.friendlyfire == "1")
			{
				// Make sure at least one point of damage is done
				if(iDamage < 1)
					iDamage = 1;

				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

				// Shellshock/Rumble
				self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				self playrumble("damage_heavy");
			}
			else if(level.friendlyfire == "2")
			{
				eAttacker.friendlydamage = true;

				iDamage = int(iDamage * .5);

				// Make sure at least one point of damage is done
				if(iDamage < 1)
					iDamage = 1;

				eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				eAttacker.friendlydamage = undefined;

				friendly = true;
			}
			else if(level.friendlyfire == "3")
			{
				eAttacker.friendlydamage = true;

				iDamage = int(iDamage * .5);

				// Make sure at least one point of damage is done
				if(iDamage < 1)
					iDamage = 1;

				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				eAttacker.friendlydamage = undefined;

				friendly = true;

				// Shellshock/Rumble
				self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				self playrumble("damage_heavy");
			}
		}
		else
		{
			// Make sure at least one point of damage is done
			if(iDamage < 1)
				iDamage = 1;

			self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

			// Shellshock/Rumble
			self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
			self playrumble("damage_heavy");
		}

		if(isdefined(eAttacker) && eAttacker != self)
			eAttacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback();
	}

	// Do debug print if it's enabled
	if(getCvarInt("g_debugDamage"))
	{
		println("client:" + self getEntityNumber() + " health:" + self.health +
			" damage:" + iDamage + " hitLoc:" + sHitLoc);
	}

	if(self.sessionstate != "dead")
	{
		lpselfnum = self getEntityNumber();
		lpselfname = self.name;
		lpselfteam = self.pers["team"];
		lpselfGuid = self getGuid();
		lpattackerteam = "";

		if(isPlayer(eAttacker))
		{
			lpattacknum = eAttacker getEntityNumber();
			lpattackGuid = eAttacker getGuid();
			lpattackname = eAttacker.name;
			lpattackerteam = eAttacker.pers["team"];
		}
		else
		{
			lpattacknum = -1;
			lpattackGuid = "";
			lpattackname = "";
			lpattackerteam = "world";
		}

		if(isDefined(friendly))
		{
			lpattacknum = lpselfnum;
			lpattackname = lpselfname;
			lpattackGuid = lpselfGuid;
		}

		logPrint("D;" + lpselfGuid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackGuid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
	}
}

Callback_PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self endon("spawned");
	self notify("killed_player");

	if(self.sessionteam == "spectator")
		return;

	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE")
		sMeansOfDeath = "MOD_HEAD_SHOT";

	// send out an obituary message to all clients about the kill
	obituary(self, attacker, sWeapon, sMeansOfDeath);

	self maps\mp\gametypes\_weapons::dropWeapon();
	self maps\mp\gametypes\_weapons::dropOffhand();

	self.sessionstate = "dead";
	self.statusicon = "hud_status_dead";
	self.dead_origin = self.origin;
	self.dead_angles = self.angles;

	if(!isdefined(self.switching_teams))
		self.deaths++;

	lpselfnum = self getEntityNumber();
	lpselfname = self.name;
	lpselfguid = self getGuid();
	lpselfteam = self.pers["team"];
	lpattackerteam = "";

	attackerNum = -1;
	if(isPlayer(attacker))
	{
		if(attacker == self) // killed himself
		{
			doKillcam = false;

			// switching teams
			if(isdefined(self.switching_teams))
			{
				if((self.leaving_team == "allies" && self.joining_team == "axis") || (self.leaving_team == "axis" && self.joining_team == "allies"))
				{
					players = maps\mp\gametypes\_teams::CountPlayers();
					players[self.leaving_team]--;
					players[self.joining_team]++;

					if((players[self.joining_team] - players[self.leaving_team]) > 1)
						attacker.score--;
				}
			}

			if(isdefined(attacker.friendlydamage))
				attacker iprintln(&"MP_FRIENDLY_FIRE_WILL_NOT");
		}
		else
		{
			attackerNum = attacker getEntityNumber();
			doKillcam = true;

			if(self.pers["team"] == attacker.pers["team"]) // killed by a friendly
				attacker.score--;
			else
	//#####################################
			{
				attacker.score++;
				teamscore = getTeamScore(attacker.pers["team"]);
				teamscore++;
				setTeamScore(attacker.pers["team"], teamscore);
				checkScoreLimit();
			}
	//#####################################
		}

		lpattacknum = attacker getEntityNumber();
		lpattackguid = attacker getGuid();
		lpattackname = attacker.name;
		lpattackerteam = attacker.pers["team"];
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		doKillcam = false;

		self.score--;

		lpattacknum = -1;
		lpattackname = "";
		lpattackguid = "";
		lpattackerteam = "world";
	}


	level notify("update_allhud_score");

	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

	// Stop thread if map ended on this death
	if(level.mapended)
		return;

	self.switching_teams = undefined;
	self.joining_team = undefined;
	self.leaving_team = undefined;

	body = self cloneplayer(deathAnimDuration);
	thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"], 5);

	delay = 2;	// Delay the player becoming a spectator till after he's done dying
	self thread respawn_timer(delay);

	wait delay;	// ?? Also required for Callback_PlayerKilled to complete before respawn/killcam can execute

	if(doKillcam && level.killcam)
		self maps\mp\gametypes\_killcam::killcam(attackerNum, delay, psOffsetTime);

	self thread respawn();
}

spawnPlayer()
{
	self endon("disconnect");
	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionteam = self.pers["team"];
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;
	self.statusicon = "";
	self.maxhealth = 100;
	self.health = self.maxhealth;
	self.dead_origin = undefined;
	self.dead_angles = undefined;

	spawnpointname = "mp_tdm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");

//###################################################
printObjectiveStates();

	if (isdefined(level.objectivearray)) 
	{
//		if (level.firstSwitchThrown)
//			locationToUse = 0;
//		else

		locationToUse = getcvar("scr_cnq_initialobjective");
		
		for (n = 0; n < level.objectivearray.size; n++) 
		{
			spawnObjective = level.objectivearray[n];
			if (isOff(spawnObjective))
				continue;
			locationToUse = spawnObjective.script_idnumber;
		}
		
		printDebug( "Basing spawns on objective #" + locationToUse);
		teamRole = "";
		
		if (self.pers["team"] == game["attackers"])
			teamRole = "attackers";
		else
			teamRole = "defenders";
		
		spawngroup = teamRole + locationToUse;
		printDebug( "Attempting to use spawngroup " + spawngroup );
		spawnpoints = getentarray(spawngroup, "targetname");
		if (isdefined(spawnpoints)) 
		{
			if (spawnpoints.size == 0) 
			{
				spawnpoints = getentarray(spawnpointname, "classname");
				printDebug( "0 spawns found, switching to regular TDM spawns" );
			}	
		} 
		else 
		{
			spawnpoints = getentarray(spawnpointname, "classname");
			printDebug( "No spawns found, switching to regular TDM spawns" );
		}
	}
	printDebug( "Found " + spawnpoints.size + " spawn points.");
	
	if (getcvar("scr_cnq_spawnmethod") == "random")
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);
	else
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);

	if(isDefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
//###################################################

	if(!isDefined(self.pers["savedmodel"]))
		maps\mp\gametypes\_teams::model();
	else
		maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	maps\mp\gametypes\_weapons::givePistol();
	maps\mp\gametypes\_weapons::giveGrenades();
	maps\mp\gametypes\_weapons::giveBinoculars();

	self giveWeapon(self.pers["weapon"]);
	self giveMaxAmmo(self.pers["weapon"]);
	self setSpawnWeapon(self.pers["weapon"]);

	//###
	self setObjectiveTextAll();
	//###
	
	self thread updateTimer();

	waittillframeend;
	self notify("spawned_player");
}

spawnSpectator(origin, angles)
{
	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;

	if(self.pers["team"] == "spectator")
		self.statusicon = "";

	maps\mp\gametypes\_spectating::setSpectatePermissions();

	if(isDefined(origin) && isDefined(angles))
		self spawn(origin, angles);
	else
	{
		spawnpointname = "mp_global_intermission";
		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

		if(isDefined(spawnpoint))
			self spawn(spawnpoint.origin, spawnpoint.angles);
		else
			maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	self setClientCvar("cg_objectiveText", "");
}

spawnIntermission()
{
	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionstate = "intermission";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;

	spawnpointname = "mp_global_intermission";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

	if(isDefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");

	self thread updateTimer();
}

respawn()
{
	self endon("disconnect");
	self endon("end_respawn");

	if(!isDefined(self.pers["weapon"]))
		return;

	self.sessionteam = self.pers["team"];
	self.sessionstate = "spectator";

	if(isdefined(self.dead_origin) && isdefined(self.dead_angles))
	{
		origin = self.dead_origin + (0, 0, 16);
		angles = self.dead_angles;
	}
	else
	{
		origin = self.origin + (0, 0, 16);
		angles = self.angles;
	}

	self spawn(origin, angles);

	while(isdefined(self.WaitingToSpawn))
		wait .05;

	if(getCvarInt("scr_forcerespawn") <= 0)
	{
		self thread waitRespawnButton();
		self waittill("respawn");
	}

	self thread spawnPlayer();
}

waitRespawnButton()
{
	self endon("disconnect");
	self endon("end_respawn");
	self endon("respawn");

	wait 0; // Required or the "respawn" notify could happen before it's waittill has begun

	if(!isdefined(self.respawntext))
	{
		self.respawntext = newClientHudElem(self);
		self.respawntext.horzAlign = "center_safearea";
		self.respawntext.vertAlign = "center_safearea";
		self.respawntext.alignX = "center";
		self.respawntext.alignY = "middle";
		self.respawntext.x = 0;
		self.respawntext.y = -50;
		self.respawntext.archived = false;
		self.respawntext.font = "default";
		self.respawntext.fontscale = 2;
		self.respawntext setText(&"PLATFORM_PRESS_TO_SPAWN");
	}

	thread removeRespawnText();
	thread waitRemoveRespawnText("end_respawn");
	thread waitRemoveRespawnText("respawn");

	while(self useButtonPressed() != true)
		wait .05;

	self notify("remove_respawntext");

	self notify("respawn");
}

removeRespawnText()
{
	self waittill("remove_respawntext");

	if(isDefined(self.respawntext))
		self.respawntext destroy();
}

waitRemoveRespawnText(message)
{
	self endon("remove_respawntext");

	self waittill(message);
	self notify("remove_respawntext");
}

startGame()
{
	level.starttime = getTime();

	if(level.timelimit > 0)
	{
		level.clock = newHudElem();
		level.clock.horzAlign = "left";
		level.clock.vertAlign = "top";
		level.clock.x = 8;
		level.clock.y = 2;
		level.clock.font = "default";
		level.clock.fontscale = 2;
		level.clock setTimer(level.timelimit * 60);
	}

	for(;;)
	{
		checkTimeLimit();
		wait 1;
	}
}

endMap()
{
//////// Added for AWE /////////
	awe\_global::EndMap();
////////////////////////////////

	game["state"] = "intermission";
	level notify("intermission");

	alliedscore = getTeamScore("allies");
	axisscore = getTeamScore("axis");

	if(alliedscore == axisscore)
	{
		winningteam = "tie";
		losingteam = "tie";
		text = "MP_THE_GAME_IS_A_TIE";
	}
	else if(alliedscore > axisscore)
	{
		winningteam = "allies";
		losingteam = "axis";
		text = &"MP_ALLIES_WIN";
	}
	else
	{
		winningteam = "axis";
		losingteam = "allies";
		text = &"MP_AXIS_WIN";
	}

	winners = "";
	losers = "";

	//####################################
	if (getcvar("scr_cnq_campaign") == "1") 
	{
		if (winningteam != "tie") 
			setcvar("scr_cnq_lastwinner", winningteam);
		else
			setcvar("scr_cnq_lastwinner", game["attackers"]);
	}
	//###################################
	if(winningteam == "allies")
		level thread playSoundOnPlayers("MP_announcer_allies_win");
	else if(winningteam == "axis")
		level thread playSoundOnPlayers("MP_announcer_axis_win");
	else
		level thread playSoundOnPlayers("MP_announcer_round_draw");

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if((winningteam == "allies") || (winningteam == "axis"))
		{
			lpGuid = player getGuid();
			if((isDefined(player.pers["team"])) && (player.pers["team"] == winningteam))
				winners = (winners + ";" + lpGuid + ";" + player.name);
			else if((isDefined(player.pers["team"])) && (player.pers["team"] == losingteam))
				losers = (losers + ";" + lpGuid + ";" + player.name);
		}

		player closeMenu();
		player closeInGameMenu();
		player setClientCvar("cg_objectiveText", text);

		player spawnIntermission();
	}

	if((winningteam == "allies") || (winningteam == "axis"))
	{
		logPrint("W;" + winningteam + winners + "\n");
		logPrint("L;" + losingteam + losers + "\n");
	}

	// set everyone's rank on xenon
	if(level.xenon)
	{
		players = getentarray("player", "classname");
		highscore = undefined;

		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(!isdefined(player.score))
				continue;

			if(!isdefined(highscore) || player.score > highscore)
				highscore = player.score;
		}

		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(!isdefined(player.score))
				continue;

			if(highscore <= 0)
				rank = 0;
			else
			{
				rank = int(player.score * 10 / highscore);
				if(rank < 0)
					rank = 0;
			}

			if(player.pers["team"] == "allies")
				setplayerteamrank(player, 0, rank);
			else if(player.pers["team"] == "axis")
				setplayerteamrank(player, 1, rank);
			else if(player.pers["team"] == "spectator")
				setplayerteamrank(player, 2, rank);
		}
		sendranks();
	}

	wait 10;
	exitLevel(false);
}

checkTimeLimit()
{
	if(level.timelimit <= 0)
		return;

	timepassed = (getTime() - level.starttime) / 1000;
	timepassed = timepassed / 60.0;

	if(timepassed < level.timelimit)
		return;

	if(level.mapended)
		return;
	level.mapended = true;

	if(!level.splitscreen)
		iprintln(&"MP_TIME_LIMIT_REACHED");

	level thread endMap();
}

checkScoreLimit()
{
	if(level.scorelimit <= 0)
		return;

	if(getTeamScore("allies") < level.scorelimit && getTeamScore("axis") < level.scorelimit)
		return;

	if(level.mapended)
		return;
	level.mapended = true;

	if(!level.splitscreen)
		iprintln(&"MP_SCORE_LIMIT_REACHED");

	level thread endMap();
}

updateGametypeCvars()
{
	for(;;)
	{
		timelimit = getCvarFloat("scr_cnq_timelimit");  //###########
		if(level.timelimit != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_cnq_timelimit", "1440");  //###########
			}

			level.timelimit = timelimit;
// La Truffe ->
//			setCvar("ui_cnq_timelimit", level.timelimit);  //###########
			setCvar("ui_timelimit", level.timelimit);  //###########
// La Truffe <-
			level.starttime = getTime();

			if(level.timelimit > 0)
			{
				if(!isDefined(level.clock))
				{
					level.clock = newHudElem();
					level.clock.horzAlign = "left";
					level.clock.vertAlign = "top";
					level.clock.x = 8;
					level.clock.y = 2;
					level.clock.font = "default";
					level.clock.fontscale = 2;
				}
				level.clock setTimer(level.timelimit * 60);
			}
			else
			{
				if(isDefined(level.clock))
					level.clock destroy();
			}

			checkTimeLimit();
		}

		scorelimit = getCvarInt("scr_cnq_scorelimit");  //###########
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
// La Truffe ->
//			setCvar("ui_cnq_scorelimit", level.scorelimit);  //###########
			setCvar("ui_scorelimit", level.scorelimit);  //###########
// La Truffe <-
			level notify("update_allhud_score");
		}
		checkScoreLimit();

		wait 1;
	}
}

printJoinedTeam(team)
{
	if(!level.splitscreen)
	{
	    if(team == "allies")
		    iprintln(&"MP_JOINED_ALLIES", self);
	    else if(team == "axis")
		    iprintln(&"MP_JOINED_AXIS", self);
	}
}

//initflag was here

playSoundOnPlayers(sound, team)
{
	players = getentarray("player", "classname");

	if(level.splitscreen)
	{
		if(isdefined(players[0]))
			players[0] playLocalSound(sound);
	}
	else
	{
		if(isdefined(team))
		{
			for(i = 0; i < players.size; i++)
			{
				if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
					players[i] playLocalSound(sound);
			}
		}
		else
		{
			for(i = 0; i < players.size; i++)
				players[i] playLocalSound(sound);
		}
	}
}

printOnTeam(text, team)
{
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
			players[i] iprintln(text);
	}
}

menuAutoAssign()
{
	numonteam["allies"] = 0;
	numonteam["axis"] = 0;

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(!isDefined(player.pers["team"]) || player.pers["team"] == "spectator" || player == self)
			continue;

		numonteam[player.pers["team"]]++;
	}

	// if teams are equal return the team with the lowest score
	if(numonteam["allies"] == numonteam["axis"])
	{
		if(getTeamScore("allies") == getTeamScore("axis"))
		{
			teams[0] = "allies";
			teams[1] = "axis";
			assignment = teams[randomInt(2)];
		}
		else if(getTeamScore("allies") < getTeamScore("axis"))
			assignment = "allies";
		else
			assignment = "axis";
	}
	else if(numonteam["allies"] < numonteam["axis"])
		assignment = "allies";
	else
		assignment = "axis";

	if(assignment == self.pers["team"] && (self.sessionstate == "playing" || self.sessionstate == "dead"))
	{
	    if(!isdefined(self.pers["weapon"]))
	    {
		    if(self.pers["team"] == "allies")
			    self openMenu(game["menu_weapon_allies"]);
		    else
			    self openMenu(game["menu_weapon_axis"]);
	    }

		return;
	}

	if(assignment != self.pers["team"] && (self.sessionstate == "playing" || self.sessionstate == "dead"))
	{
		self.switching_teams = true;
		self.joining_team = assignment;
		self.leaving_team = self.pers["team"];
		self suicide();
	}

	self.pers["team"] = assignment;
	self.pers["weapon"] = undefined;
	self.pers["savedmodel"] = undefined;

	self setClientCvar("ui_allow_weaponchange", "1");

	if(self.pers["team"] == "allies")
	{
		self openMenu(game["menu_weapon_allies"]);
		self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
	}
	else
	{
		self openMenu(game["menu_weapon_axis"]);
		self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);
	}

	self notify("joined_team");
	self notify("end_respawn");
}

menuAllies()
{
	if(self.pers["team"] != "allies")
	{
		if(self.sessionstate == "playing")
		{
			self.switching_teams = true;
			self.joining_team = "allies";
			self.leaving_team = self.pers["team"];
			self suicide();
		}

		self.pers["team"] = "allies";
		self.pers["weapon"] = undefined;
		self.pers["savedmodel"] = undefined;

		self setClientCvar("ui_allow_weaponchange", "1");
		self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);

		self notify("joined_team");
		self notify("end_respawn");
	}

	if(!isdefined(self.pers["weapon"]))
		self openMenu(game["menu_weapon_allies"]);
}

menuAxis()
{
	if(self.pers["team"] != "axis")
	{
		if(self.sessionstate == "playing")
		{
			self.switching_teams = true;
			self.joining_team = "axis";
			self.leaving_team = self.pers["team"];
			self suicide();
		}

		self.pers["team"] = "axis";
		self.pers["weapon"] = undefined;
		self.pers["savedmodel"] = undefined;

		self setClientCvar("ui_allow_weaponchange", "1");
		self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);

		self notify("joined_team");
		self notify("end_respawn");
	}

	if(!isdefined(self.pers["weapon"]))
		self openMenu(game["menu_weapon_axis"]);
}

menuSpectator()
{
	if(self.pers["team"] != "spectator")
	{
		if(isAlive(self))
		{
			self.switching_teams = true;
			self.joining_team = "spectator";
			self.leaving_team = self.pers["team"];
			self suicide();
		}

		self.pers["team"] = "spectator";
		self.pers["weapon"] = undefined;
		self.pers["savedmodel"] = undefined;

		self.sessionteam = "spectator";
		self setClientCvar("ui_allow_weaponchange", "0");

		self thread updateTimer();

		spawnSpectator();

		if(level.splitscreen)
			self setClientCvar("g_scriptMainMenu", game["menu_ingame_spectator"]);
		else
			self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

		self notify("joined_spectators");
		self notify("end_respawn");
	}
}

menuWeapon(response)
{
	if(!isDefined(self.pers["team"]) || (self.pers["team"] != "allies" && self.pers["team"] != "axis"))
		return;

	weapon = self maps\mp\gametypes\_weapons::restrictWeaponByServerCvars(response);

	if(weapon == "restricted")
	{
		if(self.pers["team"] == "allies")
			self openMenu(game["menu_weapon_allies"]);
		else if(self.pers["team"] == "axis")
			self openMenu(game["menu_weapon_axis"]);

		return;
	}

	if(level.splitscreen)
		self setClientCvar("g_scriptMainMenu", game["menu_ingame_onteam"]);
	else
		self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

	if(isDefined(self.pers["weapon"]) && self.pers["weapon"] == weapon)
		return;

	if(!isDefined(self.pers["weapon"]))
	{
		self.pers["weapon"] = weapon;

		if(isdefined(self.WaitingToSpawn))
		{
			self thread respawn();
			self thread updateTimer();
		}
		else
			spawnPlayer();

		self thread printJoinedTeam(self.pers["team"]);
	}
	else
	{
		self.pers["weapon"] = weapon;

		weaponname = maps\mp\gametypes\_weapons::getWeaponName(self.pers["weapon"]);

		if(maps\mp\gametypes\_weapons::useAn(self.pers["weapon"]))
			self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_AN", weaponname);
		else
			self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_A", weaponname);
	}

	self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
}

//###############################################
//###############################################

startObjectives() 
{
	startSpawnObjectives();
	startBonusObjectives();
	setObjectives();
	adjustObjectivesCount();
  
}

startSpawnObjectives()
{

	if(getcvar("scr_cnq_initialobjective") == "") // Initial switch on, admin setting
	{ 
		if (isdefined(game["cnq_initialobjective"])) // Initial switch, optional mapper setting
		{ 
			setcvar("scr_cnq_initialobjective", game["cnq_initialobjective"]);
		}
		else
		{
			setcvar("scr_cnq_initialobjective", "1");
		}
	}
		
	level.conquest_objectives = getentarray("spawnobjective","targetname");
	printDebug ("Found " + level.conquest_objectives.size + " spawn objectives in this map.");
		
	for(i = 0; i < level.conquest_objectives.size; i++)
	{
		//first, find the triggers each objective targets and set them
		objective = level.conquest_objectives[i];
		flipOff(objective); //turn all off to start
		
		if (isdefined(objective.target) )
		{
			targets = getentarray (objective.target,"targetname");
			for (t = 0; t < targets.size; t++)
			{
				if (targets[t].classname == "trigger_use" || targets[t].classname == "trigger_multiple")
				{
					objective.trigger = targets[t];
					//targets[t] delete();
				}
			}
		}

		objective notify ("round_ended");
		objective thread objective_think();
		
		level.objectivearray[objective.script_idnumber - 1] = objective;
	
	}
	
	found = 0;
	for (i = 0; i < level.objectivearray.size; i++) 
	{
		if (level.objectivearray[i].script_idnumber <= getcvarint("scr_cnq_initialobjective")) 
		{
			flipObjective(level.objectivearray[i]);
			found = 1;
		} 
		else 
		{
			break;
		}
	}
}

startBonusObjectives() 
{

	level endon("round_ended");

	level.bonus_objectives = getentarray("bonusobjective","targetname");
	printDebug ("Found " + level.bonus_objectives.size + " bonus objectives in this map.");
	
	for(i = 0; i < level.bonus_objectives.size; i++) 	
	{
		//first, find the triggers each objective targets and set them
		objective = level.bonus_objectives[i];
		if (isdefined (objective.target)) 
		{
			targets = getentarray (objective.target,"targetname");

			for (t = 0; t < targets.size; t++) 
			{
				if (targets[t].classname == "trigger_use" || targets[t].classname == "trigger_multiple") 
				{
					objective.trigger = targets[t];
					objective thread bonus_objective_think();
					break;
				}
			}    
		}
	}
    
}

objective_think() 
{

	for(;;)
	{
		delaytime = 0.9;
	
		self.trigger waittill("trigger", other);
	
		if (isPlayer(other)) 
		{	
			allSpawnObjectives = level.objectivearray;
	
			if (!isdefined(allSpawnObjectives))
				continue;
	
			for (n = 0; n < allSpawnObjectives.size; n++) 
			{	
				if (self.script_idnumber == allSpawnObjectives[n].script_idnumber) 
				{
	
					if (other.pers["team"] == game["attackers"]) 
					{
	
						// if it's already on, fugeddabowdit
						if (isOn(self)) 
						{
							other iprintln( "Your team has already taken this objective! Look at your compass or the scoreboard for your current objective.");
								continue;
						}
	
						//attackers can always turn on the 1st objective
						//otherwise, they can turn a objecetive on only if the previous one is also on.
						previousObjective = allSpawnObjectives[n-1];
						if ((n == 0) || (isdefined(previousObjective) && isOn(previousObjective))) 
						{
							thread performObjectiveCompleteTasks(self, other, "spawn");
							if (isdefined(self.trigger.delay) && (self.trigger.delay > 0.5))
								delaytime = self.trigger.delay / 1000; //don't know why, but delay comes through as map # * 1000;
						} 
						else 
						{
							other iprintln( "This is not your current objective! Look at your compass or the scoreboard for your current objective.");
						}
	
					} 
					else //defenders
					{ 
	
						// if it's already off, fugeddabowdit
						if (isOff(self)) 
						{
							other iprintln( "Your team has already taken this objective! Look at your compass or the scoreboard for your current objective.");
								continue;
						}
	
						//defenders can always turn on the last objective and the next to be turned off
						previousObjective = allSpawnObjectives[n+1];
						if ((n == allSpawnObjectives.size - 1) || (isdefined(previousObjective) && isOff(previousObjective))) 
						{
							thread performObjectiveCompleteTasks(self, other, "spawn");
							if (isdefined(self.trigger.delay))
								delaytime = self.trigger.delay / 1000; //don't know why, but delay comes through as map # * 1000;
						} 
						else 
						{
							other iprintln( "This is not your current objective! Look at your compass or the scoreboard for your current objective.");
						}
					} // if other.per["team"]
				} //if self.script_idnumber
			} //for loop
		} //if isPlayer
		wait delaytime;
		if (isdefined(level.cnqCallbackSpawnObjectiveRegen))
			thread [[level.cnqCallbackSpawnObjectiveRegen]](self);
	} //outside for loop
	
}

bonus_objective_think()
{

	level endon("round_ended");
	
	if (!isdefined(self.radius))
		self.radius = 256;
	
	self thread countdownUntilAvailable(60); //initial wait, so teams don't earn bonus in 1st minute before everyone is spawned in.
	
	for(;;)
	{	
		self.trigger waittill("trigger", other);

		printDebug ("Bonus triggered by " + other.name + " playing for the " + other.pers["team"]);
	
		if (isPlayer(other)) 
		{
	
			if (!isdefined(level.objectivearray))
				continue;
	
			teamRole = "attackers";
			if (other.pers["team"] == game["defenders"])
				teamRole = "defenders";
	
			if (isdefined(self.script_team) && (self.script_team == teamRole)) //if it's their bonus objective
			{ 
				if (level.objCount[teamRole] == level.objectivearray.size) //and they control all the regular objectives
				{ 
					if (self.isAvailable == 1) //and it's not in a wait state
					{ 
						self.isAvailable = 0;
						thread performObjectiveCompleteTasks(self, other, "bonus");
						self thread countdownUntilAvailable();
					} 
					else 
					{
						other iprintln("This bonus objective cannot be taken yet. Look at your compass or the scoreboard for your current objective.");
					}
				} 
				else 
				{
					other iprintln("This is not your current objective! Look at your compass or the scoreboard for your current objective.");
				}	
			} 
			else 
			{
				other iprintln("This is not your team's bonus objective! Look at your compass or the scoreboard for your current objective.");
			}
		} //if isPlayer
		wait 0.5;
	} //outside for loop
}

countdownUntilAvailable(delayTime) 
{ 
	self.isAvailable = 0;
	if (!isdefined(delayTime)) 
	{
		if (isdefined(self.trigger.delay) && (self.trigger.delay > 0.5)) 
		{
			delayTime  = self.trigger.delay / 1000; //don't know why, but delay comes through as map # * 1000
		} 
		else 
		{
			delayTime = 60; 
		}
	}
	 
	printDebug ("Delay time on trigger is " + delaytime + " seconds.");
	wait delayTime;
	self.isAvailable = 1;
	thread updatePlayerInfo();
	if (isdefined(level.cnqCallbackBonusObjectiveRegen))
		thread [[level.cnqCallbackBonusObjectiveRegen]](self);
}

flipObjective(spawnObjective) 
{
	if (isOn(spawnObjective)) 
	{
		flipOff(spawnObjective);
	} 
	else 
	{
		flipOn(spawnObjective);
	}  
	  printObjectiveStates();
}

getNumObjectivesControlled( team ) 
{

  if (team == game["attackers"])  
    return level.objCount["attackers"];
  else
    return level.objCount["defenders"];
  
}

setObjectives() 
{
	deleteObjectivesFromHud();
	addObjectiveToHud(getNextObjective(game["attackers"]), game["attackers"]);
	addObjectiveToHud(getNextObjective(game["defenders"]), game["defenders"]);
}

addObjectiveToHud(objective, team) 
{
	if (isdefined(objective)) 
	{	
		hudIndex = 0; //attackers
		if (team == game["defenders"])
			hudIndex = 1;
		
		objective_add(hudIndex, "current", objective.origin, "objpoint_star");
		objective_position(hudIndex, objective.origin);
		objective_team(hudIndex,team);
	}
}

deleteObjectivesFromHud() 
{
	objective_delete(0);
	objective_delete(1);
}

adjustObjectivesCount() 
{
	if ( isdefined(level.objCount) ) 
	{
			
		if (isdefined(level.objCount["attackers"]) )
			level.objCount["attackers"] = 0;	
		if (isdefined(level.objCount["defenders"]) )
			level.objCount["defenders"] = 0;

      
		for (n = 0; n < level.objectivearray.size; n++) 
		{	
			if (isOn(level.objectivearray[n])) 
			{
				level.objCount["attackers"] = level.objCount["attackers"] +1;
			} 
			else 
			{
				level.objCount["defenders"] = level.objCount["defenders"]+1;
			}
		}
	}
}

flipOff(objective) 
{
	objective.script_nodestate = "0";
	objective.team = game["defenders"];
}

flipOn(objective) 
{
	objective.script_nodestate = "1";
	objective.team = game["attackers"];
}

printObjectiveStates() 
{
	
  if (getcvar("scr_cnq_debug") != "1" )
    return;
    
	if (isdefined(level.objectivearray))  
	{
		for (n = 0; n < level.objectivearray.size; n++) 
		{
			spawnObjective = level.objectivearray[n];
			if ( isdefined(spawnObjective)) 
			{
				if (isOn(spawnObjective)) 
				{
					printDebug ("Objective number " + spawnObjective.script_idnumber + " is on.");
				} 
				else 
				{
					printDebug ("Objective number " + spawnObjective.script_idnumber + " is off.");
				}  
			}			
			else 
			{
				printDebug ("The spawnObjective at position " + n + " is not defined!!!!");
			}
		}
		
	} 
	else 
	{
		printDebug ("level.objectivearray is not defined!!!!");
	}
}

printDebug(text) 
{
  if (getcvar("scr_cnq_debug") == "1" ) 
    iprintln ("DEBUG: " + text);
}

performObjectiveCompleteTasks(objective, player, objectiveType) 
{
	if (objectiveType == "spawn") 
	{
		flipObjective(objective);
		level.firstSwitchThrown = true;
	}
	
	awardPoints(player, objectiveType);
	  
	if (objectiveType == "spawn") 
	{
		if (isdefined(level.cnqCallbackSpawnObjectiveComplete))
		  thread [[level.cnqCallbackSpawnObjectiveComplete]](objective, player);
	} 
	else 
	{
		if (isdefined(level.cnqCallbackBonusObjectiveComplete))
		  thread [[level.cnqCallbackBonusObjectiveComplete]](objective, player);
	}
	  
	logAction(player);
	if(level.mapended) // if map is over, bail out
		return;
	
	updatePlayerInfo();
	displayGameMessage(objective, player, objectiveType);
}

updatePlayerInfo() 
{
  setObjectives();
  adjustObjectivesCount();
  setObjectiveTextAll(); 
}

displayGameMessage (objective, player, objectiveType) 
{
  
  if (isdefined (objective.script_objective_name))
    objectiveName = objective.script_objective_name;
  else 
    objectiveName = "the objective";

  message = player.name + " ^7has reached ^2" + objectiveName + "^7.";
  
  if (objectiveType == "spawn")
// La Truffe ->
//    message = message + " The " + getColor(player.pers["team"]) + maps\mp\_ahz_utility::toUpper(player.pers["team"]) + " ^7are advancing!";
    message = message + " The " + getColor(player.pers["team"]) + toUpper(player.pers["team"]) + " ^7are advancing!";
// La Truffe <-

  if (objectiveType == "bonus")
// La Truffe ->
//    message = message + " The " + getColor(player.pers["team"]) + maps\mp\_ahz_utility::toUpper(player.pers["team"]) + " ^7are advancing!";
    message = message + " The " + getColor(player.pers["team"]) + toUpper(player.pers["team"]) + " ^7are advancing!";
// La Truffe <-

  iprintln (message);  
 self setObjectiveTextAll(); 
}

logAction(player) 
{
 	lpselfnum = player getEntityNumber();
	lpselfname = player.name;
	lpselfteam = player.pers["team"];
	lpselfguid = player getGuid();
	logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + "cnq_objective" + "\n");
}

awardPoints(player, objectiveType) 
{

	if (objectiveType == "bonus") 
	{
		playerPoints = getcvarint("scr_cnq_player_bonus_points");// level.player_bonus_points;
		teamPoints = getcvarint("scr_cnq_team_bonus_points");//level.team_bonus_points;
	} 
	else 
	{
		playerPoints = getcvarint("scr_cnq_player_objective_points");//level.player_obj_points;
		teamPoints = getcvarint("scr_cnq_team_objective_points");//level.team_obj_points;
	} 
	player.score += playerPoints;
	player checkScoreLimit ();
	player notify("update_playerhud_score");
	
	teamscore = getTeamScore(player.pers["team"]);
	teamscore += teamPoints;
	setTeamScore(player.pers["team"], teamscore);
	
	level notify("update_allhud_score");
}

playSound(soundAlias) 
{
	players = getentarray("player", "classname");
	
	for(i = 0; i < players.size; i++)	
		players[i] playLocalSound( soundAlias );
}

isOn(spawnObjective) 
{
  return (spawnObjective.script_nodestate == "1");
}

isOff(spawnObjective) 
{
  return (spawnObjective.script_nodestate == "0");
}

startHud() 
{
	if( !level.showobj_hud)
		return;

	level endon( "end_map" );
	for (;;) 
	{
		showHud();
		wait 0.5;
	}  
}

showHud() 
{
	teams = [];
	teams[ 0 ] = game["attackers"];
	teams[ 1 ] = game["defenders"];
	_startat = 20;
	_bump = 2;
	_ybase = 25;

	//first, display the static icons for deaths and objectives
	if (!isdefined (level._team_objs) ) 
	{
	
		_obj_icon = newHudElem();
		_obj_icon.x = 20;
		_obj_icon.y = 90;
		_obj_icon.alignX = "center";
		_obj_icon.alignY = "middle";
		_obj_icon.sort = 1;	
		_obj_icon setShader(game["objecticon_allies"], 25,25 );
		
		_obj_icon = newHudElem();
		_obj_icon.x = 51;
		_obj_icon.y = 90;
		_obj_icon.alignX = "center";
		_obj_icon.alignY = "middle";
		_obj_icon.sort = 1;	
		_obj_icon setShader(game["objecticon_axis"], 25,25 );
		level._score_icons[1] = _obj_icon;
	}
	
	for ( i = 0; i < teams.size; i++ ) 
	{
	
		if ( !isdefined( level._team_objs ) || !isdefined( level._team_objs[ i ] ) )
		{
			_obj = newHudElem();
			_obj.x = _startat + (i * 30);
			_obj.y = 110;
			_obj.alignX = "center";
			_obj.alignY = "middle";
			_obj.sort = 2;
			_obj.color = ( 1, 1, 0 );
			_obj.fontScale = 2;
		
			level._team_objs[ i ] = _obj;
		}
		else
			_obj = level._team_objs[ i ];
		
		_team = teams[ i ];
		_numobjs = getNumObjectivesControlled(_team);
		_obj setValue( _numobjs );
	}

	return;
}

getColor( team ) 
{
	
	color = "^7";
	switch ( team ) 
	{
		case "allies":
			color = "^4";
			break;
			
		case "axis":
			color = "^1";
			break;
	}
	return ( color );
}


getNextObjective ( team ) 
{
	if (team == game["attackers"]) 
	{
    	  
		for (i = 0; i < level.objectivearray.size; i++) 
		{
			if (isOff(level.objectivearray[i])) 
			{
				return level.objectivearray[i];
			}
		}
		teamRole = "attackers";

	} 
	else 
	{ 
		for (i = level.objectivearray.size - 1; i >= 0; i--) 
		{
			if (isOn(level.objectivearray[i])) 
			{
				return level.objectivearray[i];
			}
		}
		teamRole = "defenders";

	}
	//no spawn objectives currently, so check for a bonus objective
	for (i = 0; i < level.bonus_objectives.size; i++) 
	{   
		available = 0;
		if (isdefined(level.bonus_objectives[i].isAvailable))
			available = level.bonus_objectives[i].isAvailable;
    
		if ( level.bonus_objectives[i].script_team == teamRole && (available == 1))
			return level.bonus_objectives[i];
	}
	//no current objective, return nil
	return undefined;
}

setObjectiveTextAll() 
{
    printDebug ("setObjectiveTextAll()  was called.");
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
		setObjectiveText (players[i]);
  
}

setObjectiveText( player ) 
{
  	printDebug ("setObjectiveText( player )  was called.");
	nextObj = getNextObjective (player.pers["team"]);

	if (isdefined(nextObj)) 
	{
   		printDebug ("nextObj is defined.");
		if (isdefined (nextObj.script_objective_name))
			{
			objectiveName = nextObj.script_objective_name;
			printDebug ("nextObj.script_objective_name is defined and is " + objectiveName);
			}
		else
			objectiveName = "the next objective";

// La Truffe ->
//		objText = maps\mp\_ahz_utility::toUpper(player.pers["team"]) + "^7 must take ^2" + objectiveName + "^7";
		objText = toUpper(player.pers["team"]) + "^7 must take ^2" + objectiveName + "^7";
// La Truffe <-
	} 
	else 
	{
		if(player.pers["team"] == game["attackers"])
			objText = game["cnq_attackers_obj_text"];
		else if (player.pers["team"] == game["defenders"])
			objText = game["cnq_defenders_obj_text"];
		else
			objText = game["cnq_neutral_obj_text"];
	}

	player setClientCvar("cg_objectiveText", objText); 
}

respawn_timer(delay)
{
	self endon("disconnect");

	self.WaitingToSpawn = true;

	if(level.respawndelay > 0)
	{
		if(!isdefined(self.respawntimer))
		{
			self.respawntimer = newClientHudElem(self);
			self.respawntimer.x = 0;
			self.respawntimer.y = -50;
			self.respawntimer.alignX = "center";
			self.respawntimer.alignY = "middle";
			self.respawntimer.horzAlign = "center_safearea";
			self.respawntimer.vertAlign = "center_safearea";
			self.respawntimer.alpha = 0;
			self.respawntimer.archived = false;
			self.respawntimer.font = "default";
			self.respawntimer.fontscale = 2;
			self.respawntimer.label = (&"MP_TIME_TILL_SPAWN");
			self.respawntimer setTimer (level.respawndelay + delay);
		}

		wait delay;
		self thread updateTimer();

		wait level.respawndelay;

		if(isdefined(self.respawntimer))
			self.respawntimer destroy();
	}

	self.WaitingToSpawn = undefined;
}

updateTimer()
{
	if(isdefined(self.respawntimer))
	{
		if(isdefined(self.pers["team"]) && (self.pers["team"] == "allies" || self.pers["team"] == "axis") && isdefined(self.pers["weapon"]))
			self.respawntimer.alpha = 1;
		else
			self.respawntimer.alpha = 0;
	}
}

///////////////////////////////////////////////////////////////////////////////
// Convert lowercase characters in a string to uppercase
// CODE COURTESY OF [MC]HAMMER's CODADM
toUpper( str ) 
{
	return ( mapChar( str, "L-U" ) );
}

///////////////////////////////////////////////////////////////////////////////
// PURPOSE: 	Convert (map) characters in a string to another character.  A
//		conversion parameter determines how to perform the mapping.
// RETURN:	Mapped string
// CALL:	<str> = waitthread level.ham_f_utils::mapChar <str> <str>
// CODE COURTESY OF [MC]HAMMER's CODADM
mapChar( str, conv )
{
	if ( !isdefined( str ) || ( str == "" ) )
		return ( "" );

	switch ( conv )
	{
	  case "U-L":	case "U-l":	case "u-L":	case "u-l":
		from = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		to   = "abcdefghijklmnopqrstuvwxyz";
		break;
	  case "L-U":	case "L-u":	case "l-U":	case "l-u":
		from = "abcdefghijklmnopqrstuvwxyz";
		to   = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		break;
	  default:
	  	return ( str );
	}

	s = "";
	for ( i = 0; i < str.size; i++ )
	{
		ch = str[ i ];

		for ( j = 0; j < from.size; j++ )
			if ( ch == from[ j ] )
			{
				ch = to[ j ];
				break;
			}

		s += ch;
	}

	return ( s );
}