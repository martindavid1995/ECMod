//Retrieval Concept by Etromania www.wclan.com - etromania@wclan.com
//_retrieval.gsc sets up the moved map and capture location on some maps 
initflag()
{

	if(getcvar("mapname") == "mp_brecourt")
	{
	 	brecourt();
	}
	if(getcvar("mapname") == "mp_dawnville")
	{
	 	dawnville();
	}
	
	if(getcvar("mapname") == "mp_breakout")
	{
	 	breakout();
	}
	
	if(getcvar("mapname") == "mp_railyard")
	{
		railyard();
	}
	
	if(getcvar("mapname") == "mp_leningrad")
	{
		leningrad();
	}
	
	if(getcvar("mapname") == "mp_downtown")
	{
		downtown();
	}

	if(getcvar("mapname") == "mp_matmata")
	{
		matmata();
	}

	if(getcvar("mapname") == "mp_farmhouse")
	{
		farmhouse();
	}
	
}
railyard()
{
	
	allied_flag = getent("allied_flag", "targetname");
	allied_flag.home_origin = allied_flag.origin + (-690, 585, 127);
	allied_flag.home_angles = allied_flag.angles + (0, 91, 0);
	allied_flag.flagmodel = spawn("script_model", allied_flag.home_origin);
	allied_flag.flagmodel.angles = allied_flag.home_angles;
	allied_flag.flagmodel setmodel("xmodel/prop_map_2");
	allied_flag.team = "allies";
	allied_flag.atbase = true;
	allied_flag.objective = 0;
	allied_flag.compassflag = level.compassflag_allies;


	if(getcvar("scr_ctf_sl") == "1")//shows flags across map
	{
		allied_flag.objpointflag = level.objpointflag_allies;
	}
	
	allied_flag thread flag();

	axis_flag = getent("axis_flag", "targetname");
	axis_flag.home_origin = axis_flag.origin + (820, -543, 380);
	axis_flag.home_angles = axis_flag.angles;
	axis_flag.flagmodel = spawn("script_model", axis_flag.home_origin);
	axis_flag.flagmodel.angles = axis_flag.home_angles;
	axis_flag.flagmodel setmodel("xmodel/prop_map_case_1");
	axis_flag.team = "axis";
	axis_flag.atbase = true;
	axis_flag.objective = 1;
	axis_flag.compassflag = level.compassflag_axis;

	if(getcvar("scr_ctf_sl") == "1")//shows flags across map
		{
		axis_flag.objpointflag = level.objpointflag_axis;
		}
	axis_flag thread flag1();

}
dawnville()
{
	
	allied_flag = getent("allied_flag", "targetname");
	allied_flag.home_origin = allied_flag.origin + (1490, -450, 140);
	allied_flag.home_angles = allied_flag.angles;
	
	allied_flag.flagmodel = spawn("script_model", allied_flag.home_origin);
	allied_flag.flagmodel.angles = allied_flag.home_angles;
	allied_flag.flagmodel setmodel("xmodel/prop_map_3");
	allied_flag.team = "allies";
	allied_flag.atbase = true;
	allied_flag.objective = 0;
	allied_flag.compassflag = level.compassflag_allies;

	if(getcvar("scr_ctf_sl") == "1")//shows flags across map
	{
		allied_flag.objpointflag = level.objpointflag_allies;
		
	}
	
	allied_flag thread flag();

	axis_flag = getent("axis_flag", "targetname");
	axis_flag.home_origin = axis_flag.origin + (-1350, -50, 60);
	axis_flag.home_angles = axis_flag.angles+ (2, 100, -100);
	axis_flag.flagmodel = spawn("script_model", axis_flag.home_origin);
	axis_flag.flagmodel.angles = axis_flag.home_angles;
	axis_flag.flagmodel setmodel("xmodel/prop_map_case_1");
	axis_flag.team = "axis";
	axis_flag.atbase = true;
	axis_flag.objective = 1;
	axis_flag.compassflag = level.compassflag_axis;

	if(getcvar("scr_ctf_sl") == "1")//shows flags across map
		{
		axis_flag.objpointflag = level.objpointflag_axis;
		}
	axis_flag thread flag1();
}


farmhouse()
{
	allied_flag = getent("allied_flag", "targetname");
	allied_flag.home_origin = allied_flag.origin + (-765, 109, 227);
	allied_flag.home_angles = allied_flag.angles;
	allied_flag.flagmodel = spawn("script_model", allied_flag.home_origin);
	allied_flag.flagmodel.angles = allied_flag.home_angles;
	allied_flag.flagmodel setmodel("xmodel/prop_map_2");
	allied_flag.team = "allies";
	allied_flag.atbase = true;
	allied_flag.objective = 0;
	allied_flag.compassflag = level.compassflag_allies;

	if(getcvar("scr_ctf_sl") == "1")//shows flags across map
		{
		allied_flag.objpointflag = level.objpointflag_allies;
		

		}

	allied_flag thread flag();

	

	axis_flag = getent("axis_flag", "targetname");
	axis_flag.home_origin = axis_flag.origin + (-170, -1550, 170);
	axis_flag.home_angles = axis_flag.angles+ (0, 150, 0);
	axis_flag.flagmodel = spawn("script_model", axis_flag.home_origin);
	axis_flag.flagmodel.angles = axis_flag.home_angles;
	axis_flag.flagmodel setmodel("xmodel/prop_map_case_1");
	axis_flag.team = "axis";
	axis_flag.atbase = true;
	axis_flag.objective = 2;
	axis_flag.compassflag = level.compassflag_axis;

	if(getcvar("scr_ctf_sl") == "1")//shows flags across map
		{
		axis_flag.objpointflag = level.objpointflag_axis;
		}
	axis_flag thread flag1();
}
leningrad()
{
	allied_flag = getent("allied_flag", "targetname");
	allied_flag.home_origin = allied_flag.origin + (-695, -70, 61);
	allied_flag.home_angles = allied_flag.angles;
	allied_flag.flagmodel = spawn("script_model", allied_flag.home_origin);
	allied_flag.flagmodel.angles = allied_flag.home_angles;
	allied_flag.flagmodel setmodel("xmodel/prop_map_3");
	allied_flag.team = "allies";
	allied_flag.atbase = true;
	allied_flag.objective = 0;
	allied_flag.compassflag = level.compassflag_allies;

	if(getcvar("scr_ctf_sl") == "1")//shows flags across map
		{
		allied_flag.objpointflag = level.objpointflag_allies;
		

		}

	allied_flag thread flag();

	

	axis_flag = getent("axis_flag", "targetname");
	axis_flag.home_origin = axis_flag.origin + (0, 1116, 140);
	axis_flag.home_angles = axis_flag.angles + (0, 0, 0);
	axis_flag.flagmodel = spawn("script_model", axis_flag.home_origin);
	axis_flag.flagmodel.angles = axis_flag.home_angles;
	axis_flag.flagmodel setmodel("xmodel/prop_map_case_1");
	axis_flag.team = "axis";
	axis_flag.atbase = true;
	axis_flag.objective = 1;
	axis_flag.compassflag = level.compassflag_axis;

	if(getcvar("scr_ctf_sl") == "1")//shows flags across map
		{
		axis_flag.objpointflag = level.objpointflag_axis;
		}
	axis_flag thread flag1();
}

downtown()
{
	allied_flag = getent("allied_flag", "targetname");
	allied_flag.home_origin = allied_flag.origin;
	allied_flag.home_angles = allied_flag.angles;
	allied_flag.flagmodel = spawn("script_model", allied_flag.home_origin);
	allied_flag.flagmodel.angles = allied_flag.home_angles;
	allied_flag.flagmodel setmodel("xmodel/prop_map_3");
	allied_flag.team = "allies";
	allied_flag.atbase = true;
	allied_flag.objective = 0;
	allied_flag.compassflag = level.compassflag_allies;

	if(getcvar("scr_ctf_sl") == "1")//shows flags across map
		{
		allied_flag.objpointflag = level.objpointflag_allies;
		

		}

	allied_flag thread flag();

	axis_flag = getent("axis_flag", "targetname");
	axis_flag.home_origin = axis_flag.origin;
	axis_flag.home_angles = axis_flag.angles;
	axis_flag.flagmodel = spawn("script_model", axis_flag.home_origin);
	axis_flag.flagmodel.angles = axis_flag.home_angles;
	axis_flag.flagmodel setmodel("xmodel/prop_map_case_1");
	axis_flag.team = "axis";
	axis_flag.atbase = true;
	axis_flag.objective = 1;
	axis_flag.compassflag = level.compassflag_axis;

	if(getcvar("scr_ctf_sl") == "1")//shows flags across map
		{
		axis_flag.objpointflag = level.objpointflag_axis;
		}
	axis_flag thread flag1();
}
matmata()
{
	allied_flag = getent("allied_flag", "targetname");
	allied_flag.home_origin = allied_flag.origin;
	allied_flag.home_angles = allied_flag.angles;
	allied_flag.flagmodel = spawn("script_model", allied_flag.home_origin);
	allied_flag.flagmodel.angles = allied_flag.home_angles;
	allied_flag.flagmodel setmodel("xmodel/prop_map_3");
	allied_flag.team = "allies";
	allied_flag.atbase = true;
	allied_flag.objective = 0;
	allied_flag.compassflag = level.compassflag_allies;

	if(getcvar("scr_ctf_sl") == "1")//shows flags across map
		{
		allied_flag.objpointflag = level.objpointflag_allies;
		

		}

	allied_flag thread flag();

	axis_flag = getent("axis_flag", "targetname");
	axis_flag.home_origin = axis_flag.origin;
	axis_flag.home_angles = axis_flag.angles;
	axis_flag.flagmodel = spawn("script_model", axis_flag.home_origin);
	axis_flag.flagmodel.angles = axis_flag.home_angles;
	axis_flag.flagmodel setmodel("xmodel/prop_map_case_1");
	axis_flag.team = "axis";
	axis_flag.atbase = true;
	axis_flag.objective = 1;
	axis_flag.compassflag = level.compassflag_axis;

	if(getcvar("scr_ctf_sl") == "1")//shows flags across map
		{
		axis_flag.objpointflag = level.objpointflag_axis;
		}
	axis_flag thread flag1();
}
breakout()
{
	allied_flag = getent("allied_flag", "targetname");
	allied_flag.home_origin = allied_flag.origin + (-195, -2150, 82);
	allied_flag.home_angles = allied_flag.angles;
	allied_flag.flagmodel = spawn("script_model", allied_flag.home_origin);
	allied_flag.flagmodel.angles = allied_flag.home_angles;
	allied_flag.flagmodel setmodel("xmodel/prop_map_3");
	allied_flag.team = "allies";
	allied_flag.atbase = true;
	allied_flag.objective = 0;
	allied_flag.compassflag = level.compassflag_allies;

	if(getcvar("scr_ctf_sl") == "1")//shows flags across map
		{
		allied_flag.objpointflag = level.objpointflag_allies;
		

		}

	allied_flag thread flag();

	axis_flag = getent("axis_flag", "targetname");
	axis_flag.home_origin = axis_flag.origin + (-1700, 2200, -10);
	axis_flag.home_angles = axis_flag.angles+ (0, 300, 0);
	axis_flag.flagmodel = spawn("script_model", axis_flag.home_origin);
	axis_flag.flagmodel.angles = axis_flag.home_angles;
	axis_flag.flagmodel setmodel("xmodel/prop_map_case_1");
	axis_flag.team = "axis";
	axis_flag.atbase = true;
	axis_flag.objective = 1;
	axis_flag.compassflag = level.compassflag_axis;

	if(getcvar("scr_ctf_sl") == "1")//shows flags across map
		{
		axis_flag.objpointflag = level.objpointflag_axis;
		}
	axis_flag thread flag1();
}
brecourt()
{
	allied_flag = getent("allied_flag", "targetname");
	allied_flag.home_origin = allied_flag.origin + (-400, 1900, 9);
	allied_flag.home_angles = allied_flag.angles;
	allied_flag.flagmodel = spawn("script_model", allied_flag.home_origin);
	allied_flag.flagmodel.angles = allied_flag.home_angles;
	allied_flag.flagmodel setmodel("xmodel/prop_map_3");
	allied_flag.team = "allies";
	allied_flag.atbase = true;
	allied_flag.objective = 0;
	allied_flag.compassflag = level.compassflag_allies;

	if(getcvar("scr_ctf_sl") == "1")//shows flags across map
		{
		allied_flag.objpointflag = level.objpointflag_allies;
		

		}

	allied_flag thread flag();

	axis_flag = getent("axis_flag", "targetname");
	axis_flag.home_origin = axis_flag.origin + (-1027, -20, -37);
	axis_flag.home_angles = axis_flag.angles;
	axis_flag.flagmodel = spawn("script_model", axis_flag.home_origin);
	axis_flag.flagmodel.angles = axis_flag.home_angles;
	axis_flag.flagmodel setmodel("xmodel/prop_map_case_1");
	axis_flag.team = "axis";
	axis_flag.atbase = true;
	axis_flag.objective = 1;
	axis_flag.compassflag = level.compassflag_axis;

	if(getcvar("scr_ctf_sl") == "1")//shows flags across map
		{
		axis_flag.objpointflag = level.objpointflag_axis;
		}
	axis_flag thread flag1();
}

flag()
{
	
	if(getcvar("mapname") == "mp_brecourt")
	{
		self.origin = self.origin + (-400, 1900, 9);
	}

	if(getcvar("mapname") == "mp_breakout")
	{
		self.origin = self.origin + (-195, -2150, 82);
	}
	if(getcvar("mapname") == "mp_dawnville")
	{
		self.origin = self.origin + (1490, -450, 140);
	}
	if(getcvar("mapname") == "mp_railyard")
	{
		self.origin = self.origin + (-690, 585, 127);
	}
	
	if(getcvar("mapname") == "mp_leningrad")
	{
		self.origin = self.origin + (-695, -70, 61);
	}
	if(getcvar("mapname") == "mp_farmhouse")
	{
		self.origin = self.origin + (-765, 109, 227);
	}
	
	objective_add(self.objective, "current", self.origin, self.compassflag);
	self maps\mp\gametypes\re::createFlagWaypoint();

	for(;;)
	{
		self waittill("trigger", other);

		if(isPlayer(other) && isAlive(other) && (other.pers["team"] != "spectator"))
		{
			if(other.pers["team"] == self.team) // Touched by team
			{
				
				
				
				
			}
			else if(other.pers["team"] != self.team) // Touched by enemy
			{
				println("PICKED UP THE FLAG!");

				friendlyAlias = "ctf_touchenemy";
				enemyAlias = "ctf_enemy_touchenemy";

				if(self.team == "axis")
					enemy = "allies";
				else
					enemy = "axis";

				thread maps\mp\gametypes\re::playSoundOnPlayers(friendlyAlias, self.team);
				if(!level.splitscreen)
					thread maps\mp\gametypes\re::playSoundOnPlayers(enemyAlias, enemy);

				thread maps\mp\gametypes\re::printOnTeam(&"RE_YOUR_FLAG_WAS_TAKEN", self.team);
				thread maps\mp\gametypes\re::printOnTeam(&"RE_ENEMY_FLAG_TAKEN", enemy);

				other maps\mp\gametypes\re::pickupFlag(self); // Stolen flag
			}
		}
		wait 0.05;
	}
}
flag1()
{	
	if(getcvar("mapname") == "mp_brecourt")
	{
		self.origin = self.origin + (-1027, -20, -37);
	}
	if(getcvar("mapname") == "mp_breakout")
	{
		self.origin = self.origin + (-1700, 2200, -10);
	}
	if(getcvar("mapname") == "mp_dawnville")
	{
		self.origin = self.origin + (-1350, -50, 60);
	}
	if(getcvar("mapname") == "mp_railyard")
	{
		self.origin = self.origin + (820, -543, 380);
	}
	if(getcvar("mapname") == "mp_leningrad")
	{
		self.origin = self.origin + (0, 1116, 140);
	}
	if(getcvar("mapname") == "mp_farmhouse")
	{
		self.origin = self.origin + (-170, -1550, 170);
	}
	
	objective_add(self.objective, "current", self.origin, self.compassflag);
	self maps\mp\gametypes\re::createFlagWaypoint();

	for(;;)
	{
		self waittill("trigger", other);

		if(isPlayer(other) && isAlive(other) && (other.pers["team"] != "spectator"))
		{
			if(other.pers["team"] == self.team) // Touched by team
			{
				if(self.atbase)
				{
					if(isdefined(other.flag)) // Captured flag
					{
						println("CAPTURED THE FLAG!");

						friendlyAlias = "ctf_touchcapture";
						enemyAlias = "ctf_enemy_touchcapture";

						if(self.team == "axis")
							enemy = "allies";
						else
							enemy = "axis";

						thread maps\mp\gametypes\re::playSoundOnPlayers(friendlyAlias, self.team);
						if(!level.splitscreen)
							thread maps\mp\gametypes\re::playSoundOnPlayers(enemyAlias, enemy);

						thread maps\mp\gametypes\re::printOnTeam(&"RE_ENEMY_FLAG_CAPTURED", self.team);
						thread maps\mp\gametypes\re::printOnTeam(&"RE_YOUR_FLAG_WAS_CAPTURED", enemy);

						other.flag maps\mp\gametypes\re::returnFlag();
						other maps\mp\gametypes\re::detachFlag(other.flag);
						other.flag = undefined;

						//other.score += 3;
						self.pers["score"]++;
						self.score = self.pers["score"];
						teamscore = getTeamScore(other.pers["team"]);
						teamscore += 1;
						setTeamScore(other.pers["team"], teamscore);
						level notify("update_teamscore_hud");

						iprintln(&"MP_AXISMISSIONACCOMPLISHED");
						level thread maps\mp\gametypes\re::endRound("axis");
						
						maps\mp\gametypes\re::checkScoreLimit();
					}
				}
				
			}
			
		}
		wait 0.05;
	}
}
