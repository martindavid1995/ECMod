// Modified by La Truffe

init()
{
	// Delete all MG42s?
	level.awe_mg42disable		= awe\_util::cvardef("awe_mg42_disable", 0, 0, 1, "int");
	// Delete all 30Cals?
	level.awe_30caldisable		= awe\_util::cvardef("awe_30cal_disable", 0, 0, 1, "int");

	// Mobile turrets?
	level.awe_turretmobile		= awe\_util::cvardef("awe_turret_mobile",0,0,2,"int");

	if(level.awe_turretmobile)
	{
		level.awe_turretplanttime	= awe\_util::cvardef("awe_turret_plant_time", 2, 0, 30, "float");
		level.awe_turretpicktime	= awe\_util::cvardef("awe_turret_pick_time", 1, 0, 30, "float");
		level.awe_mg42spawnextra	= awe\_util::cvardef("awe_mg42_spawn_extra", 0, 0, 20, "int");
		level.awe_30calspawnextra	= awe\_util::cvardef("awe_30cal_spawn_extra", 0, 0, 20, "int");

		level.awe_turretpenalty 	= awe\_util::cvardef("awe_turret_penalty", 1, 0, 1, "int");
		level.awe_turretrecover		= awe\_util::cvardef("awe_turret_recover", 1, 0, 1, "int");

		level.awe_turretpickupmessage	= &"^7Hold MELEE ([{+melee}]) to pick up";
		level.awe_turretplacemessage	= &"^7Hold MELEE ([{+melee}]) to place";
		if(level.awe_turretpicktime)
			level.awe_turretpickingmessage= &"^7Picking up...";
		if(level.awe_turretplanttime)
			level.awe_turretplacingmessage= &"^7Placing...";
	}

	// Overheating turrets?
	level.awe_turretoverheat		= awe\_util::cvardef("awe_turret_overheat",10,0,9999,"int");
	level.awe_turretcooldown		= awe\_util::cvardef("awe_turret_cooldown",5,0,9999,"int");

	if(level.awe_turretoverheat)
	{
		level.awe_turretoverheatmessage= &"^7Temperature";
		level.awe_turretoverheatmessage2= &"^3OVERHEATED!";
		level.awe_overheatfx = loadfx ("fx/smoke/thin_black_smoke_S.efx");
	}

	// Precache
	if(!isdefined(game["gamestarted"]))
	{
		if(level.awe_turretmobile)
		{
			precacheString( level.awe_turretpickupmessage );
			precacheString( level.awe_turretplacemessage );
			if(level.awe_turretpicktime)
				precacheString( level.awe_turretpickingmessage );
			if(level.awe_turretplanttime)
				precacheString( level.awe_turretplacingmessage );

			precacheShader("gfx/icons/hud@mg42.tga");
			precacheShader("gfx/icons/hud_30cal");
		}

		temp = awe\_util::cvardef("awe_turret_w0", "", "", "", "string");
		if(temp != "" || level.awe_turretmobile)
		{
			// MG42
			precacheModel("xmodel/weapon_mg42");
			precacheItem("mg42_bipod_duck_mp");
			precacheItem("mg42_bipod_prone_mp");
			precacheItem("mg42_bipod_stand_mp");
			precacheTurret("mg42_bipod_duck_mp");
			precacheTurret("mg42_bipod_prone_mp");
			precacheTurret("mg42_bipod_stand_mp");

			// 30Cal
			precacheModel("xmodel/weapon_30cal");
			precacheItem("30cal_prone_mp");
			precacheItem("30cal_stand_mp");	
			precacheTurret("30cal_prone_mp");
			precacheTurret("30cal_stand_mp");
		}

		if(level.awe_turretoverheat)
		{
			precacheString( level.awe_turretoverheatmessage );
			precacheString( level.awe_turretoverheatmessage2 );
// La Truffe ->
			precacheString (&"AWE_OVERHEATED");
// La Truffe <-
			precacheShader("gfx/hud/hud@health_back.tga");
			precacheShader("gfx/hud/hud@health_bar.tga");
		}
	}

	level thread turretStuff();
}

CleanupKilled(sMeansOfDeath)
{
	RemoveOverheatHud();

	// Drop turret
//	dropTurret(undefined, sMeansOfDeath);

	// Remove huds
//	if(isdefined(self.awe_turretmessage))	self.awe_turretmessage destroy();
//	if(isdefined(self.awe_turretmessage2))	self.awe_turretmessage2 destroy();
//	if(isdefined(self.awe_pickbarbackground))	self.awe_pickbarbackground destroy();
//	if(isdefined(self.awe_pickbar))		self.awe_pickbar destroy();
//	if(isdefined(self.awe_plantbarbackground))	self.awe_plantbarbackground destroy();
//	if(isdefined(self.awe_plantbar))		self.awe_plantbar destroy();
}

RunOnSpawn()
{
	RemoveOverheatHud();

//	dropTurret(undefined, undefined);	// Just in case...

	self.awe_usingturret = undefined;
//	self.awe_touchingturret = undefined;
//	self.awe_placingturret = undefined;
//	self.awe_pickingturret = undefined;
}

turretStuff()
{
	level endon("awe_killthreads");

	// Wait a servercycle to make sure unwanted entities has been removed
	wait .05;

	// Count all turrets
	allent = getentarray();	// Get all entities

	numturrets=0;

	for(i=0;i<allent.size;i++)	// Loop through them
	{
		if(isdefined(allent[i]))		// Exist?
		{
			if(isdefined(allent[i].weaponinfo))		// Weapon?
			{
				switch(allent[i].weaponinfo)
				{
					case "mg42_bipod_prone_mp":
					case "mg42_bipod_stand_mp":
					case "mg42_bipod_duck_mp":
						if(level.awe_mg42disable)	// Delete MG42s?
							allent[i] delete();
						else
 							numturrets++;
						break;
					case "30cal_prone_mp":
					case "30cal_stand_mp":
						if(level.awe_30caldisable)	// Delete 30Cals?
							allent[i] delete();
						else
 							numturrets++;
						break;

					default:
						break;
				}
			}
		}
	}

	if(level.awe_mg42disable || level.awe_30caldisable)
		wait 0.05;	// Allow changes to happen

	// Spawn extra MG42s and/or 30Cals at specific locations

	// Get first turret
	count = 0;
	x = awe\_util::cvardef("awe_turret_x" + count, 0, -50000, 50000, "int");
	y = awe\_util::cvardef("awe_turret_y" + count, 0, -50000, 50000, "int");
	z = awe\_util::cvardef("awe_turret_z" + count, 0, -50000, 50000, "int");
	a = awe\_util::cvardef("awe_turret_a" + count, 0, -50000, 50000, "int");
	w = awe\_util::cvardef("awe_turret_w" + count, "", "", "", "string");

	// spawn turrets
	while(w != "" && numturrets < 32)
	{
		switch(w)
		{
			case "mg42_bipod_stand_mp":
			case "mg42_bipod_duck_mp":
			case "mg42_bipod_prone_mp":
				name	= "misc_turret";
				model	= "xmodel/weapon_mg42";
				break;

			default:
				name	= "misc_turret";
				model	= "xmodel/weapon_30cal";
				break;
		}

		position = (x,y,z);
		turret = spawnTurret (name, position, w);
 		turret setmodel (model);
		turret.weaponinfo = w;
		turret.angles = (0,a,0);
		turret.origin = position + (0,0,-1);	//do this LAST. It'll move the MG into a usable position
		turret show();

		numturrets++;		
		count++;

		x = awe\_util::cvardef("awe_turret_x" + count, 0, -50000, 50000, "int");
		y = awe\_util::cvardef("awe_turret_y" + count, 0, -50000, 50000, "int");
		z = awe\_util::cvardef("awe_turret_z" + count, 0, -50000, 50000, "int");
		a = awe\_util::cvardef("awe_turret_a" + count, 0, -50000, 50000, "int");
		w = awe\_util::cvardef("awe_turret_w" + count, "", "", "", "string");
	}
/*
	// Spawn extra MG42s and/or 30Cals
	if(level.awe_mg42spawnextra || level.awe_30calspawnextra)
	{
		spawnallied	= getentarray(level.awe_spawnalliedname, "classname");
		spawnaxis	= getentarray(level.awe_spawnaxisname, "classname");

		// Fall back to deatchmatch spawns, just in case. (Needed for LTS on non SD maps)
		if(!spawnallied.size)
			spawnallied	= getentarray("mp_deathmatch_spawn", "classname");
		if(!spawnallied.size)
			spawnallied	= getentarray("mp_teamdeathmatch_spawn", "classname");
		if(!spawnaxis.size)
			spawnaxis	= getentarray("mp_deathmatch_spawn", "classname");
		if(!spawnaxis.size)
			spawnaxis	= getentarray("mp_teamdeathmatch_spawn", "classname");

		oddeven=randomInt(2);
		for(i=0;i<level.awe_mg42spawnextra && numturrets<32;i++)
		{
			// Get a random spawn point
			if(oddeven)
			{
				spawn = spawnallied[randomInt(spawnallied.size)];
				oddeven=0;
			}
			else
			{
				spawn = spawnaxis[randomInt(spawnaxis.size)];
				oddeven=1;
			}

			position = spawn.origin - ( 15, 15, 0) + ( randomInt(31), randomInt(31), 0);
			trace=bulletTrace(position,position+(0,0,-1200),false,undefined);
			ground=trace["position"];
			turret = spawn("script_model", ground+(0,0,-10000));
			turret.targetname = "dropped_turret";
			turret setmodel ( "xmodel/mg42_bipod"  );
			turret.angles = (0,randomInt(360),125);
			turret.origin = ground + (0,0,11);  //get the little feet into the terrain
			turret show();

			numturrets++;
		}
	
		oddeven=randomInt(2);
		for(i=0;i<level.awe_30calspawnextra && numturrets<32;i++)
		{
			// Get a random spawn point
			if(oddeven)
			{
				spawn = spawnallied[randomInt(spawnallied.size)];
				oddeven=0;
			}
			else
			{
				spawn = spawnaxis[randomInt(spawnaxis.size)];
				oddeven=1;
			}

			position = spawn.origin - ( 15, 15, 0) + ( randomInt(31), randomInt(31), 0);
			trace=bulletTrace(position,position+(0,0,-1200),false,undefined);
			ground=trace["position"];
			turret = spawn("script_model", ground + (0,0,-10000));
			turret.targetname = "dropped_turret";
			turret setmodel ( "xmodel/weapon_antitankrifle"  );
			turret.angles = (0,randomInt(360),112);
			turret.origin = ground + (0,0,11);
			turret show();

			numturrets++;
		}
	}	
*/
	wait 0.05;	// Allow changes to happen

	// Build turret array
	level.awe_turrets = [];

	allent = getentarray();	// Get all entities

	for(i=0;i<allent.size;i++)	// Loop through them
	{
		if(isdefined(allent[i]))		// Exist?
		{
			if(isdefined(allent[i].weaponinfo))		// Weapon?
			{
				switch(allent[i].weaponinfo)
				{
					case "mg42_bipod_stand_mp":
					case "mg42_bipod_duck_mp":
					case "mg42_bipod_prone_mp":
					case "30cal_prone_mp":
					case "30cal_stand_mp":
						level.awe_turrets[level.awe_turrets.size]["turret"] = allent[i];
						level.awe_turrets[level.awe_turrets.size - 1]["type"] = "misc_turret";
						level.awe_turrets[level.awe_turrets.size - 1]["original_position"] = allent[i].origin;
						level.awe_turrets[level.awe_turrets.size - 1]["original_angles"]	= allent[i].angles;
						level.awe_turrets[level.awe_turrets.size - 1]["original_weaponinfo"]=allent[i].weaponinfo;
						level.awe_turrets[level.awe_turrets.size - 1]["dropped"] = undefined;
						level.awe_turrets[level.awe_turrets.size - 1]["carried"] = undefined;
						level.awe_turrets[level.awe_turrets.size - 1]["heat"] = 0;
						break;

					default:
						break;
				}
			}
		}
	}

	// Get dropped turrets
	mgs=getEntArray("dropped_turret","targetname");
	for (i=0;i<mgs.size;i++)
	{
		if(isdefined(mgs[i]))
		{
			level.awe_turrets[level.awe_turrets.size]["turret"] = mgs[i];
			level.awe_turrets[level.awe_turrets.size - 1]["type"] = "misc_turret";
			level.awe_turrets[level.awe_turrets.size - 1]["original_position"] = mgs[i].origin;
			level.awe_turrets[level.awe_turrets.size - 1]["original_angles"]	= mgs[i].angles;
			level.awe_turrets[level.awe_turrets.size - 1]["original_weaponinfo"]= undefined;
			level.awe_turrets[level.awe_turrets.size - 1]["dropped"] = true;
			level.awe_turrets[level.awe_turrets.size - 1]["carried"] = undefined;
			level.awe_turrets[level.awe_turrets.size - 1]["heat"] = 0;
		}
	}

	// Start turret think threads
	for(i=0;i<level.awe_turrets.size;i++)
		if( !isdefined(level.awe_turrets[i]["dropped"]) && !isdefined(level.awe_turrets[i]["carried"]) )
			level.awe_turrets[i]["turret"] thread turret_think(i);
}

turret_think(num)
{
	level endon("awe_killthreads");
	self endon("awe_killthreads");

	dist = 0;
	oldammo = 0;
	cooldown = 0;
	oddeven = 0;

	for(;;)
	{
		globalused = false;
		fired = false;

		// No need to run if turret is being carried (Thread should be killed, but just in case)
		if(isdefined(level.awe_turrets[num]["carried"]))
		{
			wait 0.5;
			continue;
		}
			
		// Every other run flag
		if(oddeven)
			oddeven = 0;
		else
			oddeven = 1;

		// Loop through all the players
		for(i = 0; i < level.awe_allplayers.size; i++)
		{
			used = false;
			touched = false;

			player = level.awe_allplayers[i];

			// Does player exist, alive and playing?
			if(isdefined(player) && isAlive(player) && player.sessionstate == "playing")
			{
				touched = player istouching(self);

				// Within distance?
				dist = distance(self.origin, player.origin);
//				if(dist<100) player iprintln("dist:" + dist);
				if(isdefined(dist) && dist < 65 && dist > 49 && !touched)
				{
					cw = player getCurrentWeapon();
					// If curretweapon is "none" then we are for sure using the turret
					if(cw == "none")
						used = true;
					else	// However sometimes it is not set to "none" and we need more checking
					{
						// Is the player fireing?
						if(level.awe_turretoverheat)
						{
							if(player attackButtonPressed())
							{
								// Which slot are we checking?
								slot = "none";
								if(cw == player getWeaponSlotWeapon("primary"))
									slot = "primary";
								if(cw == player getWeaponSlotWeapon("primaryb"))
									slot = "primaryb";
								if(slot != "none")
								{
									// Get ammo
									ammo = player getWeaponSlotAmmo(slot);	

									if(oldammo)
									{
										// Is it unchanged?
										if(ammo == oldammo)
										{
											used = true;
										}
									}
									oldammo = ammo;
								}
							}
							else	// Have used this turret and is within distance and has not fired
							{
								if(isdefined(player.awe_usingturret) && player.awe_usingturret == num)
									used = true;
							}
						}
					}
				}

				if(used)
				{
					globalused = true;
					player.awe_usingturret = num;
					if(level.awe_debug)
					{
						player iprintln("w:" + self.weaponinfo);
						player iprintln("x:" + self.origin[0] + " y:" + self.origin[1] + " z:" + self.origin[2] + " a:" + self.angle[2]);
					}

					// Is it being fired?
					if(level.awe_turretoverheat)
					{
						if(player attackButtonPressed())
						{
							fired = true;
							oddeven = 1;
							// Is it overheated?
							level.awe_turrets[num]["heat"]++;
							if(level.awe_turrets[num]["heat"] > level.awe_turretoverheat*5)
							{
								cooldown = level.awe_turretcooldown*5;
// La Truffe ->
//								player iprintlnbold("^1OVERHEATED!");
								player iprintlnbold (&"AWE_OVERHEATED");
// La Truffe <-
								sMeansOfDeath = "MOD_EXPLOSIVE";
								iDFlags = 1;
								iDamage = level.awe_turrets[num]["heat"] - level.awe_turretoverheat*5;
								sWeapon = self.weaponinfo;
								vDir=(0,0,0);
								player thread [[level.callbackPlayerDamage]](self, self, iDamage, iDFlags, sMeansOfDeath, sWeapon, undefined, vDir, "none", 0);
							}
						}
						else
						{
							if(cooldown)
							{
								if(randomint(2))
									playfx(level.awe_overheatfx,self.origin + (0,0,10));
								cooldown--;
							}
							else
							{
								if(oddeven && level.awe_turrets[num]["heat"]) level.awe_turrets[num]["heat"]--;
							}
						}
						// Show heatbar
						player UpdateOverheatHud(num, fired, oddeven);
					}
				}
				else
				{
					// Clear player flag if this turret has been used previously
					if(isdefined(player.awe_usingturret) && player.awe_usingturret == num)
					{
						player.awe_usingturret = undefined;
						player RemoveOverheatHud();
					}
				}
			}
		}
		// Cool down even if noone is using it.
		if(!globalused && !fired)
		{
			if(cooldown)
			{
				if(randomint(2))
					playfx(level.awe_overheatfx,self.origin + (0,0,10));
				cooldown--;
			}
			else
			{
				if(oddeven && level.awe_turrets[num]["heat"]) level.awe_turrets[num]["heat"]--;
			}
		}
		wait .2;
	}
}

UpdateOverheatHud(num, fired, oddeven)
{
	if(!oddeven) return;

	if(fired)
		time = 0.2;
	else
		time = 0.4;

	barsize = 200;
// La Truffe ->
//	y = 468;
	y = 452;
// La Truffe <-
	heat = level.awe_turrets[num]["heat"];
	if(heat>level.awe_turretoverheat*5)
	{
		heat = level.awe_turretoverheat*5;
		message = level.awe_turretoverheatmessage2; 
	}
	else
		message = level.awe_turretoverheatmessage; 
	size = int(heat * barsize / (level.awe_turretoverheat * 5) + 0.5);
	
	c = size / barsize;

	if(!size) size = 1;

	color = (1,1-c,1-c);
	if(!isdefined(self.awe_overheatbarbackground))
	{
		// Background
		self.awe_overheatbarbackground = newClientHudElem(self);				
		self.awe_overheatbarbackground.alignX = "center";
		self.awe_overheatbarbackground.alignY = "top";
		self.awe_overheatbarbackground.x = 320;
		self.awe_overheatbarbackground.y = y;
		self.awe_overheatbarbackground setShader("gfx/hud/hud@health_back.tga", (barsize + 4), 11);			
	}
	if(!isdefined(self.awe_overheatbar))
	{
		// Progress bar
		self.awe_overheatbar = newClientHudElem(self);				
		self.awe_overheatbar.alignX = "left";
		self.awe_overheatbar.alignY = "top";
		self.awe_overheatbar.x = (320 - (barsize / 2.0));
		self.awe_overheatbar.y = y+1;
		self.awe_overheatbar.color = color;
		self.awe_overheatbar setShader("gfx/hud/hud@health_bar.tga", size, 9);
	}
	else
	{
		self.awe_overheatbar.color = color;
		self.awe_overheatbar scaleOverTime(time , size, 9);
	}

	if(!isdefined(self.awe_overheatmessage))
	{
		self.awe_overheatmessage = newClientHudElem( self );
		self.awe_overheatmessage.alignX = "center";
		self.awe_overheatmessage.alignY = "top";
		self.awe_overheatmessage.x = 320;
		self.awe_overheatmessage.y = y+1;
		self.awe_overheatmessage.alpha = 1;
		self.awe_overheatmessage.fontScale = 0.80;
//		self.awe_overheatmessage.color = (.5,.5,.5);
	}
	self.awe_overheatmessage setText( message );

//	self iprintln("size: " + size);
}

RemoveOverheatHud()
{
	if(!level.awe_turretoverheat)
		return;

	if(isdefined(self.awe_overheatbarbackground))	self.awe_overheatbarbackground destroy();
	if(isdefined(self.awe_overheatbar))			self.awe_overheatbar destroy();
	if(isdefined(self.awe_overheatmessage))		self.awe_overheatmessage destroy();
}