// THIS FILE IS AUTOGENERATED, DO NOT MODIFY
main()
{
	codescripts\character::setModelFromArray(xmodelalias\mp_body_american_normandy::main());
	self attach("xmodel/head_us_ranger_frank", "", true);
	self.awe_headmodel = "xmodel/head_us_ranger_frank";
	self.hatModel = "xmodel/helmet_us_ranger_generic";
	self attach(self.hatModel, "", true);
	self setViewmodel("xmodel/viewmodel_hands_cloth");
}

precache()
{
	codescripts\character::precacheModelArray(xmodelalias\mp_body_american_normandy::main());
	precacheModel("xmodel/head_us_ranger_frank");
	precacheModel("xmodel/helmet_us_ranger_generic");
	precacheModel("xmodel/viewmodel_hands_cloth");
}
