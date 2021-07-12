init()
{
	// Is AWE enabled?
	level.awe_disable = awe\_util::cvardef("awe_disable",0,0,1,"int");
	if(level.awe_disable)
		return;

	// Override callbacks
	level.awe_callbackStartGameType = level.callbackStartGameType;
	level.awe_callbackPlayerConnect = level.callbackPlayerConnect;
	level.awe_callbackPlayerDisconnect = level.callbackPlayerDisconnect;
	level.awe_callbackPlayerDamage = level.callbackPlayerDamage;
	level.awe_callbackPlayerKilled = level.callbackPlayerKilled;

	level.callbackStartGameType = ::Callback_StartGameType;
	level.callbackPlayerConnect = ::Callback_PlayerConnect;
	level.callbackPlayerDisconnect = ::Callback_PlayerDisconnect;
	level.callbackPlayerDamage = ::Callback_PlayerDamage;
	level.callbackPlayerKilled = ::Callback_PlayerKilled;
}

Callback_StartGameType()
{
	awe\_global::init();
	[[level.awe_callbackStartGameType]]();
}

Callback_PlayerConnect()
{
	self endon("disconnect");
	self awe\_player::PlayerConnect();
	[[level.awe_callbackPlayerConnect]]();
}

Callback_PlayerDisconnect()
{
	self endon("disconnect");
	self awe\_player::PlayerDisconnect();
	[[level.awe_callbackPlayerDisconnect]]();
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	self endon("disconnect");

	iDamage = self awe\_player::PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

	if(iDamage>=0)
	{
	 	[[level.awe_callbackPlayerDamage]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
		awe\_player::PostPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
	}
	// Update healthbar
	if (isdefined(self) && isPlayer(self))
		self awe\_healthbar::UpdateHealthBar();
	if (isdefined(eAttacker) && isPlayer(eAttacker))
		eAttacker awe\_healthbar::UpdateHealthBar();
}

Callback_PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self endon("disconnect");
	self awe\_player::PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);
	[[level.awe_callbackPlayerKilled]](eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);
}