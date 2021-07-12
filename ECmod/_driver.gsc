/** Sh0k'
Sets up custom cvars and inits all custom scripts that are globally used
 */
init(){
    
    setupConfigCvars();
    
    //Init custom script gsc's
    ECmod\_fpsMultiplier::init(); 
    ECmod\_setCvars::init(); 
    ECmod\_precache::init();
    

}

/** Sh0k'
Setting up the custom cvars in the mod config
 */
setupConfigCvars(){
    level.ec_devMode = awe\_util::cvardef("ec_devMode", 0, 0, 1, "int");
    level.ec_bombTimer = awe\_util::cvardef("ec_bombTimer", 60, 1, 120, "int");
    level.ec_rifleList = awe\_util::cvardef("ec_rifleList", "", "", "", "string");
    level.ec_sdHalftime = awe\_util::cvardef("ec_sdHalftime", 0, 0, 100, "int");
    level.ec_sdStratTime = awe\_util::cvardef("ec_sdStratTime", 10, 0, 100, "int");
    level.ec_sdFirstRoundStratTime = awe\_util::cvardef("ec_sdFirstRoundStratTime", 20, 0, 100, "int");
    setcvar("startGame", 0);

}

