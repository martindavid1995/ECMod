init()
{
	level.awe_efogstr = awe\_util::cvardef("awe_efog", "none", "", "", "string");
	if(level.awe_efogstr == "none") return;

	efogstr = awe\_util::strip(level.awe_efogstr);
	if(efogstr=="")	return;

	efog = awe\_util::explode(efogstr," ");
	if(efog.size != 6)	return;

	level.awe_efog 		= int(efog[0]);
	level.awe_efogdensity	= float(efog[1]);
	level.awe_efogdensity2	= float(efog[2]);
	level.awe_efogred		= float(efog[3]);
	level.awe_efoggreen	= float(efog[4]);
	level.awe_efogblue	= float(efog[5]);

	level thread StartThreads();
}

float(temp)
{
	setcvar("awe_float", temp);
	temp = getCvarFloat("awe_float");
	return temp;
}

StartThreads()
{
	level endon("awe_killthreads");
	wait .05;
	level thread overridefog();
}

overridefog()
{
	level endon("awe_killthreads");
	if(randomInt(100) < level.awe_efog)
	{
		if(level.awe_efogdensity2)
			thread fadeExpFog();
		else
			setExpFog(level.awe_efogdensity, level.awe_efogred, level.awe_efoggreen, level.awe_efogblue, 0);
	}
}

fadeExpFog()
{
	level endon("awe_killthreads");

	if(level.awe_roundbased)
	{
		time = level.roundlength * 30;
		if(!time) time = 5 * 30;
	}
	else
	{
		time = level.timelimit * 30;
		if(!time) time = 20 * 30;
	}
	if(randomInt(2))
	{
		start = level.awe_efogdensity;
		end = level.awe_efogdensity2;
	}
	else
	{
		start = level.awe_efogdensity2;
		end = level.awe_efogdensity;
	}
	density = start;
	delta = (end - start)/time;
	for(i=0;i<time;i++)
	{
		setExpFog(density, level.awe_efogred, level.awe_efoggreen, level.awe_efogblue, 0);
		density = density + delta;
		wait 1;
	}
	density = end;
	delta = 0 - delta;
	for(i=0;i<time;i++)
	{
		setExpFog(density, level.awe_efogred, level.awe_efoggreen, level.awe_efogblue, 0);
		density = density + delta;
		wait 1;
	}
	density = start;
	delta = 0 - delta;
	for(i=0;i<time;i++)
	{
		setExpFog(density, level.awe_efogred, level.awe_efoggreen, level.awe_efogblue, 0);
		density = density + delta;
		wait 1;
	}
	density = end;
	delta = 0 - delta;
	for(i=0;i<time;i++)
	{
		setExpFog(density, level.awe_efogred, level.awe_efoggreen, level.awe_efogblue, 0);
		density = density + delta;
		wait 1;
	}
}
