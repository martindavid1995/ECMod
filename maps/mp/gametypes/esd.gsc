// Modified by La Truffe

// -- Gametype modified by Number7 -- (www.aigaming.net)

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
	// Number7
	if (getCvar("scr_debug_esd") == "")
		setCvar("scr_debug_esd", 0);

	level.splitscreen = isSplitScreen();

	// if this is a fresh map start, set nationalities based on cvars, otherwise leave game variable nationalities as set in the level script
	if(!isdefined(game["gamestarted"]))
	{
		// defaults if not defined in level script
		if(!isdefined(game["allies"]))
			game["allies"] = "american";
		if(!isdefined(game["axis"]))
			game["axis"] = "german";
		if(!isdefined(game["attackers"]))
			game["attackers"] = "allies";
		if(!isdefined(game["defenders"]))
			game["defenders"] = "axis";

		// server cvar overrides
		if(getCvar("scr_allies") != "")
			game["allies"] = getCvar("scr_allies");
		if(getCvar("scr_axis") != "")
			game["axis"] = getCvar("scr_axis");

		precacheStatusIcon("hud_status_dead");
		precacheStatusIcon("hud_status_connecting");
		precacheRumble("damage_heavy");
		precacheShader("white");
		precacheShader("plantbomb");
		precacheShader("defusebomb");
		precacheShader("objective");
		precacheShader("objectiveA");
		precacheShader("objectiveB");
		precacheShader("bombplanted");
		precacheShader("objpoint_bomb");
		precacheShader("objpoint_A");
		precacheShader("objpoint_B");
		precacheShader("objpoint_star");
		precacheShader("hudStopwatch");
		precacheShader("hudstopwatchneedle");
		precacheString(&"MP_MATCHSTARTING");
		precacheString(&"MP_MATCHRESUMING");
		precacheString(&"MP_EXPLOSIVESPLANTED");
		precacheString(&"MP_EXPLOSIVESDEFUSED");
		precacheString(&"MP_ROUNDDRAW");
		precacheString(&"MP_TIMEHASEXPIRED");
		precacheString(&"MP_ALLIEDMISSIONACCOMPLISHED");
		precacheString(&"MP_AXISMISSIONACCOMPLISHED");
		precacheString(&"MP_ALLIESHAVEBEENELIMINATED");
		precacheString(&"MP_AXISHAVEBEENELIMINATED");
		precacheString(&"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES");
		precacheString(&"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES");
		precacheString (&"MP_TIME_TILL_SPAWN");
		precacheString (&"PLATFORM_PRESS_TO_SPAWN");
		precacheModel("xmodel/mp_tntbomb");
		precacheModel("xmodel/mp_tntbomb_obj");

		//thread maps\mp\gametypes\_teams::addTestClients();
	}

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

	game["gamestarted"] = true;

	setClientNameMode("manual_change");

	spawnpointname = "mp_sd_spawn_attacker";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	spawnpointname = "mp_sd_spawn_defender";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] PlaceSpawnpoint();

	level._effect["bombexplosion"] = loadfx("fx/props/barrelexp.efx");

	allowed[0] = "sd";
	allowed[1] = "bombzone";
	allowed[2] = "blocker";
	maps\mp\gametypes\_gameobjects::main(allowed);

	// Time limit per map
	level.timelimit = cvardef ("scr_esd_timelimit", 0, 0, 1440, "float");
	setCvar("ui_timelimit", level.timelimit);
	makeCvarServerInfo("ui_timelimit", "0");

	if(!isdefined(game["timepassed"]))
		game["timepassed"] = 0;

	// Score limit per map
	level.scorelimit = cvardef ("scr_esd_scorelimit", 10, 0, 9999, "int");
	setCvar("ui_scorelimit", level.scorelimit);
	makeCvarServerInfo("ui_scorelimit", "10");

	// Round limit per map
	level.roundlimit = cvardef ("scr_esd_roundlimit", 0, 0, 999, "int");
	setCvar("ui_roundlimit", level.roundlimit);
	makeCvarServerInfo("ui_roundlimit", "0");

	// Time at round start where spawning and weapon choosing is still allowed
	level.graceperiod = cvardef ("scr_esd_graceperiod", 15, 0, 60, "float");

	// Time length of each round
	level.roundlength = cvardef ("scr_esd_roundlength", 4, level.graceperiod / 60, 1440, "float");
  setCvar ("ui_roundlength", level.roundlength);
	makeCvarServerInfo ("ui_roundlength", "4");

	// Sets the time it takes for a planted bomb to explode
	level.bombtimer = cvardef ("scr_esd_bombtimer", 60, 30, 120, "int");
	setCvar ("ui_esd_bombtimer", level.bombtimer);
	storeServerInfoDvar ("ui_esd_bombtimer");

	// Auto Team Balancing
	level.teambalance = cvardef ("scr_teambalance", 0, 0, 1, "int");
	level.lockteams = false;

	// Draws a team icon over teammates
	level.drawfriend = cvardef ("scr_drawfriend", 1, 0, 1, "int");

	level.plantscore = cvardef ("scr_esd_plantscore", 0, 0, 99, "int");
	setCvar ("ui_esd_plantscore", level.plantscore);
	storeServerInfoDvar ("ui_esd_plantscore");

	level.defusescore = cvardef ("scr_esd_defusescore", 0, 0, 99, "int");
	setCvar ("ui_esd_defusescore", level.defusescore);
	storeServerInfoDvar ("ui_esd_defusescore");

	level.defendscore = cvardef ("scr_esd_defendscore", 0, 0, 99, "int");
	setCvar ("ui_esd_defendscore", level.defendscore);
	storeServerInfoDvar ("ui_esd_defendscore");

	level.planttime = cvardef ("scr_esd_planttime", 5, 0, 60, "int");
	setCvar ("ui_esd_planttime", level.planttime);
	storeServerInfoDvar ("ui_esd_planttime");

	level.defusetime = cvardef ("scr_esd_defusetime", 10, 0, 60, "int");
	setCvar ("ui_esd_defusetime", level.defusetime);
	storeServerInfoDvar ("ui_esd_defusetime");

	// Swap teams
	game["swapTeams"]	= cvardef ("scr_esd_swap_teams", 0, 0, 99, "int");

	// Ability to respawn
	level.respawn = cvardef ("scr_esd_respawn", 0, 0, 1, "int");
	setCvar ("ui_esd_respawn", level.respawn);
	storeServerInfoDvar ("ui_esd_respawn");

	// Respawn delay
	level.respawndelay = cvardef ("scr_esd_respawndelay", 10, 0, 600, "int");
	setCvar ("ui_esd_respawndelay", level.respawndelay);
	storeServerInfoDvar ("ui_esd_respawndelay");

	// End round when dead team
	level.endround_deadteam = cvardef ("scr_esd_endround_deadteam", 1, 0, 1, "int");
	setCvar ("ui_esd_endround_deadteam", level.endround_deadteam);
	storeServerInfoDvar ("ui_esd_endround_deadteam");

	// ESD mode	
	level.esd_mode = cvardef ("scr_esd_mode", 0, 0, 4, "int");
	setCvar ("ui_esd_mode", level.esd_mode);
	storeServerInfoDvar ("ui_esd_mode");

	level.defuseback = (level.esd_mode == 3) || (level.esd_mode == 4);
	
	// Force respawning
	level.forcerespawn = cvardef ("scr_forcerespawn", 0, 0, 1, "int");

	if(!isdefined(game["state"]))
		game["state"] = "playing";
	if(!isdefined(game["roundsplayed"]))
		game["roundsplayed"] = 0;
	if(!isdefined(game["matchstarted"]))
		game["matchstarted"] = false;

	if(!isdefined(game["alliedscore"]))
		game["alliedscore"] = 0;
	setTeamScore("allies", game["alliedscore"]);

	if(!isdefined(game["axisscore"]))
		game["axisscore"] = 0;
	setTeamScore("axis", game["axisscore"]);

	level.lastbombplanted = false;
	
	level.bombplanted[0] = false;
	level.bombplanted[1] = false;
	level.bombexploded[0] = false;
	level.bombexploded[1] = false;
	level.bombdefused[0] = false;
	level.bombdefused[1] = false;

	level.roundstarted = false;
	level.roundended = false;
	level.mapended = false;
	level.bombmode = 0;

	level.exist["allies"] = 0;
	level.exist["axis"] = 0;
	level.exist["teams"] = false;
	level.didexist["allies"] = false;
	level.didexist["axis"] = false;

	thread bombzones();
	thread startGame();
	thread updateGametypeCvars();
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

	if(!isdefined(self.pers["team"]) && !level.splitscreen)
		iprintlnFIXED (&"MP_CONNECTED", self);

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("J;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");

	self thread setServerInfoDvars ();

	if(game["state"] == "intermission")
	{
		spawnIntermission();
		return;
	}

	level endon("intermission");

	if (! isdefined (self.bombtimer))
		self.bombtimer = [];
	
	if(level.splitscreen)
	{
		if(isdefined(self.pers["weapon"]))
			scriptMainMenu = game["menu_ingame_onteam"];
		else
			scriptMainMenu = game["menu_ingame_spectator"];
	}
	else
		scriptMainMenu = game["menu_ingame"];

	if(isdefined(self.pers["team"]) && self.pers["team"] != "spectator")
	{
		self setClientCvar("ui_allow_weaponchange", "1");

		if(isdefined(self.pers["weapon"]))
			spawnPlayer();
		else
		{
			self.sessionteam = "spectator";

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
		iprintlnFIXED (&"MP_DISCONNECTED", self);

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
	lpselfguid = self getGuid();
	logPrint("Q;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");

	if(game["matchstarted"])
		level thread updateTeamStatus();
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(self.sessionteam == "spectator")
		return;

	// Don't do knockback if the damage direction was not specified
	if(!isdefined(vDir))
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

				// Shellshock/Rumble
				self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				self playrumble("damage_heavy");

				friendly = true;
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
		lpselfguid = self getGuid();
		lpselfname = self.name;
		lpselfteam = self.pers["team"];
		lpattackerteam = "";

		if(isPlayer(eAttacker))
		{
			lpattacknum = eAttacker getEntityNumber();
			lpattackguid = eAttacker getGuid();
			lpattackname = eAttacker.name;
			lpattackerteam = eAttacker.pers["team"];
		}
		else
		{
			lpattacknum = -1;
			lpattackguid = "";
			lpattackname = "";
			lpattackerteam = "world";
		}

		if(isdefined(friendly))
		{
			lpattacknum = lpselfnum;
			lpattackname = lpselfname;
			lpattackguid = lpselfguid;
		}

		logPrint("D;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
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

	if(!isdefined(self.switching_teams))
	{
		self.pers["deaths"]++;
		self.deaths = self.pers["deaths"];
	}

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	lpselfname = self.name;
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

			if(self.pers["team"] == attacker.pers["team"]) // killed by a friendly
			{
				attacker.pers["score"]--;
				attacker.score = attacker.pers["score"];
			}
			else
			{
				// Number7

				attacker.pers["score"]++;

				// if the dead person was close to the objective then give the killer a defense bonus
				if (self is_near_obj(attacker))
				{
					// let everyone know
					if (attacker.pers["team"] == game["defenders"])
						iprintlnFIXED (&"ESD_DEFENDED_OBJECTIVE", attacker);
					else
					{
						if (attacker.pers["team"] == "allies")
							iprintlnFIXED (&"ESD_DEFENDED_ALLIES", attacker);
						else
							iprintlnFIXED (&"ESD_DEFENDED_AXIS", attacker);
					}
					
					attacker.pers["score"] += level.defendscore;

					lpattacknum = attacker getEntityNumber();
					lpattackguid = attacker getGuid();
					logPrint("A;" + lpattackguid + ";" + lpattacknum + ";" + attacker.pers["team"] + ";" + attacker.name + ";" + "sd_defend" + "\n");
				}

				attacker.score = attacker.pers["score"];
			}
		}

		lpattacknum = attacker getEntityNumber();
		lpattackguid = attacker getGuid();
		lpattackname = attacker.name;
		lpattackerteam = attacker.pers["team"];

		self notify("killed_player", attacker);
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		doKillcam = false;

		self.pers["score"]--;
		self.score = self.pers["score"];

		lpattacknum = -1;
		lpattackguid = "";
		lpattackname = "";
		lpattackerteam = "world";

		self notify("killed_player", self);
	}

	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

	self.pers["weapon1"] = undefined;
	self.pers["weapon2"] = undefined;
	self.pers["spawnweapon"] = undefined;

	if (isdefined (self.bombtimer[0]))
		self.bombtimer[0] destroy ();
	if (isdefined (self.bombtimer[1]))
		self.bombtimer[1] destroy ();

	if ((! isdefined (self.switching_teams)) || level.respawn)
	{
		body = self cloneplayer(deathAnimDuration);
		thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"], 5);
	}
	self.switching_teams = undefined;
	self.joining_team = undefined;
	self.leaving_team = undefined;

	level updateTeamStatus();

	if (((! level.respawn) || level.endround_deadteam) && (!level.exist[self.pers["team"]])) // If the last player on a team was just killed, don't do killcam
	{
		doKillcam = false;
		self.skip_setspectatepermissions = true;

		if(level.lastbombplanted && level.planting_team == self.pers["team"])
		{
			players = getentarray("player", "classname");
			for(i = 0; i < players.size; i++)
			{
				player = players[i];

				if(player.pers["team"] == self.pers["team"])
				{
					player allowSpectateTeam("allies", true);
					player allowSpectateTeam("axis", true);
					player allowSpectateTeam("freelook", true);
					player allowSpectateTeam("none", false);
				}
			}
		}
	}

	delay = 2;	// Delay the player becoming a spectator till after he's done dying

	if (level.respawn)
		self thread respawn_timer (delay);

	wait delay;	// ?? Also required for Callback_PlayerKilled to complete before respawn/killcam can execute

	if(doKillcam && level.killcam && !level.roundended)
		self maps\mp\gametypes\_killcam::killcam(attackerNum, delay, psOffsetTime);

	if (level.respawn)
	{
		self.spawned = undefined;
		self thread respawn ();
	}
	else
	{
		currentorigin = self.origin;
		currentangles = self.angles;
		self thread spawnSpectator (currentorigin + (0, 0, 60), currentangles);
	}
}

// Number7
is_near_obj(attacker)
{
	// Attackers are defending their bomb..

	if (level.bombplanted[0] && (! level.bombdefused[0]) && (! level.bombexploded[0]) && (attacker.pers["team"] == game["attackers"]) && isdefined (level.bombmodel[0]))
	{
		dist = distance(level.bombmodel[0].origin, self.origin);
		if (dist < 350)	return true;
	}
	if (level.bombplanted[1] && (! level.bombdefused[1]) && (! level.bombexploded[1]) && (attacker.pers["team"] == game["attackers"]) && isdefined (level.bombmodel[1]))
	{
		dist = distance(level.bombmodel[1].origin, self.origin);
		if (dist < 350)	return true;
	}

	// Defenders are preventing bomb plant..

	if (!level.bombplanted[0] && attacker.pers["team"] == game["defenders"])
	{
		dist = distance(level.sdObjective[0], self.origin);
		if (dist < 350)	return true;
	}
	if (!level.bombplanted[1] && attacker.pers["team"] == game["defenders"])
	{
		dist = distance(level.sdObjective[1], self.origin);
		if (dist < 350)	return true;
	}

	return false;
}

spawnPlayer()
{
	self endon("disconnect");
	self notify("spawned");
	
	if (level.respawn)
		self notify ("end_respawn");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	if(isdefined(self.spawned))
		return;

	self.sessionteam = self.pers["team"];
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.statusicon = "";
	self.maxhealth = 100;
	self.health = self.maxhealth;
	self.friendlydamage = undefined;
	self.spawned = true;

	if(self.pers["team"] == "allies")
		spawnpointname = "mp_sd_spawn_attacker";
	else
		spawnpointname = "mp_sd_spawn_defender";

	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

	if(isdefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");

	level updateTeamStatus();

	if(!isdefined(self.pers["score"]))
		self.pers["score"] = 0;
	self.score = self.pers["score"];

	if(!isdefined(self.pers["deaths"]))
		self.pers["deaths"] = 0;
	self.deaths = self.pers["deaths"];

	if(!isdefined(self.pers["savedmodel"]))
		maps\mp\gametypes\_teams::model();
	else
		maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	if(isdefined(self.pers["weapon1"]) && isdefined(self.pers["weapon2"]))
	{
	 	self setWeaponSlotWeapon("primary", self.pers["weapon1"]);
		self setWeaponSlotAmmo("primary", 999);
		self setWeaponSlotClipAmmo("primary", 999);

	 	self setWeaponSlotWeapon("primaryb", self.pers["weapon2"]);
		self setWeaponSlotAmmo("primaryb", 999);
		self setWeaponSlotClipAmmo("primaryb", 999);

		self setSpawnWeapon(self.pers["spawnweapon"]);
	}
	else
	{
		self setWeaponSlotWeapon("primary", self.pers["weapon"]);
		self setWeaponSlotAmmo("primary", 999);
		self setWeaponSlotClipAmmo("primary", 999);

		self setSpawnWeapon(self.pers["weapon"]);
	}

	maps\mp\gametypes\_weapons::givePistol();
	maps\mp\gametypes\_weapons::giveGrenades();
	maps\mp\gametypes\_weapons::giveBinoculars();

	self.usedweapons = false;
	thread maps\mp\gametypes\_weapons::watchWeaponUsage();

	if (level.bombplanted[0] && (! level.bombdefused[0]) && (! level.bombexploded[0]))
		thread showPlayerBombTimer (0);
	if (level.bombplanted[1] && (! level.bombdefused[1]) && (! level.bombexploded[1]))
		thread showPlayerBombTimer (1);

	if(!level.splitscreen)
	{
		if(level.scorelimit > 0)
		{
			if(self.pers["team"] == game["attackers"])
				self setClientCvar("cg_objectiveText", &"MP_OBJ_ATTACKERS", level.scorelimit);
			else if(self.pers["team"] == game["defenders"])
				self setClientCvar("cg_objectiveText", &"MP_OBJ_DEFENDERS", level.scorelimit);
		}
		else
		{
			if(self.pers["team"] == game["attackers"])
				self setClientCvar("cg_objectiveText", &"MP_OBJ_ATTACKERS_NOSCORE");
			else if(self.pers["team"] == game["defenders"])
				self setClientCvar("cg_objectiveText", &"MP_OBJ_DEFENDERS_NOSCORE");
		}
	}
	else
	{
		if(self.pers["team"] == game["attackers"])
			self setClientCvar("cg_objectiveText", &"MP_DESTROY_THE_OBJECTIVE");
		else if(self.pers["team"] == game["defenders"])
			self setClientCvar("cg_objectiveText", &"MP_DEFEND_THE_OBJECTIVE");
	}

	waittillframeend;
	self notify("spawned_player");
}

spawnSpectator(origin, angles)
{
	self notify("spawned");
	
	if (level.respawn)
		self notify ("end_respawn");
		
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

	if(!isdefined(self.skip_setspectatepermissions))
		maps\mp\gametypes\_spectating::setSpectatePermissions();

	if(isdefined(origin) && isdefined(angles))
		self spawn(origin, angles);
	else
	{
 		spawnpointname = "mp_global_intermission";
		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

		if(isdefined(spawnpoint))
			self spawn(spawnpoint.origin, spawnpoint.angles);
		else
			maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	level updateTeamStatus();

	self.usedweapons = false;

	self setClientCvar("cg_objectiveText", "");
}

spawnIntermission()
{
	self notify("spawned");
	
	if (level.respawn)
		self notify ("end_respawn");
		
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

	if(isdefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
}

startGame()
{
	level.starttime = getTime();
	thread startRound();
}

startRound()
{
	if (! level.esd_mode)
		level endon ("bomb_planted");

	level endon("round_ended");

	// Number7
	if (!(game["swapTeams"] && game["roundsplayed"] == game["swapTeams"]))
		thread sayObjective();

	level.clock = newHudElem();
	level.clock.horzAlign = "left";
	level.clock.vertAlign = "top";
	level.clock.x = 8;
	level.clock.y = 2;
	level.clock.font = "default";
	level.clock.fontscale = 2;
	level.clock setTimer(level.roundlength * 60);

	if(game["matchstarted"])
	{
		level.clock.color = (.98, .827, .58);

		if((level.roundlength * 60) > level.graceperiod)
		{
			wait level.graceperiod;

			level notify("round_started");
			level.roundstarted = true;
			level.clock.color = (1, 1, 1);

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
		level.clock.color = (1, 1, 1);
		wait(level.roundlength * 60);
	}

	if(level.roundended)
		return;

	if(!level.exist[game["attackers"]] || !level.exist[game["defenders"]])
	{
		iprintln(&"MP_TIMEHASEXPIRED");
		level thread endRound("draw");
		return;
	}

	iprintln(&"MP_TIMEHASEXPIRED");
	level thread endRound(game["defenders"]);
}

checkMatchStart()
{
	oldvalue["teams"] = level.exist["teams"];
	level.exist["teams"] = false;

	// Number7
	// If teams currently exist
	if (getCvarInt("scr_debug_esd") != 1)
	{
		if(level.exist["allies"] && level.exist["axis"])
			level.exist["teams"] = true;
	}
	else
		level.exist["teams"] = true;

	// If teams previously did not exist and now they do
	if(!oldvalue["teams"] && level.exist["teams"])
	{
		if(!game["matchstarted"])
		{
			iprintln(&"MP_MATCHSTARTING");

			level notify("kill_endround");
			level.roundended = false;
			level thread endRound("reset");
		}
		else
		{
			iprintln(&"MP_MATCHRESUMING");

			level notify("kill_endround");
			level.roundended = false;
			level thread endRound("draw");
		}

		return;
	}
}

resetScores()
{
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		player.pers["score"] = 0;
		player.pers["deaths"] = 0;
	}

	game["alliedscore"] = 0;
	setTeamScore("allies", game["alliedscore"]);
	game["axisscore"] = 0;
	setTeamScore("axis", game["axisscore"]);
}

endRound(roundwinner)
{
	level endon("intermission");
	level endon("kill_endround");

	if(level.roundended)
		return;
	level.roundended = true;

	// End bombzone threads and remove related hud elements and objectives
	level notify("round_ended");
	level notify("update_allhud_score");

	if (level.esd_mode && isdefined (level.clock))
		level.clock destroy ();
	
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isdefined(player.progressbackground))
			player.progressbackground destroy();

		if(isdefined(player.progressbar))
			player.progressbar destroy();

		player unlink();
		player enableWeapon();
	}

	objective_delete(0);
	objective_delete(1);

	level thread announceWinner(roundwinner, 2);

	winners = "";
	losers = "";

	if(roundwinner == "allies")
	{
		game["alliedscore"]++;
		setTeamScore("allies", game["alliedscore"]);

		players = getentarray("player", "classname");
		for(i = 0; i < players.size; i++)
		{
			lpGuid = players[i] getGuid();
			if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == "allies"))
				winners = (winners + ";" + lpGuid + ";" + players[i].name);
			else if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == "axis"))
				losers = (losers + ";" + lpGuid + ";" + players[i].name);
		}
		logPrint("W;allies" + winners + "\n");
		logPrint("L;axis" + losers + "\n");
	}
	else if(roundwinner == "axis")
	{
		game["axisscore"]++;
		setTeamScore("axis", game["axisscore"]);

		players = getentarray("player", "classname");
		for(i = 0; i < players.size; i++)
		{
			lpGuid = players[i] getGuid();
			if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == "axis"))
				winners = (winners + ";" + lpGuid + ";" + players[i].name);
			else if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == "allies"))
				losers = (losers + ";" + lpGuid + ";" + players[i].name);
		}
		logPrint("W;axis" + winners + "\n");
		logPrint("L;allies" + losers + "\n");
	}

	// Number7
	wait 4;

	if(game["matchstarted"])
	{
		checkScoreLimit();
		game["roundsplayed"]++;
		checkRoundLimit();
	}

	if(!game["matchstarted"] && roundwinner == "reset")
	{
		game["matchstarted"] = true;
		thread resetScores();
		game["roundsplayed"] = 0;
	}

	game["timepassed"] = game["timepassed"] + ((getTime() - level.starttime) / 1000) / 60.0;

	checkTimeLimit();

	if(level.mapended)
		return;
	level.mapended = true;

	// Number7
	doWait = false;

	// Number7
	if (game["swapTeams"] && game["roundsplayed"] == game["swapTeams"])
	{
		doWait = true;

		iprintlnbold (&"ESD_SWAP_TEAMS");
		wait 4;
	}

	// Number7
	if (!doWait)
		wait 3;

	// for all living players store their weapons
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isdefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
		{
			weapon1 = player getWeaponSlotWeapon("primary");
			weapon2 = player getWeaponSlotWeapon("primaryb");
			current = player getCurrentWeapon();

			// A new weapon has been selected
			if(isdefined(player.oldweapon))
			{
				player.pers["weapon1"] = player.pers["weapon"];
				player.pers["weapon2"] = "none";
				player.pers["spawnweapon"] = player.pers["weapon1"];
			} // No new weapons selected
			else
			{
				if(!maps\mp\gametypes\_weapons::isMainWeapon(weapon1) && !maps\mp\gametypes\_weapons::isMainWeapon(weapon2))
				{
					player.pers["weapon1"] = player.pers["weapon"];
					player.pers["weapon2"] = "none";
				}
				else if(maps\mp\gametypes\_weapons::isMainWeapon(weapon1) && !maps\mp\gametypes\_weapons::isMainWeapon(weapon2))
				{
					player.pers["weapon1"] = weapon1;
					player.pers["weapon2"] = "none";
				}
				else if(!maps\mp\gametypes\_weapons::isMainWeapon(weapon1) && maps\mp\gametypes\_weapons::isMainWeapon(weapon2))
				{
					player.pers["weapon1"] = weapon2;
					player.pers["weapon2"] = "none";
				}
				else
				{
					assert(maps\mp\gametypes\_weapons::isMainWeapon(weapon1) && maps\mp\gametypes\_weapons::isMainWeapon(weapon2));

					if(current == weapon2)
					{
						player.pers["weapon1"] = weapon2;
						player.pers["weapon2"] = weapon1;
					}
					else
					{
						player.pers["weapon1"] = weapon1;
						player.pers["weapon2"] = weapon2;
					}
				}

				player.pers["spawnweapon"] = player.pers["weapon1"];
			}
		}
	}

	// Number7
	if (game["matchstarted"] && game["swapTeams"] && game["roundsplayed"] == game["swapTeams"])
		swapteams ();

	level notify("restarting");

	map_restart(true);
}

endMap()
{
//////// Added for AWE /////////
	awe\_global::EndMap();
////////////////////////////////

	game["state"] = "intermission";
	level notify("intermission");

	if(isdefined(level.bombmodel[0]))
		level.bombmodel[0] stopLoopSound();
	if(isdefined(level.bombmodel[1]))
		level.bombmodel[1] stopLoopSound();

	if(game["alliedscore"] == game["axisscore"])
		text = &"MP_THE_GAME_IS_A_TIE";
	else if(game["alliedscore"] > game["axisscore"])
		text = &"MP_ALLIES_WIN";
	else
		text = &"MP_AXIS_WIN";

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		player closeMenu();
		player closeInGameMenu();
		player setClientCvar("cg_objectiveText", text);

		player spawnIntermission();
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

	wait 15;
	exitLevel(false);
}

checkTimeLimit()
{
	if(level.timelimit <= 0)
		return;

	if(game["timepassed"] < level.timelimit)
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

	if(game["alliedscore"] < level.scorelimit && game["axisscore"] < level.scorelimit)
		return;

	if(level.mapended)
		return;
	level.mapended = true;

	if(!level.splitscreen)
		iprintln(&"MP_SCORE_LIMIT_REACHED");

	level thread endMap();
}

checkRoundLimit()
{
	if(level.roundlimit <= 0)
		return;

	if(game["roundsplayed"] < level.roundlimit)
		return;

	if(level.mapended)
		return;
	level.mapended = true;

	if(!level.splitscreen)
		iprintln(&"MP_ROUND_LIMIT_REACHED");

	level thread endMap();
}

updateGametypeCvars()
{
	for(;;)
	{
		timelimit = cvardef ("scr_esd_timelimit", 0, 0, 1440, "float");
		if(level.timelimit != timelimit)
		{
			level.timelimit = timelimit;
			setCvar("ui_timelimit", level.timelimit);
		}

		scorelimit = cvardef ("scr_esd_scorelimit", 10, 0, 9999, "int");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
			setCvar("ui_scorelimit", level.scorelimit);
			level notify("update_allhud_score");

			if(game["matchstarted"])
				checkScoreLimit();
		}

		roundlimit = cvardef ("scr_esd_roundlimit", 0, 0, 999, "int");
		if(level.roundlimit != roundlimit)
		{
			level.roundlimit = roundlimit;
			setCvar("ui_roundlimit", level.roundlimit);

			if(game["matchstarted"])
				checkRoundLimit();
		}

		wait 1;
	}
}

updateTeamStatus()
{
	wait 0;	// Required for Callback_PlayerDisconnect to complete before updateTeamStatus can execute

	resettimeout();

	oldvalue["allies"] = level.exist["allies"];
	oldvalue["axis"] = level.exist["axis"];
	level.exist["allies"] = 0;
	level.exist["axis"] = 0;

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isdefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
			level.exist[player.pers["team"]]++;
	}

	// Number7
	if (getCvarInt("scr_debug_esd") == 1)
		return;

	if(level.exist["allies"])
		level.didexist["allies"] = true;
	if(level.exist["axis"])
		level.didexist["axis"] = true;

	if(level.roundended)
		return;

	if (level.respawn && (! level.endround_deadteam))
		return;
		
	// if both allies and axis were alive and now they are both dead in the same instance
	if(oldvalue["allies"] && !level.exist["allies"] && oldvalue["axis"] && !level.exist["axis"])
	{
		if(level.lastbombplanted)
		{
			// if allies planted the bomb, allies win
			if(level.planting_team == "allies")
			{
				iprintln(&"MP_ALLIEDMISSIONACCOMPLISHED");
				level thread endRound("allies");
				return;
			}
			else // axis planted the bomb, axis win
			{
				assert(game["attackers"] == "axis");
				iprintln(&"MP_AXISMISSIONACCOMPLISHED");
				level thread endRound("axis");
				return;
			}
		}

		// if there is no bomb planted the round is a draw
		iprintln(&"MP_ROUNDDRAW");
		level thread endRound("draw");
		return;
	}

	// if allies were alive and now they are not
	if(oldvalue["allies"] && !level.exist["allies"])
	{
		// if allies planted the bomb, continue the round
		if(level.lastbombplanted && level.planting_team == "allies")
			return;

		iprintln(&"MP_ALLIESHAVEBEENELIMINATED");
		level thread playSoundOnPlayers("mp_announcer_allieselim");
		level thread endRound("axis");
		return;
	}

	// if axis were alive and now they are not
	if(oldvalue["axis"] && !level.exist["axis"])
	{
		// if axis planted the bomb, continue the round
		if(level.lastbombplanted && level.planting_team == "axis")
			return;

		iprintln(&"MP_AXISHAVEBEENELIMINATED");
		level thread playSoundOnPlayers("mp_announcer_axiselim");
		level thread endRound("allies");
		return;
	}
}

bombzones()
{
	// Number7
	level.sdObjective = [];

	maperrors = [];

	if(level.splitscreen)
		level.barsize = 152;
	else
		level.barsize = 192;

	wait .2;

	bombzones = getentarray("bombzone", "targetname");
	array = [];

	if(level.bombmode == 0)
	{
		for(i = 0; i < bombzones.size; i++)
		{
			bombzone = bombzones[i];

			if(isdefined(bombzone.script_bombmode_original) && isdefined(bombzone.script_label))
				array[array.size] = bombzone;
		}

		if(array.size == 2)
		{
			bombzone0 = array[0];
			bombzone1 = array[1];
			bombzoneA = undefined;
			bombzoneB = undefined;

			if(bombzone0.script_label == "A" || bombzone0.script_label == "a")
		 	{
		 		bombzoneA = bombzone0;
		 		bombzoneB = bombzone1;
		 	}
		 	else if(bombzone0.script_label == "B" || bombzone0.script_label == "b")
		 	{
		 		bombzoneA = bombzone1;
		 		bombzoneB = bombzone0;
		 	}
		 	else
		 		maperrors[maperrors.size] = "^1Bombmode original: Bombzone found with an invalid \"script_label\", must be \"A\" or \"B\"";

	 		objective_add(0, "current", bombzoneA.origin, "objectiveA");
	 		objective_add(1, "current", bombzoneB.origin, "objectiveB");
			thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzoneA.origin, "0", "allies", "objpoint_A");
			thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzoneB.origin, "1", "allies", "objpoint_B");
			thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzoneA.origin, "0", "axis", "objpoint_A");
			thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzoneB.origin, "1", "axis", "objpoint_B");

	 		bombzoneA thread bombzone_think(bombzoneB, 0);
			bombzoneB thread bombzone_think(bombzoneA, 1);
		}
		else if(array.size < 2)
			maperrors[maperrors.size] = "^1Bombmode original: Less than 2 bombzones found with \"script_bombmode_original\" \"1\"";
		else if(array.size > 2)
			maperrors[maperrors.size] = "^1Bombmode original: More than 2 bombzones found with \"script_bombmode_original\" \"1\"";
	}
	else if(level.bombmode == 1)
	{
		for(i = 0; i < bombzones.size; i++)
		{
			bombzone = bombzones[i];

			if(isdefined(bombzone.script_bombmode_single))
				array[array.size] = bombzone;
		}

		if(array.size == 1)
		{
	 		objective_add(0, "current", array[0].origin, "objective");
			thread maps\mp\gametypes\_objpoints::addTeamObjpoint(array[0].origin, "single", "allies", "objpoint_star");
			thread maps\mp\gametypes\_objpoints::addTeamObjpoint(array[0].origin, "single", "axis", "objpoint_star");

	 		array[0] thread bombzone_think();
		}
		else if(array.size < 1)
			maperrors[maperrors.size] = "^1Bombmode single: Less than 1 bombzone found with \"script_bombmode_single\" \"1\"";
		else if(array.size > 1)
			maperrors[maperrors.size] = "^1Bombmode single: More than 1 bombzone found with \"script_bombmode_single\" \"1\"";
	}
	else if(level.bombmode == 2)
	{
		for(i = 0; i < bombzones.size; i++)
		{
			bombzone = bombzones[i];

			if(isdefined(bombzone.script_bombmode_dual))
		 		array[array.size] = bombzone;
		}

		if(array.size == 2)
		{
	 		bombzone0 = array[0];
	 		bombzone1 = array[1];

	 		objective_add(0, "current", bombzone0.origin, "objective");
	 		objective_add(1, "current", bombzone1.origin, "objective");

	 		if(isdefined(bombzone0.script_team) && isdefined(bombzone1.script_team))
	 		{
	 			if((bombzone0.script_team == "allies" && bombzone1.script_team == "axis") || (bombzone0.script_team == "axis" || bombzone1.script_team == "allies"))
	 			{
	 				objective_team(0, bombzone0.script_team);
	 				objective_team(1, bombzone1.script_team);

					if(bombzone0.script_team == "allies")
					{
						thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzone0.origin, "0", "allies", "objpoint_star");
						thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzone1.origin, "1", "axis", "objpoint_star");
					}
					else
					{
						thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzone0.origin, "0", "axis", "objpoint_star");
						thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzone1.origin, "1", "allies", "objpoint_star");
					}
	 			}
	 			else
	 				maperrors[maperrors.size] = "^1Bombmode dual: One or more bombzones missing \"script_team\" \"allies\" or \"axis\"";
	 		}

	 		bombzone0 thread bombzone_think(bombzone1);
	 		bombzone1 thread bombzone_think(bombzone0);
		}
		else if(array.size < 2)
			maperrors[maperrors.size] = "^1Bombmode dual: Less than 2 bombzones found with \"script_bombmode_dual\" \"1\"";
		else if(array.size > 2)
			maperrors[maperrors.size] = "^1Bombmode dual: More than 2 bombzones found with \"script_bombmode_dual\" \"1\"";
	}
	else
		println("^6Unknown bomb mode");

	bombtriggers = getentarray("bombtrigger", "targetname");
	if(bombtriggers.size < 1)
		maperrors[maperrors.size] = "^1No entities found with \"targetname\" \"bombtrigger\"";
	else if(bombtriggers.size > 1)
		maperrors[maperrors.size] = "^1More than 1 entity found with \"targetname\" \"bombtrigger\"";

	if(maperrors.size)
	{
		println("^1------------ Map Errors ------------");
		for(i = 0; i < maperrors.size; i++)
			println(maperrors[i]);
		println("^1------------------------------------");

		return;
	}

	bombtrigger = getent("bombtrigger", "targetname");
	bombtrigger maps\mp\_utility::triggerOff();

	// Kill unused bombzones and associated script_exploders

	accepted = [];
	for(i = 0; i < array.size; i++)
	{
		if(isdefined(array[i].script_noteworthy))
			accepted[accepted.size] = array[i].script_noteworthy;
	}

	remove = [];
	bombzones = getentarray("bombzone", "targetname");
	for(i = 0; i < bombzones.size; i++)
	{
		bombzone = bombzones[i];

		if(isdefined(bombzone.script_noteworthy))
		{
			addtolist = true;
			for(j = 0; j < accepted.size; j++)
			{
				if(bombzone.script_noteworthy == accepted[j])
				{
					addtolist = false;
					break;
				}
			}

			if(addtolist)
				remove[remove.size] = bombzone.script_noteworthy;
		}
	}

	ents = getentarray();
	for(i = 0; i < ents.size; i++)
	{
		ent = ents[i];

		if(isdefined(ent.script_exploder))
		{
			kill = false;
			for(j = 0; j < remove.size; j++)
			{
				if(ent.script_exploder == int(remove[j]))
				{
					kill = true;
					break;
				}
			}

			if(kill)
				ent delete();
		}
	}
}

bombzone_think(bombzone_other, id)
{
	level endon("round_ended");

	level.barincrement = (level.barsize / (20.0 * level.planttime));

	self setteamfortrigger(game["attackers"]);
	self setHintString(&"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES");

	// Number7
	if (isDefined(level.sdObjective))
		level.sdObjective[level.sdObjective.size] = self.origin;

	for(;;)
	{
		self waittill("trigger", other);

		if ((! level.esd_mode) && isdefined (bombzone_other) && isdefined (bombzone_other.planting))
			continue;

		if (level.roundended)
			continue;
		
		if(level.bombmode == 2 && isdefined(self.script_team))
			team = self.script_team;
		else
			team = game["attackers"];

		if(isPlayer(other) && (other.pers["team"] == team) && other isOnGround())
		{
			while(other istouching(self) && isAlive(other) && other useButtonPressed() && (! level.roundended))
			{
				other notify("kill_check_bombzone");

				self.planting = true;
				other clientclaimtrigger(self);
				
				if ((! level.esd_mode) && isdefined (bombzone_other))
					other clientclaimtrigger(bombzone_other);

				if(!isdefined(other.progressbackground))
				{
					other.progressbackground = newClientHudElem(other);
					other.progressbackground.x = 0;

					if(level.splitscreen)
						other.progressbackground.y = 70;
					else
						other.progressbackground.y = 104;

					other.progressbackground.alignX = "center";
					other.progressbackground.alignY = "middle";
					other.progressbackground.horzAlign = "center_safearea";
					other.progressbackground.vertAlign = "center_safearea";
					other.progressbackground.alpha = 0.5;
				}
				other.progressbackground setShader("black", (level.barsize + 4), 12);

				if(!isdefined(other.progressbar))
				{
					other.progressbar = newClientHudElem(other);
					other.progressbar.x = int(level.barsize / (-2.0));

					if(level.splitscreen)
						other.progressbar.y = 70;
					else
						other.progressbar.y = 104;

					other.progressbar.alignX = "left";
					other.progressbar.alignY = "middle";
					other.progressbar.horzAlign = "center_safearea";
					other.progressbar.vertAlign = "center_safearea";
				}
				other.progressbar setShader("white", 0, 8);
				other.progressbar scaleOverTime(level.planttime, level.barsize, 8);

				other playsound("MP_bomb_plant");
				other linkTo(self);
				other disableWeapon();

				self.progresstime = 0;
				while(isAlive(other) && other useButtonPressed() && (self.progresstime < level.planttime))
				{
					self.progresstime += 0.05;
					wait 0.05;
				}

				// TODO: script error if player is disconnected/kicked here
				other clientreleasetrigger(self);

				if ((! level.esd_mode) && isdefined (bombzone_other))
					other clientreleasetrigger(bombzone_other);

				if(self.progresstime >= level.planttime)
				{
					other.progressbackground destroy();
					other.progressbar destroy();
					
					if (level.esd_mode)
						other unlink();
					
					other enableWeapon();

					if(isdefined(self.target))
					{
						exploder = getent(self.target, "targetname");

						if(isdefined(exploder) && isdefined(exploder.script_exploder))
							level.bombexploder[id] = exploder.script_exploder;
					}

					if (! level.esd_mode)
					{
						bombzones = getentarray("bombzone", "targetname");
						for(i = 0; i < bombzones.size; i++)
							bombzones[i] delete();
					}
					
					if(level.bombmode == 1)
					{
						objective_delete(0);
						thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("allies");
						thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("axis");
					}
					else
					{
						if (! level.esd_mode)
						{
							objective_delete(0);
							objective_delete(1);
							thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("allies");
							thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("axis");
						}
					}

					plant = other maps\mp\_utility::getPlant();

					level.bombmodel[id] = spawn("script_model", plant.origin);
					level.bombmodel[id].angles = plant.angles;
					level.bombmodel[id] setmodel("xmodel/mp_tntbomb");
					level.bombmodel[id] playSound("Explo_plant_no_tick");
					level.bombglow[id] = spawn("script_model", plant.origin);
					level.bombglow[id].angles = plant.angles;
					level.bombglow[id] setmodel("xmodel/mp_tntbomb_obj");

					if (! level.esd_mode)
					{
						bombtrigger = getent("bombtrigger", "targetname");
						bombtrigger.origin = level.bombmodel[id].origin;
					}
					else
						bombtrigger = self;
					
					if (! level.esd_mode)
					{
						objective_add(0, "current", bombtrigger.origin, "objective");
						thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("allies");
						thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("axis");
					}
					else
						objective_icon (id, "objective");

					if (! level.esd_mode)
					{
						thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombtrigger.origin, "bomb", "allies", "objpoint_star");
						thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombtrigger.origin, "bomb", "axis", "objpoint_star");
					}
					else
					{
						name = "" + id;
						thread changeTeamObjpoints (name, "allies", "objpoint_star", true);
						thread changeTeamObjpoints (name, "axis", "objpoint_star", true);
					}

					level.bombplanted[id] = true;

					if (! level.esd_mode)
						level.lastbombplanted = true;
					else
						level.lastbombplanted = (level.bombplanted[0] && level.bombplanted[1]);
						
					level.bombtimerstart[id] = gettime();
					level.planting_team = other.pers["team"];
					
					lpselfnum = other getEntityNumber();
					lpselfguid = other getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "bomb_plant" + "\n");

					iprintln(&"MP_EXPLOSIVESPLANTED");
					level thread soundPlanted(other);

///// Added for AWE ////
					other.pers["score"] += level.plantscore;
					other.score = other.pers["score"];
////////////////////////

					bombtrigger thread bomb_think(id);
					bombtrigger thread bomb_countdown(id);

					if (! level.esd_mode)
					{
						level notify ("bomb_planted");
						level.clock destroy ();
						return;
					}
					else if (level.defuseback)
					{
						self waittill ("bomb_defuseback");
						level.bombplanted[id] = false;
						level.bombdefused[id] = false;
						self setteamfortrigger (game["attackers"]);
						self setHintString (&"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES");
						break;
					}
					else
						return;	//TEMP, script should stop after the wait .05
				}
				else
				{
					if(isdefined(other.progressbackground))
						other.progressbackground destroy();

					if(isdefined(other.progressbar))
						other.progressbar destroy();

					other unlink();
					other enableWeapon();
				}

				wait .05;
			}

			self.planting = undefined;
			other thread check_bombzone(self);
		}
	}
}

check_bombzone(trigger)
{
	self notify("kill_check_bombzone");
	self endon("kill_check_bombzone");
	level endon("round_ended");

	while(isdefined(trigger) && !isdefined(trigger.planting) && self istouching(trigger) && isAlive(self))
		wait 0.05;
}

bomb_countdown(id)
{
	self endon("bomb_defused");
	level endon("intermission");

	thread showBombTimers(id);
	level.bombmodel[id] playLoopSound("bomb_tick");

	wait level.bombtimer;

	// bomb timer is up
	if (! level.esd_mode)
	{
		objective_delete(0);
		thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("allies");
		thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("axis");
	}
	else
	{
		objective_delete (id);
		name = "" + id;
		thread changeTeamObjpoints (name, "allies", "", false);
		thread changeTeamObjpoints (name, "axis", "", false);
	}
	
	thread deleteBombTimers(id);

	level.bombexploded[id] = true;
	
	wait 0.3;
	
	self notify("bomb_exploded");

	// trigger exploder if it exists
	if(isdefined(level.bombexploder[id]))
		maps\mp\_utility::exploder(level.bombexploder[id]);

	// explode bomb
	origin = self getorigin();
	range = 500;
	maxdamage = 2000;
	mindamage = 1000;

	self delete(); // delete the defuse trigger
	level.bombmodel[id] stopLoopSound();
	level.bombmodel[id] delete();
	level.bombglow[id] delete();

	playfx(level._effect["bombexplosion"], origin);
	radiusDamage(origin, range, maxdamage, mindamage);

	level thread playSoundOnPlayers("mp_announcer_objdest");

	if ((level.esd_mode == 0) || (level.esd_mode == 1) || (level.esd_mode == 3) || ((level.esd_mode == 2) || (level.esd_mode == 4) && level.bombexploded[1 - id]))
		level thread endRound(level.planting_team);
}

bomb_think(id)
{
	self endon("bomb_exploded");
	level.barincrement = (level.barsize / (20.0 * level.defusetime));

	self setteamfortrigger(game["defenders"]);
	self setHintString(&"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES");

	for(;;)
	{
		self waittill("trigger", other);

		if (level.roundended || level.bombexploded[id])
			continue;

		// check for having been triggered by a valid player
		if(isPlayer(other) && (other.pers["team"] != level.planting_team) && other isOnGround())
		{
			while(isAlive(other) && other useButtonPressed() && (! level.roundended) && (! level.bombexploded[id]))
			{
				other notify("kill_check_bomb");

				other clientclaimtrigger(self);

				if(!isdefined(other.progressbackground))
				{
					other.progressbackground = newClientHudElem(other);
					other.progressbackground.x = 0;

					if(level.splitscreen)
						other.progressbackground.y = 70;
					else
						other.progressbackground.y = 104;

					other.progressbackground.alignX = "center";
					other.progressbackground.alignY = "middle";
					other.progressbackground.horzAlign= "center_safearea";
					other.progressbackground.vertAlign = "center_safearea";
					other.progressbackground.alpha = 0.5;
				}
				other.progressbackground setShader("black", (level.barsize + 4), 12);

				if(!isdefined(other.progressbar))
				{
					other.progressbar = newClientHudElem(other);
					other.progressbar.x = int(level.barsize / (-2.0));

					if(level.splitscreen)
						other.progressbar.y = 70;
					else
						other.progressbar.y = 104;

					other.progressbar.alignX = "left";
					other.progressbar.alignY = "middle";
					other.progressbar.horzAlign = "center_safearea";
					other.progressbar.vertAlign = "center_safearea";
				}
				other.progressbar setShader("white", 0, 8);
				other.progressbar scaleOverTime(level.defusetime, level.barsize, 8);

				other playsound("MP_bomb_defuse");
				other linkTo(self);
				other disableWeapon();

				self.progresstime = 0;
				while(isAlive(other) && other useButtonPressed() && (self.progresstime < level.defusetime) && (! level.bombexploded[id]))
				{
					self.progresstime += 0.05;
					wait 0.05;
				}

				other clientreleasetrigger(self);

				if(self.progresstime >= level.defusetime)
				{
					other.progressbackground destroy();
					other.progressbar destroy();

					if (! level.esd_mode)
					{
						objective_delete(0);
						thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("allies");
						thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("axis");
					}
					else
					{
						other unlink();
						other enableWeapon();
						
						if (level.defuseback)
						{
							if (id == 0)
							{
								objective_icon (0, "objectiveA");
								thread changeTeamObjpoints ("0", "allies", "objpoint_A", true);
								thread changeTeamObjpoints ("0", "axis", "objpoint_A", true);
							}
							else
							{
								objective_icon (1, "objectiveB");
								thread changeTeamObjpoints ("1", "allies", "objpoint_B", true);
								thread changeTeamObjpoints ("1", "axis", "objpoint_B", true);
							}
						}
						else
						{
							objective_delete (id);
							name = "" + id;
							thread changeTeamObjpoints (name, "allies", "", false);
							thread changeTeamObjpoints (name, "axis", "", false);
						}
					}
					
					thread deleteBombTimers(id);

					self notify("bomb_defused");
					level.bombmodel[id] stopLoopSound();
					level.bombmodel[id] delete();
					level.bombglow[id] delete();
					
					if (! level.defuseback)
						self delete ();

					iprintln(&"MP_EXPLOSIVESDEFUSED");
					level thread playSoundOnPlayers("MP_announcer_bomb_defused");

					lpselfnum = other getEntityNumber();
					lpselfguid = other getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "bomb_defuse" + "\n");

///// Added for AWE ////
					other.pers["score"] += level.defusescore;
					other.score = other.pers["score"];
////////////////////////

					level.bombdefused[id] = true;
					
					if (! level.esd_mode)
					{
						level thread endRound(other.pers["team"]);
						return;
					}

					if ((! level.defuseback) && (level.esd_mode == 2) || ((level.esd_mode == 1) && level.lastbombplanted && level.bombdefused[1 - id]))
					{
						level thread endRound(other.pers["team"]);
						return;
					}

					if (level.defuseback)
						self notify ("bomb_defuseback");
					
					return;	//TEMP, script should stop after the wait .05
				}
				else
				{
					if(isdefined(other.progressbackground))
						other.progressbackground destroy();

					if(isdefined(other.progressbar))
						other.progressbar destroy();

					other unlink();
					other enableWeapon();
				}

				wait .05;
			}

			self.defusing = undefined;
			other thread check_bomb(self);
		}
	}
}

check_bomb(trigger)
{
	self notify("kill_check_bomb");
	self endon("kill_check_bomb");

	while(isdefined(trigger) && !isdefined(trigger.defusing) && self istouching(trigger) && isAlive(self))
		wait 0.05;
}

printJoinedTeam(team)
{
	if(!level.splitscreen)
	{
		if(team == "allies")
			iprintlnFIXED (&"MP_JOINED_ALLIES", self);
		else if(team == "axis")
			iprintlnFIXED (&"MP_JOINED_AXIS", self);
	}
}

sayObjective()
{
	wait 2;

	attacksounds["american"] = "US_mp_cmd_movein";
	attacksounds["british"] = "UK_mp_cmd_movein";
	attacksounds["russian"] = "RU_mp_cmd_movein";
	attacksounds["german"] = "GE_mp_cmd_movein";
	defendsounds["american"] = "US_mp_defendbomb";
	defendsounds["british"] = "UK_mp_defendbomb";
	defendsounds["russian"] = "RU_mp_defendbomb";
	defendsounds["german"] = "GE_mp_defendbomb";

	level playSoundOnPlayers(attacksounds[game[game["attackers"]]], game["attackers"]);
	level playSoundOnPlayers(defendsounds[game[game["defenders"]]], game["defenders"]);
}

showBombTimers(id)
{
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isdefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
			player showPlayerBombTimer(id);
	}
}

showPlayerBombTimer(id)
{
	timeleft = (level.bombtimer - (getTime() - level.bombtimerstart[id]) / 1000);

	if(timeleft > 0)
	{
		self.bombtimer[id] = newClientHudElem(self);

		if (! level.esd_mode)
		{
			self.bombtimer[id].x = 6;
			self.bombtimer[id].y = 76;
		}
		else
		{
			self.bombtimer[id].x = 6 + 48 * id;
			self.bombtimer[id].y = 76;
		}
		self.bombtimer[id].horzAlign = "left";
		self.bombtimer[id].vertAlign = "top";

		if (! level.esd_mode)
			self.bombtimer[id] setClock(timeleft, level.bombtimer, "hudStopwatch", 48, 48);
		else
			self.bombtimer[id] setClock(timeleft, level.bombtimer, "hudStopwatch", 40, 40);
	}
}

deleteBombTimers(id)
{
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
		players[i] deletePlayerBombTimer(id);
}

deletePlayerBombTimer(id)
{
	if(isdefined(self.bombtimer[id]))
		self.bombtimer[id] destroy();
}

announceWinner(winner, delay)
{
	wait delay;

	// Announce winner
	if(winner == "allies")
		level thread playSoundOnPlayers("MP_announcer_allies_win");
	else if(winner == "axis")
		level thread playSoundOnPlayers("MP_announcer_axis_win");
	else if(winner == "draw")
	{
		// Number7
		if (!(game["swapTeams"] && game["roundsplayed"] == game["swapTeams"]))
			level thread playSoundOnPlayers("MP_announcer_round_draw");
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

		if(!isdefined(player.pers["team"]) || player.pers["team"] == "spectator")
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
			assignment = teams[randomInt(2)];	// should not switch teams if already on a team
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
	self.pers["weapon1"] = undefined;
	self.pers["weapon2"] = undefined;
	self.pers["spawnweapon"] = undefined;
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
	
	if (level.respawn)
		self notify ("end_respawn");
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
		self.pers["weapon1"] = undefined;
		self.pers["weapon2"] = undefined;
		self.pers["spawnweapon"] = undefined;
		self.pers["savedmodel"] = undefined;

		self setClientCvar("ui_allow_weaponchange", "1");
		self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);

		self notify("joined_team");
		
		if (level.respawn)
			self notify ("end_respawn");
	}

	if(!isdefined(self.pers["weapon"]))
		self openMenu(game["menu_weapon_allies"]);
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
		self.pers["weapon1"] = undefined;
		self.pers["weapon2"] = undefined;
		self.pers["spawnweapon"] = undefined;
		self.pers["savedmodel"] = undefined;

		self setClientCvar("ui_allow_weaponchange", "1");
		self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);

		self notify("joined_team");
		
		if (level.respawn)
			self notify ("end_respawn");
	}

	if(!isdefined(self.pers["weapon"]))
		self openMenu(game["menu_weapon_axis"]);
}

menuSpectator()
{
	if(self.pers["team"] != "spectator")
	{
		if (! level.respawn)
			self notify ("joined_spectators");

		if(isAlive(self))
		{
			self.switching_teams = true;
			self.joining_team = "spectator";
			self.leaving_team = self.pers["team"];
			self suicide();
		}

		self.pers["team"] = "spectator";
		self.pers["weapon"] = undefined;
		self.pers["weapon1"] = undefined;
		self.pers["weapon2"] = undefined;
		self.pers["spawnweapon"] = undefined;
		self.pers["savedmodel"] = undefined;

		self.sessionteam = "spectator";
		self setClientCvar("ui_allow_weaponchange", "0");

		if (level.respawn)
			self thread updateTimer ();

		spawnSpectator();

		if(level.splitscreen)
			self setClientCvar("g_scriptMainMenu", game["menu_ingame_spectator"]);
		else
			self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

		if (level.respawn)
		{
			self notify ("joined_spectators");
			self notify ("end_respawn");
		}
	}
}

menuWeapon(response)
{
	if(!isdefined(self.pers["team"]) || (self.pers["team"] != "allies" && self.pers["team"] != "axis"))
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

	if(isdefined(self.pers["weapon"]) && self.pers["weapon"] == weapon && !isdefined(self.pers["weapon1"]))
		return;

	if(!game["matchstarted"])
	{
		if(isdefined(self.pers["weapon"]))
		{
			self.pers["weapon"] = weapon;
			self setWeaponSlotWeapon("primary", weapon);
			self setWeaponSlotAmmo("primary", 999);
			self setWeaponSlotClipAmmo("primary", 999);
			self switchToWeapon(weapon);

			maps\mp\gametypes\_weapons::givePistol();
			maps\mp\gametypes\_weapons::giveGrenades();
		}
		else
		{
			self.pers["weapon"] = weapon;

			if (isdefined (self.WaitingToSpawn))
			{
				self thread respawn ();
				self thread updateTimer ();
			}
			else
			{
				self.spawned = undefined;
				spawnPlayer ();
			}

			self thread printJoinedTeam(self.pers["team"]);
			level checkMatchStart();
		}
	}
	else if(!level.roundstarted && !self.usedweapons)
	{
		if(isdefined(self.pers["weapon"]))
		{
			self.pers["weapon"] = weapon;
			self setWeaponSlotWeapon("primary", weapon);
			self setWeaponSlotAmmo("primary", 999);
			self setWeaponSlotClipAmmo("primary", 999);
			self switchToWeapon(weapon);

			maps\mp\gametypes\_weapons::givePistol();
			maps\mp\gametypes\_weapons::giveGrenades();
		}
		else
		{
			self.pers["weapon"] = weapon;
			if(!level.exist[self.pers["team"]])
			{
				if (isdefined (self.WaitingToSpawn))
				{
					self thread respawn ();
					self thread updateTimer ();
				}
				else
				{
					self.spawned = undefined;
					spawnPlayer ();
				}

				self thread printJoinedTeam(self.pers["team"]);
				level checkMatchStart();
			}
			else
			{
				if (isdefined (self.WaitingToSpawn))
				{
					self thread respawn ();
					self thread updateTimer ();
				}
				else
				{
					spawnPlayer ();
				}

				self thread printJoinedTeam(self.pers["team"]);
			}
		}
	}
	else
	{
		if(isdefined(self.pers["weapon"]))
			self.oldweapon = self.pers["weapon"];

		self.pers["weapon"] = weapon;
		self.sessionteam = self.pers["team"];

		if(self.sessionstate != "playing")
			self.statusicon = "hud_status_dead";

		if(self.pers["team"] == "allies")
			otherteam = "axis";
		else
		{
			assert(self.pers["team"] == "axis");
			otherteam = "allies";
		}

		// if joining a team that has no opponents, just spawn
		if(!level.didexist[otherteam] && !level.roundended)
		{
			if(isdefined(self.spawned))
			{
				if(isdefined(self.pers["weapon"]))
				{
					self.pers["weapon"] = weapon;
					self setWeaponSlotWeapon("primary", weapon);
					self setWeaponSlotAmmo("primary", 999);
					self setWeaponSlotClipAmmo("primary", 999);
					self switchToWeapon(weapon);

					maps\mp\gametypes\_weapons::givePistol();
					maps\mp\gametypes\_weapons::giveGrenades();
				}
			}
			else
			{
				if (isdefined (self.WaitingToSpawn))
				{
					self thread respawn ();
					self thread updateTimer ();
				}
				else
				{
					self.spawned = undefined;
					spawnPlayer ();
				}

				self thread printJoinedTeam(self.pers["team"]);
			}
		} // else if joining an empty team, spawn and check for match start
		else if(!level.didexist[self.pers["team"]] && !level.roundended)
		{
			if (isdefined (self.WaitingToSpawn))
			{
				self thread respawn ();
				self thread updateTimer ();
			}
			else
			{
				self.spawned = undefined;
				spawnPlayer ();
			}

			self thread printJoinedTeam(self.pers["team"]);
			level checkMatchStart();
		} // else you will spawn with selected weapon next round
		else
		{
			weaponname = maps\mp\gametypes\_weapons::getWeaponName(self.pers["weapon"]);

			if (level.respawn)
			{
				if(isdefined(self.WaitingToSpawn))
				{
					self thread respawn();
					self thread updateTimer();
				}
				else
				{
					if (level.respawn)
						self.spawned = undefined;
					spawnPlayer();
				}
		
				self thread printJoinedTeam(self.pers["team"]);
			}
			else
			{
				if(self.pers["team"] == "allies")
				{
					if(maps\mp\gametypes\_weapons::useAn(self.pers["weapon"]))
						self iprintln(&"MP_YOU_WILL_SPAWN_ALLIED_WITH_AN_NEXT_ROUND", weaponname);
					else
						self iprintln(&"MP_YOU_WILL_SPAWN_ALLIED_WITH_A_NEXT_ROUND", weaponname);
				}
				else if(self.pers["team"] == "axis")
				{
					if(maps\mp\gametypes\_weapons::useAn(self.pers["weapon"]))
						self iprintln(&"MP_YOU_WILL_SPAWN_AXIS_WITH_AN_NEXT_ROUND", weaponname);
					else
						self iprintln(&"MP_YOU_WILL_SPAWN_AXIS_WITH_A_NEXT_ROUND", weaponname);
				}
			}
		}
	}

	self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
}

soundPlanted(player)
{
	if(game["allies"] == "british")
		alliedsound = "UK_mp_explosivesplanted";
	else if(game["allies"] == "russian")
		alliedsound = "RU_mp_explosivesplanted";
	else
		alliedsound = "US_mp_explosivesplanted";

	axissound = "GE_mp_explosivesplanted";

	if(level.splitscreen)
	{
		if(player.pers["team"] == "allies")
			player playLocalSound(alliedsound);
		else if(player.pers["team"] == "axis")
			player playLocalSound(axissound);

		return;
	}
	else
	{
		level playSoundOnPlayers(alliedsound, "allies");
		level playSoundOnPlayers(axissound, "axis");

		wait 1.5;

		if(level.planting_team == "allies")
		{
			if(game["allies"] == "british")
				alliedsound = "UK_mp_defendbomb";
			else if(game["allies"] == "russian")
				alliedsound = "RU_mp_defendbomb";
			else
				alliedsound = "US_mp_defendbomb";

			level playSoundOnPlayers(alliedsound, "allies");
			level playSoundOnPlayers("GE_mp_defusebomb", "axis");
		}
		else if(level.planting_team == "axis")
		{
			if(game["allies"] == "british")
				alliedsound = "UK_mp_defusebomb";
			else if(game["allies"] == "russian")
				alliedsound = "RU_mp_defusebomb";
			else
				alliedsound = "US_mp_defusebomb";

			level playSoundOnPlayers(alliedsound, "allies");
			level playSoundOnPlayers("GE_mp_defendbomb", "axis");
		}
	}
}

swapteams ()
{
	newTeam = undefined;

	// Swap all players
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		// Only swap axis and allies, not spectators
		if(players[i].pers["team"] != "allies" && players[i].pers["team"] != "axis")
			continue;

		if(players[i].pers["team"] == "axis")
		{
			newTeam = "allies";
			if(isdefined(players[i].pers["weapon"]))	players[i].pers["awe_axisweapon"]	= players[i].pers["weapon"];
			if(isdefined(players[i].pers["weapon1"]))	players[i].pers["awe_axisweapon1"]	= players[i].pers["weapon1"];
			if(isdefined(players[i].pers["weapon2"]))	players[i].pers["awe_axisweapon2"]	= players[i].pers["weapon2"];
			if(isdefined(players[i].pers["spawnweapon"])) players[i].pers["awe_axisspawnweapon"] = players[i].pers["spawnweapon"];
		}
		if(players[i].pers["team"] == "allies")
		{
			newTeam = "axis";
			if(isdefined(players[i].pers["weapon"]))	players[i].pers["awe_alliedweapon"]	= players[i].pers["weapon"];
			if(isdefined(players[i].pers["weapon1"]))	players[i].pers["awe_alliedweapon1"]	= players[i].pers["weapon1"];
			if(isdefined(players[i].pers["weapon2"]))	players[i].pers["awe_alliedweapon2"]	= players[i].pers["weapon2"];
			if(isdefined(players[i].pers["spawnweapon"])) players[i].pers["awe_alliedspawnweapon"] = players[i].pers["spawnweapon"];
		}

		players[i].pers["team"] = newTeam;
		players[i].pers["weapon"] = undefined;
		players[i].pers["weapon1"] = undefined;
		players[i].pers["weapon2"] = undefined;
		players[i].pers["spawnweapon"] = undefined;
		players[i].pers["savedmodel"] = undefined;

		// update spectator permissions immediately on change of team
		//players[i] maps\mp\gametypes\_teams::SetSpectatePermissions();
		players[i] thread maps\mp\gametypes\_spectating::setSpectatePermissions();	// cod-2
	
		if(players[i].pers["team"] == "allies")
		{
			// Set old allied weapon if available
			if(isdefined(players[i].pers["awe_alliedweapon"]))	players[i].pers["weapon"]	= players[i].pers["awe_alliedweapon"];
			if(isdefined(players[i].pers["awe_alliedweapon1"]))	players[i].pers["weapon1"]	= players[i].pers["awe_alliedweapon1"];
			if(isdefined(players[i].pers["awe_alliedweapon2"]))	players[i].pers["weapon2"]	= players[i].pers["awe_alliedweapon2"];
			if(isdefined(players[i].pers["awe_alliedspawnweapon"])) players[i].pers["spawnweapon"] = players[i].pers["awe_alliedspawnweapon"];

		}
		else
		{
			// Set old axis weapon if available
			if(isdefined(players[i].pers["awe_axisweapon"]))	players[i].pers["weapon"]	= players[i].pers["awe_axisweapon"];
			if(isdefined(players[i].pers["awe_axisweapon1"]))	players[i].pers["weapon1"]	= players[i].pers["awe_axisweapon1"];
			if(isdefined(players[i].pers["awe_axisweapon2"]))	players[i].pers["weapon2"]	= players[i].pers["awe_axisweapon2"];
			if(isdefined(players[i].pers["awe_axisspawnweapon"])) players[i].pers["spawnweapon"] = players[i].pers["awe_axisspawnweapon"];
		}

	}

	var = cvardef("scr_esd_swap_teams_reset", 0, 0, 3, "int");

	if (var == 0)
	{
		tempscore =  game["alliedscore"];
		game["alliedscore"] = game["axisscore"];
		game["axisscore"] = tempscore;
		setTeamScore("allies", game["alliedscore"]);
		setTeamScore("axis", game["axisscore"]);
		return;
	}

	if (var == 1 || var == 3)
	{
		players = getentarray("player", "classname");
		for (i = 0; i < players.size; i++)
		{
			if (isDefined(players[i]))
			{
				if (!isDefined(self.pers["score"]))
					self.pers["score"] = 0;
				self.score = self.pers["score"];

				if (!(game["hudStats"] || game["bestStats"] || game["yourStats"]))
				{
					if (!isDefined(self.pers["deaths"]))
						self.pers["deaths"] = 0;
					self.deaths = self.pers["deaths"];
				}
			}
		}
	}

	if (var == 2 || var == 3)
	{
		game["alliedscore"] = 0;
		setTeamScore("allies", game["alliedscore"]);
		game["axisscore"] = 0;
		setTeamScore("axis", game["axisscore"]);
	}
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

	if(isdefined(level.awe_gametype))
		gametype = level.awe_gametype;	// "tdm", "bel", etc.
	else
		gametype = getcvar("g_gametype");	// "tdm", "bel", etc.

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

	if (! level.forcerespawn)
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

changeTeamObjpoints (name, team, material, drawwaypoint)
{
	if (! level.awe_objectivepoints)
		return;

	players = getentarray ("player", "classname");
	for (i = 0; i < players.size; i ++)
	{
		player = players[i];
		if (isdefined (player.pers["team"]) && (player.pers["team"] == team) && (player.sessionstate == "playing"))
		{
			objpoints = player.objpoints;
			for (j = 0; j < objpoints.size; j ++)
			{
				if (objpoints[j].name == name)
				{
					objpoints[j] setShader (material, level.objpoint_scale, level.objpoint_scale);
					objpoints[j] setwaypoint (drawwaypoint);
				}
			}
		}
		
		objpoints = level.objpoints_allies.array;
		for (j = 0; j < objpoints.size; j ++)
		{
			if (objpoints[j].name == name)
				objpoints[j].material = material;
		}
		
		objpoints = level.objpoints_axis.array;
		for (j = 0; j < objpoints.size; j ++)
		{
			if (objpoints[j].name == name)
				objpoints[j].material = material;
		}
	}
}