init()
{
////////// Added for AWE ///////////
	level.awe_damagefeedback	= awe\_util::cvardef("awe_damage_feedback", 1, 0, 1, "int");
	if(!level.awe_damagefeedback)
		return;
////////////////////////////////////

	precacheShader("damage_feedback");

	level thread onPlayerConnect();
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill("connecting", player);

		player.hud_damagefeedback = newClientHudElem(player);
		player.hud_damagefeedback.horzAlign = "center";
		player.hud_damagefeedback.vertAlign = "middle";
		player.hud_damagefeedback.x = -12;
		player.hud_damagefeedback.y = -12;
		player.hud_damagefeedback.alpha = 0;
		player.hud_damagefeedback.archived = true;
		player.hud_damagefeedback setShader("damage_feedback", 24, 24);
	}
}

updateDamageFeedback()
{
////////// Added for AWE ///////////
	if(!level.awe_damagefeedback)
		return;
////////////////////////////////////

	if(isPlayer(self))
	{
		self.hud_damagefeedback.alpha = 1;
		self.hud_damagefeedback fadeOverTime(1);
		self.hud_damagefeedback.alpha = 0;
		self playlocalsound("MP_hit_alert");
	}
}