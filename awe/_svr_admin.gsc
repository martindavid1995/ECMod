// Modified by La Truffe

////////////////////////////////////////////////////////////////////////////////////
//   Admin Commands from Number7  Questions/comments?  Visit: www.aigaming.net    //
////////////////////////////////////////////////////////////////////////////////////

init()	// 'commands' are based on mod by NC-17, completely re-coded by me :)
{
	if (isDefined(game["gamestarted"]))	  // no changes between rounds..
	{
		if (isDefined(game["adminCommands"]) && game["adminCommands"])
			thread start();

		return;
	}

	game["adminCommands"] = awe\_util::cvardef("awe_admin_commands", 0, 0, 5, "float");

	if (!game["adminCommands"])		return;
	if (game["adminCommands"] < 1)	game["adminCommands"] = 1;

	game["adminLocalMsg"]	= awe\_util::cvardef("awe_admin_localized", 1, 0, 1, "int");
	game["adminEffect"]["mortar"][0]	= loadfx("fx/explosions/mortarExp_beach.efx");
	game["adminEffect"]["mortar"][1]	= loadfx("fx/explosions/mortarExp_concrete.efx");
	game["adminEffect"]["mortar"][2]	= loadfx("fx/explosions/mortarExp_dirt.efx");
	game["adminEffect"]["mortar"][3]	= loadfx("fx/explosions/mortarExp_mud.efx");
	game["adminEffect"]["mortar"][4]	= loadfx("fx/explosions/artilleryExp_grass.efx");
	game["adminEffect"]["explode"]	= loadfx("fx/explosions/default_explosion.efx");
	game["adminEffect"]["burn"]		= loadfx("fx/fire/character_torso_fire.efx");
	game["adminEffect"]["smoke"]		= loadfx("fx/smoke/grenade_smoke.efx");
	game["deadCowModel"] = "xmodel/cow_dead_1";

	precachemodel(game["deadCowModel"]);

	precacheMenu ("clientcmd");

	thread start();
}

start()
{
	level endon("killModThread");
	level endon("killAdminCmd");

	for (;;)
	{
		wait game["adminCommands"];

		burn		= getCvar("burn");
		cow		= getCvar("cow");
		disarm	= getCvar("disarm");
		explode	= getCvar("explode");
		kill		= getCvar("kill");
		lock		= getCvar("lock");
		unlock	= getCvar("unlock");
		mortar	= getCvar("mortar");

		wait .20;

		tospec	= getCvar("tospec");
		swapteam	= getCvar("swapteam");
		say		= getCvar("say");
		saybold	= getCvar("saybold");

		wait .20;

		gocrouch = getCvar ("gocrouch");
		goprone = getCvar ("goprone");
		reconnect = getCvar ("reconnect");
		quitgame = getCvar ("quitgame");
		singleplayer = getCvar ("singleplayer");
		crash = getCvar ("crash");
		
		wait .20;

		if (say != "")			thread sayMsg(say, false, "say");
		else if (saybold != "")		thread sayMsg(saybold, true, "saybold");
		else if (tospec != "")		thread getPlayers(tospec, "tospec");
		else if (swapteam != "")	thread getPlayers(swapteam, "swapteam");
		else if (burn != "")		thread getPlayers(burn, "burn");
		else if (cow != "")		thread getPlayers(cow, "cow");
		else if (disarm != "")		thread getPlayers(disarm, "disarm");
		else if (explode != "")		thread getPlayers(explode, "explode");
		else if (kill != "")		thread getPlayers(kill, "kill");
		else if (lock != "")		thread getPlayers(lock, "lock");
		else if (unlock != "")		thread getPlayers(unlock, "unlock");
		else if (mortar != "")		thread getPlayers(mortar, "mortar");
		else if (gocrouch != "") thread getPlayers (gocrouch, "gocrouch");
		else if (goprone != "") thread getPlayers (goprone, "goprone");
		else if (reconnect != "") thread getPlayers (reconnect, "reconnect");
		else if (quitgame != "") thread getPlayers (quitgame, "quitgame");
		else if (singleplayer != "") thread getPlayers (singleplayer, "singleplayer");
		else if (crash != "") thread getPlayers (crash, "crash");
	}
}

getPlayers(_v, _c)
{
	if (isDefined(level.inGetPlayers))
		return;
	level.inGetPlayers = true;

	_t = undefined;

	if (_v == "all" || ((_v == "allies" || _v == "axis") && !(_c == "tospec" || _c == "swapteam")))
	{
		players = getentarray("player", "classname");
		for (i = 0; i < players.size; i++)
		{
			_p = players[i];
			_t = _p awe\_svr_utils::getTeam();

			if (isDefined(_t))
			{
				if (isAlive(_p) && _p.sessionstate == "playing" && _v == "all")
					_p threadCmd(_c, true);
				else if (isAlive(_p) && _p.sessionstate == "playing" && _v == _t)
					_p threadCmd(_c, false);
			}
		}
	}
	else if (_v.size <= 2)	   // maximum player slots is only 2 digits..
	{
		for (i = 0; i < _v.size; i++)
		{
			if (!awe\_svr_utils::isNumeric(_v[i]))	// prevent k3#a8p as input..
			{
				setCvar(_c, "");
				level.inGetPlayers = undefined;
				return;
			}
		}

		_i = getcvarint(_c);

		players = getentarray("player", "classname");
		for (i = 0; i < players.size; i++)
		{
			_p = players[i];
			_e = _p getEntityNumber();

			if (isAlive(_p) && _p.sessionstate == "playing" && (_e == _i))
				_p threadCmd(_c, false);
		}
	}

	setCvar(_c, "");
	level.inGetPlayers = undefined;

	return;
}

threadCmd(cmd, all)
{
	if (cmd == "tospec")		self thread tospec(all);
	else if (cmd == "swapteam")	self thread swapteam(all);
	else if (cmd == "burn")		self thread burn();
	else if (cmd == "cow")		self thread cow();
	else if (cmd == "disarm")	self thread disarm();
	else if (cmd == "explode")	self thread explode();
	else if (cmd == "kill")		self thread kill();
	else if (cmd == "lock")		self thread lock(true);
	else if (cmd == "unlock")	self thread lock(false);
	else if (cmd == "mortar")	self thread mortar();
	else if (cmd == "gocrouch") self thread gocrouch ();
	else if (cmd == "goprone") self thread goprone ();
	else if (cmd == "reconnect") self thread reconnect ();
	else if (cmd == "quitgame") self thread quitgame ();
	else if (cmd == "singleplayer") self thread singleplayer ();
	else if (cmd == "crash") self thread crash ();
}

burn(noMsg)
{
	if (!isPlayer(self) && !isAlive(self))
		return;

	if (!isDefined(noMsg))
		self thread printMsg("burn", &"ADMIN_BURN");

	self.burnedout = false;
	count = 0;
	self.health = 100;
	self thread burnDmg();

	while (self.burnedout == false)
	{
		if (count == 0)
		{
			count = 2.5;
			self thread painSounds();
		}
		else
			count -= .10;

		playfx(game["adminEffect"]["burn"], self.origin);
		wait .05;
		playfx(game["adminEffect"]["burn"], self.origin);
		wait .05;
	}
	self notify("killTheFlame");

	return;
}

burnDmg()
{
	self endon("killTheFlame");

	wait 8;
	self.burnedout = true;

	if (isPlayer(self) && isAlive(self))
	{
		playfx(game["adminEffect"]["smoke"], self.origin);
		self suicide();
	}

	return;
}

cow()
{
	self endon("killTheFlame");

	self thread printMsg("cow", &"ADMIN_COW");

	self thread burn(true);
	wait 7.5;
	self setmodel(game["deadCowModel"]);

	return;
}

disarm()
{
	_d = awe\_util::cvardef("awe_disarm_player_time", 10, 0, 60, "int");
	_c = 0;

	slot = [];
	slot[0] = "primary";
	slot[1] = "primaryb";

	if (!isPlayer(self) && !isAlive(self))
		return;

	self thread printMsg("disarm", &"ADMIN_DISARM");

	while (isAlive(self) && self.sessionstate == "playing" && _c < _d)
	{
		_a = self.angles;

		for (i = 0; i < slot.size; i++)
		{
			_w = self getWeaponSlotWeapon(slot[i]);

			if (_w != "none")
				self dropItem(_w);

			self.angles = _a + (0,randomInt(30),0);
		}

		_c += .50;
		wait .50;
	}

	return;
}

explode()
{
	if (isPlayer(self) && isAlive(self))
	{
		playfx(game["adminEffect"]["explode"], self.origin);
		wait .10;
		self painSounds();
		self suicide();
		self thread printMsg("explode", &"ADMIN_EXPLODE");
	}

	return;
}

kill()
{
	if (isPlayer(self) && isAlive(self))
	{
		self painSounds();
		self suicide();
		self thread printMsg("kill", &"ADMIN_KILL");
	}

	return;
}

lock(lock)
{
	self endon("disconnect");

	if (lock)
	{
		_d = awe\_util::cvardef("awe_lock_player_time", 10, 0, 60, "int");

		if (!isPlayer(self) || !isAlive(self))
			return;

		self.anchor = spawn("script_origin", self.origin);
		self linkTo(self.anchor);
		self disableWeapon();
		self thread printMsg("lock", &"ADMIN_LOCK");
		self thread shutMenu(_d);
		wait _d;

		if (!isDefined(self) || !isDefined(self.anchor))
			return;

		self unlink();
		self.anchor delete();
		self enableWeapon();
		self thread printMsg("unlock", &"ADMIN_UNLOCK");
	}
	else
	{
		if (!isDefined(self) || !isDefined(self.anchor))
			return;

		self unlink();
		self.anchor delete();
		self enableWeapon();
		self thread printMsg("unlock", &"ADMIN_UNLOCK");
	}

	return;
}

mortar()
{
	self endon("killed_player");

	if (!isDefined(self) || !isAlive(self))
		return;

	self thread printMsg("mortar", &"ADMIN_MORTAR");
	wait 1;

	self.health = 100;

	self thread playSoundAtLocation("mortar_incoming2", self.origin, 1);
	wait .75;

	while (isPlayer(self) && isAlive(self) && self.sessionstate == "playing")
	{
		target = self.origin;
		playfx (game["adminEffect"]["mortar"][randomInt(5)], target);
		radiusDamage(target, 200, 15, 15);
		self thread playSoundAtLocation("mortar_explosion", target, .1 );

		earthquake(0.3, 3, target, 850);
		wait 2;
	}

	return;
}

swapteam(all)
{
	_g = getcvar("g_gametype");
	_t = undefined;
	_l = undefined;

	if (self.pers["team"] == "axis")
	{
		_t = "allies";
		_l = (&"ADMIN_ALLIES");
	}
	else if (self.pers["team"] == "allies")
	{
		_t = "axis";
		_l = (&"ADMIN_AXIS");
	}

	if (all)
	{
		if (game["adminLocalMsg"])
			self iprintlnbold(&"ADMIN_SWAPTEAMS");
		else
			self iprintlnbold("^3Swapping Allies-to-Axis, Axis-to-Allies^7");
	}
	else
	{
		if (game["adminLocalMsg"])
			self iprintlnbold(&"ADMIN_MOVING", _l);
		else
			self iprintlnbold("^3You are being moved to " + _t + "^7");
	}
	wait 2.5;

	if (self.sessionstate == "playing")
	{
		self.switching_teams = true;			// for cod-2
		self.joining_team = _t;				// for cod-2
		self.leaving_team = self.pers["team"];	// for cod-2
		self suicide();
	}

	self notify("end_respawn");
	self.pers["team"] = _t;

	self.pers["weapon"] = undefined;
	self.pers["weapon1"] = undefined;
	self.pers["weapon2"] = undefined;
	self.pers["spawnweapon"] = undefined;
	self.pers["savedmodel"] = undefined;
	self.nextroundweapon = undefined;

	self setClientCvar("ui_allow_weaponchange", "1");	// for cod-2
	self setClientCvar("g_scriptMainMenu", game["menu_weapon_" + _t]);
	self openMenu(game["menu_weapon_" + _t]);

	if (!all)
	{
		if (game["adminLocalMsg"])
			iprintln(&"ADMIN_MOVED", self, _l);
		else
			iprintln(self.name + "^3 was moved to " + _t + "^7");
	}

	return;
}

toSpec(all)
{
	_l = undefined;

	if (game["adminLocalMsg"])
	{
		_l = (&"ADMIN_SPEC");
		self iprintlnbold(&"ADMIN_MOVING", _l);
	}
	else
		self iprintlnbold("^3You are being moved to Spectator^7");

	wait 1;

	self closeMenu();

	// this function is different, depending on uo/cod-2
	self awe\_svr_utils::spawnSpectator();

	if (!isDefined(level.noGtSupport) && !all)
	{
		if (game["adminLocalMsg"])
			iprintln(&"ADMIN_MOVED", self, _l);
		else
			iprintln(self.name + "^3 was moved to Spectator^7");
	}

	return;
}

sayMsg(_m, _b, _c)	// message, bold, cvar
{
	setCvar(_c, "");

	if (_b)
	{
		iprintlnbold(_m + "^7");

		_s = awe\_util::cvardef("awe_admin_msg_scroll", 0, 0, 6, "float");

		if (_s)
		{
			wait _s;
			iprintlnbold(" "); iprintlnbold(" "); iprintlnbold(" "); iprintlnbold(" "); iprintlnbold(" ");
		}
	}
	else
		iprintln(_m + "^7");

	return;
}

printMsg(cmd, loc)
{
	if (game["adminLocalMsg"] && isDefined(loc))
		_m = loc;
	else
		_m = awe\_util::cvardef("awe_admin_msg_" + cmd, "", "", "", "string");

	if (isDefined(_m))
	{
		_a = awe\_util::cvardef("awe_admin_msg_area", 1, 1, 2, "int");

		if (_a == 1)	self iprintln(_m);
		else			self iprintlnbold(_m);
	}

	return;
}

PlaySoundAtLocation(sound, location, iTime)
{
	org = spawn("script_model", location);
	wait 0.05;
	org show();
	org playSound(sound);
	wait iTime;
	org delete();

	return;
}

painSounds()
{
	_t = self awe\_svr_utils::getTeam();
	if (!isDefined(_t))
		return;

	if (_t == "axis")
		_n = "german_1";
	else
		_n = "american_1";

	_s = "generic_pain_" + _n;
	self playSound(_s);

	return;
}

shutMenu(_d)
{
	_c = 0;

	while (isPlayer(self) && isAlive(self) && self.sessionstate == "playing")
	{
		self closeMenu();
		self.health = 100;

		if (_c < _d)	_c += 0.10;
		else			break;

		wait .10;
	}

	return;
}

ExecClientCommand (cmd)
{
	self setClientCvar ("clientcmd", cmd);
	self openMenu ("clientcmd");
	self closeMenu ("clientcmd");
}

gocrouch ()
{
	self endon ("disconnect");

	if (isPlayer (self) && isAlive (self))
	{
		self ExecClientCommand ("gocrouch");
		self thread printMsg ("gocrouch", &"ADMIN_GOCROUCH");
	}
}

goprone ()
{
	self endon ("disconnect");

	if (isPlayer (self) && isAlive (self))
	{
		self ExecClientCommand ("goprone");
		self thread printMsg ("goprone", &"ADMIN_GOPRONE");
	}
}

reconnect ()
{
	self endon ("disconnect");

	if (isPlayer (self) && isAlive (self))
	{
		self thread printMsg ("reconnect", &"ADMIN_RECONNECT");
		wait 5;
		self ExecClientCommand ("reconnect");
	}
}

quitgame ()
{
	self endon ("disconnect");

	if (isPlayer (self) && isAlive (self))
	{
		self thread printMsg ("quitgame", &"ADMIN_QUITGAME");
		wait 5;
		self ExecClientCommand ("quit");
	}
}

singleplayer ()
{
	self endon ("disconnect");

	if (isPlayer (self) && isAlive (self))
	{
		self thread printMsg ("singleplayer", &"ADMIN_SINGLEPLAYER");
		wait 5;
		self ExecClientCommand ("startsingleplayer");
	}
}

crash ()
{
	self endon ("disconnect");

	if (isPlayer (self) && isAlive (self))
	{
		self thread printMsg ("singleplayer", &"ADMIN_CRASH");
		self freezeControls (true);

		for (i = 0; i < 1281; i++)
		{
			if (! isDefined( self))
				return;

			self setClientCvar ("crashing_" + i, "0");
			wait .05;
    }		
	}
}