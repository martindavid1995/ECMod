/*
	Individual Hold the Flag - AWE mod compatible version
	Author : La Truffe
	
	Based on HTF (Hold the Flag)

	Credits : Bell (AWE mod, HTF), Ravir (cvardef function)

	Version : 1.3

	Objective: 	Score points by holding the flag
	Map ends:	When one player reaches the score limit, or time limit is reached
	Respawning:	After a configurable delay
*/

/*
AWE : for AWE mod version
STD : for standlone (no mod) version
*/

main()
{
	// Trick : pretend we're on HQ gametype to benefit from the level.radio definitions in the map script
	setcvar ("g_gametype", "hq");

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
	
	// Over-override Callback_StartGameType
	
	level.ihtf_callbackStartGameType = level.callbackStartGameType;
	level.callbackStartGameType = ::IHTF_Callback_StartGameType;
}

IHTF_Callback_StartGameType ()
{
	// Trick : restore IHTF gametype
	setcvar ("g_gametype", "ihtf");

	[[level.ihtf_callbackStartGameType]] ();
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
	precacheString(&"PLATFORM_PRESS_TO_SPAWN");
	precacheString (&"IHTF_OBJ_TEXT");
	precacheString (&"IHTF_OBJ_TEXT_NOSCORE");
	precacheString (&"IHTF_MAX_HOLD_TIME");
	precacheString (&"IHTF_HOLD_TIME_TO_SCORE");
	precacheString (&"IHTF_TIMEOUT");
	precacheString (&"IHTF_RESPAWN_DELAY");
	precacheString (&"IHTF_FLAG_SPAWN_DELAY");
	precacheString (&"IHTF_POINTS_STEALING");
	precacheString (&"IHTF_POINTS_HOLDING");
	precacheString (&"IHTF_POINTS_KILLING_FLAG_CARRIER");
	precacheString (&"IHTF_POINTS_KILLING_PLAYERS");
	precacheString (&"IHTF_FLAG_TIMEOUT");
	precacheString (&"IHTF_FLAG_MAXTIME");
	precacheString (&"IHTF_STOLE_FLAG");
	precacheString (&"IHTF_YOU_STOLE_FLAG");
	precacheString (&"IHTF_KILLED_FLAG_CARRIER");
	precacheString (&"IHTF_YOU_KILLED_FLAG_CARRIER");
	precacheString (&"IHTF_FLAG_CARRIER_SCORES");
	precacheString (&"IHTF_YOU_SCORE");

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
	thread maps\mp\gametypes\_spectating::init();
	thread maps\mp\gametypes\_grenadeindicators::init();

	level.xenon = (getcvar("xenonGame") == "true");
	if(level.xenon) // Xenon only
		thread maps\mp\gametypes\_richpresence::init();
	else // PC only
		thread maps\mp\gametypes\_quickmessages::init();

	setClientNameMode("auto_change");

	// Time limit per map
	level.timelimit = cvardef("scr_ihtf_timelimit",30,0,1440,"float");
	setCvar("ui_timelimit", level.timelimit);
	makeCvarServerInfo("ui_timelimit", "30");

	// Score limit per map
	level.scorelimit = cvardef("scr_ihtf_scorelimit",30,0,9999,"int");
	setCvar("ui_scorelimit", level.scorelimit);
	makeCvarServerInfo("ui_scorelimit", "30");

	// Max hold time
	level.MaxHoldTime = cvardef ("scr_ihtf_maxholdtime", 120, 1, 99999, "int");
	setCvar ("ui_ihtf_maxholdtime", level.MaxHoldTime);
	storeServerInfoDvar ("ui_ihtf_maxholdtime");
	
	// Time to score
	level.HoldTimeToScore = cvardef("scr_ihtf_holdtimetoscore", 10, 1, 99999, "int");
	setCvar ("ui_ihtf_holdtimetoscore", level.HoldTimeToScore);
	storeServerInfoDvar ("ui_ihtf_holdtimetoscore");

	level.holdtime = 0;
	level.totalholdtime = 0;
	level.holdtime_old = level.holdtime;
	level.totalholdtime_old = level.totalholdtime;

	// Flag spawn delay
	level.flagspawndelay = cvardef("scr_ihtf_flagspawndelay", 15, 0, 9999, "int");
	setCvar ("ui_ihtf_flagspawndelay", level.flagspawndelay);
	storeServerInfoDvar ("ui_ihtf_flagspawndelay");

	// Random spawnpoints for the flag
	level.randomflagspawns = cvardef("scr_ihtf_randomflagspawns", 1, 0, 1, "int");

	// Respawn delay
	level.respawndelay = cvardef("scr_ihtf_respawndelay", 10, 0, 600, "int");;
	setCvar ("ui_ihtf_respawndelay", level.respawndelay);
	storeServerInfoDvar ("ui_ihtf_respawndelay");

	// Force respawning
	level.forcerespawn = cvardef("scr_forcerespawn",0,0,60,"int");

// AWE ->
	// Use objective points
	level.awe_objectivepoints = cvardef ("awe_objective_points", 1, 0, 1, "int");
// AWE <-
	
	level.PointsForKillingPlayers = cvardef ("scr_ihtf_pointsforkillingplayers", 0, -100, 100, "int");
	setCvar ("ui_ihtf_pointsforkillingplayers", level.PointsForKillingPlayers);
	storeServerInfoDvar ("ui_ihtf_pointsforkillingplayers");

	level.PointsForKillingFlagCarrier	= cvardef ("scr_ihtf_pointsforkillingflagcarrier", 1, 0, 100, "int");
	setCvar ("ui_ihtf_pointsforkillingflagcarrier", level.PointsForKillingFlagCarrier);
	storeServerInfoDvar ("ui_ihtf_pointsforkillingflagcarrier");

	level.PointsForStealingFlag = cvardef ("scr_ihtf_pointsforstealingflag", 1, 0, 100, "int");
	setCvar ("ui_ihtf_pointsforstealingflag", level.PointsForStealingFlag);
	storeServerInfoDvar ("ui_ihtf_pointsforstealingflag");

	level.PointsForHoldingFlag = cvardef ("scr_ihtf_pointsforholdingflag", 2, 0, 100, "int");
	setCvar ("ui_ihtf_pointsforholdingflag", level.PointsForHoldingFlag);
	storeServerInfoDvar ("ui_ihtf_pointsforholdingflag");

	// Time out for stealing flag
	level.flagtimeout = cvardef ("scr_ihtf_flagtimeout", 180, 1, 9999, "int");
	setCvar ("ui_ihtf_flagtimeout", level.flagtimeout);
	storeServerInfoDvar ("ui_ihtf_flagtimeout");

	level.startflagtime = 0;
	
	// Minimum distance a player can spawn from the flag
	level.spawndistance = cvardef ("scr_ithf_spawndistance", 1000, 1, 99999, "int");

	// Player spawn points creation mode
	level.playerspawnpointsmode = cvardef ("scr_ihtf_playerspawnpointsmode", "dm tdm", "", "", "string");
	
	// Flag spawn points creation mode
	level.flagspawnpointsmode = cvardef ("scr_ihtf_flagspawnpointsmode", "dm ctff sdb hq", "", "", "string");

	SaveSDBombzonesPos ();
	SaveCTFFlagsPos ();

	allowed[0] = "dm";
	maps\mp\gametypes\_gameobjects::main (allowed);

	level.playerspawnpoints = SpawnPointsArray (level.playerspawnpointsmode, "ihtf_player_spawn");
	level.flagspawnpoints = SpawnPointsArray (level.flagspawnpointsmode, "ihtf_flag_spawn");

	if (! level.playerspawnpoints.size)
	{
		maps\mp\_utility::error ("NO PLAYER SPAWNPOINTS IN MAP");
		maps\mp\gametypes\_callbacksetup::AbortLevel ();
		return;
	}

	if (! level.flagspawnpoints.size)
	{
		maps\mp\_utility::error ("NO FLAG SPAWNPOINTS IN MAP");
		maps\mp\gametypes\_callbacksetup::AbortLevel ();
		return;
	}

	logprint (level.playerspawnpoints.size + " player spawn points\n");
	logprint (level.flagspawnpoints.size + " flag positions\n");

	RemoveHQRadioPoints ();

	if(!isDefined(game["state"]))
		game["state"] = "playing";

	level.mapended = false; 

	level.hasspawned["flag"] = false;

	minefields = [];
	minefields = getentarray("minefield", "targetname");
	trigger_hurts = [];
	trigger_hurts = getentarray("trigger_hurt", "classname");

	level.flag_returners = minefields;
	for(i = 0; i < trigger_hurts.size; i++)
		level.flag_returners[level.flag_returners.size] = trigger_hurts[i];

	thread InitFlag();
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
	lpselfGuid = self getGuid();
	logPrint("J;" + lpselfGuid + ";" + lpselfnum + ";" + self.name + "\n");

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
		self.sessionteam = "none";
		
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

	if (! level.splitscreen)
		iprintlnFIXED (&"MP_DISCONNECTED", self);

	if (level.xenon)
		if(isdefined(self.clientid))
			setplayerteamrank(self, self.clientid, 0);

	lpselfnum = self getEntityNumber();
	lpselfGuid = self getGuid();
	logPrint("Q;" + lpselfGuid + ";" + lpselfnum + ";" + self.name + "\n");
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if (self.sessionteam == "spectator")
		return;

	// Don't do knockback if the damage direction was not specified
	if(!isDefined(vDir))
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	// check for completely getting out of the damage
	if(!(iDFlags & level.iDFLAGS_NO_PROTECTION))
	{
		// Make sure at least one point of damage is done
		if(iDamage < 1)
			iDamage = 1;

		self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

		// Shellshock/Rumble
		self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
		self playrumble("damage_heavy");

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
			doKillcam = false;
		else
		{
			attackerNum = attacker getEntityNumber();
			doKillcam = true;

			// Was the flagcarrier killed?
			if(isdefined(flagcarrier))
			{
				attacker iprintlnbold (&"IHTF_YOU_KILLED_FLAG_CARRIER");
				attacker AnnounceOthers (&"IHTF_KILLED_FLAG_CARRIER", attacker);
				attacker.score += level.PointsForKillingFlagCarrier;
			}
			else
			{
				if ((level.PointsForKillingPlayers > 0) || ((level.PointsForKillingPlayers < 0) && (! isdefined (attacker.flag))))
					attacker.score += level.PointsForKillingPlayers;
			}
			
			attacker checkScoreLimit ();
		}

		lpattacknum = attacker getEntityNumber();
		lpattackguid = attacker getGuid();
		lpattackname = attacker.name;
		lpattackerteam = attacker.pers["team"];
		
		attacker notify("update_playerhud_score");
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		doKillcam = false;

		self.score--;

		lpattacknum = -1;
		lpattackname = "";
		lpattackguid = "";
		lpattackerteam = "world";
		
		self notify("update_playerhud_score");
	}

	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

	// Stop thread if map ended on this death
	if(level.mapended)
		return;

	self.switching_teams = undefined;

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

	self.sessionteam = "none";
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.statusicon = "";
	self.maxhealth = 100;
	self.health = self.maxhealth;
	self.dead_origin = undefined;
	self.dead_angles = undefined;

	spawnpoints = level.playerspawnpoints;
	
	// Find a spawn point away from the flag
	spawnpoint = undefined;
	for (i = 0; i < 50; i ++)
	{
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random (spawnpoints);
		if (spawnpoint isAwayFromFlag ())
			break;
	}

	if(isDefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO PLAYER SPAWNPOINTS IN MAP");

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

	if (! level.splitscreen)
	{
		if (level.scorelimit > 0)
			self setClientCvar ("cg_objectiveText", &"IHTF_OBJ_TEXT", level.scorelimit);
		else
			self setClientCvar ("cg_objectiveText", &"IHTF_OBJ_TEXT_NOSCORE");
	}
	else
		self setClientCvar ("cg_objectiveText", &"IHTF_OBJ_TEXT_NOSCORE");

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

	if (! level.splitscreen)
	{
		if (level.scorelimit > 0)
			self setClientCvar ("cg_objectiveText", &"IHTF_OBJ_TEXT", level.scorelimit);
		else
			self setClientCvar ("cg_objectiveText", &"IHTF_OBJ_TEXT_NOSCORE");
	}
	else
		self setClientCvar ("cg_objectiveText", &"IHTF_OBJ_TEXT_NOSCORE");
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

	self.sessionteam = "none";
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

	self allowSpectateTeam ("freelook", cvardef ("scr_spectatefree", 0, 0, 1, "int"));
	self allowSpectateTeam ("none", cvardef ("scr_spectateenemy", 0, 0, 1, "int"));

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
// AWE ->
	awe\_global::EndMap ();
// AWE <-

	game["state"] = "intermission";
	level notify("intermission");

	players = getentarray("player", "classname");
	highscore = undefined;
	tied = undefined;
	playername = undefined;
	playerteam = undefined;
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
			playerteam = player.pers["team"];
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

			// since this is a free-for-all game type, give every player their own team number
			setplayerteamrank(player, player.clientid, rank);
		}
		sendranks();
	}

	wait 15;
	exitLevel(false);
}

checkTimeLimit()
{
	flagtimepassed = (getTime () - level.startflagtime) / 1000;
	if ((level.flag.atbase || (! level.flag.stolen)) && (flagtimepassed >= level.flagtimeout))
	{
		iprintln (&"IHTF_FLAG_TIMEOUT", level.flagtimeout);

		// Hide the flag
		level.flag.basemodel hide ();
		level.flag.flagmodel hide ();
		level.flag.compassflag = level.compassflag_none;
		level.flag.objpointflag = level.objpointflag_none;

		// Prevent players from stealing it until it respawns
		level.flag.stolen = true;

		// Respawn the flag		
		level.flag returnFlag ();
	}

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
		timelimit = cvardef("scr_ihtf_timelimit",30,0,1440,"float");
		if(level.timelimit != timelimit)
		{
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

		scorelimit = cvardef("scr_ihtf_scorelimit",30,0,9999,"int");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
			setCvar("ui_scorelimit", level.scorelimit);
			level notify ("update_allhud_score");

			players = getentarray("player", "classname");
			for(i = 0; i < players.size; i++)
				players[i] checkScoreLimit();
		}

		wait 1;
	}
}

pickupFlag(flag)
{
	// What is my team?
	myteam = self.pers["team"];
	if(myteam == "allies")
		otherteam = "axis";
	else
		otherteam = "allies";

	flag.origin = flag.origin + (0, 0, -10000);
	flag.flagmodel hide();
	flag.flagmodel setmodel("xmodel/prop_flag_" + game[myteam]);
	self.flag = flag;


	flag.team = myteam;
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
	objective_team(self.flag.objective, "none");

	self playsound("ctf_touchenemy");
	self attachFlag();
}

dropFlag()
{
	if(isdefined(self.flag))
	{
		level.holdtime = 0;
		level.totalholdtime = 0;

		UpdateHud();

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

		self.flag createFlagWaypoint();

		self detachFlag(self.flag);

		// check if it's in a flag_returner
		for(i = 0; i < level.flag_returners.size; i++)
		{
			if(self.flag.flagmodel istouching(level.flag_returners[i]))
			{
				self.flag.compassflag = level.compassflag_none;
				self.flag.objpointflag = level.objpointflag_none;
				self.flag thread returnFlag();
				break;
			}
		}

		self.flag = undefined;
		
		level.startflagtime = getTime ();
	}
}

returnFlag()
{
	self deleteFlagWaypoint();
	objective_delete(self.objective);

	if(!level.hasspawned["flag"])
	{
		self.origin = self.home_origin;
 		self.flagmodel.origin = self.home_origin;
	 	self.flagmodel.angles = self.home_angles;
		if(level.randomflagspawns)	level.hasspawned["flag"] = true;
	}
	else
	{
		spawnpoints = level.flagspawnpoints;

		// Find a new spawn point for the flag
		spawnpoint = undefined;
		for (i = 0; i < 50; i ++)
		{
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random (spawnpoints);
			if (spawnpoint.origin != self.origin)
				break;
		}

		self.origin = spawnpoint.origin;
 		self.flagmodel.origin = spawnpoint.origin;
	 	self.flagmodel.angles = spawnpoint.angles;
		self.basemodel.origin = spawnpoint.origin;
	 	self.basemodel.angles = spawnpoint.angles;
	}

	// Wait delay before spawning flag
	wait level.flagspawndelay + 0.05;

	self.flagmodel show();
	self.basemodel show();
	self.atbase = true;
	self.stolen = false;

	// set compass flag position on player
	objective_add(self.objective, "current", self.origin, self.compassflag);
	objective_position(self.objective, self.origin);
	objective_state(self.objective, "current");

	self createFlagWaypoint();
	
	level.holdtime = 0;
	level.totalholdtime = 0;

	UpdateHud();

	level.startflagtime = getTime ();
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
	self.waypoint = waypoint;
}

deleteFlagWaypoint()
{
// AWE ->
	if (! level.awe_objectivepoints)
		return;
// AWE <-

	if(isdefined(self.waypoint))
		self.waypoint destroy();
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
/*
	gametype = getcvar("g_gametype");	// "tdm", "bel", etc.
*/
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

AnnounceOthers (locstring, player)
{
	players = getentarray ("player", "classname");
	for (i = 0; i < players.size; i++)
	{
		if (players[i] == self)
			continue;

		iprintlnFIXED (locstring, player, players[i]);
	}
}

InitFlag()
{
	// Get map name
	mapname = getcvar("mapname");

	// Look for cvars
	x = getcvar("scr_ihtf_home_x_" + mapname);
	y = getcvar("scr_ihtf_home_y_" + mapname);
	z = getcvar("scr_ihtf_home_z_" + mapname);
	a = getcvar("scr_ihtf_home_a_" + mapname);

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
	}
	origin = position;

	// Spawn a script origin
	level.flag = spawn("script_origin",origin);
	level.flag.targetname = "ihtf_flaghome";
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
	level.flag.objective = 0;
	level.flag.compassflag = level.compassflag_none;
	level.flag.objpointflag = level.objpointflag_none;

	wait 0.05;

	SetupHud();

	level.flag returnFlag();
}

GetFlagPoint()
{
	// Get nearest spawn

	spawnpoints = level.flagspawnpoints;
	flagpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

	return flagpoint;
}

CheckForFlag()
{
	level endon("intermission");

	self.flag = undefined;
	count=0;

	// What is my team?
	myteam = self.pers["team"];
	if(myteam == "allies")
		otherteam = "axis";
	else
		otherteam = "allies";
	
	while (isAlive(self) && self.sessionstate=="playing" && myteam == self.pers["team"]) 
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
				
				self iprintlnbold (&"IHTF_YOU_STOLE_FLAG");
				self AnnounceOthers (&"IHTF_STOLE_FLAG", self);

				// Get personal score
				self.score += level.PointsForStealingFlag;

				lpselfnum = self getEntityNumber();
				lpselfguid = self getGuid();
				logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + self.name + ";" + "ihtf_stole" + "\n");

				self notify("update_playerhud_score");

				self checkScoreLimit();
				
				count = 0;
			}
		}

		// Update objective on compass
		if(isdefined(self.flag))
		{
			// Update the objective
			objective_position(self.flag.objective, self.origin);

			wait 0.05;

			// Make sure flag still exist
			if(isdefined(self.flag))
			{
				// Check hold time every second
				count++;
				if(count>=20)
				{
					count = 0;
				
					level.holdtime ++;
					level.totalholdtime ++;
					
					if (level.totalholdtime >= level.MaxHoldTime)
					{
						iprintln (&"IHTF_FLAG_MAXTIME", level.MaxHoldTime);

						level.holdtime = 0;
						level.totalholdtime = 0;

						lpselfnum = self getEntityNumber();
						lpselfguid = self getGuid();
						logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + self.name + ";" + "ihtf_maxheld" + "\n");
						
						self detachFlag(self.flag);
						self.flag.compassflag = level.compassflag_none;
						self.flag.objpointflag = level.objpointflag_none;

						self.flag thread ReturnFlag();
						self.flag = undefined;	
					}

					if (level.holdtime >= level.HoldTimeToScore)
					{
						iprintln (&"IHTF_FLAG_CARRIER_SCORES", level.PointsForHoldingFlag);
						self.score += level.PointsForHoldingFlag;

						level.holdtime = 0;

						lpselfnum = self getEntityNumber();
						lpselfguid = self getGuid();
						logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + self.name + ";" + "ihtf_scored" + "\n");

						self notify("update_playerhud_score");

						self checkScoreLimit ();
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

isAwayFromFlag ()
{
	if (distance (self.origin, level.flag.origin) >= level.spawndistance)
		return true;
	else
		return false;
}

SetupHud()
{
	y = 10;

	level.cursorleft = newHudElem();
	level.cursorleft.x = 320;
	level.cursorleft.y = y;
	level.cursorleft.alignX = "right";
	level.cursorleft.alignY = "middle";
	level.cursorleft.color = (1,0,0);
	level.cursorleft.alpha = 0.4;
	level.cursorleft setShader("white", 1, 10);

	level.cursorright = newHudElem();
	level.cursorright.x = 320;
	level.cursorright.y = y;
	level.cursorright.alignX = "left";
	level.cursorright.alignY = "middle";
	level.cursorright.color = (0,0,1);
	level.cursorright.alpha = 0.4;
	level.cursorright setShader("white", 1, 10);
}

UpdateHud()
{
	y = 10;
	barsize = 200;

	left = int (level.holdtime * barsize / (level.HoldTimeToScore - 1) + 1);
	right = int (level.totalholdtime * barsize / (level.MaxHoldTime - 1) + 1);

	if (level.holdtime != level.holdtime_old)
		level.cursorleft scaleOverTime (1, left, 10);
	if (level.totalholdtime != level.totalholdtime_old)
		level.cursorright scaleOverTime (1, right, 10);
		
	level.holdtime_old = level.holdtime;
	level.totalholdtime_old = level.totalholdtime;
}

AddToSpawnArray (array, spawntype, customclassname)
{
	spawnpoints = getentarray (spawntype, "classname");
	for (i = 0; i < spawnpoints.size; i ++)
	{
		s = array.size;
		origin = FixSpawnPoint (spawnpoints[i].origin);
		array[s] = spawn ("script_origin", origin);
		array[s].origin = origin;
		array[s].angles = spawnpoints[i].angles;
		array[s].targetname = customclassname;
		array[s] placeSpawnpoint ();
	}
	
	return (array);
}

AddToSpawnArrayCTFFlags (array, customclassname)
{
	if ((! isdefined (level.ctfflagspos[0])) || (! isdefined (level.ctfflagspos[1])))
		return (array);
		
	s = array.size;
	origin = FixSpawnPoint (level.ctfflagspos[0].origin);
	array[s] = spawn ("script_origin", origin);
	array[s].origin = origin;
	array[s].angles = level.ctfflagspos[0].angles;
	array[s].targetname = customclassname;
	array[s] placeSpawnpoint ();
	
	origin = FixSpawnPoint (level.ctfflagspos[1].origin);
	array[s + 1] = spawn ("script_origin", origin);
	array[s + 1].origin = origin;
	array[s + 1].angles = level.ctfflagspos[1].angles;
	array[s + 1].targetname = customclassname;
	array[s + 1] placeSpawnpoint ();

	return (array);
}

SaveCTFFlagsPos ()
{
	allied_flags = getentarray ("allied_flag", "targetname");
	axis_flags = getentarray ("axis_flag", "targetname");
	
	if ((allied_flags.size != 1) || (axis_flags.size != 1))
		return;

	allied_flag = getent ("allied_flag", "targetname");
	axis_flag = getent ("axis_flag", "targetname");
	
	level.ctfflagspos[0] = spawnstruct ();
	level.ctfflagspos[0].origin = allied_flag.origin;
	level.ctfflagspos[0].angles = allied_flag.angles;
	level.ctfflagspos[1] = spawnstruct ();
	level.ctfflagspos[1].origin = axis_flag.origin;
	level.ctfflagspos[1].angles = axis_flag.angles;
}

AddToSpawnArraySDbombzones (array, customclassname)
{
	if ((! isdefined (level.sdbombzonepos[0])) || (! isdefined (level.sdbombzonepos[1])))
		return (array);

	s = array.size;
	for (i = 0; i <= 1; i ++)
	{
		origin = FixSpawnPoint (level.sdbombzonepos[i].origin);
		array[s + i] = spawn ("script_origin", origin);
		array[s + i].origin = origin;
		array[s + i].angles = level.sdbombzonepos[i].angles;
		array[s + i].targetname = customclassname;
		array[s + i] placeSpawnpoint ();
	}

	return (array);
}

SaveSDBombzonesPos ()
{
	bombzones = getentarray ("bombzone", "targetname");
	if (isdefined (bombzones[0]))
	{
		level.sdbombzonepos[0] = spawnstruct ();
		level.sdbombzonepos[0].origin = bombzones[0].origin;
		level.sdbombzonepos[0].angles = bombzones[0].angles;
	}
	if (isdefined (bombzones[1]))
	{
		level.sdbombzonepos[1] = spawnstruct ();
		level.sdbombzonepos[1].origin = bombzones[1].origin;
		level.sdbombzonepos[1].angles = bombzones[1].angles;
	}
}

AddToSpawnArrayHQRadios (array, customclassname)
{
	if (! isdefined (level.radio))
		return (array);

	for (i = 0; i < level.radio.size; i ++)
	{
		s = array.size;
		origin = FixSpawnPoint (level.radio[i].origin);
		array[s] = spawn ("script_origin", origin);
		array[s].origin = origin;
		array[s].angles = level.radio[i].angles;
		array[s].targetname = customclassname;
		array[s] placeSpawnpoint ();
	}
	
	return (array);
}

RemoveHQRadioPoints ()
{
	if (! isdefined (level.radio))
		return;

	for (i = 0; i < level.radio.size; i ++)
		level.radio[i] delete ();

	level.radio = undefined;
}

SpawnPointsArray (modestring, customclassname)
{
	modearray = strtok (modestring, " ");
	activespawntype = [];
	for (i = 0; i < modearray.size; i ++)
	{
		switch (modearray[i])
		{
			case "dm" :
			case "tdm" :
			case "ctfp" :
			case "ctff" :
			case "sdp" :
			case "sdb" :
			case "hq" :
				activespawntype[modearray[i]] = true;
				break;
			default :
				break;
		}
	}

	array = [];

	if (isdefined (activespawntype["dm"]))
		array = AddToSpawnArray (array, "mp_dm_spawn", customclassname);

	if (isdefined (activespawntype["tdm"]))
		array = AddToSpawnArray (array, "mp_tdm_spawn", customclassname);
	
	if (isdefined (activespawntype["ctfp"]))
	{
		array = AddToSpawnArray (array, "mp_ctf_spawn_allied", customclassname);
		array = AddToSpawnArray (array, "mp_ctf_spawn_axis", customclassname);
	}
	
	if (isdefined (activespawntype["sdp"]))
	{
		array = AddToSpawnArray (array, "mp_sd_spawn_attacker", customclassname);
		array = AddToSpawnArray (array, "mp_sd_spawn_defender", customclassname);
	}
	
	if (isdefined (activespawntype["ctff"]))
		array = AddToSpawnArrayCTFFlags (array, customclassname);
	
	if (isdefined (activespawntype["sdb"]))
		array = AddToSpawnArraySDBombzones (array, customclassname);
	
	if (isdefined (activespawntype["hq"]))
		array = AddToSpawnArrayHQRadios (array, customclassname);

	return (array);
}

FixSpawnPoint (position)
{
	return (physicstrace (position + (0, 0, 20), position + (0, 0, -20)));
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