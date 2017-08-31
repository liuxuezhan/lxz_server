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
#include <errno.h>

#include "net.h"
#include "mylist.h"
#include "buf.h"
#include "pike.h"
#include "que.h"
#include "log.h"
void notify_read(int fd, short ev, void *arg);

#define LOOP_TICK 10000
#define MAX_SERVER_PACKET_SIZE 0x2000000

#define NET_PING        1
#define NET_PONG        2
#define NET_ADD_LISTEN  3
#define NET_ADD_INCOME  4
#define NET_CMD_CLOSE   5
#define NET_MSG_CLOSE   6 
#define NET_CMD_STOP    7
#define NET_SET_MAP_ID  8
#define NET_SET_SRV_ID  9
#define NET_MSG_CONN_COMP 10 
#define NET_MSG_CONN_FAIL  11
#define NET_ADD_CONNECT  12


static int gSn = 0;
static struct Sess* gSess[0x010000];
static struct event_base *gBase = NULL;
static struct timeval  gTickTm;
static struct event    gTickEv;

static struct list_head gSndBufq;
static pthread_mutex_t  gSndBufqLock;

static struct list_head gRcvBufq;
static struct list_head gRcvBufqTmp;
static pthread_mutex_t  gRcvBufqLock;

enum SessState {STATE_CLOSE, STATE_SEND_SEED, STATE_RECV_SEED, STATE_OK, STATE_CONNECT_PEND};

struct Sess {
    int fd;
    int sid; // session id
    struct Buf *bufr, *bufw;
    struct list_head bufwq;
    int encrypt;
    int tag;  // if tag isn't 0, the tag will send to lua
    int mode;  // if mode isn't 0, the mode will send to lua
    struct event evr, evw;
    Ctx ctxr, ctxw;
    struct timeval tm;
    enum SessState state;
} ;


#define MODE_CONNECT 0
#define MODE_ACCEPT 1


struct Sess* getSessByFd(int fd)
{
    if (fd >= 0 && fd < 0x010000) return gSess[ fd ];
    return NULL;
}

struct Sess* getSessBySid(int sid)
{
    if (sid > 0) {
        struct Sess* s = gSess[ sid & 0x0FFFF ];
        if (s && s->sid == sid) return s;
    }
    return NULL;
}

unsigned int makesid(int fd)
{
    gSn++;
    if (gSn >= 0x08000) gSn = 1;
    return (gSn << 16) + fd;
}


void init(void* p)
{
    gBase = event_base_new();
    memset(gSess, 0, sizeof(gSess));

}

void recv_buf(struct Buf *buf, int sid, int mode)
{
    buf->sid = sid;
    buf->mode = mode;
    LIST_ADD_TAIL(&buf->link, &gRcvBufqTmp);
}

void notify(int sid, int a0, int a1, int a2, int a3)
{
    //LOG("notify, sid=%d, a0=%d", sid, a0);
    struct Buf *buf = new_buf(0);
    char *cur = buf->t;
    *(unsigned int*)(cur) = htonl(16);
    *(unsigned int*)(cur+4) = htonl(a0); 
    *(unsigned int*)(cur+8) = htonl(a1);
    *(unsigned int*)(cur+12) =  htonl(a2);
    *(unsigned int*)(cur+16) = htonl(a3);
    buf->t += 20;
    recv_buf(buf, sid, 1);
}


void doclose_session(struct Sess *s) 
{
    close(s->fd);
    LOG("close_session, fd=%d", s->fd);

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
    s->sid = 0;

    if (s->fd >= 8192) {
        gSess[ s->fd ] = NULL;
        free(s);
    }
}

void close_session(struct Sess *s) 
{
    notify(s->sid, NET_MSG_CLOSE, s->sid, 0, 0);
    event_del(&s->evr);
    if (!LIST_EMPTY(&s->bufwq) || s->bufw) event_del(&s->evw);
    doclose_session(s);
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
        remain = buf->e - buf->t;
        if (remain > size) flag = 1;
    }
    
    if (!flag) {
        buf = new_buf(size);
        LIST_ADD_TAIL(&buf->link, &dsts->bufwq);
    }
    return buf;
}


int read_data(int fd, short ev, struct Sess *s)
{
    if (ev == EV_READ) {
        if (!s->bufr) s->bufr = new_buf(0);
        struct Buf *buf = s->bufr;
        if (buf->e > buf->t) {
            int nRead = recv(fd, buf->t, buf->e - buf->t, 0);
            char tips[16];
            sprintf(tips, "RECV %04d:", fd);
            //dump(buf->t, nRead, tips);
            if (nRead > 0) {
                if (s->encrypt) ctx_encode(&s->ctxr, buf->t, nRead);
                buf->t += nRead;
                return nRead;
            } else {
                LOG("NET_ERROR, nRead=%d, : %d", nRead, __LINE__);
            }
        } else {
            LOG("NET_ERROR: %d", __LINE__);
        }
    }
    return 0;
}


void common_write(int fd, short ev, void *arg)
{
    struct Sess *s = (struct Sess*)arg;
    if (s->state == STATE_SEND_SEED) {
        unsigned int val[2] = {4, s->sid};
        val[0] = htonl(4);
        val[1] = htonl(s->sid);
        if (send(s->fd, (char*)val, 8, 0) != 8)  return close_session(s);
        ctx_init(s->sid, &s->ctxr);
        ctx_init(s->sid, &s->ctxw);
        s->state = STATE_OK;
        if (s->bufw || !LIST_EMPTY(&s->bufwq)) event_add(&s->evw, NULL);
    }

    struct Buf *buf = s->bufw;
    if (!buf) {
        if (!LIST_EMPTY(&s->bufwq)) {
            struct list_head *pos = s->bufwq.next;
            LIST_DEL(pos);
            buf = LIST_ENTRY(pos, struct Buf, link);
            if (s->encrypt) ctx_encode(&s->ctxw, buf->h, buf->t - buf->h);
            s->bufw = buf;
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
        buf->h += len;
    }

    if (need == len) {
        del_buf(buf);
        s->bufw = NULL;
    }

    if (s->bufw || !LIST_EMPTY(&s->bufwq)) event_add(&s->evw, NULL);
}


void common_read(int fd, short ev, void *arg)
{
    struct Sess *s = (struct Sess*)arg;

    if (s->state == STATE_RECV_SEED) {
        int val[2] = {0,};
        int nRead = recv(s->fd, val, 8, 0);
        if (nRead != 8) close_session(s);
        LOG("recv seed  %d", val[1]);
        ctx_init(ntohl(val[1]), &s->ctxr);
        ctx_init(ntohl(val[1]), &s->ctxw);
        s->state = STATE_OK;
        return;
    }

    if (!read_data(fd, ev, s)) return close_session(s);

    unsigned int pktype, pksize, remain;
    struct Buf *buf = s->bufr;
    struct Buf *newbuf = NULL;
    char *cur, *end; 

    cur = buf->h;
    end = buf->t;
    buf->pknum = 0;

    int mode = s->mode;

    if (mode == 2) {
        while (end - cur >= 4) {  // for mongo
            pksize = *(unsigned int*)cur;
            if (pksize < 4) return close_session(s);
            if (cur + pksize > end) break;
            *(unsigned int*)cur = htonl(pksize-4);
            cur += pksize;
            buf->pknum++;
        }
    } else {
        while (end - cur >= 4) {
            pksize = ntohl(*(unsigned int*)cur);
            if (pksize < 4) return close_session(s);
            if (cur + 4 + pksize > end) break;
            cur += (pksize+4);
            buf->pknum++;
        }
    }

    remain = end - cur;
    if (buf->pknum) {
        if (remain > 0) {
            newbuf = new_buf(remain);
            memcpy(newbuf->h, cur, remain);
            newbuf->t += remain;
        } 
        s->bufr = newbuf;
        buf->t = cur;
        //dump(buf->h, cur - buf->h, "recvBuf:");
        recv_buf(buf, s->sid, s->mode);
    } else {
        if (end == buf->e) {
            if (mode != 2) pksize += 4;
            if (pksize < MAX_SERVER_PACKET_SIZE && pksize > buf->e - buf->h) {
                newbuf = new_buf(pksize);
                memcpy(newbuf->h, cur, remain);
                newbuf->t += remain;
                s->bufr = newbuf;
                del_buf(buf);
            } else {
                LOG("NET_ERROR: %d, pkisize=%d, room=%d", __LINE__, pksize, buf->e - buf->h);
            }
        }
    }
}


void on_command(struct Sess *sSrv, char *src, int len)
{
    // the src is : pktype, ...
    int pktype;
    char *cur = src;
    pktype = ntohl(*(int*)(cur));
    
    if (pktype == NET_CMD_CLOSE) {
        // the src is: pktype, clisid
        int sidCli = ntohl(*(int*)(cur+4));
        struct Sess* sCli = getSessBySid(sidCli);
        if (sCli) close_session(sCli);

    } else if (pktype == NET_CMD_STOP) {
        event_base_loopexit(gBase, NULL);

    } else if (pktype == NET_ADD_CONNECT) {
        event_base_loopexit(gBase, NULL);


    } else if (pktype == NET_ADD_INCOME) {
        int sidCli = ntohl(*(int*)(cur+4));
        int isAccept = ntohl(*(int*)(cur+8)); 
        int encrypt = ntohl(*(int*)(cur+12));
        int mode = ntohl(*(int*)(cur+16));

        int fd = sidCli & 0x0FFFF;
        struct Sess *sCli = getSessByFd(fd);
        if (!sCli) {
            sCli = (struct Sess*)calloc(sizeof(struct Sess), 1);
            INIT_LIST_HEAD(&sCli->bufwq);
            gSess[ fd ] = sCli;
        }

        sCli->fd = fd;
        sCli->sid = sidCli;
        sCli->bufr = NULL;
        sCli->bufw = NULL;
        INIT_LIST_HEAD(&sCli->bufwq);
        sCli->encrypt = encrypt;
        sCli->mode = mode;

        event_assign(&sCli->evw, gBase, sCli->fd, EV_WRITE, common_write, sCli);
        event_assign(&sCli->evr, gBase, sCli->fd, EV_READ|EV_PERSIST, common_read, sCli);
        event_add(&sCli->evr, NULL);

        if (sCli->encrypt) {
            if (isAccept) {
                sCli->state = STATE_SEND_SEED;
                event_add(&sCli->evw, NULL);
            } else {
                sCli->state = STATE_RECV_SEED;
            }
        } else {
            sCli->state = STATE_OK;
        }
        notify(sCli->sid, NET_MSG_CONN_COMP, sCli->sid, 0, 0);
    } 
}


void accept_callback(struct evconnlistener *lsn, evutil_socket_t client_fd, struct sockaddr* addr, int addrlen,  void *arg)
{
    struct Sess *sSrv = (struct Sess*)arg;
    //struct Sess *sCli = getSessByFd(client_fd);
    //if (!sCli) {
    //    sCli = (struct Sess*)calloc(sizeof(struct Sess), 1);
    //    INIT_LIST_HEAD(&sCli->bufwq);
    //    gSess[ client_fd ] = sCli;
    //} 
    //sCli->fd = client_fd;
    //sCli->sid = makesid(client_fd);
    //sCli->bufr = NULL;
    //sCli->bufw = NULL;
    //INIT_LIST_HEAD(&sCli->bufwq);
    //sCli->encrypt = sSrv->encrypt;

    //LOG("income, fd=%d, encrypt=%d, sid=%d, %s\n", client_fd, sCli->encrypt, sCli->sid, inet_ntoa(((struct sockaddr_in*)addr)->sin_addr));

    //if (sSrv->encrypt) {
    //    unsigned int val[2] = {4, sCli->sid};
    //    if (send(client_fd, (char*)val, 8, 0) != 8) {
    //        LOG("send seed %d", sCli->sid);
    //        return;
    //    }
    //}

    //event_assign(&sCli->evw, gBase, client_fd, EV_WRITE, common_write, sCli);
    //event_assign(&sCli->evr, gBase, client_fd, EV_READ|EV_PERSIST, common_read, sCli);
    //event_add(&sCli->evr, NULL);

    evutil_make_socket_nonblocking(client_fd);
    unsigned int sid = makesid(client_fd);
    send_command(NET_ADD_INCOME, sid, MODE_ACCEPT, sSrv->encrypt, 0);

}


int start_listen(int port, int encrypt)
{
    struct sockaddr_in sin;
    memset(&sin, 0, sizeof(sin));  
    sin.sin_family = AF_INET;  
    sin.sin_addr.s_addr = htonl(0);  
    sin.sin_port = htons(port); 

    struct evconnlistener *lsn;
    lsn = evconnlistener_new_bind(gBase, NULL, NULL, LEV_OPT_CLOSE_ON_FREE| LEV_OPT_REUSEABLE, -1,  (struct sockaddr*)&sin, sizeof(sin));  
    if(!lsn)  {  
        perror("could't not create listener");  
        return -1;  
    }  

    int fd = evconnlistener_get_fd(lsn);
    struct Sess *s = getSessByFd(fd);
    if (!s) {
        s = (struct Sess*)calloc(sizeof(struct Sess), 1);
        INIT_LIST_HEAD(&s->bufwq);
        gSess[ fd ] = s;
    }

    s->encrypt = encrypt;
    s->fd = fd;
    s->sid = makesid(s->fd);
    LOG("listen fd=%d", fd);

    evconnlistener_set_cb(lsn, accept_callback, s);
    evconnlistener_enable(lsn);
    return s->sid;
    
}


void on_tick(int fd, short ev, void *arg)
{
    if (!LIST_EMPTY(&gRcvBufqTmp)) {
        pthread_mutex_lock(&gRcvBufqLock);
        LIST_SPLICE_TAIL(&gRcvBufqTmp, &gRcvBufq);
        pthread_mutex_unlock(&gRcvBufqLock);
        INIT_LIST_HEAD(&gRcvBufqTmp);
    }

    if (!LIST_EMPTY(&gSndBufq)) {
        struct list_head q;
        INIT_LIST_HEAD(&q);

        pthread_mutex_lock(&gSndBufqLock);
        LIST_SPLICE_TAIL(&gSndBufq, &q);
        INIT_LIST_HEAD(&gSndBufq);
        pthread_mutex_unlock(&gSndBufqLock);
    
        struct list_head *pos, *nouse;
        struct Buf *buf;
        struct Sess *s;
        LIST_FOR_EACH_SAFE(pos, nouse, &q) {
            buf = LIST_ENTRY(pos, struct Buf, link);
            s = getSessBySid(buf->sid);
            if (s) {
                if (s->bufw == NULL && LIST_EMPTY(&s->bufwq)) event_add(&s->evw, NULL);
                LIST_ADD_TAIL(&buf->link, &s->bufwq);
            } else {
                if (buf->sid == 0) on_command(s, buf->h+4, buf->t - buf->h - 4);
                del_buf(buf);
            }
        }
    }

    gTickTm.tv_sec = 0;
    gTickTm.tv_usec = LOOP_TICK;
    evtimer_add(&gTickEv, &gTickTm);
    //setTime();
}

int recv_bufq(struct list_head *q)
{
   if (!LIST_EMPTY(&gRcvBufq)) {
        pthread_mutex_lock(&gRcvBufqLock);
        LIST_SPLICE_TAIL(&gRcvBufq, q);
        INIT_LIST_HEAD(&gRcvBufq);
        pthread_mutex_unlock(&gRcvBufqLock);
        return 1;
    }
    return 0;
}


void send_bufq(struct list_head *q)
{
    pthread_mutex_lock(&gSndBufqLock);
    LIST_SPLICE_TAIL(q, &gSndBufq);
    INIT_LIST_HEAD(q);
    pthread_mutex_unlock(&gSndBufqLock);
}

void send_buf(struct Buf* buf, int sid)
{
    buf->sid = sid;
    pthread_mutex_lock(&gSndBufqLock);
    LIST_ADD_TAIL(&buf->link, &gSndBufq);
    pthread_mutex_unlock(&gSndBufqLock);
}


void send_command(int pt, int a0, int a1, int a2, int a3)
{
    struct Buf *buf = new_buf(0);
    char *cur = buf->t;
    *(unsigned int*)(cur) = htonl(20);
    *(unsigned int*)(cur+4) = htonl(pt);
    *(unsigned int*)(cur+8) =  htonl(a0);
    *(unsigned int*)(cur+12) = htonl(a1);
    *(unsigned int*)(cur+16) = htonl(a2);
    *(unsigned int*)(cur+20) = htonl(a3);
    buf->t += 24;
    send_buf(buf, 0);
}


void disconnect(int sid) 
{
    send_command(NET_CMD_CLOSE, sid, 0, 0, 0);
}


int init_net()
{
    if (gBase) return -1;
    //setTime();
    INIT_LIST_HEAD(&gRcvBufqTmp);
    INIT_LIST_HEAD(&gRcvBufq);
    INIT_LIST_HEAD(&gSndBufq);

    pthread_mutex_init(&gRcvBufqLock, NULL);
    pthread_mutex_init(&gSndBufqLock, NULL);

    gBase = event_base_new();

    return 0;
}


int start_tick()
{
    if (!gBase) return -1;
    gTickTm.tv_sec = 0;
    gTickTm.tv_usec = LOOP_TICK;
    evtimer_set(&gTickEv, on_tick, 0);
    event_base_set(gBase, &gTickEv);
    evtimer_add(&gTickEv, &gTickTm);
    return 0;
}

void *doNet(void *arg)
{
    event_base_dispatch(gBase);


    return NULL;
}

typedef struct {
    in_addr_t ip;
    int port, sid, fd, encrypt, mode;
    struct list_head link;
} ConnectInfo;

Que gConnectQue;


void *connecter(void *arg)
{
    ConnectInfo *info = NULL;
    QueInit( &gConnectQue );
    struct sockaddr_in addr;
    struct list_head *pos; 
    int fd;
    struct timeval tm;
    fd_set wset, eset;
    while ( pos = QueGet( &gConnectQue ) ) {
        info = LIST_ENTRY( pos, ConnectInfo, link );
        if ( info->fd == 0 ) {
            free( info );
            return NULL;
        }

        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_port = htons(info->port);
        addr.sin_addr.s_addr = info->ip;

        fd = info->fd;
        int rt = connect(info->fd, (struct sockaddr *)&addr, sizeof(addr));
        if ( rt == 0 ) {
            int flags = fcntl(fd, F_GETFL, 0);
            fcntl(fd, F_SETFL, flags|O_NONBLOCK);
            send_command(NET_ADD_INCOME, info->sid, MODE_CONNECT, info->encrypt, info->mode);
            free( info );
            continue;
        }

        notify(info->sid, NET_MSG_CONN_FAIL, info->sid, 0, 0);
        free( info );
    }
}

int connect_to(const char *ip, int port, int encrypt, int mode)
{
    ConnectInfo *info = ( ConnectInfo* )calloc( sizeof(ConnectInfo), 1 );
    if ( !info ) return 0;

    int fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP); 
    if ( fd <= 0 ) return 0;

    info->ip = inet_addr( ip );
    info->port = port;
    info->sid = makesid( fd );
    info->fd = fd;
    info->encrypt = encrypt;
    info->mode = mode;

    QuePut( &gConnectQue, &info->link );
    return info->sid;
}


pthread_t start_net()
{
    pthread_t tid; 
    pthread_attr_t attr;
    pthread_attr_init(&attr); 
    pthread_create(&tid,&attr,doNet,NULL);
    pthread_attr_destroy(&attr);

    pthread_attr_init(&attr); 
    pthread_create(&tid,&attr,connecter,NULL);
    pthread_attr_destroy(&attr);

    return tid;
}

