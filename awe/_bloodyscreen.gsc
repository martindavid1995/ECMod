init()
{
	level.awe_bloodyscreen		= awe\_util::cvardef("awe_bloodyscreen", 0, 0, 1, "int");

	if(!level.awe_bloodyscreen)		return;

	// Precache
	if(!isdefined(game["gamestarted"]))
	{
		precacheShader("gfx/impact/flesh_hit2");
		precacheShader("gfx/impact/flesh_hitgib");
	}
}

CleanupSpawned()
{
	if(!level.awe_bloodyscreen)		return;

	// Remove bloody screen
	if (isDefined(self.awe_bloodyscreen))	self.awe_bloodyscreen destroy();
	if (isDefined(self.awe_bloodyscreen1))	self.awe_bloodyscreen1 destroy();
	if (isDefined(self.awe_bloodyscreen2))	self.awe_bloodyscreen2 destroy();
	if (isDefined(self.awe_bloodyscreen3))	self.awe_bloodyscreen3 destroy();
}

Splatter_View()
{
	self endon("kill_threads");

	if(!level.awe_bloodyscreen)		return;

	if(!isDefined(self.awe_bloodyscreen))
	{
		self.awe_bloodyscreen = newClientHudElem(self);
		self.awe_bloodyscreen1 = newClientHudElem(self);
		self.awe_bloodyscreen2 = newClientHudElem(self);
		self.awe_bloodyscreen3 = newClientHudElem(self);

		self.awe_bloodyscreen.alignX = "left";
		self.awe_bloodyscreen.alignY = "top";
	
		self.awe_bloodyscreen1.alignX = "left";
		self.awe_bloodyscreen1.alignY = "top";

		self.awe_bloodyscreen2.alignX = "left";
		self.awe_bloodyscreen2.alignY = "top";
		
		self.awe_bloodyscreen3.alignX = "left";
		self.awe_bloodyscreen3.alignY = "top";
		
		bs1 = (randomint(496));
		bs2 = (randomint(336));
		bs1a = (randomint(496));
		bs2a = (randomint(336));
		bs1b = (randomint(496));
		bs2b = (randomint(336));
		bs1c = (randomint(496));
		bs2c = (randomint(336));

		self.awe_bloodyscreen.x = bs1;
		self.awe_bloodyscreen.y = bs2;

		self.awe_bloodyscreen1.x = bs1a;
		self.awe_bloodyscreen1.y = bs2a;

		self.awe_bloodyscreen2.x = bs1b;
		self.awe_bloodyscreen2.y = bs2b;

		self.awe_bloodyscreen3.x = bs1c;
		self.awe_bloodyscreen3.y = bs2c;

		bs3 = randomint(48);
		bs3a = randomint(48);
		bs3b = randomint(48);
		bs3c = randomint(48);
		self.awe_bloodyscreen.color = (1,1,1);
		self.awe_bloodyscreen1.color = (1,1,1);
		self.awe_bloodyscreen2.color = (1,1,1);
		self.awe_bloodyscreen3.color = (1,1,1);
		self.awe_bloodyscreen.alpha = 1;
		self.awe_bloodyscreen1.alpha = 1;
		self.awe_bloodyscreen2.alpha = 1;
		self.awe_bloodyscreen3.alpha = 1;

		self.awe_bloodyscreen SetShader("gfx/impact/flesh_hit2",96 + bs3 , 96 + bs3);
		self.awe_bloodyscreen1 SetShader("gfx/impact/flesh_hitgib",96 + bs3a , 96 + bs3a);
		self.awe_bloodyscreen2 SetShader("gfx/impact/flesh_hit2",96 + bs3b , 96 + bs3b);
		self.awe_bloodyscreen3 SetShader("gfx/impact/flesh_hitgib",96 + bs3c , 96 + bs3c);

		wait (4);

		if(!isdefined(self.awe_bloodyscreen))
			return;

		self.awe_bloodyscreen fadeOverTime (2); 
		self.awe_bloodyscreen.alpha = 0;
		self.awe_bloodyscreen1 fadeOverTime (2);
		self.awe_bloodyscreen1.alpha = 0;
		self.awe_bloodyscreen2 fadeOverTime (2);
		self.awe_bloodyscreen2.alpha = 0;
		self.awe_bloodyscreen3 fadeOverTime (2);
		self.awe_bloodyscreen3.alpha = 0;
		wait(2);
		// Remove bloody screen
		if (isDefined(self.awe_bloodyscreen))	self.awe_bloodyscreen destroy();
		if (isDefined(self.awe_bloodyscreen1))	self.awe_bloodyscreen1 destroy();
		if (isDefined(self.awe_bloodyscreen2))	self.awe_bloodyscreen2 destroy();
		if (isDefined(self.awe_bloodyscreen3))	self.awe_bloodyscreen3 destroy();
	}
}
