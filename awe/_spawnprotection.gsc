init()
{
	// Spawn protection
	level.awe_spawnprotection	= awe\_util::cvardef("awe_spawn_protection", 0, 0, 99, "int");

	if(!level.awe_spawnprotection) return;

	level.awe_spawnprotectionrange		= awe\_util::cvardef("awe_spawn_protection_range", 50, 0, 10000, "int");
	level.awe_spawnprotectionhud			= awe\_util::cvardef("awe_spawn_protection_hud", 1, 0, 2, "int");
	level.awe_spawnprotectionheadicon 		= awe\_util::cvardef("awe_spawn_protection_headicon", 1, 0, 1, "int");
	level.awe_spawnprotectiondropweapon 	= awe\_util::cvardef("awe_spawn_protection_dropweapon",0,0,1,"int");
	level.awe_spawnprotectiondisableweapon 	= awe\_util::cvardef("awe_spawn_protection_disableweapon",0,0,1,"int");

	// Precache
	if(!isdefined(game["gamestarted"]))
	{
		precacheShader("gfx/hud/hud@health_cross.tga");
		precacheHeadIcon("gfx/hud/hud@spprot_cross.tga");
	}
}

CleanupKilled()
{
	self.awe_invulnerable = false;
	if(isdefined(self.awe_spawnprotection))	self.awe_spawnprotection destroy();
}

RunOnSpawn()
{
	self thread SpawnProtection();
}

SpawnProtection()
{
	self endon("awe_killthreads");
	if(!level.awe_spawnprotection) return;

	if(level.awe_teamplay)
		myteam = self.sessionteam;
	else
		myteam = self.pers["team"];
	if(myteam == "axis")
		otherteam = "allies";
	else
		otherteam = "axis";

	count = 0;
	startposition = self.origin;
	self iprintln(&"AWE_SPROT_ACT");

	if(level.awe_spawnprotectiondisableweapon)
		self disableWeapon();

	// Set up HUD element
	if(level.awe_spawnprotectionhud == 1)
	{
		self.awe_spawnprotection = newClientHudElem(self);	
		self.awe_spawnprotection.x = 520;
		self.awe_spawnprotection.y = 410;
		self.awe_spawnprotection.alpha = 0.65;
		self.awe_spawnprotection.alignX = "center";
		self.awe_spawnprotection.alignY = "middle";
		self.awe_spawnprotection setShader("gfx/hud/hud@health_cross.tga",40,40);
	}

	if(level.awe_spawnprotectionhud == 2)
	{
		self.awe_spawnprotection = newClientHudElem(self);	
		self.awe_spawnprotection.x = 320;
		self.awe_spawnprotection.y = 240;
		self.awe_spawnprotection.alpha = 0.4;
		self.awe_spawnprotection.alignX = "center";
		self.awe_spawnprotection.alignY = "middle";
		self.awe_spawnprotection setShader("gfx/hud/hud@health_cross.tga",350,320);
	}

	// Get grenade count
	myammo	= self getammocount(awe\_util::GetGrenadeType(game[myteam]));
	otherammo 	= self getammocount(awe\_util::GetGrenadeType(game[otherteam]));
	oldammo = myammo + otherammo;

	while(isAlive(self) && self.sessionstate=="playing" && count < (level.awe_spawnprotection * 20) && !(self attackButtonPressed() || self meleeButtonPressed()) )
	{
		// Get grenade count
		myammo	= self getammocount(awe\_util::GetGrenadeType(game[myteam]));
		otherammo 	= self getammocount(awe\_util::GetGrenadeType(game[otherteam]));
		ammo = myammo + otherammo;
		// Has it decreased?
		if(ammo < oldammo)	// Stop protection on grenade usage
			break;
		// Save last value
		oldammo = ammo;

		self.awe_invulnerable = true;

		if(level.awe_spawnprotectionheadicon)
		{
			// Setup headicon
			self.headicon = "gfx/hud/hud@spprot_cross.tga";
			self.headiconteam = "none";
		}

		if(level.awe_spawnprotectionrange)
		{
			// Check moved range
			distance = distance(startposition, self.origin);
			if(distance > level.awe_spawnprotectionrange)
				count = level.awe_spawnprotection * 20;
		}

		count++;

		wait 0.05;
	}

	if(level.awe_spawnprotectiondisableweapon)
		self enableWeapon();

	self.awe_invulnerable = false;

	if(level.awe_spawnprotectionheadicon)
	{
		if(level.awe_teamplay && level.drawfriend)
		{
			if(myteam == "allies")
			{
				self.headicon = game["headicon_allies"];
				self.headiconteam = "allies";
			}
			else
			{
				self.headicon = game["headicon_axis"];
				self.headiconteam = "axis";
			}
		}
		else
		{
			self.headicon = "";
		}
	}

	if( isAlive(self) && self.sessionstate=="playing" )
	{
		self iprintln(&"AWE_SPROT_DEACT");

		// Fade HUD element
		if(isdefined(self.awe_spawnprotection))
		{
			self.awe_spawnprotection fadeOverTime (1); 
			self.awe_spawnprotection.alpha = 0;
		}

		wait 1;
	}

	// Remove HUD element
	if(isdefined(self.awe_spawnprotection))
		self.awe_spawnprotection destroy();
}