// Modified by La Truffe

////////////////////
// Initialization //
////////////////////

// Do various startup things
init()
{
	// Kill any global threads that are running
	level notify("awe_killthreads");

	SetupVariables();

	// Init stuff
	awe\_bloodyscreen::init();
	awe\_bots::init();
	awe\_coldbreath::init();
	awe\_deadbody::init();
	awe\_dmgmod::init();
	awe\_falldmg::init();
 	awe\_fog::init();
	awe\_healthbar::init();
	awe\_healthpacks::init();
// La Truffe ->
	awe\_ingamevote::init ();
// La Truffe <-
	awe\_laserdot::init();
	awe\_logos::init();
	awe\_mapvote::init();
	awe\_minefields::init();
	awe\_maprotation::init();
	awe\_mortars::init();
	awe\_popping::init();
	awe\_servermessages::init();
	awe\_showteamstatus::init();
	awe\_spawnprotection::init();
	awe\_sprinting::init();
// La Truffe ->
	awe\_svr_admin::init ();
	awe\_svr_bash::init ();
// La Truffe <-
	awe\_teamkilling::init();
	awe\_tripwire::init();
	awe\_turrets::init();
	awe\_weaponlimiting::init();
	awe\_welcomemessages::init();

	DoPrecaching();
	LoadEffects();

	Setup();
}

// Read cvars and setup variables
SetupVariables()
{
	////////////////////////////
	// Setup global variables //
	////////////////////////////
	
	level.awe_gametype = getcvar("g_gametype");		// Save gametype in case we are pretending to be another gametype

	switch(level.awe_gametype)
	{
		case "dm":
			level.awe_teamplay = false;
			break;

		case "lms":
			level.awe_teamplay = false;
			break;

		case "ihtf":
			level.awe_teamplay = false;
			break;

// La Truffe ->
		case "hm" :
			level.awe_teamplay = false;
			break;
// La Truffe <-

		default:
			level.awe_teamplay = true;
			break;
	}

	// defaults if not defined in level script
	if(!isDefined(game["allies"]))	game["allies"] = "american";
	if(!isDefined(game["axis"]))		game["axis"] = "german";

	// Number of available punishments
// La Truffe ->
//	level.awe_punishments = 3;
	level.awe_punishments = 5;
// La Truffe <-

	if(!isdefined(game["roundsplayed"]))
		level.awe_roundbased = false;
	else
		level.awe_roundbased = true;

	// Create player array
	level.awe_allplayers = getentarray("player", "classname");

	// Set up number of voices
	level.awe_voices["german"] = 3;
	level.awe_voices["american"] = 7;
	level.awe_voices["russian"] = 6;
	level.awe_voices["british"] = 6;

	if(isdefined(game["german_soldiertype"]) && (game["german_soldiertype"] == "winterlight" || game["german_soldiertype"] == "winterdark") )
		level.awe_wintermap = true;
	else
		level.awe_wintermap = false;
		
	//Test from AWE 3.4.2
	level.awe_weapons = "colt_mp m1carbine_mp m1garand_mp greasegun_mp thompson_mp bar_mp springfield_mp webley_mp enfield_mp sten_mp bren_mp enfield_scope_mp tt30_mp mosin_nagant_mp svt40_mp pps42_mp ppsh_mp mosin_nagant_sniper_mp luger_mp kar98k_mp g43_mp mp40_mp mp44_mp kar98k_sniper_mp g43_sniper_mp shotgun_mp panzerschreck_mp panzerfaust_mp 30cal_mp mg42_mp";

	////////////////
	// Read cvars //
	////////////////

	// Debug
	level.awe_debug 			= awe\_util::cvardef("awe_debug", 0, 0, 1, "int");	

     	// pain & death sounds
	level.awe_painsound		= awe\_util::cvardef("awe_painsound", 1, 0, 1, "int");
	level.awe_deathsound		= awe\_util::cvardef("awe_deathsound", 1, 0, 1, "int");

	// Use deathicons, nadeicons, weapon drop etc...
	level.awe_allowcrosshair	= awe\_util::cvardef("awe_allow_crosshair", 1, 0, 2, "int");
	level.awe_allowcrosshairnames	= awe\_util::cvardef("awe_allow_crosshair_names", 1, 0, 2, "int");
	level.awe_allowcrosshaircolor	= awe\_util::cvardef("awe_allow_crosshair_color", 1, 0, 2, "int");
	
	// Unknown Soldiers handling
	level.awe_unknownreflect 	= awe\_util::cvardef("awe_unknown_reflect",1,0,1,"int");
	level.awe_unknownmethod 	= awe\_util::cvardef("awe_unknown_method",0,0,2,"int");
	level.awe_unknownrenamemsg 	= awe\_util::cvardef("awe_unknown_rename_msg","Unknown Soldier is not a valid name! You have been renamed by the server.","","","string");

	// Override gravity?
	level.awe_gravity 		= awe\_util::cvardef("awe_gravity",100,0,9999,"int");
	// Override speed?
	level.awe_speed	 		= awe\_util::cvardef("awe_speed",100,0,9999,"int");

	// Crush models
	level.awe_crushmodels = [];
	level.awe_crushmodels[level.awe_crushmodels.size] = awe\_util::cvardef("awe_crush_model0","furniture_piano_d","","","string");
	for(i=1;i<100;i++)
	{
		crushmodel = awe\_util::cvardef("awe_crush_model" + i,"none","","","string");
		if(crushmodel == "none") break;
		level.awe_crushmodels[level.awe_crushmodels.size] = crushmodel;
	}

	// Stop client exploits
	level.awe_stopclientexploits	= awe\_util::cvardef("awe_stop_client_exploits",1,0,1,"int");

	// Force quick fading compass dots
	level.awe_quickfadecompassdots= awe\_util::cvardef("awe_quickfade_compass_dots",0,0,1,"int");

	// Use grenade cooking?
	level.awe_grenadecooking	= awe\_util::cvardef("awe_grenade_cooking", 1, 0, 3, "int");
	switch(level.awe_grenadecooking)
	{
		case 1:
			level.awe_cook = "cook_";
			break;
		case 2:
			level.awe_cook = "cook2_";
			break;
		case 3:
			level.awe_cook = "cook3_";
			break;
		default:
			level.awe_cook = "";
			break;
	}

	// Use colored smoke grenades?
	level.awe_coloredsmokes	= awe\_util::cvardef("awe_colored_smokes", 1, 0, 2, "int");
	switch(level.awe_coloredsmokes)
	{
		case 1:
			level.awe_smoke = "dale_";
			break;
		case 2:
			level.awe_smoke = "dave_";
			break;
		default:
			level.awe_smoke = "";
			break;
	}

// La Truffe ->
	// Anti-dbbh
	level.awe_anti_dbbh = awe\_util::cvardef ("awe_anti_dbbh", 3, 0, 3, "int");
// La Truffe <-
}

DoPrecaching()
{
	if(!isdefined(game["gamestarted"]))
	{
		if(level.awe_debug)
		{
			precacheModel("xmodel/vehicle_stuka_flying");
		}
	}
}

LoadEffects()
{
	// Used to blow up players. Using same effect as sd.gsc (should save resources)
	level._effect["bombexplosion"] = loadfx("fx/props/barrelexp.efx");
}

Setup()
{
	// Find map limits
	awe\_util::FindMapDimensions();

	// Find play area by checking all the spawnpoints
	awe\_util::FindPlayArea();

	// Override speed and/or gravity?
	if(level.awe_gravity != 100) setcvar("g_gravity", 8 * level.awe_gravity);
	if(level.awe_speed != 100) setcvar("g_speed", int(1.9 * level.awe_speed) );

	// Warm up round
//	WarmupRound();

// La Truffe ->
	// Warmup delay
	thread awe\_warmup::warmup ();
// La Truffe <-
}


///////////////
// Functions //
///////////////

EndMap()
{
	if(level.awe_disable)
		return;

	setcvar("g_gametype",level.awe_gametype);		// Restore gametype in case we are pretending

	awe\_mapvote::Initialise();
}
