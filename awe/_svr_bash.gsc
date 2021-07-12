// Modified by La Truffe

////////////////////////////////////////////////////////////////////////////////////
//      Bash-Mode from Number7  Questions/comments?  Visit: www.aigaming.net      //
////////////////////////////////////////////////////////////////////////////////////

init()
{
	thread chkBashMode();
}

chkBashMode()
{
	level endon("killModThread");

	for (;;)
	{
		wait 3;

		_b = awe\_util::cvardef("awe_bash_mode", 0, 0, 1, "int");

		if (_b)
		{
			if (!isDefined(game["bashModeOn"]))
			{
				_m = awe\_util::cvardef("awe_bash_on_msg", "", "", "", "string");
				if (_m != "")	  iprintlnbold(_m);
			}
			setBashMode(true);
		}
		else
		{
			if (isDefined(game["bashModeOn"]))
			{
				_m = awe\_util::cvardef("awe_bash_off_msg", "", "", "", "string");
				if (_m != "")	  iprintlnbold(_m);

				setBashMode(false);
			}
		}
	}
}

setBashMode(enable)
{
	level endon("killModThread");

	checkAweAmmo(enable);	  // for awe..

	players = getentarray("player", "classname");

	for (i = 0; i<players.size; i++)
	{
		_p = players[i];

		if (enable)
		{
			game["bashModeOn"] = true;

			if (_p getWeaponSlotWeapon("primary") != "none")
			{
				//iprintln("primary is: " + _p getWeaponSlotWeapon("primary"));
				_p setWeaponSlotAmmo("primary", 0);
				_p setWeaponSlotClipAmmo("primary", 0);
			}
			if (_p getWeaponSlotWeapon("primaryb") != "none")
			{
				//iprintln("primaryb is: " + _p getWeaponSlotWeapon("primaryb"));
				_p setWeaponSlotAmmo("primaryb", 0);
				_p setWeaponSlotClipAmmo("primaryb", 0);
			}

			_p takeWeapon("frag_grenade_american_mp");
			_p takeWeapon("frag_grenade_british_mp");
			_p takeWeapon("frag_grenade_russian_mp");
			_p takeWeapon("frag_grenade_german_mp");
			_p takeWeapon("smoke_grenade_american_mp");
			_p takeWeapon("smoke_grenade_british_mp");
			_p takeWeapon("smoke_grenade_russian_mp");
			_p takeWeapon("smoke_grenade_german_mp");
		}
		else
		{
			game["bashModeOn"] = undefined;

			_w = _p getWeaponSlotWeapon("primary");
			if (_w != "none")
			{
				//iprintln("primary is: " + _w);
				_p setweaponslotclipammo("primary", awe\_svr_utils::getFullClipAmmo(_w));
				_p giveMaxAmmo(_p getWeaponSlotWeapon("primary"));
			}

			_w = _p getWeaponSlotWeapon("primaryb");
			if (_w != "none")
			{
				//iprintln("primaryb is: " + _w);
				_p setweaponslotclipammo("primaryb", awe\_svr_utils::getFullClipAmmo(_w));
				_p giveMaxAmmo(_p getWeaponSlotWeapon("primaryb"));
			}

			_p maps\mp\gametypes\_weapons::giveGrenades();

			_p awe\_weaponlimiting::ammoLimiting();	// for awe..
		}
	}
}

checkAweAmmo(enable)
{
	if (enable)
	{
		level.awe_unlimitedammo			= 0;
		level.awe_unlimitedgrenades		= 0;
		level.awe_unlimitedsmokegrenades	= 0;
		return;
	}

	level.awe_unlimitedammo			= awe\_util::cvardef("awe_unlimited_ammo", 0, 0, 2, "int");
	level.awe_unlimitedgrenades		= awe\_util::cvardef("awe_unlimited_grenades", 0, 0, 1, "int");
	level.awe_unlimitedsmokegrenades	= awe\_util::cvardef("awe_unlimited_smokegrenades", 0, 0, 1, "int");
}
