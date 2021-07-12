init()
{
	// welcome message
	level.awe_welcomedelay		= awe\_util::cvardef("awe_welcome_delay", 1, 0.05, 30, "float");
}

Cleanup()
{
	if(!isdefined(self.pers["awe_welcomed"]))		self.pers["awe_welcomed"] = false;
}

RunOnSpawn()
{
	self thread ShowWelcomeMessages();
}

ShowWelcomeMessages()
{
	self endon("awe_killthreads");

	if(getcvar("awe_welcome0") == "")
		return;

	// Allready has been welcomed?
	if(self.pers["awe_welcomed"])
		return;
	
	// Flag player as having been welcomed
	self.pers["awe_welcomed"] = true;

	wait 2;

	count = 0;
	message = awe\_util::cvardef("awe_welcome" + count, "", "", "", "string");
	while(message != "")
	{
		self iprintlnbold(message);
		count++;
		message = awe\_util::cvardef("awe_welcome" + count, "", "", "", "string");
		wait level.awe_welcomedelay;
	}
}
