LUA_LIB="/usr/local/lib"
LUALIB= -lpthread  -lm  $(LUA_LIB)/liblua.a -DLUA_USE_READLINE -ldl  -Wl,-E  -lrt

CFLAGS = -ggdb3 -rdynamic -Wall -Wconversion -Wextra -Wstack-protector  -fexceptions -fstack-protector-all -Wstack-protector -D__DEBUG__

.PHONY: all linux

all :
	@echo Please do \'make PLATFORM\' where PLATFORM is one of these:
	@echo win linux

linux: robot.so robot

robot.so : robot.c
	gcc --shared -Wall -fPIC -O3 $^ -o $@ -llua -lpthread

robot : main.cpp
	g++  $(CFLAGS)  $^ -o $@  $(LUALIB)
clean:
	rm -f robot.so server



