// THIS FILE IS AUTOGENERATED, DO NOT MODIFY
main()
{
	codescripts\character::setModelFromArray(xmodelalias\mp_body_british_africa::main());
	self attach("xmodel/head_british_chance", "", true);
	self.awe_headmodel = "xmodel/head_british_chance";
	self.hatModel = "xmodel/helmet_british_afrca";
	self attach(self.hatModel, "", true);
	self setViewmodel("xmodel/viewmodel_hands_british_bare");
}

precache()
{
	codescripts\character::precacheModelArray(xmodelalias\mp_body_british_africa::main());
	precacheModel("xmodel/head_british_chance");
	precacheModel("xmodel/helmet_british_afrca");
	precacheModel("xmodel/viewmodel_hands_british_bare");
}
