init()
{
	// Damage modifiers
	// American 
	level.awe_dmgmod["greasegun_mp"]		= awe\_util::cvardef("awe_dmgmod_greasegun_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["m1carbine_mp"]		= awe\_util::cvardef("awe_dmgmod_m1carbine_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["m1garand_mp"]		= awe\_util::cvardef("awe_dmgmod_m1garand_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["thompson_mp"]		= awe\_util::cvardef("awe_dmgmod_thompson_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["bar_mp"]			= awe\_util::cvardef("awe_dmgmod_bar_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["springfield_mp"]		= awe\_util::cvardef("awe_dmgmod_springfield_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod[level.awe_cook + "frag_grenade_american_mp"]=awe\_util::cvardef("awe_dmgmod_frag_grenade_american_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["colt_mp"]			= awe\_util::cvardef("awe_dmgmod_colt_mp",100,0,9999,"float")*0.01;

	// British
	level.awe_dmgmod["enfield_mp"]		= awe\_util::cvardef("awe_dmgmod_enfield_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["sten_mp"]			= awe\_util::cvardef("awe_dmgmod_sten_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["bren_mp"]			= awe\_util::cvardef("awe_dmgmod_bren_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["enfield_scope_mp"]	= awe\_util::cvardef("awe_dmgmod_enfield_scope_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod[level.awe_cook + "frag_grenade_british_mp"]=awe\_util::cvardef("awe_dmgmod_frag_grenade_british_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["webley_mp"]			= awe\_util::cvardef("awe_dmgmod_webley_mp",100,0,9999,"float")*0.01;

	// German
	level.awe_dmgmod["kar98k_mp"]			= awe\_util::cvardef("awe_dmgmod_kar98k_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["g43_mp"]			= awe\_util::cvardef("awe_dmgmod_g43_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["mp40_mp"]			= awe\_util::cvardef("awe_dmgmod_mp40_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["mp44_mp"]			= awe\_util::cvardef("awe_dmgmod_mp44_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["kar98k_sniper_mp"]	= awe\_util::cvardef("awe_dmgmod_kar98k_sniper_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod[level.awe_cook + "frag_grenade_german_mp"]= awe\_util::cvardef("awe_dmgmod_frag_grenade_german_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["luger_mp"]			= awe\_util::cvardef("awe_dmgmod_luger_mp",100,0,9999,"float")*0.01;

	// Russian
	level.awe_dmgmod["mosin_nagant_mp"]		= awe\_util::cvardef("awe_dmgmod_mosin_nagant_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["pps42_mp"]			= awe\_util::cvardef("awe_dmgmod_pps42_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["ppsh_mp"]			= awe\_util::cvardef("awe_dmgmod_ppsh_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["mosin_nagant_sniper_mp"]= awe\_util::cvardef("awe_dmgmod_mosin_nagant_sniper_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod[level.awe_cook + "frag_grenade_russian_mp"]=awe\_util::cvardef("awe_dmgmod_frag_grenade_russian_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["tt30_mp"]			= awe\_util::cvardef("awe_dmgmod_tt30_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["svt40_mp"]			= awe\_util::cvardef("awe_dmgmod_svt40_mp",100,0,9999,"float")*0.01;

	// Turrets
	level.awe_dmgmod["mg42_bipod_duck_mp"]	= awe\_util::cvardef("awe_dmgmod_mg42_bipod_duck_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["mg42_bipod_prone_mp"]	= awe\_util::cvardef("awe_dmgmod_mg42_bipod_prone_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["mg42_bipod_stand_mp"]	= awe\_util::cvardef("awe_dmgmod_mg42_bipod_stand_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["30cal_prone_mp"]		= awe\_util::cvardef("awe_dmgmod_30cal_prone_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["30cal_stand_mp"]		= awe\_util::cvardef("awe_dmgmod_30cal_stand_mp",100,0,9999,"float")*0.01;

	// "Common"
	level.awe_dmgmod["shotgun_mp"]		= awe\_util::cvardef("awe_dmgmod_shotgun_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["panzerfaust_mp"]		= awe\_util::cvardef("awe_dmgmod_panzerfaust_mp",100,0,9999,"float")*0.01;
	level.awe_dmgmod["panzerschreck_mp"]	= awe\_util::cvardef("awe_dmgmod_panzerschreck_mp",100,0,9999,"float")*0.01;
}

