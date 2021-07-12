init()
{
	// Pop helmet
	level.awe_pophelmet 		= awe\_util::cvardef("awe_pophelmet", 50, 0, 100, "int");

	// head popping controls
	level.awe_pophead			= awe\_util::cvardef("awe_pophead", 0, 0, 100, "int");
	level.awe_popheadbullet		= awe\_util::cvardef("awe_pophead_bullet", 1, 0, 1, "int");
	level.awe_popheadmelee		= awe\_util::cvardef("awe_pophead_melee", 1, 0, 1, "int");
	level.awe_popheadexplosion	= awe\_util::cvardef("awe_pophead_explosion", 1, 0, 1, "int");

	// Set up object queues
	if(level.awe_pophead)
	{
		level.awe_objectQ["head"] = [];
		level.awe_objectQcurrent["head"] = 0;
		level.awe_objectQsize["head"] = 4;
	}
	if(level.awe_pophelmet)
	{
		level.awe_objectQ["helmet"] = [];
		level.awe_objectQcurrent["helmet"] = 0;
		level.awe_objectQsize["helmet"] = 8;
	}

	// Flesh hit effect used by bouncing heads
	if(level.awe_pophead)
		level.awe_popheadfx = loadfx("fx/impacts/flesh_hit.efx");
}

CleanupKilled()
{
	self.awe_helmetpopped = false;
	self.awe_headpopped = false;
}

popHelmet( damageDir, damage)
{
	self.awe_helmetpopped = true;

	if(!isdefined(self.hatModel))
		return;

	self detach( self.hatModel , "");

	if(isPlayer(self))
	{
		switch(self.awe_stance)
		{
			case 2:
				helmetoffset = (0,0,15);
				break;
			case 1:
				helmetoffset = (0,0,44);
				break;
			default:
				helmetoffset = (0,0,64);
				break;
		}
	}
	else
		helmetoffset = (0,0,15);

//	iprintln("hatModel:" + self.hatModel);
	switch(self.hatModel)
	{
		case "xmodel/helmet_russian_trench_a_hat":
		case "xmodel/helmet_russian_trench_b_hat":
		case "xmodel/helmet_russian_trench_c_hat":
		case "xmodel/helmet_russian_padded_a":
			bounce = 0.2;
			impactsound = undefined;
			break;
		default:
			bounce = 0.7;
			impactsound = "helmet_bounce_";
			break;
	}		

	rotation = (randomFloat(540), randomFloat(540), randomFloat(540));
	offset = (0,0,3);
	radius = 6;
	velocity = maps\mp\_utility::vectorScale(damageDir, (damage/20 + randomFloat(5)) ) + (0,0,(damage/20 + randomFloat(5)) );

	helmet = spawn("script_model", self.origin + helmetoffset );
	helmet setmodel( self.hatModel );
	helmet.angles = self.angles;
	helmet.targetname = "popped helmet";
	helmet thread awe\_util::bounceObject(rotation, velocity, offset, (0,0,0), radius, bounce, impactsound, undefined, "helmet");
}

popHead( damageDir, damage)
{
	self.awe_headpopped = true;

	if(!self.awe_helmetpopped)
		self popHelmet( damageDir, damage );

	if(!isdefined(self.awe_headmodel))
		return;

	self detach( self.awe_headmodel , "");
	playfxontag (level.awe_popheadfx,self,"J_Neck");

	if(isPlayer(self))
	{
		switch(self.awe_stance)
		{
			case 2:
				headoffset = (0,0,16);
				break;
			case 1:
				headoffset = (0,0,45);
				break;
			default:
				headoffset = (0,0,65);
				break;
		}
	}
	else
		headoffset = (0,0,16);
	
	rotation = (randomFloat(540), randomFloat(540), randomFloat(540));
	offset = (-2,0,-13);
	radius = 6;

	velocity = maps\mp\_utility::vectorScale(damageDir, (damage/20 + randomFloat(5)) ) + (0,0,(damage/20 + randomFloat(5)) );

	head = spawn("script_model", self.origin + headoffset );
	head setmodel( self.awe_headmodel );
	head.angles = self.angles;
	head thread awe\_util::bounceObject(rotation, velocity, offset, (-90,0,-90), radius, 0.75, "Land_", level.awe_popheadfx, "head");
}

delayedbloodfx()
{
	x = 2 + randomint(4);
	for(i=0;i<x;i++)
	{
		wait 0.25 + randomfloat(i);
		if(isdefined(self))
			playfxontag (level.awe_popheadfx,self,"J_Neck");
	}

/*	x = 15 + randomint(10);
	if(isdefined(level.awe_bleedingfx))
	{
		for(i=0;i<x && isdefined(self);i++)
		{
			s = 0;
			for(k = 0 ; k < 3 ; k++ )
			{
				p = (randomInt(2) *.1) + (randomInt(5) * .01);
				if(isdefined(self))
					playfxontag(level.awe_bleedingfx, self ,"J_Neck" );
				wait p;
				s = s + p;
			}
			wait (.75 - s);
		}
	}*/
}
