LUA_LIB=../skynet/3rd/lua
LUALIB= -lpthread  -lm  $(LUA_LIB)/liblua.a -DLUA_USE_READLINE -ldl  -Wl,-E  -lrt

CFLAGS = -ggdb3 -rdynamic -Wall -Wconversion -Wextra -Wstack-protector  -fexceptions -fstack-protector-all -Wstack-protector -D__DEBUG__ 

.PHONY: all linux

all :
	@echo Please do \'make PLATFORM\' where PLATFORM is one of these:
	@echo win linux

linux:  robot

robot : src/main.cpp
	g++  $(CFLAGS)  -I$(LUA_LIB) $^ -o $@  $(LUALIB)
clean:
	rm -f *.so robot 



