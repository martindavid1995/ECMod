init()
{
	// Logos
	level.awe_showlogo 		= awe\_util::cvardef("awe_show_logo", 1, 0, 1, "int");	
	level.awe_showserverlogo 	= awe\_util::cvardef("awe_show_server_logo", 0, 0, 2, "int");	

	// Setup logos	
	//level.awe_logotext = &"^6AWE ^53.0 ^3CE";
	level.awe_logotext = "";
	if(level.awe_showserverlogo)
		server_logo\_awe_server_logo::logo();

	if(level.awe_showserverlogo)
	{
		if(isdefined(level.awe_serverlogo))
			level.awe_serverlogo destroy();

		level.awe_serverlogo = newHudElem();	
		if(level.awe_showserverlogo == 1)
		{
			level.awe_serverlogo.x = 630;
			level.awe_serverlogo.alignX = "right";
		}
		else
		{
			level.awe_serverlogo.x = 320;
			level.awe_serverlogo.alignX = "center";
		}
		level.awe_serverlogo.y = 475;

		level.awe_serverlogo.alignY = "middle";
		level.awe_serverlogo.sort = -3;
		level.awe_serverlogo.alpha = 1;
		level.awe_serverlogo.fontScale = 0.7;
		level.awe_serverlogo.archived = true;
		level.awe_serverlogo setText(level.awe_serverlogotext);
	}

	if(level.awe_showlogo)
	{
		if(isdefined(level.awe_logo))
			level.awe_logo destroy();

		level.awe_logo = newHudElem();	
		level.awe_logo.x = 3;
		level.awe_logo.y = 475;
		level.awe_logo.alignX = "left";
		level.awe_logo.alignY = "middle";
		level.awe_logo.sort = -3;
		level.awe_logo.alpha = 1;
		level.awe_logo.fontScale = 0.7;
		level.awe_logo.archived = true;
		level.awe_logo setText(level.awe_logotext);
	}
}
