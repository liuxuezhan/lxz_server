#ifndef HANDLE_H
#define HANDLE_H

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "mylist.h"

lua_State *lua_start(char *file);
void lua_loop(lua_State *L, int msec);
void lua_post_msg_roi(int msg, int d0, int d1, int d2, int d3, int d4, int d5, int d6, int d7);
#endif
