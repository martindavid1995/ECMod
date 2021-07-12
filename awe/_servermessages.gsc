init()
{
	// Server messages
	level.awe_messagedelay		= awe\_util::cvardef("awe_message_delay", 30, 1, 1440, "int");
	level.awe_messagenextmap	= awe\_util::cvardef("awe_message_next_map", 2, 0, 4, "int");
	level.awe_messageloop		= awe\_util::cvardef("awe_message_loop", 1, 0, 1, "int");
	level.awe_messageindividual	= awe\_util::cvardef("awe_message_individual", 0, 0, 1, "int");

	thread StartThreads();
}

StartThreads()
{
	wait .05;
	level endon("awe_killthreads");
	
	// Announce next map and display server messages globally
	if(!level.awe_messageindividual)	thread ServerMessages();
}

RunOnSpawn()
{
	// Announce next map and display server messages locally
	if(level.awe_messageindividual) self thread ServerMessages();
}

ServerMessages()
{
	maps = undefined;

	if(level.awe_messageindividual)
	{
		self endon("awe_killthreads");

		// Check if thread has allready been called.
		if(isdefined(self.pers["awe_serverMessages"]))
			return;
	}
	else
	{
		level endon("awe_killthreads");

		// Check if thread has allready been called.
		if(isdefined(game["serverMessages"]))
			return;
	}

	wait level.awe_messagedelay;

	for(;;)
	{
		if( !level.awe_mapvote && level.awe_messagenextmap && !(level.awe_messageindividual && isdefined(self.pers["awe_messagecount"])) )
		{
			x = awe\_util::GetCurrentMapRotation(1);
			if(isdefined(x))
			{
				if(isdefined(x.maps))
					maps = x.maps;
				x delete();
			}

			if(isdefined(maps) && maps.size)
			{
				// Get next map
				if(isdefined(maps[0]["gametype"]))
					nextgt=maps[0]["gametype"];
				else
					nextgt=level.awe_gametype;

				nextmap=maps[0]["map"];

				if(level.awe_messagenextmap == 4)
				{
					if(level.awe_randommaprotation)
					{
						if(level.awe_messageindividual)
							self iprintln(&"AWE_THIS_SERVER_RANDOM");
						else
							iprintln(&"AWE_THIS_SERVER_RANDOM");
					}
					else
					{
						if(level.awe_messageindividual)
							self iprintln(&"AWE_THIS_SERVER_NORMAL");
						else
							iprintln(&"AWE_THIS_SERVER_NORMAL");
					}	
				
					wait 1;
				}

				if(level.awe_messagenextmap > 2)
				{
					if(level.awe_messageindividual)
						self iprintln("^3Next gametype: ^5" + awe\_util::getGametypeName(nextgt) );
					else
						iprintln("^3Next gametype: ^5" + awe\_util::getGametypeName(nextgt) );
					wait 1;
				}

				if(level.awe_messagenextmap > 2 || level.awe_messagenextmap == 1)
				{
					if(level.awe_messageindividual)
						self iprintln("^3Next map: ^5" + awe\_util::getMapName(nextmap) );
					else
						iprintln("^3Next map: ^5" + awe\_util::getMapName(nextmap) );
				}

				if(level.awe_messagenextmap == 2)
				{
					if(level.awe_messageindividual)
						self iprintln("^3Next: ^5" + awe\_util::getMapName(nextmap) + "^3/^5" + awe\_util::getGametypeName(nextgt) );
					else
						iprintln("^3Next: ^5" + awe\_util::getMapName(nextmap) + "^3/^5" + awe\_util::getGametypeName(nextgt) );
					wait 1;
				}

				// Set next message
				if(level.awe_messageindividual)
					self.pers["awe_messagecount"] = 0;

				wait level.awe_messagedelay;
			}
		}
	
		// Get first message
		if(level.awe_messageindividual && isdefined(self.pers["awe_messagecount"]))
			count = self.pers["awe_messagecount"];
		else
			count = 0;

		message = awe\_util::cvardef("awe_message" + count, "", "", "", "string");

		// Avoid infinite loop
		if(message == "" && !(isdefined(maps) && maps.size))
			wait level.awe_messagedelay;

		// Announce messages
		while(message != "")
		{
			if(level.awe_messageindividual)
				self iprintln(message);
			else
				iprintln(message);
			count++;
			// Set next message
			if(level.awe_messageindividual)
				self.pers["awe_messagecount"] = count;

			wait level.awe_messagedelay;

			message = awe\_util::cvardef("awe_message" + count, "", "", "", "string");
		}

		if(level.awe_messageindividual)
			self.pers["awe_messagecount"] = undefined;

		// Loop?
		if(!level.awe_messageloop)
			break;
	}
	// Set flag to indicate that this thread has been called and run all through once
	if(level.awe_messageindividual)
		self.pers["awe_serverMessages"] = true;
	else
		game["serverMessages"] = true;
}
