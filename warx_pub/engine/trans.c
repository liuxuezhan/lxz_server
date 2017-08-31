#include <event.h>
#include <event2/listener.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <pthread.h>
#include <assert.h>
#include "mylist.h"
#include "pike.h"
#include "buf.h"
#include "log.h"

#define N_THREAD 8
#define LOOP_TICK 10000
#define MAX_MAP 0x01000

// from the net kernel
#define NET_PING        1
#define NET_PONG        2
#define NET_ADD_LISTEN  3
#define NET_ADD_INCOME  4
#define NET_CMD_CLOSE   5
#define NET_MSG_CLOSE   6 
#define NET_CMD_STOP    7
#define NET_SET_MAP_ID  8
#define NET_SET_SRV_ID  9

#define MAX_SERVER_PACKET_SIZE 0x2000000
#define MAX_CLIENT_PACKET_SIZE 0x10000

struct Thread {
    struct list_head sendQ;
    struct list_head transQ[ N_THREAD ];
    struct event_base *base;
    pthread_mutex_t lock;
    pthread_t tid;
    struct timeval  tickTm;
    struct event    tickEv;
    int idx;
} ;

struct Sess {
    int fd;
    int sid;
    int mid;
    int sid2srv;
    struct Buf *bufr, *bufw;
    struct list_head bufwq;
    int encrypt, mode;  // mode=0, normal; mode=1, gate front clint; mode=2, gate front server
    struct event evr, evw;
    Ctx ctxr, ctxw;
    struct timeval tm;
    struct Thread *master;
} ;

struct Thread vThread[ N_THREAD ];
static struct Sess* gSess[0x010000];
static int gMap2Sid[MAX_MAP][2];

static int gSn = 1;

unsigned int makesid(int fd)
{
    gSn++;
    if (gSn >= 0x08000) gSn = 1;
    return (gSn << 16) + fd;
}

struct Sess* get_sess(int sid)
{
    if (sid > 0) {
        struct Sess* s = gSess[ sid & 0x0FFFF ];
        if (s && s->sid == sid) return s;
    }
    return NULL;
}

struct Sess *get_slot(int fd)
{
    if (fd >= 0 && fd < 0x010000) {
        if (gSess[fd]) return gSess[ fd ];
        struct Sess *s = calloc(sizeof(struct Sess), 1);
        s->fd = fd;
        INIT_LIST_HEAD(&s->bufwq);
        gSess[ fd ] = s;
        return s;
    }
    return NULL;
}

int setSidForMap(int mapid, int sid)
{
    int i = 0;
    int idx = -1;
    int mid = -1;
    for (i = 0; i < MAX_MAP; ++i) {
        mid = gMap2Sid[i][0];
        if (mid == mapid) {
            gMap2Sid[i][1] = sid;
            LOG("setSidForMap, idx=%d, mid=%d, fd=%d, sid=%d", i, mapid, sid & 0x0FFFF, sid);
            return 0;
        } else if( idx==-1 && mid == 0) {
            idx = i;
        }
    }

    if (idx >= 0) {
        gMap2Sid[idx][0] = mapid;
        gMap2Sid[idx][1] = sid;
        LOG("setSidForMap, idx=%d, mid=%d, fd=%d, sid=%d", idx, mapid, sid & 0x0FFFF, sid);
        return 0;
    }
    return -1;
}


int getSidFromMap(int mapid)
{
    int i = 0;
    for (i = 0; i < MAX_MAP; ++i) {
        if (gMap2Sid[i][0] == mapid) return gMap2Sid[i][1];
    }
    return 0;
}

struct Buf* get_sess_write_buf(struct Sess *dsts, int size)
{
    struct Buf* buf = NULL;
    struct list_head *pos;
    unsigned int remain;
    int flag = 0;
    if (!LIST_EMPTY(&dsts->bufwq)) {
        pos = dsts->bufwq.prev;
        buf = LIST_ENTRY(pos, struct Buf, link);
        if (buf->e - buf->t >= size) return buf;
    }
    return NULL;
}

void cb_accept(struct evconnlistener *lsn, evutil_socket_t client_fd, struct sockaddr* addr, int addrlen,  void *arg)
{
    struct Sess *sSrv = (struct Sess*)arg;
    struct Buf *buf = new_buf(0);
    char *cur = buf->h;
    *(int*)(cur+0) = NET_ADD_INCOME;
    *(int*)(cur+4) = client_fd;
    *(int*)(cur+8) = sSrv->mode;
    *(int*)(cur+12) = sSrv->encrypt;
    buf->t += 16;
    buf->sid = 0;
    LOG("income, fd=%d, mode=%d, encrypt=%d, ip=%s\n", client_fd, sSrv->mode, sSrv->encrypt, inet_ntoa(((struct sockaddr_in*)addr)->sin_addr));

    struct Thread *master = sSrv->master;
    LIST_ADD_TAIL(&buf->link, &(master->transQ[ client_fd % N_THREAD ]));
}

void doclose_session(struct Sess *s) 
{
    LOG("close_session, fd=%d", s->fd);
    int fd = s->fd;

    if (s->bufr) {
        del_buf(s->bufr);
        s->bufr = NULL;
    }

    if (s->bufw) {
        del_buf(s->bufw);
        s->bufw = NULL;
    }

    struct list_head *pos;
    struct Buf *buf;
    while (!LIST_EMPTY(&s->bufwq)) {
        pos = s->bufwq.next;
        LIST_DEL(pos);
        buf = LIST_ENTRY(pos, struct Buf, link);
        del_buf(buf);
    }

    if (s->fd >= 8192) {
        gSess[ s->fd ] = NULL;
        free(s);
    } else {
        memset(s, 0, sizeof(struct Sess));
        INIT_LIST_HEAD(&s->bufwq);
    }
    close(fd);
}

void close_session(struct Sess *s) 
{
    event_del(&s->evr);
    if (!LIST_EMPTY(&s->bufwq) || s->bufw) event_del(&s->evw);

    if (s->mode == 1) {
        struct Buf *buf = new_buf(0);
        *(int*)(buf->t) = htonl(8);
        *(int*)(buf->t+4) = htonl(s->sid);
        *(int*)(buf->t+8) = htonl(NET_MSG_CLOSE);
        buf->t += 12;
        buf->sid = s->sid2srv;
        LIST_ADD_TAIL(&buf->link, &s->master->transQ[ s->sid2srv % N_THREAD ]);
    }
    doclose_session(s);
}


void read_wait(int fd, short ev, void *arg)
{
    struct Sess *s = (struct Sess*)arg;
    if (ev == EV_TIMEOUT) {
        LOG("read_first_packet, fd=%d, timeout", fd);
        return doclose_session(s);
    }
}

void read_first_packet(int fd, short ev, void *arg)
{
    struct Sess *s = (struct Sess*)arg;

    if (ev == EV_TIMEOUT) {
        LOG("read_first_packet, fd=%d, timeout", fd);
        return doclose_session(s);

    } else if (ev == EV_READ) {
        unsigned int val[512];      // len, pktype, mapid, ...
        unsigned int pksize, pktype, mapid, sid2srv;

        size_t len = recv(fd, &val, sizeof(val), 0);


        if (len < 12) return doclose_session(s);
        assert(len < 512);


        char tips[16];
        sprintf(tips, "RECV %04d:", fd);
        //dump(val, len, tips);

        if (s->encrypt) {
            ctx_init(s->sid, &s->ctxr);
            ctx_init(s->sid, &s->ctxw);
            ctx_encode(&s->ctxr, val, len);
        }

        pksize = ntohl(val[0]);
        if (len != pksize + 4) return doclose_session(s);
        
        pktype = ntohl(val[1]);

        mapid = ntohl(val[2]);
        sid2srv = getSidFromMap(mapid);

        if (!sid2srv) {
            LOG("read_first_packet, not map, fd=%d, len=%d, mapid=%d", fd, len, mapid);
            LOG("no mapid");
            return doclose_session(s);
        }

        struct Sess *dsts = get_sess(sid2srv);
        if (!dsts) return doclose_session(s);

        struct Thread *master = s->master;
        
        // the src is : pksize, pktype, ...
        // transto be : pksize, sockid, pktype, ...
        struct Buf *buf = new_buf(0);
        char *cur = buf->t;
        *(unsigned int*)(cur + 0) = htonl(pksize+4);
        *(unsigned int*)(cur + 4) = htonl(s->sid);

        memcpy(cur+8, &val[1], len-4);
        buf->t += (len+4);
        buf->sid = dsts->sid;
        LIST_ADD_TAIL(&buf->link, &(master->transQ[ dsts->fd % N_THREAD ]));
        
        s->tm.tv_sec = 5;
        s->tm.tv_usec = 0;
        event_assign(&s->evr, master->base, fd, EV_TIMEOUT, read_wait, s);
        event_add(&s->evr, NULL);

        LOG("read_first_packet, fd=%d, mapid=%d", fd, mapid);
    }
}

int read_data(int fd, short ev, struct Sess *s)
{
    if (ev == EV_READ) {
        if (!s->bufr) s->bufr = new_buf(0);
        struct Buf *buf = s->bufr;
        if (buf->e > buf->t) {
            int nRead = recv(fd, buf->t, buf->e - buf->t, 0);
            LOG("read_data, fd=%d, nRead=%d, room=%d", fd, nRead, buf->e - buf->t);

            char tips[16];
            sprintf(tips, "RECV %04d:", fd);
            //dump(buf->t, nRead, tips);

            if (nRead > 0) {
                if (s->encrypt) ctx_encode(&s->ctxr, buf->t, nRead);
                buf->t += nRead;
                return nRead;
            }
        } else {
            LOG("NET_ERROR: %d", __LINE__);
        }
    } else {
        LOG("read_data, what ev, %d", ev);
    
    }
    return 0;
}


struct Buf* handle_read_remain(struct Buf *buf, char *cur, int isCli)
{
    char *end = buf->t;
    int remain = end - cur;
    assert(remain >= 0);
    if (remain == 0) {
        if (buf->b != buf->pool) {
            del_buf(buf);
            return NULL;
        } else {
            buf->h = buf->b;
            buf->t = buf->b;
            buf->e = buf->h + sizeof(buf->pool);
        }
    } else {
        int handle = cur - buf->h;
        if (!handle) {
            if (buf->e == buf->t) {
                int pksize = ntohl(*(int*)(buf->h));
                if (pksize + 4 > buf->e - buf->h) {
                    struct Buf *newbuf = new_buf(pksize+4);
                    memcpy(newbuf->h, buf->h, remain);
                    newbuf->t += remain;
                    del_buf(buf);
                    return newbuf;
                }
            }
        } else {
            memmove(buf->h, cur, remain);
            buf->t = buf->h + remain;
        }
    }
    return buf;
}


void read_cli(int fd, short ev, void *arg)
{
    struct Sess *s = (struct Sess*)arg;
    if (!read_data(fd, ev, s)) return close_session(s);

    unsigned int pktype, pksize, remain, handle;
    struct Buf *buf = s->bufr;
    struct Buf *newbuf;
    int clid;
    struct Sess *srv;

    char *old, *cur, *end; 
    cur = buf->h;
    old = cur;
    end = buf->t;

    struct Thread *master = s->master;
    while (end - cur >= 4) {
        pksize = ntohl(*(unsigned int*)cur);
        if (pksize < 4) return close_session(s);
        if (pksize >= MAX_CLIENT_PACKET_SIZE) return close_session(s);
        if (cur + 4 + pksize > end) break;

        pktype = ntohl(*(int*)(cur+4));
        if (pktype == NET_PING) {
            newbuf = get_sess_write_buf(s, 8);
            if (!newbuf) { 
                newbuf = new_buf(8);
                LIST_ADD_TAIL(&newbuf->link, &s->bufwq);
            }
            *(int*)(newbuf->t) = htonl(4);
            *(int*)(newbuf->t + 4) = htonl(NET_PONG);
            newbuf->t += 8;

        } else if (pktype == NET_PONG) {

        } else {
            // pksize, pktype, ...
            // pksize, clisid, pktype, ...
            // think it just pktype, no value, the pksize = 4
            srv = get_sess(s->sid2srv);
            if (srv) {
                newbuf = new_buf(pksize+8);
                *(int*)(newbuf->t) = htonl(pksize + 4);
                *(int*)(newbuf->t+4) = htonl(s->sid);
                memcpy(newbuf->t+8, cur+4, pksize);
                newbuf->t += (pksize+8);
                newbuf->sid = s->sid2srv;
                LIST_ADD_TAIL(&newbuf->link, &master->transQ[ srv->fd % N_THREAD]);
            }
        }
        cur += (pksize+4);
    }
    s->bufr = handle_read_remain(buf, cur, 1);
}

void cb_write(int fd, short ev, void *arg)
{
    int more, room;
    struct Sess *s = (struct Sess*)arg;
    struct Buf *buf, *tbuf;
    struct list_head *pos;
    buf = s->bufw;
    if (!buf) {
        if (!LIST_EMPTY(&s->bufwq)) {
            pos = s->bufwq.next;
            LIST_DEL(pos);
            buf = LIST_ENTRY(pos, struct Buf, link);
            s->bufw = buf;
        }

        if (buf) {
            room = buf->e - buf->t;
            while (!LIST_EMPTY(&s->bufwq)) {
                pos = s->bufwq.next;
                tbuf = LIST_ENTRY(pos, struct Buf, link);
                more = tbuf->t - tbuf->h;
                if (room < more) break;

                memcpy(buf->t, tbuf->h, more);
                buf->t += more;
                room -= more;
                LIST_DEL(pos);
                del_buf(tbuf);
            }
            if (s->encrypt) ctx_encode(&s->ctxw, buf->h, buf->t - buf->h);
        }
    }

    if (!buf) return;
    int need = buf->t - buf->h;
    int len = 0;
    
    if (need > 0) {
        len = send(s->fd, buf->h, need, 0);
        if (len < 0) return close_session(s);

        char tips[16];
        sprintf(tips, "SEND %04d:", fd);
        //dump(buf->h, len, tips);
        buf->h += len;
    }

    if (need == len) {
        del_buf(buf);
        s->bufw = NULL;
    }

    if (s->bufw || !LIST_EMPTY(&s->bufwq)) event_add(&s->evw, NULL);
}

void read_srv(int fd, short ev, void *arg)
{
    struct Sess *s = (struct Sess*)arg;
    if (!read_data(fd, ev, s)) return close_session(s);

    unsigned int pktype, pksize, remain, handle;
    struct Buf *buf = s->bufr;
    struct Buf *newbuf;
    int clid, cmd, a0, a1, flag;
    struct Sess *cli;

    char *old, *cur, *end; 
    cur = buf->h;
    old = cur;
    end = buf->t;

    struct Thread *master = s->master;
    while (end - cur >= 4) {
        pksize = ntohl(*(unsigned int*)cur);
        if (pksize < 4) return close_session(s);
        if (cur + 4 + pksize > end) break;

        clid = ntohl(*(int*)(cur+4));
        if (clid == 0) {
            cmd = ntohl(*(int*)(cur+8));
            LOG("read_srv, cmd = %d, fd = %d", cmd, fd);
            if (cmd == NET_SET_SRV_ID) {
                a0 = ntohl(*(int*)(cur+12));
                newbuf = new_buf(0);
                *(int*)(newbuf->t+0) = cmd;
                *(int*)(newbuf->t+4) = a0;        // client sid
                *(int*)(newbuf->t+8) = s->sid;    // server sid
                newbuf->t += 12;
                newbuf->sid = 0;

                a0 &= 0x0FFFF;
                LIST_ADD_TAIL(&newbuf->link, &master->transQ[ a0 % N_THREAD ]);

            } else if (cmd == NET_CMD_CLOSE) {
                a0 = ntohl(*(int*)(cur+12));
                newbuf = new_buf(0);
                *(int*)(newbuf->t+0) = cmd;
                *(int*)(newbuf->t+4) = a0;
                newbuf->t += 8;
                newbuf->sid = 0;
                LIST_ADD_TAIL(&newbuf->link, &master->transQ[ a0 % N_THREAD ]);

            } else if (cmd == NET_SET_MAP_ID) {
                a0 = ntohl(*(int*)(cur+12));
                s->mid = a0;
                setSidForMap(s->mid, s->sid);
            }
            //todo

        } else {
            // pksize, tosid, pktype, ...
            // pksize, pktype, ...
            // think it just pktype, no value, the pksize = 8
            cli = get_sess(clid);
            if (cli) {
                newbuf = new_buf(pksize);
                *(int*)(newbuf->t) = htonl(pksize - 4);
                memcpy(newbuf->t+4, cur+8, pksize-4);
                newbuf->t += pksize;
                newbuf->sid = clid;
                //todo: if the cli session is the same with the srv session

                LIST_ADD_TAIL(&newbuf->link, &master->transQ[ cli->fd % N_THREAD]);
            }
        }
        cur += (pksize+4);
    }
    s->bufr = handle_read_remain(buf, cur, 0);
}

void on_tick(int fd, short ev, void *arg)
{
    int flag, i, cmd, a0;
    struct Thread *t, *dt;
    char *cur;
    t = (struct Thread*)arg;

    struct Sess *s;
    struct Buf *buf;
    struct list_head q, *pos;
    INIT_LIST_HEAD(&q);

    pthread_mutex_lock(&t->lock);
    LIST_SPLICE_TAIL(&t->sendQ, &q);
    INIT_LIST_HEAD(&t->sendQ);
    pthread_mutex_unlock(&t->lock);

    while (!LIST_EMPTY(&q)) {
        pos = q.next;
        LIST_DEL(pos);
        buf = LIST_ENTRY(pos, struct Buf, link);
        if (buf->sid) {
            s = get_sess(buf->sid);
            if (!s) {
                del_buf(buf);
                continue;
            }

            flag = 0;
            if ( s->bufw || !LIST_EMPTY(&s->bufwq) ) flag = 1;

            int len = buf->t - buf->h;
            assert(len > 0);
            struct Buf *wbuf = get_sess_write_buf(s, len);
            if (!wbuf) {
                LIST_ADD_TAIL(&buf->link, &s->bufwq);
            
            } else {
                memcpy(wbuf->t, buf->h, len);
                wbuf->t += len;
                del_buf(buf);
            }
            if (!flag) event_add(&s->evw, NULL);
        } else {
            cur = buf->h;
            cmd = *(int*)(cur);
            a0 = *(int*)(cur+4);
            switch (cmd) {
                case NET_ADD_LISTEN:
                    s = get_slot(a0);
                    if (s) {
                        s->fd = a0;
                        LOG("do a command, add listen, fd=%d, t->idx=%d", a0, t->idx);
                        s->mode = *(int*)(cur+8);
                        s->encrypt = *(int*)(cur+12);
                        s->sid = *(int*)(cur+16);
                        s->master = t;
                        evconnlistener_new(t->base, cb_accept, s, LEV_OPT_CLOSE_ON_FREE | LEV_OPT_REUSEABLE, 10, s->fd);
                    }
                    break;

                case NET_ADD_INCOME:
                    s = get_slot(a0);
                    if (s) {
                        s->fd = a0;
                        s->sid = makesid(s->fd);
                        s->mode = *(int*)(cur+8);
                        s->encrypt = *(int*)(cur+12);
                        event_assign(&s->evw, t->base, s->fd, EV_WRITE, cb_write, s);
                        LOG("do a command, add income, fd=%d, mode=%d", a0, s->mode);

                        if (s->mode == 1) {
                            s->tm.tv_sec = 5;
                            event_assign(&s->evr, t->base, s->fd, EV_READ|EV_TIMEOUT, read_first_packet, s);
                            event_add(&s->evr, &s->tm);
                        } else {
                            event_assign(&s->evr, t->base, s->fd, EV_READ|EV_PERSIST, read_srv, s);
                            event_add(&s->evr, NULL);
                        }
                        s->master = t;
                    }
                    break;

                case NET_SET_SRV_ID:
                    s = get_sess(a0);
                    if (s) {
                        s->sid2srv = *(int*)(cur+8);
                        LOG("do_command set_srv_id, fd=%d, srvid=%d", s->fd, s->sid2srv & 0x0FFFF );
                        event_del(&s->evr);
                        event_assign(&s->evr, t->base, s->fd, EV_READ|EV_PERSIST, read_cli, s);
                        event_add(&s->evr, NULL);
                    }
                    break;

                case NET_CMD_CLOSE:
                    s = get_sess(a0);
                    if (s) close_session(s);
                    break;

                default:
                    break;
            }
            del_buf(buf);
        }
    }

    for (i = 0; i < N_THREAD; ++i) {
        if (!LIST_EMPTY(&(t->transQ[i]))) {
            dt = &vThread[ i ];
            pthread_mutex_lock(&dt->lock);
            LIST_SPLICE_TAIL(&t->transQ[i], &dt->sendQ);
            pthread_mutex_unlock(&dt->lock);
            INIT_LIST_HEAD(&t->transQ[i]);
        }
    }

    t->tickTm.tv_usec = LOOP_TICK;
    evtimer_add(&t->tickEv, &t->tickTm);
}

void *doNet(void *arg)
{
    int j;
    struct Thread *t = (struct Thread*)arg;
    pthread_mutex_init(&t->lock, NULL);
    t->base = event_base_new();

    INIT_LIST_HEAD(&t->sendQ);
    for (j=0; j < N_THREAD; ++j) INIT_LIST_HEAD(&(t->transQ[j]));

    t->tickTm.tv_sec = 0;
    t->tickTm.tv_usec = LOOP_TICK;
    evtimer_set(&t->tickEv, on_tick, t);
    event_base_set(t->base, &t->tickEv);
    evtimer_add(&t->tickEv, &t->tickTm);
    event_base_dispatch(t->base);

    return NULL;
}


void start_net()
{
    memset(vThread, 0, sizeof(vThread));
    memset(gSess, 0, sizeof(gSess));

    int i,j;
    struct Thread *t;
    for (i = 0; i < N_THREAD; ++i) {
        t = &vThread[ i ];
        t->idx = i;
        pthread_attr_t attr;
        pthread_attr_init(&attr); 
        pthread_create(&t->tid,&attr,doNet,t);
        pthread_attr_destroy(&attr);
    }
}


int start_listen(char *ip, int port, int encrypt, int mode )
{
    struct sockaddr_in sin;
    memset(&sin, 0, sizeof(sin));  
    sin.sin_family = AF_INET;  
    sin.sin_addr.s_addr = inet_addr(ip);
    sin.sin_port = htons(port); 

    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (bind(fd, (struct sockaddr*)&sin, sizeof(sin))) {
        perror("can not bind");
        exit(-1);
    }
    listen(fd, 10);
    LOG("listen %s:%d, fd=%d", ip, port, fd);

    evutil_make_socket_nonblocking(fd);

    int sid = makesid(fd);
    
    struct Buf *buf = new_buf(0);
    char *cur = buf->h;
    *(int*)(cur+0) = NET_ADD_LISTEN;
    *(int*)(cur+4) = fd;
    *(int*)(cur+8) = mode;
    *(int*)(cur+12) = encrypt;
    *(int*)(cur+16) = sid;

    buf->sid = 0;
    struct Thread *t = &vThread[ fd % N_THREAD ];

    pthread_mutex_lock(&t->lock);
    LIST_ADD_TAIL(&buf->link, &t->sendQ);
    pthread_mutex_unlock(&t->lock);

    return sid;
}

int main(int argc, char* argv[])
{
    start_net();
    start_listen("127.0.0.1", 8001, 0, 1);
    start_listen("127.0.0.1", 8002, 0, 2);
    while (1) {
        sleep(1);
    }
    return 0;
}

