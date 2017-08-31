#include <unistd.h>
#include <stdlib.h>
#include <pthread.h>
#include "net.h"
#include "msg.h"
#include "handle.h"
#include "timer.h"
#include "world.h"
#include "log.h"


int gOn = 1;

int gMsec;
int gTime;
int gTimeControl = 0;
struct timeval tsStart;

int gMap = 0;

void initWorld();
int is_lib_time_out();
int gCpuTick = 0;

unsigned long TICK()
{
    unsigned int lo,hi;
    __asm__ __volatile__
        (
         "rdtsc":"=a"(lo),"=d"(hi)
        );
    return ((unsigned long)hi) << 32 | lo;
}


void setTime()
{
    if (!gTimeControl) {
        struct timeval tsNow;
        gettimeofday(&tsNow, NULL);

        int cursec = tsNow.tv_sec;
        int curmsec = (cursec - tsStart.tv_sec) * 1000 + tsNow.tv_usec * 0.001;
        if (cursec >= gTime && curmsec >= gMsec) {
            gTime = cursec;
            gMsec = curmsec;
        }
    }
}

void *thread_time( void *arg )
{
    while ( gOn ) {
        setTime();
        usleep(10 * 1000);
    }
}


int main(int argc, char **argv)
{
    if (is_lib_time_out()) return 0;
    if (argc < 2) return printf("usage: ./game mapid tips main_scrip\n");

    gMap = atoi(argv[1]);
    char tip[16];
    if (argc >= 3) {
        snprintf(tip, sizeof(tip), argv[2]);
    } else {
        snprintf(tip, sizeof(tip), "map_%d", gMap);
    }
    init_log(tip);

    char init_script[256] = {0,};
    if (argc >= 4) {
        snprintf(init_script, sizeof(init_script), argv[3]);
    } else {
        snprintf(init_script, sizeof(init_script), "frame/frame.lua");
    }

    LOG("start game");
    unsigned long t = TICK();
    sleep(2);
    t = TICK() - t;
    gCpuTick = t / 2000;
    printf("gCpuTick=%d\n", gCpuTick);

    gettimeofday(&tsStart, NULL);
    tsStart.tv_usec = 0;
    gTime = tsStart.tv_sec;
    gMsec = 0;

    init_net();
    start_tick();
    start_net();
    start_timer();

    pthread_t tid; 
    pthread_attr_t attr;
    pthread_attr_init(&attr); 
    pthread_create(&tid,&attr,thread_time, NULL);
    pthread_attr_destroy(&attr);

    chdir("../script/");

    lua_State *L = lua_start(init_script);

    int deadline = gMsec;
    int nsleep;

    //int frame_tick = 50;
    int frame_tick = 20;
    while (gOn) {
        if (gTimeControl) {
            lua_loop(L, gMsec+1);
        } else {
            //setTime();
            deadline = gMsec + frame_tick;
            lua_loop(L, deadline);
            nsleep = deadline - gMsec;
            if (nsleep > 0) {
                if (nsleep > frame_tick) nsleep = frame_tick;
                //usleep(nsleep * 1000);
                usleep(0);
            }
        }
    }

    return 0;
}

