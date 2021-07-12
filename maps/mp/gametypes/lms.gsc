// Modified by La Truffe

/*
	Last Man Standing
	Objective: 	Be the last one alive to score
	Map ends:	When one player reaches the score limit, or time limit is reached
	Respawning:	No wait / Away from other players

	Level requirements
	------------------
		Spawnpoints:
			classname		mp_dm_spawn
			All players spawn from these. The spawnpoint chosen is dependent on the current locations of enemies at the time of spawn.
			Players generally spawn away from enemies.

		Spectator Spawnpoints:
			classname		mp_global_intermission
			Spectators spawn from these and intermission is viewed from these positions.
			Atleast one is required, any more and they are randomly chosen between.

	Level script requirements
	-------------------------
		Team Definitions:
			game["allies"] = "american";
			game["axis"] = "german";
			Because Deathmatch doesn't have teams with regard to gameplay or scoring, this effectively sets the available weapons.

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
*/

/*QUAKED mp_dm_spawn (1.0 0.5 0.0) (-16 -16 0) (16 16 72)
Players spawn away from enemies at one of these positions.*/

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
	if(!isdefined(game["allies"]))
		game["allies"] = "american";
	if(!isdefined(game["axis"]))
		game["axis"] = "german";

	// server cvar overrides
	if(getCvar("scr_allies") != "")
		game["allies"] = getCvar("scr_allies");
	if(getCvar("scr_axis") != "")
		game["axis"] = getCvar("scr_axis");

	precacheStatusIcon("hud_status_dead");
	precacheStatusIcon("hud_status_connecting");
	precacheRumble("damage_heavy");
	precacheString(&"PLATFORM_PRESS_TO_SPAWN");

	thread maps\mp\gametypes\_menus::init();
	thread maps\mp\gametypes\_serversettings::init();
	thread maps\mp\gametypes\_clientids::init();
	thread maps\mp\gametypes\_teams::init();
	thread maps\mp\gametypes\_weapons::init();
	thread maps\mp\gametypes\_scoreboard::init();
	thread maps\mp\gametypes\_killcam::init();
	thread maps\mp\gametypes\_shellshock::init();
	thread maps\mp\gametypes\_hud_playerscore::init();
	thread maps\mp\gametypes\_deathicons::init();
	thread maps\mp\gametypes\_damagefeedback::init();
	thread maps\mp\gametypes\_healthoverlay::init();
	thread maps\mp\gametypes\_grenadeindicators::init();

	level.xenon = (getcvar("xenonGame") == "true");
	if(level.xenon) // Xenon only
		thread maps\mp\gametypes\_richpresence::init();
	else // PC only
		thread maps\mp\gametypes\_quickmessages::init();

	setClientNameMode("auto_change");

	spawnpointname = "mp_dm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	allowed[0] = "dm";
	maps\mp\gametypes\_gameobjects::main(allowed);

	// Time limit per map
	level.timelimit = cvardef("scr_lms_timelimit",20,0,1440,"float");
// La Truffe ->
/*
	setCvar("ui_lms_timelimit", level.timelimit);
	makeCvarServerInfo("ui_lms_timelimit", "20");
*/
	setCvar("ui_timelimit", level.timelimit);
	makeCvarServerInfo("ui_timelimit", "20");
// La Truffe <-

	// Score limit per map
	level.scorelimit = cvardef("scr_lms_scorelimit",3,0,9999,"int");
// La Truffe ->
/*
	setCvar("ui_lms_scorelimit", level.scorelimit);
	makeCvarServerInfo("ui_lms_scorelimit", "3");
*/
	setCvar("ui_scorelimit", level.scorelimit);
	makeCvarServerInfo("ui_scorelimit", "3");
// La Truffe <-

	// Force respawning
	level.forcerespawn = cvardef("scr_forcerespawn",0,0,60,"int");

	level.minplayers = cvardef("scr_lms_minplayers", 4, 3, 64, "int");
	level.gamestarted = false;
	level.joinperiod = false;
	level.joinperiodtime = cvardef("scr_lms_joinperiod", 15, 1, 120, "int");
	level.jointimeleft = level.joinperiodtime;
	level.duelperiodtime = cvardef("scr_lms_duelperiod", 60, 1, 120, "int");
	level.dueltimeleft = level.duelperiodtime;
	level.endingmatch = false;
	level.killwinner = cvardef("scr_lms_killwinner",0,0,1,"int");
	level.killometer = cvardef("scr_lms_killometer",60,1,1200,"int");
	level.duel = false;
	level.oldbarsize = 0;

	precacheShader("white");
	precacheString(&"Join-O-Meter");
	precacheString(&"Kill-O-Meter");
	precacheString(&"Die-O-Meter");
	precacheString(&"Duel-O-Meter");

	precacheString(&"Opponent Info");
	precacheString(&"Player ^3A");
	precacheString(&"Player ^3B");
	precacheString(&"Distance(m)");
	precacheString(&"Health");
	precacheString(&"Weapon");
	precacheString(&"Ammo");

	precacheString(&"Sniper");
	precacheString(&"Rifle");
	precacheString(&"Shotgun");
	precacheString(&"Machinegun");
	precacheString(&"Pistol");
	precacheString(&"Sprinting");
	precacheString(&"None");

	precacheShader("hud_status_dead");

	precacheShader("objpoint_A");
	precacheShader("objpoint_B");

	updateAlivePlayersHud(0);

	if(!isdefined(game["state"]))
		game["state"] = "playing";

	level.QuickMessageToAll = true;
	level.mapended = false;

	thread startGame();
	thread updateGametypeCvars();
	//thread maps\mp\gametypes\_teams::addTestClients();
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
	lpselfguid = self getGuid();
	logPrint("J;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");

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

	if(isdefined(self.pers["team"]) && self.pers["team"] != "spectator")
	{
		self setClientCvar("ui_allow_weaponchange", "1");
		self.sessionteam = "none";

		if(isdefined(self.pers["weapon"]))
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

	if(isdefined(self.clientid))
		setplayerteamrank(self, self.clientid, 0);

	checkAlivePlayers();
	self removeKillOMeter();

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("Q;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(self.sessionteam == "spectator")
		return;

	// Don't do knockback if the damage direction was not specified
	if(!isdefined(vDir))
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	// Make sure at least one point of damage is done
	if(iDamage < 1)
		iDamage = 1;

	// Do debug print if it's enabled
	if(getCvarInt("g_debugDamage"))
	{
		println("client:" + self getEntityNumber() + " health:" + self.health +
			" damage:" + iDamage + " hitLoc:" + sHitLoc);
	}

	// Apply the damage to the player
	self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

	// Shellshock/Rumble
	self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
	self playrumble("damage_heavy");
	if(isdefined(eAttacker) && eAttacker != self)
		eAttacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback();

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

		logPrint("D;" + lpselfGuid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackGuid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
	}
}

Callback_PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self endon("spawned");
	self notify("killed_player");

	if(self.sessionteam == "spectator")
		return;

	self removeKillOMeter();
	self thread removeDuelHud();

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
		self.deaths++;

	lpselfnum = self getEntityNumber();
	lpselfname = self.name;
	lpselfteam = "";
	lpselfguid = self getGuid();
	lpattackerteam = "";

	attackerNum = -1;
	if(isPlayer(attacker))
	{
		if(attacker == self) // killed himself
		{
			doKillcam = false;

//			if(!isdefined(self.switching_teams))
//				attacker.score--;
		}
		else
		{
			attackerNum = attacker getEntityNumber();
			doKillcam = true;

//			attacker.score++;
//			attacker checkScoreLimit();
			attacker.killometer = level.killometer;
			attacker updateKillOMeter();
		}

		lpattacknum = attacker getEntityNumber();
		lpattackguid = attacker getGuid();
		lpattackname = attacker.name;

		attacker notify("update_playerhud_score");
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		doKillcam = false;

//		self.score--;

		lpattacknum = -1;
		lpattackguid = "";
		lpattackname = "";

		self notify("update_playerhud_score");
	}

	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

	// Stop thread if map ended on this death
	if(level.mapended)
		return;

	self.switching_teams = undefined;
	self.joining_team = undefined;
	self.leaving_team = undefined;

	body = self cloneplayer(deathAnimDuration);
	thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"]);

	if(!isdefined(self.nowinner))
		checkAlivePlayers();
	else
		self.nowinner = undefined;

	delay = 2;	// Delay the player becoming a spectator till after he's done dying
	wait delay;	// ?? Also required for Callback_PlayerKilled to complete before respawn/killcam can execute

	if(doKillcam && level.killcam)
		self maps\mp\gametypes\_killcam::killcam(attackerNum, delay, psOffsetTime, true);

	self thread respawn();
}

spawnPlayer()
{
	self endon("disconnect");

	// Avoid duplicates
	self notify("lms_respawn");
	self endon("lms_respawn");

	// Wait for spawn if we are not in the first joinperiod or if we have allready spawned once.
	if(!level.joinperiod || isdefined(self.havespawned))
	{
		if(!level.gamestarted)
		{
			thread countPlayers();
		}
		else
		{
			self iprintlnbold("Waiting for the next cycle to start...");
		}
		self spawnSpectator(undefined,undefined);
		level waittill("lms_spawn_players");
	}
	
	// Flag player as one that has spawned at least once
	self.havespawned = true;

	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionteam = "none";
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.statusicon = "";
	self.maxhealth = 100;
	self.health = self.maxhealth;

	spawnpointname = "mp_dm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_DM(spawnpoints);

	if(isdefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");

	if(!isdefined(self.pers["savedmodel"]))
		maps\mp\gametypes\_teams::model();
	else
		maps\mp\_utility::loadModel(self.pers["savedmodel"]);

	maps\mp\gametypes\_weapons::givePistol();
	maps\mp\gametypes\_weapons::giveGrenades();
	maps\mp\gametypes\_weapons::giveBinoculars();

	self giveWeapon(self.pers["weapon"]);
	self giveMaxAmmo(self.pers["weapon"]);
	self setSpawnWeapon(self.pers["weapon"]);

	if(!level.splitscreen)
	{
		if(level.scorelimit > 0)
			self setClientCvar("cg_objectiveText", &"LMS_OBJ_TEXT", level.scorelimit);
		else
			self setClientCvar("cg_objectiveText", &"LMS_OBJ_TEXT_NOSCORE");
	}
	else
		self setClientCvar("cg_objectiveText", &"LMS_OBJ_TEXT_NOSCORE");

	waittillframeend;
	self notify("spawned_player");

	checkAlivePlayers(true);
	self thread killOMeter();
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

	if(self.pers["team"] == "spectator")
		self.statusicon = "";

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

	spawnpointname = "mp_global_intermission";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

	if(isdefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
}

respawn()
{
	if(!isdefined(self.pers["weapon"]))
		return;

	self endon("end_respawn");

	if(level.forcerespawn <= 0)
	{
		self thread waitRespawnButton();
		self waittill("respawn");
	}

	self thread spawnPlayer();
}

waitRespawnButton()
{
	self endon("end_respawn");
	self endon("respawn");

	wait 0; // Required or the "respawn" notify could happen before it's waittill has begun

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

	thread removeRespawnText();
	thread waitRemoveRespawnText("end_respawn");
	thread waitRemoveRespawnText("respawn");

	while((isdefined(self)) && (self useButtonPressed() != true))
		wait .05;

	if(isdefined(self))
	{
		self notify("remove_respawntext");
		self notify("respawn");
	}
}

removeRespawnText()
{
	self waittill("remove_respawntext");

	if(isdefined(self.respawntext))
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

	players = getentarray("player", "classname");
	highscore = undefined;
	tied = undefined;
	playername = undefined;
	name = undefined;
	guid = undefined;

	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isdefined(player.pers["team"]) && player.pers["team"] == "spectator")
			continue;

		if(!isdefined(highscore))
		{
			highscore = player.score;
			playername = player;
			name = player.name;
			guid = player getGuid();
			continue;
		}

		if(player.score == highscore)
			tied = true;
		else if(player.score > highscore)
		{
			tied = false;
			highscore = player.score;
			playername = player;
			name = player.name;
			guid = player getGuid();
		}
	}

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		player closeMenu();
		player closeInGameMenu();

		if(isdefined(tied) && tied == true)
			player setClientCvar("cg_objectiveText", &"MP_THE_GAME_IS_A_TIE");
		else if(isdefined(playername))
			player setClientCvar("cg_objectiveText", &"MP_WINS", playername);

		player spawnIntermission();
	}

	if(isdefined(name))
		logPrint("W;;" + guid + ";" + name + "\n");

	// set everyone's rank on xenon
	if(level.xenon)
	{
		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(isdefined(player.pers["team"]) && player.pers["team"] == "spectator")
				continue;

			if(highscore <= 0)
				rank = 0;
			else
			{
				rank = int(player.score * 10 / highscore);
				if(rank < 0)
					rank = 0;
			}

			// since DM is a free-for-all, give every player their own team number
			setplayerteamrank(player, player.clientid, rank);
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
	waittillframeend;

	if(level.scorelimit <= 0)
		return;

	if(self.score < level.scorelimit)
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
		timelimit = cvardef("scr_lms_timelimit",20,0,1440,"float");
		if(level.timelimit != timelimit)
		{
			level.timelimit = timelimit;
// La Truffe ->
//			setCvar("ui_lms_timelimit", level.timelimit);
			setCvar("ui_timelimit", level.timelimit);
// La Truffe <-
			level.starttime = getTime();

			if(level.timelimit > 0)
			{
				if(!isdefined(level.clock))
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
				if(isdefined(level.clock))
					level.clock destroy();
			}

			checkTimeLimit();
		}

		scorelimit = cvardef("scr_lms_scorelimit",3,0,9999,"int");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
// La Truffe ->
//			setCvar("ui_lms_scorelimit", level.scorelimit);
			setCvar("ui_scorelimit", level.scorelimit);
// La Truffe <-
			level notify("update_allhud_score");

			players = getentarray("player", "classname");
			for(i = 0; i < players.size; i++)
				players[i] checkScoreLimit();
		}

		wait 1;
	}
}

menuAutoAssign()
{
	if(self.pers["team"] != "allies" && self.pers["team"] != "axis")
	{
		if(self.sessionstate == "playing")
		{
			self.switching_teams = true;
			self suicide();
		}

		teams[0] = "allies";
		teams[1] = "axis";
		self.pers["team"] = teams[randomInt(2)];
		self.pers["weapon"] = undefined;
		self.pers["savedmodel"] = undefined;

		self setClientCvar("ui_allow_weaponchange", "1");

		if(self.pers["team"] == "allies")
			self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
		else
			self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);

		self notify("joined_team");
		self notify("end_respawn");
	}

	if(!isdefined(self.pers["weapon"]))
	{
		if(self.pers["team"] == "allies")
			self openMenu(game["menu_weapon_allies"]);
		else
			self openMenu(game["menu_weapon_axis"]);
	}
}

menuAllies()
{
	if(self.pers["team"] != "allies")
	{
		if(self.sessionstate == "playing")
		{
			self.switching_teams = true;
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
			self suicide();
		}

		self.pers["team"] = "spectator";
		self.pers["weapon"] = undefined;
		self.pers["savedmodel"] = undefined;

		self.sessionteam = "spectator";
		self setClientCvar("ui_allow_weaponchange", "0");
		spawnSpectator();

		if(level.splitscreen)
			self setClientCvar("g_scriptMainMenu", game["menu_ingame_spectator"]);
		else
			self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

		self notify("joined_spectators");
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

	if(isdefined(self.pers["weapon"]) && self.pers["weapon"] == weapon)
		return;

	if(!isdefined(self.pers["weapon"]))
	{
		self.pers["weapon"] = weapon;
		spawnPlayer();
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
}

updateAlivePlayersHud(n)
{
	if(!isdefined(level.aphud))
	{
		level.aphud = newHudElem();
		level.aphud.x = 345;
		level.aphud.y = 20;
		level.aphud.alignX = "left";
		level.aphud.alignY = "middle";
		level.aphud.alpha = 0.8;
		level.aphud.color = (1,1,1);

		level.aphud2 = newHudElem();
		level.aphud2.x = 345;
		level.aphud2.y = 20;
		level.aphud2.alignX = "right";
		level.aphud2.alignY = "middle";
		level.aphud2.alpha = 0.8;
		level.aphud2.color = (1,1,1);
		level.aphud2 setText(&"Alive players:");			
	}
	level.aphud setValue(n);			
}

checkAlivePlayers(spawn)
{
	// Count the number of players who is still alive
	n=0;
	lastOnesAlive = undefined;
	lastOnesAlive2 = undefined;
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isDefined(player) && isAlive(player))
		{
			n++;

			// Save the two last players
			if(isdefined(lastOnesAlive)) lastOnesAlive2 = lastOnesAlive;
			lastOnesAlive = player;
		}
	}

	updateAlivePlayersHud(n);
//	iprintlnbold("Alive players: " + n);
	
	// Do not check for winners when players spawn
	if(isdefined(spawn)) return;

	// Do we have a winner?
	if(n<2)
		level thread endMatch(lastOnesAlive);
	else if(n==2)
		level thread duel(lastOnesAlive, lastOnesAlive2);
}

countPlayers()
{
	// Count the number of players who has chosen their team
	n=0;
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isdefined(player.pers["team"]))
			n++;
	}

//	iprintln("Players: " + n);

	// Do we have enough players to start?
	if(n>=level.minplayers)
	{
		// Start join period
		level thread watchJoinPeriod();
	}
	else
	{
		iprintlnbold("Waiting for " + (level.minplayers - n) + " more players to join.");
	}
}

watchJoinPeriod()
{
	level notify("end_watchJoinPeriod");
	level endon("end_watchJoinPeriod");

	// Make sure we have only one thread
	if(level.joinperiod) return;
	level.joinperiod = true;
	level.jointimeleft = level.joinperiodtime;

	// Officially start the game
	level.gamestarted = true;
	
	// Spawn all waiting players
	iprintlnbold("Spawning players...");
	level notify("lms_spawn_players");
	wait .05;
	level notify("lms_spawn_players");

	iprintlnbold("Game is now open for joining... (" + level.joinperiodtime + " seconds)");
	// Allow new players to join for the specified amount of time
	for(i=0;i<level.joinperiodtime;i++)
	{
		level.jointimeleft = level.joinperiodtime - i;
		wait 1;
	}
	iprintlnbold("Joining period is over...");

	// Join period is officially over
	level.joinperiod = false;
}

endMatch(winner)
{
	// Avoid dups
	if(level.endingmatch) return;
	level.endingmatch = true;

	// Reset flags
	level.joinperiod = false;
	level.duel = false;

	// Kill threads
	level notify("end_killometers");
	level notify("end_duel");

	removeDuelOMeter();
	removeSpectatorHuds();

	// Announce winner
	if(isdefined(winner))
	{
		iprintlnbold(winner.name + "^7 is the Last Man Standing!");
		if(level.killwinner && isDefined(winner) && isAlive(winner))
		{
			winner suicide();
		}
		if(isdefined(winner))
		{
			winner.score++;
			winner notify("update_playerhud_score");
		}
		winner thread removeDuelHud();
	}
	else
	{
		iprintlnbold("No one managed to stay alive.");
	}
	wait 5;

	if(isdefined(winner))
		winner checkScoreLimit();

	// Did the map end?
	if(level.mapended)	return;

	// Reset player flags for dead players
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isAlive(player))
			player.havespawned = undefined;

		player.killometer = level.killometer;
		player updateKillOMeter();
	}

	// Restart the kill-o-meter for the winner if still alive
	if(isDefined(winner) && isAlive(winner))
		winner thread killometer();

	// Start a new join period
	level notify("end_watchJoinPeriod");
	wait .05;
	level.joinperiod = false;
	level thread watchJoinPeriod();

	level.endingmatch = false;
}

killOMeter()
{
	self endon("disconnect");
	self endon("spawned");
	self endon("killed_player");
	level endon("end_killometers");

	// Avoid duplicate threads, happens sometimes, reason unknown
	self notify("end_killometer");
	wait .05;
	self endon("end_killometer");

	self.killometer = level.killometer;
	self setupKillOMeter();

	while(isAlive(self) && self.sessionstate == "playing")
	{
		updateKillOMeter();
		wait 1;
		if(self.killometer && !level.joinperiod)
			self.killometer--;
		else if(!self.killometer)
			self suicide();
	}
	self removeKillOMeter();
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

removeKillOMeter()
{
	if(isdefined(self.komback)) self.komback destroy();
	if(isdefined(self.komfront)) self.komfront destroy();
	if(isdefined(self.komtext)) self.komtext destroy();
}

setupKillOMeter()
{
	y = 10;
	barsize = 300;
	
	self.oldbarsize = barsize;

	self removeKillOMeter();

	self.komback = newClientHudElem(self);
	self.komback.x = 320;
	self.komback.y = y;
	self.komback.alignX = "center";
	self.komback.alignY = "middle";
	self.komback.alpha = 0.3;
	self.komback.color = (0.2,0.2,0.2);
	self.komback setShader("white", barsize+4, 12);			

	self.komfront = newClientHudElem(self);
	self.komfront.x = 320;
	self.komfront.y = y;
	self.komfront.alignX = "center";
	self.komfront.alignY = "middle";
	self.komfront.color = (0,1,0);
	self.komfront.alpha = 0.5;
	self.komfront setShader("white", barsize, 10);

	self.komtext = newClientHudElem(self);
	self.komtext.x = 320;
	self.komtext.y = y;
	self.komtext.alignX = "center";
	self.komtext.alignY = "middle";
	self.komtext.alpha = 0.8;
	self.komtext.color = (1,1,1);
	self.komtext setText(&"Kill-O-Meter");			
}

updateKillOMeter()
{
	y = 10;
	barsize = 300;
	

	if(isdefined(self.komfront))
	{
/*		if(level.duel)
		{
			pc = level.dueltimeleft/level.duelperiodtime;
			self.komtext setText(&"Duel-O-Meter");			
			self.komfront.color = (1,1*pc,0);
		}
		else*/

		if(level.joinperiod)
		{
			pc = level.jointimeleft/level.joinperiodtime;
			self.komtext setText(&"Join-O-Meter");			
			self.komfront.color = (0,0,1);
		}
		else
		{
			pc = self.killometer/level.killometer;
			if(pc>=0.55)
			{
				c = 1 - (pc - 0.55)/0.45;
				self.komfront.color = (1*c,1,0);
				self.komtext setText(&"Kill-O-Meter");			
			}
			else if(pc>=0.1)
			{
				c = (pc-0.1)/0.45;
				self.komfront.color = (1,1*c,0);
				self.komtext setText(&"Kill-O-Meter");			
			}
			else
			{
				self.komtext setText(&"Die-O-Meter");			
				self.komfront.color = (1,0,0);
			}
		}
		size = int(barsize * pc + 0.5);
		if(size < 1) size = 1;
		if(self.oldbarsize != size)
		{
			self.komfront scaleOverTime(1, size, 10);
			self.oldbarsize = barsize;
		}
	}
}

duel(p1, p2)
{
	level notify("end_duel");
	level endon("end_duel");
	if(level.duel) return;
	level.duel = true;
	level.dueltimeleft = level.duelperiodtime;

	// End join period
	level notify("end_watchJoinPeriod");
	level.joinperiod = false;

	iprintlnbold("Only two players remain. Entering duel mode. (" + level.duelperiodtime + " seconds)");

	if(isDefined(p1) && isAlive(p1) && isDefined(p2) && isAlive(p2))
	{
		p1 notify("end_killometer");
		p2 notify("end_killometer");
		p1 removeKillOMeter();
		p2 removeKillOMeter();
		p1 thread duelHud(p2);
		p2 thread duelHud(p1);
	}

	setupDuelOMeter();

	setupSpectatorHuds(p1,p2);

	for(i=0;i<level.duelperiodtime;i++)
	{
		level.dueltimeleft = level.duelperiodtime - i;
		updateDuelOMeter();
		wait 1;
	}

	// If we get here then there is no winners, kill the loosers...
	iprintlnbold("This sucks... Killing duellists.");
	p1.nowinner = true;
	p1 suicide();
	p2 suicide();

	// End match without winner
	endMatch(undefined);
}

duelHud(other)
{
	self endon("end_duelhud");

	size = 70;
	y = 60;

//	other.dh_dist = 0;
	other.dh_weapon = &"None";
	other.dh_ammo = 0;

	titlecolor = (1,1,1);
	subtitlecolor = (0.8,0.8,0.8);
	valuecolor = (1,1,0);

	self.duelback = newClientHudElem(self);
	self.duelback.x = 0;
	self.duelback.y = y;
	self.duelback.alignX = "left";
	self.duelback.alignY = "top";
	self.duelback.alpha = 0.3;
	self.duelback.color = (0,0,0.2);
	self.duelback setShader("white", 1, 135);			
	self.duelback scaleOverTime(1, size , 135);

	wait 1;

	if(!isdefined(self) || !isdefined(other) || !isAlive(self) || !isAlive(other)) return;

	dist = int(distance(self.origin, other.origin) * 0.0254 + 0.5);
	cw = other getCurrentWeapon();
	weapon = weaponType(cw);
	ammo = other getammocount(cw);

//	other.dh_dist = dist;
	other.dh_weapon = weapon;
	other.dh_ammo = ammo;

	self.dueltitle = newClientHudElem(self);
	self.dueltitle.x = size/2;
	self.dueltitle.y = y+2;
	self.dueltitle.alignX = "center";
	self.dueltitle.alignY = "top";
	self.dueltitle.alpha = 0;
	self.dueltitle.color = titlecolor;
	self.dueltitle setText(&"Opponent Info");			
	self.dueltitle fadeOverTime(1);
	self.dueltitle.alpha = 1;

	self.dueldist = newClientHudElem(self);
	self.dueldist.x = size/2;
	self.dueldist.y = y+17;
	self.dueldist.alignX = "center";
	self.dueldist.alignY = "top";
	self.dueldist.alpha = 0;
	self.dueldist.color = subtitlecolor;
	self.dueldist setText(&"Distance(m)");			
	self.dueldist fadeOverTime(2);
	self.dueldist.alpha = 1;

	self.dueldist2 = newClientHudElem(self);
	self.dueldist2.x = size/2;
	self.dueldist2.y = y+30;
	self.dueldist2.alignX = "center";
	self.dueldist2.alignY = "top";
	self.dueldist2.alpha = 0;
	self.dueldist2.color = valuecolor;
	self.dueldist2 setValue(dist);			
	self.dueldist2 fadeOverTime(2);
	self.dueldist2.alpha = 0.8;
	
	self.duelhealth = newClientHudElem(self);
	self.duelhealth.x = size/2;
	self.duelhealth.y = y + 47;
	self.duelhealth.alignX = "center";
	self.duelhealth.alignY = "top";
	self.duelhealth.alpha = 0;
	self.duelhealth.color = subtitlecolor;
	self.duelhealth setText(&"Health");			
	self.duelhealth fadeOverTime(2);
	self.duelhealth.alpha = 0.8;

	self.duelhealth2 = newClientHudElem(self);
	self.duelhealth2.x = size/2;
	self.duelhealth2.y = y + 60;
	self.duelhealth2.alignX = "center";
	self.duelhealth2.alignY = "top";
	self.duelhealth2.alpha = 0;
	self.duelhealth2.color = valuecolor;
	self.duelhealth2 setValue(other.health);			
	self.duelhealth2 fadeOverTime(2);
	self.duelhealth2.alpha = 0.8;

	self.duelweapon = newClientHudElem(self);
	self.duelweapon.x = size/2;
	self.duelweapon.y = y + 77;
	self.duelweapon.alignX = "center";
	self.duelweapon.alignY = "top";
	self.duelweapon.alpha = 0;
	self.duelweapon.color = subtitlecolor;
	self.duelweapon setText(&"Weapon");			
	self.duelweapon fadeOverTime(2);
	self.duelweapon.alpha = 0.8;

	self.duelweapon2 = newClientHudElem(self);
	self.duelweapon2.x = size/2;
	self.duelweapon2.y = y + 90;
	self.duelweapon2.alignX = "center";
	self.duelweapon2.alignY = "top";
	self.duelweapon2.alpha = 0;
	self.duelweapon2.color = valuecolor;
	self.duelweapon2 setText(weapon);			
	self.duelweapon2 fadeOverTime(2);
	self.duelweapon2.alpha = 0.8;

	self.duelammo = newClientHudElem(self);
	self.duelammo.x = size/2;
	self.duelammo.y = y + 107;
	self.duelammo.alignX = "center";
	self.duelammo.alignY = "top";
	self.duelammo.alpha = 0;
	self.duelammo.color = subtitlecolor;
	self.duelammo setText(&"Ammo");			
	self.duelammo fadeOverTime(2);
	self.duelammo.alpha = 0.8;

	self.duelammo2 = newClientHudElem(self);
	self.duelammo2.x = size/2;
	self.duelammo2.y = y + 120;
	self.duelammo2.alignX = "center";
	self.duelammo2.alignY = "top";
	self.duelammo2.alpha = 0;
	self.duelammo2.color = valuecolor;
	self.duelammo2 setValue(ammo);			
	self.duelammo2 fadeOverTime(2);
	self.duelammo2.alpha = 0.8;

	while(isdefined(self) && isAlive(self) && self.sessionstate == "playing" && isdefined(other) && isAlive(other) && other.sessionstate == "playing")
	{
		dist = int(distance(self.origin, other.origin) * 0.0254 + 0.5);
		self.dueldist2 setValue(dist);			
		self.duelhealth2 setValue(other.health);			

		cw = other getCurrentWeapon();
		weapon = weaponType(cw);
		ammo = other getammocount(cw);
		self.duelweapon2 setText(weapon);			
		self.duelammo2 setValue(ammo);			

//		other.dh_dist = dist;
		other.dh_weapon = weapon;
		other.dh_ammo = ammo;

		wait .05;
	}
}

removeDuelHud()
{
	// End thread
	self notify("end_duelhud");

	// Fade away text
	if(isdefined(self.dueltitle))
	{
		self.dueltitle fadeOverTime(1);
		self.dueltitle.alpha = 0;
	}
	if(isdefined(self.dueldist))
	{
		self.dueldist fadeOverTime(1);
		self.dueldist.alpha = 0;
	}
	if(isdefined(self.dueldist2))
	{
		self.dueldist2 fadeOverTime(1);
		self.dueldist2.alpha = 0;
	}
	if(isdefined(self.duelhealth))
	{
		self.duelhealth fadeOverTime(1);
		self.duelhealth.alpha = 0;
	}
	if(isdefined(self.duelhealth2))
	{
		self.duelhealth2 fadeOverTime(1);
		self.duelhealth2.alpha = 0;
	}
	if(isdefined(self.duelweapon))
	{
		self.duelweapon fadeOverTime(1);
		self.duelweapon.alpha = 0;
	}
	if(isdefined(self.duelweapon2))
	{
		self.duelweapon2 fadeOverTime(1);
		self.duelweapon2.alpha = 0;
	}
	if(isdefined(self.duelammo))
	{
		self.duelammo fadeOverTime(1);
		self.duelammo.alpha = 0;
	}
	if(isdefined(self.duelammo2))
	{
		self.duelammo2 fadeOverTime(1);
		self.duelammo2.alpha = 0;
	}
	wait 1;

	if(isdefined(self.duelback))
		self.duelback scaleOverTime(1, 1 , 135);

	wait 1;

	// Remove HUD elements
	if(isdefined(self.duelback)) self.duelback destroy();
	if(isdefined(self.dueldist)) self.dueldist destroy();
	if(isdefined(self.dueldist2)) self.dueldist2 destroy();
	if(isdefined(self.duelhealth)) self.duelhealth destroy();
	if(isdefined(self.duelhealth2)) self.duelhealth2 destroy();
	if(isdefined(self.duelweapon)) self.duelweapon destroy();
	if(isdefined(self.duelweapon2)) self.duelweapon2 destroy();
	if(isdefined(self.duelammo)) self.duelammo destroy();
	if(isdefined(self.duelammo2)) self.duelammo2 destroy();
	if(isdefined(self.dueltitle)) self.dueltitle destroy();
}

weaponType(cw)
{
	weapon = &"None";
	switch(cw)
	{
		case "enfield_mp":
		case "g43_mp":
		case "kar98k_mp":
		case "m1carbine_mp":
		case "m1garand_mp":
		case "mosin_nagant_mp":
		case "svt40_mp":
			weapon = &"Rifle";
			break;

		case "greasegun_mp":
		case "mp40_mp":
		case "sten_mp":
		case "thompson_mp":
		case "pps42_mp":
		case "mp44_mp":
		case "bar_mp":
		case "bren_mp":
		case "ppsh_mp":
			weapon = &"Machinegun";
			break;

		case "mosin_nagant_sniper_mp":
		case "springfield_mp":
		case "kar98k_sniper_mp":
		case "enfield_scope_mp":
			weapon = &"Sniper";
			break;

		case "shotgun_mp":
			weapon = &"Shotgun";
			break;

		case "colt_mp":
		case "luger_mp":
		case "tt30_mp":
		case "webley_mp":
			weapon = &"Pistol";
			break;

		default:
			if(cw == level.awe_sprintweapon)
				weapon = &"Sprinting";
			break;
	}
	return weapon;
}

removeDuelOMeter()
{
	if(isdefined(level.duelback)) level.duelback destroy();
	if(isdefined(level.duelfront)) level.duelfront destroy();
	if(isdefined(level.dueltext)) level.dueltext destroy();
}

setupDuelOMeter()
{
	y = 10;
	barsize = 300;
	
	level.oldbarsize = barsize;

	level removeDuelOMeter();

	level.duelback = newHudElem();
	level.duelback.x = 320;
	level.duelback.y = y;
	level.duelback.alignX = "center";
	level.duelback.alignY = "middle";
	level.duelback.alpha = 0.3;
	level.duelback.color = (0.2,0.2,0.2);
	level.duelback setShader("white", barsize+4, 12);			

	level.duelfront = newHudElem();
	level.duelfront.x = 320;
	level.duelfront.y = y;
	level.duelfront.alignX = "center";
	level.duelfront.alignY = "middle";
	level.duelfront.color = (1,1,0);
	level.duelfront.alpha = 0.5;
	level.duelfront setShader("white", barsize, 10);

	level.dueltext = newHudElem();
	level.dueltext.x = 320;
	level.dueltext.y = y;
	level.dueltext.alignX = "center";
	level.dueltext.alignY = "middle";
	level.dueltext.alpha = 0.8;
	level.dueltext.color = (1,1,1);
	level.dueltext setText(&"Duel-O-Meter");			
}

updateDuelOMeter()
{
	y = 10;
	barsize = 300;
	
	if(isdefined(level.duelfront))
	{
		pc = level.dueltimeleft/level.duelperiodtime;
		level.duelfront.color = (1,1*pc,0);

		size = int(barsize * pc + 0.5);
		if(size < 1) size = 1;
		if(level.oldbarsize != size)
		{
			level.duelfront scaleOverTime(1, size, 10);
			level.oldbarsize = barsize;
		}
	}
}

setupSpectatorHuds(a,b)
{
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isDefined(player) && !isAlive(player))
		{
			player thread spectatorHud(a,b);
		}
	}
}

spectatorHud(a,b)
{
	self endon("end_spectatorhud");

	self.spectatorhud = true;

	size = 70;
	y = 60;

	titlecolor = (1,1,1);
	subtitlecolor = (0.8,0.8,0.8);
	valuecolor = (0,0.8,0);
	valuecolor2 = (0.8,0,0);

	self.spectatorback = newClientHudElem(self);
	self.spectatorback.x = 0;
	self.spectatorback.y = y;
	self.spectatorback.alignX = "left";
	self.spectatorback.alignY = "top";
	self.spectatorback.alpha = 0.3;
	self.spectatorback.color = (0,0.2,0);
	self.spectatorback setShader("white", 1, 135);			
	self.spectatorback scaleOverTime(1, size , 135);

	self.spectator2back = newClientHudElem(self);
	self.spectator2back.x = 640;
	self.spectator2back.y = y;
	self.spectator2back.alignX = "right";
	self.spectator2back.alignY = "top";
	self.spectator2back.alpha = 0.3;
	self.spectator2back.color = (0.2,0,0);
	self.spectator2back setShader("white", 1, 135);			
	self.spectator2back scaleOverTime(1, size , 135);

	wait 1;

	if(!isdefined(a) || !isdefined(b) || !isAlive(a) || !isAlive(b)) return;

	dist = int(distance(self.origin, a.origin) * 0.0254 + 0.5);
//	dist = a.dh_dist;
	weapon = a.dh_weapon;
	ammo = a.dh_ammo;

	self.spectatortitle = newClientHudElem(self);
	self.spectatortitle.x = size/2;
	self.spectatortitle.y = y+2;
	self.spectatortitle.alignX = "center";
	self.spectatortitle.alignY = "top";
	self.spectatortitle.alpha = 0;
	self.spectatortitle.color = titlecolor;
	self.spectatortitle setText(&"Player ^3A");			
	self.spectatortitle fadeOverTime(1);
	self.spectatortitle.alpha = 1;

	self.spectatordist = newClientHudElem(self);
	self.spectatordist.x = size/2;
	self.spectatordist.y = y+17;
	self.spectatordist.alignX = "center";
	self.spectatordist.alignY = "top";
	self.spectatordist.alpha = 0;
	self.spectatordist.color = subtitlecolor;
	self.spectatordist setText(&"Distance(m)");			
	self.spectatordist fadeOverTime(2);
	self.spectatordist.alpha = 1;

	self.spectatordist2 = newClientHudElem(self);
	self.spectatordist2.x = size/2;
	self.spectatordist2.y = y+30;
	self.spectatordist2.alignX = "center";
	self.spectatordist2.alignY = "top";
	self.spectatordist2.alpha = 0;
	self.spectatordist2.color = valuecolor;
	self.spectatordist2 setValue(dist);			
	self.spectatordist2 fadeOverTime(2);
	self.spectatordist2.alpha = 0.8;
	
	self.spectatorhealth = newClientHudElem(self);
	self.spectatorhealth.x = size/2;
	self.spectatorhealth.y = y + 47;
	self.spectatorhealth.alignX = "center";
	self.spectatorhealth.alignY = "top";
	self.spectatorhealth.alpha = 0;
	self.spectatorhealth.color = subtitlecolor;
	self.spectatorhealth setText(&"Health");			
	self.spectatorhealth fadeOverTime(2);
	self.spectatorhealth.alpha = 0.8;

	self.spectatorhealth2 = newClientHudElem(self);
	self.spectatorhealth2.x = size/2;
	self.spectatorhealth2.y = y + 60;
	self.spectatorhealth2.alignX = "center";
	self.spectatorhealth2.alignY = "top";
	self.spectatorhealth2.alpha = 0;
	self.spectatorhealth2.color = valuecolor;
	self.spectatorhealth2 setValue(a.health);			
	self.spectatorhealth2 fadeOverTime(2);
	self.spectatorhealth2.alpha = 0.8;

	self.spectatorweapon = newClientHudElem(self);
	self.spectatorweapon.x = size/2;
	self.spectatorweapon.y = y + 77;
	self.spectatorweapon.alignX = "center";
	self.spectatorweapon.alignY = "top";
	self.spectatorweapon.alpha = 0;
	self.spectatorweapon.color = subtitlecolor;
	self.spectatorweapon setText(&"Weapon");			
	self.spectatorweapon fadeOverTime(2);
	self.spectatorweapon.alpha = 0.8;

	self.spectatorweapon2 = newClientHudElem(self);
	self.spectatorweapon2.x = size/2;
	self.spectatorweapon2.y = y + 90;
	self.spectatorweapon2.alignX = "center";
	self.spectatorweapon2.alignY = "top";
	self.spectatorweapon2.alpha = 0;
	self.spectatorweapon2.color = valuecolor;
	self.spectatorweapon2 setText(weapon);			
	self.spectatorweapon2 fadeOverTime(2);
	self.spectatorweapon2.alpha = 0.8;

	self.spectatorammo = newClientHudElem(self);
	self.spectatorammo.x = size/2;
	self.spectatorammo.y = y + 107;
	self.spectatorammo.alignX = "center";
	self.spectatorammo.alignY = "top";
	self.spectatorammo.alpha = 0;
	self.spectatorammo.color = subtitlecolor;
	self.spectatorammo setText(&"Ammo");			
	self.spectatorammo fadeOverTime(2);
	self.spectatorammo.alpha = 0.8;

	self.spectatorammo2 = newClientHudElem(self);
	self.spectatorammo2.x = size/2;
	self.spectatorammo2.y = y + 120;
	self.spectatorammo2.alignX = "center";
	self.spectatorammo2.alignY = "top";
	self.spectatorammo2.alpha = 0;
	self.spectatorammo2.color = valuecolor;
	self.spectatorammo2 setValue(ammo);			
	self.spectatorammo2 fadeOverTime(2);
	self.spectatorammo2.alpha = 0.8;

	dist = int(distance(self.origin, b.origin) * 0.0254 + 0.5);
//	dist = b.dh_dist;
	weapon = b.dh_weapon;
	ammo = b.dh_ammo;

	self.spectator2title = newClientHudElem(self);
	self.spectator2title.x = 640-size/2;
	self.spectator2title.y = y+2;
	self.spectator2title.alignX = "center";
	self.spectator2title.alignY = "top";
	self.spectator2title.alpha = 0;
	self.spectator2title.color = titlecolor;
	self.spectator2title setText(&"Player ^3B");			
	self.spectator2title fadeOverTime(1);
	self.spectator2title.alpha = 1;

	self.spectator2dist = newClientHudElem(self);
	self.spectator2dist.x = 640-size/2;
	self.spectator2dist.y = y+17;
	self.spectator2dist.alignX = "center";
	self.spectator2dist.alignY = "top";
	self.spectator2dist.alpha = 0;
	self.spectator2dist.color = subtitlecolor;
	self.spectator2dist setText(&"Distance(m)");			
	self.spectator2dist fadeOverTime(2);
	self.spectator2dist.alpha = 1;

	self.spectator2dist2 = newClientHudElem(self);
	self.spectator2dist2.x = 640-size/2;
	self.spectator2dist2.y = y+30;
	self.spectator2dist2.alignX = "center";
	self.spectator2dist2.alignY = "top";
	self.spectator2dist2.alpha = 0;
	self.spectator2dist2.color = valuecolor2;
	self.spectator2dist2 setValue(dist);			
	self.spectator2dist2 fadeOverTime(2);
	self.spectator2dist2.alpha = 0.8;
	
	self.spectator2health = newClientHudElem(self);
	self.spectator2health.x = 640-size/2;
	self.spectator2health.y = y + 47;
	self.spectator2health.alignX = "center";
	self.spectator2health.alignY = "top";
	self.spectator2health.alpha = 0;
	self.spectator2health.color = subtitlecolor;
	self.spectator2health setText(&"Health");			
	self.spectator2health fadeOverTime(2);
	self.spectator2health.alpha = 0.8;

	self.spectator2health2 = newClientHudElem(self);
	self.spectator2health2.x = 640-size/2;
	self.spectator2health2.y = y + 60;
	self.spectator2health2.alignX = "center";
	self.spectator2health2.alignY = "top";
	self.spectator2health2.alpha = 0;
	self.spectator2health2.color = valuecolor2;
	self.spectator2health2 setValue(b.health);			
	self.spectator2health2 fadeOverTime(2);
	self.spectator2health2.alpha = 0.8;

	self.spectator2weapon = newClientHudElem(self);
	self.spectator2weapon.x = 640-size/2;
	self.spectator2weapon.y = y + 77;
	self.spectator2weapon.alignX = "center";
	self.spectator2weapon.alignY = "top";
	self.spectator2weapon.alpha = 0;
	self.spectator2weapon.color = subtitlecolor;
	self.spectator2weapon setText(&"Weapon");			
	self.spectator2weapon fadeOverTime(2);
	self.spectator2weapon.alpha = 0.8;

	self.spectator2weapon2 = newClientHudElem(self);
	self.spectator2weapon2.x = 640-size/2;
	self.spectator2weapon2.y = y + 90;
	self.spectator2weapon2.alignX = "center";
	self.spectator2weapon2.alignY = "top";
	self.spectator2weapon2.alpha = 0;
	self.spectator2weapon2.color = valuecolor2;
	self.spectator2weapon2 setText(weapon);			
	self.spectator2weapon2 fadeOverTime(2);
	self.spectator2weapon2.alpha = 0.8;

	self.spectator2ammo = newClientHudElem(self);
	self.spectator2ammo.x = 640-size/2;
	self.spectator2ammo.y = y + 107;
	self.spectator2ammo.alignX = "center";
	self.spectator2ammo.alignY = "top";
	self.spectator2ammo.alpha = 0;
	self.spectator2ammo.color = subtitlecolor;
	self.spectator2ammo setText(&"Ammo");			
	self.spectator2ammo fadeOverTime(2);
	self.spectator2ammo.alpha = 0.8;

	self.spectator2ammo2 = newClientHudElem(self);
	self.spectator2ammo2.x = 640-size/2;
	self.spectator2ammo2.y = y + 120;
	self.spectator2ammo2.alignX = "center";
	self.spectator2ammo2.alignY = "top";
	self.spectator2ammo2.alpha = 0;
	self.spectator2ammo2.color = valuecolor2;
	self.spectator2ammo2 setValue(ammo);			
	self.spectator2ammo2 fadeOverTime(2);
	self.spectator2ammo2.alpha = 0.8;

// Add objective points
	self.objpointa = newClientHudElem(self);
	self.objpointa.name = "PlayerA";
	self.objpointa.x = a.origin[0];
	self.objpointa.y = a.origin[1];
	self.objpointa.z = a.origin[2] + 70;
	self.objpointa.alpha = .61;
	self.objpointa.archived = false;
	self.objpointa setShader("objpoint_A", 14, 14);
	self.objpointa setwaypoint(true);

	self.objpointb = newClientHudElem(self);
	self.objpointb.name = "PlayerB";
	self.objpointb.x = b.origin[0];
	self.objpointb.y = b.origin[1];
	self.objpointb.z = b.origin[2] + 70;
	self.objpointb.alpha = .61;
	self.objpointb.archived = false;
	self.objpointb setShader("objpoint_B", 14, 14);
	self.objpointb setwaypoint(true);


	while(isdefined(a) && isAlive(a) && a.sessionstate == "playing" && isdefined(b) && isAlive(b) && b.sessionstate == "playing")
	{
		dist = int(distance(self.origin, a.origin) * 0.0254 + 0.5);
//		dist = a.dh_dist;
		weapon = a.dh_weapon;
		ammo = a.dh_ammo;
		self.spectatordist2 setValue(dist);			
		self.spectatorhealth2 setValue(a.health);			
		self.spectatorweapon2 setText(weapon);			
		self.spectatorammo2 setValue(ammo);			

		self.objpointa.x = a.origin[0];
		self.objpointa.y = a.origin[1];
		self.objpointa.z = a.origin[2] + 70;

		dist = int(distance(self.origin, b.origin) * 0.0254 + 0.5);
//		dist = b.dh_dist;
		weapon = b.dh_weapon;
		ammo = b.dh_ammo;
		self.spectator2dist2 setValue(dist);			
		self.spectator2health2 setValue(b.health);			
		self.spectator2weapon2 setText(weapon);			
		self.spectator2ammo2 setValue(ammo);			

		self.objpointb.x = b.origin[0];
		self.objpointb.y = b.origin[1];
		self.objpointb.z = b.origin[2] + 70;

		wait .05;
	}
}

removeSpectatorHuds()
{
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isDefined(player) && isdefined(player.spectatorhud))
		{
			player thread removeSpectatorHud();
		}
	}
}

removeSpectatorHud()
{
	// End thread
	self notify("end_spectatorhud");

	self.spectatorhud = undefined;

	// Remove objective points
	if(isdefined(self.objpointa)) self.objpointa destroy();
	if(isdefined(self.objpointb)) self.objpointb destroy();

	// Fade away text
	if(isdefined(self.spectatortitle))
	{
		self.spectatortitle fadeOverTime(1);
		self.spectatortitle.alpha = 0;
	}
	if(isdefined(self.spectatordist))
	{
		self.spectatordist fadeOverTime(1);
		self.spectatordist.alpha = 0;
	}
	if(isdefined(self.spectatordist2))
	{
		self.spectatordist2 fadeOverTime(1);
		self.spectatordist2.alpha = 0;
	}
	if(isdefined(self.spectatorhealth))
	{
		self.spectatorhealth fadeOverTime(1);
		self.spectatorhealth.alpha = 0;
	}
	if(isdefined(self.spectatorhealth2))
	{
		self.spectatorhealth2 fadeOverTime(1);
		self.spectatorhealth2.alpha = 0;
	}
	if(isdefined(self.spectatorweapon))
	{
		self.spectatorweapon fadeOverTime(1);
		self.spectatorweapon.alpha = 0;
	}
	if(isdefined(self.spectatorweapon2))
	{
		self.spectatorweapon2 fadeOverTime(1);
		self.spectatorweapon2.alpha = 0;
	}
	if(isdefined(self.spectatorammo))
	{
		self.spectatorammo fadeOverTime(1);
		self.spectatorammo.alpha = 0;
	}
	if(isdefined(self.spectatorammo2))
	{
		self.spectatorammo2 fadeOverTime(1);
		self.spectatorammo2.alpha = 0;
	}

	if(isdefined(self.spectator2title))
	{
		self.spectator2title fadeOverTime(1);
		self.spectator2title.alpha = 0;
	}
	if(isdefined(self.spectator2dist))
	{
		self.spectator2dist fadeOverTime(1);
		self.spectator2dist.alpha = 0;
	}
	if(isdefined(self.spectator2dist2))
	{
		self.spectator2dist2 fadeOverTime(1);
		self.spectator2dist2.alpha = 0;
	}
	if(isdefined(self.spectator2health))
	{
		self.spectator2health fadeOverTime(1);
		self.spectator2health.alpha = 0;
	}
	if(isdefined(self.spectator2health2))
	{
		self.spectator2health2 fadeOverTime(1);
		self.spectator2health2.alpha = 0;
	}
	if(isdefined(self.spectator2weapon))
	{
		self.spectator2weapon fadeOverTime(1);
		self.spectator2weapon.alpha = 0;
	}
	if(isdefined(self.spectator2weapon2))
	{
		self.spectator2weapon2 fadeOverTime(1);
		self.spectator2weapon2.alpha = 0;
	}
	if(isdefined(self.spectator2ammo))
	{
		self.spectator2ammo fadeOverTime(1);
		self.spectator2ammo.alpha = 0;
	}
	if(isdefined(self.spectator2ammo2))
	{
		self.spectator2ammo2 fadeOverTime(1);
		self.spectator2ammo2.alpha = 0;
	}
	wait 1;

	if(isdefined(self.spectatorback))
		self.spectatorback scaleOverTime(1, 1 , 135);

	if(isdefined(self.spectator2back))
		self.spectator2back scaleOverTime(1, 1 , 135);

	wait 1;

	// Remove HUD elements
	if(isdefined(self.spectatorback)) self.spectatorback destroy();
	if(isdefined(self.spectatordist)) self.spectatordist destroy();
	if(isdefined(self.spectatordist2)) self.spectatordist2 destroy();
	if(isdefined(self.spectatorhealth)) self.spectatorhealth destroy();
	if(isdefined(self.spectatorhealth2)) self.spectatorhealth2 destroy();
	if(isdefined(self.spectatorweapon)) self.spectatorweapon destroy();
	if(isdefined(self.spectatorweapon2)) self.spectatorweapon2 destroy();
	if(isdefined(self.spectatorammo)) self.spectatorammo destroy();
	if(isdefined(self.spectatorammo2)) self.spectatorammo2 destroy();
	if(isdefined(self.spectatortitle)) self.spectatortitle destroy();

	if(isdefined(self.spectator2back)) self.spectator2back destroy();
	if(isdefined(self.spectator2dist)) self.spectator2dist destroy();
	if(isdefined(self.spectator2dist2)) self.spectator2dist2 destroy();
	if(isdefined(self.spectator2health)) self.spectator2health destroy();
	if(isdefined(self.spectator2health2)) self.spectator2health2 destroy();
	if(isdefined(self.spectator2weapon)) self.spectator2weapon destroy();
	if(isdefined(self.spectator2weapon2)) self.spectator2weapon2 destroy();
	if(isdefined(self.spectator2ammo)) self.spectator2ammo destroy();
	if(isdefined(self.spectator2ammo2)) self.spectator2ammo2 destroy();
	if(isdefined(self.spectator2title)) self.spectator2title destroy();
}
