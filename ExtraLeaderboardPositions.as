// ############################## MAIN #############################

void Main() {
#if TMNEXT

    if(!UserCanUseThePlugin()){
        print("Waiting 30 more seconds for permissions...");
        // Use local delta sleep tracking instead of an un-ticked global property
        uint64 permissionTimeout = Time::Now + (30 * 1000);
        while (Time::Now < permissionTimeout) {
            yield();
        }
        if(!UserCanUseThePlugin()){
            warn("You currently don't have the permissions to use this plugin, you at least need the club edition");
            warn("If you do have the permissions, the plugin checks every 30 seconds and should work when you finished loading into the main menu");
            
            while (!UserCanUseThePlugin()) {
                sleep(30000); // Sleep the thread cleanly for 30 seconds
            }
        }
        print("Permission granted!");
    }
    startupEnded = true;
    // Add the audiences you need
    NadeoServices::AddAudience("NadeoServices");
    NadeoServices::AddAudience("NadeoLiveServices");

    // Wait until the services are authenticated
    while (!NadeoServices::IsAuthenticated("NadeoServices") || !NadeoServices::IsAuthenticated("NadeoLiveServices")) {
        yield();
    }

    auto app = cast<CTrackMania>(GetApp());
    auto network = cast<CTrackManiaNetwork>(app.Network);

    while(true){
        //if we're on a new map, the timer is over or a new pb has been made we update the times
        if(refreshPosition){
            if(CanRefresh()){
                // Double-guard the playground pointers to eliminate random race-condition crashes
                if (network.ClientManiaAppPlayground !is null && 
                    network.ClientManiaAppPlayground.Playground !is null && 
                    network.ClientManiaAppPlayground.Playground.Map !is null) {
                    
                    string mapid = network.ClientManiaAppPlayground.Playground.Map.MapInfo.MapUid;
                    if(MapHasNadeoLeaderboard(mapid)){
                        validMap = true;
                        RefreshLeaderboard();
                    }else{
                        validMap = false;
                        ClearLeaderboard();
                    }
                } else {
                    validMap = false;
                    ClearLeaderboard();
                }
            }else{
                ClearLeaderboard();
            }

            refreshPosition = false;
        }
        yield();

    }

#endif
}

/**
 * Checks if we are in a position to refresh the times or not
 */
bool CanRefresh() {
    auto app = cast<CTrackMania>(GetApp());
    if (app is null || app.Network is null) return false;

    auto network = cast<CTrackManiaNetwork>(app.Network);

    //check that we're in a map
    if (network.ClientManiaAppPlayground is null || 
        network.ClientManiaAppPlayground.Playground is null || 
        network.ClientManiaAppPlayground.Playground.Map is null) {
        return false;
    }

    // check that we're not in an invalid gamemode
    if (network.ServerInfo is null) return false;
    auto ServerInfo = cast<CTrackManiaNetworkServerInfo>(network.ServerInfo);
    string gamemode = ServerInfo.CurGameModeStr;

    if(invalidGamemodes.Find(gamemode) != -1){
        return false;
    }

    //we don't want to update the times if we know the current refresh has already failed.
    //This should not deadlock because other parts of the plugin will be able to unlock this
    if(failedRefresh){
        return false;
    }

    return true;
}

void ClearLeaderboard() {
    if(leaderboardArray.Length > 0){
        leaderboardArray = array<LeaderboardEntry@>();
    }
    currentPbEntry = LeaderboardEntry();
    currentPbEntry.entryType = EnumLeaderboardEntryType::PB;
    currentPbEntry.desc = "PB";
    timeDifferenceEntry = LeaderboardEntry();
}