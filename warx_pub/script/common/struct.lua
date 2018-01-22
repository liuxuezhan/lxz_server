local Struct = {}

Struct.UnionMember = "int pid, string name, int lv, int language, int rank, string title, int photo, int eid, int x,int y, int pow, int tm_login, int tm_logout, int buildlv, int propid, int tm_join, int donate, int nation"
Struct.UnionEnlist = "string text, int lv, int pow,int check"
Struct.UnionRankAlias = "array string rank_alias"
Struct.UnionInfo = "int uid,int new_union_sn, string name, string alias, int mars_propid, int membercount,int memberlimit, int language, int flag, string note_in, string leader, int pow, int tm_buf_over,struct UnionEnlist enlist, int state, array string rank_alias,int online, int online_h"
Struct.PlayerInfo = "int pid, string name,int language,int photo,int pow, int nation"
Struct.UnionRank = "int what, array struct UnionRank1 val"
Struct.UnionRank1 = "int rank, string name,int techexp,int pid, int donate,int photo "

RpcType._struct = Struct
