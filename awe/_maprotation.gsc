init()
{
	// Fix corrupt maprotations
	level.awe_fixmaprotation 	= awe\_util::cvardef("awe_fix_maprotation", 0, 0, 1, "int");	

	// Use random maprotation?
	level.awe_randommaprotation 	= awe\_util::cvardef("awe_random_maprotation", 0, 0, 2, "int");	

	// Rotate map if server is empty?
	level.awe_rotateifempty 	= awe\_util::cvardef("awe_rotate_if_empty", 30, 0, 1440, "int");
	// Setup time counter
	if(!isdefined(game["awe_emptytime"]))	game["awe_emptytime"] = 0;

	// Fix corrupt maprotations
	FixMapRotation();

	thread StartThreads();
}

StartThreads()
{
	wait .05;
	level endon("awe_killthreads");

	// Do maprotation randomization
	thread RandomMapRotation();

	// Start thread that rotates map if server is empty
	if(level.awe_rotateifempty) thread RotateIfEmpty();
}

RandomMapRotation()
{
	level endon("awe_killthreads");

	// Do random maprotation?
	if(!level.awe_randommaprotation || level.awe_mapvote)
		return;

	// Randomize maps of maprotationcurrent is empty or on a fresh start
	if( awe\_util::strip(getcvar("sv_maprotationcurrent")) == "" || level.awe_randommaprotation == 1)
	{
		maps = undefined;
		x = awe\_util::GetRandomMapRotation();
		if(isdefined(x))
		{
			if(isdefined(x.maps))
				maps = x.maps;
			x delete();
		}

		if(!isdefined(maps) || !maps.size)
			return;

		lastexec = "";
		lastjeep = "";
		lasttank = "";
		lastgt = "";

		// Built new maprotation string
		newmaprotation = "";
		for(i = 0; i < maps.size; i++)
		{
			if(!isdefined(maps[i]["exec"]) || lastexec == maps[i]["exec"])
				exec = "";
			else
			{
				lastexec = maps[i]["exec"];
				exec = " exec " + maps[i]["exec"];
			}

			if(!isdefined(maps[i]["jeep"]) || lastjeep == maps[i]["jeep"])
				jeep = "";
			else
			{
				lastjeep = maps[i]["jeep"];
				jeep = " allow_jeeps " + maps[i]["jeep"];
			}

			if(!isdefined(maps[i]["tank"]) || lasttank == maps[i]["tank"])
				tank = "";
			else
			{
				lasttank = maps[i]["tank"];
				tank = " allow_tanks " + maps[i]["tank"];	
			}

			if(!isdefined(maps[i]["gametype"]) || lastgt == maps[i]["gametype"])
				gametype = "";
			else
			{
				lastgt = maps[i]["gametype"];
				gametype = " gametype " + maps[i]["gametype"];	
			}
			
			temp = exec + jeep + tank + gametype + " map " + maps[i]["map"];
			if( (newmaprotation.size + temp.size)>975)
			{
				iprintlnbold("Maprotation: ^1Limiting sv_maprotation to avoid server crash! String1 size:" + newmaprotation.size + " String2 size:" + temp.size);
				break;
			}
			newmaprotation += temp;
		}

		// Set the new rotation
		setCvar("sv_maprotationcurrent", newmaprotation);

		// Set awe_random_maprotation to "2" to indicate that initial randomizing is done
		setCvar("awe_random_maprotation", "2");
	}
}

FixMapRotation()
{
	if(!level.awe_fixmaprotation || level.awe_mapvote)
		return;

	maps = undefined;
	x = awe\_util::GetPlainMapRotation();
	if(isdefined(x))
	{
		if(isdefined(x.maps))
			maps = x.maps;
		x delete();
	}

	if(!isdefined(maps) || !maps.size)
		return;

	// Built new maprotation string
	newmaprotation = "";
	newmaprotationcurrent = "";
	for(i = 0; i < maps.size; i++)
	{
		if(!isdefined(maps[i]["exec"]))
			exec = "";
		else
			exec = " exec " + maps[i]["exec"];

		if(!isdefined(maps[i]["jeep"]))
			jeep = "";
		else
			jeep = " allow_jeeps " + maps[i]["jeep"];

		if(!isdefined(maps[i]["tank"]))
			tank = "";
		else
			tank = " allow_tanks " + maps[i]["tank"];

		if(!isdefined(maps[i]["gametype"]))
			gametype = "";
		else
			gametype = " gametype " + maps[i]["gametype"];

		temp = exec + jeep + tank + gametype + " map " + maps[i]["map"];
		if( (newmaprotation.size + temp.size)>975)
		{
			iprintlnbold(&"AWE_FIXMAPROT_LIMITING");
			break;
		}
		newmaprotation += temp;

		if(i>0)
			newmaprotationcurrent += exec + jeep + tank + gametype + " map " + maps[i]["map"];
	}

	// Set the new rotation
	setCvar("sv_maprotation", awe\_util::strip(newmaprotation));

	// Set the new rotationcurrent
	setCvar("sv_maprotationcurrent", newmaprotationcurrent);

	// Set awe_fix_maprotation to "0" to indicate that initial fixing has been done
	setCvar("awe_fix_maprotation", "0");
}

RotateIfEmpty()
{
	level endon("awe_killthreads");

	while(game["awe_emptytime"]<level.awe_rotateifempty)
	{
		wait 60;

		// Reset counter
		num = 0;

		// Count clients that are playing
		for(i=0;i<level.awe_allplayers.size;i++)
			if(isdefined(level.awe_allplayers[i]) && isPlayer(level.awe_allplayers[i]) && level.awe_allplayers[i].sessionstate=="playing")
				num++; 

		// Need at least 2 playing clients			
		if(num>1)
			game["awe_emptytime"] = 0;
		else
			game["awe_emptytime"]++;
	}
	setcvar("g_gametype",level.awe_gametype);		// Restore gametype in case we are pretending
	exitLevel(false);
}
