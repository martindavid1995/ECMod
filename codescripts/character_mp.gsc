attachFromArray(a)
{
	self.awe_headmodel = codescripts\character::randomElement(a);
	self attach(self.awe_headmodel, "", true);
}
