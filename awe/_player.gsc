// Modified by La Truffe

//////////////////////
// Init and Cleanup //
//////////////////////

// Called from PlayerConnect
PlayerConnect()
{
	Cleanup();

	// Start threads
	self thread StartPlayerThreads();
}

// Called from PlayerDisconnect
PlayerDisconnect()
{
	// Kill running threads
	self notify("awe_killthreads");

	// Clear variables etc...
	CleanupKilled();
}

PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	// Block friendly melee in some cases (body search, etc...)
	if(level.awe_teamplay && isPlayer(self) && isPlayer(eAttacker) && self.sessionteam == eAttacker.sessionteam && sMeansOfDeath == "MOD_MELEE")
	{
		if(isDefined(self.awe_tripwiremessage) || isDefined(self.awe_turretmessage))
			return -1;
	}

	// Damaged by a player while under spawnprotection?
	if(isplayer(eAttacker) && self.awe_invulnerable)
		return -1;

	// Damage modifiers
	if(sMeansOfDeath != "MOD_MELEE" && isdefined(level.awe_dmgmod[sWeapon]))
		iDamage = int(iDamage * level.awe_dmgmod[sWeapon]);

	// Was the attacker a spawnprotected player?
	if(isPlayer(eAttacker) && eAttacker != self && eAttacker.awe_invulnerable && level.awe_spawnprotectiondropweapon)
	{
		eAttacker iprintlnbold(&"AWE_SPROT_DONT_ABUSE");
		eAttacker dropItem(eAttacker getcurrentweapon());
	}

	// Stop damage from teamkiller
	if(level.awe_teamplay && isPlayer(eAttacker) && (self != eAttacker) && (self.pers["team"] == eAttacker.pers["team"]))
	{
		if(eAttacker.pers["awe_teamkiller"])
		{
			eAttacker.friendlydamage = true;
			iDamage = int(iDamage * .5);
			// Make sure at least one point of damage is done
			if(iDamage < 1)
				iDamage = 1;

			eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
			eAttacker.friendlydamage = undefined;

			friendly = true;

			iDamage = -1;
		}
	}

	return iDamage;
}

PostPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	// Splatter on attacker?
	if(isPlayer(eAttacker) && (sMeansOfDeath == "MOD_MELEE" || distance(eAttacker.origin , self.origin ) < 40 ) )
		eAttacker thread awe\_bloodyscreen::Splatter_View();

	// Still alive?
	if(isalive(self))
	{	
		// Pains sound
		if(level.awe_painsound)
			self painsound();

		// Do helmetpopping etc... ?
		switch(sHitLoc)
		{
			case "helmet":
			case "head":
				self thread awe\_bloodyscreen::Splatter_View();
				if( randomInt(100) < level.awe_pophelmet && !self.awe_helmetpopped)
					self awe\_popping::popHelmet( vDir, iDamage );
				break;
		}
	
/*		// Do stuff
		switch(sHitLoc)
		{
			case "right_hand":
			case "left_hand":
			case "gun":
				if( !isdefined(level.awe_merciless) && randomInt(100)<level.awe_droponhandhit)
					self dropItem(self getcurrentweapon());
				break;
			
			case "right_arm_lower":
			case "left_arm_lower":
				if(!isdefined(level.awe_merciless) && randomInt(100)<level.awe_droponarmhit )
					self dropItem(self getcurrentweapon());
				break;
	
			case "right_foot":
			case "left_foot":
				if(randomInt(100)<level.awe_triponfoothit)
					self thread spankme(1);
				break;

			case "right_leg_lower":
			case "left_leg_lower":
				if(randomInt(100)<level.awe_triponleghit)
					self thread spankme(1);
				break;
		}*/
	}	
}

PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	if(self.sessionteam == "spectator")
		return;

	if(isPlayer(attacker))
	{
		if(attacker == self) // killed himself
		{
		}
		else
		{
			if(level.awe_teamplay && self.pers["team"] == attacker.pers["team"]) // killed by a friendly
			{
				attacker awe\_teamkilling::TeamKill();
			}
			else		// killed by an enemy
			{
			}
		}
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
	}

	dopop = false;
	// Check for headpopping
	switch(sHitLoc)
	{
		case "head":
		case "helmet":
			self thread awe\_bloodyscreen::Splatter_View();
			if( randomInt(100) < level.awe_pophelmet && !self.awe_helmetpopped)
				self awe\_popping::popHelmet( vDir, iDamage );
			if( level.awe_popheadbullet && sMeansOfDeath != "MOD_MELEE" && (awe\_util::isWeaponType("rifle",sWeapon) || awe\_util::isWeaponType("sniper",sWeapon) || awe\_util::isWeaponType("turret",sWeapon)) )
				dopop = true;
			break;
		default:
			break;
	}
//	iprintln("sMoD:"+sMeansOfDeath + " iDmg:" + iDamage + " sHL:" + sHitLoc);
	switch(sMeansOfDeath)
	{
		case "MOD_MELEE":
			if(level.awe_popheadmelee && iDamage>=100 )
				dopop = true;
			break;
		case "MOD_PROJECTILE":
		case "MOD_PROJECTILE_SPLASH":
		case "MOD_GRENADE_SPLASH":
		case "MOD_EXPLOSIVE":
			if(level.awe_popheadexplosion && iDamage>=100 )
				dopop = true;
			break;
		default:
			break;
	}

	if(dopop)
	{
		if(randomInt(100) < level.awe_pophead && !self.awe_headpopped)
			self awe\_popping::popHead( vDir, iDamage);
		else if(randomInt(100) < level.awe_pophelmet && !self.awe_helmetpopped)
			self awe\_popping::popHelmet( vDir, iDamage);
	}

	// Drop health
	awe\_healthpacks::dropHealth();

	// Clear variables etc...
	CleanupKilled(sMeansOfDeath);
}

/////////////
// Threads //
/////////////

StartPlayerThreads()
{
	// End this thread on disconnect only
	self endon("disconnect");

	for(;;)
	{
		// Wait for player to spawn
		self waittill("spawned_player");
		RunOnSpawn();
		wait .05;
	}
}

// Thread run on each player, every second
EverySecondThread()
{
	self endon("awe_killthreads");

	sprinthudvisible = false;
	self.awe_pace = 0;

	oldprimary = level.awe_sprintweapon;
	oldammo = 0;
	oldclip = 0;
	oldprimaryb = level.awe_sprintweapon;
	oldammob = 0;
	oldclipb = 0;

	// Avoid some undefined errors
	self.awe_oldprimary2 	= self getWeaponSlotWeapon("primary");
	self.awe_oldammo2 	= self getWeaponSlotAmmo("primary");
	self.awe_oldclip2 	= self getWeaponSlotClipAmmo("primary");
	self.awe_oldprimaryb = self getWeaponSlotWeapon("primaryb");
	self.awe_oldammob 	= self getWeaponSlotAmmo("primaryb");
	self.awe_oldclipb 	= self getWeaponSlotClipAmmo("primaryb");

	ch_count=0;

	if(level.awe_teamplay)
		myteam = self.sessionteam;
	else
		myteam = self.pers["team"];

	oldpos = self.origin;

	while( isPlayer(self) && isAlive(self) && self.sessionstate=="playing" )
	{
		delayed = 0;
		awe\_healthbar::UpdateHealthBar();

		// Get the current weapon
		cw = self getCurrentWeapon();

		// Get the stance every second
		self.awe_stance = self awe\_util::GetStance(false);

		// Show/Hide the sprint hint
		if(level.awe_sprint && level.awe_sprinthudhint)
		{
			if(!sprinthudvisible && self.awe_sprinttime && !self.awe_sprinting && self.awe_pace && level.awe_sprint>self.awe_stance)
			{
				if(isdefined(self.awe_sprinthud_hint))
				{
					self.awe_sprinthud_hint fadeOverTime (1); 
					self.awe_sprinthud_hint.alpha = 1;
					sprinthudvisible = true;
				}
			}
			else if(sprinthudvisible && (self.awe_sprinting || !self.awe_pace || level.awe_sprint<=self.awe_stance) )
			{
				{
					if(isdefined(self.awe_sprinthud_hint))
					{
						self.awe_sprinthud_hint fadeOverTime (1); 
						self.awe_sprinthud_hint.alpha = 0;
						sprinthudvisible = false;
					}
				}
			}
		}

		// Save old weapon data
		if(level.awe_sprint)
		{
			// Save 1 second old data
			if(oldprimary != level.awe_sprintweapon)
			{
				self.awe_oldprimary2 = oldprimary;
				self.awe_oldammo2 = oldammo;
				self.awe_oldclip2 = oldclip;
			}
			if(oldprimaryb != level.awe_sprintweapon)
			{
				self.awe_oldprimaryb = oldprimaryb;
				self.awe_oldammob = oldammob;
				self.awe_oldclipb = oldclipb;
			}
			
			// Save new data
			oldprimary 	= self getWeaponSlotWeapon("primary");
			oldammo 	= self getWeaponSlotAmmo("primary");
			oldclip 	= self getWeaponSlotClipAmmo("primary");
			oldprimaryb = self getWeaponSlotWeapon("primaryb");
			oldammob 	= self getWeaponSlotAmmo("primaryb");
			oldclipb 	= self getWeaponSlotClipAmmo("primaryb");
		}

		// Be un-nice to Unknown Players?
		if(level.awe_unknownmethod && self awe\_util::isUnknown())
		{
			self iprintlnbold("^" + randomInt(8) + "Change your name!");
			switch(level.awe_unknownmethod)
			{
				case 1:
					self dropItem(self getcurrentweapon());
					break;
				case 2:
					self shellshock("default", 1);;
					break;
				default:
					break;
			}
		}

		// Override client cvars
		if(ch_count>=15)
		{
			// Allow crosshairs?
			switch(level.awe_allowcrosshair)
			{
				case 2:		// Force crosshair on
					self setClientCvar("cg_drawcrosshair", "1");
					wait 0.05;
					delayed += 0.05;
					break;

				case 1:		// Let player choose
					break;

				default:		// Force crosshair off
					self setClientCvar("cg_drawcrosshair", "0");
					wait 0.05;
					delayed += 0.05;
					break;
			}
			// Allow crosshairs names?
			switch(level.awe_allowcrosshairnames)
			{
				case 2:		// Force crosshair names on
					self setClientCvar("cg_drawcrosshairnames", "1");
					wait 0.05;
					delayed += 0.05;
					break;

				case 1:		// Let player choose
					break;

				default:		// Force crosshair names off
					self setClientCvar("cg_drawcrosshairnames", "0");
					wait 0.05;
					delayed += 0.05;
					break;
			}
			// Allow crosshairs to switch color when aiming enemies?
			switch(level.awe_allowcrosshaircolor)
			{
				case 2:		// Force crosshair color on
					self setClientCvar("cg_crosshairenemycolor", "1");
					wait 0.05;
					delayed += 0.05;
					break;

				case 1:		// Let player choose
					break;

				default:		// Force crosshair color off
					self setClientCvar("cg_crosshairenemycolor", "0");
					wait 0.05;
					delayed += 0.05;
					break;
			}
			if(level.awe_stopclientexploits)
			{
				self setClientCvar("r_lighttweakambient","0");	// "glowing" models
				wait 0.05;
				delayed += 0.05;
				self setClientCvar("r_lodscale","1");		// See through bushes/trees
				wait 0.05;
				delayed += 0.05;
				self setClientCvar("mss_Q3fs","1");			// Ambient sounds
				wait 0.05;
				delayed += 0.05;
				self setClientCvar("r_polygonOffsetBias","-1");	// Not sure what this does
				wait 0.05;
				delayed += 0.05;
				self setClientCvar("r_polygonOffsetScale","-1");// Same here, not a clue...
			}
			if(level.awe_quickfadecompassdots)
			{
				self setClientCvar("cg_hudCompassSoundPingFadeTime","0");
				wait 0.05;
				delayed += 0.05;
			}
			ch_count=randomInt(15); // Use a random interval between cvar forcing to create some chaos (1-15 seconds)
		}
		ch_count++;

		// Do some unlimted voodoo magic to the ammo counters
		if(level.awe_unlimitedammo)
		{
			self setWeaponSlotAmmo("primary", 999);
			self setWeaponSlotAmmo("primaryb", 999);
			if(level.awe_unlimitedammo == 2)
			{
				self setWeaponSlotClipAmmo("primary", 999);
				self setWeaponSlotClipAmmo("primaryb", 999);
			}
		}
		if(level.awe_unlimitedgrenades)
		{
			sWeapon = awe\_util::GetGrenadeType(game[myteam]);
			ammo = self getammocount(sWeapon);
			if(!ammo)	self giveWeapon(sWeapon);
			self setWeaponClipAmmo(sWeapon, 999);
		}
		if(level.awe_unlimitedsmokegrenades)
		{
			sWeapon = awe\_util::GetSmokeGrenadeType(game[myteam]);
			ammo = self getammocount(sWeapon);
			if(!ammo)	self giveWeapon(sWeapon);
			self setWeaponClipAmmo(sWeapon, 999);
		}

		// Calculate current speed
		wait 1 - delayed;				// Wait 1 seconds minus whatever we were delayed while setting cvars
		newpos = self.origin;
		speed = distance(oldpos,newpos);
		oldpos = newpos;

		if (speed > 20)
			self.awe_pace = 1;
		else
			self.awe_pace = 0;
	}
}

// Thread run on each player, every frame
EveryFrameThread()
{
	if(level.awe_teamplay)
		team = self.sessionteam;
	else
		team = self.pers["team"];

	if(team == "axis")
		otherteam = "allies";
	else
		otherteam = "axis";

	self endon("awe_killthreads");

//	mindist = 9999;
//	maxdist = 0;
	count = 0;
// La Truffe ->
	stop_db = (level.awe_anti_dbbh == 1) || (level.awe_anti_dbbh == 3);
	stop_bh = (level.awe_anti_dbbh == 2) || (level.awe_anti_dbbh == 3);
	count2 = 0;
	lastprone = 2;
	lastjump = 3;
// La Truffe <-
	for(;;)
	{
		count++;
		// Get the stance every half second
		if(count>10)
		{
			self.awe_stance = self awe\_util::GetStance(false);
			count = 0;
		}

// La Truffe ->
		count2 ++;
		if (count2 > 3)
		{
			stance = self awe\_util::GetStance (false);
			jump = self awe\_util::GetStance (true);

			// Test if dive bombing or bunny hopping
			if ((stop_db && ((stance == 2) && (lastprone != 2))) || (stop_bh && ((jump == 3) && (lastjump != 3))))
				self thread WeaponPause (0.4 + randomfloat (0.3));

			lastprone = stance;
			lastjump = jump;
			count2 = 0;
		}
// La Truffe <-
		
		myammo	= self getammocount(awe\_util::GetGrenadeType(game[team]));
		otherammo 	= self getammocount(awe\_util::GetGrenadeType(game[otherteam]));
		ammo = myammo + otherammo;
		if( level.awe_tripwire && ammo>1 && self.awe_stance==2 && !isDefined(self.awe_turretmessage) && !isDefined(self.awe_tripwiremessage))
			self thread awe\_tripwire::checkTripwirePlacement(team, otherteam, myammo, otherammo);

/*		if(self meleeButtonPressed())
		{
			while(self meleeButtonPressed())
				wait .05;
			level thread awe\_util::DropPiano(self);
		}*/
//		z = self.origin[2];
		wait .05;
/*		dist = self.awe_spinemarker.origin[2] - z;
		if(dist<mindist) mindist = dist;
		if(dist>maxdist) maxdist = dist;
		if(self meleebuttonpressed())
		{
			self iprintlnbold("Min:" + mindist + " Max:" + maxdist);
			mindist = 9999;
			maxdist = 0;
		}*/
	}
}

// La Truffe ->
WeaponPause (time)
{
	self endon ("awe_killthreads");

	self disableWeapon ();
	wait time;
	if (isPlayer (self) && (! isdefined (self.awe_plantbar)) && (! isdefined (self.progressbar)))
		self enableWeapon ();
}
// La Truffe <-

///////////////
// Functions //
///////////////

Cleanup()
{
	CleanupKilled();
	CleanupSpawned();

	awe\_teamkilling::Cleanup();
	awe\_welcomemessages::Cleanup();
}

CleanupKilled(sMeansOfDeath)
{
	// Create/Reset variables
	if(!isdefined(self.pers["awe_unknown_name"]))	self.pers["awe_unknown_name"] = "Unknown Soldier";
	self.awe_stance = 0;

	// Remove spine marker if present
	if(isdefined(self.awe_spinemarker))
	{
		self.awe_spinemarker unlink();
		self.awe_spinemarker delete();
	}

	awe\_healthbar::CleanupKilled();
	awe\_laserdot::CleanupKilled();
	awe\_popping::CleanupKilled();
	awe\_spawnprotection::CleanupKilled();
	awe\_sprinting::CleanupKilled();
	awe\_tripwire::CleanupKilled();
	awe\_turrets::CleanupKilled(sMeansOfDeath);
}

CleanupSpawned()
{
	awe\_bloodyscreen::CleanupSpawned();
}

RunOnSpawn()
{
	CleanupSpawned();

	// Kill any running threads
	self notify("awe_killthreads");

	// Limit ammo
	awe\_weaponlimiting::ammoLimiting();

	// Wait for threads to die
	wait .05;

	// Attach spinemarker, used by GetStance()
	self.awe_spinemarker = spawn("script_origin",(0,0,0));
	self.awe_spinemarker linkto (self, "J_Spine4",(0,0,0),(0,0,0));	
//	self.awe_spinemarker linkto (self, "J_Neck",(0,0,0),(0,0,0));	

	// Handle the Unknown Soldiers
	if(self awe\_util::isUnknown())
	{
		// Rename Unknown Soldiers
		// Get names
		names = [];
		count = 0;
		name = awe\_util::cvardef("awe_unknown_name" + count, "", "", "", "string");
		while(name != "")
		{
			names[names.size] = name;
			count++;
			name = awe\_util::cvardef("awe_unknown_name" + count, "", "", "", "string");
		}
		if(names.size)
		{
			self.pers["awe_unknown_name"] = names[randomInt(names.size)] + " " + randomInt(1000);
			self setClientCvar("name", self.pers["awe_unknown_name"]);
			if(level.awe_unknownrenamemsg != "none")
				self iprintlnbold(level.awe_unknownrenamemsg);
		}

		// Make sure an unknown player can't do much damage
		if(level.awe_unknownreflect)
			self.pers["awe_teamkiller"] = true;
	}

	// Start new threads
	self thread EverySecondThread();
	self thread EveryFrameThread();

	self awe\_coldbreath::RunOnSpawn();
	self awe\_healthbar::RunOnSpawn();
	self awe\_laserdot::RunOnSpawn();
	self awe\_servermessages::RunOnSpawn();
	self awe\_spawnprotection::RunOnSpawn();
	self awe\_sprinting::RunOnSpawn();
	self awe\_turrets::RunOnSpawn();
	self awe\_welcomemessages::RunOnSpawn();
// La Truffe ->
	self awe\_warmup::RunOnSpawn ();
// La Truffe <-
}

painsound()
{
	if(level.awe_teamplay)
		team = self.sessionteam;
	else
		team = self.pers["team"];

	nationality = game[team];
	num =  randomInt(level.awe_voices[nationality]) + 1;

	scream = "generic_pain_" + nationality + "_" + num; // i.e. "generic_pain_german_2"
	self playSound(scream);
}
