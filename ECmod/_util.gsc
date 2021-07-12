/** Sh0k'
Used to strip the ec_rifleList cvar and determine if a map should be restricted to rifles only
 */
isRiflesOnly(mapname){

    //convert the string into an array delimited by ","
    arr = awe\_util::explode(level.ec_rifleList, ",");

    //trim whitespaces
    for (i = 0; i < arr.size; i++)
        arr[i] = awe\_util::strip(arr[i]);
    
    for (j = 0; j < arr.size; j++){
        if (mapname == arr[j])
            return true;
    }

    return false;
}