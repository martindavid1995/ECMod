init()
{
	// Anti teamkilling
	level.awe_teamkillmax		= awe\_util::cvardef("awe_teamkill_max", 3, 0, 99, "int");

	if(!level.awe_teamkillmax) return;

	level.awe_teamkillwarn		= awe\_util::cvardef("awe_teamkill_warn", 1, 0, 99, "int");
	level.awe_teamkillmethod	= awe\_util::cvardef("awe_teamkill_method", 3, 0, level.awe_punishments+1, "int");
	level.awe_teamkillreflect	= awe\_util::cvardef("awe_teamkill_reflect", 1, 0, 1, "int");
	level.awe_teamkillmsg 		= awe\_util::cvardef("awe_teamkill_msg","^6Good damnit! ^7Learn the difference between ^4friend ^7and ^1foe ^7you bastard!.","","","string");

	
	if(level.awe_teamkillmethod == 1 || level.awe_teamkillmethod == 4)
	{
		if(!isdefined(game["gamestarted"]))
		{
			// Precache crushmodels
			for(i=0;i<level.awe_crushmodels.size;i++)
				precacheModel("xmodel/" + level.awe_crushmodels[i]);

		}
		level.awe_objectQ["piano"] = [];
		level.awe_objectQcurrent["piano"] = 0;
		level.awe_objectQsize["piano"] = 2;
		level._effect["awe_dustimpact"] = loadfx("fx/dust/dust_impact_med.efx");
	}
}

Cleanup()
{
	if(!isdefined(self.pers["awe_teamkills"]))	self.pers["awe_teamkills"] = 0;
	if(!isdefined(self.pers["awe_teamkiller"]))	self.pers["awe_teamkiller"] = false;
}

TeamKill()
{
	if (!level.awe_teamkillmax)
		return;

	// Increase value
	self.pers["awe_teamkills"]++;
	
	// Check if it reached or passed the max level
	if (self.pers["awe_teamkills"]>=level.awe_teamkillmax)
	{
		if(level.awe_teamkillmethod)
			iprintln(self.name + " ^7has killed ^1" + self.pers["awe_teamkills"] + " ^7teammate(s) and will be punished.");
		if(level.awe_teamkillreflect)
			iprintln(self.name + " ^7has killed ^1" + self.pers["awe_teamkills"] + " ^7teammate(s) and will reflect damage.");

		self iprintlnbold(level.awe_teamkillmsg);
		self thread awe\_util::PunishMe(level.awe_teamkillmethod, "teamkilling");
		if(level.awe_teamkillreflect)
			self.pers["awe_teamkiller"] = true;
	}
	// Check if it reached or passed the warning level
	else if (self.pers["awe_teamkills"]>=level.awe_teamkillwarn)
	{
		if(level.awe_teamkillmethod)
			self iprintlnbold(level.awe_teamkillmax - self.pers["awe_teamkills"] + " ^7more teamkill(s) and you will be ^1punished^7!");
		else if(level.awe_teamkillreflect)
			self iprintlnbold(level.awe_teamkillmax - self.pers["awe_teamkills"] + " ^7more teamkill(s) and you will reflect damage!");
		else 
			self iprintlnbold(level.awe_teamkillmax - self.pers["awe_teamkills"] + " ^7more teamkill(s) and nothing will happen!");
	}
}
