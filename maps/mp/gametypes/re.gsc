// Modified by La Truffe

// RETRIEVAL BY ETROMANIA (Built From CTF and SD)
// Compass icons need to be looked at
// Doesn't seem to be setting angle on spawn so that you are facing your rallypoint

/*
	Search and Destroy
	Attackers objective: Bomb one of 2 positions
	Defenders objective: Defend these 2 positions / Defuse planted bombs
	Round ends:	When one team is eliminated, bomb explodes, bomb is defused, or roundlength time is reached
	Map ends:	When one team reaches the score limit, or time limit or round limit is reached
	Respawning:	Players remain dead for the round and will respawn at the beginning of the next round

	Level requirements
	------------------
		Allied Spawnpoints:
			classname		mp_sd_spawn_attacker
			Allied players spawn from these. Place at least 16 of these relatively close together.

		Axis Spawnpoints:
			classname		mp_sd_spawn_defender
			Axis players spawn from these. Place at least 16 of these relatively close together.

		Spectator Spawnpoints:
			classname		mp_global_intermission
			Spectators spawn from these and intermission is viewed from these positions.
			Atleast one is required, any more and they are randomly chosen between.

		Bombzones:
			classname					trigger_multiple
			targetname					bombzone
			script_gameobjectname		bombzone
			script_bombmode_original	<if defined this bombzone will be used in the original bomb mode>
			script_bombmode_single		<if defined this bombzone will be used in the single bomb mode>
			script_bombmode_dual		<if defined this bombzone will be used in the dual bomb mode>
			script_team					Set to allies or axis. This is used to set which team a bombzone is used by in dual bomb mode.
			script_label				Set to A or B. This sets the letter shown on the compass in original mode.
			This is a volume of space in which the bomb can planted. Must contain an origin brush.

		Bomb:
			classname				trigger_lookat
			targetname				bombtrigger
			script_gameobjectname	bombzone
			This should be a 16x16 unit trigger with an origin brush placed so that it's center lies on the bottom plane of the trigger.
			Must be in the level somewhere. This is the trigger that is used when defusing a bomb.
			It gets moved to the position of the planted bomb model.

	Level script requirements
	-------------------------
		Team Definitions:
			game["allies"] = "american";
			game["axis"] = "german";
			This sets the nationalities of the teams. Allies can be american, british, or russian. Axis can be german.

			game["attackers"] = "allies";
			game["defenders"] = "axis";
			This sets which team is attacking and which team is defending. Attackers plant the bombs. Defenders protect the targets.

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

		Exploder Effects:
			Setting script_noteworthy on a bombzone trigger to an exploder group can be used to trigger additional effects.

	Note
	----
		Setting "script_gameobjectname" to "bombzone" on any entity in a level will cause that entity to be removed in any gametype that
		does not explicitly allow it. This is done to remove unused entities when playing a map in other gametypes that have no use for them.
*/

/*QUAKED mp_sd_spawn_attacker (0.0 1.0 0.0) (-16 -16 0) (16 16 72)
Attacking players spawn randomly at one of these positions at the beginning of a round.*/

/*QUAKED mp_sd_spawn_defender (1.0 0.0 0.0) (-16 -16 0) (16 16 72)
Defending players spawn randomly at one of these positions at the beginning of a round.*/

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

	level.compassflag_allies = "objpoint_star";
	level.compassflag_axis = "prop_map_case_1_obj";
	level.objpointflag_allies = "objpoint_flag_" + game["allies"];
	level.objpointflag_axis = "objpoint_flag_" + game["axis"];
	level.hudflag_allies = "objpoint_star";
	level.hudflag_axis = "objpoint_star";

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
	precacheModel("xmodel/prop_flag_" + game["allies"]);
	precacheModel("xmodel/prop_flag_" + game["axis"]);
	precacheModel("xmodel/prop_flag_" + game["allies"] + "_carry");
	precacheModel("xmodel/prop_flag_" + game["axis"] + "_carry");
	//precacheString(&"MP_TIME_TILL_SPAWN");
	//precacheString(&"MP_CTF_OBJ_TEXT");
	precacheString(&"RE_ENEMY_FLAG_TAKEN");
	precacheString(&"RE_ENEMY_FLAG_CAPTURED");
	precacheString(&"RE_YOUR_FLAG_WAS_TAKEN");
	precacheString(&"RE_YOUR_FLAG_WAS_CAPTURED");
	precacheString(&"RE_YOUR_FLAG_WAS_RETURNED");
	//precacheString(&"PLATFORM_PRESS_TO_SPAWN");


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
		precacheModel("xmodel/mp_tntbomb");
		precacheModel("xmodel/mp_tntbomb_obj");

		thread maps\mp\gametypes\_teams::addTestClients();
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

	allowed[0] = "ctf";
	maps\mp\gametypes\_gameobjects::main(allowed);

	// Time limit per map
	if(getCvar("scr_re_timelimit") == "")
		setCvar("scr_re_timelimit", "0");
	else if(getCvarFloat("scr_re_timelimit") > 1440)
		setCvar("scr_re_timelimit", "1440");
	level.timelimit = getCvarFloat("scr_re_timelimit");
// La Truffe ->
/*
	setCvar("ui_re_timelimit", level.timelimit);
	makeCvarServerInfo("ui_re_timelimit", "0");
*/
	setCvar("ui_timelimit", level.timelimit);
	makeCvarServerInfo("ui_timelimit", "0");
// La Truffe <-

	if(!isdefined(game["timepassed"]))
		game["timepassed"] = 0;

	// Score limit per map
	if(getCvar("scr_re_scorelimit") == "")
		setCvar("scr_re_scorelimit", "10");
	level.scorelimit = getCvarInt("scr_re_scorelimit");
// La Truffe ->
/*
	setCvar("ui_re_scorelimit", level.scorelimit);
	makeCvarServerInfo("ui_re_scorelimit", "10");
*/
	setCvar("ui_scorelimit", level.scorelimit);
	makeCvarServerInfo("ui_scorelimit", "10");
// La Truffe <-

	// Round limit per map
	if(getCvar("scr_re_roundlimit") == "")
		setCvar("scr_re_roundlimit", "0");
	level.roundlimit = getCvarInt("scr_re_roundlimit");
// La Truffe ->
/*
	setCvar("ui_re_roundlimit", level.roundlimit);
	makeCvarServerInfo("ui_re_roundlimit", "0");
*/
	setCvar("ui_roundlimit", level.roundlimit);
	makeCvarServerInfo("ui_roundlimit", "0");
// La Truffe <-

	// Time at round start where spawning and weapon choosing is still allowed
	if(getCvar("scr_re_graceperiod") == "")
		setCvar("scr_re_graceperiod", "15");
	else if(getCvarFloat("scr_re_graceperiod") > 60)
		setCvar("scr_re_graceperiod", "60");
	else if(getCvarFloat("scr_re_graceperiod") < 0)
		setCvar("scr_re_graceperiod", "0");
	level.graceperiod = getCvarFloat("scr_re_graceperiod");

	// Time length of each round
	if(getCvar("scr_re_roundlength") == "")
		setCvar("scr_re_roundlength", "4");
	else if(getCvarFloat("scr_re_roundlength") > 10)
		setCvar("scr_re_roundlength", "10");
	else if(getCvarFloat("scr_re_roundlength") < (level.graceperiod / 60))
		setCvar("scr_re_roundlength", (level.graceperiod / 60));
	level.roundlength = getCvarFloat("scr_re_roundlength");

	

	// Auto Team Balancing
	if(getCvar("scr_teambalance") == "")
		setCvar("scr_teambalance", "0");
	level.teambalance = getCvarInt("scr_teambalance");
	level.lockteams = false;

	// Draws a team icon over teammates
	if(getCvar("scr_drawfriend") == "")
		setCvar("scr_drawfriend", "1");
	level.drawfriend = getCvarInt("scr_drawfriend");

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

	level.bombplanted = false;
	level.bombexploded = false;
	level.roundstarted = false;
	level.roundended = false;
	level.mapended = false;
	level.bombmode = 0;

	level.exist["allies"] = 0;
	level.exist["axis"] = 0;
	level.exist["teams"] = false;
	level.didexist["allies"] = false;
	level.didexist["axis"] = false;

	thread initFlags();
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
		{
			level notify("chkWeapLimits");
			spawnPlayer();
		}
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

	level notify("chkWeapLimits");

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
	

	self dropFlag();

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
				attacker.pers["score"]++;
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

	if(isdefined(self.bombtimer))
		self.bombtimer destroy();

	if(!isdefined(self.switching_teams))
	{
		body = self cloneplayer(deathAnimDuration);
		if(getcvar("sv_show_deathicon") == "1")
			{
			thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"], 5);
			}	

	}
	self.switching_teams = undefined;
	self.joining_team = undefined;
	self.leaving_team = undefined;

	level updateTeamStatus();

	if(!level.exist[self.pers["team"]]) // If the last player on a team was just killed, don't do killcam
	{
		doKillcam = false;
		self.skip_setspectatepermissions = true;

		if(level.bombplanted && level.planting_team == self.pers["team"])
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
	wait delay;	// ?? Also required for Callback_PlayerKilled to complete before killcam can execute

	if(doKillcam && level.killcam && !level.roundended)
		self maps\mp\gametypes\_killcam::killcam(attackerNum, delay, psOffsetTime);

	currentorigin = self.origin;
	currentangles = self.angles;
	self thread spawnSpectator(currentorigin + (0, 0, 60), currentangles);
}

spawnPlayer()
{
	self endon("disconnect");
	self notify("spawned");

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

	
	if(!level.splitscreen)
	{
		if(level.scorelimit > 0)
		{
			if(self.pers["team"] == game["attackers"])
				self setClientCvar("cg_objectiveText", &"RE_OBJ_ATTACKERS", level.scorelimit);
			else if(self.pers["team"] == game["defenders"])
				self setClientCvar("cg_objectiveText", &"RE_OBJ_DEFENDERS", level.scorelimit);
		}
		else
		{
			if(self.pers["team"] == game["attackers"])
				self setClientCvar("cg_objectiveText", &"RE_OBJ_ATTACKERS_NOSCORE");
			else if(self.pers["team"] == game["defenders"])
				self setClientCvar("cg_objectiveText", &"RE_OBJ_DEFENDERS_NOSCORE");
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
	level endon("bomb_planted");
	level endon("round_ended");

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

	// If teams currently exist
	if(level.exist["allies"] && level.exist["axis"])
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

	wait 7;

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

	wait 10;
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
		timelimit = getCvarFloat("scr_re_timelimit");
		if(level.timelimit != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_re_timelimit", "1440");
			}

			level.timelimit = timelimit;
// La Truffe ->
//			setCvar("ui_re_timelimit", level.timelimit);
			setCvar("ui_timelimit", level.timelimit);
// La Truffe <-
		}

		scorelimit = getCvarInt("scr_re_scorelimit");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
// La Truffe ->
//			setCvar("ui_re_scorelimit", level.scorelimit);
			setCvar("ui_scorelimit", level.scorelimit);
// La Truffe <-
			level notify("update_allhud_score");

			if(game["matchstarted"])
				checkScoreLimit();
		}

		roundlimit = getCvarInt("scr_re_roundlimit");
		if(level.roundlimit != roundlimit)
		{
			level.roundlimit = roundlimit;
// La Truffe ->
//			setCvar("ui_re_roundlimit", level.roundlimit);
			setCvar("ui_roundlimit", level.roundlimit);
// La Truffe <-

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

	if(level.exist["allies"])
		level.didexist["allies"] = true;
	if(level.exist["axis"])
		level.didexist["axis"] = true;

	if(level.roundended)
		return;

	// if both allies and axis were alive and now they are both dead in the same instance
	if(oldvalue["allies"] && !level.exist["allies"] && oldvalue["axis"] && !level.exist["axis"])
	{
		if(level.bombplanted)
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
		if(level.bombplanted && level.planting_team == "allies")
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
		if(level.bombplanted && level.planting_team == "axis")
			return;

		iprintln(&"MP_AXISHAVEBEENELIMINATED");
		level thread playSoundOnPlayers("mp_announcer_axiselim");
		level thread endRound("allies");
		return;
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

sayMoveIn()
{
	wait 2;

	alliedsoundalias = game["allies"] + "_move_in";
	axissoundalias = game["axis"] + "_move_in";

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(player.pers["team"] == "allies")
			player playLocalSound(alliedsoundalias);
		else if(player.pers["team"] == "axis")
			player playLocalSound(axissoundalias);
	}
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
		level thread playSoundOnPlayers("MP_announcer_round_draw");
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

		if(!isdefined(player.pers["team"]) || player.pers["team"] == "spectator" || player == self)
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
		self.pers["weapon1"] = undefined;
		self.pers["weapon2"] = undefined;
		self.pers["spawnweapon"] = undefined;
		self.pers["savedmodel"] = undefined;

		self setClientCvar("ui_allow_weaponchange", "1");
		self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);

		self notify("joined_team");
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
		self.pers["weapon1"] = undefined;
		self.pers["weapon2"] = undefined;
		self.pers["spawnweapon"] = undefined;
		self.pers["savedmodel"] = undefined;

		self setClientCvar("ui_allow_weaponchange", "1");
		self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);

		self notify("joined_team");
	}

	if(!isdefined(self.pers["weapon"]))
		self openMenu(game["menu_weapon_axis"]);
}

menuSpectator()
{
	if(self.pers["team"] != "spectator")
	{
		self notify("joined_spectators");

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
		spawnSpectator();

		if(level.splitscreen)
			self setClientCvar("g_scriptMainMenu", game["menu_ingame_spectator"]);
		else
			self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);
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
			self.spawned = undefined;
			spawnPlayer();
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
				self.spawned = undefined;
				spawnPlayer();
				self thread printJoinedTeam(self.pers["team"]);
				level checkMatchStart();
			}
			else
			{
				spawnPlayer();
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
				self.spawned = undefined;
				spawnPlayer();
				self thread printJoinedTeam(self.pers["team"]);
			}
		} // else if joining an empty team, spawn and check for match start
		else if(!level.didexist[self.pers["team"]] && !level.roundended)
		{
			self.spawned = undefined;
			spawnPlayer();
			self thread printJoinedTeam(self.pers["team"]);
			level checkMatchStart();
		} // else you will spawn with selected weapon next round
		else
		{
			weaponname = maps\mp\gametypes\_weapons::getWeaponName(self.pers["weapon"]);

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
	
	maps\mp\gametypes\_retrieval::initflag();

	
}


pickupFlag(flag)
{
	flag notify("end_autoreturn");

	flag.origin = flag.origin + (0, 0, -10000);
	flag.flagmodel hide();
	self.flag = flag;
	self.dont_auto_balance = true;

	flag deleteFlagWaypoint();

	objective_state(self.flag.objective, "invisible");

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

		// set compass flag position on player
		objective_position(self.flag.objective, self.flag.origin);
		objective_state(self.flag.objective, "current");

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

returnFlag()
{
	self notify("end_autoreturn");

 	self.origin = self.home_origin;
 	self.flagmodel.origin = self.home_origin;
 	self.flagmodel.angles = self.home_angles;
	self.flagmodel show();
	self.atbase = true;

	// set compass flag position on player
	objective_position(self.objective, self.origin);
	objective_state(self.objective, "current");

	self createFlagWaypoint();
}

autoReturn()
{
	self endon("end_autoreturn");

	wait 120;
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

	iconSize = 20;

	if (self.pers["team"] == "allies")
	{
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
		self.flagAttached setShader(level.hudflag_axis, iconSize, iconSize);
	}
	else
	{
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
		self.flagAttached setShader(level.hudflag_allies, iconSize, iconSize);
	}
	//self attach(flagModel, "J_Spine4", true);
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

	self.flagAttached destroy();
}

createFlagWaypoint()
{
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
//		waypoint setShader(self.objpointflag, 7, 7);

	waypoint setwaypoint(true);
	self.waypoint = waypoint;
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
deleteFlagWaypoint()
{
	if(isdefined(self.waypoint))
		self.waypoint destroy();
}