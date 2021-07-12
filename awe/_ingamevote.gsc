init ()
{
	InitMapsConfig ();
	level thread onPlayerConnected ();
}

onPlayerConnected ()
{
	for ( ; ; )
	{
		level waittill ("connected", player);
		player thread SetUIDvars ();
	}
}

InitMapsConfig ()
{
	level.vote_maps = [];

	fname = awe\_util::cvardef ("awe_ingame_vote_mapconfigfile", "mapvote.ini", "", "", "string");
	fdesc = OpenFile (fname, "read");
	
	if (fdesc == -1)
		return;

	for ( ; ; )
	{
		elems = freadln (fdesc);
		
		if (elems == -1)
			break;
			
		if (elems == 0)
			continue;
	
		line = "";
		for (pos = 0 ; pos < elems ; pos ++)
		{
			line = line + fgetarg (fdesc, pos);
			if (pos < elems - 1)
				line = line + ",";
		}

		if ((getsubstr (line, 0, 2) == "//") || (getsubstr (line, 0, 1) == "#"))
			continue;
		
		array = strtok (line, " ");

		shortname = array[0];
		longname = getsubstr (line, shortname.size + 1, line.size);
		
		if (! longname.size)
			longname = shortname;
		
		s = level.vote_maps.size;
		level.vote_maps[s] = spawnstruct ();
		level.vote_maps[s].shortname = shortname;
		level.vote_maps[s].longname = longname;
		
		if (level.vote_maps.size == 120)
			break;
	}
	
	CloseFile (fdesc);
}

SetUIDvars ()
{
	self endon ("disconnect");

	self waittill ("joined_team");

	gt_str = "ctf dm hq sd tdm bt cnq ctfb dom ectf ehq esd hm htf ihtf lms lts ons re vip";
	gt_array = strtok (gt_str, " ");

	allow = awe\_util::cvardef ("awe_ingame_vote_allow_gametype", 0, 0, 1, "int");
	self setClientCvar ("ui_ingame_vote_allow_gametype", allow);
	wait 0.05;
		
	if (allow)
		for (i = 0; i < gt_array.size; i ++)
		{
			if ((! isdefined (self)) || (! isplayer (self)))
				return;
					
			gt = gt_array[i];
			svr_dvar = "awe_ingame_vote_allow_" + gt;
			cli_dvar = "ui_ingame_vote_allow_" + gt;
			val = awe\_util::cvardef (svr_dvar, 1, 0, 1, "int");
			self setClientCvar (cli_dvar, val);
			wait 0.05;
		}

	allow = awe\_util::cvardef ("awe_ingame_vote_allow_map", 0, 0, 1, "int");
	self setClientCvar ("ui_ingame_vote_allow_map", allow);
	wait 0.05;
		
	if (allow)
	{
		number = level.vote_maps.size;
		for (i = 0; i < number; i ++)
		{
			if ((! isdefined (self)) || (! isplayer (self)))
				return;

			cli_dvar = "ui_ingame_vote_map_name_" + (i + 1);
			self setClientCvar (cli_dvar, level.vote_maps[i].longname);
			wait 0.05;
			cli_dvar = "ui_ingame_vote_map_cmd_" + (i + 1);
			self setClientCvar (cli_dvar, "callvote map " + level.vote_maps[i].shortname);
			wait 0.05;
		}
		
		self setClientCvar ("ui_ingame_vote_map_next", (number > 60));
	}
}