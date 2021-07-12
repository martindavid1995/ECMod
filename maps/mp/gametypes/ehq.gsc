/*
	Enhanced HQ - AWE mod compatible version
	Author : La Truffe
	
	Credits : Bell (AWE mod), Ravir (cvardef function)
	
	Version : 1.3

	Objective: 	Establish a headquarters and gain points as long as your team controls it
	Map ends:	When one teams score reaches the score limit, or time limit is reached
	Respawning:	Attackers respawn after a configurable delay, defenders can respawn with an extra delay or stay dead

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

		Radio Position information:
			To add radios to your map add a section to your level script similar to the one below. To get the origin and angles
			values easily it is recommended that you temporarily place radio models in your level and copy the origin and angles
			values to your script. The reason these are in script and not the level itself is so radio positions can easily be
			changed if needed. See the official level scripts for more examples.

			if(getcvar("g_gametype") == "hq")
			{
				level.radio = [];
				level.radio[0] = spawn("script_model", (174, -310, 16));
				level.radio[0].angles = (0, 57, 0);
				level.radio[1] = spawn("script_model", (-31, -32, 16));
				level.radio[1].angles = (0, 1, 0);
				level.radio[2] = spawn("script_model", (-299, -277, 16));
				level.radio[2].angles = (0, 312, 0);
			}

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
	// Trick : pretend we're on standard HQ gametype to benefit from the level.radio definitions in the map script
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
}

Callback_StartGameType()
{
	// Trick : restore EHQ gametype
	setcvar ("g_gametype", "ehq");

	level.splitscreen = isSplitScreen();

	// defaults if not defined in level script
	if(!isdefined(game["allies"]))
		game["allies"] = "american";
	if(!isdefined(game["axis"]))
		game["axis"] = "german";

	// server cvar overrides
	allies = cvardef ("scr_allies", "", "", "", "string");
	if (allies != "")
		game["allies"] = allies;
	axis = cvardef ("scr_axis", "", "", "", "string");
	if (axis != "")
		game["axis"] = axis;

	game["radio_prespawn"][0] = "objectiveA";
	game["radio_prespawn"][1] = "objectiveB";
	game["radio_prespawn"][2] = "objective";
	game["radio_prespawn_objpoint"][0] = "objpoint_A";
	game["radio_prespawn_objpoint"][1] = "objpoint_B";
	game["radio_prespawn_objpoint"][2] = "objpoint_star";
	game["radio_none"] = "objective";
	game["radio_axis"] = "objective_" + game["axis"];
	game["radio_allies"] = "objective_" + game["allies"];

	//custom radio colors for different nationalities
	if(game["allies"] == "american")
		game["radio_model"] = "xmodel/military_german_fieldradio_green_nonsolid";
	else if(game["allies"] == "british")
		game["radio_model"] = "xmodel/military_german_fieldradio_tan_nonsolid";
	else if(game["allies"] == "russian")
		game["radio_model"] = "xmodel/military_german_fieldradio_grey_nonsolid";
	assert(isdefined(game["radio_model"]));

	precacheShader("white");
	precacheShader("objective");
	precacheShader("objectiveA");
	precacheShader("objectiveB");
	precacheShader("objective");
	precacheShader("objpoint_A");
	precacheShader("objpoint_B");
	precacheShader("objpoint_radio");
	precacheShader("field_radio");
	precacheShader(game["radio_allies"]);
	precacheShader(game["radio_axis"]);
	precacheStatusIcon("hud_status_dead");
	precacheStatusIcon("hud_status_connecting");
	precacheRumble("damage_heavy");
	precacheModel(game["radio_model"]);
	precacheString(&"MP_TIME_TILL_SPAWN");
	precacheString(&"MP_ESTABLISHING_HQ");
	precacheString(&"MP_DESTROYING_HQ");
	precacheString(&"MP_LOSING_HQ");
	precacheString(&"MP_MAXHOLDTIME_MINUTESANDSECONDS");
	precacheString(&"MP_MAXHOLDTIME_MINUTES");
	precacheString(&"MP_MAXHOLDTIME_SECONDS");
	precacheString(&"MP_UPTEAM");
	precacheString(&"MP_DOWNTEAM");
	precacheString(&"MP_RESPAWN_WHEN_RADIO_NEUTRALIZED");
	precacheString(&"MP_MATCHSTARTING");
	precacheString(&"MP_MATCHRESUMING");
	precacheString(&"PLATFORM_PRESS_TO_SPAWN");
	precacheString (&"EHQ_OBJ_TEXT_NOSCORE");
	precacheString (&"EHQ_TEAMKILLED_ENGINEER");
	precacheString (&"EHQ_KILLED_ENGINEER");
	precacheString (&"EHQ_PLAYERS_ESTABLISH");
	precacheString (&"EHQ_PLAYERS_DESTROY");
	precacheString (&"EHQ_CAPTURE_TIMEOUT");
	precacheString (&"EHQ_ESTABLISHED");
	precacheString (&"EHQ_DESTROYED");
	precacheString (&"EHQ_BECOME_ENGINEER1");
	precacheString (&"EHQ_BECOME_ENGINEER2");
	precacheString (&"EHQ_NO_LONGER_ENGINEER1");
	precacheString (&"EHQ_NO_LONGER_ENGINEER2");
	precacheString (&"EHQ_ENGINEER_LEFT");

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
	level.graceperiod = true;

	spawnpointname = "mp_tdm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	level._effect["radioexplosion"] = loadfx("fx/explosions/grenadeExp_blacktop.efx");

	allowed[0] = "tdm";
	maps\mp\gametypes\_gameobjects::main(allowed);

	// Time limit per map
	level.timelimit = cvardef ("scr_ehq_timelimit", 30, 0, 1440, "float");
	setCvar("ui_timelimit", level.timelimit);
	makeCvarServerInfo("ui_timelimit", "30");

	// Score limit per map
	level.scorelimit = cvardef ("scr_ehq_scorelimit", 450, 0, 9999, "int");
	setCvar("ui_scorelimit", level.scorelimit);
	makeCvarServerInfo("ui_scorelimit", "450");

	// Useless : already done in _friendicons::init
/*
	// Draws a team icon over teammates
	if(getcvar("scr_drawfriend") == "")
		setcvar("scr_drawfriend", "1");
	level.drawfriend = getcvarint("scr_drawfriend");
*/

	if(!isdefined(game["state"]))
		game["state"] = "playing";

	level.mapended = false;
	level.roundStarted = false;

	level.team["allies"] = 0;
	level.team["axis"] = 0;

	// Z Distance players must be from a radio to capture/neutralize it
	level.zradioradius = cvardef ("scr_ehq_zradioradius", 72, 1, 9999, "int");
	level.captured_radios["allies"] = 0;
	level.captured_radios["axis"] = 0;

	level.progressBarHeight = 12;

	if(level.splitscreen)
		level.progressBarWidth = 152;
	else
		level.progressBarWidth = 192;

	level.RadioSpawnDelay = cvardef ("scr_ehq_radiospawndelay", 15, 0, 9999, "int");
	setCvar ("ui_ehq_radiospawndelay", level.RadioSpawnDelay);
	storeServerInfoDvar ("ui_ehq_radiospawndelay");

	level.radioradius = cvardef ("scr_ehq_radioradius", 120, 0, 9999, "int");

	level.respawngracetime = 5;

	level.RadioMaxHoldSeconds = cvardef ("scr_ehq_radiomaxholdseconds", 120, 1, 9999, "int");
	setCvar ("ui_ehq_RadioMaxHoldSeconds", level.RadioMaxHoldSeconds);
	storeServerInfoDvar ("ui_ehq_RadioMaxHoldSeconds");

	level.ehq_spawndistance = cvardef ("scr_ehq_spawndistance", 500, 1, 9999, "int");

	level.timesCaptured = 0;
	level.nextradio = 0;
	level.spawnframe = 0;
	level.DefendingRadioTeam = "none";
	level.NeutralizingPoints = 10;
	level.ehq_PlayersToEstablish = 0;
	level.ehq_PlayersToDestroy = 0;
	level.ehq_numplayers = [];
	level.ehq_PlayersToCapture = [];
	level.ehq_PlayersToCapture["allies"] = 0;
	level.ehq_PlayersToCapture["axis"] = 0;
	level.ehq_hudradioicon = [];
	level.ehq_hudradionumber = [];

	level.ehq_MultipleEstablishBias = cvardef ("scr_ehq_establishspeed", 100, 1, 9999, "int") / 100;
	level.ehq_MultipleDestroyBias = cvardef ("scr_ehq_destroyspeed", 100, 1, 9999, "int") / 100;
	
	level.respawndelay = cvardef ("scr_ehq_respawndelay", 10, 0, 600, "int");
	setCvar ("ui_ehq_respawndelay", level.respawndelay);
	storeServerInfoDvar ("ui_ehq_respawndelay");

	level.ehq_DefendersCanRespawn = cvardef ("scr_ehq_defenderscanrespawn", 0, 0, 1, "int");
	setCvar ("ui_ehq_DefendersCanRespawn", level.ehq_DefendersCanRespawn);
	storeServerInfoDvar ("ui_ehq_DefendersCanRespawn");

	level.ehq_DefendersRespawnDelayPenalty = cvardef ("scr_ehq_defendersrespawndelaypenalty", 0, 0, 999, "int");
	setCvar ("ui_ehq_DefendersRespawnDelayPenalty", level.ehq_DefendersRespawnDelayPenalty);
	storeServerInfoDvar ("ui_ehq_DefendersRespawnDelayPenalty");

	level.ehq_DestroyHQIfAllDefendersDead = cvardef ("scr_ehq_destroyhqifalldefendersdead", 1, 0, 1, "int");

	level.ehq_PlayersToEstablish_dvar = cvardef ("scr_ehq_playerstoestablish", 1, 0, 99, "int");
	setCvar ("ui_ehq_PlayersToEstablish", level.ehq_PlayersToEstablish_dvar);
	storeServerInfoDvar ("ui_ehq_PlayersToEstablish");

	level.ehq_PlayersToDestroy_dvar = cvardef ("scr_ehq_playerstodestroy", 1, 0, 99, "int");
	setCvar ("ui_ehq_PlayersToDestroy", level.ehq_PlayersToDestroy_dvar);
	storeServerInfoDvar ("ui_ehq_PlayersToDestroy");
	
	level.ehq_PlayersToEstablishRandom = cvardef ("scr_ehq_playerstoestablishrandom", 0, 0, 1, "int");
	setCvar ("ui_ehq_PlayersToEstablishRandom", level.ehq_PlayersToEstablishRandom);
	storeServerInfoDvar ("ui_ehq_PlayersToEstablishRandom");
	
	level.ehq_PlayersToDestroyRandom = cvardef ("scr_ehq_playerstodestroyrandom", 0, 0, 1, "int");
	setCvar ("ui_ehq_PlayersToDestroyRandom", level.ehq_PlayersToDestroyRandom);
	storeServerInfoDvar ("ui_ehq_PlayersToDestroyRandom");

	level.ehq_RadioCaptureTimeOut = cvardef ("scr_ehq_radiocapturetimeOut", 120, 1, 9999, "int");
	setCvar ("ui_ehq_RadioCaptureTimeOut", level.ehq_RadioCaptureTimeOut);
	storeServerInfoDvar ("ui_ehq_RadioCaptureTimeOut");
	
	level.ehq_PointsForEstablish = cvardef ("scr_ehq_pointsforestablish", 0, 0, 99, "int");
	setCvar ("ui_ehq_PointsForEstablish", level.ehq_PointsForEstablish);
	storeServerInfoDvar ("ui_ehq_PointsForEstablish");

	level.ehq_PointsForDestroy = cvardef ("scr_ehq_pointsfordestroy", 0, 0, 99, "int");
	setCvar ("ui_ehq_PointsForDestroy", level.ehq_PointsForDestroy);
	storeServerInfoDvar ("ui_ehq_PointsForDestroy");

	level.ehq_EngineerMode = cvardef ("scr_ehq_engineermode", 0, 0, 1, "int");
	setCvar ("ui_ehq_engineermode", level.ehq_EngineerMode);
	storeServerInfoDvar ("ui_ehq_engineermode");

	level.ehq_MaxEngineers = cvardef ("scr_ehq_maxengineers", 1, 0, 99, "int");
	level.ehq_PointsForKillingEngineer = cvardef ("scr_ehq_pointsforkillingengineer", 1, 0, 99, "int");

	level.ehq_ABPoints = cvardef ("scr_ehq_abpoints", 0, 0, 1, "int");

	level.ehq_RadioPointsMode = cvardef ("scr_ehq_radiopointsmode", 0, 0, 2, "int");

	level.ehq_capturenoweapon = cvardef ("scr_ehq_capturenoweapon", 0, 0, 1, "int");
	setCvar ("ui_ehq_capturenoweapon", level.ehq_capturenoweapon);
	storeServerInfoDvar ("ui_ehq_capturenoweapon");

	if (EHQ_GetEngineerMode ())
	{
		precacheHeadIcon ("objpoint_radio");
		precacheStatusIcon ("objpoint_radio");
	}

	hq_setup();

	thread EHQ_MonitorTeams ();

	thread hq_points();
	thread startGame();
	thread updateGametypeCvars();
	thread maps\mp\gametypes\_teams::addTestClients ();
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

	if(isdefined(self.pers["team"]) && self.pers["team"] != "spectator")
	{
		self setClientCvar("ui_allow_weaponchange", "1");

		if(self.pers["team"] == "allies")
			self.sessionteam = "allies";
		else
			self.sessionteam = "axis";

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

	if (EHQ_GetEngineerMode ())
		self EHQ_CheckIfEngineerLeft ();

	lpselfnum = self getEntityNumber();
	lpGuid = self getGuid();
	logPrint("Q;" + lpGuid + ";" + lpselfnum + ";" + self.name + "\n");
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(self.sessionteam == "spectator")
		return;

	friendly = undefined;

	// Don't do knockback if the damage direction was not specified
	if(!isdefined(vDir))
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

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
		lpselfname = self.name;
		lpselfteam = self.pers["team"];
		lpselfGuid = self getGuid();
		lpattackerteam = "";

		if(isPlayer(eAttacker))
		{
			lpattacknum = eAttacker getEntityNumber();
			lpattackname = eAttacker.name;
			lpattackGuid = eAttacker getGuid();
			lpattackerteam = eAttacker.pers["team"];
		}
		else
		{
			lpattacknum = -1;
			lpattackGuid = "";
			lpattackname = "";
			lpattackerteam = "world";
		}

		if(isdefined(friendly))
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

	doKillcam = false;

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
			{
				attacker.score--;
				if (EHQ_GetEngineerMode () && (self EHQ_IsEngineer ()))
				{
					attacker.score -= level.ehq_PointsForKillingEngineer;
					iprintlnFIXED (&"EHQ_TEAMKILLED_ENGINEER", attacker);
				}
			}
			else
			{
				attacker.score++;
				if (EHQ_GetEngineerMode () && (self EHQ_IsEngineer ()))
				{
					attacker.score += level.ehq_PointsForKillingEngineer;
					iprintlnFIXED (&"EHQ_KILLED_ENGINEER", attacker);
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

	level hq_removeall_hudelems(self);

	body = self cloneplayer(deathAnimDuration);
	thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"], 5);

	defendingBeforeDeath = true;
	if((isdefined(self.pers["team"])) && (level.DefendingRadioTeam != self.pers["team"]))
		defendingBeforeDeath = false;

	defendingAfterDeath = false;
	if((isdefined(self.pers["team"])) && (level.DefendingRadioTeam == self.pers["team"]))
		defendingAfterDeath = true;

	allowInstantRespawn = false;
	if((!defendingBeforeDeath) && (defendingAfterDeath))
		allowInstantRespawn = true;

	//check if it was the last person to die on the defending team
	level updateTeamStatus();
	if (level.ehq_DestroyHQIfAllDefendersDead)
		if((isdefined(self.pers["team"])) && (level.DefendingRadioTeam == self.pers["team"]) && (level.exist[self.pers["team"]] <= 0))
		{
			allowInstantRespawn = true;
			for(i = 0; i < level.radio.size; i++)
			{
				if(level.radio[i].hidden == true)
					continue;
				level hq_radio_capture(level.radio[i], "none");
				break;
			}
		}

	delay = 2;

	if((level.roundStarted) && (!allowInstantRespawn))
	{
		self thread respawn_timer(delay);
		if ((isdefined (self.pers["team"])) && (level.DefendingRadioTeam == self.pers["team"]) && (! level.ehq_DefendersCanRespawn))
			self thread respawn_staydead(delay);
	}

	wait delay;	// ?? Also required for Callback_PlayerKilled to complete before respawn/killcam can execute

	if(doKillcam && level.killcam)
		self maps\mp\gametypes\_killcam::killcam(attackerNum, delay, psOffsetTime);

	self thread respawn();
}

spawnPlayer()
{
	self endon("disconnect");

	if((!isdefined(self.pers["weapon"])) || (!isdefined(self.pers["team"])))
		return;

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
	// Find a spawn point away from the HQ
	spawnpoint = undefined;
	for (i = 0; i < 50; i ++)
	{
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam_AwayfromRadios (spawnpoints);
		if (spawnpoint IsAwayFromHQ ())
			break;
	}

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

	if(!isdefined(self))
		return;

	// Bug tracking...
	
	if ((! maps\mp\gametypes\_weapons::isMainWeapon (self.pers["weapon"])) && (! maps\mp\gametypes\_weapons::isPistol (self.pers["weapon"])))
		logprint ("DEBUG : spawnPlayer () self.pers[\"weapon\"] = \"" + self.pers["weapon"] + "\"\n");
	else
	{
		self giveWeapon (self.pers["weapon"]);
		self giveMaxAmmo (self.pers["weapon"]);
		self setSpawnWeapon (self.pers["weapon"]);
	}

	self setClientCvar ("cg_objectiveText", &"EHQ_OBJ_TEXT_NOSCORE");

	self thread updateTimer();

	if (self EHQ_IsEngineer ())
		self thread EHQ_FollowEngineer ();

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

	level hq_removeall_hudelems(self);
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

	if(isdefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");

	level hq_removeall_hudelems(self);
	self thread updateTimer();
}

respawn()
{
	self endon("disconnect");
	self endon("end_respawn");

	if(!isdefined(self.pers["weapon"]))
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

	while(isdefined(self.WaitingOnTimer) || ((self.pers["team"] == level.DefendingRadioTeam) && isdefined(self.WaitingOnNeutralize)))
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
// AWE ->
		awe\_global::EndMap ();
// AWE <-

	game["state"] = "intermission";
	level notify("intermission");

	alliedscore = getTeamScore("allies");
	axisscore = getTeamScore("axis");

	winners = undefined;
	losers = undefined;

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

	if((winningteam == "allies") || (winningteam == "axis"))
	{
		winners = "";
		losers = "";
	}

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
			if((isdefined(player.pers["team"])) && (player.pers["team"] == winningteam))
					winners = (winners + ";" + lpGuid + ";" + player.name);
			else if((isdefined(player.pers["team"])) && (player.pers["team"] == losingteam))
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
	wait 1;
	for(;;)
	{
		timelimit = cvardef ("scr_ehq_timelimit", 30, 0, 1440, "float");
		if(level.timelimit != timelimit)
		{
			level.timelimit = timelimit;
			setCvar ("ui_timelimit", level.timelimit);
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

		scorelimit = cvardef ("scr_ehq_scorelimit", 450, 0, 9999, "int");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
			setCvar ("ui_scorelimit", level.scorelimit);
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

hq_setup()
{
	wait 0.05;

	maperrors = [];

	if(!isdefined(level.radio))
		level.radio = getentarray("hqradio", "targetname");

	if (level.ehq_RadioPointsMode == 1)
	{
		for (i = 0; i < level.radio.size; i ++)
			level.radio[i] delete ();
		level.radio = [];
	}
	
	if (level.ehq_RadioPointsMode != 0)
		EHQ_CreateRadiosFromSpawnPoints ();

	if(level.radio.size < 3)
		maperrors[maperrors.size] = "^1Less than 3 entities found with \"targetname\" \"hqradio\"";

	if(maperrors.size)
	{
		println("^1------------ Map Errors ------------");
		for(i = 0; i < maperrors.size; i++)
			println(maperrors[i]);
		println("^1------------------------------------");

		return;
	}

	EHQ_RemoveScriptModels ();
	
	setTeamScore("allies", 0);
	setTeamScore("axis", 0);

	for(i = 0; i < level.radio.size; i++)
	{
		level.radio[i].team = "none";
		level.radio[i].holdtime_allies = 0;
		level.radio[i].holdtime_axis = 0;
		level.radio[i].hidden = true;

		if((!isdefined(level.radio[i].script_radius)) || (level.radio[i].script_radius <= 0))
			level.radio[i].radius = level.radioradius;
		else
			level.radio[i].radius = level.radio[i].script_radius;
	}

	hq_randomize_radioarray();

	level thread EHQ_all_radios_think ();

	level.ehq_numradioicons = [];
	level.ehq_numradioicons["allies"] = 0;
	level.ehq_numradioicons["axis"] = 0;

	level thread hq_obj_think();
}

hq_randomize_radioarray()
{
	for(i = 0; i < level.radio.size; i++)
	{
		rand = randomint(level.radio.size);
   	temp = level.radio[i];
   	level.radio[i] = level.radio[rand];
   	level.radio[rand] = temp;
	}
}

hq_obj_think(radio)
{
	NeutralRadios = 0;
	for(i = 0; i < level.radio.size; i++)
	{
		if(level.radio[i].hidden == true)
			continue;
		NeutralRadios++;
	}
	
	if(NeutralRadios <= 0)
	{
		if(level.nextradio > level.radio.size - 1)
		{
			hq_randomize_radioarray();
			level.nextradio = 0;

			if(isdefined(radio))
			{
				// same radio twice in a row so go to the next radio
				if(radio == level.radio[level.nextradio])
					level.nextradio++;
			}
		}

		//find a fake radio position that isn't the last position or the next position
		randAorB = undefined;
		if(level.radio.size >= 4)
		{
			fakeposition = level.radio[randomint(level.radio.size)];
			if(isdefined(level.radio[(level.nextradio - 1)]))
			{
				while((fakeposition == level.radio[level.nextradio]) || (fakeposition == level.radio[level.nextradio - 1]))
					fakeposition = level.radio[randomint(level.radio.size)];
			}
			else
			{
				while(fakeposition == level.radio[level.nextradio])
					fakeposition = level.radio[randomint(level.radio.size)];
			}
			randAorB = randomint(2);
			if (level.ehq_ABPoints)
			{
				objective_add(1, "current", fakeposition.origin, game["radio_prespawn"][randAorB]);
				thread maps\mp\gametypes\_objpoints::addObjpoint(fakeposition.origin, "1", game["radio_prespawn_objpoint"][randAorB]);
			}
		}
		
		if(!isdefined(randAorB))
			otherAorB = 2; //use original icon since there is only one objective that will show
		else if(randAorB == 1)
			otherAorB = 0;
		else
			otherAorB = 1;
			if (level.ehq_ABPoints)
			{
				objective_add(0, "current", level.radio[level.nextradio].origin, game["radio_prespawn"][otherAorB]);
				thread maps\mp\gametypes\_objpoints::addObjpoint(level.radio[level.nextradio].origin, "0", game["radio_prespawn_objpoint"][otherAorB]);
			}

		level hq_check_teams_exist();
		restartRound = false;
		
		while((!level.alliesexist) || (!level.axisexist))
		{
			restartRound = true;
			wait 2;
			level hq_check_teams_exist();
		}
		
		if(restartRound)
			restartRound();
		level.roundStarted = true;

		iprintln(&"MP_RADIOS_SPAWN_IN_SECONDS", level.RadioSpawnDelay);
		wait level.RadioSpawnDelay;

		level.radio[level.nextradio] EHQ_RadioShow ();
		level.radio[level.nextradio].hidden = false;

		level thread playSoundOnPlayers("explo_plant_no_tick");
		objective_add(0, "current", level.radio[level.nextradio].origin, game["radio_prespawn"][2]);
		if (level.ehq_ABPoints)
		{
			objective_icon(0, game["radio_none"]);
			objective_delete(1);
		}
		thread maps\mp\gametypes\_objpoints::removeObjpoints();
		thread maps\mp\gametypes\_objpoints::addObjpoint(level.radio[level.nextradio].origin, "0", "objpoint_radio");

		if((level.captured_radios["allies"] <= 0) && (level.captured_radios["axis"] > 0)) // AXIS HAVE A RADIO AND ALLIES DONT
			objective_team(0, "allies");
		else if((level.captured_radios["allies"] > 0) && (level.captured_radios["axis"] <= 0)) // ALLIES HAVE A RADIO AND AXIS DONT
			objective_team(0, "axis");
		else // NO TEAMS HAVE A RADIO
			objective_team(0, "none");

		if (level.ehq_PlayersToEstablishRandom)
			level.ehq_PlayersToEstablish = randomint (level.ehq_PlayersToEstablish_dvar) + 1;
		else
			level.ehq_PlayersToEstablish = level.ehq_PlayersToEstablish_dvar;

		if (level.ehq_PlayersToDestroyRandom)
			level.ehq_PlayersToDestroy = randomint (level.ehq_PlayersToDestroy_dvar) + 1;
		else
			level.ehq_PlayersToDestroy = level.ehq_PlayersToDestroy_dvar;
		
		// Add a radio on the HUD of each team

		EHQ_update_HUD_radio ("allies", true);
		EHQ_update_HUD_radio ("axis", true);
		
		level.ehq_TimeToThinkMax = getTime () + (level.ehq_RadioCaptureTimeOut * 1000);
		
		level.nextradio++;
	}
}

EHQ_update_HUD_radio (team, mustcreate)
{
	if (! isdefined (level.ehq_hudradioicon[team]))
	{
		if (! mustcreate)
			return;
	}
	else
	{
		level.ehq_hudradioicon[team] destroy ();
		level.ehq_hudradionumber[team] destroy ();
	}
		
	icon = newTeamHudElem (team);
	icon.x = 320;
	icon.y = 18;
	icon.alignX = "center";
	icon.alignY = "middle";
	icon.horzAlign = "left";
	icon.vertAlign = "top";
	icon.alpha = 0.6;
	icon setShader ("field_radio", 30, 24);
	level.ehq_hudradioicon[team] = icon; 
		
	number = newTeamHudElem (team);
	number.x = 320;
	number.y = 18;
	number.alignX = "center";
	number.alignY = "middle";
	number.font = "default";
	number.fontscale = 1.5;
	number.alpha = 1;
	number.color = (1, 1, 0);
	number setValue (level.ehq_PlayersToCapture[team]);
	level.ehq_hudradionumber[team] = number; 
}

EHQ_all_radios_think ()
{
	level endon ("intermission");
	while (! level.mapended)
	{
		wait 0.05;
		
		for (i = 0; i < level.radio.size; i ++)
			hq_radio_think (level.radio[i]);
	}
}

hq_radio_think(radio)
{
	level endon("intermission");
/*
	while(!level.mapended)
	{
		wait 0.05;
*/
		if(!radio.hidden)
		{
			if ((radio.team == "none") && (getTime () > level.ehq_TimeToThinkMax))
			{
				// Timeout for capturing radio reached
				iprintln (&"EHQ_CAPTURE_TIMEOUT", level.ehq_RadioCaptureTimeOut);
				level hq_radio_capture (radio, "none");
				if (EHQ_GetEngineerMode ())
					EHQ_UnsetAllEngineers ();
//				continue;
				return;
			}

			players = getentarray("player", "classname");
			radio.allies = 0;
			radio.axis = 0;
			for(i = 0; i < players.size; i++)
			{
				if(isdefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
				{
					// Player is not an engineer
					if (EHQ_GetEngineerMode () && (! (players[i] EHQ_IsEngineer ())))
						continue;

					if(((distance(players[i].origin,radio.origin)) <= radio.radius) && (distance((0,0,players[i].origin[2]),(0,0,radio.origin[2])) <= level.zradioradius))
					{
						if(players[i].pers["team"] == radio.team)
							continue;

						if((level.captured_radios[players[i].pers["team"]] > 0) && (radio.team == "none"))
							continue;

						if((!isdefined(players[i].radioicon)) || (!isdefined(players[i].radioicon[0])))
						{
							players[i].radioicon[0] = newClientHudElem(players[i]);
							players[i].radioicon[0].x = 320;
							players[i].radioicon[0].y = 50;
							players[i].radioicon[0].alignX = "center";
							players[i].radioicon[0].alignY = "middle";
							players[i].radioicon[0].horzAlign = "left";
							players[i].radioicon[0].vertAlign = "top";
							players[i].radioicon[0] setShader("field_radio", 40, 32);
							level.ehq_numradioicons[players[i].pers["team"]] ++;
						}

						if((level.captured_radios[players[i].pers["team"]] <= 0) && (radio.team == "none"))
						{
							// Not enough players to capture radio
							if ((level.ehq_numradioicons[players[i].pers["team"]] < level.ehq_PlayersTocapture[players[i].pers["team"]]))
							{
								if (isdefined (players[i].progressbar_capture))
									players[i].progressbar_capture destroy ();
								if (isdefined (players[i].progressbar_capture2))
									players[i].progressbar_capture2 destroy ();
								if (isdefined (players[i].progressbar_capture3))
									players[i].progressbar_capture3 destroy ();
							
								continue;
							}

							if (level.ehq_capturenoweapon)
								players[i] thread EHQ_disableWeaponDuringCapture ();

							if(!isdefined(players[i].progressbar_capture))
							{
								players[i].progressbar_capture = newClientHudElem(players[i]);
								players[i].progressbar_capture.x = 0;

								if(level.splitscreen)
									players[i].progressbar_capture.y = 70;
								else
									players[i].progressbar_capture.y = 104;

								players[i].progressbar_capture.alignX = "center";
								players[i].progressbar_capture.alignY = "middle";
								players[i].progressbar_capture.horzAlign = "center_safearea";
								players[i].progressbar_capture.vertAlign = "center_safearea";
								players[i].progressbar_capture.alpha = 0.5;
							}
							players[i].progressbar_capture setShader("black", level.progressBarWidth, level.progressBarHeight);
							if(!isdefined(players[i].progressbar_capture2))
							{
								players[i].progressbar_capture2 = newClientHudElem(players[i]);
								players[i].progressbar_capture2.x = ((level.progressBarWidth / (-2)) + 2);

								if(level.splitscreen)
									players[i].progressbar_capture2.y = 70;
								else
									players[i].progressbar_capture2.y = 104;

								players[i].progressbar_capture2.alignX = "left";
								players[i].progressbar_capture2.alignY = "middle";
								players[i].progressbar_capture2.horzAlign = "center_safearea";
								players[i].progressbar_capture2.vertAlign = "center_safearea";
							}
							if(players[i].pers["team"] == "allies")
								players[i].progressbar_capture2 setShader ("white", EHQ_Round (radio.holdtime_allies), level.progressBarHeight - 4);
							else
								players[i].progressbar_capture2 setShader ("white", EHQ_Round (radio.holdtime_axis), level.progressBarHeight - 4);

							if(!isdefined(players[i].progressbar_capture3))
							{
								players[i].progressbar_capture3 = newClientHudElem(players[i]);
								players[i].progressbar_capture3.x = 0;

								if(level.splitscreen)
									players[i].progressbar_capture3.y = 16;
								else
									players[i].progressbar_capture3.y = 50;

								players[i].progressbar_capture3.alignX = "center";
								players[i].progressbar_capture3.alignY = "middle";
								players[i].progressbar_capture3.horzAlign = "center_safearea";
								players[i].progressbar_capture3.vertAlign = "center_safearea";
								players[i].progressbar_capture3.archived = false;
								players[i].progressbar_capture3.font = "default";
								players[i].progressbar_capture3.fontscale = 2;
								players[i].progressbar_capture3 settext(&"MP_ESTABLISHING_HQ");
							}
						}
						else if(radio.team != "none")
						{
							// Not enough players to capture radio
							if ((level.ehq_numradioicons[players[i].pers["team"]] < level.ehq_PlayersToCapture[players[i].pers["team"]]))
							{
								if (isdefined (players[i].progressbar_capture))
									players[i].progressbar_capture destroy ();
								if (isdefined (players[i].progressbar_capture2))
									players[i].progressbar_capture2 destroy ();
								if (isdefined (players[i].progressbar_capture3))
									players[i].progressbar_capture3 destroy ();
							
								continue;
							}

							if (level.ehq_capturenoweapon)
								players[i] thread EHQ_disableWeaponDuringCapture ();

							if(!isdefined(players[i].progressbar_capture))
							{
								players[i].progressbar_capture = newClientHudElem(players[i]);
								players[i].progressbar_capture.x = 0;

								if(level.splitscreen)
									players[i].progressbar_capture.y = 70;
								else
									players[i].progressbar_capture.y = 104;

								players[i].progressbar_capture.alignX = "center";
								players[i].progressbar_capture.alignY = "middle";
								players[i].progressbar_capture.horzAlign = "center_safearea";
								players[i].progressbar_capture.vertAlign = "center_safearea";
								players[i].progressbar_capture.alpha = 0.5;
							}
							players[i].progressbar_capture setShader("black", level.progressBarWidth, level.progressBarHeight);

							if(!isdefined(players[i].progressbar_capture2))
							{
								players[i].progressbar_capture2 = newClientHudElem(players[i]);
								players[i].progressbar_capture2.x = ((level.progressBarWidth / (-2)) + 2);

								if(level.splitscreen)
									players[i].progressbar_capture2.y = 70;
								else
									players[i].progressbar_capture2.y = 104;

								players[i].progressbar_capture2.alignX = "left";
								players[i].progressbar_capture2.alignY = "middle";
								players[i].progressbar_capture2.horzAlign = "center_safearea";
								players[i].progressbar_capture2.vertAlign = "center_safearea";
							}
							if(players[i].pers["team"] == "allies")
								players[i].progressbar_capture2 setShader ("white", EHQ_Round ((level.progressBarWidth - 4) - radio.holdtime_allies), level.progressBarHeight - 4);
							else
								players[i].progressbar_capture2 setShader ("white", EHQ_Round ((level.progressBarWidth - 4) - radio.holdtime_axis), level.progressBarHeight - 4);

							if(!isdefined(players[i].progressbar_capture3))
							{
								players[i].progressbar_capture3 = newClientHudElem(players[i]);
								players[i].progressbar_capture3.x = 0;

								if(level.splitscreen)
									players[i].progressbar_capture3.y = 16;
								else
									players[i].progressbar_capture3.y = 50;

								players[i].progressbar_capture3.alignX = "center";
								players[i].progressbar_capture3.alignY = "middle";
								players[i].progressbar_capture3.horzAlign = "center_safearea";
								players[i].progressbar_capture3.vertAlign = "center_safearea";
								players[i].progressbar_capture3.archived = false;
								players[i].progressbar_capture3.font = "default";
								players[i].progressbar_capture3.fontscale = 2;
								players[i].progressbar_capture3 settext(&"MP_DESTROYING_HQ");
							}

							if(radio.team == "allies")
							{
								if(!isdefined(level.progressbar_axis_neutralize))
								{
									level.progressbar_axis_neutralize = newTeamHudElem("allies");
									level.progressbar_axis_neutralize.x = 0;

									if(level.splitscreen)
										level.progressbar_axis_neutralize.y = 70;
									else
										level.progressbar_axis_neutralize.y = 104;

									level.progressbar_axis_neutralize.alignX = "center";
									level.progressbar_axis_neutralize.alignY = "middle";
									level.progressbar_axis_neutralize.horzAlign = "center_safearea";
									level.progressbar_axis_neutralize.vertAlign = "center_safearea";
									level.progressbar_axis_neutralize.alpha = 0.5;
								}
								level.progressbar_axis_neutralize setShader("black", level.progressBarWidth, level.progressBarHeight);

								if(!isdefined(level.progressbar_axis_neutralize2))
								{
									level.progressbar_axis_neutralize2 = newTeamHudElem("allies");
									level.progressbar_axis_neutralize2.x = ((level.progressBarWidth / (-2)) + 2);

									if(level.splitscreen)
										level.progressbar_axis_neutralize2.y = 70;
									else
										level.progressbar_axis_neutralize2.y = 104;

									level.progressbar_axis_neutralize2.alignX = "left";
									level.progressbar_axis_neutralize2.alignY = "middle";
									level.progressbar_axis_neutralize2.horzAlign = "center_safearea";
									level.progressbar_axis_neutralize2.vertAlign = "center_safearea";
									level.progressbar_axis_neutralize2.color = (.8,0,0);
								}
								if(players[i].pers["team"] == "allies")
									level.progressbar_axis_neutralize2 setShader ("white", EHQ_Round ((level.progressBarWidth - 4) - radio.holdtime_allies), level.progressBarHeight - 4);
								else
									level.progressbar_axis_neutralize2 setShader ("white", EHQ_Round ((level.progressBarWidth - 4) - radio.holdtime_axis), level.progressBarHeight - 4);

								if(!isdefined(level.progressbar_axis_neutralize3))
								{
									level.progressbar_axis_neutralize3 = newTeamHudElem("allies");
									level.progressbar_axis_neutralize3.x = 0;

									if(level.splitscreen)
										level.progressbar_axis_neutralize3.y = 16;
									else
										level.progressbar_axis_neutralize3.y = 50;

									level.progressbar_axis_neutralize3.alignX = "center";
									level.progressbar_axis_neutralize3.alignY = "middle";
									level.progressbar_axis_neutralize3.horzAlign = "center_safearea";
									level.progressbar_axis_neutralize3.vertAlign = "center_safearea";
									level.progressbar_axis_neutralize3.archived = false;
									level.progressbar_axis_neutralize3.font = "default";
									level.progressbar_axis_neutralize3.fontscale = 2;
									level.progressbar_axis_neutralize3 settext(&"MP_LOSING_HQ");
								}
							}
							else
							if(radio.team == "axis")
							{
								if(!isdefined(level.progressbar_allies_neutralize))
								{
									level.progressbar_allies_neutralize = newTeamHudElem("axis");
									level.progressbar_allies_neutralize.x = 0;

									if(level.splitscreen)
										level.progressbar_allies_neutralize.y = 70;
									else
										level.progressbar_allies_neutralize.y = 104;

									level.progressbar_allies_neutralize.alignX = "center";
									level.progressbar_allies_neutralize.alignY = "middle";
									level.progressbar_allies_neutralize.horzAlign = "center_safearea";
									level.progressbar_allies_neutralize.vertAlign = "center_safearea";
									level.progressbar_allies_neutralize.alpha = 0.5;
								}
								level.progressbar_allies_neutralize setShader("black", level.progressBarWidth, level.progressBarHeight);

								if(!isdefined(level.progressbar_allies_neutralize2))
								{
									level.progressbar_allies_neutralize2 = newTeamHudElem("axis");
									level.progressbar_allies_neutralize2.x = ((level.progressBarWidth / (-2)) + 2);

									if(level.splitscreen)
										level.progressbar_allies_neutralize2.y = 70;
									else
										level.progressbar_allies_neutralize2.y = 104;

									level.progressbar_allies_neutralize2.alignX = "left";
									level.progressbar_allies_neutralize2.alignY = "middle";
									level.progressbar_allies_neutralize2.horzAlign = "center_safearea";
									level.progressbar_allies_neutralize2.vertAlign = "center_safearea";
									level.progressbar_allies_neutralize2.color = (.8,0,0);
								}
								if(players[i].pers["team"] == "allies")
									level.progressbar_allies_neutralize2 setShader ("white", EHQ_Round ((level.progressBarWidth - 4) - radio.holdtime_allies), level.progressBarHeight - 4);
								else
									level.progressbar_allies_neutralize2 setShader ("white", EHQ_Round ((level.progressBarWidth - 4) - radio.holdtime_axis), level.progressBarHeight - 4);

								if(!isdefined(level.progressbar_allies_neutralize3))
								{
									level.progressbar_allies_neutralize3 = newTeamHudElem("axis");
									level.progressbar_allies_neutralize3.x = 0;

									if(level.splitscreen)
										level.progressbar_allies_neutralize3.y = 16;
									else
										level.progressbar_allies_neutralize3.y = 50;

									level.progressbar_allies_neutralize3.alignX = "center";
									level.progressbar_allies_neutralize3.alignY = "middle";
									level.progressbar_allies_neutralize3.horzAlign = "center_safearea";
									level.progressbar_allies_neutralize3.vertAlign = "center_safearea";
									level.progressbar_allies_neutralize3.archived = false;
									level.progressbar_allies_neutralize3.font = "default";
									level.progressbar_allies_neutralize3.fontscale = 2;
									level.progressbar_allies_neutralize3 settext(&"MP_LOSING_HQ");
								}
							}
						}

						if(players[i].pers["team"] == "allies")
							radio.allies++;
						else
							radio.axis++;

						players[i].inrange = true;
					}
					else if((isdefined(players[i].radioicon)) && (isdefined(players[i].radioicon[0])))
					{
						if((isdefined(players[i].radioicon)) || (isdefined(players[i].radioicon[0])))
						{
							players[i].radioicon[0] destroy();
							level.ehq_numradioicons[players[i].pers["team"]] --;
						}
						if(isdefined(players[i].progressbar_capture))
							players[i].progressbar_capture destroy();
						if(isdefined(players[i].progressbar_capture2))
							players[i].progressbar_capture2 destroy();
						if(isdefined(players[i].progressbar_capture3))
							players[i].progressbar_capture3 destroy();

						players[i].inrange = undefined;
					}
				}
			}

			if(radio.team == "none") // Radio is captured if no enemies around
			{
				if((radio.allies > 0) && (radio.axis <= 0) && (radio.team != "allies"))
				{
					radio.holdtime_allies += radio.allies * level.ehq_MultipleEstablishBias / level.ehq_PlayersToCapture["allies"];

					if(radio.holdtime_allies >= (level.progressBarWidth - 4))
					{
						if((level.captured_radios["allies"] > 0) && (radio.team != "none"))
							level hq_radio_capture(radio, "none");
						else if(level.captured_radios["allies"] <= 0)
							level hq_radio_capture(radio, "allies");
					}
				}
				else if((radio.axis > 0) && (radio.allies <= 0) && (radio.team != "axis"))
				{
					radio.holdtime_axis += radio.axis * level.ehq_MultipleEstablishBias / level.ehq_PlayersToCapture["axis"];

					if(radio.holdtime_axis >= (level.progressBarWidth - 4))
					{
						if((level.captured_radios["axis"] > 0) && (radio.team != "none"))
							level hq_radio_capture(radio, "none");
						else if(level.captured_radios["axis"] <= 0)
							level hq_radio_capture(radio, "axis");
					}
				}
				else
				{
					radio.holdtime_allies = 0;
					radio.holdtime_axis = 0;

					players = getentarray("player", "classname");
					for(i = 0; i < players.size; i++)
					{
						if(isdefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
						{
							if(((distance(players[i].origin,radio.origin)) <= radio.radius) && (distance((0,0,players[i].origin[2]),(0,0,radio.origin[2])) <= level.zradioradius))
							{
								if(isdefined(players[i].progressbar_capture))
									players[i].progressbar_capture destroy();
								if(isdefined(players[i].progressbar_capture2))
									players[i].progressbar_capture2 destroy();
								if(isdefined(players[i].progressbar_capture3))
									players[i].progressbar_capture3 destroy();
							}
						}
					}
				}
			}
			else // Radio should go to neutral first
			{
				if((radio.team == "allies") && (radio.axis <= 0))
				{
					if(isdefined(level.progressbar_axis_neutralize))
						level.progressbar_axis_neutralize destroy();
					if(isdefined(level.progressbar_axis_neutralize2))
						level.progressbar_axis_neutralize2 destroy();
					if(isdefined(level.progressbar_axis_neutralize3))
						level.progressbar_axis_neutralize3 destroy();
				}
				else if((radio.team == "axis") && (radio.allies <= 0))
				{
					if(isdefined(level.progressbar_allies_neutralize))
						level.progressbar_allies_neutralize destroy();
					if(isdefined(level.progressbar_allies_neutralize2))
						level.progressbar_allies_neutralize2 destroy();
					if(isdefined(level.progressbar_allies_neutralize3))
						level.progressbar_allies_neutralize3 destroy();
				}

				if((radio.allies > 0) && (radio.team == "axis"))
				{
					radio.holdtime_allies += radio.allies * level.ehq_MultipleDestroyBias / level.ehq_PlayersToCapture["allies"];

					if(radio.holdtime_allies >= (level.progressBarWidth - 4))
						level hq_radio_capture(radio, "none");
				}
				else if((radio.axis > 0) && (radio.team == "allies"))
				{
					radio.holdtime_axis += radio.axis * level.ehq_MultipleDestroyBias / level.ehq_PlayersToCapture["axis"];

					if(radio.holdtime_axis >= (level.progressBarWidth - 4))
						level hq_radio_capture(radio, "none");
				}
				else
				{
					radio.holdtime_allies = 0;
					radio.holdtime_axis = 0;
				}
			}
		}
/*
	}
*/
}

hq_radio_capture(radio, team)
{
	radio.holdtime_allies = 0;
	radio.holdtime_axis = 0;
	numplayersonradio = 0;

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		players[i].WaitingOnTimer = undefined;
		players[i].WaitingOnNeutralize = undefined;
		if(isdefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
		{
			if((isdefined(players[i].radioicon)) && (isdefined(players[i].radioicon[0])))
			{
				players[i].radioicon[0] destroy();
				level.ehq_numradioicons[players[i].pers["team"]] --;
				level.ehq_playertoaward[numplayersonradio] = i;
				numplayersonradio ++;
				if(isdefined(players[i].progressbar_capture))
					players[i].progressbar_capture destroy();
				if(isdefined(players[i].progressbar_capture2))
					players[i].progressbar_capture2 destroy();
				if(isdefined(players[i].progressbar_capture3))
					players[i].progressbar_capture3 destroy();
			}
		}
	}

	if(radio.team != "none")
	{
		level.captured_radios[radio.team] = 0;
		playfx(level._effect["radioexplosion"], radio.origin);
		level.timesCaptured = 0;
		// Print some text
		if(radio.team == "allies")
		{
			if (EHQ_getTeamCount ("axis") && ! level.splitscreen)
				iprintln(&"MP_SHUTDOWN_ALLIED_HQ");

			if(isdefined(level.progressbar_axis_neutralize))
				level.progressbar_axis_neutralize destroy();
			if(isdefined(level.progressbar_axis_neutralize2))
				level.progressbar_axis_neutralize2 destroy();
			if(isdefined(level.progressbar_axis_neutralize3))
				level.progressbar_axis_neutralize3 destroy();
		}
		else if(radio.team == "axis")
		{
			if (EHQ_getTeamCount ("allies") && !level.splitscreen)
				iprintln(&"MP_SHUTDOWN_AXIS_HQ");

			if(isdefined(level.progressbar_allies_neutralize))
				level.progressbar_allies_neutralize destroy();
			if(isdefined(level.progressbar_allies_neutralize2))
				level.progressbar_allies_neutralize2 destroy();
			if(isdefined(level.progressbar_allies_neutralize3))
				level.progressbar_allies_neutralize3 destroy();
		}
	}

	if(radio.team == "none")
		EHQ_RadioPlaysound ("explo_plant_no_tick");

	NeutralizingTeam = undefined;
	if(radio.team == "allies")
		NeutralizingTeam = "axis";
	else if(radio.team == "axis")
		NeutralizingTeam = "allies";
	radio.team = team;

	level notify("Radio State Changed");

	if(team == "none")
	{
		// RADIO GOES NEUTRAL
		EHQ_RadioHide ();
		radio.hidden = true;

		EHQ_RadioPlaysound ("explo_radio");
		if(isdefined(NeutralizingTeam))
		{
			if(NeutralizingTeam == "allies")
				level thread playSoundOnPlayers("mp_announcer_axishqdest");
			else if(NeutralizingTeam == "axis")
				level thread playSoundOnPlayers("mp_announcer_alliedhqdest");
		}

		objective_delete(0);
		thread maps\mp\gametypes\_objpoints::removeObjpoints();
		level.DefendingRadioTeam = "none";
		level notify("Radio Neutralized");

		//give some points to the neutralizing team
		if(isdefined(NeutralizingTeam))
		{
			if((NeutralizingTeam == "allies") || (NeutralizingTeam == "axis"))
			{
				if (EHQ_getTeamCount (NeutralizingTeam))
				{
					setTeamScore(NeutralizingTeam, getTeamScore(NeutralizingTeam) + level.NeutralizingPoints);
					level notify("update_allhud_score");

					if(!level.splitscreen)
					{
						if(NeutralizingTeam == "allies")
							iprintln(&"MP_SCORED_ALLIES", level.NeutralizingPoints);
						else
							iprintln(&"MP_SCORED_AXIS", level.NeutralizingPoints);
					}

					for (i = 0; i < numplayersonradio; i ++)
					{
						iprintlnFIXED (&"EHQ_DESTROYED", players[level.ehq_playertoaward[i]]);
						players[level.ehq_playertoaward[i]].score += level.ehq_PointsForDestroy;

						lpselfnum = players[level.ehq_playertoaward[i]] getEntityNumber ();
						lpselfguid = players[level.ehq_playertoaward[i]] getGuid ();
						logPrint ("A;" + lpselfguid + ";" + lpselfnum + ";" + players[level.ehq_playertoaward[i]].name + ";" + "ehq_destroy" + "\n");
					}
				}
			}
		}

		//give all the alive players that are alive full health
		players = getentarray("player", "classname");
		for(i = 0; i < players.size; i++)
		{
			if(isdefined(players[i].pers["team"]) && players[i].sessionstate == "playing")
			{
				players[i].maxhealth = 100;
				players[i].health = players[i].maxhealth;
			}
		}

		if (EHQ_GetEngineerMode ())
			EHQ_UnsetAllEngineers ();

		level thread hq_removehudelem_allplayers(radio);
	}
	else
	{
		// RADIO CAPTURED BY A TEAM
		level.captured_radios[team] = 1;
		level.DefendingRadioTeam = team;

		if(team == "allies")
		{
			if(!level.splitscreen)
				iprintln(&"MP_SETUP_HQ_ALLIED");

			if(game["allies"] == "british")
				alliedsound = "UK_mp_hqsetup";
			else if(game["allies"] == "russian")
				alliedsound = "RU_mp_hqsetup";
			else
				alliedsound = "US_mp_hqsetup";

			level thread playSoundOnPlayers(alliedsound, "allies");
			if(!level.splitscreen)
				level thread playSoundOnPlayers("GE_mp_enemyhqsetup", "axis");
		}
		else
		{
			if(!level.splitscreen)
				iprintln(&"MP_SETUP_HQ_AXIS");

			if(game["allies"] == "british")
				alliedsound = "UK_mp_enemyhqsetup";
			else if(game["allies"] == "russian")
				alliedsound = "RU_mp_enemyhqsetup";
			else
				alliedsound = "US_mp_enemyhqsetup";

			level thread playSoundOnPlayers("GE_mp_hqsetup", "axis");
			if(!level.splitscreen)
				level thread playSoundOnPlayers(alliedsound, "allies");
		}

		for (i = 0; i < numplayersonradio; i ++)
		{
			iprintlnFIXED (&"EHQ_ESTABLISHED", players[level.ehq_playertoaward[i]]);
			players[level.ehq_playertoaward[i]].score += level.ehq_PointsForEstablish;
	
			lpselfnum = players[level.ehq_playertoaward[i]] getEntityNumber ();
			lpselfguid = players[level.ehq_playertoaward[i]] getGuid ();
			logPrint ("A;" + lpselfguid + ";" + lpselfnum + ";" + players[level.ehq_playertoaward[i]].name + ";" + "ehq_establish" + "\n");
		}

		// Add a radio on the HUD of each team
		
		EHQ_update_HUD_radio ("allies", true);
		EHQ_update_HUD_radio ("axis", true);

		//give all the alive players that are now defending the radio full health
		players = getentarray("player", "classname");
		for(i = 0; i < players.size; i++)
		{
			if(isdefined(players[i].pers["team"]) && players[i].pers["team"] == level.DefendingRadioTeam && players[i].sessionstate == "playing")
			{
				players[i].maxhealth = 100;
				players[i].health = players[i].maxhealth;
			}
		}

		level thread hq_maxholdtime_think();
	}

	objective_icon(0, (game["radio_" + team ]));
	objective_team(0, "none");

	objteam = "none";
	if((level.captured_radios["allies"] <= 0) && (level.captured_radios["axis"] > 0))
		objteam = "allies";
	else if((level.captured_radios["allies"] > 0) && (level.captured_radios["axis"] <= 0))
		objteam = "axis";

	// Make all neutral radio objectives go to the right team
	for(i = 0; i < level.radio.size; i++)
	{
		if(level.radio[i].hidden == true)
			continue;
		if(level.radio[i].team == "none")
			objective_team(0, objteam);
	}

	level notify("finish_staydead");

	level thread hq_obj_think(radio);
}

hq_maxholdtime_think()
{
	level endon("Radio State Changed");
	assert(level.RadioMaxHoldSeconds > 2);
	if(level.RadioMaxHoldSeconds > 0)
		wait(level.RadioMaxHoldSeconds - 0.05);
	level thread hq_radio_resetall();
}

hq_points()
{
	while(!level.mapended)
	{
		if(level.DefendingRadioTeam != "none")
		{
			if (EHQ_getTeamCount (level.DefendingRadioTeam))
			{
				setTeamScore(level.DefendingRadioTeam, getTeamScore(level.DefendingRadioTeam) + 1);
				level notify("update_allhud_score");
				checkScoreLimit();
			}
		}
		wait 1;
	}
}

hq_radio_resetall()
{
	// Find the radio that is in play
	radio = undefined;
	for(i = 0; i < level.radio.size; i++)
	{
		if(level.radio[i].hidden == false)
			radio = level.radio[i];
	}

	if(!isdefined(radio))
		return;

	radio.holdtime_allies = 0;
	radio.holdtime_axis = 0;

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		players[i].WaitingOnTimer = undefined;
		players[i].WaitingOnNeutralize = undefined;
		if(isdefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
		{
			if((isdefined(players[i].radioicon)) && (isdefined(players[i].radioicon[0])))
			{
				players[i].radioicon[0] destroy();
				level.ehq_numradioicons[players[i].pers["team"]] --;
				if(isdefined(players[i].progressbar_capture))
					players[i].progressbar_capture destroy();
				if(isdefined(players[i].progressbar_capture2))
					players[i].progressbar_capture2 destroy();
				if(isdefined(players[i].progressbar_capture3))
					players[i].progressbar_capture3 destroy();
			}
		}
	}

	if(radio.team != "none")
	{
		level.captured_radios[radio.team] = 0;

		playfx(level._effect["radioexplosion"], radio.origin);
		level.timesCaptured = 0;

		localizedTeam = undefined;
		if(radio.team == "allies")
		{
			localizedTeam = (&"MP_UPTEAM");
			if(isdefined(level.progressbar_axis_neutralize))
				level.progressbar_axis_neutralize destroy();
			if(isdefined(level.progressbar_axis_neutralize2))
				level.progressbar_axis_neutralize2 destroy();
			if(isdefined(level.progressbar_axis_neutralize3))
				level.progressbar_axis_neutralize3 destroy();
		}
		else if(radio.team == "axis")
		{
			localizedTeam = (&"MP_DOWNTEAM");
			if(isdefined(level.progressbar_allies_neutralize))
				level.progressbar_allies_neutralize destroy();
			if(isdefined(level.progressbar_allies_neutralize2))
				level.progressbar_allies_neutralize2 destroy();
			if(isdefined(level.progressbar_allies_neutralize3))
				level.progressbar_allies_neutralize3 destroy();
		}

		minutes = 0;
		maxTime = level.RadioMaxHoldSeconds;
		while(maxTime >= 60)
		{
			minutes++;
			maxTime -= 60;
		}
		seconds = maxTime;
		if((minutes > 0) && (seconds > 0))
			iprintlnbold(&"MP_MAXHOLDTIME_MINUTESANDSECONDS", localizedTeam, minutes, seconds);
		else
		if((minutes > 0) && (seconds <= 0))
			iprintlnbold(&"MP_MAXHOLDTIME_MINUTES", localizedTeam);
		else
		if((minutes <= 0) && (seconds > 0))
			iprintlnbold(&"MP_MAXHOLDTIME_SECONDS", localizedTeam, seconds);

		if (EHQ_GetEngineerMode ())
			EHQ_UnsetAllEngineers ();
	}

	radio.team = "none";
	level.DefendingRadioTeam = "none";
	objective_team(0, "none");

	EHQ_RadioHide ();

	if(!level.mapended)
	{
		EHQ_RadioPlaysound ("explo_radio");
		level thread playSoundOnPlayers("mp_announcer_hqdefended");
	}

	radio.hidden = true;
	objective_delete(0);
	thread maps\mp\gametypes\_objpoints::removeObjpoints();

	level.graceperiod = false;
	level thread hq_obj_think(radio);
	level thread hq_removehudelem_allplayers(radio);

	// All dead people should now respawn
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		players[i].WaitingOnTimer = undefined;
		players[i].WaitingOnNeutralize = undefined;
	}

	level notify("finish_staydead");
}

hq_removeall_hudelems(player)
{
	if(isdefined(self))
	{
		for(i = 0; i < level.radio.size; i++)
		{
			if((isdefined(player.radioicon)) && (isdefined(player.radioicon[0])))
			{
				player.radioicon[0] destroy();
				level.ehq_numradioicons[player.pers["team"]] --;
			}
			if(isdefined(player.progressbar_capture))
				player.progressbar_capture destroy();
			if(isdefined(player.progressbar_capture2))
				player.progressbar_capture2 destroy();
			if(isdefined(player.progressbar_capture3))
				player.progressbar_capture3 destroy();
		}
	}
}

hq_removehudelem_allplayers(radio)
{
	if (isdefined (level.ehq_hudradioicon["allies"]))
		level.ehq_hudradioicon["allies"] destroy ();
	if (isdefined (level.ehq_hudradioicon["axis"]))
		level.ehq_hudradioicon["axis"] destroy ();

	if (isdefined (level.ehq_hudradionumber["allies"]))
		level.ehq_hudradionumber["allies"] destroy ();
	if (isdefined (level.ehq_hudradionumber["axis"]))
		level.ehq_hudradionumber["axis"] destroy ();

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		if(!isdefined(players[i]))
			continue;
		if((isdefined(players[i].radioicon)) && (isdefined(players[i].radioicon[0])))
		{
			players[i].radioicon[0] destroy();
			level.ehq_numradioicons[players[i].pers["team"]] --;
		}
		if(isdefined(players[i].progressbar_capture))
			players[i].progressbar_capture destroy();
		if(isdefined(players[i].progressbar_capture2))
			players[i].progressbar_capture2 destroy();
		if(isdefined(players[i].progressbar_capture3))
			players[i].progressbar_capture3 destroy();
	}
}

hq_check_teams_exist()
{
	players = getentarray("player", "classname");
	level.alliesexist = false;
	level.axisexist = false;
	for(i = 0; i < players.size; i++)
	{
		if(!isdefined(players[i].pers["team"]) || players[i].pers["team"] == "spectator")
			continue;
		if(players[i].pers["team"] == "allies")
			level.alliesexist = true;
		else if(players[i].pers["team"] == "axis")
			level.axisexist = true;

		if(level.alliesexist && level.axisexist)
			return;
	}
}

updateTeamStatus()
{
	level.exist["allies"] = 0;
	level.exist["axis"] = 0;

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		if(isdefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
			level.exist[players[i].pers["team"]]++;
	}
}

restartRound()
{
	if(level.roundStarted)
	{
		iprintln(&"MP_MATCHRESUMING");
		return;
	}
	else
	{
		iprintln(&"MP_MATCHSTARTING");
		wait 5;
	}

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isdefined(player.pers["team"]) && (player.pers["team"] == "allies" || player.pers["team"] == "axis"))
		{
		    player.score = 0;
		    player.deaths = 0;

			player spawnPlayer();
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
		if (EHQ_GetEngineerMode ())
			self EHQ_CheckIfEngineerLeft ();
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
			if (EHQ_GetEngineerMode ())
				self EHQ_CheckIfEngineerLeft ();
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
			if (EHQ_GetEngineerMode ())
				self EHQ_CheckIfEngineerLeft ();
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
			if (EHQ_GetEngineerMode ())
				self EHQ_CheckIfEngineerLeft ();
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

		if(isdefined(self.WaitingOnTimer) || ((self.pers["team"] == level.DefendingRadioTeam) && isdefined(self.WaitingOnNeutralize)))
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

	self.WaitingOnTimer = true;

	if(level.respawndelay > 0)
	{
		if ((isdefined (self.pers["team"])) && (level.DefendingRadioTeam == self.pers["team"]) && level.ehq_DefendersCanRespawn)
			respawndelay = level.respawndelay + level.ehq_DefendersRespawnDelayPenalty;
		else
			respawndelay = level.respawndelay;
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
			self.respawntimer setTimer (respawndelay + delay);
		}

		wait delay;
		self thread updateTimer();

		EHQ_wait_endon_stay_dead (respawndelay);

		if(isdefined(self.respawntimer))
			self.respawntimer destroy();
	}

	self.WaitingOnTimer = undefined;
}

respawn_staydead(delay)
{
	self endon("disconnect");

	if(isdefined(self.WaitingOnNeutralize))
		return;
	self.WaitingOnNeutralize = true;

	if(!isdefined(self.staydead))
	{
		self.staydead = newClientHudElem(self);
		self.staydead.x = 0;
		self.staydead.y = -50;
		self.staydead.alignX = "center";
		self.staydead.alignY = "middle";
		self.staydead.horzAlign = "center_safearea";
		self.staydead.vertAlign = "center_safearea";
		self.staydead.alpha = 0;
		self.staydead.archived = false;
		self.staydead.font = "default";
		self.staydead.fontscale = 2;
		self.staydead setText(&"MP_RESPAWN_WHEN_RADIO_NEUTRALIZED");
	}

	self thread delayUpdateTimer(delay);
	level waittill("finish_staydead");

	if(isdefined(self.staydead))
		self.staydead destroy();

	if(isdefined(self.respawntimer))
		self.respawntimer destroy();

	self.WaitingOnNeutralize = undefined;
}

delayUpdateTimer(delay)
{
	self endon("disconnect");

	wait delay;
	thread updateTimer();
}

updateTimer()
{
	if(isdefined(self.pers["team"]) && (self.pers["team"] == "allies" || self.pers["team"] == "axis") && isdefined(self.pers["weapon"]))
	{
		if (isdefined (self.pers["team"]) && (self.pers["team"] == level.DefendingRadioTeam) && (! level.ehq_DefendersCanRespawn))
		{
			if(isdefined(self.respawntimer))
				self.respawntimer.alpha = 0;

			if(isdefined(self.staydead))
				self.staydead.alpha = 1;
		}
		else
		{
			if(isdefined(self.respawntimer))
				self.respawntimer.alpha = 1;

			if(isdefined(self.staydead))
				self.staydead.alpha = 0;
		}
	}
	else
	{
		if(isdefined(self.respawntimer))
			self.respawntimer.alpha = 0;

		if(isdefined(self.staydead))
			self.staydead.alpha = 0;
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

getTeamCount(team)
{
	count = 0;

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isdefined(player.pers["team"]) && (player.pers["team"] == team))
			count++;
	}

	return count;
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

EHQ_wait_endon_stay_dead (delay)
{
	level endon ("finish_staydead");
	wait (delay);
}

EHQ_GetEngineerMode ()
{
	return level.ehq_EngineerMode;
}

EHQ_MonitorTeams ()
{
	prev = [];
	numplayers = [];
	numengineers = [];
	
	for ( ; ; )
	{
		if (level.mapended)
			return;

		// Count players and engineers in each team

		numplayers["allies"] = 0;
		numplayers["axis"] = 0;
		numengineers["allies"] = 0;
		numengineers["axis"] = 0;

		players = getentarray ("player", "classname");
		for (i = 0; i < players.size; i ++)
		{
			player = players[i];
			if (isdefined (player.pers["team"]) && (player.pers["team"] == "allies"))
			{
				numplayers["allies"] ++;
				if (player EHQ_IsEngineer ())
					numengineers["allies"] ++;
			}
			if (isdefined (player.pers["team"]) && (player.pers["team"] == "axis"))
			{
				numplayers["axis"] ++;
				if (player EHQ_IsEngineer ())
					numengineers["axis"] ++;
			}
		}

		level.ehq_numplayers["allies"] = numplayers["allies"];
		level.ehq_numplayers["axis"] = numplayers["axis"];
		level.ehq_numengineers["allies"] = numengineers["allies"];
		level.ehq_numengineers["axis"] = numengineers["axis"];

		// Update number of players to capture the radio
		
		prev["allies"] = level.ehq_PlayersToCapture["allies"];
		prev["axis"] = level.ehq_PlayersToCapture["axis"];

		if (level.DefendingRadioTeam != "none")
		{
			// HQ is established / must be destroyed
			attackingteam  = EnemyTeam (level.DefendingRadioTeam);
			level.ehq_PlayersToCapture[attackingteam] = level.ehq_PlayersToDestroy;
			if (level.ehq_PlayersToCapture[attackingteam] > level.ehq_numplayers[attackingteam])
				level.ehq_PlayersToCapture[attackingteam] = level.ehq_numplayers[attackingteam];
			level.ehq_PlayersToCapture[level.DefendingRadioTeam] = level.ehq_PlayersToCapture[attackingteam];
		}
		else
		{
			// HQ is not established
			level.ehq_PlayersToCapture["allies"] = level.ehq_PlayersToEstablish;
			if (level.ehq_PlayersToCapture["allies"] > level.ehq_numplayers["allies"])
				level.ehq_PlayersToCapture["allies"] = level.ehq_numplayers["allies"];
			level.ehq_PlayersToCapture["axis"] = level.ehq_PlayersToEstablish;
			if (level.ehq_PlayersToCapture["axis"] > level.ehq_numplayers["axis"])
				level.ehq_PlayersToCapture["axis"] = level.ehq_numplayers["axis"];
		}

		// Ensure that values are at least 1

		if (level.ehq_PlayersToCapture["allies"] < 1)
			level.ehq_PlayersToCapture["allies"] = 1;
		if (level.ehq_PlayersToCapture["axis"] < 1)
			level.ehq_PlayersToCapture["axis"] = 1;

		// Update HUD if number of players to capture the radio have changed

		if (isdefined (level.ehq_hudradionumber) && (level.ehq_PlayersToCapture["allies"] != prev["allies"]))
			EHQ_update_HUD_radio ("allies", false);

		if (isdefined (level.ehq_hudradionumber) && (level.ehq_PlayersToCapture["axis"] != prev["axis"]))
			EHQ_update_HUD_radio ("axis", false);

		// Select new engineers if necessary
		
		if (EHQ_GetEngineerMode ())
		{
			EHQ_SelectEngineers ("allies");
			EHQ_SelectEngineers ("axis");
		}
 
		wait 0.1;
	}
}

EHQ_getTeamCount (team)
{
	return (level.ehq_numplayers[team]);
}

EHQ_SelectEngineers (team)
{
	// Update number of engineers
		
	if (level.ehq_MaxEngineers != 0)
		// Max number of engineers to select is fixed

		numengineers = level.ehq_MaxEngineers;
		
	else
	{
		// Derive the number of engineers from the number of players
		
		otherteam = Enemyteam (team);

		if (level.ehq_numplayers[team] == level.ehq_numplayers[otherteam])
			numengineers = EHQ_HalfInf (level.ehq_numplayers[team]);
		else if (level.ehq_numplayers[team] > level.ehq_numplayers[otherteam])
			numengineers = EHQ_HalfInf (level.ehq_numplayers[otherteam]);
		else
			numengineers = EHQ_HalfSup (level.ehq_numplayers[otherteam]);
			
		// Ensure that value is at least 1 and no more than the number of players
		
		if (numengineers < 1)
			numengineers = 1;
		else if (numengineers > level.ehq_numplayers[team])
			numengineers = level.ehq_numplayers[team];
	}
	
	// Select additional engineers in the team

	players = getentarray ("player", "classname");
	for (i = level.ehq_numengineers[team]; (i < numengineers) && (i < level.ehq_numplayers[team]); i ++)
	{
		selected = undefined;
		for (loopcount = 0; ; loopcount ++)
		{
			player = players[randomint (players.size)];
			if (isdefined (player.pers["team"]) && (player.pers["team"] == team) && ((! isdefined (player.switching_teams)) || (! player.switching_teams)) && (! (player EHQ_IsEngineer ())))
			{
				selected = player;
				break;
			}
			if (loopcount > 50)
			{
				logprint ("DEBUG : EHQ_SelectEngineers : max loop !!\n");
				break;
			}
		}

		if (isdefined (selected))
			selected EHQ_SetEngineer ();
	}
}

EHQ_HalfInf (n)
{
	return int (n / 2);
}

EHQ_HalfSup (n)
{
	hs = EHQ_HalfInf (n);
	if (n - 2 * hs > 0)
		hs ++;
	return hs;
}

EHQ_Round (x)
{
	n = int (x);
	if (x - n > 0.5)
		n ++;
	return n;
}

EHQ_IsEngineer ()
{
	if (! isdefined (self.ehq_IsEngineer))
		self.ehq_IsEngineer = false;

	return self.ehq_IsEngineer;
}

EHQ_SetEngineer ()
{
	if (self EHQ_IsEngineer ())
		return;
		
	self.ehq_IsEngineer = true;
	self.dont_auto_balance = true;
	self iprintlnbold (&"EHQ_BECOME_ENGINEER1");
	self iprintlnbold (&"EHQ_BECOME_ENGINEER2");
	self playLocalSound ("ctf_touchown");
	
	self thread EHQ_FollowEngineer ();
}

EHQ_FollowEngineer ()
{
	self endon ("disconnect");
	self endon ("killed_player");

	while ((isdefined (self)) && (isPlayer (self)) && (isdefined (self.pers["team"])) && (self EHQ_IsEngineer ()))
	{
		self EHQ_SetEngineerIcons (); 

		wait 0.1;
	}
}

EHQ_UnsetAllEngineers ()
{
	players = getentarray ("player", "classname");
	for (i = 0; i < players.size; i ++)
		if (players[i] EHQ_IsEngineer ())
			players[i] EHQ_UnsetEngineer ();
}

EHQ_UnsetEngineer ()
{
	if (! (self EHQ_IsEngineer ()))
		return;
		
	self iprintlnbold (&"EHQ_NO_LONGER_ENGINEER1");
	self iprintlnbold (&"EHQ_NO_LONGER_ENGINEER2");
	self EHQ_UnsetEngineerIcons ();
	self.dont_auto_balance = undefined;
	self.ehq_IsEngineer = false;
}

EHQ_CheckIfEngineerLeft ()
{
	if (! (self EHQ_IsEngineer ()))
		return;

	iprintlnFIXED (&"EHQ_ENGINEER_LEFT", self);
	self EHQ_UnsetEngineer ();
}

EHQ_SetEngineerIcons ()
{
	self.statusicon = "objpoint_radio";

	if (! level.drawfriend)
		return;
	
// AWE ->
	if (self.awe_invulnerable)
		return;
// AWE <-
	
	headicon_engineer = "objpoint_radio";
	headicon_notengineer = game["headicon_" + self.pers["team"]];
	if (self.headicon == headicon_notengineer)
		self.headicon = headicon_engineer;
}

EHQ_UnsetEngineerIcons ()
{
	self.statusicon = "";

	if (! level.drawfriend)
		return;

	headicon_notengineer = game["headicon_" + self.pers["team"]];
	self.headicon = headicon_notengineer;
}

EnemyTeam (team)
{
	if (team == "axis")
		enemyteam = "allies";
	else
		enemyteam = "axis";
	return (enemyteam);
}

EHQ_CreateRadiosFromSpawnPoints ()
{
	s = level.radio.size;
	
	spawnpoints = getentarray ("mp_dm_spawn", "classname");
	for (i = 0; i < spawnpoints.size; i ++)
	{
		origin = FindGround (spawnpoints[i].origin);
		angles = spawnpoints[i].angles;
		level.radio[s + i] = spawn ("script_model", origin);
		level.radio[s + i].angles = angles;
	}
	if (i > 0)
		logprint ("Added " + i + " DM spawn points\n");

	spawnpoints = getentarray ("mp_tdm_spawn", "classname");
	for (j = 0; j < spawnpoints.size; j ++)
	{
		origin = FindGround (spawnpoints[j].origin);
		angles = spawnpoints[j].angles;
		level.radio[s + i + j] = spawn ("script_model", origin);
		level.radio[s + i + j].angles = angles;
	}
	if (j > 0)
		logprint ("Added " + j + " TDM spawn points\n");
}

FindGround (position)
{
	trace = bulletTrace (position + (0, 0, 10), position + (0, 0, -1200), false, undefined);
	ground = trace["position"];
	return ground;
}

IsAwayFromHQ ()
{
	currentradio = level.nextradio - 1;
	if (! isdefined (level.radio[currentradio]))
		return true;
	
	if (level.radio[currentradio].hidden)
		return true;

	return (distance (self.origin, level.radio[currentradio].origin) >= level.ehq_spawndistance);
}

EHQ_RemoveScriptModels ()
{
	new_level_radio = [];
	for (i = 0; i < level.radio.size; i ++)
	{
		new_level_radio[i] = spawnstruct ();
		new_level_radio[i].origin = level.radio[i].origin;
		new_level_radio[i].angles = level.radio[i].angles;
		level.radio[i] delete ();
	}
	level.radio = new_level_radio;

	level.ehq_active_radio = spawn ("script_model", (0, 0, 0));
	level.ehq_active_radio setmodel (game["radio_model"]);
	level.ehq_active_radio hide ();
}

EHQ_RadioShow ()
{
	level.ehq_active_radio.origin = self.origin;
	level.ehq_active_radio.angles = self.angles;
	level.ehq_active_radio show ();
}

EHQ_RadioHide ()
{
	level.ehq_active_radio hide ();
}

EHQ_RadioPlaysound (sound)
{
	level.ehq_active_radio playsound (sound);
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

EHQ_disableWeaponDuringCapture ()
{
	self endon ("disconnect");
	self endon ("killed_player");
	
	while (isdefined (self.progressbar_capture))
	{
		self disableWeapon ();
		wait 0.1;
	}

	self enableWeapon ();
}