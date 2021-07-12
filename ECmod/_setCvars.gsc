init(){
    level thread printDev();
}

printDev(){
  if (level.ec_devMode == 0)
        return;

    while(1){          
        iprintln("^2dev: ", level.ec_devMode);
        iprintln("^4startGame", getcvar("startGame"));
        iprintln("^1halftime", isdefined(level.doneHalftime));
        iprintln("game[pregame]", game["pregame"]);
        wait(5);   
    }

}
