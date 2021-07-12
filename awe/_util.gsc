// Modified by La Truffe

/*
USAGE OF "cvardef"
cvardef replaces the multiple lines of code used repeatedly in the setup areas of the script.
The function requires 5 parameters, and returns the set value of the specified cvar
Parameters:
	varname - The name of the variable, i.e. "scr_teambalance", or "scr_dem_respawn"
		This function will automatically find map-sensitive overrides, i.e. "src_dem_respawn_mp_brecourt"

	vardefault - The default value for the variable.  
		Numbers do not require quotes, but strings do.  i.e.   10, "10", or "wave"

	min - The minimum value if the variable is an "int" or "float" type
		If there is no minimum, use "" as the parameter in the function call

	max - The maximum value if the variable is an "int" or "float" type
		If there is no maximum, use "" as the parameter in the function call

	type - The type of data to be contained in the vairable.
		"int" - integer value: 1, 2, 3, etc.
		"float" - floating point value: 1.0, 2.5, 10.384, etc.
		"string" - a character string: "wave", "player", "none", etc.
*/
cvardef(varname, vardefault, min, max, type)
{
	mapname = getcvar("mapname");		// "mp_dawnville", "mp_rocket", etc.

	if(isdefined(level.awe_gametype))
		gametype = level.awe_gametype;	// "tdm", "bel", etc.
	else
		gametype = getcvar("g_gametype");	// "tdm", "bel", etc.

	tempvar = varname + "_" + gametype;	// i.e., scr_teambalance becomes scr_teambalance_tdm
	if(getcvar(tempvar) != "") 		// if the gametype override is being used
		varname = tempvar; 		// use the gametype override instead of the standard variable

	tempvar = varname + "_" + mapname;	// i.e., scr_teambalance becomes scr_teambalance_mp_dawnville
	if(getcvar(tempvar) != "")		// if the map override is being used
		varname = tempvar;		// use the map override instead of the standard variable


	// get the variable's definition
	switch(type)
	{
		case "int":
			if(getcvar(varname) == "")		// if the cvar is blank
				definition = vardefault;	// set the default
			else
				definition = getcvarint(varname);
			break;
		case "float":
			if(getcvar(varname) == "")	// if the cvar is blank
				definition = vardefault;	// set the default
			else
				definition = getcvarfloat(varname);
			break;
		case "string":
		default:
			if(getcvar(varname) == "")		// if the cvar is blank
				definition = vardefault;	// set the default
			else
				definition = getcvar(varname);
			break;
	}

	// if it's a number, with a minimum, that violates the parameter
	if((type == "int" || type == "float") && definition < min)
		definition = min;

	// if it's a number, with a maximum, that violates the parameter
	if((type == "int" || type == "float") && definition > max)
		definition = max;

	return definition;
}

//Method to determine a player's current stance
GetStance(checkjump)
{
	if( checkjump && !self isOnGround() ) 
		return 3;

// La Truffe ->
//	if(isdefined(self.awe_spinemarker))
	if (isdefined (self.awe_spinemarker) && (self.awe_spinemarker.origin != (0, 0, 0)))
// La Truffe <-
{
		distance = self.awe_spinemarker.origin[2] - self.origin[2];
		if(distance<18)
			return 2;
		else if(distance<43)
			return 1;
		else
			return 0;
	}
	else
	{
/*		trace = bulletTrace( self.origin, self.origin + ( 0, 0, 80 ), false, undefined );
		top = trace["position"] + ( 0, 0, -1);//find the ceiling, if it's lower than 80

		bottom = self.origin + ( 0, 0, -12 );
		forwardangle = maps\mp\_utility::vectorScale( anglesToForward( self.angles ), 12 );

		leftangle = ( -1 * forwardangle[1], forwardangle[0], 0 );//a lateral vector

		//now do traces at different sample points
		//there are 9 sample points, forming a 3x3 grid centered on player's origin
		//and oriented with the player's facing
		trace = bulletTrace( top + forwardangle,bottom + forwardangle, true, undefined );
		height1 = trace["position"][2] - self.origin[2];

		trace = bulletTrace( top - forwardangle, bottom - forwardangle, true, undefined );
		height2 = trace["position"][2] - self.origin[2];
	
		trace = bulletTrace( top + leftangle, bottom + leftangle, true, undefined );
		height3 = trace["position"][2] - self.origin[2];
	
		trace = bulletTrace( top - leftangle, bottom - leftangle, true, undefined );
		height4 = trace["position"][2] - self.origin[2];

		trace = bulletTrace( top + leftangle + forwardangle, bottom + leftangle + forwardangle, true, undefined );
		height5 = trace["position"][2] - self.origin[2];

		trace = bulletTrace( top - leftangle + forwardangle, bottom - leftangle + forwardangle, true, undefined );
		height6 = trace["position"][2] - self.origin[2];

		trace = bulletTrace( top + leftangle - forwardangle, bottom + leftangle - forwardangle, true, undefined );
		height7 = trace["position"][2] - self.origin[2];	

		trace = bulletTrace( top - leftangle - forwardangle, bottom - leftangle - forwardangle, true, undefined );
		height8 = trace["position"][2] - self.origin[2];

		trace = bulletTrace( top, bottom, true, undefined );
		height9 = trace["position"][2] - self.origin[2];	

		//find the maximum of the height samples
		heighta = getMax( height1, height2, height3, height4 );
		heightb = getMax( height5, height6, height7, height8 );
		maxheight = getMax( heighta, heightb, height9, 0 );

		//categorize stance based on height
		if( maxheight < 25 )
			stance = 2;
		else if( maxheight < 52 )
			stance = 1;
		else
			stance = 0;

		//self iprintln("Height: "+maxheight+" Stance: "+stance);
		return stance;*/
		return 0;
	}
}

//Method that returns the maximum of a, b, c, and d
getMax( a, b, c, d )
{
	if( a > b )
		ab = a;
	else
		ab = b;
	if( c > d )
		cd = c;
	else
		cd = d;
	if( ab > cd )
		m = ab;
	else
		m = cd;
	return m;
}

GetPlainMapRotation(number)
{
	return GetMapRotation(false, false, number);
}

GetRandomMapRotation()
{
	return GetMapRotation(true, false, undefined);
}

GetCurrentMapRotation(number)
{
	return GetMapRotation(false, true, number);
}

GetMapRotation(random, current, number)
{
	maprot = "";

	if(!isdefined(number))
		number = 0;

	// Get current maprotation
	if(current)
		maprot = strip(getcvar("sv_maprotationcurrent"));	

	// Get maprotation if current empty or not the one we want
	if(level.awe_debug) iprintln("(cvar)maprot: " + getcvar("sv_maprotation").size);
	if(maprot == "")
		maprot = strip(getcvar("sv_maprotation"));	
	if(level.awe_debug) iprintln("(var)maprot: " + maprot.size);

	// No map rotation setup!
	if(maprot == "")
		return undefined;
	
	// Explode entries into an array
//	temparr2 = explode(maprot," ");
	j=0;
	temparr2[j] = "";	
	for(i=0;i<maprot.size;i++)
	{
		if(maprot[i]==" ")
		{
			j++;
			temparr2[j] = "";
		}
		else
			temparr2[j] += maprot[i];
	}

	// Remove empty elements (double spaces)
	temparr = [];
	for(i=0;i<temparr2.size;i++)
	{
		element = strip(temparr2[i]);
		if(element != "")
		{
			if(level.awe_debug) iprintln("maprot" + temparr.size + ":" + element);
			temparr[temparr.size] = element;
		}
	}

	// Spawn entity to hold the array
	x = spawn("script_origin",(0,0,0));

	x.maps = [];
	lastexec = undefined;
	lastjeep = undefined;
	lasttank = undefined;
	lastgt = level.awe_gametype;
	for(i=0;i<temparr.size;)
	{
		switch(temparr[i])
		{
			case "allow_jeeps":
				if(isdefined(temparr[i+1]))
					lastjeep = temparr[i+1];
				i += 2;
				break;

			case "allow_tanks":
				if(isdefined(temparr[i+1]))
					lasttank = temparr[i+1];
				i += 2;
				break;
	
			case "exec":
				if(isdefined(temparr[i+1]))
					lastexec = temparr[i+1];
				i += 2;
				break;

			case "gametype":
				if(isdefined(temparr[i+1]))
					lastgt = temparr[i+1];
				i += 2;
				break;

			case "map":
				if(isdefined(temparr[i+1]))
				{
					x.maps[x.maps.size]["exec"]		= lastexec;
					x.maps[x.maps.size-1]["jeep"]	= lastjeep;
					x.maps[x.maps.size-1]["tank"]	= lasttank;
					x.maps[x.maps.size-1]["gametype"]	= lastgt;
					x.maps[x.maps.size-1]["map"]	= temparr[i+1];
				}
				// Only need to save this for random rotations
				if(!random)
				{
					lastexec = undefined;
					lastjeep = undefined;
					lasttank = undefined;
					lastgt = undefined;
				}

				i += 2;
				break;

			// If code get here, then the maprotation is corrupt so we have to fix it
			default:
				iprintlnbold(&"AWE_ERROR_IN_MAPROT");
	
				if(isGametype(temparr[i]))
					lastgt = temparr[i];
				else if(isConfig(temparr[i]))
					lastexec = temparr[i];
				else
				{
					x.maps[x.maps.size]["exec"]		= lastexec;
					x.maps[x.maps.size-1]["jeep"]	= lastjeep;
					x.maps[x.maps.size-1]["tank"]	= lasttank;
					x.maps[x.maps.size-1]["gametype"]	= lastgt;
					x.maps[x.maps.size-1]["map"]	= temparr[i];
	
					// Only need to save this for random rotations
					if(!random)
					{
						lastexec = undefined;
						lastjeep = undefined;
						lasttank = undefined;
						lastgt = undefined;
					}
				}
					

				i += 1;
				break;
		}
		if(number && x.maps.size >= number)
			break;
	}

	if(random)
	{
		// Shuffle the array 20 times
		for(k = 0; k < 20; k++)
		{
			for(i = 0; i < x.maps.size; i++)
			{
				j = randomInt(x.maps.size);
				element = x.maps[i];
				x.maps[i] = x.maps[j];
				x.maps[j] = element;
			}
		}
	}

	return x;
}

isConfig(cfg)
{
	temparr = explode(cfg,".");
	if(temparr.size == 2 && temparr[1] == "cfg")
		return true;
	else
		return false;
}

isGametype(gt)
{
	switch(gt)
	{
		case "dm":
		case "tdm":
		case "sd":
		case "re":
		case "hq":
		case "bel":
		case "bas":
		case "dom":
		case "ctf":
		case "ter":
		case "actf":
		case "lts":
		case "lms":
		case "cnq":
		case "rsd":
		case "tdom":
		case "ad":
		case "htf":
		case "ihtf":
// La Truffe ->
		case "vip" :
		case "ehq" :
		case "ctfb" :
		case "ectf" :
		case "hm" :
		case "esd" :
// La Truffe <-
		case "asn":

		case "mc_dm":
		case "mc_tdm":
		case "mc_sd":
		case "mc_re":
		case "mc_hq":
		case "mc_bel":
		case "mc_bas":
		case "mc_dom":
		case "mc_ctf":
		case "mc_ter":
		case "mc_actf":
		case "mc_lts":
		case "mc_lms":
		case "mc_cnq":
		case "mc_rsd":
		case "mc_tdom":
		case "mc_ad":
		case "mc_htf":
		case "mc_ihtf":
		case "mc_asn":

			return true;

		default:
			return false;
	}
}

spawnSpectator(origin, angles)
{
	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;

	if(self.pers["team"] == "spectator")
		self.statusicon = "";

	maps\mp\gametypes\_spectating::setSpectatePermissions();
	
	if(isDefined(origin) && isDefined(angles))
		self spawn(origin, angles);
	else
	{
         	spawnpointname = "mp_global_intermission";
		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);
	
		if(isDefined(spawnpoint))
			self spawn(spawnpoint.origin, spawnpoint.angles);
		else
			maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}
}

getGametypeName(gt)
{
	switch(gt)
	{
		case "dm":
		case "mc_dm":
			gtname = "Deathmatch";
			break;
		
		case "lms":
		case "mc_lms":
			gtname = "Last Man Standing";
			break;
		
		case "ihtf":
		case "mc_ihtf":
			gtname = "Individual Hold The Flag";
			break;
		
		case "tdm":
		case "mc_tdm":
			gtname = "Team Deathmatch";
			break;

		case "sd":
		case "mc_sd":
			gtname = "Search & Destroy";
			break;

		case "re":
		case "mc_re":
			gtname = "Retrieval";
			break;

		case "hq":
		case "mc_hq":
			gtname = "Headquarters";
			break;

		case "bel":
		case "mc_bel":
			gtname = "Behind Enemy Lines";
			break;
		
		case "cnq":
		case "mc_cnq":
			gtname = "Conquest TDM";
			break;

		case "lts":
		case "mc_lts":
			gtname = "Last Team Standing";
			break;

		case "ctf":
		case "mc_ctf":
			gtname = "Capture The Flag";
			break;

		case "dom":
		case "mc_dom":
			gtname = "Domination";
			break;

		case "ad":
		case "mc_ad":
			gtname = "Attack and Defend";
			break;

		case "bas":
		case "mc_bas":
			gtname = "Base assault";
			break;

		case "actf":
		case "mc_actf":
			gtname = "AWE Capture The Flag";
			break;

		case "htf":
		case "mc_htf":
			gtname = "Hold The Flag";
			break;

		case "ter":
		case "mc_ter":
			gtname = "Territory";
			break;

		case "asn":
		case "mc_asn":
			gtname = "Assassin";
			break;

		case "mc_tdom":
			gtname = "Team Domination";
			break;
		
// La Truffe ->
		case "vip" :
			gtname = "V.I.P.";
			break;
		
		case "ehq" :
			gtname = "Enhanced Headquarters";
			break;
		
		case "ctfb" :
			gtname = "Capture The Flag Back";
			break;
		
		case "ectf" :
			gtname = "Enhanced Capture The Flag";
			break;

		case "hm" :
			gtname = "Hitman";
			break;

		case "esd" :
			gtname = "Enhanced Search and Destroy";
			break;
// La Truffe <-

		default:
			gtname = gt;
			break;
	}

	return gtname;
}

getMapName(map)
{
	switch(map)
	{
		case "mp_farmhouse":
			mapname = "Beltot";
			break;

		case "mp_brecourt":
			mapname = "Brecourt";
			break;

		case "mp_burgundy":
			mapname = "Burgundy";
			break;
		
		case "mp_trainstation":
			mapname = "Caen";
			break;

		case "mp_carentan":
			mapname = "Carentan";
			break;

		case "mp_decoy":
			mapname = "El Alamein";
			break;

		case "mp_leningrad":
			mapname = "Leningrad";
			break;
		
		case "mp_matmata":
			mapname = "Matmata";
			break;
		
		case "mp_downtown":
			mapname = "Moscow";
			break;
		
		case "mp_harbor":
			mapname = "Rostov";
			break;
		
		case "mp_dawnville":
			mapname = "St. Mere Eglise";
			break;

		case "mp_railyard":
			mapname = "Stalingrad";
			break;

		case "mp_toujane":
			mapname = "Toujane";
			break;
		
		case "mp_breakout":
			mapname = "Villers-Bocage";
			break;

		case "mp_rhine":
			mapname = "Wallendar";
			break;

		default:
			mapname = map;
			break;
	}

	return mapname;
}

explode(s,delimiter)
{
	j=0;
	temparr[j] = "";	

	for(i=0;i<s.size;i++)
	{
		if(s[i]==delimiter)
		{
			j++;
			temparr[j] = "";
		}
		else
			temparr[j] += s[i];
	}
	return temparr;
}


// Strip blanks at start and end of string
strip(s)
{
	if(s=="")
		return "";

	s2="";
	s3="";

	i=0;
	while(i<s.size && s[i]==" ")
		i++;

	// String is just blanks?
	if(i==s.size)
		return "";
	
	for(;i<s.size;i++)
	{
		s2 += s[i];
	}

	i=s2.size-1;
	while(s2[i]==" " && i>0)
		i--;

	for(j=0;j<=i;j++)
	{
		s3 += s2[j];
	}
		
	return s3;
}

//
// bounceObject
//
// rotation		(pitch, yaw, roll) degrees/seconds
// velocity		start velocity
// offset		offset between the origin of the object and the desired rotation origin.
// angles		angles offset between anchor and object
// radius		radius between rotation origin and object surfce
// falloff		velocity falloff for each bounce 0 = no bounce, 1 = bounce forever
// bouncesound	soundalias played at bounching
// bouncefx		effect to play on bounce
//
bounceObject(vRotation, vVelocity, vOffset, angles, radius, falloff, bouncesound, bouncefx, objecttype)
{
	level endon("awe_killthreads");
	self endon("awe_bounceobject");

	self thread putinQ(objecttype);

	// Hide until everthing is setup
	self hide();

	// Setup default values
	if(!isdefined(vRotation))	vRotation = (0,0,0);
	pitch = vRotation[0]*0.05;	// Pitch/frame
	yaw	= vRotation[1]*0.05;	// Yaw/frame
	roll	= vRotation[2]*0.05;	// Roll/frame

	if(!isdefined(vVelocity))	vVelocity = (0,0,0);
	if(!isdefined(vOffset))		vOffset = (0,0,0);
	if(!isdefined(falloff))		falloff = 0.5;

	// Spawn anchor (the object that we will rotate)
	self.anchor = spawn("script_origin", self.origin );
	self.anchor.angles = self.angles;

	// Link to anchor
	self linkto( self.anchor, "", vOffset, angles );
	self show();

	wait .05;	// Let it happen

	if(isdefined(level.awe_gravity))
		gravity = level.awe_gravity;
	else
		gravity = 100;

	// Set gravity
	vGravity = (0,0,-0.02 * gravity);

	stopme = 0;
	notrace = 5;	// Avoid bullettrace for the first number of frames
	// Drop with gravity
	for(;;)
	{
		// Let gravity do, what gravity do best
		vVelocity +=vGravity;

		// Get destination origin
		neworigin = self.anchor.origin + vVelocity;

		// Check for impact, check for entities but not myself.
		if(!notrace)
		{
//			trace=bulletTrace(self.anchor.origin,neworigin,true,self); 
			trace=bulletTrace(self.anchor.origin,neworigin,false,undefined); 
			if(trace["fraction"] != 1)	// Hit something
			{
				// Place object at impact point - radius
				distance = distance(self.anchor.origin,trace["position"]);
				if(distance)
				{
					fraction = (distance - radius) / distance;
					delta = trace["position"] - self.anchor.origin;
					delta2 = maps\mp\_utility::vectorScale(delta,fraction);
					neworigin = self.anchor.origin + delta2;
				}
				else
					neworigin = self.anchor.origin;

				// Play sound if defined
				if(isdefined(bouncesound)) self.anchor playSound(bouncesound + trace["surfacetype"]);	

				// Test if we are hitting ground and if it's time to stop bouncing
				if(vVelocity[2] <= 0 && vVelocity[2] > -10) stopme++;
				if(stopme==5)
				{
					stopme=0;
					// Set origin to impactpoint	
					self.anchor.origin = neworigin;
					wait .05;
					// Delete anchor to save gamestate size
					self unlink();
					self.anchor delete();
					return;
				}
				// Play effect if defined and it's a hard hit
				if(isdefined(bouncefx) && length(vVelocity) > 20) playfx(bouncefx,trace["position"]);

				// Decrease speed for each bounce.
				vSpeed = length(vVelocity) * falloff;

				// Calculate new direction (Thanks to Hellspawn this is finally done correctly)
				vNormal = trace["normal"];
				vDir = maps\mp\_utility::vectorScale(vectorNormalize( vVelocity ),-1);
				vNewDir = ( maps\mp\_utility::vectorScale(maps\mp\_utility::vectorScale(vNormal,2),vectorDot( vDir, vNormal )) ) - vDir;

				// Scale vector
				vVelocity = maps\mp\_utility::vectorScale(vNewDir, vSpeed);
	
				// Add a small random distortion
				vVelocity += (randomFloat(1)-0.5,randomFloat(1)-0.5,randomFloat(1)-0.5);
			}
		}
		else
			notrace--;

		self.anchor.origin = neworigin;

		// Rotate pitch
		a0 = self.anchor.angles[0] + pitch;
		while(a0<0) a0 += 360;
		while(a0>359) a0 -=360;

		// Rotate yaw
		a1 = self.anchor.angles[1] + yaw;
		while(a1<0) a1 += 360;
		while(a1>359) a1 -=360;

		// Rotate roll
		a2 = self.anchor.angles[2] + roll;
		while(a2<0) a2 += 360;
		while(a2>359) a2 -=360;
		self.anchor.angles = (a0,a1,a2);
		
		// Wait one frame
		wait .05;
	}
}

putinQ(type)
{
	index = level.awe_objectQcurrent[type];

	level.awe_objectQcurrent[type]++;
	if(level.awe_objectQcurrent[type] >= level.awe_objectQsize[type])
		level.awe_objectQcurrent[type] = 0;

	if(isDefined(level.awe_objectQ[type][index]))
	{
		level.awe_objectQ[type][index] notify("awe_bounceobject");
		level.awe_objectQ[type][index] notify("awe_healthpack");
		wait .05; //Let thread die
		if(isDefined(level.awe_objectQ[type][index].anchor))
		{
			level.awe_objectQ[type][index] unlink();
			level.awe_objectQ[type][index].anchor delete();
		}
		level.awe_objectQ[type][index] delete();
	}
	
	level.awe_objectQ[type][index] = self;
}

isWeaponType(type,weapon)
{
	temp = false;
	switch(type)
	{
		case "turret":
			switch(weapon)
			{
				case "mg42_bipod_duck_mp":
				case "mg42_bipod_prone_mp":
				case "mg42_bipod_stand_mp":
				case "30cal_prone_mp":
				case "30cal_stand_mp":
					temp = true;
					break;
				default:
					temp = false;
					break;
			}

		case "rocket":
			switch(weapon)
			{
				case "panzerfaust_mp":
				case "panzerschreck_mp":
					temp = true;
					break;
				default:
					temp = false;
					break;
			}
			break;

		case "common":
			switch(weapon)
			{
				case "panzerfaust_mp":
				case "panzerschreck_mp":
				case "binoculars_mp":
				case "shotgun_mp":
					temp = true;
					break;
				default:
					temp = false;
					break;
			}
			break;

		// Check if weapon is a grenade
		case "grenade":
			switch(weapon)
			{
				case "frag_grenade_american_mp":
				case "frag_grenade_british_mp":
				case "frag_grenade_german_mp":
				case "frag_grenade_russian_mp":
				case "cook_frag_grenade_american_mp":
				case "cook_frag_grenade_british_mp":
				case "cook_frag_grenade_german_mp":
				case "cook_frag_grenade_russian_mp":
				case "cook2_frag_grenade_american_mp":
				case "cook2_frag_grenade_british_mp":
				case "cook2_frag_grenade_german_mp":
				case "cook2_frag_grenade_russian_mp":
				case "cook3_frag_grenade_american_mp":
				case "cook3_frag_grenade_british_mp":
				case "cook3_frag_grenade_german_mp":
				case "cook3_frag_grenade_russian_mp":
					temp = true;
					break;
				default:
					temp = false;
					break;
			}
			break;

		// Check if weapon is smoke/flash grenade
		case "smokegrenade":
			switch(weapon)
			{
				case "dave_smoke_grenade_american_mp":
				case "dave_smoke_grenade_british_mp":
				case "dave_smoke_grenade_german_mp":
				case "dave_smoke_grenade_russian_mp":
				case "dale_smoke_grenade_american_mp":
				case "dale_smoke_grenade_british_mp":
				case "dale_smoke_grenade_german_mp":
				case "dale_smoke_grenade_russian_mp":
				case "smoke_grenade_american_mp":
				case "smoke_grenade_british_mp":
				case "smoke_grenade_german_mp":
				case "smoke_grenade_russian_mp":
					temp = true;
					break;
				default:
					temp = false;
					break;
			}
			break;

		// Check if weapon is a rifle
		case "rifle":
			switch(weapon)
			{
				case "enfield_mp":
				case "g43_mp":
				case "kar98k_mp":
				case "m1carbine_mp":
				case "m1garand_mp":
				case "mosin_nagant_mp":
				case "svt40_mp":
					temp = true;
					break;
				default:
					temp = false;
					break;
			}
			break;

		// Check if weapon is a bolt action rifle
		case "boltrifle":
			switch(weapon)
			{
				case "m1carbine_mp":
				case "mosin_nagant_mp":
				case "kar98k_mp":
				case "enfield_mp":
					temp = true;
					break;
				default:
					temp = false;
					break;
			}
			break;

		// Check if weapon is a semi automatic rifle
		case "semirifle":
			switch(weapon)
			{
				case "g43_mp":
				case "m1garand_mp":
				case "svt40_mp":
					temp = true;
					break;
				default:
					temp = false;
					break;
			}
			break;

		// Check if weapon is smg
		case "smg":
			switch(weapon)
			{
				case "greasegun_mp":
				case "mp40_mp":
				case "sten_mp":
				case "thompson_mp":
				case "pps42_mp":
					temp = true;
					break;
				default:
					temp = false;
					break;
			}
			break;

		// Check if weapon is assault
		case "assault":
			switch(weapon)
			{
				case "mp44_mp":
				case "bar_mp":
				case "bren_mp":
				case "ppsh_mp":
					temp = true;
					break;
				default:
					temp = false;
					break;
			}
			break;

		// Check if weapon is sniper
		case "sniper":
			switch(weapon)
			{
				case "mosin_nagant_sniper_mp":
				case "springfield_mp":
				case "kar98k_sniper_mp":
				case "enfield_scope_mp":
					temp = true;
					break;
				default:
					temp = false;
					break;
			}
			break;


		// Check if weapon is rocket launcher
		case "rl":
			switch(weapon)
			{
				case "panzerschreck_mp":
					temp = true;
					break;
				default:
					temp = false;
					break;
			}
			break;


		// Check if weapon is a shotgun
		case "shotgun":
			switch(weapon)
			{
				case "shotgun_mp":
					temp = true;
					break;
				default:
					temp = false;
					break;
			}
			break;


		// Check if weapon is pistol
		case "pistol":
			switch(weapon)
			{
				case "colt_mp":
				case "luger_mp":
				case "tt30_mp":
				case "webley_mp":
					temp = true;
					break;
				default:
					temp = false;
					break;
			}
			break;

		// Check if weapon is american
		case "american":
			switch(weapon)
			{
				case "frag_grenade_american_mp":
				case "cook_frag_grenade_american_mp":
				case "cook2_frag_grenade_american_mp":
				case "cook3_frag_grenade_american_mp":
				case "smoke_grenade_american_mp":
				case "dale_smoke_grenade_american_mp":
				case "dave_smoke_grenade_american_mp":
				case "colt_mp":
				case "m1carbine_mp":
				case "m1garand_mp":
				case "greasegun_mp":
				case "thompson_mp":
				case "bar_mp":
				case "springfield_mp":
				case "shotgun_mp":
					temp = true;
					break;
				default:
					temp = false;
					break;
			}
			break;

		// Check if weapon is british
		case "british":
			switch(weapon)
			{
				case "frag_grenade_british_mp":
				case "cook_frag_grenade_british_mp":
				case "cook2_frag_grenade_british_mp":
				case "cook3_frag_grenade_british_mp":
				case "smoke_grenade_british_mp":
				case "dale_smoke_grenade_british_mp":
				case "dave_smoke_grenade_british_mp":
				case "webley_mp":
				case "enfield_mp":
				case "sten_mp":
				case "bren_mp":
				case "thompson_mp":
				case "enfield_scope_mp":
				case "shotgun_mp":
					temp = true;
					break;
				default:
					temp = false;
					break;
			}
			break;

		// Check if weapon is russian
		case "russian":
			switch(weapon)
			{
				case "frag_grenade_russian_mp":
				case "cook_frag_grenade_russian_mp":
				case "cook2_frag_grenade_russian_mp":
				case "cook3_frag_grenade_russian_mp":
				case "smoke_grenade_russian_mp":
				case "dale_smoke_grenade_russian_mp":
				case "dave_smoke_grenade_russian_mp":
				case "tt30_mp":
				case "mosin_nagant_mp":
				case "svt40_mp":
				case "pps42_mp":
				case "ppsh_mp":
				case "mosin_nagant_sniper_mp":
				case "shotgun_mp":
					temp = true;
					break;
				default:
					temp = false;
					break;
			}
			break;

		// Check if weapon is german
		case "german":
			switch(weapon)
			{
				case "frag_grenade_german_mp":
				case "cook_frag_grenade_german_mp":
				case "cook2_frag_grenade_german_mp":
				case "cook3_frag_grenade_german_mp":
				case "smoke_grenade_german_mp":
				case "dale_smoke_grenade_german_mp":
				case "dave_smoke_grenade_german_mp":
				case "luger_mp":
				case "kar98k_mp":
				case "g43_mp":
				case "mp40_mp":
				case "mp44_mp":
				case "kar98k_sniper_mp":
				case "shotgun_mp":
					temp = true;
					break;
				default:
					temp = false;
					break;
			}
			break;

		default:
			temp = false;
			break;
	}
	return temp;
}

deletePlacedEntity(entity)
{
	entities = getentarray(entity, "classname");
	for(i = 0; i < entities.size; i++)
	{
		//println("DELETED: ", entities[i].classname);
		entities[i] delete();
	}
}

isUnknown()
{
	if(self.name == self.pers["awe_unknown_name"])
		return true;
	else
		return false;
}

FindGround(position)
{
	trace=bulletTrace(position+(0,0,10),position+(0,0,-1200),false,undefined);
	ground=trace["position"];
	return ground;
}

FindPlayArea()
{
	// Get all spawnpoints
	spawnpoints = [];
	temp = getentarray("mp_dm_spawn", "classname");
	if(temp.size)
		for(i=0;i<temp.size;i++)
			spawnpoints[spawnpoints.size] = temp[i];

	temp = getentarray("mp_tdm_spawn", "classname");
	if(temp.size)
		for(i=0;i<temp.size;i++)
			spawnpoints[spawnpoints.size] = temp[i];

	temp = getentarray("mp_sd_spawn_attacker", "classname");
	if(temp.size)
		for(i=0;i<temp.size;i++)
			spawnpoints[spawnpoints.size] = temp[i];

	temp = getentarray("mp_sd_spawn_defender", "classname");
	if(temp.size)
		for(i=0;i<temp.size;i++)
			spawnpoints[spawnpoints.size] = temp[i];

	temp = getentarray("mp_ctf_spawn_allied", "classname");
	if(temp.size)
		for(i=0;i<temp.size;i++)
			spawnpoints[spawnpoints.size] = temp[i];

	temp = getentarray("mp_ctf_spawn_axis", "classname");
	if(temp.size)
		for(i=0;i<temp.size;i++)
			spawnpoints[spawnpoints.size] = temp[i];

	// Initialize
	iMaxX = spawnpoints[0].origin[0];
	iMinX = iMaxX;
	iMaxY = spawnpoints[0].origin[1];
	iMinY = iMaxY;
	iMaxZ = spawnpoints[0].origin[2];
	iMinZ = iMaxZ;

	// Loop through the rest
	for(i = 1; i < spawnpoints.size; i++)
	{
		// Find max values
		if (spawnpoints[i].origin[0]>iMaxX)
			iMaxX = spawnpoints[i].origin[0];

		if (spawnpoints[i].origin[1]>iMaxY)
			iMaxY = spawnpoints[i].origin[1];

		if (spawnpoints[i].origin[2]>iMaxZ)
			iMaxZ = spawnpoints[i].origin[2];

		// Find min values
		if (spawnpoints[i].origin[0]<iMinX)
			iMinX = spawnpoints[i].origin[0];

		if (spawnpoints[i].origin[1]<iMinY)
			iMinY = spawnpoints[i].origin[1];

		if (spawnpoints[i].origin[2]<iMinZ)
			iMinZ = spawnpoints[i].origin[2];
	}

	level.awe_playAreaMin = (iMinX,iMinY,iMinZ);
	level.awe_playAreaMax = (iMaxX,iMaxX,iMaxZ);
}

FindMapDimensions()
{
	// Get entities
	entitytypes = getentarray();

	// Initialize
	iMaxX = entitytypes[0].origin[0];
	iMinX = iMaxX;
	iMaxY = entitytypes[0].origin[1];
	iMinY = iMaxY;
	iMaxZ = entitytypes[0].origin[2];
	iMinZ = iMaxZ;

	// Loop through the rest
	for(i = 1; i < entitytypes.size; i++)
	{
		// Find max values
		if (entitytypes[i].origin[0]>iMaxX)
			iMaxX = entitytypes[i].origin[0];

		if (entitytypes[i].origin[1]>iMaxY)
			iMaxY = entitytypes[i].origin[1];

		if (entitytypes[i].origin[2]>iMaxZ)
			iMaxZ = entitytypes[i].origin[2];

		// Find min values
		if (entitytypes[i].origin[0]<iMinX)
			iMinX = entitytypes[i].origin[0];

		if (entitytypes[i].origin[1]<iMinY)
			iMinY = entitytypes[i].origin[1];

		if (entitytypes[i].origin[2]<iMinZ)
			iMinZ = entitytypes[i].origin[2];
	}

	// Get middle of map
	iX = int((iMaxX + iMinX)/2);
	iY = int((iMaxY + iMinY)/2);
	iZ = int((iMaxZ + iMinZ)/2);

      // Find iMaxZ
	iTraceend = iZ;
	iTracelength = 50000;
	iTracestart = iTraceend + iTracelength;
	trace = bulletTrace((iX,iY,iTracestart),(iX,iY,iTraceend), false, undefined);
	if(trace["fraction"] != 1)
	{
		iMaxZ = iTracestart - (iTracelength * trace["fraction"]) - 100;
	} 
	
	if(level.awe_debug)
	{
		// Spawn stukas to mark center and corners that we got from the entities.
		stuka1 = spawn_model("xmodel/vehicle_stuka_flying","stuka1",(iX,iY,iMaxZ),(0,90,0));
		stuka11 = spawn_model("xmodel/vehicle_stuka_flying","stuka11",(iX,iY,iMaxZ - 200),(0,90,0));
		stuka12 = spawn_model("xmodel/vehicle_stuka_flying","stuka12",(iX,iY,iMaxZ - 400),(0,90,0));
		stuka4 = spawn_model("xmodel/vehicle_stuka_flying","stuka4",(iMaxX,iMaxY,iMaxZ),(0,90,0));
		stuka5 = spawn_model("xmodel/vehicle_stuka_flying","stuka5",(iMinX,iMinY,iMaxZ),(0,90,0));
		stuka6 = spawn_model("xmodel/vehicle_stuka_flying","stuka6",(iMaxX,iMinY,iMaxZ),(0,90,0));
		stuka7 = spawn_model("xmodel/vehicle_stuka_flying","stuka7",(iMinX,iMaxY,iMaxZ),(0,90,0));
	}

	// Find iMaxX
	iTraceend = iX;
	iTracelength = 100000;
	iTracestart = iTraceend + iTracelength;
	trace = bulletTrace((iTracestart,iY,iZ),(iTraceend,iY,iZ), false, undefined);
	if(trace["fraction"] != 1)
	{
		iMaxX = iTracestart - (iTracelength * trace["fraction"]) - 100;
	} 
	
	// Find iMaxY
	iTraceend = iY;
	iTracelength = 100000;
	iTracestart = iTraceend + iTracelength;
	trace = bulletTrace((iX,iTracestart,iZ),(iX,iTraceend,iZ), false, undefined);
	if(trace["fraction"] != 1)
	{
		iMaxY = iTracestart - (iTracelength * trace["fraction"]) - 100;
	} 

	// Find iMinX
	iTraceend = iX;
	iTracelength = 100000;
	iTracestart = iTraceend - iTracelength;
	trace = bulletTrace((iTracestart,iY,iZ),(iTraceend,iY,iZ), false, undefined);
	if(trace["fraction"] != 1)
	{
		iMinX = iTracestart + (iTracelength * trace["fraction"]) + 100;
	} 
	
	// Find iMinY
	iTraceend = iY;
	iTracelength = 100000;
	iTracestart = iTraceend - iTracelength;
	trace = bulletTrace((iX,iTracestart,iZ),(iX,iTraceend,iZ), false, undefined);
	if(trace["fraction"] != 1)
	{
		iMinY = iTracestart + (iTracelength * trace["fraction"]) + 100;
	} 

	// Find iMinZ
	iTraceend = iZ;
	iTracelength = 50000;
	iTracestart = iTraceend - iTracelength;
	trace = bulletTrace((iX,iY,iTracestart),(iX,iY,iTraceend), false, undefined);
	if(trace["fraction"] != 1)
	{
		iMinZ = iTracestart + (iTracelength * trace["fraction"]) + 100;
	} 
	if(level.awe_debug)
	{
		// Spawn stukas to mark the corner we got from bulletTracing
		stuka14 = spawn_model("xmodel/vehicle_stuka_flying","stuka14",(iMaxX,iMaxY,iMaxZ-200),(0,90,0));
		stuka15 = spawn_model("xmodel/vehicle_stuka_flying","stuka15",(iMinX,iMinY,iMaxZ-200),(0,90,0));
		stuka16 = spawn_model("xmodel/vehicle_stuka_flying","stuka16",(iMaxX,iMinY,iMaxZ-200),(0,90,0));
		stuka17 = spawn_model("xmodel/vehicle_stuka_flying","stuka17",(iMinX,iMaxY,iMaxZ-200),(0,90,0));
	}
	level.awe_vMax = (iMaxX, iMaxY, iMaxZ);
	level.awe_vMin = (iMinX, iMinY, iMinZ);
}

spawn_model(model,name,origin,angles)
{
	if (!isdefined(model) || !isdefined(name) || !isdefined(origin))
		return undefined;

	if (!isdefined(angles))
		angles = (0,0,0);

	spawn = spawn ("script_model",(0,0,0));
	spawn.origin = origin;
	spawn setmodel (model);
	spawn.targetname = name;
	spawn.angles = angles;

	return spawn;
}

TeamMateInRange(range)
{
	if(!range)
		return true;

	// Get all players and pick out the ones that are playing and are in the same team
	players = [];
	for(i = 0; i < level.awe_allplayers.size; i++)
	{
		if(isdefined(level.awe_allplayers[i]))
			if(level.awe_allplayers[i].sessionstate == "playing" && level.awe_allplayers[i].pers["team"] == self.pers["team"])
				players[players.size] = level.awe_allplayers[i];
	}

	// Get the players that are in range
	sortedplayers = sortByDist(players, self);

	// Need at least 2 players (myself + one team mate)
	if(sortedplayers.size<2)
		return false;

	// First player will be myself so check against second player
	distance = distance(self.origin, sortedplayers[1].origin);
	if( distance <= range )
		return true;
	else
		return false;
}

// sort a list of entities with ".origin" properties in ascending order by their distance from the "startpoint"
// "points" is the array to be sorted
// "startpoint" (or the closest point to it) is the first entity in the returned list
// "maxdist" is the farthest distance allowed in the returned list
// "mindist" is the nearest distance to be allowed in the returned list
sortByDist(points, startpoint, maxdist, mindist)
{
	if(!isdefined(points))
		return undefined;
	if(!isdefineD(startpoint))
		return undefined;

	if(!isdefined(mindist))
		mindist = -1000000;
	if(!isdefined(maxdist))
		maxdist = 1000000; // almost 16 miles, should cover everything.

	sortedpoints = [];

	max = points.size-1;
	for(i = 0; i < max; i++)
	{
		nextdist = 1000000;
		next = undefined;

		for(j = 0; j < points.size; j++)
		{
			thisdist = distance(startpoint.origin, points[j].origin);
			if(thisdist <= nextdist && thisdist <= maxdist && thisdist >= mindist)
			{
				next = j;
				nextdist = thisdist;
			}
		}

		if(!isdefined(next))
			break; // didn't find one that fit the range, stop trying

		sortedpoints[i] = points[next];

		// shorten the list, fewer compares
		points[next] = points[points.size-1]; // replace the closest point with the end of the list
		points[points.size-1] = undefined; // cut off the end of the list
	}

	sortedpoints[sortedpoints.size] = points[0]; // the last point in the list

	return sortedpoints;
}

getGrenadeModel(sWeapon)
{
	switch(sWeapon)
	{
		case "frag_grenade_american_mp":
		case "cook_frag_grenade_american_mp":
		case "cook2_frag_grenade_american_mp":
		case "cook3_frag_grenade_american_mp":
			model = "xmodel/weapon_mk2fraggrenade";
			break;

		case "frag_grenade_british_mp":
		case "cook_frag_grenade_british_mp":
		case "cook2_frag_grenade_british_mp":
		case "cook3_frag_grenade_british_mp":
			model = "xmodel/weapon_mk1grenade";
			break;

		case "frag_grenade_russian_mp":
		case "cook_frag_grenade_russian_mp":
		case "cook2_frag_grenade_russian_mp":
		case "cook3_frag_grenade_russian_mp":
			model = "xmodel/weapon_russian_handgrenade";
			break;	

		default:
			model = "xmodel/weapon_nebelhandgrenate";
			break;
	}
	return model;
}

scriptedRadiusDamage(eAttacker, vOffset, sWeapon, iRange, iMaxDamage, iMinDamage, ignoreTK)
{
	if(!isdefined(vOffset))
		vOffset = (0,0,0);
	
	if(isdefined(sWeapon) && isWeaponType("grenade",sWeapon) )
	{
		sMeansOfDeath = "MOD_GRENADE_SPLASH";
		iDFlags = 1;
	}
	else
	{
		sMeansOfDeath = "MOD_EXPLOSIVE";
		iDFlags = 1;
	}

	// Loop through players
	for(i=0;i<level.awe_allplayers.size;i++)
	{
		if(!isdefined(level.awe_allplayers[i]))
			continue;

		// Check that player is in range
		distance = distance((self.origin + vOffset), level.awe_allplayers[i].origin);
		if(distance>=iRange || level.awe_allplayers[i].sessionstate != "playing" || !isAlive(level.awe_allplayers[i]) )
			continue;

		if(level.awe_allplayers[i] != self && !(isdefined(self.awe_linkedto) && self.awe_linkedto == level.awe_allplayers[i]))
		{
			percent = (iRange-distance)/iRange;
			iDamage = iMinDamage + (iMaxDamage - iMinDamage)*percent;

			stance = level.awe_allplayers[i].awe_stance;
			switch(stance)
			{
				case 2:
					offset = (0,0,5);
					break;
				case 1:
					offset = (0,0,35);
					break;
				default:
					offset = (0,0,55);
					break;
			}

			traceorigin = level.awe_allplayers[i].origin + offset;

			trace = bullettrace(self.origin + vOffset, traceorigin, true, self);
			// Damage blocked by entity, remove 40%
			if(isdefined(trace["entity"]) && trace["entity"] != level.awe_allplayers[i])
				iDamage = iDamage * .6;
			// Damage blocked by other stuff(walls etc...), remove 80%
			else if(!isdefined(trace["entity"]))
				iDamage = iDamage * .2;

			vDir = vectorNormalize(traceorigin - (self.origin + vOffset));
		}
		else
		{
			iDamage = iMaxDamage;
			vDir=(0,0,1);
		}
// eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime
		if(ignoreTK && isPlayer(eAttacker) && level.awe_teamplay && isdefined(eAttacker.sessionteam) && isdefined(level.awe_allplayers[i].sessionteam) && eAttacker.sessionteam == level.awe_allplayers[i].sessionteam)
			level.awe_allplayers[i] thread [[level.callbackPlayerDamage]](self, self, iDamage, iDFlags, sMeansOfDeath, sWeapon, undefined, vDir, "none", 0);
		else
			level.awe_allplayers[i] thread [[level.callbackPlayerDamage]](self, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, undefined, vDir, "none", 0);
	}
}

getGrenadeHud(sWeapon)
{
	switch(sWeapon)
	{
		case "frag_grenade_american_mp":
		case "cook_frag_grenade_american_mp":
		case "cook2_frag_grenade_american_mp":
		case "cook3_frag_grenade_american_mp":
			model = "gfx/icons/hud@us_grenade.tga";
			break;

		case "frag_grenade_british_mp":
		case "cook_frag_grenade_british_mp":
		case "cook2_frag_grenade_british_mp":
		case "cook3_frag_grenade_british_mp":
			model = "gfx/icons/hud@british_grenade.tga";
			break;

		case "frag_grenade_russian_mp":
		case "cook_frag_grenade_russian_mp":
		case "cook2_frag_grenade_russian_mp":
		case "cook3_frag_grenade_russian_mp":
			model = "gfx/icons/hud@russian_grenade.tga";
			break;	

		default:
			model = "gfx/icons/hud@steilhandgrenate.tga";
			break;
	}
	return model;
}

PunishMe(iMethod, sReason)
{
	self endon("awe_killthreads");

	sMethodname = "";

	if(iMethod == 1)
		iMethod = 2 + randomInt(level.awe_punishments);

	switch (iMethod)
	{
		case 2:
			self suicide();
			sMethodname = "killed";
			break;

		case 3:
			wait 0.5;
			// explode 
			playfx(level._effect["bombexplosion"], self.origin);
			wait .05;
			self suicide();
			sMethodname = "blown up";
			break;
		
		case 4:
			// Drop a piano on the player
			level thread DropPiano(self);
			sMethodname = "crushed";
			break;

// La Truffe ->
		case 5 :
			wait 1;
			kick (self getEntityNumber());
			sMethodname = "kicked";
			break;

		case 6 :
			wait 1;
			self thread freezeMe (60);
			sMethodname = "frozen";
			break;
// La Truffe <-

		default:
			break;
	}
	if(iMethod)
		iprintln(self.name + "^7 is being " + sMethodname + " ^7for " + sReason + "^7.");
}

// La Truffe ->
freezeMe (duration)
{
	self endon ("awe_killthreads");
	self endon ("disconnect");
	self endon ("killed_player");
	
	self freezeControls (true);
	wait duration;
	self freezeControls (false);
}
// La Truffe <-

getGrenadeType(team)
{
	switch(team)
	{
		case "american":
			type = level.awe_cook + "frag_grenade_american_mp";
			break;
		case "british":
			type = level.awe_cook + "frag_grenade_british_mp";
			break;
		case "russian":
			type = level.awe_cook + "frag_grenade_russian_mp";
			break;
		default:
			type = level.awe_cook + "frag_grenade_german_mp";
			break;
	}
	return type;
}

getSmokeGrenadeType(team)
{
	switch(team)
	{
		case "american":
			type = level.awe_smoke + "smoke_grenade_american_mp";
			break;
		case "british":
			type = level.awe_smoke + "smoke_grenade_british_mp";
			break;
		case "russian":
			type = level.awe_smoke + "smoke_grenade_russian_mp";
			break;
		default:
			type = level.awe_smoke + "smoke_grenade_german_mp";
			break;
	}
	return type;
}

DropPiano(victim)
{
	level endon("awe_killthreads");

	falltime = 2;
	yaw = victim.angles[1];
	offset = (-25 + randomInt(51), -25 + randomInt(51), 3000);
	piano = spawn("script_model", victim.origin + offset);
	piano setModel("xmodel/" + level.awe_crushmodels[randomInt(level.awe_crushmodels.size)]);
	piano.angles = (0,yaw,0);
	piano show();
	piano moveto(victim.origin, falltime);
	origin = victim.origin;

	deltayaw = -10 + randomInt(21);

	for(i=2;i<falltime*20;i++)
	{
		if(isDefined(victim) && isPlayer(victim) && isAlive(victim))
			victim setOrigin(origin);

		piano.angles = (0,yaw,0);
		yaw += deltayaw;
		wait .05;
	}
	if(isDefined(victim) && isPlayer(victim) && isAlive(victim))
	{
		victim setOrigin(origin);
		victim suicide();
	}
	wait 0.1;
	playfx(level._effect["awe_dustimpact"],origin);
	piano playsound("wood_door_shoulderhit");
	piano thread putinQ("piano");
	wait 45;
	if(isdefined(piano))
	{
//		playfx(level._effect["awe_dustimpact"],origin);
		piano moveto(origin + offset, falltime);
		wait falltime;
		if(isdefined(piano)) piano delete();
	}
}