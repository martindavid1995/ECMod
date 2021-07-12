init()
{
	// No bodies
	level.awe_removebodies		= awe\_util::cvardef("awe_remove_bodies",0,0,999,"float");
	level.awe_removebodiessink	= awe\_util::cvardef("awe_remove_bodies_sink",1,0,1,"int");

	// Precache
	if(!isdefined(game["gamestarted"]))
	{
	}
}

HandleDeadBody(team, owner)
{
	//Give the body a model
	self setModel(owner.model);

	// Death sound
	if(level.awe_deathsound)
	{
		nationality = game[team];
		num = randomInt(level.awe_voices[nationality]) + 1;
		scream = "generic_death_" + game[team] + "_" + num;
		self playSound(scream);
	}

	if(level.awe_removebodies)
		self thread RemoveBody(level.awe_removebodies);

	// Do an extra bloodfx for headpopped players
	if(owner.awe_headpopped)	self thread awe\_popping::delayedbloodfx();
}

RemoveBody(time)
{
	level endon("awe_killthreads");
	
	if(time<0.05) time = 0.05;

	wait time;

	if(isdefined(self))
	{
		if(level.awe_removebodiessink)
		{
			for(i=0;i<(5*20);i++)
			{
				if(!isdefined(self)) return;
				self.origin = self.origin - (0,0,0.2);
				wait .05;
			}

		}
		if(isdefined(self)) self delete();
	}
}



