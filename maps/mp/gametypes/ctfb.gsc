/*
	Capture the Flag Back - AWE mod compatible version
	Author : La Truffe
	
	Credits : Matthias (original CTFB in Admiral mod), Bell (AWE mod), Ravir (cvardef function)

	Version : 1.2

	Objective: 	Score points for your team by capturing the enemy's flag and returning it to your base
	Map ends:	When one team reaches the score limit, or time limit is reached
	Respawning:	Instant / At base

	Level requirements
	------------------
		Spawnpoints:
			classname		mp_ctf_spawn_allied
			Allied players spawn from these.
			classname		mp_ctf_spawn_axis
			Axis players spawn from these.
			classname		mp_dm_spawn
			Flags spawn from these in random position mode.

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

/*
AWE : for AWE mod version
STD : for standlone (no mod) version
*/

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
	level.objpointflag_allies = "objpoint_flagpatch1_" + game["allies"];
	level.objpointflag_axis = "objpoint_flagpatch1_" + game["axis"];
	level.objpointflagmissing_allies = "objpoint_flagmissing_" + game["allies"];
	level.objpointflagmissing_axis = "objpoint_flagmissing_" + game["axis"];
	level.hudflag_allies = "compass_flag_" + game["allies"];
	level.hudflag_axis = "compass_flag_" + game["axis"];
	
	level.hudflagflash_allies = "hud_flagflash_" + game["allies"];
	level.hudflagflash_axis = "hud_flagflash_" + game["axis"];

	precacheStatusIcon("hud_status_dead");
	precacheStatusIcon("hud_status_connecting");
	precacheStatusIcon(level.hudflag_allies);
	precacheStatusIcon(level.hudflag_axis);
	precacheRumble("damage_heavy");
	precacheShader(level.compassflag_allies);
	precacheShader(level.compassflag_axis);
	precacheShader(level.objpointflag_allies);
	precacheShader(level.objpointflag_axis);
	precacheShader(level.hudflag_allies);
	precacheShader(level.hudflag_axis);
	precacheShader(level.hudflagflash_allies);
	precacheShader(level.hudflagflash_axis);
	precacheShader(level.objpointflag_allies);
	precacheShader(level.objpointflag_axis);
	precacheShader(level.objpointflagmissing_allies);
	precacheShader(level.objpointflagmissing_axis);
	precacheModel("xmodel/prop_flag_" + game["allies"]);
	precacheModel("xmodel/prop_flag_" + game["axis"]);
	precacheModel("xmodel/prop_flag_" + game["allies"] + "_carry");
	precacheModel("xmodel/prop_flag_" + game["axis"] + "_carry");
	precacheString(&"MP_TIME_TILL_SPAWN");
	precacheString (&"CTFB_OBJ_TEXT");
	precacheString (&"CTFB_OBJ_TEXT_NOSCORE");
	precacheString (&"CTFB_ENEMY_FLAG_CAPTURED");
	precacheString (&"CTFB_YOUR_FLAG_WAS_CAPTURED");
	precacheString (&"CTFB_YOUR_FLAG_WAS_RETURNED");
	precacheString (&"CTFB_YOUR_FLAG_WAS_TAKEN");
	precacheString (&"CTFB_ENEMY_FLAG_TAKEN");
	precacheString (&"CTFB_YOUR_FLAG_WAS_PICKED_UP");
	precacheString (&"CTFB_DEFEND");
	precacheString (&"CTFB_ASSIST");
	precacheString (&"CTFB_AUTO_RETURN");
	precacheString(&"PLATFORM_PRESS_TO_SPAWN");

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

	// Time limit per map
	if(getCvar("scr_ctfb_timelimit") == "")
		setCvar("scr_ctfb_timelimit", "30");
	else if(getCvarFloat("scr_ctfb_timelimit") > 1440)
		setCvar("scr_ctfb_timelimit", "1440");
	level.timelimit = getCvarFloat("scr_ctfb_timelimit");
	setCvar("ui_timelimit", level.timelimit);
	makeCvarServerInfo("ui_timelimit", "30");

	// Score limit per map
	if(getCvar("scr_ctfb_scorelimit") == "")
		setCvar("scr_ctfb_scorelimit", "5");
	level.scorelimit = getCvarInt("scr_ctfb_scorelimit");
	setCvar("ui_scorelimit", level.scorelimit);
	makeCvarServerInfo("ui_scorelimit", "5");

	// Force respawning
	if(getCvar("scr_forcerespawn") == "")
		setCvar("scr_forcerespawn", "0");

// AWE ->
	// Use objective points
	level.awe_objectivepoints = cvardef ("awe_objective_points", 1, 0, 1, "int");
// AWE <-

	level.random_flag_position = cvardef ("scr_ctfb_random_flag_position", 0, 0, 1, "int");
	level.show_enemy_own_flag = cvardef ("scr_ctfb_show_enemy_own_flag", 1, 0, 1, "int");
	level.show_enemy_own_flag_after_sec = cvardef ("scr_ctfb_show_enemy_own_flag_after_sec", 60, 20, 900, "int");
	level.show_enemy_own_flag_time = cvardef ("scr_ctfb_show_enemy_own_flag_time", 60, 20, 900, "int");
	level.points_capture_flag = cvardef ("scr_ctfb_points_capture_flag", 10, 1, 50, "int");
	level.points_returned_flag = cvardef ("scr_ctfb_points_returned_flag", 2, 1, 50, "int");
	level.points_defend = cvardef ("scr_ctfb_points_defend", 2, 1, 50, "int");
	level.points_assist = cvardef ("scr_ctfb_points_assist", 3, 1, 50, "int");
	level.flagprotectiondistance = cvardef ("scr_ctfb_flagprotectiondistance", 800, 1, 999999, "int");
	level.respawndelay = cvardef ("scr_ctfb_respawn_delay", 10, 0, 600, "int");
	level.flagautoreturndelay = cvardef ("scr_ctfb_flagautoreturndelay", 120, 0, 99999, "int");

	spawnpointname = "mp_ctf_spawn_allied";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	spawnpointname = "mp_ctf_spawn_axis";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] PlaceSpawnpoint();

	if (level.random_flag_position)
	{
		spawnpointname = "mp_dm_spawn";
		spawnpoints = getentarray (spawnpointname, "classname");

		if (! spawnpoints.size)
		{
			maps\mp\gametypes\_callbacksetup::AbortLevel ();
			return;
		}

		for (i = 0; i < spawnpoints.size; i++)
			spawnpoints[i] placeSpawnpoint ();	
	}

	allowed[0] = "ctf";
	maps\mp\gametypes\_gameobjects::main(allowed);

	if(!isDefined(game["state"]))
		game["state"] = "playing";

	level.mapended = false;

	level.team["allies"] = 0;
	level.team["axis"] = 0;

	minefields = [];
	minefields = getentarray("minefield", "targetname");
	trigger_hurts = [];
	trigger_hurts = getentarray("trigger_hurt", "classname");

	level.flag_returners = minefields;
	for(i = 0; i < trigger_hurts.size; i++)
		level.flag_returners[level.flag_returners.size] = trigger_hurts[i];

	thread initFlags();

	thread startGame();
	thread updateGametypeCvars();
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

	if (! level.splitscreen)
		iprintlnFIXED (&"MP_CONNECTED", self);

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
	self dropFlag ();
	self dropOwnFlag ();

	if (! level.splitscreen)
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

	self dropFlag();
	self dropOwnFlag ();
	
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
			{
				attacker.score++;
				attacker CheckProtectedOwnFlag (self.origin);
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

	if(self.pers["team"] == "allies")
		spawnpointname = "mp_ctf_spawn_allied";
	else
		spawnpointname = "mp_ctf_spawn_axis";

	if (level.random_flag_position)
		spawnpointname = "mp_dm_spawn";

	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);

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
			self setClientCvar("cg_objectiveText", &"CTFB_OBJ_TEXT", level.scorelimit);
		else
			self setClientCvar("cg_objectiveText", &"CTFB_OBJ_TEXT_NOSCORE");
	}
	else
		self setClientCvar("cg_objectiveText", &"CTFB_OBJ_TEXT_NOSCORE");

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
// AWE ->
	awe\_global::EndMap ();
// AWE <-

	game["state"] = "intermission";
	level notify("intermission");

	alliedscore = getTeamScore("allies");
	axisscore = getTeamScore("axis");

	if(alliedscore == axisscore)
	{
		winningteam = "tie";
		losingteam = "tie";
		text = &"MP_THE_GAME_IS_A_TIE";
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

	wait 15;
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
		timelimit = getCvarFloat("scr_ctfb_timelimit");
		if(level.timelimit != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_ctfb_timelimit", "1440");
			}

			level.timelimit = timelimit;
			setCvar("ui_timelimit", level.timelimit);
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

		scorelimit = getCvarInt("scr_ctfb_scorelimit");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
			setCvar("ui_scorelimit", level.scorelimit);
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
		    iprintlnFIXED (&"MP_JOINED_ALLIES", self);
	    else if(team == "axis")
		    iprintlnFIXED (&"MP_JOINED_AXIS", self);
	}
}

initFlags()
{
	maperrors = [];

	allied_flags = getentarray("allied_flag", "targetname");
	if(allied_flags.size < 1)
		maperrors[maperrors.size] = "^1No entities found with \"targetname\" \"allied_flag\"";
	else if(allied_flags.size > 1)
		maperrors[maperrors.size] = "^1More than 1 entity found with \"targetname\" \"allied_flag\"";

	axis_flags = getentarray("axis_flag", "targetname");
	if(axis_flags.size < 1)
		maperrors[maperrors.size] = "^1No entities found with \"targetname\" \"axis_flag\"";
	else if(axis_flags.size > 1)
		maperrors[maperrors.size] = "^1More than 1 entity found with \"targetname\" \"axis_flag\"";

	if(maperrors.size)
	{
		println("^1------------ Map Errors ------------");
		for(i = 0; i < maperrors.size; i++)
			println(maperrors[i]);
		println("^1------------------------------------");

		return;
	}

	allied_flag = getent ("allied_flag", "targetname");
	axis_flag = getent ("axis_flag", "targetname");

	if (level.random_flag_position)
	{
		spawnpoints = getentarray ("mp_dm_spawn", "classname");
		
		allied_flag.origin = (0,0,0);
		axis_flag.origin = (0,0,0);
		
		trys = 0;
		while ((distance (allied_flag.origin, axis_flag.origin) < 2200) || (allied_flag.origin == axis_flag.origin))
		{
			j = randomInt (spawnpoints.size);
			allied_flag = spawnpoints[j];
		
			j = randomInt (spawnpoints.size);
			axis_flag = spawnpoints[j];
	
			trys ++;

			if (trys > 50)
				break;
		}
	}
	
	if ((distance (axis_flag.origin, allied_flag.origin) < 2000) || (allied_flag.origin == axis_flag.origin))
	{
		allied_flag = getent ("allied_flag", "targetname");
		axis_flag = getent ("axis_flag", "targetname");
	}

	allied_flag.home_origin = allied_flag.origin;
	allied_flag.home_angles = allied_flag.angles;
	allied_flag.flagmodel = spawn("script_model", allied_flag.home_origin);
	allied_flag.flagmodel.angles = allied_flag.home_angles;
	allied_flag.flagmodel setmodel("xmodel/prop_flag_" + game["allies"]);
	allied_flag.basemodel = spawn("script_model", allied_flag.home_origin);
	allied_flag.basemodel.angles = allied_flag.home_angles;
	allied_flag.basemodel setmodel("xmodel/prop_flag_base");
	allied_flag.team = "allies";
	allied_flag.atbase = true;
	allied_flag.objective = 0;
	allied_flag.compassflag = level.compassflag_allies;
	allied_flag.objpointflag = level.objpointflag_allies;
	allied_flag.objpointflagmissing = level.objpointflagmissing_allies;

	allied_flag thread flag();

	axis_flag.home_origin = axis_flag.origin;
	axis_flag.home_angles = axis_flag.angles;
	axis_flag.flagmodel = spawn("script_model", axis_flag.home_origin);
	axis_flag.flagmodel.angles = axis_flag.home_angles;
	axis_flag.flagmodel setmodel("xmodel/prop_flag_" + game["axis"]);
	axis_flag.basemodel = spawn("script_model", axis_flag.home_origin);
	axis_flag.basemodel.angles = axis_flag.home_angles;
	axis_flag.basemodel setmodel("xmodel/prop_flag_base");
	axis_flag.team = "axis";
	axis_flag.atbase = true;
	axis_flag.objective = 1;
	axis_flag.compassflag = level.compassflag_axis;
	axis_flag.objpointflag = level.objpointflag_axis;
	axis_flag.objpointflagmissing = level.objpointflagmissing_axis;

	axis_flag thread flag();

	level.flags	= [];
	level.flags["allies"] = allied_flag;
	level.flags["axis"] = axis_flag;
}

flag()
{
	objective_add(self.objective, "current", self.origin, self.compassflag);
	self createFlagWaypoint();

	for(;;)
	{
		if (level.random_flag_position)
		{
			other = undefined;
			other = self checkFlag();
		}
		else
		{
			self waittill ("trigger", other);
		}

		if(isPlayer(other) && isAlive(other) && (other.pers["team"] != "spectator"))
		{
			if(other.pers["team"] == self.team) // Touched by team
			{
				if(self.atbase)
				{
					if (isdefined (other.flag) && (other.pers["team"] != other.flag.team)) // Captured flag
					{
						println("CAPTURED THE FLAG!");

						friendlyAlias = "ctf_touchcapture";
						enemyAlias = "ctf_enemy_touchcapture";

						if(self.team == "axis")
							enemy = "allies";
						else
							enemy = "axis";

						thread playSoundOnPlayers(friendlyAlias, self.team);
						if(!level.splitscreen)
							thread playSoundOnPlayers(enemyAlias, enemy);

						thread printOnTeamFIXED (&"CTFB_ENEMY_FLAG_CAPTURED", self.team, other);
						thread printOnTeamFIXED (&"CTFB_YOUR_FLAG_WAS_CAPTURED", enemy, other);

						other.flag returnFlag();
						other detachFlag(other.flag);
						other.flag = undefined;
						other.statusicon = "";

						other.score += level.points_capture_flag;

						teamscore = getTeamScore(other.pers["team"]);
						teamscore += 1;
						setTeamScore(other.pers["team"], teamscore);

						lpselfnum = other getEntityNumber ();
						lpselfguid = other getGuid ();
						logPrint ("A;" + lpselfguid + ";" + lpselfnum + ";" + other.name + ";" + "ctfb_capture" + "\n");

						level notify("update_teamscore_hud");
						level notify("update_allhud_score");

						checkScoreLimit();
					}
				}
				else // Picked up own flag
				{
					println("PICKED UP OWN FLAG!");
					thread playSoundOnPlayers("ctf_touchown", self.team);
					thread printOnTeamFIXED (&"CTFB_YOUR_FLAG_WAS_PICKED_UP", self.team, other);

					other pickupOwnFlag (self);
					other thread checkBaseHomeOwnFlag (self);

					lpselfnum = other getEntityNumber ();
					lpselfguid = other getGuid ();
					logPrint ("A;" + lpselfguid + ";" + lpselfnum + ";" + other.name + ";" + "ctfb_pickup_own" + "\n");
				}
			}
			else if(other.pers["team"] != self.team) // Touched by enemy
			{
				println("PICKED UP THE FLAG!");

				friendlyAlias = "ctf_touchenemy";
				enemyAlias = "ctf_enemy_touchenemy";

				if(self.team == "axis")
					enemy = "allies";
				else
					enemy = "axis";

				thread playSoundOnPlayers(friendlyAlias, self.team);
				if(!level.splitscreen)
					thread playSoundOnPlayers(enemyAlias, enemy);

				thread printOnTeamFIXED (&"CTFB_YOUR_FLAG_WAS_TAKEN", self.team, other);
				thread printOnTeamFIXED (&"CTFB_ENEMY_FLAG_TAKEN", enemy, other);

				other pickupFlag(self); // Stolen flag

				lpselfnum = other getEntityNumber ();
				lpselfguid = other getGuid ();
				logPrint ("A;" + lpselfguid + ";" + lpselfnum + ";" + other.name + ";" + "ctfb_pickup" + "\n");
			}
		}
		wait 0.05;
	}
}

checkFlag()
{
	self notify("checkFlag");
	self endon("checkFlag");

	other = undefined;

	while(isDefined(self) && !isDefined(other))
	{
		wait 0.2;

		players = getentarray("player", "classname");

		for(i = 0; i < players.size; i++)
		{
			if(isDefined(self) && players[i].sessionstate == "playing" && distance(self.origin,players[i].origin) < 65)
				return players[i];				
		}		
	}	
}

checkBaseHomeOwnFlag (flag)
{
	self endon ("disconnect");
	self endon ("killed_player");
	
	self notify ("checkBase");
	self endon ("checkBase");

	while (isDefined (flag))
	{
		wait 0.3;

	
		if (isDefined (flag) && (self.sessionstate == "playing") && (distance (flag.basemodel.origin, self.origin) < 50))
		{
			// Returned flag

			println ("RETURNED THE FLAG!");
			thread playSoundOnPlayers ("ctf_touchown", flag.team);
			thread printOnTeamFIXED (&"CTFB_YOUR_FLAG_WAS_RETURNED", flag.team, self);

			flag returnFlag ();
			self detachOwnFlag (flag);
			self.ownflag = undefined; 
			self.statusicon = "";			
			
			self.score += level.points_returned_flag;

			lpselfnum = self getEntityNumber ();
			lpselfguid = self getGuid ();
			logPrint ("A;" + lpselfguid + ";" + lpselfnum + ";" + self.name + ";" + "ctfb_return" + "\n");

			level notify ("update_teamscore_hud");
			level notify ("update_allhud_score");
			
			break;
		}
	}	
}

pickupFlag(flag)
{
	self endon ("disconnect");

	flag notify("end_autoreturn");

	flag.origin = flag.origin + (0, 0, -10000);
	flag.flagmodel hide();
	self.flag = flag;
	
	flag.carrier = self;

	if (! isdefined (self.ownflag))
	{
		if(self.pers["team"] == "allies")
			self.statusicon = level.hudflag_axis;
		else
			self.statusicon = level.hudflag_allies;
	}
	else
		self thread BlinkFlags ();

	self.dont_auto_balance = true;

	flag deleteFlagWaypoint();
	flag createFlagMissingWaypoint();

	objective_onEntity (flag.objective, self);
	objective_team (flag.objective, self.pers["team"]);

	self attachFlag();

	self thread showFlag_afterTime (flag);
}

pickupOwnFlag(flag)
{
	self endon ("disconnect");

	flag notify("end_autoreturn");

	flag.origin = flag.origin + (0, 0, -10000);
	flag.flagmodel hide();
	self.ownflag = flag;
	
	flag.carrier = self;

	if (! isdefined (self.flag))
	{
		if(self.pers["team"] == "allies")
			self.statusicon = level.hudflag_allies;
		else
			self.statusicon = level.hudflag_axis;
	}
	else
		self thread BlinkFlags ();

	self.dont_auto_balance = true;

	flag deleteFlagWaypoint();

	//flag createFlagMissingWaypoint();

	objective_onEntity (flag.objective, self);
	objective_team (flag.objective, self.pers["team"]);

	self attachOwnFlag();
	
	self thread showFlag_afterTime (flag);
}

dropFlag()
{
	if(isdefined(self.flag))
	{
		start = self.origin + (0, 0, 10);
		end = start + (0, 0, -2000);
		trace = bulletTrace(start, end, false, undefined);

		self.flag.origin = trace["position"] + (randomint (20), randomint (20), 0);
		self.flag.flagmodel.origin = self.flag.origin;
		self.flag.flagmodel show();
		self.flag.atbase = false;

		self.flag.carrier = undefined;

		objective_position(self.flag.objective, self.flag.origin);
		objective_team(self.flag.objective, "none");

		self.flag createFlagWaypoint();

		self.flag thread autoReturn();
		self detachFlag(self.flag);

		//check if it's in a flag_returner
		for(i = 0; i < level.flag_returners.size; i++)
		{
			if(self.flag.flagmodel istouching(level.flag_returners[i]))
			{
				self.flag returnFlag();
				break;
			}
		}

		self.flag = undefined;
		self.dont_auto_balance = undefined;
	}
}

dropOwnFlag()
{
	if(isdefined(self.ownflag))
	{
		start = self.origin + (0, 0, 10);
		end = start + (0, 0, -2000);
		trace = bulletTrace(start, end, false, undefined);

		self.ownflag.origin = trace["position"] + (randomint(20),randomint(20),0);
		self.ownflag.flagmodel.origin = self.ownflag.origin;
		self.ownflag.flagmodel show();
		self.ownflag.atbase = false;

		self.ownflag.carrier = undefined;

		objective_position(self.ownflag.objective, self.ownflag.origin);
		objective_team(self.ownflag.objective, "none");

		self.ownflag createFlagWaypoint();

		self.ownflag thread autoReturn();
		self detachOwnFlag(self.ownflag);

		//check if it's in a flag_returner
		for(i = 0; i < level.flag_returners.size; i++)
		{
			if(self.ownflag.flagmodel istouching(level.flag_returners[i]))
			{
				self.ownflag returnFlag();
				break;
			}
		}

		self.ownflag = undefined;
		self.dont_auto_balance = undefined;
	}
}

showFlag_afterTime (flag)
{
	if (! level.show_enemy_own_flag)
		return;

	self endon ("disconnect");
	self endon ("killed_player");
	
	flag endon ("end_autoreturn");

	flag_after_sec = level.show_enemy_own_flag_after_sec;
	flag_time = level.show_enemy_own_flag_time;
	
	for ( ; ; )
	{
		wait flag_after_sec;
	
		objective_onEntity (flag.objective, self);
		objective_team (flag.objective, "none");
		
		wait flag_time;
		
		objective_onEntity (flag.objective, self);
		objective_team (flag.objective, self.pers["team"]);	
	}
}

returnFlag()
{
	self notify("end_autoreturn");

 	self.origin = self.home_origin;
 	self.flagmodel.origin = self.home_origin;
 	self.flagmodel.angles = self.home_angles;
	self.flagmodel show();
	self.atbase = true;

	self.carrier = undefined;

	objective_position(self.objective, self.origin);
	objective_team(self.objective, "none");

	self createFlagWaypoint();
	self deleteFlagMissingWaypoint();
}

autoReturn()
{
	self endon("end_autoreturn");

	wait level.flagautoreturndelay;
	
	if (self.team == "allies")
		iprintln (&"CTFB_AUTO_RETURN", &"MP_UPTEAM");
	else
		iprintln (&"CTFB_AUTO_RETURN", &"MP_DOWNTEAM");
	
	self thread returnFlag();
}

attachFlag()
{
	self endon ("disconnect");

	if(isdefined(self.enemyflagAttached))
		return;

	if(self.pers["team"] == "allies")
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
	
	self attach(flagModel, "J_Spine4", true);
	self.enemyflagAttached = true;
	self.flagAttached = true;
	
	self thread createHudIcon();
}

attachOwnFlag ()
{
	self endon ("disconnect");

	if (isdefined (self.ownflagAttached))
		return;

	if (self.pers["team"] == "axis")
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
	
	self attach( flagModel, "J_Spine2", true);
	self.ownflagAttached = true;
	self.flagAttached = true;
	
	self thread createOwnHudIconOwn ();
}

detachFlag(flag)
{
	self endon ("disconnect");

	if(!isdefined(self.enemyflagAttached))
		return;

	if(flag.team == "allies")
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
		
	self detach(flagModel, "J_Spine4");
	self.enemyflagAttached = undefined;

	if (! isdefined (self.ownflagAttached))
		self.flagAttached = undefined;
	
	self thread deleteHudIcon();
}

detachOwnFlag (flag)
{
	self endon ("disconnect");

	if (!isdefined (self.ownflagAttached))
		return;

	if (self.pers["team"] == "axis")
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
		
	self detach (flagModel, "J_Spine2");
	self.ownflagAttached = undefined;

	if (! isdefined (self.enemyflagAttached))
		self.flagAttached = undefined;

	self thread deleteOwnHudIcon ();
}

createHudIcon()
{
	iconSize = 40;

	self.hud_flag = newClientHudElem(self);
	self.hud_flag.x = 30;
	self.hud_flag.y = 95;
	self.hud_flag.alignX = "center";
	self.hud_flag.alignY = "middle";
	self.hud_flag.horzAlign = "left";
	self.hud_flag.vertAlign = "top";
	self.hud_flag.alpha = 0;

	self.hud_flagflash = newClientHudElem(self);
	self.hud_flagflash.x = 30;
	self.hud_flagflash.y = 95;
	self.hud_flagflash.alignX = "center";
	self.hud_flagflash.alignY = "middle";
	self.hud_flagflash.horzAlign = "left";
	self.hud_flagflash.vertAlign = "top";
	self.hud_flagflash.alpha = 0;
	self.hud_flagflash.sort = 1;

	if(self.pers["team"] == "allies")
	{
		self.hud_flag setShader(level.hudflag_axis, iconSize, iconSize);
		self.hud_flagflash setShader(level.hudflagflash_axis, iconSize, iconSize);
	}
	else
	{
		assert(self.pers["team"] == "axis");
		self.hud_flag setShader(level.hudflag_allies, iconSize, iconSize);
		self.hud_flagflash setShader(level.hudflagflash_allies, iconSize, iconSize);
	}

	self.hud_flagflash fadeOverTime(.2);
	self.hud_flagflash.alpha = 1;

	self.hud_flag fadeOverTime(.2);
	self.hud_flag.alpha = 1;

	wait .2;
	
	if(isdefined(self.hud_flagflash))
	{
		self.hud_flagflash fadeOverTime(1);
		self.hud_flagflash.alpha = 0;
	}
}

createHudIconOwn()
{
	iconSize = 40;

	self.hud_flag = newClientHudElem(self);
	self.hud_flag.x = 30;
	self.hud_flag.y = 95;
	self.hud_flag.alignX = "center";
	self.hud_flag.alignY = "middle";
	self.hud_flag.horzAlign = "left";
	self.hud_flag.vertAlign = "top";
	self.hud_flag.alpha = 0;

	self.hud_flagflash = newClientHudElem(self);
	self.hud_flagflash.x = 30;
	self.hud_flagflash.y = 95;
	self.hud_flagflash.alignX = "center";
	self.hud_flagflash.alignY = "middle";
	self.hud_flagflash.horzAlign = "left";
	self.hud_flagflash.vertAlign = "top";
	self.hud_flagflash.alpha = 0;
	self.hud_flagflash.sort = 1;

	if(self.pers["team"] == "axis")
	{
		self.hud_flag setShader(level.hudflag_axis, iconSize, iconSize);
		self.hud_flagflash setShader(level.hudflagflash_axis, iconSize, iconSize);
	}
	else
	{
		assert(self.pers["team"] == "allies");
		self.hud_flag setShader(level.hudflag_allies, iconSize, iconSize);
		self.hud_flagflash setShader(level.hudflagflash_allies, iconSize, iconSize);
	}

	self.hud_flagflash fadeOverTime(.2);
	self.hud_flagflash.alpha = 1;

	self.hud_flag fadeOverTime(.2);
	self.hud_flag.alpha = 1;

	wait .2;
	
	if(isdefined(self.hud_flagflash))
	{
		self.hud_flagflash fadeOverTime(1);
		self.hud_flagflash.alpha = 0;
	}
}

createOwnHudIconOwn()
{
	iconSize = 40;

	self.hud_flagown = newClientHudElem(self);
	self.hud_flagown.x = 30;
	self.hud_flagown.y = 135;
	self.hud_flagown.alignX = "center";
	self.hud_flagown.alignY = "middle";
	self.hud_flagown.horzAlign = "left";
	self.hud_flagown.vertAlign = "top";
	self.hud_flagown.alpha = 0;

	self.hud_flagownflash = newClientHudElem(self);
	self.hud_flagownflash.x = 30;
	self.hud_flagownflash.y = 135;
	self.hud_flagownflash.alignX = "center";
	self.hud_flagownflash.alignY = "middle";
	self.hud_flagownflash.horzAlign = "left";
	self.hud_flagownflash.vertAlign = "top";
	self.hud_flagownflash.alpha = 0;
	self.hud_flagownflash.sort = 1;

	if(self.pers["team"] == "axis")
	{
		self.hud_flagown setShader(level.hudflag_axis, iconSize, iconSize);
		self.hud_flagownflash setShader(level.hudflagflash_axis, iconSize, iconSize);
	}
	else
	{
		assert(self.pers["team"] == "allies");
		self.hud_flagown setShader(level.hudflag_allies, iconSize, iconSize);
		self.hud_flagownflash setShader(level.hudflagflash_allies, iconSize, iconSize);
	}

	self.hud_flagownflash fadeOverTime(.2);
	self.hud_flagownflash.alpha = 1;

	self.hud_flagown fadeOverTime(.2);
	self.hud_flagown.alpha = 1;

	wait .2;
	
	if(isdefined(self.hud_flagownflash))
	{
		self.hud_flagownflash fadeOverTime(1);
		self.hud_flagownflash.alpha = 0;
	}
}

deleteHudIcon()
{
	if(isdefined(self.hud_flagflash))
		self.hud_flagflash destroy();
		
	if(isdefined(self.hud_flag))
		self.hud_flag destroy();
}

deleteOwnHudIcon()
{
	if(isdefined(self.hud_flagownflash))
		self.hud_flagownflash destroy();
		
	if(isdefined(self.hud_flagown))
		self.hud_flagown destroy();
}

createFlagWaypoint()
{
// AWE ->
	if (! level.awe_objectivepoints)
		return;
// AWE <-

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
	self.waypoint_flag = waypoint;
}

deleteFlagWaypoint()
{
// AWE ->
	if (! level.awe_objectivepoints)
		return;
// AWE <-

	if(isdefined(self.waypoint_flag))
		self.waypoint_flag destroy();
}

createFlagMissingWaypoint()
{
	self deleteFlagMissingWaypoint();

	waypoint = newHudElem();
	waypoint.x = self.home_origin[0];
	waypoint.y = self.home_origin[1];
	waypoint.z = self.home_origin[2] + 100;
	waypoint.alpha = .61;
	waypoint.archived = true;

	if(level.splitscreen)
		waypoint setShader(self.objpointflagmissing, 14, 14);
	else
		waypoint setShader(self.objpointflagmissing, 7, 7);

	waypoint setwaypoint(true);
	self.waypoint_base = waypoint;
}

deleteFlagMissingWaypoint()
{
	if(isdefined(self.waypoint_base))
		self.waypoint_base destroy();
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

		if(!isDefined(player.pers["team"]) || player.pers["team"] == "spectator")
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

// AWE ->
	if (isdefined (level.awe_gametype))
		gametype = level.awe_gametype;	// "tdm", "bel", etc.
	else
		gametype = getcvar("g_gametype");	// "tdm", "bel", etc.
// AWE <-

// STD ->
//	gametype = getcvar("g_gametype");	// "tdm", "bel", etc.
// STD <-

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

printOnTeamFIXED (locstring, team, player)
{
	if (IsLinuxServer ())
		printOnTeam (locstring, team, player.name);
	else
		printOnTeam (locstring, team, player);
}

BlinkFlags ()
{
	self endon ("disconnect");
	
	while (isdefined (self.flag) && isdefined (self.ownflag))
	{
		if (self.statusicon == level.hudflag_allies)
			self.statusicon = level.hudflag_axis;
		else
			self.statusicon = level.hudflag_allies;

		// 2 seconds wait ; the scoreboard is updated every 2 seconds anyway
		wait 2;
	}
}

CheckProtectedOwnFlag (victim_origin)
{
	flag = level.flags[self.pers["team"]];

	if (isdefined (flag.carrier))
	{
		// Flag is being carried
		
		if (flag.carrier == self)
			// No "self-assistance"
			return;
			
		if (flag.carrier.pers["team"] != self.pers["team"])
			// No assistance for ennemy carrier
			return;

		dist = distance (victim_origin, flag.carrier.origin);
		
		if (dist < level.flagprotectiondistance)
		{
			iprintlnFIXED (&"CTFB_ASSIST", self);
			self.score += level.points_assist - 1;
		}
		
		return;
	}

	if (flag.atbase)
		// Flag is at base
		dist = distance (victim_origin, flag.home_origin);
	else
		// Flag has been droppped by a player
		dist = distance (victim_origin, flag.origin);
	
	if (dist < level.flagprotectiondistance)
	{
		iprintlnFIXED (&"CTFB_DEFEND", self);
		self.score += level.points_defend - 1;
	}
}