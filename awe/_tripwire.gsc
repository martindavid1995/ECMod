init()
{
	// Use tripwires?
	level.awe_tripwire		= awe\_util::cvardef("awe_tripwire", 0, 0, 3, "int");

	if(!level.awe_tripwire) 		return;

	// Tripwire options
	level.awe_tripwirelimit		= awe\_util::cvardef("awe_tripwire_limit", 5, 1, 20, "int");
	level.awe_tripwirewarning	= awe\_util::cvardef("awe_tripwire_warning", 1, 0, 1, "int");
	level.awe_tripwireplanttime	= awe\_util::cvardef("awe_tripwire_plant_time", 3, 0, 30, "float");
	level.awe_tripwirepicktimesameteam	= awe\_util::cvardef("awe_tripwire_pick_time_sameteam", 5, 0, 30, "float");
	level.awe_tripwirepicktimeotherteam	= awe\_util::cvardef("awe_tripwire_pick_time_otherteam", 8, 0, 30, "float");

	// Initialize counters
	if(level.awe_teamplay)
	{
		level.awe_tripwires["axis"] = 0;
		level.awe_tripwires["allies"] = 0;
	}
	else
	{
		level.awe_tripwires = 0;
		level.awe_satchels = 0;
	}

	// Setup strings
	level.awe_tripwirepickupmessage	= &"^7Hold USE ([{+activate}]) to pick up";
	level.awe_tripwireplacemessage	= &"^7Hold USE ([{+activate}]) to place";
	if(level.awe_tripwirepicktimesameteam || level.awe_tripwirepicktimeotherteam)
		level.awe_turretpickingmessage= &"^7Picking up...";
	if(level.awe_tripwireplanttime)
		level.awe_turretplacingmessage= &"^7Placing...";

	// Precache
	if(!isdefined(game["gamestarted"]))
	{
		precacheString( level.awe_tripwirepickupmessage );
		precacheString( level.awe_tripwireplacemessage );
		if(level.awe_tripwirepicktimesameteam || level.awe_tripwirepicktimeotherteam)
			precacheString( level.awe_turretpickingmessage );
		if(level.awe_tripwireplanttime)
			precacheString( level.awe_turretplacingmessage );

		switch(game["allies"])
		{
			case "american":
				precacheShader("gfx/icons/hud@us_grenade.tga");
				break;

			case "british":
				precacheShader("gfx/icons/hud@british_grenade.tga");
				break;

			case "russian":
				precacheShader("gfx/icons/hud@russian_grenade.tga");
				break;
		}
		precacheShader("gfx/icons/hud@steilhandgrenate.tga");

		if(level.awe_tripwireplanttime || level.awe_tripwirepicktimesameteam || level.awe_tripwirepicktimeotherteam)
			precacheShader("white");
	}
}

CleanupKilled()
{
	if(!level.awe_tripwire) 		return;

	if(isdefined(self.awe_tripwiremessage))		self.awe_tripwiremessage destroy();
	if(isdefined(self.awe_tripwiremessage2))		self.awe_tripwiremessage2 destroy();
	if(isdefined(self.awe_pickbarbackground))		self.awe_pickbarbackground destroy();
	if(isdefined(self.awe_pickbar))			self.awe_pickbar destroy();
	if(isdefined(self.awe_plantbarbackground))	self.awe_plantbarbackground destroy();
	if(isdefined(self.awe_plantbar))			self.awe_plantbar destroy();

	self.awe_tripwirewarning = false;
	self.awe_checkdefusetripwire = false;
}


//Thread to determine if a player can place grenades
checkTripwirePlacement(team, otherteam, myammo, otherammo)
{
	if(!level.awe_tripwire) 		return;

	self notify("awe_checktripwireplacement");
	self endon("awe_checktripwireplacement");
	level endon("awe_killthreads");
	self endon("awe_killthreads");

	while( isAlive( self ) && self.sessionstate=="playing" && self useButtonPressed() )
		wait( 0.1 );

	if(myammo)
		sWeapon = awe\_util::GetGrenadeType(game[team]);
	else
		sWeapon = awe\_util::GetGrenadeType(game[otherteam]);

	showTripwireMessage(sWeapon, level.awe_tripwireplacemessage);

	while( isAlive( self ) && self.sessionstate=="playing" && !isdefined(self.awe_turretmessage) && !isdefined(self.progressbar) )
	{
		myammo	= self getammocount(awe\_util::GetGrenadeType(game[team]));
		otherammo 	= self getammocount(awe\_util::GetGrenadeType(game[otherteam]));
		iAmmo = myammo + otherammo;
		if(iAmmo<2) break;

		if(myammo)
		{
			sWeapon = awe\_util::GetGrenadeType(game[team]);
			if(myammo>1)
				sWeapon2 = sWeapon;
			else
				sWeapon2 = awe\_util::GetGrenadeType(game[otherteam]);
				
		}
		else
		{
			sWeapon = awe\_util::GetGrenadeType(game[otherteam]);
			sWeapon2 = sWeapon;
		}


			

		if(self.awe_stance!=2) break;

		// Get position
		position = self.origin + maps\mp\_utility::vectorScale(anglesToForward(self.angles),15);

		// Check that there is room.
		trace=bulletTrace(self.origin+(0,0,10),position+(0,0,10),false,undefined);
		if(trace["fraction"]!=1) break;
	
		// Find ground
		trace=bulletTrace(position+(0,0,10),position+(0,0,-10),false,undefined);
		if(trace["fraction"]==1) break;
		position=trace["position"];
		tracestart = position + (0,0,10);

		// Find position1
		traceend = tracestart + maps\mp\_utility::vectorScale(anglesToForward(self.angles + (0,90,0)),50);
		trace=bulletTrace(tracestart,traceend,false,undefined);
		if(trace["fraction"]!=1)
		{
			distance = distance(tracestart,trace["position"]);
			if(distance>5) distance = distance - 2;
			position1=tracestart + maps\mp\_utility::vectorScale(vectorNormalize(trace["position"]-tracestart),distance);
		}
		else
			position1 = trace["position"];

		// Find ground
		trace=bulletTrace(position1,position1+(0,0,-20),false,undefined);
		if(trace["fraction"]==1) break;
		vPos1=trace["position"] + (0,0,3);

		// Find position2
		traceend = tracestart + maps\mp\_utility::vectorScale(anglesToForward(self.angles + (0,-90,0)),50);
		trace=bulletTrace(tracestart,traceend,false,undefined);
		if(trace["fraction"]!=1)
		{
			distance = distance(tracestart,trace["position"]);
			if(distance>5) distance = distance - 2;
			position2=tracestart + maps\mp\_utility::vectorScale(vectorNormalize(trace["position"]-tracestart),distance);
		}
		else
			position2 = trace["position"];

		// Find ground
		trace=bulletTrace(position2,position2+(0,0,-20),false,undefined);
		if(trace["fraction"]==1) break;
		vPos2=trace["position"] + (0,0,3);

		if( isAlive( self ) && self.sessionstate == "playing" && self useButtonPressed() && !isdefined(self.progressbar) )
		{
			// Check tripwire limit
			if(level.awe_teamplay)
			{
				if(level.awe_tripwires[self.sessionteam]>=level.awe_tripwirelimit)
				{
					self iprintlnbold(&"AWE_MAX_TRIPWIRES_TEAM");
					// Remove hud elements
					if(isdefined(self.awe_plantbarbackground)) self.awe_plantbarbackground destroy();
					if(isdefined(self.awe_plantbar))		 self.awe_plantbar destroy();
					if(isdefined(self.awe_tripwiremessage))	self.awe_tripwiremessage destroy();
					if(isdefined(self.awe_tripwiremessage2))	self.awe_tripwiremessage2 destroy();
					return false;
				}
			}
			else
			{
				if(level.awe_tripwires>=level.awe_tripwirelimit*2)
				{
					self iprintlnbold(&"AWE_MAX_TRIPWIRES");
					// Remove hud elements
					if(isdefined(self.awe_plantbarbackground)) self.awe_plantbarbackground destroy();
					if(isdefined(self.awe_plantbar))		 self.awe_plantbar destroy();
					if(isdefined(self.awe_tripwiremessage))	self.awe_tripwiremessage destroy();
					if(isdefined(self.awe_tripwiremessage2))	self.awe_tripwiremessage2 destroy();
					return false;
				}
			}

			// Ok to plant, show progress bar
			origin = self.origin;
			angles = self.angles;

			if(level.awe_tripwireplanttime)
				planttime = level.awe_tripwireplanttime;
			else
				planttime = undefined;

			if(isdefined(planttime))
			{
				self disableWeapon();
				if(!isdefined(self.awe_plantbar))
				{
					barsize = 288;
					// Time for progressbar	
					bartime = planttime;

					if(isdefined(self.awe_tripwiremessage))	self.awe_tripwiremessage destroy();
					if(isdefined(self.awe_tripwiremessage2))	self.awe_tripwiremessage2 destroy();

					// Background
					self.awe_plantbarbackground = newClientHudElem(self);				
					self.awe_plantbarbackground.alignX = "center";
					self.awe_plantbarbackground.alignY = "top";
					self.awe_plantbarbackground.x = 320;
					self.awe_plantbarbackground.y = 405 - 6;
					self.awe_plantbarbackground.alpha = 0.5;
					self.awe_plantbarbackground.color = (0,0,0);
					self.awe_plantbarbackground setShader("white", (barsize + 4), 12);			
					// Progress bar
					self.awe_plantbar = newClientHudElem(self);				
					self.awe_plantbar.alignX = "left";
					self.awe_plantbar.alignY = "top";
					self.awe_plantbar.x = (320 - (barsize / 2.0));
					self.awe_plantbar.y = 405 - 4;
					self.awe_plantbar setShader("white", 0, 8);
					self.awe_plantbar scaleOverTime(bartime , barsize, 8);

					showTripwireMessage(sWeapon, level.awe_turretplacingmessage);

					// Play plant sound
					self playsound("moody_plant");
				}

				color = 1;
				for(i=0;i<planttime*20;i++)
				{
					if( !(self useButtonPressed() && origin == self.origin && isAlive(self) && self.sessionstate=="playing" && !isdefined(self.progressbar) ) )
						break;
					self.awe_plantbar.color = (1,color,color);
					color -= 0.05 / planttime;
					wait 0.05;
				}

				// Remove hud elements
				if(isdefined(self.awe_plantbarbackground)) self.awe_plantbarbackground destroy();
				if(isdefined(self.awe_plantbar))		 self.awe_plantbar destroy();
				if(isdefined(self.awe_tripwiremessage))	self.awe_tripwiremessage destroy();
				if(isdefined(self.awe_tripwiremessage2))	self.awe_tripwiremessage2 destroy();
		
				self enableWeapon();
				if(i<planttime*20)
					return false;
			}

			// Check tripwire limit
			if(level.awe_teamplay)
			{
				if(level.awe_tripwires[self.sessionteam]>=level.awe_tripwirelimit)
				{
					self iprintlnbold(&"AWE_MAX_TRIPWIRES_TEAM");
					return false;
				}
			}
			else
			{
				if(level.awe_tripwires>=level.awe_tripwirelimit*2)
				{
					self iprintlnbold(&"AWE_MAX_TRIPWIRES");
					return false;
				}
			}

			if(level.awe_teamplay)
				level.awe_tripwires[self.sessionteam]++;
			else
				level.awe_tripwires++;

			// Calc new center
			x = (vPos1[0] + vPos2[0])/2;
			y = (vPos1[1] + vPos2[1])/2;
			z = (vPos1[2] + vPos2[2])/2;
			vPos = (x,y,z);

			// Decrease grenade ammo
			if(myammo)	// Did we use my own grenades?
			{
				myammo--;
				if(myammo)		// Did both come from my own team?
				{
					myammo--;
					if(myammo)	// Any nades left?
						self setWeaponClipAmmo(sWeapon, myammo);	// Decrease ammo
					else		// No nades left, remove weapon and ammo
					{
						self takeWeapon(sWeapon);
						self setWeaponClipAmmo(sWeapon, 0);
					}
				}
				else		// Second grenade was the other teams
				{
					self takeWeapon(sWeapon);	// remove my nades
					self setWeaponClipAmmo(sWeapon, 0);
					otherammo--;	// Decrease ammo for the other kind
					if(otherammo)	// Any nade left?
						self setWeaponClipAmmo(sWeapon2, otherammo);	// Decrease ammo
					else	// Out of nades, remove weapon and ammo
					{
						self takeWeapon(sWeapon2);
						self setWeaponClipAmmo(sWeapon2, 0);
					}
				}
			}
			else	// Both nades where from the other team
			{
				otherammo -= 2;
				if(otherammo)	// nades left?
					self setWeaponClipAmmo(sWeapon, otherammo);
				else
				{
					self takeWeapon(sWeapon);
					self setWeaponClipAmmo(sWeapon, 0);
				}
			}

			// Spawn tripwire
			tripwire = spawn("script_origin",vPos);
			tripwire.angles = angles;
			tripwire thread monitorTripwire(self, sWeapon, sWeapon2, vPos1, vPos2);
			break;
		}
		wait( 0.2 );
	}
	if(isdefined(self.awe_tripwiremessage))	self.awe_tripwiremessage destroy();
	if(isdefined(self.awe_tripwiremessage2))	self.awe_tripwiremessage2 destroy();
}

tripwireWarning()
{
	if(self.awe_tripwirewarning)
		return;
	self.awe_tripwirewarning = true;
	self iprintlnbold(&"AWE_WARNING_TRIPWIRE");
	wait 5;
	self.awe_tripwirewarning = false;
}

monitorTripwire(owner, sWeapon, sWeapon2, vPos1, vPos2)
{
	level endon("awe_killthreads");
	self endon("awe_monitortripwire");

	// Save old team if teamplay
	if(level.awe_teamplay)
		self.oldteam = owner.sessionteam;

	wait .05;

	if(randomInt(2))
	{
		temp = sWeapon;
		sWeapon = sWeapon2;
		sWeapon2 = temp;
	}

	// Spawn nade one
	self.nade1 = spawn("script_model",vPos1);
	self.nade1 setModel(awe\_util::getGrenadeModel(sWeapon));
	self.nade1.angles = self.angles;
	self.nade1.triptype = sWeapon;

	// Spawn nade two
	self.nade2 = spawn("script_model",vPos2);
	self.nade2 setModel(awe\_util::getGrenadeModel(sWeapon2));
	self.nade2.angles = self.angles;
	self.nade2.triptype = sWeapon2;

	// Get detection spots
	vPos3 = self.origin + maps\mp\_utility::vectorScale(anglesToForward(self.angles),50);
	vPos4 = self.origin + maps\mp\_utility::vectorScale(anglesToForward(self.angles + (0,180,0)),50);

	// Get detection ranges
	range = distance(self.origin, vPos1) + 150;
	range2 = distance(vPos3,vPos1) + 2;

	if(isDefined(owner) && isAlive(owner) && owner.sessionstate == "playing")
		owner iprintlnbold(&"AWE_TRIPWIRE_ACTIVATES");

	wait 5;

	for(;;)
	{
		blow = false;

		// Loop through players to find out if one has triggered the wire
		for(i=0;i<level.awe_allplayers.size && !blow;i++)
		{
			// Check that player still exist
			if(isDefined(level.awe_allplayers[i]))
				player = level.awe_allplayers[i];
			else
				continue;

			// Player? Alive? Playing?
			if(!isPlayer(player) || !isAlive(player) || player.sessionstate != "playing")
				continue;
			
			// Within range?
			distance = distance(self.origin, player.origin);
			if(distance>=range)
				continue;

			// Check for defusal
			if(!player.awe_checkdefusetripwire)
				player thread checkDefuseTripwire(self);

			// Warm if same team?
			if(isDefined(self.oldteam) && self.oldteam == player.sessionteam && !player.awe_tripwirewarning)
			{
				// Stop check if tripwire is safe for teammates.
				if(level.awe_tripwire==3)
					continue;
				else if(level.awe_tripwirewarning && (distance((0,0,player.origin[2]),(0,0,self.origin[2])) <= 60) )
					player thread tripwireWarning();
			}

			// Within sphere one?
			distance = distance(vPos3, player.origin);
			if(distance>=range2)
				continue;

			// Within sphere two?
			distance = distance(vPos4, player.origin);
			if(distance>=range2)
				continue;

			// Time to blow
			blow = true;
			break;
		}
		// Time to blow?
		if(blow) break;
		wait .05;
	}

	if(level.awe_teamplay)
		level.awe_tripwires[self.oldteam]--;
	else
		level.awe_tripwires--;

	self.nade1 playsound("weap_fraggrenade_pin");
	wait(.05);
	self.nade2 playsound("weap_fraggrenade_pin");
	wait(.05);

	wait(randomFloat(.5));

	// Check that damage owner till exists
	if(isDefined(owner) && isPlayer(owner))
	{
		// I player has switched team and it's teamplay the tripwire is unowned.
		if(isdefined(self.oldteam) && self.oldteam == owner.sessionteam)
			eAttacker = owner;
		else if(!isdefined(self.oldteam))		//Not teamplay
			eAttacker = owner;
		else						//Player has switched team
			eAttacker = self;
	}
	else
		eAttacker = self;

	iMaxdamage = 200;
	iMindamage = 50;

	if(isdefined(level.awe_dmgmod[sWeapon]))
	{
		iMaxdamage = iMaxdamage * level.awe_dmgmod[sWeapon];
		iMindamage = iMindamage * level.awe_dmgmod[sWeapon];
	}

	// play the hit sound
	self.nade1 playsound("grenade_explode_default");
	// Blow number one
	playfx(level._effect["bombexplosion"], self.nade1.origin);
	self.nade1 awe\_util::scriptedRadiusDamage(eAttacker, (0,0,0), sWeapon, 256, iMaxdamage, iMindamage, (level.awe_tripwire>1) );
	wait .05;
	self.nade1 delete();

	// A small, random, delay between the nades
	wait(randomFloat(.25));

	// play the hit sound
	self.nade2 playsound("grenade_explode_default");
	// Blow number two
	playfx(level._effect["bombexplosion"], self.nade2.origin);
	self.nade2 awe\_util::scriptedRadiusDamage(eAttacker, (0,0,0), sWeapon, 256, iMaxdamage, iMindamage, (level.awe_tripwire>1) );
	wait .05;
	self.nade2 delete();
	self delete();
}

checkDefuseTripwire(tripwire)
{
	level endon("awe_killthreads");
	self endon("awe_killthreads");

	// Make sure to only run one instance
	if(self.awe_checkdefusetripwire)
		return;

	range = 20;

	// Check prone
	if(self.awe_stance != 2) return;

	// Is it defusable?
	if(level.awe_teamplay && self.sessionteam == tripwire.oldteam && !level.awe_tripwirepicktimesameteam) // Teamplay and same team and no defuse time
		return;
	else if((!level.awe_teamplay || self.sessionteam != tripwire.oldteam) && !level.awe_tripwirepicktimeotherteam)	// Non teamplay or other team AND no defuse time
		return;

	// Check nades
	distance1 = distance(tripwire.nade1.origin, self.origin);
	distance2 = distance(tripwire.nade2.origin, self.origin);
	if(distance1>=range && distance2>=range) return;

	if(distance1<range)
	{
		sWeapon = tripwire.nade1.triptype;
		sWeapon2 = tripwire.nade2.triptype;
	}
	else
	{
		sWeapon = tripwire.nade2.triptype;
		sWeapon2 = tripwire.nade1.triptype;
	}
	
	// Ok to defuse, kill checkTripwirePlacement and set up new hud message
	self notify("awe_checktripwireplacement");

	self.awe_checkdefusetripwire = true;

	// Remove hud elements
	if(isdefined(self.awe_plantbarbackground)) self.awe_plantbarbackground destroy();
	if(isdefined(self.awe_plantbar))		 self.awe_plantbar destroy();
	if(isdefined(self.awe_tripwiremessage))	self.awe_tripwiremessage destroy();
	if(isdefined(self.awe_tripwiremessage2))	self.awe_tripwiremessage2 destroy();

	// Set up new
	showTripwireMessage(sWeapon, level.awe_tripwirepickupmessage);

	// Loop
	for(;;)
	{
		if( isAlive( self ) && self.sessionstate == "playing" && self useButtonPressed() && !isdefined(self.progressbar))
		{
			// Ok to plant, show progress bar
			origin = self.origin;
			angles = self.angles;

			if (level.awe_teamplay && self.sessionteam == tripwire.oldteam)
			{
				if(level.awe_tripwirepicktimesameteam)
					planttime = level.awe_tripwirepicktimesameteam;
				else
					planttime = undefined;
			}
			else
			{
				if(level.awe_tripwirepicktimeotherteam)
					planttime = level.awe_tripwirepicktimeotherteam;
				else
					planttime = undefined;
			}

			if(isdefined(planttime))
			{
				self disableWeapon();
				if(!isdefined(self.awe_plantbar))
				{
					barsize = 288;
					// Time for progressbar	
					bartime = planttime;

					if(isdefined(self.awe_tripwiremessage))	self.awe_tripwiremessage destroy();
					if(isdefined(self.awe_tripwiremessage2))	self.awe_tripwiremessage2 destroy();

					// Background
					self.awe_plantbarbackground = newClientHudElem(self);				
					self.awe_plantbarbackground.alignX = "center";
					self.awe_plantbarbackground.alignY = "top";
					self.awe_plantbarbackground.x = 320;
					self.awe_plantbarbackground.y = 405 - 6;
					self.awe_plantbarbackground.alpha = 0.5;
					self.awe_plantbarbackground.color = (0,0,0);
					self.awe_plantbarbackground setShader("white", (barsize + 4), 12);			
					// Progress bar
					self.awe_plantbar = newClientHudElem(self);				
					self.awe_plantbar.alignX = "left";
					self.awe_plantbar.alignY = "top";
					self.awe_plantbar.x = (320 - (barsize / 2.0));
					self.awe_plantbar.y = 405 - 4;
					self.awe_plantbar setShader("white", 0, 8);
					self.awe_plantbar scaleOverTime(bartime , barsize, 8);

					showTripwireMessage(sWeapon, level.awe_turretpickingmessage);

					// Play plant sound
					self playsound("moody_plant");
				}

				color = 1;
				for(i=0;i<planttime*20 && isdefined(tripwire);i++)
				{
					if( !(self useButtonPressed() && origin == self.origin && isAlive(self) && self.sessionstate=="playing" && !isdefined(self.progressbar) ) )
						break;

					if(isdefined(self.awe_plantbar))
						self.awe_plantbar.color = (color,1,color);

					color -= 0.05 / planttime;
					wait 0.05;
				}

				// Remove hud elements
				if(isdefined(self.awe_plantbarbackground)) self.awe_plantbarbackground destroy();
				if(isdefined(self.awe_plantbar))		 self.awe_plantbar destroy();
				if(isdefined(self.awe_tripwiremessage))	self.awe_tripwiremessage destroy();
				if(isdefined(self.awe_tripwiremessage2))	self.awe_tripwiremessage2 destroy();
		
				self enableWeapon();
				if(i<planttime*20 || !isdefined(tripwire))
				{
					self.awe_checkdefusetripwire = false;
					return;
				}
			}

			if(level.awe_teamplay)
				level.awe_tripwires[tripwire.oldteam]--;
			else
				level.awe_tripwires--;
			// Remove tripwire
			tripwire notify("awe_monitortripwire");
			wait .05;
			if(isdefined(tripwire.nade1))
				tripwire.nade1 delete();
			if(isdefined(tripwire.nade2))
				tripwire.nade2 delete();
			if(isdefined(tripwire))
				tripwire delete();

			// Pick up grenades
			ammo = self getammocount(sWeapon);
			if(!ammo)	self giveWeapon(sWeapon);
			ammo++;
			self setWeaponClipAmmo(sWeapon, ammo);

			ammo = self getammocount(sWeapon2);
			if(!ammo)	self giveWeapon(sWeapon2);
			ammo++;
			self setWeaponClipAmmo(sWeapon2, ammo);

			break;
		}
		wait .05;

		// Check prone
		if(self.awe_stance != 2) break;
		// Check nades
		if(!isdefined(tripwire.nade1) || !isdefined(tripwire.nade2))
			break;
		distance1 = distance(tripwire.nade1.origin, self.origin);
		distance2 = distance(tripwire.nade2.origin, self.origin);
		if(distance1>=range && distance2>=range) break;
	}

	// Clean up
	if(isdefined(self.awe_plantbarbackground)) self.awe_plantbarbackground destroy();
	if(isdefined(self.awe_plantbar))		 self.awe_plantbar destroy();
	if(isdefined(self.awe_tripwiremessage))	self.awe_tripwiremessage destroy();
	if(isdefined(self.awe_tripwiremessage2))	self.awe_tripwiremessage2 destroy();

	self.awe_checkdefusetripwire = false;
}

showTripwireMessage(sWeapon, which_message )
{
	if(isdefined(self.awe_tripwiremessage))	self.awe_tripwiremessage destroy();
	if(isdefined(self.awe_tripwiremessage2))	self.awe_tripwiremessage2 destroy();

	self.awe_tripwiremessage = newClientHudElem( self );
	self.awe_tripwiremessage.alignX = "center";
	self.awe_tripwiremessage.alignY = "middle";
	self.awe_tripwiremessage.x = 320;
	self.awe_tripwiremessage.y = 404;
	self.awe_tripwiremessage.alpha = 1;
	self.awe_tripwiremessage.fontScale = 0.80;
	if( 	(isdefined(level.awe_turretpickingmessage) && which_message == level.awe_turretpickingmessage) ||
		(isdefined(level.awe_turretplacingmessage) && which_message == level.awe_turretplacingmessage) )
		self.awe_tripwiremessage.color = (.5,.5,.5);
	self.awe_tripwiremessage setText( which_message );

	self.awe_tripwiremessage2 = newClientHudElem(self);
	self.awe_tripwiremessage2.alignX = "center";
	self.awe_tripwiremessage2.alignY = "top";
	self.awe_tripwiremessage2.x = 320;
	self.awe_tripwiremessage2.y = 415;
	self.awe_tripwiremessage2 setShader(awe\_util::getGrenadeHud(sWeapon),40,40);
}
