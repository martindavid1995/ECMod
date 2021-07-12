// Modified by La Truffe

/*
	Hold the Flag 1.0
	Author: bell (http://awe.milliways.st)

	Objective: 	Score points for your team by holding the flag within your team
	Map ends:	When one team reaches the score limit, or time limit is reached
	Respawning:	Instant / At base / Near teammates

	Level requirements
	------------------
		Spawnpoints:
			classname		mp_tdm_spawn
			All players spawn from these. The spawnpoint chosen is dependent on the current locations of teammates and enemies
			at the time of spawn. Players generally spawn behind their teammates relative to the direction of enemies.

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
*/

/*QUAKED mp_tdm_spawn (0.0 0.0 1.0) (-16 -16 0) (16 16 72)
Players spawn away from enemies and near their team at one of these positions.*/

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
	if(!isDefined(game["allies"]))
		game["allies"] = "american";
	if(!isDefined(game["axis"]))
		game["axis"] = "german";

	// server cvar overrides
	if(getCvar("scr_allies") != "")
		game["allies"] = getCvar("scr_allies");
	if(getCvar("scr_axis") != "")
		game["axis"] = getCvar("scr_axis");

	level.compassflag_allies = "compass_flag_" + game["allies"];
	level.compassflag_axis = "compass_flag_" + game["axis"];
	level.compassflag_none	= "objective";
	level.objpointflag_allies = "objpoint_flag_" + game["allies"];
	level.objpointflag_axis = "objpoint_flag_" + game["axis"];
	level.objpointflag_none = "objpoint_star";
	level.hudflag_allies = "compass_flag_" + game["allies"];
	level.hudflag_axis = "compass_flag_" + game["axis"];
	

	precacheShader("white");
	precacheStatusIcon("hud_status_dead");
	precacheStatusIcon("hud_status_connecting");
	precacheRumble("damage_heavy");
	precacheShader(level.compassflag_allies);
	precacheShader(level.compassflag_axis);
	precacheShader(level.compassflag_none);
	precacheShader(level.objpointflag_allies);
	precacheShader(level.objpointflag_axis);
	precacheShader(level.objpointflag_none);
	precacheShader(level.hudflag_allies);
	precacheShader(level.hudflag_axis);
	precacheStatusIcon(level.hudflag_allies);
	precacheStatusIcon(level.hudflag_axis);
	precacheModel("xmodel/prop_flag_" + game["allies"]);
	precacheModel("xmodel/prop_flag_" + game["axis"]);
	precacheModel("xmodel/prop_flag_" + game["allies"] + "_carry");
	precacheModel("xmodel/prop_flag_" + game["axis"] + "_carry");
	precacheString(&"MP_TIME_TILL_SPAWN");
	precacheString(&"MP_CTF_OBJ_TEXT");
	precacheString(&"PLATFORM_PRESS_TO_SPAWN");

	thread maps\mp\gametypes\_menus::init();
	thread maps\mp\gametypes\_serversettings::init();
	thread maps\mp\gametypes\_clientids::init();
	thread maps\mp\gametypes\_teams::init();
	thread maps\mp\gametypes\_weapons::init();
	thread maps\mp\gametypes\_scoreboard::init();
	thread maps\mp\gametypes\_killcam::init();
	thread maps\mp\gametypes\_shellshock::init();
	if(cvardef("scr_htf_teamscore", 0, 0, 1, "int"))
		thread maps\mp\gametypes\_hud_teamscore::init();
	thread maps\mp\gametypes\_deathicons::init();
	thread maps\mp\gametypes\_damagefeedback::init();
	thread maps\mp\gametypes\_healthoverlay::init();
	thread maps\mp\gametypes\_friendicons::init();
	thread maps\mp\gametypes\_spectating::init();
	thread maps\mp\gametypes\_grenadeindicators::init();

	precacheShader(game["headicon_allies"]);
	precacheShader(game["headicon_axis"]);

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

	allowed[0] = "tdm";
	maps\mp\gametypes\_gameobjects::main(allowed);

	// Time limit per map
	level.timelimit = cvardef("scr_htf_timelimit",20,0,1440,"float");
// La Truffe ->
/*
	setCvar("ui_htf_timelimit", level.timelimit);
	makeCvarServerInfo("ui_htf_timelimit", "20");
*/
	setCvar("ui_timelimit", level.timelimit);
	makeCvarServerInfo("ui_timelimit", "20");
// La Truffe <-

	// Score limit per map
	level.scorelimit = cvardef("scr_htf_scorelimit",5,0,9999,"int");
// La Truffe ->
/*
	setCvar("ui_htf_scorelimit", level.scorelimit);
	makeCvarServerInfo("ui_htf_scorelimit", "5");
*/
	setCvar("ui_scorelimit", level.scorelimit);
	makeCvarServerInfo("ui_scorelimit", "5");
// La Truffe <-

	// Balance mode
	level.mode = cvardef("scr_htf_mode", 0, 0, 3, "int");

	// Max hold time
	level.holdtime = cvardef("scr_htf_holdtime", 90, 1, 99999, "int");
	level.teamholdtime["axis"] = 0;
	level.teamholdtime["allies"] = 0;
	level.oldteamholdtime["allies"] = level.teamholdtime["allies"];
	level.oldteamholdtime["axis"] = level.teamholdtime["axis"];

	// Flag spawn delay
	level.flagspawndelay = cvardef("scr_htf_flagspawndelay", 15, 0, 9999, "int");

	// Flag recover time
	level.flagrecovertime = cvardef("scr_htf_flagrecovertime", 0, 0, 9999, "int");

	// Remove spawnpoint which is used by the flag?
	level.removeflagspawns = cvardef("scr_htf_removeflagspawns", 1, 0, 1, "int");

	// Remove spawnpoint which is used by the flag?
	level.randomflagspawns = cvardef("scr_htf_randomflagspawns", 1, 0, 1, "int");

	// Force respawning
	level.forcerespawn = cvardef("scr_forcerespawn",0,0,60,"int");

	// Use objective points
	level.awe_objectivepoints = cvardef("awe_objective_points", 1, 0, 1, "int");

	if(!isDefined(game["state"]))
		game["state"] = "playing";

	level.mapended = false;

	level.team["allies"] = 0;
	level.team["axis"] = 0;

	level.hasspawned["axis"] = false;
	level.hasspawned["allies"] = false;
	level.hasspawned["flag"] = false;

	level.respawndelay = cvardef("scr_htf_respawndelay", 10, 0, 600, "int");;

	minefields = [];
	minefields = getentarray("minefield", "targetname");
	trigger_hurts = [];
	trigger_hurts = getentarray("trigger_hurt", "classname");

	level.flag_returners = minefields;
	for(i = 0; i < trigger_hurts.size; i++)
		level.flag_returners[level.flag_returners.size] = trigger_hurts[i];

	FindTeamSides();
	thread InitFlag();
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
	self dropFlag();

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

	if(isdefined(self.flag))
		flagcarrier = true;
	else
		flagcarrier = undefined;

	if(self.sessionteam == "spectator")
		return;

	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE")
		sMeansOfDeath = "MOD_HEAD_SHOT";

	// send out an obituary message to all clients about the kill
	obituary(self, attacker, sWeapon, sMeansOfDeath);

	self maps\mp\gametypes\_weapons::dropWeapon();
	self maps\mp\gametypes\_weapons::dropOffhand();

	self dropFlag();

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
			{
				attacker.score--;
				// Was the flagcarrier killed?
				if(isdefined(flagcarrier))
				{
					attacker announce("^1teamkilled ^7the flag carrier^7!");
					attacker.score--;
				}

			}
			else
			{
				attacker.score++;
				// Was the flagcarrier killed?
				if(isdefined(flagcarrier))
				{
					attacker announce("^7killed the flag carrier^7!");
					attacker.score++;
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

		self.score--;

		lpattacknum = -1;
		lpattackname = "";
		lpattackguid = "";
		lpattackerteam = "world";
	}

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

	// First player of each team spawn on specific teamside
	if(!level.hasspawned[self.sessionteam])
	{
		spawnpoint = maps\mp\gametypes\_spawnlogic::NearestSpawnpoint(spawnpoints, level.teamside[self.sessionteam]);
		level.hasspawned[self.sessionteam] = true;
	}
	else
	{
		// Else use TDM spawnlogic
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);
	}

	if(isDefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");

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

	if(!level.splitscreen)
	{
		if(level.scorelimit > 0)
			self setClientCvar("cg_objectiveText", &"HTF_OBJ_TEXT", level.scorelimit);
		else
			self setClientCvar("cg_objectiveText", &"HTF_OBJ_TEXT_NOSCORE");
	}
	else
		self setClientCvar("cg_objectiveText", &"HTF_OBJ_TEXT_NOSCORE");

	self thread updateTimer();

	waittillframeend;
	self notify("spawned_player");

	thread CheckForFlag();
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

	if(level.forcerespawn <= 0)
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
		timelimit = cvardef("scr_htf_timelimit",20,0,1440,"float");
		if(level.timelimit != timelimit)
		{
			level.timelimit = timelimit;
// La Truffe ->
//			setCvar("ui_htf_timelimit", level.timelimit);
			setCvar("ui_timelimit", level.timelimit);
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

		scorelimit = cvardef("scr_htf_scorelimit",5,0,9999,"int");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
// La Truffe ->
//			setCvar("ui_htf_scorelimit", level.scorelimit);
			setCvar("ui_scorelimit", level.scorelimit);
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


pickupFlag(flag)
{
	flag notify("end_autoreturn");

	// What is my team?
	myteam = self.sessionteam;
	if(myteam == "allies")
		otherteam = "axis";
	else
		otherteam = "allies";


	flag.origin = flag.origin + (0, 0, -10000);
	flag.flagmodel hide();
	flag.flagmodel setmodel("xmodel/prop_flag_" + game[myteam]);
	self.flag = flag;
	self.dont_auto_balance = true;


	flag.team = self.sessionteam;
	flag.atbase = false;

	if(myteam == "allies")
	{
		flag.compassflag = level.compassflag_allies;
		flag.objpointflag = level.objpointflag_allies;
	}
	else
	{
		flag.compassflag = level.compassflag_axis;
		flag.objpointflag = level.objpointflag_axis;
	}

	flag deleteFlagWaypoint();

	objective_icon(self.flag.objective, flag.compassflag);
	objective_team(self.flag.objective, myteam);

	// Make an identical objective but for the other team
	objective_add(self.flag.objective+1, "current", self.origin, flag.compassflag);
	objective_team(self.flag.objective+1, otherteam);

//	self playsound("health_pickup_medium");
//	sounds added by Ruud
	println("THE FLAG WAS STOLEN!");
	thread playSoundOnPlayers("ctf_touchenemy", myteam);
		if(!level.splitscreen)
			thread playSoundOnPlayers("ctf_enemy_touchenemy", otherteam);

	self attachFlag();
}

dropFlag()
{
	if(isdefined(self.flag))
	{
		start = self.origin + (0, 0, 10);
		end = start + (0, 0, -2000);
		trace = bulletTrace(start, end, false, undefined);

		self.flag.origin = trace["position"];
		self.flag.flagmodel.origin = self.flag.origin;
		self.flag.flagmodel show();
		self.flag.atbase = false;
		self.flag.stolen = false;

		// set compass flag position on player
		objective_position(self.flag.objective, self.flag.origin);
		objective_state(self.flag.objective, "current");

		// delete extra objective
		objective_delete(self.flag.objective+1);

		self.flag createFlagWaypoint();

		self.flag thread autoReturn();
		self detachFlag(self.flag);

		//check if it's in a flag_returner
		for(i = 0; i < level.flag_returners.size; i++)
		{
			if(self.flag.flagmodel istouching(level.flag_returners[i]))
			{
				self.flag thread returnFlag();
				break;
			}
		}

		self.flag = undefined;
		self.dont_auto_balance = undefined;
// added by Ruud
		println("THE FLAG WAS DROPPED!");
		thread playSoundOnPlayers("ctf_touchown");
	}
}

returnFlag()
{
	self notify("end_autoreturn");

	self deleteFlagWaypoint();
	objective_delete(self.objective);
	objective_delete(self.objective+1);

	if(!level.hasspawned["flag"])
	{
		self.origin = self.home_origin;
 		self.flagmodel.origin = self.home_origin;
	 	self.flagmodel.angles = self.home_angles;
		if(level.randomflagspawns)	level.hasspawned["flag"] = true;
	}
	else
	{
		spawnpointname = "mp_tdm_spawn";
		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);
		self.origin = spawnpoint.origin;
 		self.flagmodel.origin = spawnpoint.origin;
	 	self.flagmodel.angles = spawnpoint.angles;
		self.basemodel.origin = spawnpoint.origin;
	 	self.basemodel.angles = spawnpoint.angles;
	}

	// Wait delay before spawning flag
	wait level.flagspawndelay + 0.05;

	// Do not spawn flag unless there are alive players in both teams
	while( !(alivePlayers("allies") && alivePlayers("axis")) )
		wait 1;

	self.flagmodel show();
	self.atbase = true;
	self.stolen = false;
	self.lastteam = "none";

	// set compass flag position on player
	objective_add(self.objective, "current", self.origin, self.compassflag);
	objective_position(self.objective, self.origin);
	objective_state(self.objective, "current");

	self createFlagWaypoint();
}

autoReturn()
{
	if(!level.flagrecovertime)
		return;

	self endon("end_autoreturn");

	wait level.flagrecovertime;

	self thread returnFlag();
}

attachFlag()
{
	if (isdefined(self.flagAttached))
		return;

	//put icon on screen
	self.flagAttached = newClientHudElem(self);
	self.flagAttached.x = 30;
	self.flagAttached.y = 95;
	self.flagAttached.alignX = "center";
	self.flagAttached.alignY = "middle";
	self.flagAttached.horzAlign = "left";
	self.flagAttached.vertAlign = "top";

	iconSize = 40;

	if (self.pers["team"] == "allies")
	{
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
		self.flagAttached setShader(level.hudflag_allies, iconSize, iconSize);
		self.statusicon = level.hudflag_allies;
	}
	else
	{
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
		self.flagAttached setShader(level.hudflag_axis, iconSize, iconSize);
		self.statusicon = level.hudflag_axis;
	}
	self attach(flagModel, "J_Spine4", true);
}

detachFlag(flag)
{
	if (!isdefined(self.flagAttached))
		return;

	if (flag.team == "allies")
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
	self detach(flagModel, "J_Spine4");

	self.statusicon = "";

	self.flagAttached destroy();
}

createFlagWaypoint()
{
	if(!level.awe_objectivepoints)
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
		waypoint setShader(self.objpointflag, 7, 7);

	waypoint setwaypoint(true);
	self.waypoint = waypoint;
}

deleteFlagWaypoint()
{
	if(!level.awe_objectivepoints)
		return;

	if(isdefined(self.waypoint))
		self.waypoint destroy();
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

alivePlayers(team)
{
	allplayers = getentarray("player", "classname");
	alive = [];
	for(i = 0; i < allplayers.size; i++)
	{
		if(allplayers[i].sessionstate == "playing" && allplayers[i].sessionteam == team)
			alive[alive.size] = allplayers[i];
	}
	return alive.size;
}

announce(what)
{
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		if(players[i] == self)
			players[i] iprintlnbold("You " + what);
		else if(isPlayer(players[i]))
			players[i] iprintln(self.name + " " + what);
	}
}

FindTeamSides()
{
	spawnpointname = "mp_tdm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");
	maxdist = 0;
	p1 = spawnpoints[0];
	p2 = spawnpoints[0];
	for(i=0;i<spawnpoints.size;i++)
	{
		for(j=0;j<spawnpoints.size;j++)
		{
			if(i==j) continue;
			dist = distance(spawnpoints[i].origin,spawnpoints[j].origin);
			if(dist>maxdist)
			{
				maxdist = dist;
				p1 = spawnpoints[i];
				p2 = spawnpoints[j];
			}
		}
	}

	// Save teamsides for intitial spawning
	if(randomInt(2))
	{
		level.teamside["axis"] = p1.origin;
		level.teamside["allies"] = p2.origin;
	}
	else
	{
		level.teamside["axis"] = p2.origin;
		level.teamside["allies"] = p1.origin;
	}
}

InitFlag()
{
	// Get map name
	mapname = getcvar("mapname");

	// Look for cvars
	x = getcvar("scr_htf_home_x_" + mapname);
	y = getcvar("scr_htf_home_y_" + mapname);
	z = getcvar("scr_htf_home_z_" + mapname);
	a = getcvar("scr_htf_home_a_" + mapname);

	if(x != "" && y != "" && z != "" && a != "")
	{
		position = (x,y,z);
		angles = (0,a,0);
	}
	else
	{
		// No cvars...
		flagpoint = GetFlagPoint();
		position = flagpoint.origin;
		angles = flagpoint.angles;

		// Remove spawn on flag points?
		if(level.removeflagspawns)
		{
			spawnpointname = "mp_tdm_spawn";
			spawnpoints = getentarray(spawnpointname, "classname");
			for(i=0;i<spawnpoints.size;i++)
			{
				if(spawnpoints[i] == flagpoint)
					spawnpoints[i] delete();
			}
		}
	}
	origin = FindGround(position);

	// Spawn a script origin
	level.flag = spawn("script_origin",origin);
	level.flag.targetname = "htf_flaghome";
	level.flag.origin = origin;
	level.flag.angles = angles;
	level.flag.home_origin = origin;
	level.flag.home_angles = angles;

	// Spawn the flag base model
	level.flag.basemodel = spawn("script_model", level.flag.home_origin);
	level.flag.basemodel.angles = level.flag.home_angles;
	level.flag.basemodel setmodel("xmodel/prop_flag_base");
	
	// Spawn the flag
	level.flag.flagmodel = spawn("script_model", level.flag.home_origin);
	level.flag.flagmodel.angles = level.flag.home_angles;
	level.flag.flagmodel setmodel("xmodel/prop_flag_german");
	level.flag.flagmodel hide();

	// Set flag properties
	level.flag.team = "none";
	level.flag.atbase = false;
	level.flag.stolen = false;
	level.flag.lastteam = "none";
	level.flag.objective = 0;
	level.flag.compassflag = level.compassflag_none;
	level.flag.objpointflag = level.objpointflag_none;

	wait 0.05;

	SetupHud();

	level.flag returnFlag();
}

GetFlagPoint()
{
	p1 = level.teamside["axis"];
	p2 = level.teamside["allies"];

	// Find center
	x = p1[0] + (p2[0] - p1[0]) / 2;
	y = p1[1] + (p2[1] - p1[1]) / 2;
	z = p1[2] + (p2[2] - p1[2]) / 2;

	// Get nearest spawn
	spawnpointname = "mp_tdm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");
	flagpoint = maps\mp\gametypes\_spawnlogic::NearestSpawnpoint(spawnpoints, (x,y,z));

	return flagpoint;
}

FindGround(position)
{
	trace=bulletTrace(position+(0,0,10),position+(0,0,-1200),false,undefined);
	ground=trace["position"];
	return ground;
}

CheckForFlag()
{
	level endon("intermission");

	self.flag = undefined;
	count=0;
	oldorigin = self.origin;

	// What is my team?
	myteam = self.sessionteam;
	if(myteam == "allies")
		otherteam = "axis";
	else
		otherteam = "allies";
	
	while (isAlive(self) && self.sessionstate=="playing" && myteam == self.sessionteam) 
	{
		// Does the flag exist and is not currently being stolen?
		if(!level.flag.stolen)
		{
			// Am I touching it and it is not currently being stolen?
			if(self isTouchingFlag() && !level.flag.stolen)
			{
				level.flag.stolen = true;
		
				// Steal flag
				self pickupFlag(level.flag);

				oldorigin = self.origin;

				if(self.flag.lastteam != myteam)
				{
					self announce("^7stole the flag^7!");

					// Get personal score
					self.score += 3;

					if(level.mode == 2)
						level.teamholdtime[otherteam] = 0;

					lpselfnum = self getEntityNumber();
					lpselfguid = self getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + myteam + ";" + self.name + ";" + "htf_stole" + "\n");
				}
				else
				{
					self announce("^7picked up the flag^7!");
				}
				
				self.flag.lastteam = self.flag.team;

				if(myteam == "axis")
					level.iconaxis	scaleOverTime(1, 22, 22);
				else
					level.iconallies	scaleOverTime(1, 22, 22);
				
				count = 0;
			}
		}

		// Update objective on compass
		if(isdefined(self.flag))
		{
			// Update the objective for my team
			objective_position(self.flag.objective, self.origin);		

			wait 0.05;

			// Make sure flag still exist
			if(isdefined(self.flag))
			{
				// Increase teamscore every second
				count++;
				if(count>=20)
				{
					count = 0;
				
					// Update the other teams objective (lags 1 second behind)
					objective_position(self.flag.objective+1, oldorigin);		
					oldorigin = self.origin;
	
					if(level.mode == 1 && level.teamholdtime[otherteam])
						level.teamholdtime[otherteam]--;
					else
					level.teamholdtime[myteam]++;

					if(level.teamholdtime[myteam] >= level.holdtime)
					{
						iprintlnbold("The " + myteam + " scored by holding the flag for " + level.holdtime + " seconds.");
	
// added by Ruud
						thread playSoundOnPlayers("ctf_touchcapture", myteam);
						if(!level.splitscreen)
							thread playSoundOnPlayers("ctf_enemy_touchcapture", otherteam);
//

						level.teamholdtime[myteam] = 0;
						if(level.mode == 3)
							level.teamholdtime[otherteam] = 0;

						// Get personal score
						self.score += 2;

						// Give all other team members 1 point
						players = getentarray("player", "classname");
						for(i = 0; i < players.size; i++)
						{
							player = players[i];
					
							if(!isDefined(player.pers["team"]) || player.pers["team"] != myteam || player == self)
								continue;
							player.score++;
						}

						lpselfnum = self getEntityNumber();
						lpselfguid = self getGuid();
						logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + myteam + ";" + self.name + ";" + "htf_scored" + "\n");

						// Get score
						myteamscore = getTeamScore(myteam);
						myteamscore++;
						setTeamScore(myteam, myteamscore);
						level notify("update_allhud_score");

						if(myteam == "allies")
							level.numallies setValue(getTeamScore("allies"));
						else
							level.numaxis setValue(getTeamScore("axis"));

						checkScoreLimit();

						self detachFlag(self.flag);

						// Return flag
						self.flag thread ReturnFlag();

						// Clear flags
						self.flag = undefined;	

						if(myteam == "axis")
							level.iconaxis	scaleOverTime(1, 18, 18);
						else
							level.iconallies	scaleOverTime(1, 18, 18);
					}
					UpdateHud();
				}
			}
		}
		else
			wait 0.2;		
	}

	//player died or went spectator
	self dropFlag();
}

isTouchingFlag()
{
	if(distance(self.origin, level.flag.origin) < 50)
		return true;
	else
		return false;
}

SetupHud()
{
	y = 10;
	barsize = 200;

	level.scoreback = newHudElem();
	level.scoreback.x = 320;
	level.scoreback.y = y;
	level.scoreback.alignX = "center";
	level.scoreback.alignY = "middle";
	level.scoreback.alpha = 0.3;
	level.scoreback.color = (0.2,0.2,0.2);
	level.scoreback setShader("white", barsize*2+4, 12);			

	level.scoreallies = newHudElem();
	level.scoreallies.x = 320;
	level.scoreallies.y = y;
	level.scoreallies.alignX = "right";
	level.scoreallies.alignY = "middle";
	level.scoreallies.color = (1,0,0);
	level.scoreallies.alpha = 0.5;
	level.scoreallies setShader("white", 1, 10);

	level.scoreaxis = newHudElem();
	level.scoreaxis.x = 320;
	level.scoreaxis.y = y;
	level.scoreaxis.alignX = "left";
	level.scoreaxis.alignY = "middle";
	level.scoreaxis.color = (0,0,1);
	level.scoreaxis.alpha = 0.5;
	level.scoreaxis setShader("white", 1, 10);

	level.iconallies = newHudElem();
	level.iconallies.x = 320 - barsize - 3;
	level.iconallies.y = y;
	level.iconallies.alignX = "right";
	level.iconallies.alignY = "middle";
	level.iconallies.color = (1,1,1);
	level.iconallies.alpha = 1;
	level.iconallies setShader(game["headicon_allies"], 18, 18);

	level.iconaxis = newHudElem();
	level.iconaxis.x = 320 + barsize + 3;
	level.iconaxis.y = y;
	level.iconaxis.alignX = "left";
	level.iconaxis.alignY = "middle";
	level.iconaxis.color = (1,1,1);
	level.iconaxis.alpha = 1;
	level.iconaxis setShader(game["headicon_axis"], 18, 18);

	level.numallies = newHudElem();
	level.numallies.x = 320 - barsize - 25;
	level.numallies.y = y-2;
	level.numallies.alignX = "right";
	level.numallies.alignY = "middle";
	level.numallies.color = (1,1,0);
	level.numallies.alpha = 1;
	level.numallies.fontscale = 1.2;
	level.numallies setValue(getTeamScore("allies"));

	level.numaxis = newHudElem();
	level.numaxis.x = 320 + barsize + 31;
	level.numaxis.y = y-2;
	level.numaxis.alignX = "right";
	level.numaxis.alignY = "middle";
	level.numaxis.color = (1,1,0);
	level.numaxis.alpha = 1;
	level.numaxis.fontscale = 1.2;
	level.numaxis setValue(getTeamScore("axis"));
}

UpdateHud()
{
	y = 10;
	barsize = 200;

	axis = int(level.teamholdtime["axis"] * barsize / (level.holdtime - 1) + 1);
	allies = int(level.teamholdtime["allies"] * barsize / (level.holdtime - 1) + 1);

	if(level.teamholdtime["allies"] != level.oldteamholdtime["allies"])
		level.scoreallies scaleOverTime(1,allies,10);
	if(level.teamholdtime["axis"] != level.oldteamholdtime["axis"])
		level.scoreaxis	scaleOverTime(1,axis,10);

	level.oldteamholdtime["allies"] = level.teamholdtime["allies"];
	level.oldteamholdtime["axis"] = level.teamholdtime["axis"];
}
