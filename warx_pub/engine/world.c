#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <math.h>
#include <arpa/inet.h>
#include "mylist.h"
#include "que.h"
#include "world.h"
#include "net.h"
#include "log.h"
#include "handle.h"

extern int gOn;
extern int gMsec;
extern int gTime;
extern struct timeval tsStart;
extern int gTimeControl;
extern int gGate;
extern int gMap;

#define BLOCK_WIDTH 16
#define MAP_WIDTH 1280
#define BLOCK_NUM 80

#define BLOCK_BIT 4
#define RANGE_DETAIL 1
#define RANGE_GLOBAL 2

#define PT_ADD_ETYS 1300758837
#define PT_ADD_ETY 1190580068
#define PT_REM_ETY 1011660413
#define PT_SET_STATUS 402113662
#define NET_SNAPSHOT 17

void add_troop_to_eye(Ety *tr, int action);

/* ------------ map bit handle ------------- */
/* ------------ map bit handle ------------- */

unsigned char gLand[ MAP_WIDTH ][ MAP_WIDTH ] = {0,};

int g_state_init = 1;

typedef struct {
    int access;
    int lv;
    struct list_head link_lv0;
    struct list_head link_lv1;
    struct list_head link_view_0;  // detail view
    struct list_head link_view_1;  // global view
} BlockNode;

typedef struct {
    struct list_head *link;
    int max;
} TroopMap;

TroopMap g_troop_map[5]; // 64, 128, 256, 512, 1024
BlockNode g_linkmap[ BLOCK_NUM ][ BLOCK_NUM ];


#define HASH_SIZE 0x010000

// just for find the object conveniently
struct list_head g_eyes[ HASH_SIZE ];
struct list_head g_etys[ HASH_SIZE ]; // include troop
struct list_head g_sprs[ HASH_SIZE ]; // sprites


int g_eye_count = 0;
unsigned int g_obj_mem = 0;
int g_obj_count[100] = {0,};


#define MAX_TRIG 8
typedef struct {
    float x, y;
} Vec;

typedef struct {
    int eid;
    int tick;
} Trig;

typedef struct {
    int eid;
    struct list_head hash;
    Vec cur, dst, delta; // current pos, normalize direction 
    float dist;     // distance
    float speed;    // speed
    int tick;       // last move tick
    int state;
    int ntrig;
    Trig *ptrig;
    Trig room[ MAX_TRIG ];
} Sprite;

#define MAX_SPRITE 4096
Sprite g_sprites[MAX_SPRITE];

Que g_msgq;

static int set_bit(unsigned int x, unsigned int y, unsigned int w, unsigned int h)
{
    if (x+w >= MAP_WIDTH || y+h >= MAP_WIDTH) return -1;

    unsigned int x1, y1;
    unsigned int i, j;

    for (y1=y; y1 < y+h; y1++) {
        for (x1=x; x1 < x+w; x1++) {
            gLand[ y1 ][ x1 ] |= 0x01;
        }
    }
    return 0;
}

static int clear_bit(int x, int y, int w, int h)
{
    if (x+w >= MAP_WIDTH || y+h >= MAP_WIDTH) return -1;

    unsigned int x1, y1;
    unsigned int i, j;

    for (y1=y; y1 < y+h; y1++) {
        for (x1=x; x1 < x+w; x1++) {
            gLand[ y1 ][ x1 ] &= 0x0FE;
        }
    }
    return 0;
}

static int test_bit(unsigned int x, unsigned int y, unsigned int w, unsigned int h)
{
    if (x+w >= MAP_WIDTH || y+h >= MAP_WIDTH) return -1;

    unsigned int x1, y1;
    unsigned int i, j;

    for (y1=y; y1 < y+h; y1++) {
        for (x1=x; x1 < x+w; x1++) {
            if (gLand[ y1 ][ x1 ] & 0x01) {
                return 1;
            } 
        }
    }
    return 0;
}


void check_in(Ety *ety)
{
    int mode = ety->eid >> 16;
    if (mode < 100) g_obj_count[ mode ] += 1;
    g_obj_mem += (ety->len + sizeof(Ety));
}

void check_out(Ety *ety)
{
    int mode = ety->eid >> 16;
    if (mode < 100) g_obj_count[ mode ] -= 1;
    g_obj_mem -= (ety->len + sizeof(Ety));
}


int is_in_black( int x, int y )
{
    int zx = x >> 4;
    int zy = y >> 4;
    if ( zx >= 38 && zx <= 41 && zy >= 38 && zy <= 41 ) return 1;
    return 0;
}

Sprite *get_spr(int eid)
{
    struct list_head *pos;
    Sprite *e = NULL;
    int idx = ( eid >> 12 ) & 0x0FFFF;
    LIST_FOR_EACH(pos, &g_sprs[idx]) {
        e = LIST_ENTRY(pos, Sprite, hash);
        if (e->eid == eid) return e;
    }
    return NULL;
}

Ety *get_ety(int eid)
{
    struct list_head *pos;
    Ety *e = NULL;
    int idx = (eid >> 12) & 0x0FFFF;
    LIST_FOR_EACH(pos, &g_etys[idx]) {
        e = LIST_ENTRY(pos, Ety, hash);
        if (e->eid == eid) return e;
    }
    return NULL;
}


Eye *get_eye(unsigned int pid)
{
    Eye *eye = NULL;
    int idx = pid % HASH_SIZE;
    struct list_head *pos;
    LIST_FOR_EACH(pos, &g_eyes[ idx ]) {
        eye = LIST_ENTRY(pos, Eye, hash);
        if (eye->pid == pid) return eye;
    }
    return NULL;
}

void rem_ety(Ety *ety)
{
    check_out(ety);
    //if ( ety->range ) printf( "rem_ety, eid=%d, range=%d\n", ety->eid, ety->range );
    if (ety->r > 0) clear_bit(ety->x, ety->y, ety->r, ety->r);
    LIST_DEL_INIT(&ety->link);
    LIST_DEL_INIT(&ety->hash);
    if (ety->data) free(ety->data);
    free(ety);
}


void rem_eid(int eid)
{
    Ety *e = get_ety(eid);
    if (e) rem_ety(e);
}


int sprite_get_status(Sprite *spr, void **p)
{
    return 0;
    //static int msg[ 6 ];
    //msg[0] = htonl(sizeof(msg) - sizeof(int));
    //msg[1] = htonl(PT_SET_STATUS);
    //msg[2] = htonl(spr->eid);
    //msg[3] = htonl((int)(spr->cur.x));
    //msg[4] = htonl((int)(spr->cur.y));
    //msg[5] = htonl((int)(spr->speed));
    //*p = &msg;
    //return 24;
}

Sprite *sprite_new()
{
    static int s_idx = 0;
    int i;
    Sprite *p;
    for (i = 0; i < MAX_SPRITE; ++i, ++s_idx) {
        if (s_idx >= MAX_SPRITE) s_idx = 0;
        if (g_sprites[ s_idx ].eid == 0) {
            p = &g_sprites[ s_idx ];
            memset(p, 0, sizeof(Sprite));
            p->ptrig = p->room;
            p->ntrig = MAX_TRIG;
            INIT_LIST_HEAD(&p->hash);
            s_idx++;
            return p;
        }
    }
    return NULL;
}


void sprite_del(Sprite *p)
{
    if (p->ptrig != p->room) free(p->ptrig);
    LIST_DEL_INIT(&p->hash);
    p->eid = 0;
}

Sprite *sprite_create(int eid, int sx, int sy, int dx, int dy, int tick, float speed)
{
    if (eid < 0) return NULL;
    if (speed <= 0) return NULL;

    Sprite *spr = get_spr(eid);
    if (!spr) {
        spr = sprite_new();
        if (!spr) return NULL;
        spr->eid = eid;
        int idx = (eid >> 12) & 0x0FFFF;
        LIST_ADD_TAIL(&spr->hash, &g_sprs[ idx ]);
    }

    float fx = sx * 0.001f;
    float fy = sy * 0.001f;
    spr->cur.x = fx;
    spr->cur.y = fy;
    spr->dst.x = dx;
    spr->dst.y = dy;
    spr->tick = tick;
    spr->speed = speed;

    float x = dx - fx;
    float y = dy - fy;
    float l = x * x + y * y;
    l = pow(l, 0.5);
    spr->dist = l;

    x = (x / l);
    y = (y / l);
    spr->delta.x = x;
    spr->delta.y = y;
    return spr;
}

void sprite_add_trig(Sprite *spr, int eid, int tick)
{
    int i;
    Trig *empty = NULL;
    Trig *pt;
    for (i = 0; i < spr->ntrig; ++i) {
        pt = &spr->ptrig[ i ];
        if (pt->eid == eid) {
            pt->tick = tick;
            return;
        } else if (pt->eid == 0 && empty == NULL) {
            empty = pt;
        }
    }

    lua_post_msg_roi(ROI_TRIGGERS_ENTER, spr->cur.x, spr->cur.y, spr->eid, eid, 0, 0, 0, 0);

    if (empty) {
        empty->eid = eid;
        empty->tick = tick;
        return;
    }

    int n = spr->ntrig;
    Trig *t = (Trig*)calloc(sizeof(Trig) * n * 2, 1);
    memcpy(t, spr->ptrig, sizeof(Trig) * n);

    if (spr->ptrig != spr->room) free(spr->ptrig);
    spr->ptrig = t;
    spr->ntrig = n * 2;
    pt = &t[ n ];
    pt->eid = eid;
    pt->tick = tick;
}

void sprite_tick(Sprite *spr, int now, int recur)
{
    //printf("spr->dist = %f\n", spr->dist);
    if (spr->dist < 0) return;

    int elapse = now - spr->tick;
    if (elapse < 100) return;

    float step = spr->speed * elapse * 0.001f;
    if (step < 0.2f) return;

    if (!recur && step > 1 && elapse > 1) {
        int quick = elapse / (step + 1);
        if (quick < 1) quick = 1;

        int cur = spr->tick+quick;
        for (; cur <= now; cur+=quick) {
            sprite_tick(spr, cur, 1);
        }
        return;
    }
    //printf("sprite_process eid:%d, (%f,%f), speed=%f, tick=%d\n", spr->eid, spr->cur.x, spr->cur.y, spr->speed, spr->tick);

    spr->dist -= step;
    if (spr->dist < 0) {
        Ety *ety = get_ety( spr->eid );
        if ( ety ) {
            add_troop_to_eye(ety, 0);
        }
        rem_eid(spr->eid);
        lua_post_msg_roi(ROI_TRIGGERS_ARRIVE, spr->dst.x, spr->dst.y, spr->eid, 0, 0, 0, 0, 0);
        sprite_del(spr);
        return;
    }

    int oldx = spr->cur.x;
    int oldy = spr->cur.y;

    spr->cur.x += spr->delta.x * step;
    spr->cur.y += spr->delta.y * step;
    spr->tick = now;

    int i;
    int x = spr->cur.x;
    int y = spr->cur.y;

    BlockNode *node = NULL;
    struct list_head *pos;
    Ety *ety;

    int zx = x >> 4;
    int zy = y >> 4;
    int dx, dy;

    for (dx=zx-5; dx<=zx+5; ++dx) {
        for (dy=zy-5; dy<=zy+5; ++dy) {
            if (dx >= 0 && dy >= 0 && dx < BLOCK_NUM && dy < BLOCK_NUM) {
                node = &g_linkmap[ dy ][ dx ];
                LIST_FOR_EACH(pos, &(node->link_lv0)) {
                    ety = LIST_ENTRY(pos, Ety, link);
                    if (ety->range) {
                        //printf("ety range =%d, eid=%d\n", ety->range, ety->eid);
                        if (x >= ety->x - ety->range && x <= ety->x + ety->r + ety->range - 1) {
                            if (y >= ety->y - ety->range && y <= ety->y + ety->r + ety->range - 1) {
                                //printf("enter, eid=%d, troop=%d, range =%d, \n", ety->eid, spr->eid, ety->range);
                                sprite_add_trig(spr, ety->eid, now);
                            }
                        }
                    }
                }
            }
        }
    }

    Trig *pt = NULL;
    for (i = 0; i < spr->ntrig; ++i) {
        pt = &spr->ptrig[ i ];
        if (pt->eid > 0 && pt->tick != now) {
            //printf("leave, eid=%d, tick=%d, now=%d, (%d,%d),(%f,%f)\n", pt->eid, pt->tick, now, (int)spr->cur.x, (int)spr->cur.y, spr->cur.x, spr->cur.y);
            lua_post_msg_roi(ROI_TRIGGERS_LEAVE, spr->cur.x, spr->cur.y, spr->eid, pt->eid, 0, 0, 0, 0);
            //printf("leave, eid=%d, troop=%d\n", pt->eid, spr->eid);
            pt->eid = 0;
        }
    }

    if ( (oldx >> 4) == zx && ( oldy >> 4) == zy ) return;

    if ( is_in_black( oldx, oldy ) ) {
        if ( !is_in_black( x, y ) ) {
            lua_post_msg_roi(ROI_TRIGGERS_LEAVE, spr->cur.x, spr->cur.y, spr->eid, -1, 0, 0, 0, 0);
        }
    } else {
        if ( is_in_black( x, y ) ) {
            lua_post_msg_roi(ROI_TRIGGERS_ENTER, spr->cur.x, spr->cur.y, spr->eid, -1, 0, 0, 0, 0);
        }
    }
}


void sprite_process(int now)
{
    int i;
    for (i = 0; i < MAX_SPRITE; ++i) {
        if (g_sprites[ i ].eid) {
            sprite_tick(&g_sprites[i], now, 0);
        }
    }
}

typedef struct {
    int x, y;
} Block;

typedef struct {
    int total;
    Block *blocks;
} Range;

Range gRanges[7];
int gBlocks[BLOCK_NUM][BLOCK_NUM] = {0,};

void map_init()
{
    memset(gRanges, 0, sizeof(gRanges));
    memset(gBlocks, 0, sizeof(gBlocks));
    memset(g_sprites, 0, sizeof(g_sprites));

    int count[7] = {0,};

    int x, y;
    int dx, dy, dt, lv;
    int bn = BLOCK_NUM / 2;
    for (y = 0; y < BLOCK_NUM; ++y) {
        for (x = 0; x < BLOCK_NUM; ++x) {
            if (x < bn) dx = bn - x - 1;
            else dx = x - bn;

            if (y < bn) dy = bn - y - 1;
            else dy = y - bn;

            dt = dx > dy ? dx : dy;
            if (dt < 2) lv = 0;
            else lv = (dt - 2)/6 + 1;

            if (lv > 5) lv = 5;
            if (dt == bn-1) lv=6;

            lv = 6-lv;

            gBlocks[ y ][ x ] = lv;
            count[ lv ] += 1;
        }
    }

    for (x = 0; x < 7; ++x) {
        gRanges[ x ].blocks = (Block*)calloc(sizeof(Block),  count[x]);
        printf("lv:%d, num:%d; ", x, count[x]);
    }
    printf("\n");

    Range * node;
    for (y = 0; y < BLOCK_NUM; ++y) {
        for (x = 0; x < BLOCK_NUM; ++x) {
            lv = gBlocks[ y ][ x ];
            node = &gRanges[ lv ];
            node->blocks[ node->total ].x = x;
            node->blocks[ node->total ].y = y;
            node->total += 1;
            g_linkmap[ y ][ x ].lv = lv;
            printf("%d,", gBlocks[y][x]);
        }
        printf("\n");
    }
}


int map_get_pos_by_lv(unsigned int lv, unsigned int w, unsigned int h)
{
    if (lv > 6) return -1;

    Range *node = &gRanges[ lv ];

    unsigned int zx, zy;
    unsigned int dx, dy, x, y;
    unsigned int i,j;
    unsigned int total = node->total;
    unsigned int idx = random();

    for (i = 0; i < total; ++i) {
        idx = (idx + 1) % total;
        zx = node->blocks[ idx ].x;
        zy = node->blocks[ idx ].y;
        for (j = 0; j < BLOCK_WIDTH; ++j) {
            dx = random() % BLOCK_WIDTH;
            dy = random() % BLOCK_WIDTH;

            x = zx * BLOCK_WIDTH + dx;
            y = zy * BLOCK_WIDTH + dy;

            if (!test_bit(x, y, w, h)) {
                return (x << 16) + y;
            }
        }
    }
    return -1;
}

int map_get_zone_lv(unsigned int zx, unsigned int zy)
{
    if (zx < BLOCK_NUM && zy < BLOCK_NUM) {
        return gBlocks[ zy ][ zx ];
    }
    return -1;
}

int map_get_pos_in_zone(unsigned int zx, unsigned int zy, unsigned int w, unsigned int h)
{
    if (zx < BLOCK_NUM && zy < BLOCK_NUM) {
        int i, x, y;
        for (i = 0; i < BLOCK_WIDTH; ++i) {
            x = zx * BLOCK_WIDTH + random() % BLOCK_WIDTH;
            y = zy * BLOCK_WIDTH + random() % BLOCK_WIDTH;
            if (!test_bit(x, y, w, h)) {
                return (x << 16) + y;
            }
        }
    }
    return -1;
}

int map_test_pos(unsigned int x, unsigned int y, unsigned int w)
{
    return test_bit(x,y,w,w);
}

unsigned int roi_get_region( unsigned x, unsigned y ) 
{
    if (x >= MAP_WIDTH || y >= MAP_WIDTH) return 0;
    unsigned char m = (gLand[ y ][ x ] & 0xE);
    unsigned int r = m >> 1;
    return r;
}

void push_msg()
{
    int i, j;
    Eye *eye;
    struct list_head *pos;
    struct Buf *buf;
    struct list_head bufq;
    INIT_LIST_HEAD(&bufq);
    
    for ( i = 0; i < HASH_SIZE; ++i ) {
        if ( !LIST_EMPTY(&g_eyes[i]) ) {
            LIST_FOR_EACH(pos, &g_eyes[i]) {
                eye = LIST_ENTRY(pos, Eye, hash);
                if (eye->snapshot) {
                    buf = eye->snapshot;
                    *(int*)buf->h = htonl(buf->t - buf->h - 4);
                    LIST_ADD_TAIL(&buf->link, &bufq);
                    eye->snapshot = NULL;
                    //printf( "push_msg, pid=%d, len=%d\n", eye->pid, buf->t - buf->h );
                }
            }
        }
    }
    if (!LIST_EMPTY(&bufq)) send_bufq(&bufq);
}

void do_append(Eye *eye, void *p, int len)
{
    if ( gGate ) {
        struct Buf *buf = eye->snapshot;
        if (!buf) {
            buf = new_buf(len+12);
            eye->snapshot = buf;
            buf->sid = gGate;
            unsigned int head[3] ={0, htonl(eye->pid), htonl(NET_SNAPSHOT)};
            fill_buf(buf, head, 12);
        }
        fill_buf(buf, p, len);
    }
}

#define EID_TYPE_RES 1
int is_res(Ety *ety)
{
    int mode = ety->eid >> 16;
    if (mode == EID_TYPE_RES) return 1;
    return 0;
}


#define IS_CROSS(tr, x, y, w) \
    is_cross(tr, x-32, y-32, w+64)


int is_cross(Ety *tr, int x, int y, int w)
{
    int sx = tr->sx;
    int sy = tr->sy;
    int dx = tr->dx;
    int dy = tr->dy;

    if (sx < x && dx < x) return 0;
    if (sx > x + w && dx > x + w) return 0;

    if (sy < y && dy < y) return 0;
    if (sy > y + w && dy > y + w) return 0;

    if (sx >= x && sx <= x + w && sy >= y && sy <= y + w) return 1;
    if (dx >= x && dx <= x + w && dy >= y && dy <= y + w) return 1;

    if (sx == dx) {
        return 1;
    } else {
        float k = (dy-sy)*1.0f/(dx-sx);
        float b = sy - k * (sx);

        float yt = k * x + b;
        if (yt >= y && yt <= y + w) return 1;

        yt = k * (x + w) +b;
        if (yt >= y && yt <= y + w) return 1;

        float xt = (y-b)/k;
        if (xt >= x && xt <= x + w) return 1;

        xt = (y+w-b)/k;
        if (xt >= x && xt <= x + w) return 1;
    }
    return 0;
}

void init_linkmap()
{
    int i,j,idx;
    int max;
    struct list_head *p;
    for (i = 0; i < 5; ++i) {
        max = MAP_WIDTH >> (i + 6);
        max += 1;

        if (max << (i+6) < MAP_WIDTH) { max += 1; }

        printf("lv=%d, max=%d\n", i, max); 
        p = (struct list_head*)calloc(sizeof(struct list_head), max * max);
        for (idx=0; idx < max*max; ++idx) INIT_LIST_HEAD( &p[idx] );
        g_troop_map[ i ].max = max;
        g_troop_map[ i ].link = p;
    }
    
    BlockNode *node;
    for (i = 0; i < BLOCK_NUM; ++i) {
        for (j = 0; j < BLOCK_NUM; ++j) {
            node = &g_linkmap[ i ][ j ];
            INIT_LIST_HEAD(&node->link_lv0);
            INIT_LIST_HEAD(&node->link_lv1);
            INIT_LIST_HEAD(&node->link_view_0);
            INIT_LIST_HEAD(&node->link_view_1);
        }
    }

    for (i = 0; i < HASH_SIZE; ++i) { 
        INIT_LIST_HEAD(&g_eyes[ i ]); 
        INIT_LIST_HEAD(&g_etys[ i ]); 
        INIT_LIST_HEAD(&g_sprs[ i ]); 
    }
}


void do_add_ety_to_eye(Ety *ety, Eye *eye, int action)
{
    int head[4] = {0, 0, 0}; // len, cmd, size of vobj, vobj
    if (action) {
        head[0] = htonl(ety->len+8);
        head[1] = htonl(PT_ADD_ETY);
        head[2] = htonl(ety->len);
        do_append(eye, head, 12);
        do_append(eye, ety->data, ety->len);
    } else {
        head[0] = htonl(8);
        head[1] = htonl(PT_REM_ETY);
        head[2] = htonl(ety->eid);
        do_append(eye, head, 12);
    }
}


// add ety to view of the player who is looking at
static int add_ety_to_eye(Ety *ety, int action)
{   
    int x = ety->x;
    int y = ety->y;
    x >>= BLOCK_BIT;
    y >>= BLOCK_BIT;

    int zx, zy, idx;
    BlockNode *node;
    struct list_head *pos;
    Eye *eye;

    int head[3] = {0, 0, 0}; // len, cmd, size of vobj, vobj
    if (action) {
        head[0] = htonl(ety->len+8);
        head[1] = htonl(PT_ADD_ETY);
        head[2] = htonl(ety->len);
    } else {
        head[0] = htonl(8);
        head[1] = htonl(PT_REM_ETY);
        head[2] = htonl(ety->eid);
    }

    for (zx = x - RANGE_DETAIL; zx <= x + RANGE_DETAIL; ++zx) {
        for (zy = y - RANGE_DETAIL; zy <= y + RANGE_DETAIL; ++zy) {
            if (zx >= 0 && zy >= 0 && zx < BLOCK_NUM && zy < BLOCK_NUM) {
                node = &g_linkmap[ zy ][ zx ];
                if (!LIST_EMPTY(&node->link_view_0)) {
                    //printf( "get_eye, x=%d, y=%d\n", zx, zy );
                    LIST_FOR_EACH(pos, &node->link_view_0) {
                        eye = (Eye*)LIST_ENTRY(pos, Eye, link);
                        //printf( "get_eye, x=%d, y=%d, pid=%d\n", zx, zy, eye->pid );
                        if ( gTime - eye->tick < 900 ) {
                            do_append(eye, head, 12);
                            if (action) {
                                do_append(eye, ety->data, ety->len);
                            } 
                        } else {
                            roi_rem_eye( eye->pid );
                        }
                    }
                }
            }
        }
    }

    if (ety->lv) {
        for (zx = x - RANGE_GLOBAL; zx <= x + RANGE_GLOBAL; ++zx) {
            for (zy = y - RANGE_GLOBAL; zy <= y + RANGE_GLOBAL; ++zy) {
                if (zx >= 0 && zy >= 0 && zx < BLOCK_NUM && zy < BLOCK_NUM) {
                    node = &g_linkmap[ zy ][ zx ];
                    if (!LIST_EMPTY(&node->link_view_1)) {
                        LIST_FOR_EACH(pos, &node->link_view_1) {
                            eye = (Eye*)LIST_ENTRY(pos, Eye, link);
                            do_append(eye, head, 12);
                            if (action) do_append(eye, ety->data, ety->len); 
                        }
                    }
                }
            }
        }
    }
    return 0;
}

//int modify_eye_troop_view(Eye *eye, int sx, int sy, int dx, int dy)
//{
//    int i, r, c, idx, w;
//    int sxl, syl, dxl, dyl;
//
//    struct list_head *pos;
//    Ety *tr;
//
//    unsigned mark = (0xFFFFFFFF) << 6;
//    int osx = sx & mark;
//    int osy = sy & mark;
//    int odx = dx & mark;
//    int ody = dy & mark;
//
//    if (osx == odx && osy == ody) return 0;
//
//    int vo, vn;
//
//    int num = 0;
//    for (i = 0; i < 5; ++i) {
//        dxl = dx >> (6+i);
//        dyl = dy >> (6+i);
//
//        for (c = dxl-1; c <= dxl+1; ++c) {
//            for (r = dyl-1; r <= dyl+1; ++r) {
//                TroopMap *m = &g_troop_map[ i ];
//                if (c >= 0 && c < m->max && r >= 0 && r < m->max) {
//                    idx = r * m->max + c;
//                    LIST_FOR_EACH(pos, &m->link[idx]) {
//                        tr = LIST_ENTRY(pos, Ety, link);
//                        vo = is_cross(tr, osx, osy, 64);
//                        vn = is_cross(tr, odx, ody, 64);
//
//                        if (!vo && vn) {
//                            //do_add_ety_to_eye(tr, eye, 1);
//                            do_append(eye, tr->data, tr->len);
//                            num++;
//                        } 
//                    }
//                }
//            }
//        }
//    }
//    return num;
//}


int modify_eye_troop_view2(Eye *eye, int sx, int sy, int dx, int dy)
{
    int i, r, c, idx, w;
    int sxl, syl, dxl, dyl;

    struct list_head *pos;
    Ety *tr;
    Sprite *spr;
    int len;
    void *p;

    unsigned mark = (0xFFFFFFFF) << 6;
    int osx = sx & mark;
    int osy = sy & mark;
    int odx = dx & mark;
    int ody = dy & mark;
    //printf(" move_eye, pid=%d, (%d,%d)->(%d,%d)\n", eye->pid, osx, osy, odx, ody );

    if (osx == odx && osy == ody) return 0;

    int vo, vn;

    int num = 0;
    for (i = 0; i < 5; ++i) {
        dxl = dx >> (6+i);
        dyl = dy >> (6+i);

        sxl = sx >> (6+i);
        syl = sy >> (6+i);

        //if ( dxl == sxl && dyl == syl ) break;

        for (c = dxl-1; c <= dxl+1; ++c) {
            for (r = dyl-1; r <= dyl+1; ++r) {
                TroopMap *m = &g_troop_map[ i ];
                if (c >= 0 && c < m->max && r >= 0 && r < m->max) {
                    idx = r * m->max + c;
                    //printf( "(col,row) = (%d,%d), lv=%d, idx=%d\n", c, r, i, idx );
                    LIST_FOR_EACH(pos, &m->link[idx]) {
                        tr = LIST_ENTRY(pos, Ety, link);
                        vo = IS_CROSS(tr, osx, osy, 64);
                        vn = IS_CROSS(tr, odx, ody, 64);
                        //printf( "eid = %d -> pid = %d, vo = %d, vn = %d, (%d,%d)->(%d,%d), lv = %d, r,c,max=%d,%d,%d \n", tr->eid, eye->pid, vo, vn, osx, osy, odx, ody, i, r, c, m->max );
                        if (!vo && vn) {
                            num++;
                            do_add_ety_to_eye(tr, eye, 1);
                            spr = get_spr(tr->eid);
                            if (spr) {
                                len = sprite_get_status(spr, &p);
                                if (len) {
                                    do_append(eye, p, len);
                                }
                            }
                        } 
                    }
                }
            }
        }

        for (c = sxl-1; c <= sxl+1; ++c) {
            for (r = syl-1; r <= syl+1; ++r) {
                TroopMap *m = &g_troop_map[ i ];
                if (c >= 0 && c < m->max && r >= 0 && r < m->max) {
                    idx = r * m->max + c;
                    LIST_FOR_EACH(pos, &m->link[idx]) {
                        tr = LIST_ENTRY(pos, Ety, link);
                        vo = IS_CROSS(tr, osx, osy, 64);
                        vn = IS_CROSS(tr, odx, ody, 64);

                        if ( vo && !vn ) {
                            do_add_ety_to_eye(tr, eye, 0);
                        } 
                    }
                }
            }
        }
    }

    return num;
}


static void move_eye(Eye *eye, int sx, int sy, int dx, int dy)
{
    if (sx < 0 || sx >= MAP_WIDTH) return;
    if (sy < 0 || sy >= MAP_WIDTH) return;
    if (dx < 0 || dx >= MAP_WIDTH) return;
    if (dy < 0 || dy >= MAP_WIDTH) return;

    int osx = sx >> BLOCK_BIT;
    int osy = sy >> BLOCK_BIT;
    int zx = dx >> BLOCK_BIT;
    int zy = dy >> BLOCK_BIT;
    if (osx == zx && osy == zy) return;

    eye->x = dx;
    eye->y = dy;

    //printf( "mov_eye, pid=%d, x=%d, y=%d, lv=%d\n", eye->pid, zx, zy, eye->lv );

    int range = 0;
    BlockNode *node = &g_linkmap[ zy ][ zx ];
    LIST_DEL_INIT(&eye->link);
    if (eye->lv) {
        range = RANGE_GLOBAL;
        LIST_ADD_TAIL(&eye->link, &node->link_view_1);
    } else {
        range = RANGE_DETAIL;
        LIST_ADD_TAIL(&eye->link, &node->link_view_0);
    }

    struct list_head *pos;
    Ety *ety;
    int r, c, nres;
    
    int head[3] = {0, htonl(PT_ADD_ETYS), 0}; // sizeof etys
    do_append(eye, head, sizeof(head));
    int pos1 = eye->snapshot->t - eye->snapshot->h - sizeof(head); // point to the packet head, the pksize space
    char b[3] = {0,};
    do_append(eye, b, sizeof(b));

    int num = 0;
    for (c = zx - range; c <= zx + range; ++c) {
        for (r = zy - range; r <= zy + range; ++r) {
            if (c >= 0 && c < BLOCK_NUM && r >= 0 && r < BLOCK_NUM) {
                if (abs(c-osx) > range || abs(r-osy) > range) {
                    node = &g_linkmap[ r ][ c ];

                    LIST_FOR_EACH(pos, &node->link_lv1) {
                        ety = (Ety*)LIST_ENTRY(pos, Ety, link);
                        num++;
                        do_append(eye, ety->data, ety->len);
                    }

                    if (range == RANGE_DETAIL) {
                        nres = 0;
                        LIST_FOR_EACH(pos, &node->link_lv0) {
                            ety = (Ety*)LIST_ENTRY(pos, Ety, link);
                            //printf( "add %d to %d\n", ety->eid, eye->pid );
                            if (is_res(ety)) nres++;
                            num++;
                            do_append(eye, ety->data, ety->len);
                        }

                        if (!nres && gTime - node->access > 3600 && node->lv < 6 && node->lv > 0) lua_post_msg_roi(ROI_NTY_NO_RES, c, r, 0, 0, 0, 0, 0, 0);
                        node->access = gTime;
                    }
                }
            }
        }
    }
    //if (!eye->lv) num += modify_eye_troop_view(eye, sx, sy, dx, dy);

    b[0] = 0xdc;                /* array 16 */
    b[1] = (num & 0xff00) >> 8;
    b[2] = num & 0xff;

    struct Buf *buf = eye->snapshot;
    if (!buf) return;

    char *cur = buf->h + pos1;
    *(int*)cur = htonl(buf->t - cur - 4); cur += 8;
    *(int*)cur = htonl(buf->t - cur - 4); cur += 4;
    memcpy(cur, b, sizeof(b));

    if (!eye->lv) num += modify_eye_troop_view2(eye, sx, sy, dx, dy);

}

int init_eye_troop_view(Eye *eye)
{
    int i, r, c, idx, w;
    int dxl, dyl;

    struct list_head *pos;
    Ety *ety;

    int dx = eye->x;
    int dy = eye->y;

    unsigned flag = (0xFFFFFFFF) << 6;
    int odx = dx & flag;
    int ody = dy & flag;

    int num = 0;
    for (i = 0; i < 5; ++i) {
        TroopMap *m = &g_troop_map[ i ];
        dxl = dx >> (6+i);
        dyl = dy >> (6+i);
        for (c = dxl-1; c <= dxl+1; ++c) {
            for (r = dyl-1; r <= dyl+1; ++r) {
                if (c >= 0 && c < m->max && r >= 0 && r < m->max) {
                    idx = r * m->max + c;
                    LIST_FOR_EACH(pos, &m->link[idx]) {
                        ety = LIST_ENTRY(pos, Ety, link);
                        if (IS_CROSS(ety, odx, ody, 64)) {
                            num++;
                            do_append(eye, ety->data, ety->len);
                        }
                    }
                }
            }
        }
    }

    return num;
}


int init_eye_troop_view2(Eye *eye)
{
    int i, r, c, idx, w;
    int dxl, dyl;

    struct list_head *pos;
    Ety *ety;

    int dx = eye->x;
    int dy = eye->y;

    unsigned flag = (0xFFFFFFFF) << 6;
    int odx = dx & flag;
    int ody = dy & flag;

    Sprite *spr;
    int num = 0;
    void *p = NULL;
    int len;

    for (i = 0; i < 5; ++i) {
        TroopMap *m = &g_troop_map[ i ];
        dxl = dx >> (6+i);
        dyl = dy >> (6+i);
        for (c = dxl-1; c <= dxl+1; ++c) {
            for (r = dyl-1; r <= dyl+1; ++r) {
                if (c >= 0 && c < m->max && r >= 0 && r < m->max) {
                    idx = r * m->max + c;
                    LIST_FOR_EACH(pos, &m->link[idx]) {
                        ety = LIST_ENTRY(pos, Ety, link);
                        if (IS_CROSS(ety, odx, ody, 64)) {
                            do_add_ety_to_eye(ety, eye, 1);
                            spr = get_spr(ety->eid);
                            if (spr) {
                                len = sprite_get_status(spr, &p);
                                if (len) {
                                    do_append(eye, p, len);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    return num;
}



// add the object on the ground to the ply
int add_eye_to_link(Eye *eye) // default level 0
{
    Eye *e;
    int x = eye->x;
    int y = eye->y;
    if (x < 0 || x >= MAP_WIDTH) return -1;
    if (y < 0 || y >= MAP_WIDTH) return -1;

    x >>= BLOCK_BIT;
    y >>= BLOCK_BIT;

    int idx = 0;
    
    INIT_LIST_HEAD(&eye->link);
    INIT_LIST_HEAD(&eye->hash);

    e = get_eye(eye->pid);
    if (e) {
        LIST_DEL_INIT(&e->link);
        LIST_DEL_INIT(&e->hash);
        if (e->snapshot) del_buf(e->snapshot);
        free(e);
        g_obj_mem -= sizeof(Eye);
        g_eye_count -= 1;
    }
    eye->tick = gTime;
    idx = eye->pid % HASH_SIZE;
    LIST_ADD_TAIL(&eye->hash, &g_eyes[idx]);

    int r, c, range,nres;
    BlockNode *node;
    struct list_head *pos;
    Ety *ety;

    //printf("add eye (row:%d, col:%d)\n", y, x);
    //LOG("add_eye, pid=%d, x=%d, y=%d, (%d,%d), pid=%d, gid=%d", eye->pid, eye->x, eye->y, x, y, eye->pid, eye->gid);
    node = &g_linkmap[ y ][ x ];
    if (eye->lv) {
        range = RANGE_GLOBAL;
        LIST_ADD_TAIL(&eye->link, &node->link_view_1);
    } else {
        range = RANGE_DETAIL;
        LIST_ADD_TAIL(&eye->link, &node->link_view_0);
    }
    
    int head[3] = {0, htonl(PT_ADD_ETYS), 0}; // sizeof etys
    do_append(eye, head, sizeof(head));
    int pos1 = eye->snapshot->t - eye->snapshot->h - sizeof(head); // point to the packet head, the pksize space
    char b[3] = {0,};
    do_append(eye, b, sizeof(b));

    int num = 0;
    for (c = x - range; c <= x + range; ++c) {
        for (r = y - range; r <= y + range; ++r) {
            if (c >= 0 && c < BLOCK_NUM && r >= 0 && r < BLOCK_NUM) {
                node = &g_linkmap[ r ][ c ];
                LIST_FOR_EACH(pos, &node->link_lv1) {
                    ety = (Ety*)LIST_ENTRY(pos, Ety, link);
                    num++;
                    do_append(eye, ety->data, ety->len);
                }

                if (range == RANGE_DETAIL) {
                    nres = 0;
                    LIST_FOR_EACH(pos, &node->link_lv0) {
                        ety = (Ety*)LIST_ENTRY(pos, Ety, link);
                        if (is_res(ety)) nres++;
                        num++;
                        do_append(eye, ety->data, ety->len);
                    }
                    if (!nres && gTime - node->access > 3600 && node->lv < 6 && node->lv > 0) lua_post_msg_roi(ROI_NTY_NO_RES, c, r, 0, 0, 0, 0, 0, 0);

                    node->access = gTime;
                }
            }
        }
    }

    //if (!eye->lv) num += init_eye_troop_view(eye);

    b[0] = 0xdc;                /* array 16 */
    b[1] = (num & 0xff00) >> 8;
    b[2] = num & 0xff;

    struct Buf *buf = eye->snapshot;
    if (!buf) {
        printf("why, no snapshot\n");
        return 0;
    }

    char *cur = buf->h + pos1;
    *(int*)cur = htonl(buf->t - cur - 4); cur += 8;
    *(int*)cur = htonl(buf->t - cur - 4); cur += 4;
    memcpy(cur, b, sizeof(b));

    if (!eye->lv) init_eye_troop_view2(eye);

    return 0;
}

void add_troop_to_eye_recur(Ety *tr, int lv, int x, int y, int action)
{
    if (!lv) {
        x = x * 4;
        y = y * 4;

        int n = 4;
        int c, r;
        BlockNode *node;
        struct list_head *pos;
        int count = 0;
        Eye *eye;
        for (c = x; c < x + 4; ++c) {
            for (r = y; r < y + 4; ++r) {
                if (c < BLOCK_NUM && r < BLOCK_NUM) {
                    node = &g_linkmap[ r ][ c ];
                    if (!LIST_EMPTY(&node->link_view_0)) {
                        count = 0;
                        LIST_FOR_EACH(pos, &node->link_view_0) {
                            count++;
                            eye = (Eye*)LIST_ENTRY(pos, Eye, link);
                            //printf("add_troop_to_eye @@, eid:%d -> pid:%d, col=%d, row=%d\n", tr->eid, eye->pid, c, r);
                            do_add_ety_to_eye(tr, eye, action);
                            if (count > 30) {
                                WARN("%s:%d", __FILE__, __LINE__);
                                break;
                                //sleep(3600);
                            }
                        }
                    }
                }
            }
        }
        return;
    }
    int rx = x << (6+lv);
    int ry = y << (6+lv);
    int w = 1 << (6+lv-1);

    if (IS_CROSS(tr,   rx,   ry, w)) add_troop_to_eye_recur(tr, lv-1, 2*x, 2*y, action);
    if (IS_CROSS(tr,   rx, ry+w, w)) add_troop_to_eye_recur(tr, lv-1, 2*x, 2*y+1, action);
    if (IS_CROSS(tr, rx+w,   ry, w)) add_troop_to_eye_recur(tr, lv-1, 2*x+1, 2*y, action);
    if (IS_CROSS(tr, rx+w, ry+w, w)) add_troop_to_eye_recur(tr, lv-1, 2*x+1, 2*y+1, action);
}


void add_to_troop_cover_recur(Ety *tr, int x, int y, int w, int len, void *msg)
{
    if (w <= 64) {
        x >>= 4;
        y >>= 4;

        int c, r, count;
        BlockNode *node;
        struct list_head *pos;
        Eye *eye;

        for (c = x; c < x+4; ++c) {
            for (r = y; r < y+4; ++r) {
                if (c < BLOCK_NUM && r < BLOCK_NUM) {
                    node = &g_linkmap[ r ][ c ];
                    if (!LIST_EMPTY(&node->link_view_0)) {
                        count = 0;
                        LIST_FOR_EACH(pos, &node->link_view_0) {
                            count++;
                            eye = (Eye*)LIST_ENTRY(pos, Eye, link);
                            do_append(eye, msg, len);

                            if (count > 30) {
                                WARN("%s:%d", __FILE__, __LINE__);
                                break;
                            }
                        }
                    }
                }
            }
        }
        return;
    } 

    w >>= 1;

    if (IS_CROSS(tr,   x,   y, w)) add_to_troop_cover_recur(tr,   x,   y, w, len, msg);
    if (IS_CROSS(tr,   x, w+y, w)) add_to_troop_cover_recur(tr,   x, w+y, w, len, msg);
    if (IS_CROSS(tr, w+x,   y, w)) add_to_troop_cover_recur(tr, w+x,   y, w, len, msg);
    if (IS_CROSS(tr, w+x, w+y, w)) add_to_troop_cover_recur(tr, w+x, w+y, w, len, msg);
}


void add_to_troop_cover(Ety *tr, int len, void *msg)
{
    int x = tr->x;
    int y = tr->y;
    int l = tr->lv;
    if (l < 0 || l >= 5) return;

    TroopMap *node = &g_troop_map[ l ];
    if (x < 0 || x >= node->max) return;
    if (y < 0 || y >= node->max) return;

    int c, r, idx, rx, ry;
    int w = 1 << (6+l);
    //LOG("add_troop_to_eye_recur, hit, lv=%d, action=%d, (%d,%d)->(%d,%d) ", tr->lv, action, tr->sx, tr->sy, tr->dx, tr->dy);

    for (c = x - 1; c <= x + 1; ++c) {
        for (r = y - 1; r <= y + 1; ++r) {
            if (c >= 0 && c < node->max && r >= 0 &&  r < node->max) {
                rx = c << (6 + l);
                ry = r << (6 + l);
                //printf("add_troop, check, rx=%d, ry=%d, w=%d, action=%d, pos=(%d,%d), max=%d\n", rx, ry, w, action, c, r, node->max);
                if (IS_CROSS(tr, rx, ry, w)) {
                    //printf("add_troop, cross, rx=%d, ry=%d, w=%d, action=%d, pos=(%d,%d)\n", rx, ry, w, action, c, r);
                    add_to_troop_cover_recur(tr, rx, ry, w, len, msg);
                }
            }
        }
    }
}


void sprite_set_status(Sprite *spr)
{
    int len = 0;
    void *msg;

    Ety *tr = get_ety(spr->eid);
    if (tr) {
        len = sprite_get_status(spr, &msg);
        if (len) add_to_troop_cover(tr, len, msg);
    }
}


void add_troop_to_eye(Ety *tr, int action)
{
    int x = tr->x;
    int y = tr->y;
    int l = tr->lv;
    if (l < 0 || l >= 5) return;

    TroopMap *node = &g_troop_map[ l ];
    if (x < 0 || x >= node->max) return;
    if (y < 0 || y >= node->max) return;

    int c, r, idx, rx, ry;
    int w = 1 << (6+l);

    for (c = x - 1; c <= x + 1; ++c) {
        for (r = y - 1; r <= y + 1; ++r) {
            if (c >= 0 && c < node->max && r >= 0 &&  r < node->max) {
                rx = c << (6 + l);
                ry = r << (6 + l);
                if (IS_CROSS(tr, rx, ry, w)) {
                    add_troop_to_eye_recur(tr, l, c, r, action);
                }
            }
        }
    }
}


int add_troop_to_link(Ety *tr)
{
    int sx = tr->sx;
    int sy = tr->sy;
    int dx = tr->dx;
    int dy = tr->dy;

    if (sx < 0 || sx >= MAP_WIDTH) return -1;
    if (sy < 0 || sy >= MAP_WIDTH) return -1;

    if (dx < 0 || dx >= MAP_WIDTH) return -1;
    if (dy < 0 || dy >= MAP_WIDTH) return -1;

    if (sx == 0 && dx == 0 && sy == 0 && dy ==0) return -1;

    int eid = tr->eid;
    rem_eid(eid);

    tr->x = tr->dx;
    tr->y = tr->dy;

    int w = pow(pow(dx-sx, 2) + pow(dy-sy, 2), 0.5);
    int lv = 0;
    if (w < 64) lv = 0;
    else if(w < 128) lv = 1;
    else if(w < 256) lv = 2;
    else lv = 3;

    if (w < 64) lv = 0;
    else if(w < 128) lv = 1;
    else if(w < 256) lv = 2;
    else if(w < 512) lv = 3;
    else lv = 4;

    tr->lv = lv;
    int x = sx + (dx - sx) * 0.5;
    int y = sy + (dy - sy) * 0.5;

    x >>= (lv+6);
    y >>= (lv+6);

    //printf("add_troop, (%d,%d)->(%d,%d), w=%d, lv=%d, pos=(%d,%d)\n", sx, sy, dx, dy, w, lv, x, y);

    TroopMap *node = &g_troop_map[ lv ];
    if (x >= node->max || y >= node->max) return -1;

    tr->x = x;
    tr->y = y;

    LOG("add_troop, eid=%d, lv=%d, x=%d, y=%d, (%d,%d)->(%d,%d)", tr->eid, tr->lv, tr->x, tr->y, tr->sx, tr->sy, tr->dx, tr->dy);

    int idx = (eid >> 12) & 0x0FFFF;
    LIST_ADD_TAIL(&tr->hash, &g_etys[ idx ]);

    idx = y * node->max + x;
    LIST_ADD_TAIL(&tr->link, &node->link[idx]);
    check_in(tr);

    if (!g_state_init) add_troop_to_eye(tr, 1);

    return 0;
}


int add_ety_to_link(Ety *ety)
{
    if (ety->x < 0) return -1;
    if (ety->y < 0) return -1;
    if (ety->x >= MAP_WIDTH) return -1;
    if (ety->y >= MAP_WIDTH) return -1;

    int eid = ety->eid;
    rem_eid(eid);


    Ety *old = get_ety( eid );
    if ( old ) {
        if ( old->x == ety->x && old->y == ety->y && old->r == ety->r && old->lv == ety->r ) {
            if ( old->data ) free( old->data );
            g_obj_mem += ( ety->len - old->len);
            old->data = ety->data;
            old->len = ety->len;
            ety->data = NULL;
            ety->len = 0;
            free( ety );
            if (!g_state_init) add_ety_to_eye(old, 1);
            return 0;
        }
    }

    int lv = ety->lv;
    int x = ety->x;
    int y = ety->y;

    if (ety->r > 0) roi_set_bit(x, y, ety->r);

    x >>= BLOCK_BIT;
    y >>= BLOCK_BIT;
    //printf( "add_ety, eid=%d, x=%d, y=%d, lv=%d\n", eid, x, y, lv );

    if (!lv) {
        LIST_ADD_TAIL(&ety->link, &g_linkmap[ y ][ x ].link_lv0);
    } else {
        LIST_ADD_TAIL(&ety->link, &g_linkmap[ y ][ x ].link_lv1);
    }
    int idx = (eid >> 12) & 0x0FFFF;
    LIST_ADD_TAIL(&ety->hash, &g_etys[ idx ]);

    if (!g_state_init) add_ety_to_eye(ety, 1);
    check_in(ety);
    return 0;
}

void do_broadcast(int x, int y, int lv, struct Buf *buf)
{
    int zx, zy, idx;
    BlockNode *node;
    struct list_head *pos;
    Eye *eye;
    struct Buf *btmp;

    for (zx = x - RANGE_DETAIL; zx <= x + RANGE_DETAIL; ++zx) {
        for (zy = y - RANGE_DETAIL; zy <= y + RANGE_DETAIL; ++zy) {
            if (zx >= 0 && zy >= 0 && zx < BLOCK_NUM && zy < BLOCK_NUM) {
                node = &g_linkmap[ zy ][ zx ];
                if (!LIST_EMPTY(&node->link_view_0)) {
                    LIST_FOR_EACH(pos, &node->link_view_0) {
                        eye = (Eye*)LIST_ENTRY(pos, Eye, link);
                        do_append(eye, buf->h, buf->t - buf->h);
                    }
                }
            }
        }
    }

    if (lv) {
        for (zx = x - RANGE_GLOBAL; zx <= x + RANGE_GLOBAL; ++zx) {
            for (zy = y - RANGE_GLOBAL; zy <= y + RANGE_GLOBAL; ++zy) {
                if (zx >= 0 && zy >= 0 && zx < BLOCK_NUM && zy < BLOCK_NUM) {
                    node = &g_linkmap[ zy ][ zx ];
                    if (!LIST_EMPTY(&node->link_view_1)) {
                        LIST_FOR_EACH(pos, &node->link_view_1) {
                            eye = (Eye*)LIST_ENTRY(pos, Eye, link);
                            do_append(eye, buf->h, buf->t - buf->h);
                        }
                    }
                }
            }
        }
    }
}

void broadcast(int eid, struct Buf *buf)
{
    Ety *ety = get_ety(eid);
    if (!ety) return;

    int lv = ntohl(*(int*)(buf->h+4));
    int x = ety->x;
    int y = ety->y;
    
    if (x < 0 || x >= MAP_WIDTH) return;
    if (y < 0 || y >= MAP_WIDTH) return;

    x >>= BLOCK_BIT;
    y >>= BLOCK_BIT;

    do_broadcast(x, y, lv, buf);
    del_buf(buf);
}

void do_msg(Msg *msg)
{
    Ety *ety;
    Eye *eye;
    Sprite *spr;
    int eid, i;
    switch (msg->cmd) {
        case ROI_BROADCAST:
            broadcast(msg->d0, (struct Buf*)msg->body);
            break;

        case ROI_ADD_ETY:
            ety = (Ety*)msg->body;
            if (ety) {
                if (add_ety_to_link(ety)) {
                    if (ety->data) free(ety->data);
                    free(ety);
                }
            }
            break;

        case ROI_ADD_TROOP:
            ety = (Ety*)msg->body;
            if (ety) {
                if (add_troop_to_link(ety)) {
                    if (ety->data) free(ety->data);
                    free(ety);
                }
            }
            break;

        case ROI_REM_ETY:
            ety = get_ety(msg->d0);
            if (ety) {
                if (ety->sx || ety->sy || ety->dx || ety->dy) {
                    add_troop_to_eye(ety, 0);
                } else {
                    add_ety_to_eye(ety, 0);
                }
                rem_ety(ety);
            }
            break;

        case ROI_ADD_EYE:
            eye = (Eye*)msg->body;
            if (add_eye_to_link(eye)) {
                free(eye);
            } else {
                g_obj_mem += sizeof(Eye);
                g_eye_count += 1;
            }
            break;

        case ROI_REM_EYE:
            eye = get_eye(msg->d0);
            if (eye) {
                LIST_DEL(&eye->link);
                LIST_DEL(&eye->hash);
                if (eye->snapshot) del_buf(eye->snapshot);
                free(eye);
                g_obj_mem -= sizeof(Eye);
                g_eye_count -= 1;
            }
            break;

        case ROI_MOV_EYE:
            eye = get_eye(msg->d0);
            if (eye) {
                eye->tick = gTime;
                move_eye(eye, eye->x, eye->y, msg->d1, msg->d2);
            } else {
                roi_add_eye( msg->d1, msg->d2, 0, msg->d0, 0);
            }
            break;

        case ROI_ADD_SCAN:
            ety = get_ety(msg->d0);
            if (ety) {
                //printf("add_scan, eid=%d, range=%d, x=%d, y=%d, \n", ety->eid, msg->d1, ety->x, ety->y);
                ety->range = msg->d1;
            }
            break;

        case ROI_REM_SCAN:
            ety = get_ety(msg->d0);
            if (ety) {
                ety->range = 0;
            }
            break;

        case ROI_ADD_ACTOR:
            sprite_create(msg->d0, msg->d1, msg->d2, msg->d3, msg->d4, msg->d5, msg->d6 * 0.001f);
            break;

        case ROI_REM_ACTOR:
            eid = msg->d0;
            spr = get_spr(eid);
            if (spr) {
                sprite_del(spr);
            }
            break;

        case ROI_UPD_ACTOR:
            eid = msg->d0;
            spr = get_spr(eid);
            if (spr) {
                spr->speed = msg->d1 * 0.001f;
                sprite_set_status(spr);
            }
            break;

        case ROI_STOP:
            free(msg);
            return;

        case ROI_TIME_STEP:
            gTime = msg->d0;
            gMsec = (gTime - tsStart.tv_sec)*1000;
            sprite_process(gMsec);
            lua_post_msg_roi(ROI_TIME_STEP, gTime, gMsec, 0, 0, 0, 0, 0, 0);
            break;

        default:
            INFO("cmd = %d, no handle\n", msg->cmd);
            if (msg->body) free(msg->body);
            break;
    }
    free(msg);
}

void *loop_roi(void *arg)
{
    init_linkmap();

    struct list_head *pos;
    struct list_head pending;
    INIT_LIST_HEAD(&pending);
    int deadline = gMsec;
    Msg *msg;

    while (gOn) {
        if (gTimeControl) {
            //pos = QueGet(&g_msgq);
            //msg = LIST_ENTRY(pos, Msg, link);
            //do_msg(msg);

            sleep(1);
        } else {
            deadline = gMsec + 50;
            QueTryAll(&g_msgq, &pending);
            if (!LIST_EMPTY(&pending)) {
                while (!LIST_EMPTY(&pending)) {
                    pos = pending.next;
                    LIST_DEL(pos);
                    msg = LIST_ENTRY(pos, Msg, link);
                    do_msg(msg);
                }
            }
            if (deadline > gMsec) sprite_process(gMsec);
            if (deadline > gMsec) {
                int nsleep = deadline - gMsec;
                if (nsleep < 0) nsleep = 0;
                if (nsleep > 50) nsleep = 50;
                if (nsleep > 0) usleep(nsleep * 1000);
            }
            push_msg();
        }
    }
}

static void thread_handle_roi(int start)
{
    static pthread_t tid; 
    if (start) {
        QueInit(&g_msgq);
        printf("roi_start\n");

        pthread_attr_t attr;
        pthread_attr_init(&attr); 
        pthread_create(&tid,&attr,loop_roi,NULL);
        pthread_attr_destroy(&attr);
    } else {
        send_msg_to_roi(ROI_STOP, 0, NULL);
        pthread_join(tid, NULL);
    }
}

void roi_start()
{
    thread_handle_roi(1);
}

void stop_roi()
{
    thread_handle_roi(0);
}

void roi_view_start()
{
    g_state_init = 0;
}

void send_msg_to_roi(int cmd, int d0, void *body)
{
    Msg *msg = (Msg *)calloc(sizeof(Msg), 1);
    msg->cmd = cmd;
    msg->d0 = d0;
    msg->body = body;
    QuePut(&g_msgq, &msg->link);
}


void roi_add_eye(int x, int y, int lv, int pid, int gid) 
{
    Eye *e = (Eye*)calloc(sizeof(Eye), 1);
    if (!e) {
        printf("can not calloc");
        sleep(3600);
    };
    e->x = x;
    e->y = y;
    e->lv = lv;
    e->pid = pid;
    e->gid = gid;
    e->magic = 20100731;
    send_msg_to_roi(ROI_ADD_EYE, 0, e);
}

void roi_add_ety(int eid, int x, int y, int r, int lv, int sz, void *buffer)
{
    Ety *ety = (Ety*)calloc(sizeof(Ety), 1);
    INIT_LIST_HEAD(&ety->link);
    ety->eid = eid;
    ety->x = x;
    ety->y = y;
    ety->r = r;
    ety->lv = lv;
    if (sz > 0) {
        void *body = calloc(sz, 1);
        memcpy(body, buffer, sz);
        ety->data = body;
        ety->len = sz;
    }
    send_msg_to_roi(ROI_ADD_ETY, 0, ety);
}

void roi_add_troop(int eid, int sx, int sy, int dx, int dy, int sz, void *buffer)
{
    Ety *ety = (Ety*)calloc(sizeof(Ety), 1);
    INIT_LIST_HEAD(&ety->link);
    ety->eid = eid;
    ety->sx = sx;
    ety->sy = sy;
    ety->dx = dx;
    ety->dy = dy;

    if (sz > 0) {
        void *body = calloc(sz, 1);
        memcpy(body, buffer, sz);
        ety->data = body;
        ety->len = sz;
    }
    send_msg_to_roi(ROI_ADD_TROOP, 0, ety);
}


void roi_rem_eye(int pid)
{
    send_msg_to_roi(ROI_REM_EYE, pid, NULL);
}

void roi_rem_ety(int eid)
{
    send_msg_to_roi(ROI_REM_ETY, eid, NULL);
}

int roi_access_time(int zx, int zy)
{
    if (zx >= 0 && zx < BLOCK_NUM && zy >= 0 && zy < BLOCK_NUM) {
        return g_linkmap[ zy ][ zx ].access;
    }
    return gTime + 1;
}

void roi_mov_eye(int eid, int x, int y)
{
    Msg *msg = (Msg *)calloc(sizeof(Msg), 1);
    msg->cmd = ROI_MOV_EYE;
    msg->d0 = eid;
    msg->d1 = x;
    msg->d2 = y;
    QuePut(&g_msgq, &msg->link);
}

void roi_broadcast(int eid, struct Buf *buf)
{
    // buf->sid is the eid around
    send_msg_to_roi(ROI_BROADCAST, buf->sid, buf);
}

int roi_set_block(const char* fname)
{
    unsigned char map[MAP_WIDTH * MAP_WIDTH] = {0,};
    FILE *f = fopen(fname, "r");
    int x,y,idx;
    int rt = 0;
    if (f) {
        if (fread(map, 1, sizeof(map), f) == sizeof(map)) {
            for (y = 0; y < MAP_WIDTH; ++y) {
                for (x = 0; x < MAP_WIDTH; ++x) {
                    idx = y * MAP_WIDTH + x;
                    gLand[ y ][ x ] = map[ idx ];
                    //if( map[idx] ) {
                    //    set_bit(x, y, 1, 1);
                    //}
                }
            }
            rt = 1;
        }
        fclose(f);
    }
    return rt;
}

void roi_add_scan(int eid, int range)
{
    Msg *msg = (Msg *)calloc(sizeof(Msg), 1);
    msg->cmd = ROI_ADD_SCAN;
    msg->d0 = eid;
    msg->d1 = range;
    QuePut(&g_msgq, &msg->link);
}


void roi_rem_scan(int eid)
{
    Msg *msg = (Msg *)calloc(sizeof(Msg), 1);
    msg->cmd = ROI_REM_SCAN;
    msg->d0 = eid;
    QuePut(&g_msgq, &msg->link);
}

void roi_add_actor(int eid, int sx, int sy, int dx, int dy, int tick, float speed)
{
    Msg *msg = (Msg *)calloc(sizeof(Msg), 1);
    msg->cmd = ROI_ADD_ACTOR;
    msg->d0 = eid;
    msg->d1 = sx;
    msg->d2 = sy;
    msg->d3 = dx;
    msg->d4 = dy;
    msg->d5 = tick;
    msg->d6 = speed * 1000;
    QuePut(&g_msgq, &msg->link);
}

void roi_rem_actor(int eid)
{
    Msg *msg = (Msg *)calloc(sizeof(Msg), 1);
    msg->cmd = ROI_REM_ACTOR;
    msg->d0 = eid;
    QuePut(&g_msgq, &msg->link);
}

void roi_upd_actor(int eid, float speed)
{
    Msg *msg = (Msg *)calloc(sizeof(Msg), 1);
    msg->cmd = ROI_UPD_ACTOR;
    msg->d0 = eid;
    msg->d1 = speed * 1000;
    QuePut(&g_msgq, &msg->link);
}



void roi_time_step(int curSec)
{
    Msg *msg;
    unsigned int msec = (curSec - tsStart.tv_sec) * 1000;
    if (msec > 0) {
        struct list_head *pos;
        struct list_head pending;
        INIT_LIST_HEAD(&pending);
        QueTryAll(&g_msgq, &pending);
        if (!LIST_EMPTY(&pending)) {
            while (!LIST_EMPTY(&pending)) {
                pos = pending.next;
                LIST_DEL(pos);
                msg = LIST_ENTRY(pos, Msg, link);
                do_msg(msg);
            }
        }
        //sprite_process(curSec);
        sprite_process(msec);
    }
}

void roi_time_set_start(int curSec)
{}

void roi_set_bit(unsigned int x, unsigned int y, unsigned int r)
{
    set_bit(x, y, r, r);
}

int roi_get_actor_pos(int eid, float *x, float *y)
{
    Sprite *spr = get_spr(eid);
    if (spr) {
        *x = spr->cur.x;
        *y = spr->cur.y;
        return 1;
    }
    return 0;
}

unsigned int roi_get_culture( unsigned int x, unsigned int y )
{
    if (x >= MAP_WIDTH || y >= MAP_WIDTH) return -1;
    unsigned int bit = gLand[ y ][ x ];
    return (bit >> 1) & 7;
}

