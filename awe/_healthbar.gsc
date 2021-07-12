init()
{
	// Show healthbar
	level.awe_showhealthbar		= awe\_util::cvardef("awe_show_health_bar", 0, 0, 1, "int");
	if(!level.awe_showhealthbar)		return;

	if(!isdefined(game["gamestarted"]))
	{
		// Precache healthbar
		precacheShader("gfx/hud/hud@health_back.tga");
		precacheShader("gfx/hud/hud@health_bar.tga");
		precacheShader("gfx/hud/hud@health_cross.tga");
	}
}

CleanupKilled()
{
	if(!level.awe_showhealthbar)		return;

	if(isdefined(self.awe_healthbar))		self.awe_healthbar destroy();
	if(isdefined(self.awe_healthbar_back))	self.awe_healthbar_back destroy();
	if(isdefined(self.awe_healthbar_cross))	self.awe_healthbar_cross destroy();
}

RunOnSpawn()
{
	if(!level.awe_showhealthbar)		return;

	// Create healtbar
	x = 502;
	y = 471;
	maxwidth = 128;

	self.awe_healthbar_back = newClientHudElem( self );
	self.awe_healthbar_back setShader("gfx/hud/hud@health_back.tga", maxwidth + 2, 7);
	self.awe_healthbar_back.alignX = "left";
	self.awe_healthbar_back.alignY = "top";
	self.awe_healthbar_back.x = x;
	self.awe_healthbar_back.y = y;

	self.awe_healthbar_cross = newClientHudElem( self );
	self.awe_healthbar_cross setShader("gfx/hud/hud@health_cross.tga", 7, 7);
	self.awe_healthbar_cross.alignX = "right";
	self.awe_healthbar_cross.alignY = "top";
	self.awe_healthbar_cross.x = x - 1;
	self.awe_healthbar_cross.y = y;

	self.awe_healthbar = newClientHudElem( self );
	self.awe_healthbar setShader("gfx/hud/hud@health_bar.tga", maxwidth, 5);
	self.awe_healthbar.color = ( 0, 1, 0);
	self.awe_healthbar.alignX = "left";
	self.awe_healthbar.alignY = "top";
	self.awe_healthbar.x = x + 1;
	self.awe_healthbar.y = y + 1;
}

UpdateHealthBar()
{
	if(!level.awe_showhealthbar || !isdefined(self.awe_healthbar)) 
		return;

	x = 502;
	y = 471;
	maxwidth = 128;

	health = self.health / self.maxhealth;

	hud_width = int(health * maxwidth);
			
	if ( hud_width < 1 )
		hud_width = 1;
			
	self.awe_healthbar setShader("gfx/hud/hud@health_bar.tga", hud_width, 5);
	self.awe_healthbar.color = ( 1.0 - health, health, 0);
}
