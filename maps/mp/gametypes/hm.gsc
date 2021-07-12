// Modified by La Truffe

/*
Orignal: Ravir's "Assassin" gamtype for COD and UO

Revised: Artful_Dodger's "Espionage Agent" gametype for COD and UO - revised from Assassin.

COD2 1.3 version: Tally. Ported over Artful_Dodger's ESP gametype and added extra features, and changed scoring and respawning patterns.

*/
main()
{
	level.callbackStartGameType = ::Callback_StartGameType;
	level.callbackPlayerConnect = ::Callback_PlayerConnect;
	level.callbackPlayerDisconnect = ::Callback_PlayerDisconnect;
	level.callbackPlayerDamage = ::Callback_PlayerDamage;
	level.callbackPlayerKilled = ::Callback_PlayerKilled;
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();

	level.spawnplayer = ::spawnplayer;
	level.autoassign = ::menuAutoAssign;
	level.allies = ::menuAllies;
	level.axis = ::menuAxis;
	level.spectator = ::menuSpectator;
	level.weapon = ::menuWeapon;
	level.endgameconfirmed = ::endMap;
	
}

Callback_StartGameType()
{
// La Truffe ->
	if (isdefined (level.awe_spawnprotectionheadicon) && level.awe_spawnprotectionheadicon)
		level.awe_spawnprotectionheadicon = false;
// La Truffe <-

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

	if(!isDefined(game["precachedone"]))
	{
		precacheStatusIcon("hud_status_dead");
		precacheStatusIcon("hud_status_connecting");
		precacheRumble("damage_heavy");
		precacheString(&"PLATFORM_PRESS_TO_SPAWN");
		game["precachedone"] = true;
	}

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
	thread maps\mp\gametypes\_quickmessages::init();

//	if(!isDefined(game["precachedone"]))
//	{
		precacheString(&"HM_HITMAN");
		precacheString(&"HM_KILL_COMMANDER");
		precacheString(&"HM_NEW_HITMAN");
		precacheString(&"HM_NEW_GUARD");
		precacheString(&"HM_NEW_COMMANDER");
		precacheString(&"HM_HITMAN_VS_HITMAN");
		precacheString(&"HM_OTHER_HITMANS");
		precacheString(&"HM_AVOID_GUARDS");
		precacheString(&"HM_HITMAN_KILL_COMMANDER");
		precacheString(&"HM_COMMANDER_EVADE_HITMAN");
		precacheString(&"HM_GUARD_STOP_HITMAN");
		precacheString(&"HM_GUARD_PROTECT_COMMANDER");
		precacheString(&"HM_DONT_KILL_GUARDS");
		precacheString(&"HM_AVOID_GUARDS");
		precacheString(&"HM_RESPAWN_HITMAN");
		precacheString(&"HM_GUARD_KILLED_HITMAN");
		precacheString(&"HM_GUARD_CHOSEN_COMMANDER");
		precacheString(&"HM_GUARD_CHOSEN_HITMAN");
		precacheString(&"HM_RESPAWN_GUARD");
		precacheString(&"HM_HITMAN_KILLEDBY_GUARD");
		precacheString(&"HM_COMMANDER_KILLEDBY_HITMAN");
	
		game["hm_guard"] = ("gfx/hud/hud@headiconguad.tga");
		game["hm_commander"] = ("gfx/hud/hud@headiconcmmd.tga");
		game["hm_hitman"] = ("gfx/hud/hud@headiconagnt.tga");
	
		precacheHeadIcon(game["hm_guard"]);
		precacheHeadIcon(game["hm_commander"]);
		precacheHeadIcon(game["hm_hitman"]);
	
		precacheShader("objpoint_radio");
		precacheShader(game["hm_guard"]);
		precacheShader(game["hm_commander"]);
		precacheShader(game["hm_hitman"]);
	
		precacheStatusIcon(game["hm_guard"]);
		precacheStatusIcon(game["hm_commander"]);
		precacheStatusIcon(game["hm_hitman"]);
//		game["precachedone"] = true;
//	}

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

	for(i = 0; i < spawnpoints.size; i++) spawnpoints[i] placeSpawnpoint();

	allowed[0] = "dm";
	maps\mp\gametypes\_gameobjects::main(allowed);

	if(!isdefined(game["state"])) game["state"] = "playing";

	level.QuickMessageToAll = true;
	level.mapended = false;

	level.hitmans  = 0;
	level.guards = 0;
	level.commander = undefined;
	
	if(getCvar("scr_hm_timelimit") == "")		// Time limit per map
		setCvar("scr_hm_timelimit", "30");
	else if(getCvarFloat("scr_hm_timelimit") > 1440)
		setCvar("scr_hm_timelimit", "1440");
	level.timelimit = getCvarFloat("scr_hm_timelimit");
// La Truffe ->
/*
	setCvar("ui_hm_timelimit", level.timelimit);
	makeCvarServerInfo("ui_hm_timelimit", "30");
*/
	setCvar("ui_timelimit", level.timelimit);
	makeCvarServerInfo("ui_timelimit", "30");
// La Truffe <-

	if(getCvar("scr_hm_scorelimit") == "")		// Score limit per map
		setCvar("scr_hm_scorelimit", "50");
	level.scorelimit = getCvarInt("scr_hm_scorelimit");
// La Truffe ->
/*
	setCvar("ui_hm_scorelimit", level.scorelimit);
	makeCvarServerInfo("ui_hm_scorelimit", "50");
*/
	setCvar("ui_scorelimit", level.scorelimit);
	makeCvarServerInfo("ui_scorelimit", "50");
// La Truffe <-

	// show commander on compass
	if(getCvar("scr_hm_showcommander") == "") 
		setCvar("scr_hm_showcommander", "1");
	level.showcommander = getCvarInt("scr_hm_showcommander");
	setCvar("ui_hm_showcommander", level.showcommander);
	makeCvarServerInfo("ui_hm_showcommander", "1");

	// Seconds between commander updates on compass
	if(getCvar("scr_hm_tposuptime") == "") 
		setCvar("scr_hm_tposuptime", "1");
	level.tposuptime = getCvarInt("scr_hm_tposuptime");
	setCvar("ui_hm_tposuptime", level.tposuptime);
	makeCvarServerInfo("ui_hm_tposuptime", "1");

	if(getCvar("scr_hm_penaltytime") == "")	
		setCvar("scr_hm_penaltytime", "10");	

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

	self.hm_status = "";
	self.hm_lockstatus = false;
	self.hm_nodamage = false;
	self.hm_wasCommander = false;

	level notify("connected", self);

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("J;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");

	if(game["state"] == "intermission")
	{
		spawnIntermission();
		return;
	}

	level endon("intermission");

	scriptMainMenu = game["menu_ingame"];

	if(isdefined(self.pers["team"]) && self.pers["team"] != "spectator")
	{
		self setClientCvar("ui_allow_weaponchange", "1");
		self.sessionteam = "none";

		if(isdefined(self.pers["weapon"]))
			spawnPlayer();
		else
		{
			spawnspectator();

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

		spawnspectator();
	}

	self setClientCvar("g_scriptMainMenu", scriptMainMenu);
	thread menuWeapon();
}

Callback_PlayerDisconnect()
{

	if(!level.splitscreen)
		iprintln(&"MP_DISCONNECTED", self);

	if(isdefined(self.clientid))
		setplayerteamrank(self, self.clientid, 0);

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("Q;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");

	players = getentarray("player", "classname");

	guards = [];
	untappedguards = [];
	newcommander = undefined;

	for(i = 0; i < players.size; i++)
	{
		if(isdefined(players[i]) && isdefined(players[i].hm_status) && players[i].hm_status == "guard")
		{
			guards[guards.size] = players[i];
			if(!players[i].hm_wasCommander) // hasn't been commander
				untappedguards[untappedguards.size] = players[i];
		}
	}

	if(!isdefined(self.hm_status)) 
		return;

	if(self.hm_status == "commander")
	{
		self thread delete_commander_marker(); // remove the blip

		if(untappedguards.size > 0)
		{
			i = randomInt(untappedguards.size);
			newCommander = untappedguards[i];
		}
		else
		{
			if(guards.size > 0)
			{
				i = randomInt(guards.size);
				newCommander = guards[i];
			}
		}

		if(isdefined(newCommander))
		{
			newCommander thread hud_announce(&"HM_GUARD_CHOSEN_COMMANDER", 0);
			newCommander thread newStatus("commander");
		}
	}

	if(self.hm_status == "hitman")
	{
		level.hitmans--;
		if(level.hitmans == 0) // there are no more hitmans
		{
			if(level.guards > 0) // pick a guard to become an hitman
			{
				i = randomInt(guards.size);
				newHitman = guards[i];
				newHitman thread hud_announce(&"HM_GUARD_CHOSEN_HITMAN", 0);
				newHitman thread newStatus("hitman");
			}
		}
	}
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

	// guards and commanders share friendly fire damage
	if((self.hm_status == "guard" || self.hm_status == "commander") && isdefined(eAttacker) && isdefined(eAttacker.hm_status) && (eAttacker.hm_status == "guard" || eAttacker.hm_status == "commander"))
	{
		iDamage = int(iDamage * .5);
		
		// Make sure at least one point of damage is done
		if(iDamage < 1) 
			iDamage = 1;
		reflect = iDamage;	
		if(isdefined(eAttacker) && eAttacker.hm_status == "commander" && reflect > eAttacker.health) 
			reflect = eAttacker.health - 1;	
		if(reflect < 1) 
			reflect = 0;
		eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
	}
	
	if(self.hm_status == "commander" && isdefined(eAttacker) && isdefined(eAttacker.hm_status) && eAttacker.hm_status == "guard" && iDamage > self.health) 
		iDamage = self.health - 1;
	if(iDamage < 1) 
		iDamage = 0;

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
	oldStatus = self.hm_status;
	nextStatus = "";

	if(self.hm_status == "commander") 
		self thread delete_commander_marker();

	penalty = 0;

	if(isPlayer(attacker))
	{
		if(attacker == self) // killed himself
		{
			doKillcam = false;
			
			self.hm_lockstatus = true; // killing yourself keeps your status
	
			attacker.score--;
		}
		else
		{
			attackerNum = attacker getEntityNumber();
			doKillcam = true;

			// if an hitman kills another hitman, he delays that dead hitman's respawn time
			if(self.hm_status == "hitman" && attacker.hm_status == "hitman")
			{
				penalty = getCvarInt("scr_hm_penaltytime");
				self.hm_lockstatus = true;
			}

			// give 2 points to hitman killing commander or commander killing hitman
			if((attacker.hm_status == "commander" && self.hm_status == "hitman") ||  (attacker.hm_status == "hitman" && self.hm_status == "commander"))
			{
				attacker.score+=2;
				attacker checkScoreLimit();
			}

			// give 1 point to hitman killing guard or guard killing hitman
			if((attacker.hm_status == "guard" && self.hm_status == "hitman") ||  (attacker.hm_status == "hitman" && self.hm_status == "guard"))
			{
				attacker.score++;
				attacker checkScoreLimit();
			}

			if(self.hm_status == "hitman" && attacker.hm_status == "guard") // a guard killed an hitman
			{
				self thread hud_announce(&"HM_HITMAN_KILLEDBY_GUARD", 0);
				self thread hud_announce(&"HM_RESPAWN_GUARD", 2);
				// see if the guard should become an hitman
				if(level.hitmans > 1) // more than one hitman, may need to lose one
				{
					if(level.guards + 1 > (level.hitmans-1) * 2) // losing an hitman would produce more than 2 guards per hitman
						attackerNewStatus = "hitman";
					else 
						attackerNewStatus = "guard";
						
				}
				else
				{
					attackerNewStatus = "hitman";
				}
				
				self thread newStatus("guard");

				attacker thread hud_announce(&"HM_GUARD_KILLED_HITMAN", 0);
				if(attackerNewStatus == "hitman")
				{
					attacker thread hud_announce(&"HM_RESPAWN_HITMAN", 2);
					attacker thread newStatus("hitman");
				}
			}

			if(self.hm_status == "hitman" && attacker.hm_status == "commander") // the commander killed an hitman
			{
				self.hm_lockstatus = true;
			}
			
			if(self.hm_status == "commander") // the commander was killed by the hitman
			{
				level.commander = undefined;
				players = getentarray("player", "classname");
				guards = [];
				untappedguards = [];
				for(i = 0; i < players.size; i++)
				{
					if(isdefined(players[i]) && isdefined(players[i].hm_status) && players[i].hm_status == "guard")
					{
						guards[guards.size] = players[i]; // all guards
						if(!players[i].hm_wasCommander)
							untappedguards[untappedguards.size] = players[i]; // guards that haven't been the commander yet
					}
				}

				if(level.guards == 0) // the hitman and commander are alone on the server, exchange them
				{
					attacker thread hud_announce(&"HM_GUARD_CHOSEN_COMMANDER", 0);
					attacker thread newStatus("commander");
					self thread hud_announce(&"HM_GUARD_CHOSEN_HITMAN", 0);
					self thread newStatus("hitman");
				}
				else // there are guards on the server
				{
					if(untappedguards.size > 0)
					{
						j = randomint(untappedguards.size);
						newCommander = untappedguards[j];
					}
					else
					{
						j = randomint(guards.size);
						for(i = 0; i < guards.size; i++)
							guards[i].hm_wasCommander = false;
						newCommander = guards[j];
					}
					if(!isdefined(level.commander)) // in case someone else already got the spot
					{
						newCommander thread hud_announce(&"HM_GUARD_CHOSEN_COMMANDER", 0);
						newCommander thread newStatus("commander");
					}
					self thread hud_announce(&"HM_COMMANDER_KILLEDBY_HITMAN", 0);
					self thread hud_announce(&"HM_RESPAWN_GUARD", 2);
					self thread newStatus("guard"); // the commander is now a guard
				}
			}
		}
		lpattacknum = attacker getEntityNumber();
		lpattackguid = attacker getGuid();
		lpattackname = attacker.name;
		
		attacker notify("update_playerhud_score");
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		doKillcam = false;

		self.score--;
		self.hm_lockstatus = true;
		lpattacknum = -1;
		lpattackguid = "";
		lpattackname = "";

		self notify("update_playerscore_score");
	}

	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

	// Stop thread if map ended on this death
	if(level.mapended)
		return;

	self.switching_teams = undefined;
	self.joining_team = undefined;
	self.leaving_team = undefined;

	body = self cloneplayer(deathAnimDuration);
//	thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"], 5);

	delay = 5 + penalty;	// Delay the player becoming a spectator till after he's done dying
	if(penalty > 0) 
		self thread hud_announce(&"HM_HITMAN_VS_HITMAN", 0);

	wait delay;	// ?? Also required for Callback_PlayerKilled to complete before respawn/killcam can execute

	if(self.hm_status == "commander") // no killcam for the commander if he needs to respawn
		doKillcam = false;

	if(doKillcam && level.killcam) 
	{
		self maps\mp\gametypes\_killcam::killcam(attackerNum, delay, psOffsetTime, true);
		self thread respawn();
	}
	else // if you're stil the commander, you can't wait to respawn
	{
		if(self.hm_status == "commander") 
			self thread spawnPlayer();
		else 
			self thread respawn();
	}
}

// a player's status has changed, inform them
newStatus(status)
{
	if(!isdefined(status))
		status = self.hm_status;
	if(self.hm_status == "guard")
		level.guards--;	
	if(self.hm_status == "hitman") 
		level.hitmans--;

	myIcon = undefined;
	myHud1Text = undefined;
	myHud1Icon = undefined;
	myHud2Text = undefined;
	myHud2Icon = undefined;
	myHud3Text = undefined;
	myHud3Icon = undefined;
	myStatus = undefined;

	switch(status)
	{
		case "guard":
			myIcon = "hm_guard";
			myHud1Text = &"HM_GUARD_STOP_HITMAN";
			myHud1Icon = "hm_hitman";
			myHud2Text = &"HM_DONT_KILL_GUARDS";
			myHud2Icon = "hm_guard";
			myHud3Text = &"HM_GUARD_PROTECT_COMMANDER";
			myHud3Icon = "hm_commander";
			myStatus = &"HM_NEW_GUARD";
			level.guards++;
			break;

		case "commander":
			myIcon = "hm_commander";
			myHud1Text = &"HM_NEW_COMMANDER";
			myHud1Icon = "hm_commander";
			myHud2Text = &"HM_DONT_KILL_GUARDS";
			myHud2Icon = "hm_guard";
			myHud3Text = &"HM_COMMANDER_EVADE_HITMAN";
			myHud3Icon = "hm_hitman";
			myStatus = &"HM_NEW_COMMANDER";
			level.commander = self;
			self.hm_wasCommander = true;
			break;

		case "hitman":
			myIcon = "hm_hitman";
			myHud1Text = &"HM_OTHER_HITMANS";
			myHud1Icon = "hm_hitman";
			myHud2Text = &"HM_AVOID_GUARDS";
			myHud2Icon = "hm_guard";
			myHud3Text = &"HM_HITMAN_KILL_COMMANDER";
			myHud3Icon = "hm_commander";
			myStatus = &"HM_NEW_HITMAN";
			level.hitmans++;
			break;
	}

	respawnNow = undefined;

	if((self.hm_status == "guard" || self.hm_status == "hitman") && status == "commander" && self.sessionstate == "playing") // a player has been chosen to respawn as the commander
	{
		self.hm_status = "commander";
		respawnNow = 1;
	}

	if((self.hm_status == "guard" || self.hm_status == "commander") && status == "hitman" && self.sessionstate == "playing") // a player has been chosen to be an hitman
	{
		self.hm_status = "hitman";
		respawnNow = 1;
	}

	if(isdefined(respawnNow)) // do the forced respawn
	{
		self.hm_lockstatus = true;
		// take away their weapons and mark them as undamageable
		self.hm_nodamage = true;

		wait 2;
		self.sessionstate = "dead"; // hide the player from the world

		self thread clearHud();

		wait 3;
		self thread spawnplayer(); // respawn this player
		return;
	}

	self.hm_status = status;

	if(self.sessionstate == "playing")
	{
		self.hm_lockstatus = false;

		self.statusicon = game[myIcon];
		self.headicon = game[myIcon];

		if(!isdefined(self.statusHUDicon))
		{
			self.statusHUDicon = newClientHudElem(self);				
			self.statusHUDicon.alignX = "center";
			self.statusHUDicon.alignY = "middle";
			self.statusHUDicon.x = 125;
			self.statusHUDicon.y = 400;
		}
		self.statusHUDicon setShader(game[myIcon], 40, 40);

		if(isdefined(self.oldhmst) && self.oldhmst != myIcon)
			self thread explostatus(myIcon);

		if(!isdefined(self.hud1text))
		{
			self.hud1text = newClientHudElem(self);				
			self.hud1text.alignX = "center";
			self.hud1text.alignY = "middle";
			self.hud1text.x = 575;
			self.hud1text.y = 160;
			self.hud1text.alpha = 0.5;
		}
		self.hud1text settext(myHud1Text);			

		if(!isdefined(self.hud1icon))
		{
			self.hud1icon = newClientHudElem(self);				
			self.hud1icon.alignX = "center";
			self.hud1icon.alignY = "middle";
			self.hud1icon.x = 575;
			self.hud1icon.y = 190;
		}
		self.hud1icon setShader(game[myHud1Icon], 50, 50);

		if(!isdefined(self.hud2text))
		{
			self.hud2text = newClientHudElem(self);				
			self.hud2text.alignX = "center";
			self.hud2text.alignY = "middle";
			self.hud2text.x = 575;
			self.hud2text.y = 235;
			self.hud2text.alpha = 0.5;
		}
		self.hud2text settext(myHud2Text);			

		if(!isdefined(self.hud2icon))
		{
			self.hud2icon = newClientHudElem(self);				
			self.hud2icon.alignX = "center";
			self.hud2icon.alignY = "middle";
			self.hud2icon.x = 575;
			self.hud2icon.y = 265;
		}
		self.hud2icon setShader(game[myHud2Icon], 40, 40);

		if(!isdefined(self.hud3text))
		{
			self.hud3text = newClientHudElem(self);				
			self.hud3text.alignX = "center";
			self.hud3text.alignY = "middle";
			self.hud3text.x = 575;
			self.hud3text.y = 300;
			self.hud3text.alpha = 0.5;
		}
		self.hud3text settext(myHud3Text);			

		if(!isdefined(self.hud3icon))
		{
			self.hud3icon = newClientHudElem(self);				
			self.hud3icon.alignX = "center";
			self.hud3icon.alignY = "middle";
			self.hud3icon.x = 575;
			self.hud3icon.y = 330;
		}
		self.hud3icon setShader(game[myHud3Icon], 40, 40);

		self thread hud_announce(myStatus, 0);
		self thread hud_announce(myHud3Text, 2.5);

		self setClientCvar("cg_objectiveText", myHud3Text);

		if(self.hm_status == "commander") 
			self thread make_commander_marker();
		if(self.hm_status == "guard") 
			self thread make_guard_marker();
	}
	else self.hm_lockstatus = true; // lock this status in place for the next spawn

	self thread fadehudinfo();
	self.oldhmst = myIcon;
}

explostatus(myIcon)
{
	if(isdefined(self.statusHUDicon))
	{
		self.statusHUDicon setShader(game[myIcon], 96, 96);
		self.statusHUDicon scaleOverTime(2, 32, 32);
	}
}

fadehudinfo()
{
	self endon("death");
	self endon("respawn");
	
	wait 10;

	if(isdefined(self.hud1text))
	{
		self.hud1text fadeOverTime(2);
		self.hud1text.alpha = 0;
	}

	if(isdefined(self.hud1icon))
	{
		self.hud1icon fadeOverTime(2);
		self.hud1icon.alpha = 0;
	}

	if(isdefined(self.hud2text))
	{
		self.hud2text fadeOverTime(2);
		self.hud2text.alpha = 0;
	}

	if(isdefined(self.hud2icon))
	{
		self.hud2icon fadeOverTime(2);
		self.hud2icon.alpha = 0;
	}

	if(isdefined(self.hud3text))
	{
		self.hud3text fadeOverTime(2);
		self.hud3text.alpha = 0;
	}	

	if(isdefined(self.hud3icon))
	{
		self.hud3icon fadeOverTime(2);
		self.hud3icon.alpha = 0;
	}

	wait 2;

	if(isdefined(self.hud1text)) self.hud1text destroy();
	if(isdefined(self.hud1icon)) self.hud1icon destroy();
	if(isdefined(self.hud2text)) self.hud2text destroy();
	if(isdefined(self.hud2icon)) self.hud2icon destroy();
	if(isdefined(self.hud3text)) self.hud3text destroy();
	if(isdefined(self.hud3icon)) self.hud3icon destroy();
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

	if(!self.hm_lockstatus) // enable auto-selection of role
	{
		nextStatus = "";

		if(level.hitmans == 0) // the first player to spawn is an hitman
		{
			nextStatus = "hitman";
		}
		if(level.hitmans >= 1 && !isdefined(level.commander) && (self.hm_status == "" || self.hm_status == "guard")) // there is an hitman, but no commander, this player is the commander
		{
			nextStatus = "commander";
			level.commander = self;
		}	

		if(level.hitmans > 0 && isdefined(level.commander) && self.hm_status != "commander" && nextStatus != "commander" && nextStatus != "hitman") // this player should be either an hitman or guard
		{
			if(level.guards <= level.hitmans * 2) // there aren't enough guards, should be at least 2 to 1 odds
			{
				if(self.hm_status == "hitman") // is currently an hitman, may have to change
				{
					if((level.guards+1 <= (level.hitmans-1) * 2) && level.hitmans > 1) // one more guard and one less hitman is still good odds
						nextStatus = "guard";
					else
						nextStatus = "hitman";
				}
				else // they're not an hitman, make them a guard
				{
					nextStatus = "guard";
				}
			}
			else // might need another hitman, too many guards
			{
				if(self.hm_status == "") // not set yet, make an hitman
					nextStatus = "hitman";

				if(self.hm_status == "guard") // player is currently a guard
				{
					if((level.guards - 1) <= (level.hitmans+1) * 2) // cannot afford to convert guard to hitman
						nextStatus = "guard";
					else
						nextStatus = "hitman";
				}
			}
		}
	}
	else
	{ 
		nextStatus = self.hm_status; // players status was locked by another function
	}

	self.maxhealth = 100;
	self.health = self.maxhealth;
	
	// setup all the weapons
	self.hm_nodamage = false;
	self newStatus(nextStatus);	

//	waittillframeend;
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
	if(!isdefined(self.pers["weapon"])) return;

	self endon("end_respawn");

	if(getCvarInt("scr_forcerespawn") <= 0)
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

	while((isdefined(self)) && (self useButtonPressed() != true)) wait .05;

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

		if(isdefined(tied) && tied) player setClientCvar("cg_objectiveText", &"MP_THE_GAME_IS_A_TIE");
		else if(isdefined(playername)) player setClientCvar("cg_objectiveText", &"MP_WINS", playername);

		player 	spawnIntermission();
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

	iprintln(&"MP_SCORE_LIMIT_REACHED");

	level thread endMap();
}

updateGametypeCvars()
{
	for(;;)
	{
		timelimit = getcvarfloat("scr_hm_timelimit");
		if(level.timelimit != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_hm_timelimit", "1440");
			}

			level.timelimit = timelimit;
// La Truffe ->
//			setCvar("ui_hm_timelimit", level.timelimit);
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

		scorelimit = getCvarInt("scr_hm_scorelimit");
		if(level.scorelimit != scorelimit)
		{
			level.scorelimit = scorelimit;
// La Truffe ->
//			setCvar("ui_hm_scorelimit", level.scorelimit);
			setCvar("ui_scorelimit", level.scorelimit);
// La Truffe <-

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

hud_announce(message, predelay)
{
	self endon("kill_hud_announce");
	self endon("disconnect");

	if(!isDefined(message)) return;

	if(!isDefined(self.hud_announce))
	{
		self.hud_announce = [];
		self.hudwait = 1;
	}

	if(self.hudwait < 1) self.hudwait = 1;

	self.hudwait++;
	
	wait self.hudwait;

	for(i = 0; i < self.hud_announce.size; i++)
	{
		if(isDefined(self.hud_announce[i]))
		{
			self.hud_announce[i] moveOverTime(0.25);
			self.hud_announce[i].y = self.hud_announce[i].y - 20;
		}
	}

	i = 0;
	while(isDefined(self.hud_announce[i])) i++;

	self.hud_announce[i] = newClientHudElem(self);
	self.hud_announce[i].alignX = "center";
	self.hud_announce[i].alignY = "middle";
	self.hud_announce[i].x = 320;
	self.hud_announce[i].y = 100;
	self.hud_announce[i].alpha = 0;
	self.hud_announce[i].fontscale = 1.5;
	wait 0.25;

	self.hud_announce[i] settext(message);
	self.hud_announce[i] fadeOverTime(0.5);
	self.hud_announce[i].alpha = 1;
	wait 2.5;
	self.hud_announce[i] fadeOverTime(0.5);
	self.hud_announce[i].alpha = 0;
	wait 0.25;

	self.hud_announce[i] destroy();
	self.hudwait--;
}

make_commander_marker()
{
	self endon("commanderblip");
	wait(level.tposuptime);

	while((isPlayer(self)) && (isAlive(self)))
	{
		if(getCvarInt("scr_hm_showcommander"))
		{
			objective_add(1, "current", self.origin, "objpoint_radio");
			objective_icon(1, "objpoint_radio");
			objective_team(1, "none");
			objective_position(1, self.origin);
			lastobjpos = self.origin;
			newobjpos = self.origin;
			lastobjpos = newobjpos;
			newobjpos = (((lastobjpos[0] + self.origin[0]) * 0.5), ((lastobjpos[1] + self.origin[1]) * 0.5), 0);
			objective_position(0, newobjpos);
		}
		wait(level.tposuptime);
		objective_delete(0);
	}
}

delete_commander_marker()
{
	self notify("commanderblip");
	objective_delete(0);
}

make_guard_marker()
{
	if(getCvar("scr_hm_showguard") == "0")
		return;

	self.lastobjpos = self.origin;
	self.newobjpos = self.origin;
}

clearHUD()
{
	if(isdefined(self.hud1text)) self.hud1text destroy();
	if(isdefined(self.hud1icon)) self.hud1icon destroy();
	if(isdefined(self.hud2text)) self.hud2text destroy();
	if(isdefined(self.hud2icon)) self.hud2icon destroy();
	if(isdefined(self.hud3text)) self.hud3text destroy();
	if(isdefined(self.hud3icon)) self.hud3icon destroy();
	if(isdefined(self.statusHUDicon)) self.statusHUDicon destroy();
}