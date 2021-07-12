init()
{
	level.awe_healthpacks		= awe\_util::cvardef("awe_healthpacks", 0, 0, 2, "int");

	if(!level.awe_healthpacks) 
		return;

	level.awe_healthpacksmin	= awe\_util::cvardef("awe_healthpacks_min", 15, 1, 100, "int");
	level.awe_healthpacksmax	= awe\_util::cvardef("awe_healthpacks_max", 65, level.awe_healthpacksmin, 100, "int");

	// Set up object queue
	level.awe_objectQ["healthpack"] = [];
	level.awe_objectQcurrent["healthpack"] = 0;
	level.awe_objectQsize["healthpack"] = 16;

	// Precache possible models
	if(!isdefined(game["gamestarted"]))
	{
		if(level.awe_healthpacksmin<20)						precacheModel("xmodel/health_small");
		if(level.awe_healthpacksmax>=50)						precacheModel("xmodel/health_large");
		if(level.awe_healthpacksmin<50 && level.awe_healthpacksmax>=20)	precacheModel("xmodel/health_medium");
	}
}

dropHealth(alive)
{
	if(!level.awe_healthpacks) 
		return;

//	if(self.awe_nohealthpack)
//		return;
//	self.awe_nohealthpack = true;

	// Use an offset if an alive player drops health
	if(isdefined(alive))
		offset = maps\mp\_utility::vectorScale(anglestoforward(self.angles), 40 ) + (0,0,32);
	else
		offset = maps\mp\_utility::vectorScale(anglestoforward(self.angles + (0,-90 + randomInt(2)*180,0)), 10 + randomInt(8) ) + (0,0,32);
	
	// Find ground
	origin = awe\_util::FindGround(self.origin + offset);

	// Randomize health
	diff = level.awe_healthpacksmax-level.awe_healthpacksmin;
	if(diff > 0)
		health = level.awe_healthpacksmin + randomInt(diff+1);
	else
		health = level.awe_healthpacksmin;

	// Decide which model
	if(health<20)
		model = "xmodel/health_small";
	else if(health>=50)
		model = "xmodel/health_large";
	else	
		model = "xmodel/health_medium";

	// Spawn model
	healthpack = spawn("script_model", origin);
	healthpack setModel(model);
	healthpack thread healthpack_think(health);
}

healthpack_think(health)
{
	level endon("awe_killthreads");
	self endon("awe_healthpack");

	self thread awe\_util::putinQ("healthpack");

	for(;;)
	{
		// Loop through all players
		for(i=0;i<level.awe_allplayers.size;i++)
		{
			// Check that player still exist
			if(isDefined(level.awe_allplayers[i]))
				player = level.awe_allplayers[i];
			else
				continue;

			// Player? Alive? Playing? Wounded?
			if(!isPlayer(player) || !isAlive(player) || player.sessionstate != "playing" || player.health==100)
				continue;

			// Check that healthpack still exist
			if(!isdefined(self))
				return;
			
			// Within range?
			distance = distance(self.origin, player.origin);
			if(distance>=20)
				continue;

			// Wounded player in range, let him get some health
			newhealth = player.health + health;
			if(newhealth>100) newhealth = 100;
			player.health = newhealth;
			player awe\_healthbar::UpdateHealthBar();

			if(level.awe_healthpacks != 2)
				player iprintln(&"AWE_PICKED_HEALTH");

			// Play sound
			player  playsound("health_pickup_medium");

			// Delete healthpack
			self delete();

			// End this thread
			return;
		}
		wait .05;
	}
}
