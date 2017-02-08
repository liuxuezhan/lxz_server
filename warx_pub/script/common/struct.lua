local Struct = {}

Struct.UnionMember = "int pid, string name, int lv, int language, int rank, string title, int photo, int eid, int x,\
					  int y, int pow, int tm_login, int tm_logout, int buildlv, int propid, int tm_join"
Struct.UnionEnlist = "string text, int lv, int pow,int check"
Struct.UnionRankAlias = "Array string rank_alias"
Struct.UnionInfo = "int uid,int new_union_sn, string name, string alias, int mars_propid, int membercount,\
                    int memberlimit, int language, int flag, string note_in, string leader, int pow, int tm_buf_over,\
                    Struct UnionEnlist enlist, int state, int range, Array string rank_alias"
Struct.PlayerInfo = "int pid, string name,int language,int photo,int pow"


RpcType._struct = Struct
