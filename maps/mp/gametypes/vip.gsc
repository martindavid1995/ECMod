/*
	V.I.P. - AWE mod compatible version
	Author : La Truffe
	
	Credits : Bell (AWE mod), Ravir (cvardef function)

	Version : 1.3
	
	Objective : Kill the VIP of the other team while protecting yours. A team scores when the enemy VIP has been killed.
	Map ends : When one team reaches the score limit, or time limit is reached.
	Respawning : After a configurable delay / Near teammates.
	
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

	// Over-override Callback_PlayerDamage
	
	level.vip_callbackPlayerDamage = level.callbackPlayerDamage;
	level.callbackPlayerDamage = ::VIP_Callback_PlayerDamage;
}

VIP_Callback_PlayerDamage (eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if (isdefined (sWeapon) && ((sWeapon == level.vip_smokenade[game["allies"]]) || (sWeapon == level.vip_smokenade[game["axis"]])))
	{
		// Damage caused by a VIP smoke nade : not a real damage

		if (isdefined (self) && isPlayer (self) && (self IsVIP ()) && (isdefined (self.pers["team"])) && (sWeapon == level.vip_smokenade[game[self.pers["team"]]]))
			self thread VIPSmoke (vPoint);
			
		return;
	}
	
	[[level.vip_callbackPlayerDamage]] (eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
}

Callback_StartGameType()
{
	level.splitscreen = isSplitScreen();

	// defaults if not defined in level script
	if (! isDefined (game["allies"]))
		game["allies"] = "american";
	if (! isDefined (game["axis"]))
		game["axis"] = "german";

	// server cvar overrides
	allies = cvardef ("scr_allies", "", "", "", "string");
	if (allies != "")
		game["allies"] = allies;
	axis = cvardef ("scr_axis", "", "", "", "string");
	if (axis != "")
		game["axis"] = axis;
	
	precacheStatusIcon("hud_status_dead");
	precacheStatusIcon("hud_status_connecting");
	precacheStatusIcon ("hudicon_" + game["allies"]);
	precacheStatusIcon ("hudicon_" + game["axis"]);
	
	precacheRumble("damage_heavy");

	precacheString (&"PLATFORM_PRESS_TO_SPAWN");
	precacheString (&"MP_TIME_TILL_SPAWN");
	precacheString (&"VIP_OBJ_TEXT_NOSCORE");
	precacheString (&"VIP_VIP_KILLED_HIMSELF");
	precacheString (&"VIP_VIP_TEAMKILLED_BY");
	precacheString (&"VIP_VIP_KILLED_BY");
	precacheString (&"VIP_VIP_KILLED");
	precacheString (&"VIP_PROTECTED_VIP");
	precacheString (&"VIP_BECOME_VIP1");
	precacheString (&"VIP_BECOME_VIP2");
	precacheString (&"VIP_NO_LONGER_VIP");
	precacheString (&"VIP_NEW_VIP_ALLIES");
	precacheString (&"VIP_NEW_VIP_AXIS");
	precacheString (&"VIP_VIP_CHANGE_TEAM");
	precacheString (&"VIP_VIP_SPECTATOR");
	precacheString (&"VIP_VIP_DISCONNECTED");
	precacheString (&"VIP_VIP_SPOTTED");
	precacheString (&"VIP_VIP_ALIVE");
	precacheString (&"VIP_VIP_ALIVE_RECORD");
	
	precacheHeadIcon ("objective_" + game["allies"] + "_down");
	precacheHeadIcon ("objective_" + game["axis"] + "_down");
	
	precacheShader ("objective_" + game["allies"]);
	precacheShader ("objective_" + game["axis"]);

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

	if (!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for (i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint ();

	allowed[0] = "tdm";
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.vipmaxsmokenades = 9;
	level.vipmaxfragnades = 9;

	// Time limit per map
	level.timelimit = cvardef ("scr_vip_timelimit", 30, 0, 1440, "float");
	setCvar ("ui_timelimit", level.timelimit);
	makeCvarServerInfo ("ui_timelimit", "30");

	// Score limit per map
	level.scorelimit = cvardef ("scr_vip_scorelimit", 20, 0, 9999, "int");
	setCvar ("ui_scorelimit", level.scorelimit);
	makeCvarServerInfo ("ui_scorelimit", "20");

	// Respawn delay
	level.respawndelay = cvardef ("scr_vip_respawndelay", 10, 0, 600, "int");
	setCvar ("ui_vip_respawndelay", level.respawndelay);
	storeServerInfoDvar ("ui_vip_respawndelay");

	// Delay for selecting a new VIP
	level.vipdelay = cvardef ("scr_vip_vipdelay", 5, 0, 600, "int");
	setCvar ("ui_vip_vipdelay", level.vipdelay);
	storeServerInfoDvar ("ui_vip_vipdelay");

	// VIP visibility on compass by team mates
	level.vipvisiblebyteammates = cvardef ("scr_vip_vipvisiblebyteammates", 1, 0, 1, "int");
	setCvar ("ui_vip_vipvisiblebyteammates", level.vipvisiblebyteammates);
	storeServerInfoDvar ("ui_vip_vipvisiblebyteammates");

	// VIP visibility on compass by enemies
	level.vipvisiblebyenemies = cvardef ("scr_vip_vipvisiblebyenemies", 1, 0, 1, "int");
	setCvar ("ui_vip_vipvisiblebyenemies", level.vipvisiblebyenemies);
	storeServerInfoDvar ("ui_vip_vipvisiblebyenemies");

	// Points for killing a VIP
	level.pointsforkillingvip = cvardef ("scr_vip_pointsforkillingvip", 5, -999, 999, "int");
	setCvar ("ui_vip_pointsforkillingvip", level.pointsforkillingvip);
	storeServerInfoDvar ("ui_vip_pointsforkillingvip");

	// Points for protecting VIP
	level.pointsforprotectingvip = cvardef ("scr_vip_pointsforprotectingvip", 3, -999, 999, "int");
	setCvar ("ui_vip_pointsforprotectingvip", level.pointsforprotectingvip);
	storeServerInfoDvar ("ui_vip_pointsforprotectingvip");

	// Points for a VIP staying alive at each cycle
	level.vippoints = cvardef ("scr_vip_vippoints", 2, -999, 999, "int");
	setCvar ("ui_vip_vippoints", level.vippoints);
	storeServerInfoDvar ("ui_vip_vippoints");

	// Cyclic delay after which a VIP scores points for staying alive
	level.vippointscycle = cvardef ("scr_vip_vippoints_cycle", 3, 0, 600, "int");
	setCvar ("ui_vip_vippoints_cycle", level.vippointscycle);
	storeServerInfoDvar ("ui_vip_vippoints_cycle");

	// Distance max for VIP protection
	level.vipprotectiondistance = cvardef ("scr_vip_vipprotectiondistance", 800, 0, 999999, "int");

	// Time max for VIP protection
	level.vipprotectiontime = cvardef ("scr_vip_vipprotectiontime", 15, 0, 600, "int");

	// VIP pistol
	level.vippistol = cvardef ("scr_vip_vippistol", 1, 0, 1, "int");
	setCvar ("ui_vip_vippistol", level.vippistol);
	storeServerInfoDvar ("ui_vip_vippistol");

	// VIP smoke grenades
	level.vipsmokenades = cvardef ("scr_vip_vipsmokenades", 3, 0, level.vipmaxsmokenades, "int");
	setCvar ("ui_vip_vipsmokenades", level.vipsmokenades);
	storeServerInfoDvar ("ui_vip_vipsmokenades");

	// VIP smoke radius
	level.vipsmokeradius = cvardef ("scr_vip_vipsmokeradius", 380, 0, 999999, "int");

	// VIP smoke duration
	level.vipsmokeduration = cvardef ("scr_vip_vipsmokeduration", 70, 0, 600, "int");

	// VIP frag grenades
	level.vipfragnades = cvardef ("scr_vip_vipfragnades", 0, 0, level.vipmaxfragnades, "int");
	setCvar ("ui_vip_vipfragnades", level.vipfragnades);
	storeServerInfoDvar ("ui_vip_vipfragnades");

	// VIP health
	level.viphealth = cvardef ("scr_vip_viphealth", 150, 0, 9999, "int");
	setCvar ("ui_vip_viphealth", level.viphealth);
	storeServerInfoDvar ("ui_vip_viphealth");
	
	// Special binoculars
	level.vipbinoculars = cvardef ("scr_vip_binoculars", 1, 0, 1, "int");
	setCvar ("ui_vip_binoculars", level.vipbinoculars);
	storeServerInfoDvar ("ui_vip_binoculars");

	// Force respawning
	level.forcerespawn = cvardef ("scr_forcerespawn", 0, 0, 1, "int");

	if(!isDefined(game["state"]))
		game["state"] = "playing";

	level.mapended = false;

	level.team["allies"] = 0;
	level.team["axis"] = 0;

	level.alive_time_record = 0;
	
	level.objnumber = [];
	level.objnumber["allies"] = 0;
	level.objnumber["axis"] = 1;

	level.vip_player = [];
	level.vip_player["allies"] = undefined;
	level.vip_player["axis"] = undefined;

	level._effect["vip_fx"] = loadfx ("fx/misc/flare_smoke_9sec.efx");

	level.vip_pistol["american"] = "colt_vip_mp";
	level.vip_pistol["british"] = "webley_vip_mp";
	level.vip_pistol["russian"] = "tt30_vip_mp";
	level.vip_pistol["german"] = "luger_vip_mp";

	if (level.vippistol)
	{
		precacheItem (level.vip_pistol[game["allies"]]);
		precacheItem (level.vip_pistol[game["axis"]]);
	}
	
	level.vip_smokenade["american"] = "smoke_grenade_american_vip_mp";
	level.vip_smokenade["british"] = "smoke_grenade_british_vip_mp";
	level.vip_smokenade["russian"] = "smoke_grenade_russian_vip_mp";
	level.vip_smokenade["german"] = "smoke_grenade_german_vip_mp";

	if (level.vipsmokenades)
	{
		precacheItem (level.vip_smokenade[game["allies"]]);
		precacheItem (level.vip_smokenade[game["axis"]]);
	}

	thread startGame();
	thread updateGametypeCvars();
	thread maps\mp\gametypes\_teams::addTestClients();

	level thread SelectVIP ("allies");
	level thread SelectVIP ("axis");
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

	self thread setServerInfoDvars ();

	if(game["state"] == "intermission")
	{
		spawnIntermission ();
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
			spawnSpectator ();

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
			if (! isdefined (self.pers["skipserverinfo"]))
				self openMenu (game["menu_serverinfo"]);
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
	
	if (self IsVIP ())
	{
		iprintlnFIXED (&"VIP_VIP_DISCONNECTED", self);
		RemoveVIPFromTeam (self.pers["team"]);
	}

	lpselfnum = self getEntityNumber();
	lpGuid = self getGuid();
	logPrint("Q;" + lpGuid + ";" + lpselfnum + ";" + self.name + "\n");
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if (self.sessionteam == "spectator")
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
			
			// Damage caused to the enemy VIP : record the time
			
			if ((self IsVIP ()) && isdefined (eAttacker) && isPlayer (eAttacker))
				eAttacker.last_VIP_damage_time = getTime ();
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

	if (! isdefined (self.switching_vip))
	{
		// If the player was killed by a head shot, let players know it was a head shot kill
		if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE")
			sMeansOfDeath = "MOD_HEAD_SHOT";

		// send out an obituary message to all clients about the kill
		obituary (self, attacker, sWeapon, sMeansOfDeath);

		self maps\mp\gametypes\_weapons::dropWeapon();
		self maps\mp\gametypes\_weapons::dropOffhand();
	}
	
	self.sessionstate = "dead";
	self.statusicon = "hud_status_dead";

	if ((! isdefined (self.switching_teams)) && (! isdefined (self.switching_vip)))
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
				attacker thread CheckProtectedVIP (self);
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

	if (self isVIP ())
		self thread VIPkilledBy (attacker);

	if (! isdefined (self.switching_vip))
		level notify ("update_allhud_score");

	if (! isdefined (self.switching_vip))
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
		self maps\mp\gametypes\_killcam::killcam(attackerNum, delay, psOffsetTime, true);

	if (isdefined (self.switching_vip))
	{
		self.switching_vip = undefined;
		self.isvip = true;
		body delete ();
	}

	self thread respawn();
}

spawnPlayer()
{
	self endon("disconnect");
	self notify("spawned");
	self notify("end_respawn");

	team = self.pers["team"];
	
	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionteam = team;
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;

	if (self IsVIP ())
		self.statusicon = "hudicon_" + game[team];
	else
		self.statusicon = "";
		
	self.last_VIP_damage_time = undefined;	
	
	if (self IsVIP ())
		self.maxhealth = level.viphealth;
	else
		self.maxhealth = 100;
	self.health = self.maxhealth;

	self.friendlydamage = undefined;

	spawnpointname = "mp_tdm_spawn";
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

	if ((self IsVIP ()) && level.vippistol)
	{
		pistol = level.vip_pistol[game[team]];
		self giveWeapon (pistol);
		self giveMaxAmmo (pistol);
		self setSpawnWeapon (pistol);
	}
	else
	{
		maps\mp\gametypes\_weapons::givePistol ();

		// Bug tracking...
	
		if ((! maps\mp\gametypes\_weapons::isMainWeapon (self.pers["weapon"])) && (! maps\mp\gametypes\_weapons::isPistol (self.pers["weapon"])))
			logprint ("DEBUG : spawnPlayer () self.pers[\"weapon\"] = \"" + self.pers["weapon"] + "\"\n");
		else
		{
			self giveWeapon (self.pers["weapon"]);
			self giveMaxAmmo (self.pers["weapon"]);
			self setSpawnWeapon (self.pers["weapon"]);
		}
	}
			
	maps\mp\gametypes\_weapons::giveGrenades ();

	if ((self IsVIP ()) && level.vipsmokenades)
	{
		self RemoveRegularSmokeNades ();

		smokenade = level.vip_smokenade[game[team]];
		self giveWeapon (smokenade);
		self setWeaponClipAmmo (smokenade, level.vipsmokenades);
	}

	if ((self IsVIP ()) && level.vipfragnades)
	{
// AWE ->
		fragnade = level.awe_cook + "frag_grenade_" + game[team] + "_mp";
// AWE <-

// STD ->
/*
		fragnade = "frag_grenade_" + game[team] + "_mp";
*/
// STD <-

		self setWeaponClipAmmo (fragnade, level.vipfragnades);
	}
		
	maps\mp\gametypes\_weapons::giveBinoculars ();

	self setClientCvar ("cg_objectiveText", &"VIP_OBJ_TEXT_NOSCORE");

	if (self IsVIP ())
	{
		// VIP attributes
		
		self.vip_credit = 0;
		self.vip_alive_time = getTime ();
		self.vip_alive_time_cycle = self.vip_alive_time;
			
		// Add the objective on compass

		if (level.vipvisiblebyteammates || level.vipvisiblebyenemies)
		{
			if (level.vipvisiblebyteammates && level.vipvisiblebyenemies)
				objteam = "none";
			else if (level.vipvisiblebyteammates)
				objteam = team;
			else
				objteam = EnemyTeam (team);
			
			objective_add (level.objnumber[team], "current", self.origin, "objective_" + game[team]);
			objective_team (level.objnumber[team], objteam);
		}

		// Follow VIP until he's no longer a VIP
		
		self thread FollowVIP ();
	}
	
	self thread updateTimer();

	if (level.vipbinoculars)
		self thread CheckBinoculars ();
	
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

	// VIP is forced to respawn
	if ((level.forcerespawn <= 0) && (! self IsVIP ()))
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
	level notify ("intermission");

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

	if (winningteam == "allies")
		level thread playSoundOnPlayers ("MP_announcer_allies_win");
	else if (winningteam == "axis")
		level thread playSoundOnPlayers ("MP_announcer_axis_win");
	else
		level thread playSoundOnPlayers ("MP_announcer_round_draw");

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
		
		player spawnIntermission ();
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
	waittillframeend;

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
		timelimit = cvardef ("scr_vip_timelimit", 30, 0, 1440, "float");
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

		scorelimit = cvardef ("scr_vip_scorelimit", 20, 0, 9999, "int");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
			setCvar("ui_scorelimit", level.scorelimit);
			level notify("update_allhud_score");
		}
		checkScoreLimit();

		wait 2;
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

menuAutoAssign()
{
	if (self IsVIP ())
	{
		self iprintlnbold (&"VIP_VIP_CHANGE_TEAM");
		return;
	}

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
	if (self IsVIP ())
	{
		self iprintlnbold (&"VIP_VIP_CHANGE_TEAM");
		return;
	}

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
	if (self IsVIP ())
	{
		self iprintlnbold (&"VIP_VIP_CHANGE_TEAM");
		return;
	}

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
	if (self IsVIP ())
	{
		self iprintlnbold (&"VIP_VIP_SPECTATOR");
		return;
	}

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
	if ((! isDefined (self)) || (! isDefined (self.pers["team"])) || ((self.pers["team"] != "allies") && (self.pers["team"] != "axis")))
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

	// Bug tracking...
	
	if ((! maps\mp\gametypes\_weapons::isMainWeapon (weapon)) && (! maps\mp\gametypes\_weapons::isPistol (weapon)))
	{
		logprint ("DEBUG : menuWeapon () weapon = \"" + weapon + "\"\n");

		if (self.pers["team"] == "allies")
			self openMenu (game["menu_weapon_allies"]);
		else if (self.pers["team"] == "axis")
			self openMenu (game["menu_weapon_axis"]);

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

IsVIP ()
{
	if (! isdefined (self.isvip))
		self.isvip = false;

	return self.isvip;
}

SetVIP ()
{
	if (self IsVIP ())
		// We shouldn't be here...
		return;

	// VIP attributes
		
	self.in_smoke = spawnstruct ();
	self.in_smoke.status = false;
	self.in_smoke.nextnade = 0;
	self.in_smoke.statusbynade = [];
	for (i = 0; i < level.vipmaxsmokenades; i ++)
		self.in_smoke.statusbynade[i] = false;

	vipteam = self.pers["team"];
	
	if (isdefined (level.vip_player[vipteam]))
		// Already a VIP in the team ?! (should not happen)
		return;
	
	level.vip_player[vipteam] = self;
	self.dont_auto_balance = true;

	// Notify the change to the player himself

	self iprintlnbold (&"VIP_BECOME_VIP1");
	self iprintlnbold (&"VIP_BECOME_VIP2");
	self playLocalSound ("ctf_touchenemy");

	// Notify the change to other players

	players = getentarray ("player", "classname");
	for (i = 0; i < players.size; i ++)
	{
		player = players[i];
		if ((! isdefined (player.pers["team"])) || (player == self))
			continue;

		if (vipteam == "allies")
			iprintlnFIXED (&"VIP_NEW_VIP_ALLIES", self, player);
		else
			iprintlnFIXED (&"VIP_NEW_VIP_AXIS", self, player);
	}

	// Suicide the player with a little effect

	self.switching_vip = true;
	self suicide ();
	playfx (level._effect["vip_fx"], self.origin);
}

ForceVIPpistol ()
{
// AWE ->
	if (self.awe_invulnerable && level.awe_spawnprotectiondisableweapon)
		return;
// AWE <-

	weaponb = self getWeaponSlotWeapon ("primaryb");
	current = self getCurrentWeapon ();
	pistol = level.vip_pistol[game[self.pers["team"]]];

// AWE ->
	if (weaponb == level.awe_sprintweapon)
		return;
// AWE <-

	if (weaponb != "none")
	{
		self dropItem (weaponb);
		self switchToWeapon (pistol);
	}	
}

RemoveRegularSmokeNades ()
{
	team = self.pers["team"];
	
// AWE ->
	self takeWeapon (level.awe_smoke + "smoke_grenade_" + game["allies"] + "_mp");
	self takeWeapon (level.awe_smoke + "smoke_grenade_" + game["axis"] + "_mp");
// AWE <-

// STD ->
/*
	self takeWeapon ("smoke_grenade_" + game["allies"] + "_mp");
	self takeWeapon ("smoke_grenade_" + game["axis"] + "_mp");
*/
// STD <-
}

FollowVIP ()
{
	vipteam = self.pers["team"];

	self LoopOnVIP ();
	
	level thread SelectVIP (vipteam);
}

LoopOnVIP ()
{
	self endon ("disconnect");
	self endon ("killed_vip");

	while ((isdefined (self)) && (isPlayer (self)) && (isdefined (self.pers["team"])) && (self IsVIP ()))
	{
		wait 0.05;
		
		vipteam = self.pers["team"];
		
		// Force head icon

		self SetVIPIcon ();
		
		// Update icon position and visibility on compass
	
		if (level.vipvisiblebyteammates || level.vipvisiblebyenemies)
		{
			objective_position (level.objnumber[vipteam], self.origin);

			self.in_smoke.status = false;
			for (i = 0; i < level.vipmaxsmokenades; i ++)
				self.in_smoke.status = self.in_smoke.status || self.in_smoke.statusbynade[i];
				
			if (self.in_smoke.status)
				objective_state (level.objnumber[vipteam], "invisible");
			else
				objective_state (level.objnumber[vipteam], "current");
		}

		// Make sure VIP pistol is used

		if (level.vippistol)
			self ForceVIPpistol ();
			
		// Make sure VIP has no regular smoke nade
		
		if (level.vipsmokenades)
			self RemoveRegularSmokeNades ();
			
		// Reward VIP for staying alive is enemy team is populated

		timepassed = (getTime () - self.vip_alive_time_cycle) / 1000;
		if (timepassed > level.vippointscycle * 60)
		{
			self.vip_alive_time_cycle = getTime ();
			playerscount = maps\mp\gametypes\_teams::CountPlayers ();
			if (playerscount[EnemyTeam (vipteam)] > 0)
				self.score += level.vippoints;
		}
	}
}

VIPSmoke (location)
{
	if ((! level.vipvisiblebyteammates) && (! level.vipvisiblebyenemies))
		return;

	self endon ("killed_vip");
	self endon ("disconnect");

	nade = self.in_smoke.nextnade;
	self.in_smoke.nextnade ++;
	
	vipteam = self.pers["team"];
	endtime = getTime () + level.vipsmokeduration * 1000;
	
	while (getTime () < endtime)
	{
		self.in_smoke.statusbynade[nade] = (distance (self.origin, location) <= level.vipsmokeradius);
		wait 0.1;
	}

	self.in_smoke.statusbynade[nade] = false;
}

RemoveVIPFromTeam (team)
{
	// Team has no more VIP
	
	level.vip_player[team] = undefined;
	
	// Remove the objective on compass

	if (level.vipvisiblebyteammates || level.vipvisiblebyenemies)
		objective_delete (level.objnumber[team]);
}

UnsetVIP ()
{
	if (! self IsVIP ())
		// We shouldn't be here...
		return;
		
	RemoveVIPFromTeam	(self.pers["team"]);

	self.isvip = false;
	self.dont_auto_balance = undefined;
	self.in_smoke = undefined;
	self UnsetVIPIcon ();

	// Notify the change to the player himself only

	self iprintlnbold (&"VIP_NO_LONGER_VIP");
}

SetVIPIcon ()
{
	if (! level.drawfriend)
		return;
	
// AWE ->
	if (self.awe_invulnerable)
		return;
// AWE <-

	headicon_vip = "objective_" + game[self.pers["team"]] + "_down";
	headicon_notvip = game["headicon_" + self.pers["team"]];
	
	if (self.headicon == headicon_notvip)
		self.headicon = headicon_vip;
}

UnsetVIPIcon ()
{
	if (! level.drawfriend)
		return;

	headicon_notvip = game["headicon_" + self.pers["team"]];
	self.headicon = headicon_notvip;
}

SelectVIP (team)
{
	wait level.vipdelay;
	
	candidate = undefined;
	candidate_credit = 0;

	for ( ; ; )
	{
		players = getentarray ("player", "classname");

		// Increase randomly the credit of all living players of the team
	
		for (i = 0; i < players.size; i ++)
		{
			player = players[i];
		
			if ((! isdefined (player.pers["team"])) || (player.pers["team"] != team))
				continue;

			if (! isdefined (player.vip_credit))
				player.vip_credit = 0;
		
			if (player.sessionstate == "playing")
				player.vip_credit += randomInt (100);
		}
	
		// Choose the new VIP = the alive player with the highest credit
	
		for (i = 0; i < players.size; i ++)
		{
			player = players[i];
		
			if ((! isdefined (player.pers["team"])) || (player.pers["team"] != team))
				continue;
		
			if (player.vip_credit > candidate_credit)
			{
				candidate = player;
				candidate_credit = player.vip_credit;
			}
		}

		playerscount = maps\mp\gametypes\_teams::CountPlayers ();

		if (isdefined (candidate) && (candidate.sessionstate == "playing") && (playerscount[EnemyTeam (team)] > 0))
			break;
		
		wait 1;
	}
	
	candidate SetVIP ();
}

VIPkilledBy (killer)
{
	vipteam = self.pers["team"];
	enemyteam = EnemyTeam (vipteam);

	if (isPlayer (killer))	
		killerteam = killer.pers["team"];
	else
		killerteam = undefined;

	if (! isdefined (killerteam))
	{
		iprintlnFIXED (&"VIP_VIP_KILLED", self);
		teamscoring	= enemyteam;
	}
	else if (killer == self)
	{
		if (isdefined (self.switching_teams))
			return;
			
		iprintlnFIXED (&"VIP_VIP_KILLED_HIMSELF", killer);
		teamscoring = enemyteam;
	}
	else if (killerteam == vipteam)
	{
		iprintlnFIXED (&"VIP_VIP_TEAMKILLED_BY", killer);
		teamscoring = enemyteam;
	}
	else
	{
		iprintlnFIXED (&"VIP_VIP_KILLED_BY", killer);
		teamscoring = killerteam;
		killer.score += level.pointsforkillingvip - 1;	// 1 point already given in Callback_PlayerKilled
	}

	alive_time = getTime () - self.vip_alive_time;
	alive_sec_total = int (alive_time / 1000);
	alive_min = int (alive_sec_total / 60);
	alive_sec = alive_sec_total - alive_min * 60;
	if (alive_sec >= 10)
		alive_str = alive_min + "'" + alive_sec + "''";
	else
		alive_str = alive_min + "'0" + alive_sec + "''";

	if (alive_time > level.alive_time_record)
	{
		iprintln (&"VIP_VIP_ALIVE_RECORD", alive_str);
		level.alive_time_record = alive_time;
	}
	else
		iprintln (&"VIP_VIP_ALIVE", alive_str);

	setTeamScore (teamscoring, getTeamScore (teamscoring) + 1);

	wait 1;
	
	playSoundOnPlayers ("ctf_touchcapture", teamscoring);
	playSoundOnPlayers ("ctf_enemy_touchcapture", vipteam);
	
	self notify ("killed_vip");

	self UnsetVIP ();
}

EnemyTeam (team)
{
	if (team == "axis")
		enemyteam = "allies";
	else
		enemyteam = "axis";
	return (enemyteam);
}

CheckBinoculars ()
{
	self endon ("disconnect");
	self endon ("killed_player");
	
	for ( ; ; )
	{
		if (isdefined (self.vip_hudvipspotted))
			self.vip_hudvipspotted destroy ();

		self waittill ("binocular_enter");
		self thread CheckVIPspotted ();
		self waittill ("binocular_exit");

		if (isdefined (self.vip_hudvipspotted))
			self.vip_hudvipspotted destroy ();
		
		wait 0.2;
	}	
}

CheckVIPspotted ()
{
	self endon ("disconnect");
	self endon ("killed_player");
	self endon ("binocular_exit");

	wait 0.5;
	
	team = self.pers["team"];
	vipteam = EnemyTeam (team);
	
	for ( ; ; )
	{
		wait 0.1;
	
		if (! isdefined (level.vip_player[vipteam]))
			// No VIP on team yet
			continue;
		
		vip = level.vip_player[vipteam];

		// Condition on alive state
		cond_state = (vip.sessionstate == "playing");
		
		// Condition on invisibility in smoke
		cond_smoke = (isdefined (vip.in_smoke)) && (isdefined (vip.in_smoke.status)) && (! vip.in_smoke.status);
		
		self_eyepos = self getEye ();
		vip_eyepos = vip getEye ();
		self_angles = self getplayerangles ();

		trace = bulletTrace (self_eyepos, vip_eyepos, false, undefined);
		virtualpoint = trace["position"];
		virtual_dist = distance (vip_eyepos, virtualpoint);

		// Condition on direct visibility
		cond_visible = (virtual_dist < 5);

		virtual_angles = vectortoangles (vectornormalize (trace["normal"]));

		delta_angles_v = virtual_angles[0] - self_angles[0];
		if (delta_angles_v < 0)
			delta_angles_v += 360;
		else if (delta_angles_v > 360)
			delta_angles_v -= 360;

		delta_angles_h = virtual_angles[1] - self_angles[1];
		if (delta_angles_h < 0)
			delta_angles_h += 360;
		else if (delta_angles_h > 360)
			delta_angles_h -= 360;

		// Condition on view angles : less than 4 degrees vertically and horizontally
		cond_angle = ((delta_angles_v < 4) || (delta_angles_v > 356)) && ((delta_angles_h < 4) || (delta_angles_h > 356));

		// Resulting condition for spotting enemy VIP
		cond = cond_state && cond_smoke && cond_visible && cond_angle;
		
		if (cond)
		{
			if (! isdefined (self.vip_hudvipspotted))
			{
				self.vip_hudvipspotted = newClientHudElem (self);
				self.vip_hudvipspotted.x = 320;
				self.vip_hudvipspotted.y = 20;
				self.vip_hudvipspotted.alignX = "center";
				self.vip_hudvipspotted.alignY = "middle";
				self.vip_hudvipspotted.color = (1, 1, 1);
				self.vip_hudvipspotted.alpha = 1;
				self.vip_hudvipspotted.fontScale = 1.6;
				self.vip_hudvipspotted.archived = true;
				self.vip_hudvipspotted setText (&"VIP_VIP_SPOTTED");
			}
		}
		else
			if (isdefined (self.vip_hudvipspotted))
				self.vip_hudvipspotted destroy ();
	}
}

CheckProtectedVIP (victim)
{
	if (self IsVIP ())
		// No "self protection" for VIPs
		return;
		
	team = self.pers["team"];
	vip = level.vip_player[team];
	
	// Condition on distance to VIP
	if (isdefined (vip) && isPlayer (vip) && (vip.sessionstate == "playing"))
		cond_dist = (distance (victim.origin, vip.origin) <= level.vipprotectiondistance);
	else
		cond_dist = false;
	
	// Condition on time since last damage to VIP
	if (isdefined (vip) && isPlayer (vip) && (vip.sessionstate == "playing") && isdefined (victim.last_VIP_damage_time))
		cond_time = ((getTime () - victim.last_VIP_damage_time) < level.vipprotectiontime * 1000);
	else
		cond_time = false;
	
	if (cond_dist || cond_time)
	{
		iprintlnFIXED (&"VIP_PROTECTED_VIP", self);
		self.score += level.pointsforprotectingvip - 1;	// 1 point already given in Callback_PlayerKilled
	}
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