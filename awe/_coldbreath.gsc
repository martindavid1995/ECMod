init()
{
	// Cold breath
	level.awe_coldbreath		= awe\_util::cvardef("awe_cold_breath", 0, 0, 1, "int");

	if(!level.awe_coldbreath || !level.awe_wintermap) return;

	// Load breath fx
	level.awe_breathfx = loadfx ("fx/misc/cold_breath.efx");
}

RunOnSpawn()
{
	if(!level.awe_coldbreath || !level.awe_wintermap) return;

	self thread breath_fx();
}

breath_fx()
{
	self endon("awe_killthreads");

	wait (2 + randomint(3));

	while(isalive(self) && self.sessionstate == "playing")
	{
		playfxontag (level.awe_breathfx, self, "J_Head");
		wait randomfloatrange(1.5,3.5);
	}
}

