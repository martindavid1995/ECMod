warmup ()
{
	level.awe_warmup = awe\_util::cvardef ("awe_warmup", 0, 0, 120, "int");
	if (! level.awe_warmup)
		return;

	if (isdefined (game["warmup_over"]))
		return;

	precacheString (&"MP_WAITING_MATCH");
	precacheString (&"MP_MATCHSTARTING");
	
	level.awe_warmup_mess = newHudElem ();
	level.awe_warmup_mess.x = 320;
	level.awe_warmup_mess.y = 115;
	level.awe_warmup_mess.alignX = "center";
	level.awe_warmup_mess.alignY = "middle";
	level.awe_warmup_mess.fontscale = 2;
	level.awe_warmup_mess.color = (1, 1, 0);
	level.awe_warmup_mess.label = &"MP_WAITING_MATCH";
	
	level.awe_warmup_time = newHudElem ();
	level.awe_warmup_time.x = 320;
	level.awe_warmup_time.y = 180;
	level.awe_warmup_time.alignX = "center";
	level.awe_warmup_time.alignY = "middle";
	level.awe_warmup_time setClock (level.awe_warmup, level.awe_warmup, "hudstopwatch", 80, 80);
	
	wait level.awe_warmup;
	
	level.awe_warmup_time fadeOverTime (2);
	level.awe_warmup_time.alpha = 0;
	level.awe_warmup_time destroy ();

	level.awe_warmup_mess.label = &"MP_MATCHSTARTING";

	wait 2;

	level.awe_warmup_mess fadeOverTime (2);
	level.awe_warmup_mess.alpha = 0;
	level.awe_warmup_mess destroy ();
	
	players = getentarray ("player", "classname");
	for (i = 0; i < players.size; i++)
	{
		player = players[i];
		player.pers["score"] = 0;
		player.pers["deaths"] = 0;
	}

	game["alliedscore"] = 0;
	setTeamScore ("allies", 0);
	game["axisscore"] = 0;
	setTeamScore ("axis", 0);
	
	game["warmup_over"] = true;
	
	map_restart (true);
}

RunOnSpawn ()
{
	if (! level.awe_warmup)
		return;

	// Fix spectate permissions that got lost in the map_restart after warmup
	
	if (isdefined (game["warmup_over"]))
		self maps\mp\gametypes\_spectating::setSpectatePermissions ();

	// Fix the player HUD score that got lost	in the map_restart after warmup

	self notify ("update_playerhud_score");
}