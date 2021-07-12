init()
{
	level.awe_laserdot	= awe\_util::cvardef("awe_laserdot", 0, 0, 2, "int");

	if(!level.awe_laserdot) return;

	if(level.awe_laserdot == 1)
		size = 10;
	else
		size = 2;

	level.awe_laserdotsize	= awe\_util::cvardef("awe_laserdot_size", size, 0, 99, "int");
	level.awe_laserdotalpha	= awe\_util::cvardef("awe_laserdot_alpha", 0.8, 0, 1, "float");
	level.awe_laserdotred	= awe\_util::cvardef("awe_laserdot_red", 1, 0, 1, "float");
	level.awe_laserdotgreen	= awe\_util::cvardef("awe_laserdot_green", 0, 0, 1, "float");
	level.awe_laserdotblue	= awe\_util::cvardef("awe_laserdot_blue", 0, 0, 1, "float");

	// Precache
	if(!isdefined(game["gamestarted"]))
	{
		if(level.awe_laserdot == 1)
			precacheShader("compassping_enemyfiring");
		else
			precacheShader("white");
	}
}

CleanupKilled()
{
	if(!level.awe_laserdot) return;

	if(isdefined(self.awe_laserdot))		self.awe_laserdot destroy();
}

RunOnSpawn()
{
	if(!level.awe_laserdot) return;

	if(level.awe_laserdot == 1)
	{
		shader = "compassping_enemyfiring";
		y = 240;
		color = (1,1,1);
	}
	else
	{
		shader = "white";
		y = 242;
		color = (level.awe_laserdotred,level.awe_laserdotgreen,level.awe_laserdotblue);
	}

	if(!isdefined(self.awe_laserdot))
	{
		self.awe_laserdot = newClientHudElem( self );
		self.awe_laserdot setShader(shader, level.awe_laserdotsize, level.awe_laserdotsize);
		self.awe_laserdot.alignX = "center";
		self.awe_laserdot.alignY = "middle";
		self.awe_laserdot.alpha = level.awe_laserdotalpha;
		self.awe_laserdot.color = color;
		self.awe_laserdot.x = 320;
		self.awe_laserdot.y = y;
	}
}
