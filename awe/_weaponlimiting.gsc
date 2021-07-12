init()
{
	// Weapon limiting
	level.awe_riflelimit	= awe\_util::cvardef("awe_rifle_limit", 0, 0, 100, "int");
	level.awe_boltriflelimit= awe\_util::cvardef("awe_boltrifle_limit", 0, 0, 100, "int");
	level.awe_semiriflelimit= awe\_util::cvardef("awe_semirifle_limit", 0, 0, 100, "int");
	level.awe_smglimit	= awe\_util::cvardef("awe_smg_limit", 0, 0, 100, "int");
	level.awe_assaultlimit	= awe\_util::cvardef("awe_assault_limit", 0, 0, 100, "int");
	level.awe_sniperlimit	= awe\_util::cvardef("awe_sniper_limit", 0, 0, 100, "int");
	level.awe_shotgunlimit	= awe\_util::cvardef("awe_shotgun_limit", 0, 0, 100, "int");

	// Ammo limiting
	level.awe_ammomin = awe\_util::cvardef("awe_ammo_min",100,0,100,"int");
	level.awe_ammomax = awe\_util::cvardef("awe_ammo_max",100,level.awe_ammomin,100,"int");

	// Unlimted ammo
	level.awe_unlimitedammo 	= awe\_util::cvardef("awe_unlimited_ammo", 0, 0, 2, "int");
	level.awe_unlimitedgrenades 	= awe\_util::cvardef("awe_unlimited_grenades", 0, 0, 1, "int");
	level.awe_unlimitedsmokegrenades=awe\_util::cvardef("awe_unlimited_smokegrenades", 0, 0, 1, "int");

	if(!(level.awe_riflelimit || level.awe_boltriflelimit || level.awe_semiriflelimit || level.awe_smglimit || level.awe_assaultlimit || level.awe_sniperlimit || level.awe_shotgunlimit))
		return;

	// Reset cvars on init
	limitWeapons("allies");
	limitWeapons("axis");

	thread StartThreads();
}

StartThreads()
{
	wait .05;
	level endon("awe_killthreads");

	thread CheckLimitedWeapons();
}

checkLimitedWeapons()
{
	level endon("awe_killthreads");

	for(;;)
	{
		limitWeapons("allies");
		wait 0.1;
		limitWeapons("axis");
		wait 0.1;
	}
}

limitWeapons(team)
{
	if(level.awe_disable) return;

	rifle = 0;
	boltrifle = 0;
	semirifle = 0;
	smg = 0;
	assault = 0;
	sniper = 0;
	shotgun = 0;

	for(i = 0; i < level.awe_allplayers.size; i++)
	{
		if(isdefined(level.awe_allplayers[i]))
		{
			player = level.awe_allplayers[i];
			if( (level.awe_teamplay && team == player.sessionteam) || (!level.awe_teamplay && team == player.pers["team"]) )
			{
				if(player.sessionstate == "playing")
				{
					primary = player getWeaponSlotWeapon("primary");
					primaryb = player getWeaponSlotWeapon("primaryb");
					// Is player using other weapons than his spawnweapon?
					if(isdefined(player.pers["weapon"]) && primary != player.pers["weapon"] && primaryb != player.pers["weapon"])
						spawn = player.pers["weapon"];
					else
						spawn = "none";
					
				}
				else
				{
					primary = "none";
					primaryb = "none";
					if(isdefined(player.pers["weapon"]))
						spawn = player.pers["weapon"];
					else
						spawn = "none";
				}
				if(!isdefined(primary) || primary == "") primary = "none";
				if(!isdefined(primaryb) || primaryb == "") primaryb = "none";
				if(!isdefined(spawn) || spawn == "") spawn = "none";

				if(awe\_util::IsWeaponType("rifle",primary) || awe\_util::IsWeaponType("rifle",primaryb) || awe\_util::IsWeaponType("rifle",spawn))
					rifle ++;
				if(awe\_util::IsWeaponType("boltrifle",primary) || awe\_util::IsWeaponType("boltrifle",primaryb) || awe\_util::IsWeaponType("boltrifle",spawn))
					boltrifle ++;
				if(awe\_util::IsWeaponType("semirifle",primary) || awe\_util::IsWeaponType("semirifle",primaryb) || awe\_util::IsWeaponType("semirifle",spawn))
					semirifle ++;
				if(awe\_util::IsWeaponType("smg",primary) || awe\_util::IsWeaponType("smg",primaryb) || awe\_util::IsWeaponType("smg",spawn))
					smg ++;
				if(awe\_util::IsWeaponType("assault",primary) || awe\_util::IsWeaponType("assault",primaryb) || awe\_util::IsWeaponType("assault",spawn))
					assault ++;
				if(awe\_util::IsWeaponType("sniper",primary) || awe\_util::IsWeaponType("sniper",primaryb) || awe\_util::IsWeaponType("sniper",spawn))
					sniper ++;
				if(awe\_util::IsWeaponType("shotgun",primary) || awe\_util::IsWeaponType("shotgun",primaryb) || awe\_util::IsWeaponType("shotgun",spawn))
					shotgun ++;
			}
		}
	}

	if(level.awe_riflelimit && !(level.awe_boltriflelimit || level.awe_semiriflelimit))
	{
		if(level.awe_riflelimit>rifle)
			enableDisableWeaponType(team, "rifle", 1);
		else
			enableDisableWeaponType(team, "rifle", 0);
	}

	if(level.awe_boltriflelimit)
	{
		if(level.awe_boltriflelimit>boltrifle)
			enableDisableWeaponType(team, "boltrifle", 1);
		else
			enableDisableWeaponType(team, "boltrifle", 0);
	}

	if(level.awe_semiriflelimit)
	{
		if(level.awe_semiriflelimit>semirifle)
			enableDisableWeaponType(team, "semirifle", 1);
		else
			enableDisableWeaponType(team, "semirifle", 0);
	}

	if(level.awe_smglimit)
	{
		if(level.awe_smglimit>smg)
			enableDisableWeaponType(team, "smg", 1);
		else
			enableDisableWeaponType(team, "smg", 0);
	}

	if(level.awe_assaultlimit)
	{
		if(level.awe_assaultlimit>assault)
			enableDisableWeaponType(team, "assault", 1);
		else
			enableDisableWeaponType(team, "assault", 0);
	}

	if(level.awe_sniperlimit)
	{
		if(level.awe_sniperlimit>sniper)
			enableDisableWeaponType(team, "sniper", 1);
		else
			enableDisableWeaponType(team, "sniper", 0);
	}

	if(level.awe_shotgunlimit)
	{
		if(level.awe_shotgunlimit>shotgun)
			enableDisableWeaponType(team, "shotgun", 1);
		else
			enableDisableWeaponType(team, "shotgun", 0);
	}
}

enableDisableWeaponType(team, type, value)
{
	switch(game[team])
	{
		case "american":
			switch(type)
			{
				case "rifle":
					aweSetCvar("scr_allow_m1carbine", value);
					aweSetCvar("scr_allow_m1garand", value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_m1carbine_mp");
						awe\_util::DeletePlacedEntity("weapon_m1garand_mp");
					}
					break;
				case "boltrifle":
					aweSetCvar("scr_allow_m1carbine", value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_m1carbine_mp");
					}
					break;
				case "semirifle":
					aweSetCvar("scr_allow_m1garand", value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_m1garand_mp");
					}
					break;
				case "smg":
					aweSetCvar("scr_allow_greasegun",value);
					aweSetCvar("scr_allow_thompson",value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_greasegun_mp");
						awe\_util::DeletePlacedEntity("weapon_thompson_mp");
					}
					break;
				case "assault":
					aweSetCvar("scr_allow_bar",value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_bar_mp");
					}
					break;
				case "sniper":
					aweSetCvar("scr_allow_springfield",value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_springfield_mp");
					}
					break;
				case "shotgun":
					aweSetCvar("scr_allow_shotgun_allies",value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_shotgun_mp");
					}
					break;
				default:
					break;
			}
			break;

		case "british":
			switch(type)
			{
				case "rifle":
					aweSetCvar("scr_allow_enfield", value);
					aweSetCvar("scr_allow_m1garand", value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_enfield_mp");
						awe\_util::DeletePlacedEntity("weapon_m1garand_mp");
					}
					break;
				case "boltrifle":
					aweSetCvar("scr_allow_enfield", value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_enfield_mp");
					}
					break;
				case "semirifle":
					aweSetCvar("scr_allow_m1garand", value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_m1garand_mp");
					}
					break;
				case "smg":
					aweSetCvar("scr_allow_sten",value);
					aweSetCvar("scr_allow_thompson",value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_sten_mp");
						awe\_util::DeletePlacedEntity("weapon_thompson_mp");
					}
					break;
				case "assault":
					aweSetCvar("scr_allow_bren",value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_bren_mp");
					}
					break;
				case "sniper":
					aweSetCvar("scr_allow_enfieldsniper",value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("enfield_scope_mp");
					}
					break;
				case "shotgun":
					aweSetCvar("scr_allow_shotgun_allies",value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_shotgun_mp");
					}
					break;
				default:
					break;
			}
			break;

		case "russian":
			switch(type)
			{
				case "rifle":
					aweSetCvar("scr_allow_nagant", value);
					aweSetCvar("scr_allow_svt40", value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_mosin_nagant_mp");
						awe\_util::DeletePlacedEntity("weapon_svt40_mp");
					}
					break;
				case "boltrifle":
					aweSetCvar("scr_allow_nagant", value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_mosin_nagant_mp");
					}
					break;
				case "semirifle":
					aweSetCvar("scr_allow_svt40", value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_svt40_mp");
					}
					break;
				case "smg":
					aweSetCvar("scr_allow_pps42",value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_pps42_mp");
					}
					break;
				case "assault":
					aweSetCvar("scr_allow_ppsh",value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_ppsh_mp");
					}
					break;
				case "sniper":
					aweSetCvar("scr_allow_nagantsniper",value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_mosin_nagant_sniper_mp");
					}
					break;
				case "shotgun":
					aweSetCvar("scr_allow_shotgun_allies",value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_shotgun_mp");
					}
					break;
				default:
					break;
			}
			break;

		default:
			switch(type)
			{
				case "rifle":
					aweSetCvar("scr_allow_kar98k", value);
					aweSetCvar("scr_allow_g43", value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_kar98k_mp");
						awe\_util::DeletePlacedEntity("weapon_g43_mp");
					}
					break;
				case "boltrifle":
					aweSetCvar("scr_allow_kar98k", value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_kar98k_mp");
					}
					break;
				case "semirifle":
					aweSetCvar("scr_allow_g43", value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_g43_mp");
					}
					break;
				case "smg":
					aweSetCvar("scr_allow_mp40",value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_mp40_mp");
					}
					break;
				case "assault":
					aweSetCvar("scr_allow_mp44",value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_mp44_mp");
					}
					break;
				case "sniper":
					aweSetCvar("scr_allow_kar98ksniper",value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_kar98k_sniper_mp");
					}
					break;
				case "shotgun":
					aweSetCvar("scr_allow_shotgun_axis",value);
					if(!value)
					{
						awe\_util::DeletePlacedEntity("weapon_shotgun_mp");
					}
					break;
				default:
					break;
			}
			break;
	}
}

aweSetCvar(cvar, value)
{
	if(getcvarint(cvar) != value) setcvar(cvar,value);
}

ammoLimiting()
{
	self limitAmmo("primary");
	self limitAmmo("primaryb");

/*	// Set weapon based grenade count
	if(!isdefined(level.awe_classbased))
	{
		if(level.awe_grenadecount)
			grenadecount = level.awe_grenadecount;
		else
		{
			if(isdefined(self.awe_grenadeforced))
				grenadecount = maps\mp\gametypes\_teams::getWeaponBasedGrenadeCount(self getWeaponSlotWeapon("primary"));
			else
			{
				grenadecount = self getWeaponSlotClipAmmo("grenade");
			}
		}
	}
	else
	{
		grenadecount = self getWeaponSlotClipAmmo("grenade");
	}

	// Randomize grenade count?
	if(grenadecount && level.awe_grenadecountrandom)
	{
		if(level.awe_grenadecountrandom == 1)
			grenadecount = randomInt(grenadecount) + 1;
		if(level.awe_grenadecountrandom == 2)
			grenadecount = randomInt(grenadecount + 1);
	}

	// If no grenades, remove weapon
	if(!grenadecount)
		self setWeaponSlotWeapon("grenade", "none");
	else
		self setWeaponSlotClipAmmo("grenade", grenadecount);

	// UO?
	if(!isdefined(level.awe_uo))
		return;

	// Set weapon based smokegrenade count
	if(!isdefined(level.awe_classbased))
	{
		if(level.awe_smokegrenadecount)
			smokegrenadecount = level.awe_smokegrenadecount;
		else
		{
			if(isdefined(self.awe_smokegrenadeforced))
				smokegrenadecount = maps\mp\gametypes\_awe_uncommon::aweGetWeaponBasedSmokeGrenadeCount(self getWeaponSlotWeapon("primary"));
			else
			{
				smokegrenadecount = self getWeaponSlotClipAmmo("smokegrenade");
			}
		}
	}
	else
	{
		smokegrenadecount = self getWeaponSlotClipAmmo("smokegrenade");
	}

	// Randomize smokegrenade count?
	if(smokegrenadecount && level.awe_smokegrenadecountrandom)
	{
		if(level.awe_smokegrenadecountrandom == 1)
			smokegrenadecount = randomInt(smokegrenadecount) + 1;
		if(level.awe_smokegrenadecountrandom == 2)
			smokegrenadecount = randomInt(smokegrenadecount + 1);
	}

	// If no smokegrenades, remove weapon
	if(!smokegrenadecount)
		self setWeaponSlotWeapon("smokegrenade", "none");
	else
	{
		if(self getWeaponSlotWeapon("smokegrenade") == "none")
			self setWeaponSlotWeapon("smokegrenade", "smokegrenade_mp");
		self setWeaponSlotClipAmmo("smokegrenade", smokegrenadecount);
	}

	// Give satchel
	if(level.awe_satchelcount)
	{
		if(self getWeaponSlotWeapon("satchel") == "none")
			self setWeaponSlotWeapon("satchel", "satchelcharge_mp");
		self setWeaponSlotClipAmmo("satchel", level.awe_satchelcount);
	}*/
}

limitAmmo(slot)
{
	if(level.awe_ammomin == 100)
		return;

	sWeapon = self getWeaponSlotWeapon(slot);
	if(sWeapon == "panzerfaust_mp" || sWeapon == "" || sWeapon == "none")
		return;

	if(!level.awe_ammomax)
		ammopc = 0;
	else if(level.awe_ammomin == level.awe_ammomax)
		ammopc = level.awe_ammomin;
	else
		ammopc = level.awe_ammomin + randomInt(level.awe_ammomax - level.awe_ammomin + 1);

	iAmmo = self getWeaponSlotAmmo(slot) + self getWeaponSlotClipAmmo(slot);
	iAmmo = int(iAmmo * ammopc*0.01 + 0.5);
	
	// If no ammo, remove weapon
	if(!iAmmo)
	{
		self takeWeapon(sWeapon);
		self setWeaponSlotWeapon(slot, "none");
	}
	else
	{
		self setWeaponSlotClipAmmo(slot,iAmmo);
		iAmmo = iAmmo - self getWeaponSlotClipAmmo(slot);
		if(iAmmo < 0) iAmmo = 0;	// this should never happen
		self setWeaponSlotAmmo(slot, iAmmo);
	}
}
