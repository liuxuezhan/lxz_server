#include <unistd.h>
#include "net.h"
#include "msg.h"
#include "handle.h"
#include "log.h"
#include "timer.h"

int gOn = 1;

extern int gMsec;
extern int gTime;

int gMap = 0;

int main(int argc, char **argv)
{
    init_net();
    start_tick();
    start_net();
    start_timer();
    //lua_State *L = lua_start("client.lua");
    lua_State *L = lua_start("user.lua");

    int deadline = gMsec;
    int nsleep;
    while (gOn) {
        deadline = gMsec + 10;
        lua_loop(L, deadline);
        if (deadline > gMsec) {
            nsleep = deadline - gMsec;
            if (nsleep > 10) nsleep = 10;
            usleep(nsleep * 1000);
        }
    }
    return 0;
}

