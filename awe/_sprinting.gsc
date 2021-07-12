init()
{
	// Which sprint weapon to use?
	level.awe_sprintweapon = "sprint" + awe\_util::cvardef("awe_sprint_speed",6,2,9,"int") + "0_mp";

	// AWE Sprinting
	level.awe_sprint 			= awe\_util::cvardef("awe_sprint",0,0,3,"int");
	if(!level.awe_sprint) return;

	level.awe_sprinttime 		= awe\_util::cvardef("awe_sprint_time",3,1,999,"int") * 20;
	level.awe_sprintrecovertime	= awe\_util::cvardef("awe_sprint_recover_time",2,0,999,"int") * 20;
	level.awe_sprinthud 		= awe\_util::cvardef("awe_sprint_hud",1,0,2,"int");
	level.awe_sprinthudhint 	= awe\_util::cvardef("awe_sprint_hud_hint",1,0,1,"int");
	level.awe_sprintheavyflag 	= awe\_util::cvardef("awe_sprint_heavy_flag", 0, 0, 1, "int");

	// Precache
	if(!isdefined(game["gamestarted"]))
	{
		precacheItem(level.awe_sprintweapon);

		if(level.awe_sprinthud == 1)
		{
			precacheShader("gfx/hud/hud@health_back.tga");
			precacheShader("gfx/hud/hud@health_bar.tga");
		}

		if(level.awe_sprinthud == 2)
			precacheShader("white");

		if(level.awe_sprinthudhint)
			precacheString(&"^7Hold USE [{+activate}] to sprint");
	}
}

CleanupKilled()
{
	self.awe_sprinttime = 0;
	self.awe_sprinting = false;

	if(!level.awe_sprint) return;

	// Remove hud elements
	if(isdefined(self.awe_sprinthud))		self.awe_sprinthud destroy();
	if(isdefined(self.awe_sprinthud_back))	self.awe_sprinthud_back destroy();
	if(isdefined(self.awe_sprinthud_hint))	self.awe_sprinthud_hint destroy();
}

RunOnSpawn()
{
	self thread MonitorSprinting();
}

monitorsprinting()
{
	self endon("awe_killthreads");

	if(!level.awe_sprint)
		return;

	self.awe_oldprimary = self getWeaponSlotWeapon("primary");
	self.awe_oldprimary2 = self.awe_oldprimary;
	self.awe_oldammo = self getWeaponSlotAmmo("primary");
	self.awe_oldammo2= self.awe_oldammo;
	self.awe_oldclip = self getWeaponSlotClipAmmo("primary");
	self.awe_oldclip2= self.awe_oldclip;
	self.awe_oldcurrent = self getCurrentWeapon();
	self.awe_oldcurrent2 = self.awe_oldcurrent;

	playbreathsound = false;

	// Get maximum sprinttime from global variable
	self.awe_sprinttime = level.awe_sprinttime;
	// Clear recovertime
	recovertime = 0;
	// Setup sprint ammo
	ammo = 100;

	maxwidth = 83;
	y = 434;
	x = 547;

	if(level.awe_sprinthud == 1)
	{
		self.awe_sprinthud_back = newClientHudElem( self );
		self.awe_sprinthud_back setShader("gfx/hud/hud@health_back.tga", maxwidth + 2, 5);
		self.awe_sprinthud_back.alignX = "left";
		self.awe_sprinthud_back.alignY = "top";
		self.awe_sprinthud_back.x = x;
		self.awe_sprinthud_back.y = y;

		self.awe_sprinthud = newClientHudElem( self );
		self.awe_sprinthud setShader("gfx/hud/hud@health_bar.tga", maxwidth, 3);
		self.awe_sprinthud.color = ( 0, 0, 1);
		self.awe_sprinthud.alignX = "left";
		self.awe_sprinthud.alignY = "top";
		self.awe_sprinthud.x = x + 1;
		self.awe_sprinthud.y = y + 1;
	}

	if(level.awe_sprinthud == 2)
	{
		self.awe_sprinthud_back = newClientHudElem( self );
		self.awe_sprinthud_back setShader("white", maxwidth + 2, 5);
		self.awe_sprinthud_back.color = (0.85,0.85,0.85);
		self.awe_sprinthud_back.alignX = "left";
		self.awe_sprinthud_back.alignY = "top";
		self.awe_sprinthud_back.alpha = 0.95;
		self.awe_sprinthud_back.x = x;
		self.awe_sprinthud_back.y = y;

		self.awe_sprinthud = newClientHudElem( self );
		self.awe_sprinthud setShader("white", maxwidth, 3);
		self.awe_sprinthud.color = ( 0, 0, 1);
		self.awe_sprinthud.alignX = "left";
		self.awe_sprinthud.alignY = "top";
		self.awe_sprinthud.alpha = 0.65;
		self.awe_sprinthud.x = x + 1;
		self.awe_sprinthud.y = y + 1;
	}

	if(level.awe_sprinthudhint)
	{
		self.awe_sprinthud_hint = newClientHudElem( self );
		self.awe_sprinthud_hint setText(&"^7Hold USE [{+activate}] to sprint");
		self.awe_sprinthud_hint.alignX = "right";
		self.awe_sprinthud_hint.alignY = "top";
		self.awe_sprinthud_hint.fontScale = 0.8;
		self.awe_sprinthud_hint.x = 635;
		self.awe_sprinthud_hint.y = y - 8;
		self.awe_sprinthud_hint.alpha = 0;
	}


	while (isAlive(self) && self.sessionstate == "playing")
	{
		sprint = (level.awe_sprinttime-self.awe_sprinttime)/level.awe_sprinttime;
		
		if(level.awe_sprinthud)
		{
			if(!self.awe_sprinttime)
			{
				self.awe_sprinthud.color = ( 1.0, 0.0, 0.0);
			}
			else	
			{
				self.awe_sprinthud.color = ( sprint, 0, 1.0-sprint);
			}
		
			hud_width = int((1.0 - sprint) * maxwidth);
			
			if ( hud_width < 1 )
				hud_width = 1;
			
			if(level.awe_sprinthud == 1)
				self.awe_sprinthud setShader("gfx/hud/hud@health_back.tga", hud_width, 3);
			else
				self.awe_sprinthud setShader("white", hud_width, 3);
		}

		oldorigin = self.origin;
		// Wait
		wait .05;

/*		// No sprinting if parchuting or under spawnprotection (with disabled weapon)
		if( (isdefined(self.awe_invulnerable) && level.awe_spawnprotectiondisableweapon) || isdefined(self.awe_isparachuting))
			continue;*/

		// Disable sprinting if we carry a flag in heavy flag mode
		if (level.awe_sprintheavyflag && isdefined(self.flagAttached))
			self.awe_sprinttime = 0;

		// Are we sprinting?
		if((oldorigin != self.origin || self.awe_pace) && self.awe_sprinttime>0 && self useButtonPressed() && level.awe_sprint>self.awe_stance)
		{
			// If not currently sprinting
			if(!self.awe_sprinting)
			{
				// Save old primary
				pw = self getWeaponSlotWeapon("primary");
				cw = self getCurrentWeapon();

				// If primary is not allready level.awe_sprintweapon
				if(pw != level.awe_sprintweapon)
				{
					// If current weapon is not "none"
					if(cw != "none")
					{
						// Save old primary
						self.awe_oldprimary = pw;
						self.awe_oldammo = self getWeaponSlotAmmo("primary");
						self.awe_oldclip = self getWeaponSlotClipAmmo("primary");

						// Save old current unless it is allready level.awe_sprintweapon
						if(cw != level.awe_sprintweapon)
							self.awe_oldcurrent = cw;
						else	// Else save primary as current
							self.awe_oldcurrent = pw;
					}
					else	// If cw is "none" then we likely unintenionally picked up a weapon when trying to sprint
					{
						// Check if any of the primaries have between the last 1-2 seconds
						if(pw != self.awe_oldprimary2)	// We've picked up a new primary by mistake
						{
							// Save the old primary in temporary varibles in case we need them
							oldprimary2 = self.awe_oldprimary2;
							oldammo2 = self.awe_oldammo2;
							oldclip2 = self.awe_oldclip2;
							oldcurrent2 = self.awe_oldprimary2;

							// Measure that the button is pressed for 0.5 second to make sure the player really want to sprint
							buttoncount = 0;
							while(self useButtonPressed() && buttoncount < 10)
							{
								buttoncount++;
								wait .05;
							}
							if(buttoncount<10)	// Seems this was just a normal weapon pickup
								continue;
							
							// Save the old primary instead if the new one
							self.awe_oldprimary = oldprimary2;
							self.awe_oldammo = oldammo2;
							self.awe_oldclip = oldclip2;
							self.awe_oldcurrent = oldprimary2;
						}
						else if(self getWeaponSlotWeapon("primaryb") != self.awe_oldprimaryb)	//We've picked up a new primaryb by mistake
						{
							// Save the old primary in temporary varibles in case we need them
							oldprimaryb = self.awe_oldprimaryb;
							oldammob = self.awe_oldammob;
							oldclipb = self.awe_oldclipb;

							// Measure that the button is pressed for 0.5 second to make sure the player really want to sprint
							buttoncount = 0;
							while(self useButtonPressed() && buttoncount < 10)
							{
								buttoncount++;
								wait .05;
							}
							if(buttoncount<10)	// Seems this was just a normal weapon pickup
								continue;

							// Restore the old primaryb
							self setWeaponSlotWeapon(	"primaryb",oldprimaryb);
							self setWeaponSlotAmmo(		"primaryb",oldammob);
							self setWeaponSlotClipAmmo(	"primaryb",oldclipb);

							// Save old primary
							self.awe_oldprimary = pw;
							self.awe_oldammo = self getWeaponSlotAmmo("primary");
							self.awe_oldclip = self getWeaponSlotClipAmmo("primary");

							// If we just switched primaryb then it must have been the current weapon
							self.awe_oldcurrent = oldprimaryb;
						}
						else	// Current weapon is "none" for unknown reason
						{
							// Save old primary
							self.awe_oldprimary = pw;
							self.awe_oldammo = self getWeaponSlotAmmo("primary");
							self.awe_oldclip = self getWeaponSlotClipAmmo("primary");
							self.awe_oldcurrent = pw;
						}
					}
				}

				if(level.awe_debug)
				{
					iprintln("oldprimary:" + self.awe_oldprimary);
					iprintln("oldcurrent:" + self.awe_oldcurrent);
					iprintln("cw:" + cw);
					iprintln("pw:" + pw);
				}

				// Set and select sprint weapon as primary
				self setWeaponSlotWeapon("primary", level.awe_sprintweapon);
				self switchToWeapon(level.awe_sprintweapon);
				self.awe_sprinting = true;
				playbreathsound = true;
				wait .05;
			}
			else
			{
				// Are we sprinting but weapon has been switched or picked up?
				cw = self getCurrentWeapon();
				pw = self getWeaponSlotWeapon("primary");

				// Picked up weapon by mistake?
				if(pw != level.awe_sprintweapon)
				{
					//Clean sweep the "world" for dropped potatoes
					awe\_util::deletePlacedEntity("weapon_" + level.awe_sprintweapon);

					// Set and select sprint weapon as primary
					self setWeaponSlotWeapon("primary", level.awe_sprintweapon);
					self switchToWeapon(level.awe_sprintweapon);
					wait .05;
				}
				else if(cw != level.awe_sprintweapon)	// Switched weapon while sprinting?
				{
					//Switch back to potato
					self switchToWeapon(level.awe_sprintweapon);
					wait .05;
				}
			}

			// Decrease available sprinttime
			self.awe_sprinttime--;
			// Update sprint ammo
			ammo = int(100 * (1.0 - sprint));
			self setWeaponSlotAmmo("primary",ammo);

		}
		else
		{
			// Did we just stop sprinting?
			if(self.awe_sprinting)
			{
				if(level.awe_debug)
				{
					iprintln("oldprimary2:" + self.awe_oldprimary);
					iprintln("oldcurrent2:" + self.awe_oldcurrent);
				}

				//Restore old primary and ammo
				self setWeaponSlotWeapon("primary", self.awe_oldprimary);
				self setWeaponSlotAmmo("primary", self.awe_oldammo);
				self setWeaponSlotClipAmmo("primary", self.awe_oldclip);
		
				// Make sure no sprint weapon has been picked up as primaryb (should never happen)
				if(self getWeaponSlotWeapon("primaryb") == level.awe_sprintweapon)
					self setWeaponSlotWeapon("primaryb", "none");

				//Restore old current
				if(self.awe_oldcurrent != "none")
					self switchToWeapon(self.awe_oldcurrent);
				else if(self.awe_oldprimary != "none")
					self switchToWeapon(self.awe_oldprimary); // Fallback

				// Get recover time from global variable
				recovertime = level.awe_sprintrecovertime;

				// Calculate recovertime of full sprinttime has not been used
				if(self.awe_sprinttime>0)
					recovertime = int(recovertime * sprint + 0.5);

				self.awe_sprinting = false;
				wait .05;
			}

			// Are we recovering?
			if(self.awe_sprinttime<(level.awe_sprinttime) && !(self useButtonPressed() && !isdefined(self.awe_plantbar) && !isdefined(self.awe_pickbar) ) )
			{
				// Don't increase sprinttime unless recovertime has passed
				if(recovertime>0)
				{
					recovertime--;
					if(playbreathsound)
					{
						if(!randomInt(6))
							self playLocalSound("breathing_better");
						playbreathsound = false;
					}
				}
				else
					self.awe_sprinttime++;
			}
		}
	}

	if(isdefined(self.awe_sprinthud)) self.awe_sprinthud destroy();
	if(isdefined(self.awe_sprinthud_back)) self.awe_sprinthud_back destroy();
	if(isdefined(self.awe_sprinthud_hint)) self.awe_sprinthud_hint destroy();
}
