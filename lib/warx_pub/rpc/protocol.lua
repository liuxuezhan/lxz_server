local Protocol =  {}

Protocol.Server = {
    firstPacket = "int id, string account, string pasw",
    login = "",
    onBreak = "",
    onQryCross = "int toPid, int sn, int smap, int spid, string cmd, pack arg",
    onAckCross = "int smap, int sn, int code, pack arg",

    hello = "int pid1, int pid2, string text",
    say = "string say, int nouse",
    say1 = "string say, int nouse",
    chat = "int did, string word",
    testPack = "int i, pack p, string s",
    qryInfo = "int pid",
    qryAround = "",
    seige = "int dpid, pack troop",
    reap = "string id",
    build = "int x, int y, int buildid",
    upgrade = "string id",
    train = "string buildid, int armid, int num",
    draft = "string buildid",

    geniusDo = "int id",
    learn_tech = "int build_idx, int tech_id",

    debugStart = "",
    debugInput = "s",
    debugClose = "",
}


Protocol.Client = {
    onQryCross = "int toPid, int sn, int smap, int spid, string cmd, pack arg",
    onAckCross = "int smap, int sn, int code, pack arg",

    hello = "int pid1, int pid2, string text",
    onLogin = "int pid, string name",
    say = "string say, int nouse",
    say1 = "string say, int nouse",
    chat = "int sid, string name, string word",
    testPack = "int i, pack p, string s",

    qryInfo = "pack info",
    qryAround = "pack objs",

    tips = "string s",
}

return Protocol
