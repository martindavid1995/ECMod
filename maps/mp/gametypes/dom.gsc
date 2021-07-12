//*****************************************
//*    DOMination release 4 (Jan 2007)    *
//*             N.0.P.                    *
//* (Nedgerblansky & 0ddball Productions) *
//*****************************************
/**/
// *Credits:
// *
// * DOMination 2 gametype from  Nedgerblansky, Tally, Oddball based on the
// * original work of Matthias Lorenz on his mod ADMIRALMod, http://www.cod2mod.com.
// *

/*
	Domination
	Objective: 	Score points for your team by capturing the enemy's flag and returning it to your base
	Map ends:	When one team reaches the score limit, or time limit is reached
	Respawning:	Instant / At base

	Level requirements
	------------------
		Spawnpoints:
			classname		mp_dm_spawn
			Allied players spawn from these.
			classname		mp_dm_spawn
			Axis players spawn from these.

		Spectator Spawnpoints:
			classname		mp_global_intermission
			Spectators spawn from these and intermission is viewed from these positions.
			Atleast one is required, any more and they are randomly chosen between.

	Level script requirements
	-------------------------
		Team Definitions:
			game["allies"] = "american";
			game["axis"] = "german";
			This sets the nationalities of the teams. Allies can be american, british, or russian. Axis can be german.

		If using minefields or exploders:
			maps\mp\_load::main();

	Optional level script settings
	------------------------------
		Soldier Type and Variation:
			game["american_soldiertype"] = "normandy";
			game["german_soldiertype"] = "normandy";
			This sets what character models are used for each nationality on a particular map.

			Valid settings:
				american_soldiertype	normandy
				british_soldiertype		normandy, africa
				russian_soldiertype		coats, padded
				german_soldiertype		normandy, africa, winterlight, winterdark

/*--------------------------------------------------------------------------------------
	Updates, Additions and Standalone Version:
		
	La Tuffe (nedgerblansky), Tally, & Oddball
	
	credits:
	
	Some script in here was originally coded by Pointy - www.planetpointy.co.uk
----------------------------------------------------------------------------------------*/
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
	
	game["dom_language"] = "english";
	
	if(!isDefined(game["roundsplayed"])) game["roundsplayed"] = 0;	
}

Callback_StartGameType()
{
	level.splitscreen = isSplitScreen();

	// defaults if not defined in level script
	if(!isDefined(game["allies"]))
		game["allies"] = "american";
	if(!isDefined(game["axis"]))
		game["axis"] = "german";

	// server cvar overrides
	if(getCvar("scr_allies") != "")
		game["allies"] = getCvar("scr_allies");
	if(getCvar("scr_axis") != "")
		game["axis"] = getCvar("scr_axis");
	
	
	if(!isDefined(game["alliedscore"]))	game["alliedscore"] = 0;
	if(!isDefined(game["axisscore"]))	game["axisscore"] = 0;

	level.compassflag_allies 	= "compass_flag_" + game["allies"];
	level.compassflag_axis 		= "compass_flag_" + game["axis"];
	level.compassflag_empty 	= "gfx/custom/objective_empty.tga";
	
	level.objpointflag_allies 	= "objpoint_flagpatch1_" + game["allies"];
	level.objpointflag_axis 	= "objpoint_flagpatch1_" + game["axis"];	
	level.objpointflag_empty 	= "gfx/custom/objpoint_empty.tga";

	level.hudicon_empty 		= "gfx/custom/headicon_empty.tga";

	precacheStatusIcon("hud_status_dead");
	precacheStatusIcon("hud_status_connecting");
	precacheRumble("damage_heavy");
	precacheShader ("hudStopwatch");
	precacheShader(level.compassflag_allies);
	precacheShader(level.compassflag_axis);
	precacheShader(level.objpointflag_allies);
	precacheShader(level.objpointflag_axis);
	
	precacheShader(level.compassflag_empty);
	precacheShader(level.objpointflag_empty);
	precacheShader(level.hudicon_empty);
	
	precacheShader("gfx/custom/flagge_german.tga");
	precacheShader("gfx/custom/flagge_" + game["allies"] + ".tga");
	
	
	
	precacheModel("xmodel/prop_flag_" + game["allies"]);
	precacheModel("xmodel/prop_flag_" + game["axis"]);
	precacheString(&"MP_TIME_TILL_SPAWN");
	precacheString(&"PLATFORM_PRESS_TO_SPAWN");

	precacheModel("xmodel/fahne");
	precacheModel ("xmodel/prop_flag_base");

  precacheString(&"DOM_WAITING_FOR_PLAYERS");
	precacheString(&"DOM_MATCH_STARTING");

	
	
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
	thread maps\mp\gametypes\_objpoints::init();
	thread maps\mp\gametypes\_friendicons::init();
	thread maps\mp\gametypes\_spectating::init();
	thread maps\mp\gametypes\_grenadeindicators::init();

	level.xenon = (getcvar("xenonGame") == "true");
	if(level.xenon) // Xenon only
		thread maps\mp\gametypes\_richpresence::init();
	else // PC only
		thread maps\mp\gametypes\_quickmessages::init();

	setClientNameMode("auto_change");
	
	DOM_InitMapConfig ();
	
	// Switching spawn position at each round ?
	level.switchspawns = cvardef("scr_dom_switchspawns",0 , 0, 1, "int");
	setCvar("ui_switchspawns", level.switchspawns);
	storeServerInfoDvar ("ui_switchspawns");
	
  DOM_InitSpawnsAndFlagsOrders();
 	
  //Assert that the spawntype is compliant with the current map
  
  assert(isSpawnTypeCompliant(level.spawn_allies, level.spawn_axis));
  	
	setSpawnPoints(level.spawn_allies);
  if (level.spawn_allies != level.spawn_axis) //For "sd" or "ctf"
      setSpawnPoints(level.spawn_axis);
  
	allowed[0] = "ctf"; // Das muﬂ so bleiben
	maps\mp\gametypes\_gameobjects::main(allowed);

  //NO score limit for DOM
	level.scorelimit = 0;
	
	// Round limit per map
	level.roundlimit = cvardef ("scr_dom_roundlimit", 5, 0, 99, "int");
	setCvar("ui_roundlimit", level.roundlimit);
	makeCvarServerInfo("ui_roundlimit", "0");

	level.graceperiod = cvardef("scr_dom_graceperiod", 15, 0, 60, "int");

	// Time length of each round
	level.roundlength = cvardef("scr_dom_roundlength", 4, level.graceperiod / 60, 60, "int");
  setCvar("ui_roundlength", level.roundlength);
	makeCvarServerInfo("ui_roundlength", "0");
	
	//Most Flags captured Wins ? Default is "All Flags captured" wins
	level.mostflagswins = cvardef ("scr_dom_mostflagswins", 0, 0, 1, "int");
	
  // Warmup time
	level.warmuptime = cvardef ("scr_dom_warmuptime", 60, 1, 600, "int");

	// Cool down time
	level.cooldowntime = cvardef ("scr_dom_cooldowntime", 10, 1, 600, "int");
	
	//Time Limit per map
	level.timelimit = cvardef("scr_dom_timelimit", 0, 0, 1449, "float");
	setCvar("ui_timelimit", level.timelimit);
	makeCvarServerInfo("ui_timelimit", "0");
	
	
	
	if(!isdefined(game["timepassed"]))
		game["timepassed"] = 0;	
		
	
	// Force respawning
	if(getCvar("scr_forcerespawn") == "")
		setCvar("scr_forcerespawn", "0");

	// Use objective points
	if (IsmodAWE ())
		level.awe_objectivepoints = cvardef("awe_objective_points", 1, 0, 1, "int");

//#######################################
	if(!isDefined(game["state"]))
		game["state"] = "waiting";

	level.mapended = false;
//#######################################
//#######################################
	level.roundstarted = false;
	level.roundended = false;
//#######################################

	level.team["allies"] = 0;
	level.team["axis"] = 0;

	level.respawndelay = cvardef("scr_dom_respawndelay", 10, 1, 60, "int");
	level.pointscaptureflag = cvardef("scr_dom_pointscaptureflag", 5, 1, 50, "int");
	level.flagcapturetime = cvardef("scr_dom_flagcapturetime", 10, 1, 45, "int");
	level.spawndistance = cvardef("scr_dom_spawndistance", 250, 1, 99999, "int");
	level.flagsnumber = cvardef("scr_dom_flagsnumber", 5, 0, 99, "int");
	level.randomflags = cvardef ("scr_dom_randomflags", 0, 0, 1, "int");
	
	if (level.flags.size && (! level.randomflags))
		level.flagtimeout = 0;
	else
		level.flagtimeout = cvardef ("scr_dom_flagtimeout", 120, 0, 9999, "int");
	
	level.showflagpoints = cvardef ("scr_dom_showflagpoints", 1, 0, 1, "int");

	thread initFlags();
	thread startGame();
	thread updateGametypeCvars();
	thread maps\mp\gametypes\_teams::addTestClients();
	
	level.winning_team = "none";
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
	
  if(!isDefined(self.pers["team"]) && (!level.splitscreen))
	    iprintlnFIXED (&"MP_CONNECTED", self);
	
	lpselfnum = self getEntityNumber();
	lpGuid = self getGuid();
	logPrint("J;" + lpGuid + ";" + lpselfnum + ";" + self.name + "\n");

	self thread setServerInfoDvars ();

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
			
		self maps\mp\gametypes\_spectating::setSpectatePermissions ();

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
	   iprintlnFIXED(&"MP_DISCONNECTED", self);
	
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
//############################################################
	if(level.roundstarted || game["state"] == "warmup")
		level thread CheckTeams();
//############################################################
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

//#########################################################################################
	if(!isdefined(self.switching_teams) && !level.roundended && level.roundstarted)
	{
		self.pers["deaths"]++;
		self.deaths = self.pers["deaths"];
	}
//#########################################################################################

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
					{
						attacker.pers["score"]--;
						attacker.score = attacker.pers["score"];
					}
				}
			}

			if(isdefined(attacker.friendlydamage))
				attacker iprintln(&"MP_FRIENDLY_FIRE_WILL_NOT");
		}
		else
		{
			attackerNum = attacker getEntityNumber();
			doKillcam = true;
			
			//##############################
			//if game has started and has not ended
			if (!level.roundended && level.roundstarted)
			{
			//##############################
				if(self.pers["team"] == attacker.pers["team"]) // killed by a friendly
				{
				 attacker.pers["score"]--;
				 attacker.score = attacker.pers["score"];
			  }
			  else
			  {
				 attacker.pers["score"]++;
				 attacker.score = attacker.pers["score"];
			  }
			}
		}

		lpattacknum = attacker getEntityNumber();
		lpattackguid = attacker getGuid();
		lpattackname = attacker.name;
		lpattackerteam = attacker.pers["team"];
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		doKillcam = false;

		self.pers["score"]--;
		self.score = self.pers["score"];

		lpattacknum = -1;
		lpattackname = "";
		lpattackguid = "";
		lpattackerteam = "world";
	}

	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

//##############################
	if(level.roundended)
		return;
//##############################

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
	
	if(self.pers["team"] == "allies")
		  spawnpointname = level.spawn_allies;
	  else
		  spawnpointname = level.spawn_axis;
	
		
		spawnpoints = getentarray(spawnpointname, "classname");
    
		
	 // Find a spawn point away from the flags
	
	 spawnpoint = undefined;
	 for (i = 0; i < 50; i ++)
	 {
		 spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam (spawnpoints);
		 if (spawnpoint IsAwayFromFlags (level.spawndistance))
			 break;
	 }
	
	//End of modifications.

	if(isDefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
  
  if(!isdefined(self.pers["score"]))
		self.pers["score"] = 0;
	self.score = self.pers["score"];

	if(!isdefined(self.pers["deaths"]))
		self.pers["deaths"] = 0;
	self.deaths = self.pers["deaths"];
	
	if(!isDefined(self.pers["savedmodel"]))
		maps\mp\gametypes\_teams::model();
	else
		maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	self maps\mp\gametypes\_weapons::givePistol();
	self maps\mp\gametypes\_weapons::giveGrenades();
	self maps\mp\gametypes\_weapons::giveBinoculars();

	if(!isdefined(self))
		return;

	self giveWeapon(self.pers["weapon"]);
	self giveMaxAmmo(self.pers["weapon"]);
	self setSpawnWeapon(self.pers["weapon"]);
	

	if(!level.splitscreen)
	{
		self setClientCvar("cg_objectiveText", &"DOM_OBJ_TEXT_NOSCORE");
	}
	else
		self setClientCvar("cg_objectiveText", &"DOM_OBJ_TEXT");

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

	while(isdefined(self.WaitingToSpawn)) wait .05;



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
	setTeamScore("allies", game["alliedscore"]);
	setTeamScore("axis", game["axisscore"]);

  level.starttime = getTime();
//##############################
	thread startRound();
	showWaiting();
//##############################
  
}

endMap()
{
	game["state"] = "intermission";
	level notify("intermission");
	
	level.roundended=true;

	
	if(isDefined(level.roundclock))		
		level.roundclock destroy();	
				
  if(isDefined(level.roundnumber))		
		level.roundnumber destroy();
	if(isDefined(level.roundslash))		
		level.roundslash destroy();
	if(isDefined(level.roundmax))		
		level.roundmax destroy();
		
	winningteam = "tie";
	losingteam = "tie";
	text = &"MP_THE_GAME_IS_A_TIE";
	
	DOM_SetRoundWinners();
	
	if(level.winning_team == "allies")
	{
			game["alliedscore"]++;
			setTeamScore("allies", game["alliedscore"]);
					
			winningteam = "allies";
			losingteam = "axis";
			text = &"MP_ALLIES_WIN";
					
			level createLevelHudElement("flag_winner", 320,110, "center","middle","fullscreen","fullscreen",false,"gfx/custom/flagge_" + game["allies"] + ".tga",128,128,1,0.9,1,1,1);
	}
				
	if(level.winning_team == "axis")
	{
			game["axisscore"]++;
			setTeamScore("axis", game["axisscore"]);
					
			winningteam = "axis";
			losingteam = "allies";
			text = &"MP_AXIS_WIN";
					
			level createLevelHudElement("flag_winner", 320,110, "center","middle","fullscreen","fullscreen",false,"gfx/custom/flagge_german.tga",128,128,1,0.9,1,1,1);
	}
		
		level notify("update_allhud_score");
	
		iprintlnbold(text);
	
		winners = "";
		losers = "";
	
		if(winningteam == "allies")
			level thread playSoundOnPlayers("MP_announcer_allies_win");
		else if(winningteam == "axis")
			level thread playSoundOnPlayers("MP_announcer_axis_win");
		else
			level thread playSoundOnPlayers("MP_announcer_round_draw");
	

	wait 0.5;
	level notify("end_map");


	//############################################################
		//do endround delay
		wait(level.cooldowntime);
	//############################################################
	
		level deleteLevelHudElementByName("flag_winner");
		wait(level.cooldowntime);
	
		// * Rounds Check * 
		game["roundsplayed"]++;
				
	  timeLimitReached = checkTimeLimit();
	  
	if((game["roundsplayed"] < level.roundlimit) && !timeLimitReached ) 
	{
		iprintlnbold(&"DOM_START_NEXT_ROUND");
		
		wait(level.cooldowntime);
			
		players = getentarray("player", "classname");
		for(i = 0; i < players.size; i++) 
		{
			players[i].pers["rank"] = 1;
		}
			
		level.mapended = false;
		
		deleteFlags();
		deleteLevelHudElements();
				
		game["state"] = "playing";
		level notify("restarting");
		
		map_restart(true);		
	}
	else 
	{
		if (timeLimitReached) iprintlnbold(&"MP_TIME_LIMIT_REACHED");
		
		if (IsModAWE ())
		  awe\_global::EndMap ();

		if(game["alliedscore"] == game["axisscore"]) 
		{
			text = &"MP_THE_GAME_IS_A_TIE";
		}
		else if(game["alliedscore"] > game["axisscore"]) 
		{
			text = &"MP_ALLIES_WIN";
			winningteam = "axis";
			losingteam = "allies";
		}
		else 
		{
			text = &"MP_AXIS_WIN";
			winningteam = "allies";
			winningteam = "axis";
		}
		
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
		
		wait 10;
			
		exitLevel(false);
	}
}


updateGametypeCvars()
{
	for(;;)
	{
		timelimit = cvardef("scr_dom_timelimit", 0, 0, 1440, "float");
		if(level.timelimit != timelimit)
		{
		 level.timelimit = timelimit;
		 setCvar("ui_timelimit", level.timelimit);
	  }
	  
	  wait 1;
	  
		roundlimit = getCvarInt("scr_dom_roundlimit");
		if(level.roundlimit != roundlimit)
		{
			level.roundlimit = roundlimit;
			setCvar("ui_roundlimit", level.roundlimit);			
		} 

		wait 1;
		
		roundlength = getCvarInt("scr_dom_roundlength");
		if(level.roundlength != roundlength)
		{
			level.roundlength = roundlength;
			setCvar("scr_dom_roundlength", level.roundlength);			
		}
		
		wait 1; 
	}
}

printJoinedTeam(team)
{
	if(!level.splitscreen)
	{
		if(team == "allies")
		    iprintlnFIXED(&"MP_JOINED_ALLIES", self);
	    else if(team == "axis")
		    iprintlnFIXED(&"MP_JOINED_AXIS", self);
	}
}

initFlags()
{
	level.hud_dom_pos_y = 20;
	level.flag_radius 	= 80;
	
	if ((! level.flags.size) || level.randomflags)
	{
		level.flags = [];
		
		spawnpoints = getentarray("mp_dm_spawn", "classname");
		for (i = 0; i < spawnpoints.size; i++)
			spawnpoints[i] placeSpawnpoint ();
		
		j = randomInt(spawnpoints.size);
		
		level.flags[0] = spawnpoints[j];	
		//logprint("Flag "+flags.size+ " : " + spawnpoints[j].origin + "\n");
		
		if (level.flagsnumber > 0)
			// Fixed number of flags
			flagsnumber = level.flagsnumber;
		else
		{
			// Variable number of flags, depending on the number of players
			// We have to wait until teams are populated
			
			while (! check_teams_exist ())
			{
				iprintlnbold (&"DOM_WAITING_FOR_PLAYERS");
				wait 20;
			}
			
			players = getentarray ("player", "classname");
			flagsnumber = players.size / 2 + 1;
		}
	
		if (flagsnumber < 2)
			flagsnumber = 2;
		if (flagsnumber > 7)
			flagsnumber = 7;

		trys = 0;
		
		while(level.flags.size < flagsnumber) 
		{
			trys++;
			if(trys > 100) break;
		
			j = randomInt(spawnpoints.size);
			
			near = false;
			
			for(i=0;i<level.flags.size;i++) 
			{
				if(distance(spawnpoints[j].origin,level.flags[i].origin) < 1000) 
				{
					near = true;
					break;
				}
			}
		
			if(near == true) 
				continue;
			
			level.flags[level.flags.size] = spawnpoints[j];					
		}
	}

  flags = level.flags;	
	
	for(i=0;i<flags.size;i++) 
	{
		team 							= "none";			

		flags[i].flagmodel 	= spawn("script_model", flags[i].origin);
		flags[i].flagmodel.angles 		= flags[i].angles;
		flags[i].flagmodel setmodel("xmodel/fahne");
	
		flags[i].basemodel 	= spawn("script_model", flags[i].origin);
		flags[i].basemodel.angles = flags[i].angles;
		flags[i].basemodel setmodel("xmodel/prop_flag_base");

		flags[i].team 					= team;
		flags[i].objective 				= i;
		flags[i].compassflag 			= level.compassflag_empty;
		flags[i].objpointflag 			= level.objpointflag_empty;
		
		flags[i] thread flag();		


		level createLevelHudElement ("flag_" + flags[i].objective, 325 + 36 * i - 18 * (flags.size - 1), level.hud_dom_pos_y, "center", "middle", "fullscreen", "fullscreen", false, level.hudicon_empty, 32, 32, 1, 0.8, 1, 1, 1);
	}	
	
	level.flagscaptured["allies"] = 0;
	level.flagscaptured["axis"] = 0;
	
	level thread checkWin(flags);
}

FlagTimeOut()
{
	if(!level.roundstarted)
		return;	
	
	while (isdefined (level.FlagTimeOut_running) && level.FlagTimeOut_running)
		// No multiple occurrences allowed otherwise new flag point selection will yield unpredictable results
		wait (randomint (10) / 10);

	iprintln (&"DOM_CAPTURE_TIMEOUT", level.flagtimeout);
	iprintln (&"DOM_NEW_FLAG", 5);
	
	level.FlagTimeOut_running = true;
	self.flagmodel hide ();
	self.basemodel hide ();
	self deleteFlagWaypoint ();
	objective_state (self.objective, "invisible");
	level changeLevelHudElementByName ("flag_" + self.objective, 0);

	spawnpoints = getentarray ("mp_dm_spawn", "classname");
	
	new_point = undefined;
	for (i = 0; i < 100 ; i ++)
	{
		new_point = spawnpoints[randomint (spawnpoints.size)];
		if (new_point IsAwayFromFlags (1000))
			break;
	}

	wait 5;

	self.origin = new_point.origin;
	self.flagmodel.origin = self.origin;
	self.flagmodel.angles = self.angles;
	self.basemodel.origin = self.origin;
	self.basemodel.angles = self.angles;
	level changeLevelHudElementByName ("flag_" + self.objective, 0.8);
	objective_position (self.objective, self.origin);
	objective_state (self.objective, "current");
	self createFlagWaypoint ();
	self.flagmodel show ();
	self.basemodel show ();

	level.FlagTimeOut_running = false;
}

flag()
{
	level endon("end_map");

	
		objective_add(self.objective, "current", self.origin, self.compassflag);
		self createFlagWaypoint();
	
	
	for(;;)
	{
						
		other = WaitForRadius(self.origin, level.flag_radius, 50);

		if (! isdefined (other))
			// no return value for WaitForRadius : time out for the flag
			self FlagTimeOut ();
							
		else if(isPlayer(other) && isAlive(other) && (other.pers["team"] != "spectator") && level.roundstarted && !level.roundended) 
		{
			if(check_teams_exist()) 
			{
				// Touched by enemy

			if ((other.pers["team"] != self.team) && self DOM_CanCapture (other, other.pers["team"]))
				{
					self startCaptureProgress(other.clientid, other.pers["team"]);
					
					
				}
			}
			else 
			{
				other iprintlnbold(&"DOM_WAIT_FOR_TEAM");				
				wait 7;
			}
			
			// Flag is reachable
			self.reachable = true;
		}
		
		wait 0.5;
	}
}

startCaptureProgress(clientid, team) 
{
	
	origin 	= self.origin;
	swatch 	= 0;
	
	//Prepare the blinking of objective icon on compass and HUD.
	
	if (team =="allies")
	{
	   compass_icon[0] = level.compassflag_allies;
	   hud_icon[0] = game["hudicon_allies"];
	}
	else if (team == "axis")
	{
	   compass_icon[0] = level.compassflag_axis;
	   hud_icon[0] = game["hudicon_axis"];
	}
	else 
	{
		self.flagmodel stopLoopSound();
		return;
	}
	
	compass_icon[1] = self.compassflag;
	
	if (self.team =="allies")
		hud_icon[1] = game["hudicon_allies"];
	else if (self.team == "axis")
		hud_icon[1] = game["hudicon_axis"];
	else 
		hud_icon[1] = level.hudicon_empty;
		
	other = getPlayerPlaying(clientid,team);
	
	if (!isdefined(other)) 
	   return;

	helper = self.basemodel;

	
  
	other DOM_SetCaptureProgressIndicator();
	
	helper playloopsound("dom_start_flag_capture");
  
  other.progresstime = 0;    
  
	// * Objective capture *	
	while(isAlive(other) && (other.progresstime < level.flagcapturetime)) 
	{
		//Compass and HUD blink.
		objective_icon(self.objective, compass_icon[swatch] );
	  
	  level changeLevelHudElementShaderByName ("flag_" + self.objective, hud_icon[swatch], 32, 32);
		
		
		//Player (other) not in flag radius or dead
    if(!(self DOM_CanCapture(other, team)) ) 
   		{
   			other DOM_DestroyCaptureProgressIndicator();
			
			  objective_icon(self.objective, self.compassflag);
							  			
			  level changeLevelHudElementShaderByName ("flag_" + self.objective, hud_icon[1], 32, 32);
			
			  helper stopLoopSound();
			  
			  return;
		  }
		
		other.progresstime += 0.5;
		
		swatch++;
		if(swatch > 1) swatch = 0;
		
		wait 0.45;
		
	}
	
		
	other DOM_DestroyCaptureProgressIndicator();
  helper stopLoopSound();
			
	other = getPlayerPlaying(clientid,team);
	
	if(isDefined(other)) 
		other GetFlag(self); // Getting flag
	else 
	{
		objective_icon(self.objective, self.compassflag);
		level changeLevelHudElementShaderByName ("flag_" + self.objective, hud_icon[1], 32, 32);
	}	
}



GetFlag(flag) 
{
	self endon("disconnect");

	if(level.pointscaptureflag > 0) 
	{
		givePlayerPoints(self.clientid,self.pers["team"],level.pointscaptureflag);
	}
  
  enemy_team = EnemyTeam(self.pers["team"]);
  
  if (flag.team == enemy_team)
     level.flagscaptured[enemy_team]--;
      
	level.flagscaptured[self.pers["team"]] ++;
	
	if(self.pers["team"] == "allies") 
	{
		flag.team = "allies";	
		
		kurz = self GetTeamKurz();
		
		if(!DOM_checkAllObjectivesTaken()) 
		{
			if(flag.team != "axis") 	level thread playSoundOnPlayers("dom_" + kurz + "_area_secured_" + game["dom_language"], "allies");	
			else						level thread playSoundOnPlayers("dom_" + kurz + "_ground_taken_" + game["dom_language"], "allies");	
			level thread playSoundOnPlayers("dom_GE_lost_ground_" + game["dom_language"], "axis");
		}
	
		flagModel = "xmodel/prop_flag_" + game["allies"];
		flag.flagmodel setmodel(flagModel);	
		
		flag.compassflag = level.compassflag_allies;
		objective_icon(flag.objective, flag.compassflag);
		
		
		if (level.showflagpoints)
			flag.objpointflag = level.objpointflag_allies;
		
		level changeLevelHudElementShaderByName("flag_" + flag.objective, game["hudicon_allies"], 32, 32);

	}
	else 
	{
		flag.team = "axis";	  

    kurz = GetKurzAllies();

		if(!DOM_checkAllObjectivesTaken()) 
		{
			if(flag.team != "allies")	
				level thread playSoundOnPlayers("dom_GE_area_secured_" + game["dom_language"], "axis");
			else						
				level thread playSoundOnPlayers("dom_GE_ground_taken_" + game["dom_language"], "axis");

			level thread playSoundOnPlayers("dom_" + kurz + "_lost_ground_" + game["dom_language"], "allies");	
		}

		flagModel = "xmodel/prop_flag_" + game["axis"];
		flag.flagmodel setmodel(flagModel);	
		
		flag.compassflag = level.compassflag_axis;
		objective_icon(flag.objective, flag.compassflag);
		
		
		if (level.showflagpoints)
			flag.objpointflag = level.objpointflag_axis;

		level changeLevelHudElementShaderByName("flag_" + flag.objective, game["hudicon_axis"], 32, 32);

	}		

	self.dont_auto_balance = true;
  
  flag createFlagWaypoint();	
	
		
}

createFlagWaypoint()
{
	if(IsmodAWE () && !level.awe_objectivepoints)
		return;

	self deleteFlagWaypoint();

	waypoint = newHudElem();
	waypoint.x = self.origin[0];
	waypoint.y = self.origin[1];
	waypoint.z = self.origin[2] + 100;
	waypoint.alpha = .61;
	waypoint.archived = true;

	if(level.splitscreen)
		waypoint setShader(self.objpointflag, 14, 14);
	else
	{
		if (level.showflagpoints)
			waypoint setShader(self.objpointflag, 7, 7);
	}

	waypoint setwaypoint(true);
	self.waypoint_flag = waypoint;

}

deleteFlagWaypoint()
{
	if(IsmodAWE () && !level.awe_objectivepoints)
		return;

	if(isdefined(self.waypoint_flag))
		self.waypoint_flag destroy();
}

checkWin(flags) 
{
	level notify("checkWin");
	level endon("checkWin");
	
	while(isDefined(flags)) 
	{
		if(DOM_checkAllObjectivesTaken()) 
		{
			if(flags[0].team == "allies")	
				level.winning_team = "allies";
			else							
				level.winning_team = "axis";
	
			level.mapended = true;
			
			level thread endMap();
		
			break;
		}		
		
		wait 0.5;
	}
}



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

printOnTeam(text, team, playername)
{
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
			players[i] iprintln(text,playername);
	}
}

menuAutoAssign()
{
	if(!level.xenon && isdefined(self.pers["team"]) && (self.pers["team"] == "allies" || self.pers["team"] == "axis"))
	{
		self openMenu(game["menu_team"]);
		return;
	}

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


	self.pers["remember_player_class"] 		= -1;
	self.pers["preselected_player_class"] 	= -1;
	self.pers["player_class"] 				= -1;	

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
		if(!level.xenon && !maps\mp\gametypes\_teams::getJoinTeamPermissions("allies"))
		{
			self openMenu(game["menu_team"]);
			return;
		}

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


		self.pers["remember_player_class"] 		= -1;
		self.pers["preselected_player_class"] 	= -1;
		self.pers["player_class"] 				= -1;	

		self setClientCvar("ui_allow_weaponchange", "1");
		self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);

		self notify("joined_team");
		self notify("end_respawn");
	}

	if(!isdefined(self.pers["weapon"])) 
	{
		self openMenu(game["menu_weapon_allies"]);
	}
}

menuAxis()
{
	if(self.pers["team"] != "axis")
	{
		if(!level.xenon && !maps\mp\gametypes\_teams::getJoinTeamPermissions("axis"))
		{
			self openMenu(game["menu_team"]);
			return;
		}

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


		self.pers["remember_player_class"] 		= -1;
		self.pers["preselected_player_class"] 	= -1;
		self.pers["player_class"] 				= -1;	


		self setClientCvar("ui_allow_weaponchange", "1");
		self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);


		self notify("joined_team");
		self notify("end_respawn");
	}

	if(!isdefined(self.pers["weapon"])) {
		self openMenu(game["menu_weapon_axis"]);
	}
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


		self.pers["remember_player_class"] 		= -1;
		self.pers["preselected_player_class"] 	= -1;
		self.pers["player_class"] 				= -1;	

		self thread updateTimer();

		spawnSpectator();

//##############################	
		thread CheckTeams();
//##############################

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
	self endon("disconnect");


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

//##############################
		thread CheckTeams();
//##############################

		self thread printJoinedTeam(self.pers["team"]);
	}
	else
	{
		self.pers["next_spawn_weapon"] = weapon;
		
		self.pers["weapon"] = weapon;

		weaponname = maps\mp\gametypes\_weapons::getWeaponName(self.pers["weapon"]);
	
		if(maps\mp\gametypes\_weapons::useAn(self.pers["weapon"]))
			self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_AN", weaponname);
		else
			self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_A", weaponname);
	}

	self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
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

createLevelHudElement(hud_element_name, x,y,xAlign,yAlign,horzAlign,vertAlign,foreground,shader,shader_width,shader_height,sort,alpha,color_r,color_g,color_b) 
{
	
	if(!isDefined(level.hud)) level.hud = [];
	
	count = level.hud.size;

	level.hud[count] = newHudElem();
	level.hud[count].x = x;
	level.hud[count].y = y;
	level.hud[count].alignX = xAlign;
	level.hud[count].alignY = yAlign;
	level.hud[count].horzAlign = horzAlign;
	level.hud[count].vertAlign = vertAlign;
	level.hud[count].foreground = foreground;
	level.hud[count] setShader(shader, shader_width, shader_height);	
	level.hud[count].sort = sort;
	level.hud[count].alpha = alpha;
	level.hud[count].color = (color_r,color_g,color_b);
	
	level.hud[count].name 			= hud_element_name;
	level.hud[count].shader_name 	= shader;
	level.hud[count].shader_width 	= shader_width;
	level.hud[count].shader_height 	= shader_height;
}

changeLevelHudElementByName(hud_element_name,alpha) 
{
	if(isDefined(level.hud) && level.hud.size > 0) 
	{
	
		for(i=0;i<level.hud.size;i++) 
		{
			if(isDefined(level.hud[i].name) && level.hud[i].name == hud_element_name) 
			{
 				if(isDefined(level.hud[i])) level.hud[i].alpha = alpha;
				
				break;
			}
		}	
	}
}

deleteLevelHudElementByName(hud_element_name) 
{

	// * HUD-Elemente entfernen *
	if(isDefined(level.hud) && level.hud.size > 0) 
	{
	
		for(i=0;i<level.hud.size;i++) 
		{
			if(isDefined(level.hud[i].name) && level.hud[i].name == hud_element_name) 
			{
				level.hud[i] destroy();
				level.hud[i].name = undefined;
			}
		}
		
		new_ar = [];
		
		for(i=0;i<level.hud.size;i++) 
		{
			if(isDefined(level.hud[i].name)) new_ar[new_ar.size] = level.hud[i];			
		}
		
		level.hud = new_ar;
	}
}

WaitFlagTimeOut (timeout)
{
	if (isdefined (self.reachable))
		// No more time out for this flag
		return;
		
	wait (timeout);
	
	// If still not reachable, time out !
	if (! isdefined (self.reachable))
		self notify ("flag_timeout");
}

WaitForRadius(origin, radius, height) 
{
	self endon ("flag_timeout");
	
	if (level.flagtimeout)
		self thread WaitFlagTimeOut (level.flagtimeout);

	if(!isDefined(origin) || !isDefined(radius) || !isDefined(height)) return;

	trigger = spawn("trigger_radius", origin, 0, radius, height);	

	while(1) 
	{
		trigger waittill("trigger", other);	
	
		if(isPlayer(other) && other.sessionstate == "playing") 
		{
			if(isDefined(trigger)) trigger delete();
			return other;
		}	
		
		wait 0.1;
	}
	
	if(isDefined(trigger)) trigger delete();
}

getPlayerPlaying(client_id,team) 
{
 	self endon("disconnect");

	players = getentarray("player", "classname");

	for(i=0;i<players.size;i++) 
	{
		if(players[i].sessionstate == "playing" && players[i].clientid == client_id && isDefined(players[i].pers["team"]) && players[i].pers["team"] == team) 
		{
			return players[i];
		}
	}
		
	return undefined;
}

getPlayerOrigin(client_id) 
{

 	self endon("disconnect");


	players = getentarray("player", "classname");

	for(i=0;i<players.size;i++) 
	{
		if(players[i].sessionstate == "playing" && players[i].clientid == client_id) 
		{
			return players[i].origin;
		}
	}
		
	return undefined;
}

givePlayerPoints(clientid,clientteam,points) 
{	
	if(!isDefined(clientid) || !isDefined(clientteam)) 
		return;
	
	if(clientteam != "allies" && clientteam != "axis")
		return;
	
	players = getentarray("player", "classname");

	for(i=0;i<players.size;i++) 
	{
		if(players[i].clientid == clientid && players[i].sessionstate == "playing") 
		{	
			players[i] doPlayerPoints(clientteam,points);
			break;
		}
	}	
}


GetTeamKurz() 
{
	self endon("killed_player");
	self endon("disconnect");

	kurz = "GE";

	if(self.pers["team"] == "allies")
	{
		switch(game["allies"]) 
		{
		case "american":
			kurz = "US";			
			break;
		case "british":
			kurz = "UK";			
			break;		
		case "russian":
			kurz = "RU";			
			break;
		}
	}
	
	return kurz;
}

GetKurzAllies() 
{

	kurz = "US";
	
	switch(game["allies"]) 
	{
		case "american":
			kurz = "US";			
			break;
		case "british":
			kurz = "UK";			
			break;		
		case "russian":
			kurz = "RU";			
			break;
	}
	
	return kurz;
}

checkTimeLimit()
{
	if(level.timelimit <= 0)
		return false;
		
  game["timepassed"] = game["timepassed"] + ((getTime() - level.starttime) / 1000) / 60.0;
  
	if(game["timepassed"] >= level.timelimit)
		return true;
	
	return false;
}

checkOtherPlayerInRange(client_id, origin, team, radius) 
{
	wait 0.05;
	
	players = getentarray("player", "classname");

	for(i = 0; i < players.size; i++) 
	{             
		if(players[i].sessionstate == "playing" && isDefined(players[i].pers["team"]) && (players[i].pers["team"] == team || team == "all") && distance(players[i].origin,origin) < radius && players[i].clientid != client_id) 
		{
			return players[i].clientid;			
		}
	}		
	
	return -1;
}

doPlayerPoints(clientteam,points) 
{
	self endon("disconnect");

	if(isDefined(self.pers["score"])) 	
	{
		self.pers["score"] = self.pers["score"] + points;		
		
		if(isDefined(self.score)) self.score = self.pers["score"];
	}
	else 
	{
		self.score 	= self.score + points;
	}

	level notify("update_teamscore_hud");
	level notify("update_allhud_score");
}

/*
USAGE OF "cvardef"
cvardef replaces the multiple lines of code used repeatedly in the setup areas of the script.
The function requires 5 parameters, and returns the set value of the specified cvar
Parameters:
	varname - The name of the variable, i.e. "scr_teambalance", or "scr_dem_respawn"
		This function will automatically find map-sensitive overrides, i.e. "src_dem_respawn_mp_brecourt"

	vardefault - The default value for the variable.  
		Numbers do not require quotes, but strings do.  i.e.   10, "10", or "wave"

	min - The minimum value if the variable is an "int" or "float" type
		If there is no minimum, use "" as the parameter in the function call

	max - The maximum value if the variable is an "int" or "float" type
		If there is no maximum, use "" as the parameter in the function call

	type - The type of data to be contained in the vairable.
		"int" - integer value: 1, 2, 3, etc.
		"float" - floating point value: 1.0, 2.5, 10.384, etc.
		"string" - a character string: "wave", "player", "none", etc.
*/
cvardef(varname, vardefault, min, max, type)
{
	mapname = getcvar("mapname");		// "mp_dawnville", "mp_rocket", etc.
	
	if (IsModAWE () && (isdefined (level.awe_gametype)))
		gametype = level.awe_gametype;	// "tdm", "bel", etc.
	else
		gametype = getcvar("g_gametype");

	tempvar = varname + "_" + gametype;	// i.e., scr_teambalance becomes scr_teambalance_tdm
	if(getcvar(tempvar) != "") 		// if the gametype override is being used
		varname = tempvar; 		// use the gametype override instead of the standard variable

	tempvar = varname + "_" + mapname;	// i.e., scr_teambalance becomes scr_teambalance_mp_dawnville
	if(getcvar(tempvar) != "")		// if the map override is being used
		varname = tempvar;		// use the map override instead of the standard variable


	// get the variable's definition
	switch(type)
	{
		case "int":
			if(getcvar(varname) == "")		// if the cvar is blank
				definition = vardefault;	// set the default
			else
				definition = getcvarint(varname);
			break;
		case "float":
			if(getcvar(varname) == "")	// if the cvar is blank
				definition = vardefault;	// set the default
			else
				definition = getcvarfloat(varname);
			break;
		case "string":
		default:
			if(getcvar(varname) == "")		// if the cvar is blank
				definition = vardefault;	// set the default
			else
				definition = getcvar(varname);
			break;
	}

	// if it's a number, with a minimum, that violates the parameter
	if((type == "int" || type == "float") && definition < min)
		definition = min;

	// if it's a number, with a maximum, that violates the parameter
	if((type == "int" || type == "float") && definition > max)
		definition = max;

	return definition;
}

IsModAWE ()
{
	return (isdefined (level.awe_disable) && (! level.awe_disable));
}

IsLinuxServer ()
{
	if (! isdefined (level.IsLinuxServer))
	{
		version = getcvar ("version");
		endstr = "";
		for (i = 0; i < 7; i ++)
			endstr += version[i + version.size - 7];
		level.IsLinuxServer = (endstr != "win-x86");
	}
	
	return (level.IsLinuxServer);
}

IsAwayFromFlags (mindist)
{
	for (i = 0; i < level.flags.size; i ++)
		if (distance (self.origin, level.flags[i].origin) < mindist)
			return false;
	
	return true;
}

EnemyTeam (team)
{
	if (team == "allies")
		return ("axis");
	return ("allies");
}

check_teams_exist() 
{
	players = getentarray("player", "classname");
	
	alliesexist = false;
	axisexist = false;
	
	for(i = 0; i < players.size; i++) 
	{
		if(!isdefined(players[i].pers["team"]) || players[i].pers["team"] == "spectator") 
			continue;
		
		if(players[i].pers["team"] == "allies")		
			alliesexist = true;
		else if(players[i].pers["team"] == "axis")	
			axisexist = true;

		if(alliesexist && axisexist) return true;
	}
	
	return false;
}

/*
awardTeamPoints() 
{

	if(level.team_obj_points) 
	{
		teamPoints = getcvarint("scr_dom_team_objective_points");//level.team_obj_points;
	
		teamscore = getTeamScore(self.pers["team"]);
		teamscore += teamPoints;
		setTeamScore(self.pers["team"], teamscore);
		
		level notify("update_allhud_score");
	}
}*/

showWaiting()
{
	if   (!level.roundstarted)
	{
		if(!isdefined(level.waitmsg))
		{
			level.waitmsg = newHudElem();
			level.waitmsg.archived = false;
			level.waitmsg.x = 320;
			level.waitmsg.y = 80;
			level.waitmsg.alignX = "center";
			level.waitmsg.alignY = "middle";
			level.waitmsg.fontScale = 2;
			level.waitmsg setText(&"DOM_WAITING_FOR_PLAYERS");
		}
		else
		{
			level.waitmsg setText(&"DOM_WAITING_FOR_PLAYERS");
		}

		if(isdefined(level.warmupcountdown))
			level.warmupcountdown destroy();
	}
}

CheckTeams()
{
	// Kill dupes
	self notify("checkforteams");
	self endon("checkforteams");

	wait 0;	// Required for Callback_PlayerDisconnect to complete before updateCheckTeams execute

	debug = getCvarint("scr_debug_ctf");

	players_on_allies = 0;
	players_on_axis = 0;

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		
		player = players[i];
		
		if(isDefined(player.pers["team"]))
			switch(player.pers["team"])
			{
				case "allies":
				{
					players_on_allies++;
					break;
				}
				case "axis":
				{
					players_on_axis++;
					break;
				}
			}
				
		// if we are in debug mode and we have found one person on a team then we are good
		if ( debug && (players_on_allies || players_on_axis) )
		{
			players_on_allies = 1;
			players_on_axis = 1;
			break;
		}			
		
		// if there is at least one player on each team then we are good.
		if (players_on_allies && players_on_axis )
		{
			break;
		}
	}
		
	// if one of these is zero then we only have one team
	if ( !players_on_allies || !players_on_axis )
	{
		if(level.roundstarted)
		{
			//abort round
			level.roundstarted=false;
			announcement(&"MP_THE_GAME_IS_A_TIE");
			level thread playSoundOnPlayers("MP_announcer_round_draw");
			setTeamScore("axis", 0);
			setTeamScore("allies", 0);
			level notify("update_allhud_score");
			game["state"] = "waiting";
			thread showWaiting();
		}
		else if(game["state"] == "warmup")
		{
			//abort start
			level notify("abort_startround");
			game["state"] = "waiting";
			thread showWaiting();
		}
	}
	else
	//teams are good to play
	{
		//start the round if not started or starting
		if(!level.roundstarted && game["state"] == "waiting")
			thread dowarmup();
	}
}

doWarmup()
{
	level endon("abort_startround");

	level.roundstarted=false;
	game["state"] = "warmup";


	if(isdefined(level.waitmsg))
		level.waitmsg setText(&"DOM_MATCH_STARTING");

	time = level.warmuptime;
	

	level.warmupcountdown = newHudElem();
	level.warmupcountdown.archived = false;
	level.warmupcountdown.x = 320;
	level.warmupcountdown.y = 100;
	level.warmupcountdown.alignX = "center";
	level.warmupcountdown.alignY = "middle";
	level.warmupcountdown.fontScale = 2;

	while (time)
	{	
		level.warmupcountdown setTimer(time );
		wait 1;
		time--;
	}	
	
	game["state"] = "playing";

	if(isdefined(level.waitmsg))
		level.waitmsg destroy();

	if(isdefined(level.warmupcountdown))
		level.warmupcountdown destroy();

	level notify("cleanup match starting");

	map_restart(true);
}

startRound()
{
	//don't start unless the match has started
	if(game["state"] != "playing")
		return;

	level.roundstarted=true;

		
	level.roundclock = newHudElem();
	level.roundclock.alignx = "left";
	level.roundclock.aligny = "top";
	level.roundclock.x = 8;
	level.roundclock.y = 2;
	level.roundclock.font = "default";
	level.roundclock.fontscale = 2;
	level.roundclock setTimer(level.roundlength * 60);

  currentround = game["roundsplayed"]+1;
	level.roundnumber = newHudElem();
	level.roundnumber.alignx = "left";
	level.roundnumber.aligny = "top";
	level.roundnumber.x = 8;
	level.roundnumber.y = 75;
	level.roundnumber.font = "default";
	level.roundnumber.fontscale = 2;
	level.roundnumber setValue(currentround);
	level.roundnumber.color = (1, 1, 0);
	
	offset = 0;
	if(currentround >= 10)
		offset += 12;
	level.roundslash = newHudElem();
	level.roundslash.alignx = "left";
	level.roundslash.aligny = "top";
	level.roundslash.x = 22 + offset ;
	level.roundslash.y = 77;
	level.roundslash.font = "default";
	level.roundslash.fontscale = 2;
	level.roundslash setText(&"MP_SLASH");
	level.roundslash.color = (1, 1, 1);
	
	roundlimit = level.roundlimit;
	level.roundmax = newHudElem();
	level.roundmax.alignx = "left";
	level.roundmax.aligny = "top";
	level.roundmax.x = 34 + offset;
	level.roundmax.y = 75;
	level.roundmax.font = "default";
	level.roundmax.fontscale = 2;
	level.roundmax setValue(roundlimit);
	level.roundmax.color = (0, 1, 0);
	
	if(isdefined(level.roundstarted))
	{
		level.roundclock.color = (.98, .827, .58);

		if((level.roundlength * 60) > level.graceperiod)
		{
			wait level.graceperiod;

			level notify("round_started");
			level.roundstarted = true;
			level.roundclock.color = (1, 1, 1);

			// Players on a team but without a weapon show as dead since they can not get in this round
			players = getentarray("player", "classname");
			for(i = 0; i < players.size; i++)
			{
				player = players[i];

				if(player.sessionteam != "spectator" && !isdefined(player.pers["weapon"]))
					player.statusicon = "hud_status_dead";
			}

			wait((level.roundlength * 60) - level.graceperiod);
		}
		else
			wait(level.roundlength * 60);
	}
	else
	{
		level.roundclock.color = (1, 1, 1);
		wait(level.roundlength * 60);
	}

	if(level.roundended)
		return;

	iprintln(&"MP_TIMEHASEXPIRED");
	level thread endMap();

}

//Added by 0ddball.

getSpawnTypeAllies(spawntype)
{
	switch(spawntype)
	{
		case "dm" :
		  spawntype_allies = "mp_dm_spawn";
			break;
		case "tdm" : 
			spawntype_allies = "mp_tdm_spawn";
			break;
		case "sd" :
			spawntype_allies = "mp_sd_spawn_attacker";
			break;
		case "ctf":
			spawntype_allies = "mp_ctf_spawn_allied";
			break;
		default:
			spawntype_allies = "mp_dm_spawn";
		break;
	}
	return spawntype_allies;
}

getSpawnTypeAxis(spawntype)
{
	switch(spawntype)
	{
		case "dm" :
		  spawntype_axis = "mp_dm_spawn";
			break;
		case "tdm" : 
			spawntype_axis = "mp_tdm_spawn";
			break;
		case "sd" :
			spawntype_axis = "mp_sd_spawn_defender";
			break;
		case "ctf":
			spawntype_axis = "mp_ctf_spawn_axis";
			break;
		default:
			spawntype_axis = "mp_dm_spawn";
		break;
	}
  return spawntype_axis;
}

isSpawnTypeCorrect(spawntype)
{
  switch(spawntype)
	{
		case "dm" :
		case "tdm" : 
		case "sd" :
		case "ctf":
			res = true;
			break;
		default:
			res=false;;
		break;
	}
  return res;
}

setSpawnPoints(spawntype)
{
	
	spawnpoints = getentarray(spawntype, "classname");
			if(!spawnpoints.size)
	    {
		    maps\mp\gametypes\_callbacksetup::AbortLevel();
		    return;
	    }
	    
	    for(i = 0; i < spawnpoints.size; i++)
		
	spawnpoints[i] placeSpawnpoint();
	
	return spawnpoints;
		
}	 

changeLevelHudElementShaderByName(hud_element_name, shader, shader_width, shader_height) 
{
	if(isDefined(level.hud) && level.hud.size > 0) 
	{
	
		for(i=0;i<level.hud.size;i++) 
		{
			if(isDefined(level.hud[i].name) && level.hud[i].name == hud_element_name) 
			{
 				if(isDefined(level.hud[i])) level.hud[i] setShader(shader, shader_width, shader_height);
				
				break;
			}
		}	
	}
}

//Delete all the icons in top HUD

deleteLevelHudElements() 
{

	// * HUD-Elemente entfernen *
	if(isDefined(level.hud) && level.hud.size > 0) 
	{
	
		for(i=0;i<level.hud.size;i++) 
		{
			if(isDefined(level.hud[i].name) ) 
			{
				level.hud[i] destroy();
				level.hud[i].name = undefined;
			}
		}
 }
}

iprintlnFIXED (locstring, player, target)
{
	if (IsLinuxServer ())
	{
		if (isdefined (target))
			target iprintln (locstring, player.name);
		else
			iprintln (locstring, player.name);
	}
	else
	{
		if (isdefined (target))
			target iprintln (locstring, player);
		else
			iprintln (locstring, player);
	}
}

isEven( number)
{
	return ( int( number / 2 ) * 2 == number);
}

//Delete all the Static Flags

deleteFlags()
{
	for (i = 0; i < level.flags.size; i ++) 
	  {
		  if (isDefined(level.flags[i].flagmodel)) level.flags[i].flagmodel delete();
    	 
	    if (isDefined(level.flags[i].basemodel)) level.flags[i].basemodel delete();
	  
	    level.flags[i] deleteFlagWaypoint();
	  }
}

//###################################################
//Functions added to manage the "DOMination" Gametype.
//###################################################

//Function :Test if the end of round condition is reached

DOM_checkAllObjectivesTaken() 
{
	flags = level.flags;
	
	team = flags[0].team;

	if(!isDefined(team)) return false;
	if(team != "axis" && team != "allies") return false;

	if (level.flagscaptured[team] == flags.size)
		return true;
	
	return false;
}

//flag Method: Tell if a Player can capture a Flag

DOM_CanCapture(player,team)
{
	return (level.roundstarted && !(level.roundended) && isdefined(player) && isalive(player) && (player.sessionstate == "playing") && (distance(player.origin, self.origin) < level.flag_radius) && ( checkOtherPlayerInRange(player.clientid, self.origin, EnemyTeam (team), level.flag_radius) == -1 )); 
}

DOM_InitSpawnsAndFlagsOrders() 
{
	if (!isdefined(level.spawntype)||!(isSpawnTypeCorrect(level.spawntype)))
  {
  	level.spawntype = "dm";
  }
  
  //If there's no different allies and axis spawn, don't switch.
  
  if (level.spawntype == "dm" || level.spawntype == "tdm" )
     level.spawnsSwitched = 0;
  else if (isdefined(level.switchspawns) && (level.switchspawns == 1) && !isEven(game["roundsplayed"]) )
           level.spawnsSwitched = 1;
       else
           level.spawnsSwitched = 0;  
     
	if ( level.spawnsSwitched == 0)
   		{
   			level.spawn_allies = getSpawnTypeAllies(level.spawntype);
        level.spawn_axis = getSpawnTypeAxis(level.spawntype);  
      }
  else
      {
      	level.spawn_allies = getSpawnTypeAxis(level.spawntype);
        level.spawn_axis = getSpawnTypeAllies(level.spawntype);  
        DOM_SwitchFlags();
      }
}

// Function: Switch the flags.

DOM_SwitchFlags()
{
	//No use for Random Flags
	
   for (i=0; i < level.flags.size ; i++)
	  {
		  j = level.flags.size - 1 -i;
		
		  if (i >= j) return;
		
		  flag = level.flags[i];
		  level.flags[i] = level.flags[j];
		  level.flags[j] = flag ;
	  }
}

//Player Method: Sets a Capture progress Indicator (clock).

DOM_SetCaptureProgressIndicator()
{
	
	if (! isdefined (self.capturetimer))
	{
		self.capturetimer = newClientHudElem (self);
		self.capturetimer.x = 320;
		self.capturetimer.y = 390;
		self.capturetimer.alignX = "center";
		self.capturetimer.alignY = "middle";
		self.capturetimer setClock (level.flagcapturetime, level.flagcapturetime, "hudstopwatch", 60, 60);
	}
}

//Player Method: Destroy the Capture Progress Indicator.

DOM_DestroyCaptureProgressIndicator()
{
	if (isdefined (self.capturetimer))
		self.capturetimer destroy ();
}

//New .ini Format parser.

DOM_InitMapConfig ()
{
	level.flags = [];

	fname = cvardef ("scr_dom_mapsconfigfile", "mapsconfig.ini", "", "", "string");
	fdesc = OpenFile (fname, "read");
	
	if (fdesc == -1)
	{
		return (false);
	}

	currentmap = false;
	for ( ; ; )
	{
		elems = freadln (fdesc);
		
		if (elems == -1)
			break;
			
		if (elems == 0)
		{
			currentmap = false;
			continue;
		}
	
		line = "";
		for (pos = 0 ; pos < elems ; pos ++)
		{
			line = line + fgetarg (fdesc, pos);
			if (pos < elems - 1)
				line = line + ",";
		}

		if ((getsubstr (line, 0, 2) == "//") || (getsubstr (line, 0, 1) == "#"))
			continue;
		
		array = strtok (line, " ");

		kw = array[0];

		if (kw == getcvar ("mapname"))
		{
			currentmap = true;
			continue;
		}
		
		if (currentmap)			
			switch (kw)
			{
				case "spawntype" :
					level.spawntype = array[1];
					break;

				case "flag" :
					flagnumber = atoi (array[1]);
					origin_str = getsubstr (array[2], 1, array[2].size -1);
					angles_str = getsubstr (array[3], 1, array[3].size -1);
					origin_array = strtok (origin_str, ",");
					angles_array = strtok (angles_str, ",");
					origin = (atof (origin_array[0]), atof (origin_array[1]), atof (origin_array[2]));
					angles = (atof (angles_array[0]), atof (angles_array[1]), atof (angles_array[2]));
					level.flags[flagnumber] = spawn ("script_model", origin);
					level.flags[flagnumber].angles = angles;
					break;

				default :
					break;
			}
	}
	
	CloseFile (fdesc);
}

atof (str)
{
	if ((! isdefined (str)) || (! str.size))
		return (0);

	switch (str[0])
	{
		case "+" :
			sign = 1;
			offset = 1;
			break;
		case "-" :
			sign = -1;
			offset = 1;
			break;
		default :
			sign = 1;
			offset = 0;
			break;
	}

	str2 = getsubstr (str, offset);
	parts = strtok (str2, ".");	

	intpart = atoi (parts[0]);
	decpart = atoi (parts[1]);

	if (decpart < 0)
		return (0);

	if (decpart)
		for (i = 0; i < parts[1].size; i ++)
			decpart = decpart / 10;

	return ((intpart + decpart) * sign);
}

atoi (str)
{
	if ((! isdefined (str)) || (! str.size))
		return (0);

	ctoi = [];
	ctoi["0"] = 0;
	ctoi["1"] = 1;
	ctoi["2"] = 2;
	ctoi["3"] = 3;
	ctoi["4"] = 4;
	ctoi["5"] = 5;
	ctoi["6"] = 6;
	ctoi["7"] = 7;
	ctoi["8"] = 8;
	ctoi["9"] = 9;
	
	switch (str[0])
	{
		case "+" :
			sign = 1;
			offset = 1;
			break;
		case "-" :
			sign = -1;
			offset = 1;
			break;
		default :
			sign = 1;
			offset = 0;
			break;
	}

	val = 0;
	
	for (i = offset; i < str.size; i ++)
	{
		switch (str[i])
		{
			case "0" :
			case "1" :
			case "2" :
			case "3" :
			case "4" :
			case "5" :
			case "6" :
			case "7" :
			case "8" :
			case "9" :
				val = val * 10 + ctoi[str[i]];
				break;
			default :
				return (0);
		}
	}
	
	return (val * sign);	
}

DOM_SetRoundWinners()
{
	if (!DOM_checkAllObjectivesTaken() && (level.mostflagswins == 1))
	{
		allies_flags = level.flagscaptured["allies"];
		axis_flags = level.flagscaptured["axis"];
		
				   
	  if ( allies_flags > axis_flags ) level.winning_team = "allies" ;
	  else if ( axis_flags > allies_flags ) level.winning_team = "axis" ;
	 }
}

storeServerInfoDvar (dvar)
{
	if (! isdefined (game["serverinfodvar"]))
		game["serverinfodvar"] = [];

	game["serverinfodvar"][game["serverinfodvar"].size] = dvar;
}

setServerInfoDvars ()
{
	self endon ("disconnect");

	for (i= 0; i < game["serverinfodvar"].size; i ++)
	{
		dvar = game["serverinfodvar"][i];
		val = getCvar (dvar);
		self setClientCvar (dvar, val);
		wait 0.05;
	}
}