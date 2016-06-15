#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include <string.h>
#include <stdint.h>
#include <pthread.h>
#include <stdlib.h>

#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>


void dump(void* src, int len, const char *tip )
{
    int lc = 16;
    int pos = 0;
    int line = 0;
    int tmplen;
    int i;
    unsigned int X;
    char node[4];

    char val[ 256 ] = { 0, };
    char part3[ 16 + 1 ] = { 0, };
    for( ; len > 0; len -= lc ) {
        memset( val, 0, sizeof(val) );
        memset( part3, 0, sizeof(part3) );

        sprintf( val, "%08X : ", line );
        tmplen = len;
        if( tmplen > lc ) tmplen = lc;
        for( i = 0; i < tmplen; ++i ) {
            X = *(unsigned char*)((unsigned char*)src+pos);
            pos++;
            //*(unsigned int*)node = 0;
            sprintf( node, "%02X ", X );
            strcat( val, node );

            memset( node, 0, sizeof(node) );
            if( X >= '!' && X <= '~' ) {
                node[ 0 ] = X;
            } else {
                node[ 0 ] = '.';
            }
            strcat( part3, node );
        }

        for( ; i < lc; ++i ) {
            strcat( val, "   " );
        }

        strcat( val, " ; " );
        strcat( val, part3 );
        printf("%s | %s\n", tip, val);
        line++;

        //return; // extra, kill dump
    }
}


//----------------------------------数据处理--------------------------------------
enum OP {OP_NEXT=1, OP_HEAD, OP_OVER, OP_AROUND, OP_FLUSH, OP_TEST, OP_HEAD2S, OP_PKG, OP_TBL, OP_PACK, OP_I4, OP_F4, OP_S, OP_U4};

int pullBuf(lua_State *L, int op)
{
    static char *cur = NULL;
    static char *end = NULL;

    int len;
    int i4;
    unsigned int u4;
    unsigned short i2;
    float f4;

    if (op == OP_NEXT) {
        size_t l;
        cur = (char*)luaL_checklstring(L, 1, &l);
        if (cur) {
            end = cur + l;
            if (cur <= end-4) {
                i4 = ntohl(*(int*)cur);
                lua_pushinteger(L, i4);
                cur += 4;
                return 1;
            }
        }
        return 0;

    } else if (op == OP_PACK) {
        len = ntohl(*(int*)cur);
        cur += 4;
        if (cur+len <= end) {
            lua_pushlstring(L, cur, len);
            cur += len;
            return 1;
        }else{
            cur = end;
            lua_pushstring(L, "");
            return 1;
        }

    } else if (op == OP_I4) {
        if (cur && cur <= end-4) {
            i4 = ntohl(*(int*)cur);
            lua_pushinteger(L, i4);
            cur += 4;
            return 1;
        }  else {
            cur = end;
            lua_pushinteger(L, 0);
            printf("%s, no i4", __func__);
            return 1;
        }

    } else if (op == OP_U4) {
        if (cur && cur <= end-4) {
            u4 = ntohl(*(unsigned int*)cur);
            lua_pushnumber(L, u4);
            cur += 4;
            return 1;
        }  else {
            cur = end;
            lua_pushnumber(L, 0);
            printf("%s, no u4", __func__);
            return 1;
        }

    } else if (op == OP_F4) {
        if (cur && cur <= end - 4) {
            i4 = ntohl(*(unsigned int*)cur);
            memcpy(&f4, &i4, sizeof(i4));
            lua_pushnumber(L, f4);
            cur += 4;
            return 1;
        } else {
            cur = end;
            lua_pushnumber(L, 0);
            printf("%s, no f4", __func__);
            return 1;
        }

    } else if (op == OP_S) {
        if (cur && cur <= end - 2) {
            i2 = ntohs(*(unsigned short*)cur);
            cur += 2;
            if (cur + i2 <= end) {
                lua_pushlstring(L, cur, i2);
                cur += i2;
                return 1;
            } else {
                cur = end;
                lua_pushstring(L, "");
                return 1;
            }
        } else {
            cur = end;
            lua_pushstring(L, "");
            printf("%s, no str", __func__);
            return 1;
        }
    }
    return 0;
}

int pushBuf(lua_State *L, int op)
{
    static char *start = NULL;
    static char *cur = NULL;
    static char *end = NULL;
    static char buf[16*1024];
    int len;
    int i4, gid, cid, pktype;
    size_t sz = 0;
    unsigned int u4;
    unsigned short i2;
    float f4;
    char *str;

    if (op == OP_HEAD) {
        cur = buf;
        start = buf;
        end = (char*)buf + sizeof(buf);

        cur += 4;
        pktype = luaL_checkinteger(L, 1);
        *(int *)cur = htonl(pktype);
        cur += 4;

    } else if (op == OP_PACK) {
        const char *buffer = luaL_checklstring(L, 1, &sz);

        if (cur + sz >= end) return 0;

        *(int*)cur = htonl(sz);
        cur += 4;
        memcpy(cur, buffer, sz);
        cur += sz;

    } else if (op == OP_OVER) {
        len = cur - start - 4;
        *(unsigned int*)start = htonl(len);
        lua_pushlstring(L, start, len+4);

        return 1;

    } else if (op == OP_I4) {
        sz = 4;
        if (cur + sz >= end) return 0;
        i4 = luaL_checkinteger(L, 1);
        *(int *)cur = htonl(i4);
        cur += 4;

    } else if (op == OP_U4) {
        sz = 4;
        if (cur + sz >= end) return 0;
        u4 = luaL_checkinteger(L, 1);
        *(unsigned int *)cur = htonl(u4);
        cur += 4;

    } else if (op == OP_F4) {
        sz = 4;
        if (cur + sz >= end) return 0;

        f4 = luaL_checknumber(L, 1);
        memcpy(&i4, &f4, sizeof(int));
        *(int *)cur = htonl(i4);
        cur += 4;

    } else if (op == OP_S) {
        str = (char*)luaL_checklstring(L, 1, &sz);
        if (sz >= 0x010000) sz = 0x0FFFF;
        if (cur + sz + 2 >= end) return 0;

        i2 = sz;
        *(short*)cur = htons(i2);
        cur += 2;
        memcpy(cur, str, sz);
        cur += sz;
    }
    return 0;
}


int pushHead(lua_State *L) { pushBuf(L, OP_HEAD); return 0;}
int pushOver(lua_State *L) { pushBuf(L, OP_OVER); return 1;}
int pushInt(lua_State *L) { pushBuf(L, OP_I4); return 0;}
int pushUint(lua_State *L) { pushBuf(L, OP_U4); return 0;}
int pushFloat(lua_State *L) { pushBuf(L, OP_F4); return 0;}
int pushString(lua_State *L) { pushBuf(L, OP_S); return 0;}
int pushPack(lua_State *L) { pushBuf(L, OP_PACK); return 0;}

int pullNext(lua_State *L) { return pullBuf(L, OP_NEXT);}
int pullInt(lua_State *L) { return pullBuf(L, OP_I4); }
int pullUint(lua_State *L) { return pullBuf(L, OP_U4); }
int pullFloat(lua_State *L) { return pullBuf(L, OP_F4);}
int pullString(lua_State *L) { return pullBuf(L, OP_S);}
int pullPack(lua_State *L) { return pullBuf(L, OP_PACK);}

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

int
luaopen_slg_pack(lua_State *L) {
	 luaL_Reg l[] ={
				{"pullInt",  pullInt},
				{"pullUint", pullUint},
				{"pullFloat",pullFloat},
				{"pullString",pullString},
				{"pullNext", pullNext},
				{"pullPack",  pullPack},
				{"pushHead", pushHead},
				{"pushOver", pushOver},
				{"pushInt",  pushInt},
				{"pushUint", pushUint},
				{"pushFloat",pushFloat},
				{"pushString",pushString},
				{"pushPack",pushPack},
				{"hashStr", lhashStr},
				{ NULL, NULL },
	 };

    luaL_newlib(L,l);

     return 1;
}





