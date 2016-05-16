
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

//----------------------------------????????????--------------------------------------

#define BLACK	"\033[30m"
#define RED	"\033[31m"
#define GREEN	"\033[32m"
#define YELLOW	"\033[33m"
#define BLUE	"\033[34m"
#define PURPLE	"\033[35m"
#define CYAN	"\033[36m"
#define WHITE	"\033[37m"
#define BOLD		"\033[1m"
#define COLOR_END	"\033[0m"

static int
color_print(lua_State *L) {

	int c = luaL_checknumber(L, 1);
	size_t sz = 0;
	const char * msg = luaL_checklstring(L, 2, &sz);

	if(0==c)printf("%s%s%s", WHITE,msg,COLOR_END);
	if(1==c)printf("%s%s%s", RED,msg,COLOR_END);
	if(2==c)printf("%s%s%s", YELLOW,msg,COLOR_END);
	if(3==c)printf("%s%s%s", BLUE,msg,COLOR_END);
	if(4==c)printf("%s%s%s", GREEN,msg,COLOR_END);
	if(5==c)printf("%s%s%s", PURPLE,msg,COLOR_END);
	if(6==c)printf("%s%s%s", CYAN,msg,COLOR_END);
	return 0;

}


int
luaopen_cprint(lua_State *L) {
	 luaL_Reg l[] ={
				{"cprint",  color_print},
				{ NULL, NULL },
	 };

    luaL_newlib(L,l);

     return 1;
}

