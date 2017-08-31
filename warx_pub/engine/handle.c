#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>
#include <sys/stat.h>
#include <malloc_extension_c.h>
#include "handle.h"
#include "mylist.h"
#include "buf.h"
#include "log.h"
#include "net.h"
#include "timer.h"
#include "dbg.h"
#include "world.h"
#include "que.h"
#include "tlog.h"

extern int gMsec;
extern int gTime;
extern struct timeval tsStart;
extern int gTimeControl;
extern int gMap;
extern int gCpuTick;

static struct list_head gRecvPackQ;
static struct list_head gRecvTimerQ;
static int stackErrorHook = 0;

int gPkNum = 0;
int gDbNum = 0;
int gTmNum = 0;
int gRoiNum = 0;
int gRoi = 0;
int gGate = 0;

extern unsigned long TICK();

int luaopen_bson(lua_State *L);
int luaopen_mongo_driver(lua_State *L);
int luaopen_cmsgpack(lua_State *L);
int luaopen_skiplist_c(lua_State *L);

Que g_msg_from_roi;

typedef struct {
    int msgid;
    int d0;
    int d1;
    int d2;
    int d3;
    int d4;
    int d5;
    int d6;
    int d7;
    struct list_head link;
} MsgFromRoi;

int gDebug = 0;
int gBegJob = 0;
char *gScript = NULL;

enum LuaRef {
    REF_MAIN_LOOP = 1,
    REF_MAX
};
static int gRef[REF_MAX];

extern int g_obj_count[5];
extern int g_eye_count;
extern unsigned int g_obj_mem;
extern unsigned int gBufCount;
extern unsigned int gBufExtra;

struct list_head gRpcBufQ;

int lget_engine_mem(lua_State *L)
{

    size_t sz = 0, hsz = 0;
    MallocExtension_GetNumericProperty("generic.current_allocated_bytes", &sz);
    MallocExtension_GetNumericProperty("generic.heap_size", &hsz);

    lua_pushinteger(L, hsz >> 20);
    lua_pushinteger(L, sz >> 20);
    lua_pushinteger(L, lua_gc(L, LUA_GCCOUNT, 0) >> 10);
    lua_pushinteger(L, (gBufCount * sizeof(struct Buf) + gBufExtra) >> 20);
    lua_pushinteger(L, g_obj_mem >> 20);
    lua_pushinteger(L, gBufCount);
    lua_pushinteger(L, g_obj_count[0]);
    lua_pushinteger(L, g_obj_count[1]);
    lua_pushinteger(L, g_obj_count[2]);
    lua_pushinteger(L, g_obj_count[3]);
    lua_pushinteger(L, g_obj_count[4]);
    lua_pushinteger(L, g_eye_count);
    return 12;
}

void sh(int sig)
{
    if (gDebug) {
        printf("double debug, exit\n");
        exit(-1);
    }
    printf("start debug\n");
    gDebug = 1;
}


static void initRef(lua_State *L)
{
    int i, tmp;
    for (i = 0; i < REF_MAX; ++i) gRef[i] = LUA_NOREF;

    lua_getglobal( L, "main_loop" );
    if (lua_isnil(L, -1)) WARN("no do_packet");
    gRef[REF_MAIN_LOOP] = luaL_ref(L, LUA_REGISTRYINDEX);
}

int error_hook( lua_State* L )
{
    WARN( "[LUA] %s", lua_tostring(L, -1));
    lua_Debug ldb;
    int i = 0;
    for( i = 0; lua_getstack( L, i, &ldb ) == 1; i++ ) {
        lua_getinfo( L, "Slnu", &ldb );
        const char * name = ldb.name ? ldb.name : "";
        const char * filename = ldb.source ? ldb.source : "";
        WARN( "[LUA] %s '%s' @ file '%s', line %d\n", ldb.what, name, filename, ldb.currentline );
    }
    return 0;
}

void lua_loop(lua_State *L, int deadline)
{
    static int nframe = 0;
    static int nlast = 0; 
    static int ngc0 = 0;
    static int ngc1 = 0;
    static int npk = 0;
    static int nLuaMax = 0;
    static int nLuaPre = 0;

    int f_pk = recv_bufq( &gRecvPackQ );
    int f_tm = recv_timerq( &gRecvTimerQ );
    int f_roi = QuePeek( &g_msg_from_roi );

    if (gTelDebug) f_pk = recv_debugq(&gRecvPackQ) ? 1 : f_pk;

    nframe++;
    int memA = lua_gc(L, LUA_GCCOUNT, 0);
    if (f_pk || f_tm || f_roi || gDebug || gBegJob) {
        INIT_LIST_HEAD(&gRpcBufQ);

        unsigned long tick = TICK();
        gPkNum = 0;
        gDbNum = 0;
        gTmNum = 0;
        gRoiNum = 0;
        npk = nframe;
        int top = lua_gettop(L);
        lua_rawgeti(L, LUA_REGISTRYINDEX, gRef[REF_MAIN_LOOP]);
        lua_pushinteger(L, gTime);
        lua_pushinteger(L, gMsec);
        lua_pushinteger(L, f_pk);
        lua_pushinteger(L, f_tm);
        lua_pushinteger(L, f_roi);
        lua_pushinteger(L, gDebug);

        gDebug = 0;
        gBegJob = 0;

        lua_pcall(L, 6, 0, stackErrorHook);
        lua_settop(L, top);

        unsigned long uset = TICK() - tick;
        int m = uset / gCpuTick;
        if (m > 20) INFO("[CPU_FRAME], pk=%d, db=%d, tm=%d, roi=%d, use=%d, nframe=%d", gPkNum, gDbNum, gTmNum, gRoiNum, m, nframe);

        if (!LIST_EMPTY(&gRpcBufQ)) send_bufq(&gRpcBufQ);
    }

    if (gTimeControl) {
        //if (lua_gc(L, LUA_GCSTEP, 128) == 1) {
        //    lua_gc(L, LUA_GCRESTART, 0);
        //}
        return;
    }

    int memB = lua_gc(L, LUA_GCCOUNT, 0);
    if (ngc0 > npk) return ;

    int i;
    for (i = 0; i < 1024 && gMsec < deadline; ++i) {
        if (lua_gc(L, LUA_GCSTEP, 128) == 1) {
            lua_gc(L, LUA_GCRESTART, 0);
            ngc0 = ngc1;
            ngc1 = nframe;
            break;
        }
    }
    int memC = lua_gc(L, LUA_GCCOUNT, 0);
    int memNew = memB - memA;
    int memDel = memB - memC;

    if (memB > nLuaMax || memNew > 2000 || gTime - nlast > 60) {
        if (memB > nLuaMax) nLuaMax = memB;

        size_t sz = 0;
        size_t hsz = 0;
        MallocExtension_GetNumericProperty("generic.current_allocated_bytes", &sz);
        MallocExtension_GetNumericProperty("generic.heap_size", &hsz);

        size_t nbuf = gBufCount;
        size_t szbuf = gBufCount * sizeof(struct Buf) + gBufExtra;

        INFO("[LUA_MEM], Total=%d, Heap=%d, LuaMax=%d, LuaNow=%d, mBuf=%d, nBuf=%d", sz >> 20, hsz >> 20, nLuaMax >> 10, memC >> 10, szbuf>>20, nbuf);
        //INFO("[LUA_MEM], %d, %d, %d, %d, %d", memB, nLuaMax, memNew, gTime, nlast );
        nlast = gTime;
    }
    nLuaPre = memC;
}


#define CHECK_REMAIN(fsize, fcur, fend) \
    do { \
        if (fend - fcur < fsize) { \
            WARN("[WARN], protocol, pkmod=%d, pid=%d, pktype=%d", buf->mode, pid, pk); \
            fcur = fend; \
            return 0; \
        } \
    } while (0)
 
enum OP {OP_NEXT=1, OP_HEAD, OP_OVER, OP_AROUND, OP_FLUSH, OP_TEST, OP_HEAD2S, OP_PKG, OP_PACK, OP_I4, OP_F4, OP_S, OP_U4};

int pullBuf(lua_State *L, int op)
{
    static struct Buf *buf = NULL;
    static char *start = NULL;
    static char *cur = NULL;
    static char *end = NULL;
    static int pid;
    static int pk;
    static int mode;
    static unsigned long tick = 0;
    static unsigned long uset = 0;

    struct list_head *pos;

    int len;
    int i4;
    unsigned int u4;
    unsigned short i2;
    float f4;

    if (op == OP_NEXT) {
        while (1) {
            if (!buf) {
                if (LIST_EMPTY(&gRecvPackQ)) {
                    if (pk > 0 || mode > 0) {
                        uset = TICK() - tick;
                        int m = uset / gCpuTick;
                        if (m > 10) INFO("[CPU_PACKET], pk=%d, mode=%d, use=%d", pk, mode, m);
                        pk = 0;
                        mode = 0;
                    }
                    return 0;
                }
                pos = gRecvPackQ.next;
                LIST_DEL(pos);
                buf = LIST_ENTRY(pos, struct Buf, link);
                cur = buf->h;
                end = cur;
            }

            cur = end;
            if (cur + 4 > buf->t) {
                del_buf(buf); buf = NULL; continue;
            }

            len = ntohl(*(unsigned int*)cur);
            cur += 4;
            end = cur + len;
            //dump(cur, end-cur, "packet");
            if (end > buf->t) {
                WARN("[WARN] %s,%d\n", __FILE__, __LINE__);
                del_buf(buf); buf = NULL; start = cur = end = NULL; continue;
            }

            if (pk > 0 || mode > 0) {
                uset = TICK() - tick;
                int m = uset / gCpuTick;
                if (m > 10) INFO("[CPU_PACKET], pk=%d, mode=%d, use=%d", pk, mode, m);
            }

            tick = TICK();
            mode = buf->mode;
            pk = 0;
            if (!buf->mode) {
                if (cur + 8 > end) {
                    WARN("WARN %s,%d\n", __FILE__, __LINE__);
                    del_buf(buf); buf = NULL; start = cur = end = NULL; continue;
                }
                pid = ntohl(*(unsigned int*)(cur));
                pk = ntohl(*(unsigned int*)(cur+4));
                lua_pushinteger(L,buf->sid);
                gPkNum++;
                return 1;
            } else {
                lua_pushinteger(L,buf->sid);
                lua_pushinteger(L,buf->mode);
                gDbNum++;
                return 2;
            }
        }
    }

    if (!buf || !cur || cur>=end) {
        WARN("WARN %s,%d, buf=%d, cur=%d, end=%d\n", __FILE__, __LINE__, buf, cur, end);
        dump(buf->h, buf->t - buf->h, "all buf");
        return 0;
    }

    if (op == OP_PACK) {
        CHECK_REMAIN(4, cur, end);
        len = ntohl(*(int*)cur);
        cur += 4;

        CHECK_REMAIN(len, cur, end);
        lua_pushlstring(L, cur, len);
        cur += len;
        return 1;

    } else if (op == OP_PKG) {
        lua_pushlstring(L, cur, end-cur);
        cur = end;
        start = end;
        return 1;

    } else if (op == OP_I4) {
        CHECK_REMAIN(4, cur, end);
        i4 = ntohl(*(int*)cur);
        lua_pushinteger(L, i4);
        cur += 4;
        return 1;

    } else if (op == OP_U4) {
        CHECK_REMAIN(4, cur, end);
        u4 = ntohl(*(unsigned int*)cur);
        lua_pushnumber(L, u4);
        cur += 4;
        return 1;

    } else if (op == OP_F4) {
        CHECK_REMAIN(4, cur, end);
        i4 = ntohl(*(unsigned int*)cur);
        memcpy(&f4, &i4, sizeof(i4));
        lua_pushnumber(L, f4);
        cur += 4;
        return 1;

    } else if (op == OP_S) {
        CHECK_REMAIN(2, cur, end);
        i2 = ntohs(*(unsigned short*)cur);
        cur += 2;

        CHECK_REMAIN(i2, cur, end);
        lua_pushlstring(L, cur, i2);
        cur += i2;
        return 1;
    }
    return 0;
}

#define CHECK_BUF(fbuf, fstart, fcur, fend, fsize) \
    do { \
        if (fend - fcur < fsize) { \
            struct Buf *temp = fbuf; \
            fbuf = new_buf( (fcur-fstart+fsize) * 2); \
            memcpy( fbuf->h, fstart, fcur - fstart ); \
            fcur = fbuf->h + (fcur - fstart); \
            fstart = fbuf->h; \
            fend = fbuf->e;  \
            fbuf->sid = temp->sid; \
            fbuf->mode = temp->mode; \
            fbuf->pknum = temp->pknum; \
            del_buf(temp); \
        } \
    } while(0) 



int pushBuf(lua_State *L, int op) 
{
    static struct Buf *buf = NULL;
    static char *start = NULL;
    static char *cur = NULL;
    static char *end = NULL;
    int len;
    int i4, gid, cid, pktype;
    unsigned int u4;
    unsigned short i2;
    float f4;
    char *str;

    if (!buf) {
        buf = new_buf(0);
        start = cur = buf->h;
        end = buf->e;
    }

    if (op == OP_HEAD) {
        if (start != cur) cur = start;

        gid = luaL_checkinteger(L, 1);
        cid = luaL_checkinteger(L, 2);
        pktype = luaL_checkinteger(L, 3);
        buf->sid = gid;

        CHECK_BUF(buf, start, cur, end, 12);
        cur = start + 4;

        *(int *)cur = htonl(cid);
        cur += 4;

        *(int *)cur = htonl(pktype);
        cur += 4;

    } else if (op == OP_HEAD2S) {
        if (start != cur) cur = start;

        gid = luaL_checkinteger(L, 1);
        pktype = luaL_checkinteger(L, 2);
        buf->sid = gid;

        CHECK_BUF(buf, start, cur, end, 8);
        cur = start + 4;

        *(int *)cur = htonl(pktype);
        cur += 4;

    } else if (op == OP_PACK) {
        size_t sz = 0;
        const char *buffer = luaL_checklstring(L, 1, &sz);

        CHECK_BUF(buf, start, cur, end, 4+sz);
        *(int*)cur = htonl(sz);
        cur += 4;
        memcpy(cur, buffer, sz);
        cur += sz;

    } else if (op == OP_PKG) {
        int gid = luaL_checkinteger(L,1);
        size_t sz = 0;
        const char *buffer = luaL_checklstring(L, 2, &sz);

        struct Buf *tbuf = new_buf(sz);
        memcpy(tbuf->t, buffer, sz);
        tbuf->t += sz;
        tbuf->sid = gid;
        //send_buf(tbuf, tbuf->sid);
        LIST_ADD_TAIL(&tbuf->link, &gRpcBufQ);

    } else if (op == OP_OVER) {
        if (buf) {
            len = cur - start - 4;
            *(unsigned int*)start = htonl(len);
            start = cur;
            if (start > buf->h) {
                buf->t = start;
                //send_buf(buf, buf->sid);
                LIST_ADD_TAIL(&buf->link, &gRpcBufQ);
                buf = NULL;
            } else {
                LOG("why, op_over");
            }
        }

    } else if (op == OP_AROUND) {
        if (buf) {
            len = cur - start - 4;
            *(unsigned int*)start = htonl(len);
            start = cur;
            if (start > buf->h) {
                buf->t = start;
                roi_broadcast(buf->sid, buf);
                buf = NULL;
            } else {
                LOG("why, op_over");
            }
        }

    } else if (op == OP_I4) {
        CHECK_BUF(buf, start, cur, end, 4);
        i4 = luaL_checkinteger(L, 1);
        *(int *)cur = htonl(i4);
        cur += 4;

    } else if (op == OP_U4) {
        CHECK_BUF(buf, start, cur, end, 4);
        u4 = luaL_checkinteger(L, 1);
        *(unsigned int *)cur = htonl(u4);
        cur += 4;
    
    } else if (op == OP_F4) {
        CHECK_BUF(buf, start, cur, end, 4);
        f4 = luaL_checknumber(L, 1);
        memcpy(&i4, &f4, sizeof(int));
        *(int *)cur = htonl(i4);
        cur += 4;
    
    } else if (op == OP_S) {
        size_t lstr;
        str = (char*)luaL_checklstring(L, 1, &lstr);
        if (lstr >= 0x010000) lstr = 0x0FFFF;
        CHECK_BUF(buf, start, cur, end, lstr + 2);
        i2 = lstr;
        *(short*)cur = htons(i2);
        cur += 2;
        memcpy(cur, str, lstr);
        cur += lstr;
    }
    return 0;
}


int pushHead(lua_State *L) { pushBuf(L, OP_HEAD); return 0;}
int pushHead2s(lua_State *L) { pushBuf(L, OP_HEAD2S); return 0;}
int pushOver(lua_State *L) { pushBuf(L, OP_OVER); return 0;}
int pushAround(lua_State *L) { pushBuf(L, OP_AROUND); return 0;}
int pushInt(lua_State *L) { pushBuf(L, OP_I4); return 0;}
int pushUint(lua_State *L) { pushBuf(L, OP_U4); return 0;}
int pushFloat(lua_State *L) { pushBuf(L, OP_F4); return 0;}
int pushString(lua_State *L) { pushBuf(L, OP_S); return 0;}
int pushPack(lua_State *L) { pushBuf(L, OP_PACK); return 0;}
int pushPkg(lua_State *L) { pushBuf(L, OP_PKG); return 0;}

int pullInt(lua_State *L) { return pullBuf(L, OP_I4); }
int pullUint(lua_State *L) { return pullBuf(L, OP_U4); }
int pullFloat(lua_State *L) { return pullBuf(L, OP_F4);}
int pullString(lua_State *L) { return pullBuf(L, OP_S);}
int pullNext(lua_State *L) { return pullBuf(L, OP_NEXT);}
int pullPack(lua_State *L) { return pullBuf(L, OP_PACK);}
int pullPkg(lua_State *L) { return pullBuf(L, OP_PKG);}

int lpullRoiMsg(lua_State *L)
{
    static struct list_head qInner;
    static int init = 0;
    if (!init) {
        INIT_LIST_HEAD(&qInner);
        init = 1;
    }

    struct list_head *pos;
    MsgFromRoi *t;


    if (LIST_EMPTY(&qInner)) QueTryAll(&g_msg_from_roi, &qInner);

    if (!LIST_EMPTY(&qInner)) {
        gRoiNum++;
        pos = qInner.next;
        LIST_DEL(pos);
        t = LIST_ENTRY(pos, MsgFromRoi, link);
        lua_pushinteger(L, t->msgid);
        lua_pushinteger(L, t->d0);
        lua_pushinteger(L, t->d1);
        lua_pushinteger(L, t->d2);
        lua_pushinteger(L, t->d3);
        lua_pushinteger(L, t->d4);
        lua_pushinteger(L, t->d5);
        lua_pushinteger(L, t->d6);
        lua_pushinteger(L, t->d7);
        free(t);
        return 9;
    }
    return 0;
}


int lpullTimer(lua_State *L)
{
    static struct list_head qTimer;
    static int init = 0;
    if (!init) {
        INIT_LIST_HEAD(&qTimer);
        init = 1;
    }

    struct list_head *pos;
    timer_list *tl;
    if (LIST_EMPTY(&gRecvTimerQ)) recv_timerq(&gRecvTimerQ);

    if (!LIST_EMPTY(&gRecvTimerQ)) {
        gTmNum++;
        pos = gRecvTimerQ.next;
        LIST_DEL(pos);
        tl = LIST_ENTRY(pos, timer_list, link);
        lua_pushinteger(L, tl->id);
        lua_pushinteger(L, tl->tag);
        free(tl);
        return 2;
    }
    return 0;
}

int laddTimer(lua_State *L)
{
    long id = luaL_checknumber(L, 1);
    long ex = luaL_checknumber(L, 2);
    int tag = luaL_checknumber(L, 3);
    add_timer(ex, id, tag);
    return 0;
}
    
int lhashStr(lua_State *L)
{
    char *str = (char*)luaL_checkstring(L, 1);

    /* magic numbers from http://www.isthe.com/chongo/tech/comp/fnv/ */
    static const unsigned int InitialFNV = 2166136261U;
    static const unsigned int FNVMultiple = 16777619;

    int len = strlen(str);

    /* Fowler / Noll / Vo (FNV) Hash */
    unsigned int hash = InitialFNV;
    int i;
    for(i = 0; i < len; i++)
    {
        hash = hash ^ (str[i]);       /* xor  the low 8 bits */
        hash = hash * FNVMultiple;  /* multiply by the magic number */
    }
    hash &= 0x7FFFFFFF;
    lua_pushinteger(L, hash);
    return 1;
}

int lconnect(lua_State *L)
{
    const char *ip = luaL_checkstring(L, 1);
    int port = luaL_checkinteger(L, 2);
    int encrypt = luaL_checkinteger(L, 3);
    int mode = luaL_checkinteger(L, 4);
    int sid = connect_to(ip, port, encrypt, mode);
    lua_pushinteger(L, sid);
    return 1;
}

int lshutdown(lua_State *L)
{
    int sid = luaL_checkinteger(L, 1);
    disconnect(sid);
    return 0;
}

int llog(lua_State *L)
{
    const char *s = luaL_checkstring(L, 1);
    LOG(s);
    return 0;
}

int linfo(lua_State *L)
{
    const char *s = luaL_checkstring(L, 1);
    INFO(s);
    return 0;
}

int lwarn(lua_State *L)
{
    const char *s = luaL_checkstring(L, 1);
    WARN(s);
    return 0;
}

int lmap_init(lua_State *L)
{
    map_init();
    return 0;
}

int lroi_init(lua_State *L)
{
    gRoi = 1;
    roi_start();
    return 0;
}

int lroi_set_block(lua_State *L)
{
    const char *fn = luaL_checkstring(L, 1);
    int rt = roi_set_block(fn);
    lua_pushnumber(L, rt);
    return 1;
}

int lroi_view_start(lua_State *L)
{
    roi_view_start();
    return 0;
}

int lroi_add_scan(lua_State *L)
{
    int eid = luaL_checkinteger(L, 1);
    int range = luaL_checkinteger(L, 2);
    roi_add_scan(eid, range);
    return 0;
}

int lroi_rem_scan(lua_State *L)
{
    int eid = luaL_checkinteger(L, 1);
    roi_rem_scan(eid);
    return 0;
}

//int lroi_add_actor(lua_State *L)
//{
//    int eid = luaL_checkinteger(L, 1);
//    int sx = luaL_checkinteger(L, 2);
//    int sy = luaL_checkinteger(L, 3);
//    int dx = luaL_checkinteger(L, 4);
//    int dy = luaL_checkinteger(L, 5);
//    float speed = (float)luaL_checknumber(L, 6);
//    roi_add_actor(eid, sx, sy, dx, dy, gMsec, speed);
//    return 0;
//}

int lroi_add_actor(lua_State *L)
{
    int eid = luaL_checkinteger(L, 1);
    float sx = luaL_checknumber(L, 2);
    float sy = luaL_checknumber(L, 3);
    int dx = luaL_checkinteger(L, 4);
    int dy = luaL_checkinteger(L, 5);
    int tm = luaL_checkinteger(L, 6);
    float speed = (float)luaL_checknumber(L, 7);
    int msec = (tm - tsStart.tv_sec) * 1000;
    roi_add_actor(eid, sx*1000, sy*1000, dx, dy, msec, speed);
    return 0;
}

int lroi_get_actor_pos(lua_State *L)
{
    int eid = luaL_checkinteger(L, 1);
    float x = 0;
    float y = 0;
    if (roi_get_actor_pos(eid, &x, &y)) {
        lua_pushnumber(L, x);
        lua_pushnumber(L, y);
        return 2;
    } else {
        return 0;
    }
}


int lroi_rem_actor(lua_State *L)
{
    int eid = luaL_checkinteger(L, 1);
    roi_rem_actor(eid);
    return 0;
}

int lroi_upd_actor(lua_State *L)
{
    int eid = luaL_checkinteger(L, 1);
    float speed = (float)luaL_checknumber(L, 2);
    roi_upd_actor(eid, speed);
    return 0;
}


//int lgetPosByLv(lua_State *L)
int lget_pos_by_lv(lua_State *L)
{
    unsigned int lv = luaL_checkinteger(L, 1);
    unsigned int w = luaL_checkinteger(L, 2);
    unsigned int h = luaL_checkinteger(L, 3);

    if (lv > 6) return 0;  
    int pos = map_get_pos_by_lv(lv, w, h);
    if (pos < 0) return 0;

    int x = (pos >> 16) & 0x0FFFF;
    int y = pos & 0x0FFFF;
    lua_pushinteger(L, x);
    lua_pushinteger(L, y);
    return 2;
}

int lget_zone_lv(lua_State *L)
{
    unsigned int zx = luaL_checkinteger(L, 1);
    unsigned int zy = luaL_checkinteger(L, 2);
    lua_pushinteger(L, map_get_zone_lv(zx, zy));
    return 1;
}

int lget_culture(lua_State *L)
{
    unsigned int x = luaL_checkinteger(L, 1);
    unsigned int y = luaL_checkinteger(L, 2);
    unsigned int c = roi_get_culture( x, y );
    lua_pushinteger(L, c);
    return 1;
}


int lget_pos_in_zone(lua_State *L)
{
    unsigned int zx = luaL_checkinteger(L, 1);
    unsigned int zy = luaL_checkinteger(L, 2);
    unsigned int w = luaL_checkinteger(L, 3);
    unsigned int h = luaL_checkinteger(L, 4);
    int pos = map_get_pos_in_zone(zx, zy, w, h);
    if (pos < 0) return 0;
    int x = (pos >> 16) & 0x0FFFF;
    int y = pos & 0x0FFFF;
    lua_pushinteger(L, x);
    lua_pushinteger(L, y);
    return 2;
}


int lmap_test_pos(lua_State *L)
{
    unsigned int x = luaL_checkinteger(L, 1);
    unsigned int y = luaL_checkinteger(L, 2);
    unsigned int w = luaL_checkinteger(L, 3);
    int b = map_test_pos(x, y, w);
    lua_pushinteger(L, b);
    return 1;
}

int lmap_get_region(lua_State *L)
{
    unsigned int x = luaL_checkinteger(L, 1);
    unsigned int y = luaL_checkinteger(L, 2);
    unsigned int region = roi_get_region( x, y );
    lua_pushinteger(L, region);
    return 1;
}


int lgetMap(lua_State *L)
{
    lua_pushinteger(L, gMap);
    return 1;
}

static inline uint32_t
to_little_endian(uint32_t v) {
	union {
		uint32_t v;
		uint8_t b[4];
	} u;
	u.v = v;
	return u.b[0] | u.b[1] << 8 | u.b[2] << 16 | u.b[3] << 24;
}


typedef struct {
//		int32_t length; // total message size, including this
		int32_t request_id; // identifier for this message
		int32_t response_id; // requestID from the original request
							// (used in reponses from db)
		int32_t opcode; // request type 
		int32_t flags;
		int32_t cursor_id[2];
		int32_t starting;
		int32_t number;
} Reply;

#define REPLY_QUERYFAILURE 2
int lgetReplyID(lua_State *L)
{
    size_t data_len = 0;
	const char * data = luaL_checklstring(L,1,&data_len);
	//struct {
    //    //int32_t length; // total message size, including this
	//	int32_t request_id; // identifier for this message
	//	int32_t response_id; // requestID from the original request
	//						// (used in reponses from db)
	//	int32_t opcode; // request type 
	//	int32_t flags;
	//	int32_t cursor_id[2];
	//	int32_t starting;
	//	int32_t number;
	//} const *reply = (const void *)data;

    Reply *reply = (Reply*)data;

	if (data_len < sizeof(*reply)) {
		lua_pushboolean(L, 0);
		return 1;
	}

	int id = to_little_endian(reply->response_id);
	int flags = to_little_endian(reply->flags);
	if (flags & REPLY_QUERYFAILURE) {
		lua_pushboolean(L,0);
		lua_pushinteger(L, id);
		return 2;
	}

    lua_pushinteger(L, 1);
    lua_pushinteger(L, id);
    return 2;
}

//#ifdef _SRV_
//int lackdbg(lua_State *L)
//{
//    size_t sz = 0;
//    const char *str = luaL_checklstring(L, 1, &sz);
//    struct Buf *buf = new_buf(sz);
//    memcpy(buf->t, str, sz);
//    ack_dbg(buf);
//    return 0;
//}
//#endif
//
int lbegJob(lua_State *L)
{
    gBegJob = 1;
    return 0;
}

int lgetScript(lua_State *L)
{
    lua_pushstring(L, gScript);
    return 1;
}

int lget_map_access(lua_State *L)
{
    int zx = luaL_checkinteger(L, 1);
    int zy = luaL_checkinteger(L, 2);
    lua_pushinteger(L, roi_access_time(zx, zy));
    return 1;
}

int ladd_ety(lua_State *L)
{
    int eid = luaL_checkinteger(L, 1);
    int x = luaL_checkinteger(L, 2);
    int y = luaL_checkinteger(L, 3);
    int r = luaL_checkinteger(L, 4);
    int lv = luaL_checkinteger(L, 5);
    if (r > 0) {
        roi_set_bit(x, y, r);
    } else {
        printf("!!! add_ety, eid=%d, x=%d, y=%d, r=%d\n", eid, x, y, r);
    }
    //printf("add_ety, eid=%d, x=%d, y=%d, r=%d\n", eid, x, y, r);

    size_t sz = 0;
    const char *buffer = luaL_checklstring(L, 6, &sz);
    roi_add_ety(eid, x, y, r, lv, sz, (void*)buffer);
    return 0;
}


int ladd_troop(lua_State *L)
{
    int eid = luaL_checkinteger(L, 1);
    int sx = luaL_checknumber(L, 2);
    int sy = luaL_checknumber(L, 3);
    int dx = luaL_checknumber(L, 4);
    int dy = luaL_checknumber(L, 5);
    size_t sz = 0;
    const char *buffer = luaL_checklstring(L, 6, &sz);
    roi_add_troop(eid, sx, sy, dx, dy, sz, (void*)buffer);
    return 0;
}


int ladd_eye(lua_State *L)
{
    int x = luaL_checkinteger(L, 1);
    int y = luaL_checkinteger(L, 2);
    int lv = luaL_checkinteger(L, 3);
    int pid = luaL_checkinteger(L, 4);
    int gid = luaL_checkinteger(L, 5);
    roi_add_eye(x, y, lv, pid, gid);
    return 0;
}

int lrem_ety(lua_State *L)
{
    int eid = luaL_checkinteger(L, 1);
    roi_rem_ety(eid);
    return 0;
}
 
int lrem_eye(lua_State *L)
{
    int pid = luaL_checkinteger(L, 1);
    roi_rem_eye(pid);
    return 0;
}
 
int lmov_eye(lua_State *L)
{
    int eid = luaL_checkinteger(L, 1);
    int x = luaL_checkinteger(L, 2);
    int y = luaL_checkinteger(L, 3);
    roi_mov_eye(eid, x, y);
    return 0;
}

//int lget_eid(lua_State *L)
//{
//    int mode = luaL_checkinteger(L, 1);
//    int eid = get_eid(mode);
//    lua_pushinteger(L, eid);
//    return 1;
//}


int linit_log(lua_State *L)
{
    const char *tips = luaL_checkstring(L, 1);
    static char vtips[32] = {0,};
    snprintf(vtips, sizeof(vtips)-1, "%s", tips);
    init_log(vtips);
    return 0;
}


int lcrossZone(lua_State *L)
{
    int stepy, stepx;
    unsigned int tx, ty;

    unsigned int sx = luaL_checkinteger(L, 1);
    unsigned int sy = luaL_checkinteger(L, 2);
    unsigned int dx = luaL_checkinteger(L, 3);
    unsigned int dy = luaL_checkinteger(L, 4);

    if (sx > dx) {
        tx = sx; ty = sy;
        sx = dx; sy = dy;
        dx = tx; dy = ty;
    }

    unsigned sx1 = sx >> 4;
    unsigned sy1 = sy >> 4;
    unsigned dx1 = dx >> 4;
    unsigned dy1 = dy >> 4;

    printf("(%d,%d)->(%d,%d)\n", sx, sy, dx, dy);
    printf("(%d,%d)->(%d,%d)\n", sx1, sy1, dx1, dy1);

    lua_newtable(L);
    int ltab = lua_gettop(L);
    int count = 1;

    if (sx1 == dx1) {
        if (dy1 > sy1) stepy = 1; else stepy = -1;
        for (; sy1 != dy1; sy1+=stepy) {
            lua_pushinteger(L, sx1),
            lua_rawseti(L, ltab, count++);
            lua_pushinteger(L, sy1),
            lua_rawseti(L, ltab, count++);
            printf("(%d,%d)\n", sx1, sy1);
        } 

        lua_pushinteger(L, dx1);
        lua_rawseti(L, ltab, count++);

        lua_pushinteger(L, dy1);
        lua_rawseti(L, ltab, count++);

        printf("(%d,%d)\n", sx1, sy1);
        return 1;
    }

    float k = (dy - sy) * 1.0f / (dx - sx);
    if (dy1 > sy1) stepy = 1; else stepy = -1;

    float y0 = sy;
    float y1 = y0;

    unsigned int py0 = (unsigned int)y0 >> 4;
    unsigned int py1 = py0;

    for ( ; sx1 <= dx1; sx1++) {
        if (sx1 == dx1) {
            py1 = dy1;
        } else {
            y1 = k * ((sx1 + 1) * 16 - sx) + sy;
            py1 = (unsigned int)y1 >> 4;
        }
        printf("x = %d, y1 = %f, k = %f, (py0, py1) = (%d,%d), \n", sx1, y1, k, py0, py1);
        while (py0 != py1) {
            lua_pushinteger(L, sx1);
            lua_rawseti(L, ltab, count++);
            lua_pushinteger(L, py0);
            lua_rawseti(L, ltab, count++);
            printf("(%d,%d)\n", sx1, py0);
            py0 += stepy;
        }
        lua_pushinteger(L, sx1);
        lua_rawseti(L, ltab, count++);
        lua_pushinteger(L, py0);
        lua_rawseti(L, ltab, count++);
        printf("(%d,%d)\n", sx1, py0);

        py0 = py1;
    }
    return 1;
}


int ltick(lua_State *L)
{
    static unsigned long cur = 0;
    int flag = luaL_checkinteger(L, 1);
    if (flag) {
        unsigned long t = TICK() - cur;
        t /= gCpuTick;
        lua_pushnumber(L, t);
        return 1;
    } else {
        cur = TICK();
    }
    return 0;
}


int lstart_debug(lua_State *L)
{
    int port = luaL_checkinteger(L, 1);
    create_dbg(port);
    return 0;
}

int lget_top(lua_State *L)
{
    int i = lua_gettop(L);
    lua_pushnumber(L, i);
    return 1;
}

int ldump_stack(lua_State *L)
{
    lua_Debug debug;
    uint32_t level = 0;

    while (lua_getstack(L, level, &debug)) {
        lua_getinfo(L, "Sln", &debug);
        LOG("dump_stack, level:%d, line:%d, %s\n", level, debug.currentline, debug.short_src);
        level++;
    }
    return 0;
}



int ltime_set_start(lua_State *L)
{
    int now = luaL_checkinteger(L, 1);
    gTimeControl = 1;
    sleep(2);

    tsStart.tv_sec = now;
    tsStart.tv_usec = 0;
    gTime = now;
    gMsec = 0;

    timer_time_set_start(now);
    roi_time_set_start(now);
    //roi_time_step(now);
}

int ltime_step(lua_State *L)
{
    int now = luaL_checkinteger(L, 1);
    gTime = now;
    gMsec = (now - tsStart.tv_sec) * 1000;
    timer_time_step(now);
    if (gRoi) roi_time_step(now);
    return 0;
}


int ltime_release(lua_State *L)
{
    gTimeControl = 0;
    return 0;
}

int lset_gate(lua_State *L)
{
    gGate = luaL_checkinteger(L, 1);
    return 0;
}


int ltlog_start(lua_State *L)
{
    const char *xml = luaL_checkstring( L, 1 );
    tlog_start( xml );
    return 0;
}

int ltlog(lua_State *L)
{
    char *msg = (char*)luaL_checkstring( L, 1 );
    tlog( msg );
    return 0;
}


int lfmtime( lua_State *L )
{
    char *file = (char*)luaL_checkstring( L, 1 );
    FILE *fp;
    int fd;
    struct stat buf;
    fp = fopen( file, "r" );
    if ( fp ) {
        fd = fileno( fp );
        fstat( fd, &buf );
        lua_pushnumber( L, buf.st_mtime );
        fclose( fp );
        return 1;
    }
    return 0;
}

int lget_time( lua_State *L )
{
    lua_pushinteger(L, gTime);
    return 1;
}


int lrelease_mem( lua_State *L )
{
    size_t sz = 0, sz1 = 0;
    MallocExtension_GetNumericProperty("generic.current_allocated_bytes", &sz);
    MallocExtension_ReleaseFreeMemory();
    MallocExtension_GetNumericProperty("generic.current_allocated_bytes", &sz1);
    printf( "release_mem, %d, %d, %d\n", sz, sz1, sz-sz1 );
    return 0;
}

lua_State *lua_start(char *file)
{

	signal(SIGINT, sh);
    signal(SIGPIPE, SIG_IGN);

    INIT_LIST_HEAD(&gRecvPackQ);
    INIT_LIST_HEAD(&gRecvTimerQ);

    QueInit(&g_msg_from_roi);

    lua_State *L = luaL_newstate();
    luaL_openlibs(L);

    luaopen_cmsgpack(L);
    lua_setglobal(L, "cmsgpack");

    luaopen_bson(L);
    lua_setglobal(L, "bson");

    luaopen_mongo_driver(L);
    lua_setglobal(L, "mongo_driver");

    luaopen_skiplist_c(L);
    lua_setglobal(L, "skiplist");

    lua_atpanic( L, error_hook );
    lua_pushcfunction(L, error_hook);
    stackErrorHook = lua_gettop(L);

    int stepPause = lua_gc(L, LUA_GCSETPAUSE, 1000);
    int stepMul = lua_gc(L, LUA_GCSETSTEPMUL, 10);

    lua_register(L, "llog", llog);
    lua_register(L, "linfo", linfo);
    lua_register(L, "lwarn", lwarn);
    lua_register(L, "c_init_log", linit_log);

    lua_register(L, "getScript", lgetScript);

    lua_register(L, "pullInt",  pullInt);
    lua_register(L, "pullUint", pullUint);
    lua_register(L, "pullFloat",pullFloat);
    lua_register(L, "pullString",pullString);
    lua_register(L, "pullNext", pullNext);
    lua_register(L, "pullPack",  pullPack);
    lua_register(L, "pullPkg",  pullPkg);

    lua_register(L, "pushHead", pushHead);
    lua_register(L, "pushHead2s", pushHead2s);
    lua_register(L, "pushOver", pushOver);
    lua_register(L, "pushAround", pushAround);
    lua_register(L, "pushInt",  pushInt);
    lua_register(L, "pushUint", pushUint);
    lua_register(L, "pushFloat",pushFloat);
    lua_register(L, "pushString",pushString);
    lua_register(L, "pushPack",pushPack);
    lua_register(L, "pushPkg",pushPkg);

    lua_register(L, "hashStr", lhashStr);
    lua_register(L, "connect", lconnect);
    lua_register(L, "shutdown", lshutdown);

    lua_register(L, "pullTimer", lpullTimer);
    lua_register(L, "addTimer", laddTimer);

    lua_register(L, "c_set_gate", lset_gate);
    lua_register(L, "c_pull_msg_roi", lpullRoiMsg);

    lua_register(L, "c_get_engine_mem", lget_engine_mem);

    lua_register(L, "getMap", lgetMap);
//#ifdef _SRV_
//    lua_register(L, "ackdbg", lackdbg);
//#endif
    lua_register(L, "begJob", lbegJob);

    lua_register(L, "c_roi_init", lroi_init);
    lua_register(L, "c_map_init", lmap_init);
    lua_register(L, "c_roi_set_block", lroi_set_block);

    lua_register(L, "c_roi_view_start", lroi_view_start);
    lua_register(L, "c_get_pos_by_lv", lget_pos_by_lv);
    lua_register(L, "c_get_pos_in_zone", lget_pos_in_zone);
    lua_register(L, "c_map_test_pos", lmap_test_pos);
    lua_register(L, "c_map_get_region", lmap_get_region);
    lua_register(L, "c_get_zone_lv", lget_zone_lv);
    lua_register(L, "c_get_culture", lget_culture);

    lua_register(L, "c_add_scan", lroi_add_scan);
    lua_register(L, "c_rem_scan", lroi_rem_scan);
    lua_register(L, "c_add_actor", lroi_add_actor);

    lua_register(L, "c_rem_actor", lroi_rem_actor);
    lua_register(L, "c_upd_actor", lroi_upd_actor);
    lua_register(L, "c_get_actor_pos", lroi_get_actor_pos);

    lua_register(L, "getReplyID", lgetReplyID);
    lua_register(L, "crossZone", lcrossZone);

    lua_register(L, "c_add_ety", ladd_ety);
    lua_register(L, "c_rem_ety", lrem_ety);

    lua_register(L, "c_add_troop", ladd_troop);

    lua_register(L, "c_add_eye", ladd_eye);
    lua_register(L, "c_rem_eye", lrem_eye);
    lua_register(L, "c_mov_eye", lmov_eye);

    lua_register(L, "c_get_map_access", lget_map_access);

    //lua_register(L, "c_get_eid", lget_eid);

    lua_register(L, "c_tick", ltick);
    lua_register(L, "c_start_debug", lstart_debug);
    lua_register(L, "c_get_top", lget_top);
    lua_register(L, "c_dump_stack", ldump_stack);

    lua_register(L, "c_time_set_start", ltime_set_start);
    lua_register(L, "c_time_step", ltime_step);
    lua_register(L, "c_time_release", ltime_release);

    lua_register(L, "c_tlog_start", ltlog_start);
    lua_register(L, "c_tlog", ltlog);

    lua_register(L, "c_fmtime", lfmtime); // file modify time
    lua_register(L, "c_get_time", lget_time);
    lua_register(L, "c_release_mem", lrelease_mem);

    if (luaL_loadfile(L, file) || lua_pcall(L, 0, LUA_MULTRET, stackErrorHook)) {
        WARN("err = %s\n", lua_tostring(L, -1));
        exit(-1);
    }

    initRef(L);
    luaopen_bson(L);
    luaopen_mongo_driver(L);

    int top = lua_gettop(L);
    lua_getglobal( L, "init" );
    lua_pushinteger(L, gTime);
    lua_pushinteger(L, gMsec);
    lua_call(L, 2, 1);

    int code = (int)lua_tonumber(L, -1);
    if (code != 1) {
        WARN("INIT ERROR");
        exit(-1);
    }
    lua_settop(L, top);
    gScript = file;

    return L;
}

void lua_post_msg_roi(int msg, int d0, int d1, int d2, int d3, int d4, int d5, int d6, int d7)
{
    MsgFromRoi *m = (MsgFromRoi*)calloc(sizeof(MsgFromRoi), 1);
    INIT_LIST_HEAD(&m->link);
    m->msgid = msg;
    m->d0 = d0;
    m->d1 = d1;
    m->d2 = d2;
    m->d3 = d3;
    m->d4 = d4;
    m->d5 = d5;
    m->d6 = d6;
    m->d7 = d7;
    QuePut(&g_msg_from_roi, &m->link);
}

