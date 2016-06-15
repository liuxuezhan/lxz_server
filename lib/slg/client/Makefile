LUA_LIB="/usr/local/lib"
LUALIB= -lpthread  -lm  $(LUA_LIB)/liblua.a -DLUA_USE_READLINE -ldl  -Wl,-E  -lrt

CFLAGS = -ggdb3 -rdynamic -Wall -Wconversion -Wextra -Wstack-protector  -fexceptions -fstack-protector-all -Wstack-protector -D__DEBUG__

.PHONY: all linux

all :
	@echo Please do \'make PLATFORM\' where PLATFORM is one of these:
	@echo win linux

linux: socket.so pack.so lpack.so robot

socket.so : socket.c
	gcc --shared -Wall -fPIC -O3 $^ -o $@ -llua -lpthread

pack.so : pack.c
	gcc --shared -Wall -fPIC -O3 $^ -o $@ -llua 

lpack.so : lpack.c
	gcc --shared -Wall -fPIC -O3 $^ -o $@ -llua 

robot : main.cpp
	g++  $(CFLAGS)  $^ -o $@  $(LUALIB)
clean:
	rm -f *.so robot


