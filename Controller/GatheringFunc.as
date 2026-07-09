// File containing all functions that gather data from the API


/**
 * Get the personal best time of the current map from the online leaderboard
 */
LeaderboardEntry@ GetPersonalBestEntry() {
    // initialize default no record entry
    LeaderboardEntry@ pbTimeTmp = LeaderboardEntry();
    pbTimeTmp.time = -1;
    pbTimeTmp.position = -1;
    pbTimeTmp.entryType = EnumLeaderboardEntryType::PB;
    pbTimeTmp.desc = "PB";

    if (!validMap) {
        return pbTimeTmp;
    }

    auto app = cast<CTrackMania>(GetApp());
    auto network = cast<CTrackManiaNetwork>(app.Network);

    // verify that we are on a valid map
    if (network.ClientManiaAppPlayground !is null && 
        network.ClientManiaAppPlayground.Playground !is null && 
        network.ClientManiaAppPlayground.Playground.Map !is null) {
        
        string mapid = network.ClientManiaAppPlayground.Playground.Map.MapInfo.MapUid;

        string route = "/api/token/leaderboard/group/Personal_Best/map/" + mapid + "/surround/0/0?onlyWorld=true";
        auto info = FetchNadeoEndpoint("NadeoLiveServices", route);

        // parse the result
        if (info.GetType() == Json::Type::Object) {
            auto tops = info["tops"];
            if (tops.GetType() == Json::Type::Array && tops.Length > 0) {
                auto top = tops[0]["top"];
                if (top.GetType() == Json::Type::Array && top.Length > 0) {
                    pbTimeTmp.time = top[0]["score"];
                    pbTimeTmp.position = top[0]["position"];
                }
            }
        }
    }

    return pbTimeTmp;
}


/**
 * Return the leaderboard entries of given friend account IDs
 */
array<LeaderboardEntry@> GetFriendsEntry(string _friends) {
    // initialize default no record entries
    array<LeaderboardEntry@> positionsEntry;
    
    if (!validMap || _friends == "") {
        return positionsEntry;
    }

    auto app = cast<CTrackMania>(GetApp());
    auto network = cast<CTrackManiaNetwork>(app.Network);

    // verify that we are on a valid map
    if (network.ClientManiaAppPlayground !is null && 
        network.ClientManiaAppPlayground.Playground !is null && 
        network.ClientManiaAppPlayground.Playground.Map !is null) {
        
        string mapid = currentMapId;
        
        string route = "/v2/mapRecords/by-account/?mapId=" + mapid + "&accountIdList=" + _friends + "&gameMode=TimeAttack";
        auto info = FetchNadeoEndpoint("NadeoServices", route);
        
        // parse the result
        if (info.GetType() == Json::Type::Array) {
            for (uint i = 0; i < info.Length; i++) {
                LeaderboardEntry@ positionEntry = LeaderboardEntry();
                auto friendItem = info[i];
                auto infoTop = friendItem["recordScore"];
                
                positionEntry.time = infoTop["time"];
                positionEntry.position = i + 1; 
                positionEntry.id = friendItem["accountId"];
                positionEntry.entryType = EnumLeaderboardEntryType::POSITION;
                positionEntry.desc = "Friend";

                // extract friends from data
                for (uint j = 0; j < allFriendsToGet.Length; j++) {
                    if (allFriendsToGet[j] == friendItem["accountId"]) {
                        positionEntry.name = allFriendsName[j];
                        break;
                    }
                }
                
                positionsEntry.InsertLast(positionEntry);
            }
        }
    }

    return positionsEntry;
}
