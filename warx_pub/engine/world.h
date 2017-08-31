#ifndef WORLD_H
#define WORLD_H

#include "mylist.h"
#include "buf.h"

#define ROI_ADD_ETY 1
#define ROI_ADD_EYE 2   //just look view
#define ROI_ADD_TROOP 3

#define ROI_REM_ETY 4
#define ROI_REM_EYE 5
//#define ROI_REM_TROOP 6

#define ROI_MOV_EYE 7
//#define ROI_MOD_EYE_POS 8
//#define ROI_MOD_EYE_VLV 9

//#define ROI_MSG_REFRESH_ETY 10
//#define ROI_MSG_REFRESH_MAP 11

#define ROI_BROADCAST 12

#define ROI_NTY_NO_RES 13
#define ROI_TRIGGERS_ENTER 21
#define ROI_TRIGGERS_LEAVE 22
#define ROI_TRIGGERS_ARRIVE 23
#define ROI_ADD_SCAN 24
#define ROI_REM_SCAN 25
#define ROI_ADD_ACTOR 26
#define ROI_REM_ACTOR 27
#define ROI_UPD_ACTOR 28
#define ROI_TIME_STEP 29

#define ROI_STOP 528 

// add_ety_to_link --> add_ety_to_ply --> do_add_ety_to_ply
// init_ply_ety_view 
// modify_ply_ety_view
//
// add_troop_to_link --> add_troop_to_ply --> do_add_troop_to_ply
// init_ply_troop_view
// modify_ply_troop_view




typedef struct {
    struct list_head link;
    int cmd;
    int d0, d1, d2, d3, d4, d5, d6, d7;
    int len;
    void *body;
} Msg;

typedef struct {
    struct list_head link; // link in g_linkmap
    struct list_head hash; // link in g_etys
    int eid, x, y, r; // pos, radius
    int lv; // for ety, view level, res is on level 0, ply is on level 1; for troop, is the level on troop_map

    int len;
    void *data;

    int sx,sy,dx,dy; // for troop use

    int range; // for scan object
    //void *sprite;
} Ety;

// just for look at
typedef struct {
    struct list_head link; // view link
    struct list_head hash; // view link
    int pid, gid;
    int x, y; // view x, view y
    int lv;
    int tick;
    struct Buf *snapshot;
    int magic;
} Eye;

void roi_start();
void roi_view_start();
int roi_set_block(const char* fname);

void send_msg_to_roi(int cmd, int d0, void *body);
int get_eid(int mode);

void roi_add_ety(int eid, int x, int y, int r,  int lv, int sz, void *buffer);
void roi_add_troop(int eid, int sx, int sy, int dx, int dy, int sz, void *buffer);
void roi_add_eye(int x, int y, int lv, int pid, int gid) ;

void roi_rem_ety(int eid);
void roi_rem_eye(int eid);
void roi_mov_eye(int eid, int x, int y);

int roi_access_time(int zx, int zy);
void roi_broadcast(int eid, struct Buf *buf);


void roi_add_scan(int eid, int range);
void roi_rem_scan(int eid);
void roi_add_actor(int eid, int sx, int sy, int dx, int dy, int tick, float speed);
void roi_rem_actor(int eid);
void roi_upd_actor(int eid, float speed);
void roi_time_step(int curSec);
void roi_time_set_start(int curSec);
void roi_set_bit(unsigned int x, unsigned int y, unsigned int r);
unsigned int roi_get_region(unsigned int x, unsigned int y);
unsigned int roi_get_culture( unsigned int x, unsigned int y );

int roi_get_actor_pos(int eid, float *x, float *y);

void map_init();
int map_get_pos_by_lv(unsigned int lv, unsigned int w, unsigned int h);
int map_get_pos_in_zone(unsigned int zx, unsigned int zy, unsigned int w, unsigned int h);
int map_get_zone_lv(unsigned int x, unsigned int y);
int map_test_pos(unsigned int x, unsigned int y, unsigned int w);

#endif
