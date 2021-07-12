/** Sh0k'
This script is needed to account for the bump in sv_fps from 20 to 30. We use these
constants to tweak any wait() command to match up with the new game speed. 
 */
init(){
    pullSVFPS();

}

pullSVFPS(){
    //If we're overclocked
    if (getcvarint("sv_fps") == 30){
        level.ec_fpsMultiplier = 1.51382; //Constant value adapted from PAM v2.04
        level.frame = .033; //Constant value adapted from PAM v2.04
    }  
    else{
        level.ec_fpsMultiplier = 1;
        level.frame = .05;
    }
       
}

