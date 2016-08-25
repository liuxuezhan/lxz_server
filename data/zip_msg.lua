----------------------------------------------压缩数据--------------------------------------------------------------------------------
g_msgid = {
    ---通信
    cs_open =1, 
    cs_enter =2, 
}
g_msg = {}
g_msg[g_msgid.cs_open] = {"mid","host","port","tid","pwd","sid"} --链接loginserver
g_msg[g_msgid.cs_enter] = {"mid","tid","pid"} --进入game
