init()
{
	// Disable minefields
	level.awe_disableminefields = awe\_util::cvardef("awe_disable_minefields", 0, 0, 1, "int");

	if(!level.awe_disableminefields) return;

	minefields = getentarray( "minefield", "targetname" );
	if(minefields.size)
		for(i=0;i< minefields.size;i++)
			if(isdefined(minefields[i]))
				minefields[i] delete();
}
