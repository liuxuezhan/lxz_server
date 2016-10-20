LUALIB=-I../../skynet/3rd/lua/ -L../../skynet.3rd/lua/ -llua 

#LUA_LIB=../../skynet/3rd/lua
#LUALIB= -lm  $(LUA_LIB)/liblua.a -DLUA_USE_READLINE -ldl  -Wl,-E  -lrt

SOCKETLIB=-lws2_32

.PHONY: all win linux

all : 
	@echo Please do \'make PLATFORM\' where PLATFORM is one of these:
	@echo win linux

win: mongo.dll bson.dll

linux: mongo.so bson.so

mongo.dll : lua-mongo.c lua-socket.c
	gcc --shared -Wall -g $^ -o$@ $(LUALIB) $(SOCKETLIB)

mongo.so : lua-mongo.c lua-socket.c
	gcc --shared -Wall -fPIC -g $^ -o$@ 

bson.dll : bson.c
	gcc --shared -Wall -O2 $^ -o$@ $(LUALIB) $(SOCKETLIB)

bson.so : bson.c
	gcc --shared -Wall -fPIC -O3 $^ -o$@ $(LUALIB)

clean:
	rm -f mongo.dll mongo.so bson.so bson.dll
