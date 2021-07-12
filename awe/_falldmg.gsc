init()
{
	level.awe_falldamage = awe\_util::cvardef("awe_falldamage", 0, 0, 1, "int");
	if(!level.awe_falldamage) return;

	level.awe_minfallheight = awe\_util::cvardef("awe_minfallheight",256,1,1000,"int");
	level.awe_maxfallheight = awe\_util::cvardef("awe_maxfallheight",480,level.awe_minfallheight,1000,"int");

	setcvar("bg_fallDamageMinHeight", level.awe_minfallheight);
	setcvar("bg_fallDamageMaxHeight", level.awe_maxfallheight); 
} 