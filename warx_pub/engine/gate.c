
// NOTICE !!!
// packet should recv from format LEN, TO, PKTYPE, ...
// packet should send after make format LEN, FROM, PKTYPE, ...

#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/types.h>          /* See NOTES */
#include <sys/socket.h>
#include <sys/epoll.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <string.h>
#include "mylist.h"
#include "pike.h"
#include "buf.h"
#include "que.h"
#include "log.h"

int gOn = 1;
int gIsGate = 1;
Que exchange_msg;
int gSidRouter = 0;
extern unsigned int gBufCount;

#define HASH_SIZE 0x010000
#define HASH_MARK 0x00FFFF

#define MAX_THREAD 16
#define THREAD_MARK 0x0F

#define NET_ECHO 12

#define NET_P2P         1612229045
#define NET_P2PS        215171762
#define NET_LOGIN       1233071922
#define NET_SET_MAP_ID  8
#define NET_SET_SRV_ID  9
#define NET_SNAPSHOT    17
#define NET_FIRST_PACKET    1122052733
#define NET_ROUTER      1276860164
#define NET_SIGNIN      999243419
#define NET_SIGNOUT     1378554184

#define NET_SEND_MUL    15

#define MAX_CLIENT_PACKET_SIZE 0x04000

enum {STATE_NULL, STATE_NEW, STATE_SHAKE, STATE_ON, STATE_BREAK};
enum {MODE_NULL=0, MODE_CLI_LISTEN, MODE_SRV_LISTEN, MODE_CLI, MODE_SRV, MODE_ROUTER, MODE_SIGNAL, MODE_MAX};
enum {CMD_LISTEN, CMD_CONNECT, CMD_SIGNIN, CMD_SIGNOUT, CMD_INCOME_CLI, CMD_INCOME_SRV, CMD_SEND_ALL, CMD_SEND_MUL};


typedef struct {
    struct list_head qw;
    pthread_mutex_t qwl;
    int nw;
    int sockw;
    int epfd;
} Thread;

typedef struct {
    int sid;
    int fd;
    int pid; // server is also a player, pid < 10000
    int map;
    int state, mode;
    struct Buf *bufr, *bufw;
    struct list_head bufwq;
    struct epoll_event ev;
    Ctx *ctxw, *ctxr;
} Sess;

typedef int (*FUNC_R)(Sess *, struct list_head *, int);

typedef struct {
    struct list_head link;
    int key, val;
} Node;


#if 0

#define DEL_BUF(buf) \
    del_buf_mark(buf, __LINE__, __FILE__); \


#define NEW_BUF(size) \
    new_buf_mark( size, __LINE__, __FILE__); \

#else

#define DEL_BUF(buf) \
    del_buf(buf); \

#define NEW_BUF(size) \
    new_buf( size ); \

#endif

long volatile g_nthread = 0;
Sess vSess[ HASH_SIZE ];
Thread vThread[MAX_THREAD];
struct list_head vPid2Sid[ HASH_SIZE ];

Sess *get_sess(int sid)
{
    Sess *s = &vSess[ sid & HASH_MARK ];
    if ( s->sid == sid ) return s;
    return NULL;
}


struct Buf *make_cmd(int cmd, int sid, int d1, int d2, int d3, int d4)
{
    struct Buf *buf = NEW_BUF(0);
    char *cur = buf->h;
    *(unsigned int*)cur = cmd; cur+=4;
    *(unsigned int*)cur = sid; cur+=4;
    *(unsigned int*)cur = d1; cur+=4;
    *(unsigned int*)cur = d2; cur+=4;
    *(unsigned int*)cur = d3; cur+=4;
    *(unsigned int*)cur = d4; cur+=4;
    buf->t = cur;
    buf->sid = 0;
    return buf;
}

int break_sess( Sess *s, struct list_head *msgq, int epfd )
{
    //s->ev.events = 0;
    s->state = STATE_BREAK;
    epoll_ctl(epfd, EPOLL_CTL_DEL, s->fd, &s->ev);

    struct Buf *tbuf = make_cmd(CMD_SIGNOUT, s->sid, s->pid, 0, 0, 0);
    LIST_ADD_TAIL( &tbuf->link, msgq );
    return -1;
}

void close_sess( Sess *s )
{
    struct list_head *pos;
    struct Buf *buf;
    printf( "CLOSE, fd=%d, sid=0x%08x, mode=%d\n", s->fd, s->sid, s->mode );

    close( s->fd );
    if ( s->bufr ) DEL_BUF( s->bufr );
    if ( s->bufw ) DEL_BUF( s->bufw );
    if ( s->ctxr ) free( s->ctxr );
    if ( s->ctxw ) free( s->ctxw );

    while ( !LIST_EMPTY( &s->bufwq ) ) {
        pos = s->bufwq.next;
        LIST_DEL(pos);
        buf = LIST_ENTRY( pos, struct Buf, link );
        DEL_BUF( buf );
    }

    memset( s, 0, sizeof(Sess) );
    INIT_LIST_HEAD( &s->bufwq );
}

int start_listen( int port, int mode )
{
    struct sockaddr_in sin;
    memset(&sin, 0, sizeof(sin));  
    sin.sin_family = AF_INET;  
    sin.sin_addr.s_addr = htonl(0);  
    sin.sin_port = htons(port); 

    int fd = socket(AF_INET, SOCK_STREAM, 0);
    int flags = fcntl(fd, F_GETFL, 0);
    fcntl(fd, F_SETFL, flags|O_NONBLOCK);

    int reuse = 1;
    setsockopt( fd, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse) );

    bind( fd, (struct sockaddr *)&sin, sizeof( sin ) );

    struct Buf *buf = make_cmd(CMD_LISTEN, fd, mode, 0, 0, 0);
    buf->sid = 0;
    QuePut( &exchange_msg, &buf->link );

    printf("listen, fd=%d, port=%d\n", fd, port);
}

int start_connect( const char *ip, int port, int mode )
{
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons( port );
    addr.sin_addr.s_addr = inet_addr( ip );

    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if ( !connect( fd, (struct sockaddr *)&addr, sizeof(addr)) ) {
        int flags = fcntl(fd, F_GETFL, 0);
        fcntl(fd, F_SETFL, flags|O_NONBLOCK);
        struct Buf *buf = make_cmd( CMD_CONNECT, fd, mode, 0, 0, 0 );
        QuePut( &exchange_msg, &buf->link );

    } else {
        char tips[32];
        snprintf( tips, sizeof(tips), "connect %s:%d error", ip, port );
        perror( tips );
        return 0;
    }
}

int onR_null(Sess *s, struct list_head *msgq, int epfd)
{
    // todo
    printf("sid = %d, onR_null\n", s->sid);
    return -1;
}

int onAccept_cli(Sess *s, struct list_head *msgq, int epfd)
{
    struct sockaddr_in addr;
    socklen_t len = sizeof( addr );
    int fd = accept( s->fd, (struct sockaddr *)&addr, &len);
    if (fd > 0) {
        printf( "income_cli, fd = %d\n", fd );
        struct Buf *buf = make_cmd(CMD_INCOME_CLI, fd, 0, 0, 0, 0);
        LIST_ADD_TAIL( &buf->link, msgq );
    }
    return 0;
}


int onAccept_srv(Sess *s, struct list_head *msgq, int epfd)
{
    struct sockaddr_in addr;
    socklen_t len = sizeof( addr );
    int fd = accept( s->fd, (struct sockaddr *)&addr, &len);
    if (fd > 0) {
        printf( "income_srv, fd = %d\n", fd );
        struct Buf *buf = make_cmd(CMD_INCOME_SRV, fd, 0, 0, 0, 0);
        LIST_ADD_TAIL( &buf->link, msgq );
    }
    return 0;
}

int onRead_cli(Sess *s, struct list_head *msgq, int epfd)
{
    char *cur, *end;
    int pktype, pksize, remain, len, map;
    char *p;

    struct Buf *buf = s->bufr;
    struct Buf *tbuf;

    if (!buf) { 
        buf = NEW_BUF(0); 
        s->bufr = buf; 
    }
    len = recv(s->fd, buf->t, buf->e - buf->t, 0);

    if (len <= 0) {
        return break_sess( s, msgq, epfd );

    } else {
        if ( !s->ctxr ) {
            //s->ctxr = calloc(sizeof(Ctx), 1);
            //s->ctxw = calloc(sizeof(Ctx), 1);
            //ctx_init(s->sid, s->ctxr);
            //ctx_init(s->sid, s->ctxw);
            //ctx_encode(s->ctxr, buf->t, len);
            //printf("set seed = %d\n", s->sid);
        }

        buf->t += len;
        cur = buf->h;
        end = buf->t;

        if ( !s->pid ) {
            // todo
            pksize = ntohl(*(unsigned int*)cur);
            if ( pksize < 4 ) return break_sess( s, msgq, epfd );
            if ( pksize > 4096 ) return break_sess( s, msgq, epfd );
            if ( cur + 4 + pksize != end ) return break_sess( s, msgq, epfd );

            //printf( "onRead_cli, pksize = %d\n", pksize );

            pktype = ntohl( *(unsigned int*)(cur+4) );
            if ( pktype != NET_FIRST_PACKET ) return break_sess( s, msgq, epfd );

            // len, 0, pktype, sid, ...
            tbuf = NEW_BUF( 0 );

            p = tbuf->t;
            *(unsigned int*)(p) = htonl( pksize + 4 ); p += 4;
            *(unsigned int*)(p) = htonl( 0 ); p += 4;
            memcpy( p, cur + 4, pksize ); p += pksize;
            tbuf->t = p;
            *( unsigned int* )( tbuf->h + 12 ) = htonl( s->sid );
            map = ntohl( *( unsigned int* )( buf->h + 8 ) );

            tbuf->sid = map;
            LIST_ADD_TAIL( &tbuf->link, msgq );
            DEL_BUF( buf );
            s->bufr = NULL;
            return 0;
        }

        while (end - cur >= 4) {
            pksize = ntohl(*(unsigned int*)cur);
            if ( pksize < 4 ) return break_sess( s, msgq, epfd );

            if ( cur + 4 + pksize > end ) break;

            pktype = ntohl( *(unsigned int*)(cur+4) );
            if (pktype == NET_ECHO) {
                if ( !(s->ev.events & EPOLLOUT) ) {
                    s->ev.events |= EPOLLOUT;
                    epoll_ctl(epfd, EPOLL_CTL_MOD, s->fd, &s->ev);
                }

                tbuf = NEW_BUF( pksize+4 );

                memcpy( tbuf->t, cur, pksize + 4 );
                tbuf->t += ( pksize + 4 );
                LIST_ADD_TAIL( &tbuf->link, &s->bufwq );

            } else if ( pktype == NET_P2P ) {
                //todo
            } else if ( pktype == NET_FIRST_PACKET ) {
                return break_sess( s, msgq, epfd );

            
            } else {

                tbuf = NEW_BUF( pksize + 8 );

                p = tbuf->t;
                *(unsigned int*)(p) = htonl( pksize + 4 ); p += 4;
                *(unsigned int*)(p) = htonl( s->pid ); p += 4;
                memcpy( p, cur+4, pksize ); p += pksize;
                tbuf->t = p;
                tbuf->sid = s->map;
                LIST_ADD_TAIL( &tbuf->link, msgq );
            } 
            cur += ( 4 + pksize );
        }

        remain = end - cur;
        if ( !remain ) {
            // todo
            //buf->t = buf->h;
            DEL_BUF( buf );
            s->bufr = NULL;
        } else {
            if ( cur == buf->h ) {
                if (buf->e == buf->t) {
                    s->bufr = NULL;
                    tbuf = NEW_BUF(pksize+4);

                    if (tbuf) {
                        memcpy(tbuf->h, cur, remain);
                        tbuf->t = tbuf->h + remain;
                        s->bufr = tbuf;
                    }
                    DEL_BUF(buf);
                }
            } else {
                memmove( buf->h, cur, remain);
                buf->t = buf->h + remain;
            }
        }
    }
}


int onRead_srv(Sess *s, struct list_head *msgq, int epfd)
{
    char *cur, *end, *p;
    int pktype, pksize, sid, pid, num, remain, map;

    struct Buf *buf = s->bufr;
    struct Buf *tbuf;

    if (!buf) { 
        buf = NEW_BUF(0); 
        s->bufr = buf; 
    }
    int len = recv(s->fd, buf->t, buf->e - buf->t, 0);

    if (len <= 0) {
        return break_sess( s, msgq, epfd );

    } else {
        buf->t += len;
        cur = buf->h;
        end = buf->t;
        num = 0;
        while (end - cur >= 4) {
            pksize = ntohl(*(unsigned int*)cur);
            if ( pksize < 4 ) return break_sess( s, msgq, epfd );
            if ( cur + 4 + pksize > end ) break;
            //printf( "onRead_srv, pksize = %d\n", pksize );

            pid = ntohl( *(int*)(cur+4) );
            if (pid > 0) {
                pktype = ntohl(*(unsigned int*)(cur+8));
                if ( pktype == NET_SNAPSHOT ) {
                    tbuf = NEW_BUF( pksize - 8 ); 

                    memcpy( tbuf->t, cur + 12, pksize - 8 );
                    tbuf->t = tbuf->h + pksize - 8;
                    tbuf->sid = pid;
                    LIST_ADD_TAIL( &tbuf->link, msgq);

                } else {
                    tbuf = NEW_BUF( pksize );
                    p = tbuf->h;
                    *( unsigned int* )p = htonl( pksize - 4 ); p += 4;
                    memcpy( p, cur + 8, pksize - 4 ); p += ( pksize - 4 );
                    tbuf->t = p;
                    tbuf->sid = pid;
                    LIST_ADD_TAIL( &tbuf->link, msgq);

                }

            } else if ( pid == 0 ) {
                pktype = ntohl( *(unsigned int*)(cur+8) );
                if ( pktype == NET_SET_MAP_ID ) {
                    map = ntohl( *(unsigned int*)(cur+12) );
                    s->map = map;
                    tbuf = make_cmd(CMD_SIGNIN, s->sid, map, 0, 0, 0);
                    LIST_ADD_TAIL( &tbuf->link, msgq);

                } else if ( pktype == NET_SET_SRV_ID ) {
                    sid = ntohl( *(unsigned int*)(cur+12) );
                    map = ntohl( *(unsigned int*)(cur+16) );
                    pid = ntohl( *(unsigned int*)(cur+20) );
                    tbuf = make_cmd(CMD_SIGNIN, sid, pid, map, 0, 0);
                    LIST_ADD_TAIL( &tbuf->link, msgq);
                    printf( "set_srv_id, sid=%d, fd=%d, map=%d, pid=%d\n", sid, sid % HASH_SIZE, map, pid );

                } else if ( pktype == NET_SEND_MUL ) {
                    // pksize, 0, sendMul, count, ...
                    //            CMD_MUL, count, 
                    tbuf = NEW_BUF( pksize - 4 );
                    p = tbuf->h;
                    *( unsigned int* )p = CMD_SEND_MUL; p += 4;
                    memcpy( p, cur + 12, pksize - 8 ); p += ( pksize - 8 );
                    tbuf->t = p;
                    LIST_ADD_TAIL( &tbuf->link, msgq);

                } else {
                    printf( "not handle, pid=0, pktype = %d\n", pktype );
                }

            } else if ( pid < 0 ) {
                tbuf = NEW_BUF( pksize + 4 );
                p = tbuf->h;
                *( unsigned int* )p = CMD_SEND_ALL; p += 4;
                *( unsigned int* )p = s->map; p += 4;

                *( unsigned int* )p = htonl( pksize - 4 ); p += 4;
                memcpy( p, cur + 8, pksize - 4 );
                p += ( pksize - 4 );
                tbuf->t = p;
                LIST_ADD_TAIL( &tbuf->link, msgq);

                //printf( "send all, map=%d, size=%d\n", s->map, pksize );
            }
            cur += ( pksize + 4 );
        }
        remain = end - cur;
        if ( !remain ) {
            //todo
            //buf->t = buf->h;
            DEL_BUF( buf );
            s->bufr = NULL;

        } else {
            if ( cur == buf->h ) {
                if (buf->e == buf->t) {
                    s->bufr = NULL;
                    tbuf = NEW_BUF(pksize+4);

                    if (tbuf) {
                        memcpy(tbuf->h, cur, remain);
                        tbuf->t = tbuf->h + remain;
                        s->bufr = tbuf;
                    }
                    DEL_BUF(buf);
                }
            } else {
                memmove( buf->h, cur, remain);
                buf->t = buf->h + remain;
            }
        }
    }
}

int onRead_trans_router(Sess *s, struct list_head *msgq, int epfd)
{
    // Len, To, NET_ROUTER, From, REAL_PACKET, 
    // Len, Pid, NET_SIGNIN,
    // Len, Pid, NET_SIGNOUT,
    char *cur, *end, *p;
    int pktype, pksize, sid, pid, num, remain, map;
    int from, to;

    struct Buf *buf = s->bufr;
    struct Buf *tbuf;

    if (!buf) { 
        buf = NEW_BUF(0); 
        s->bufr = buf; 
    }
    int len = recv(s->fd, buf->t, buf->e - buf->t, 0);

    if (len <= 0) {
        return break_sess( s, msgq, epfd );

    } else {
        buf->t += len;
        cur = buf->h;
        end = buf->t;
        num = 0;
        while (end - cur >= 4) {
            pksize = ntohl(*(unsigned int*)cur);
            if ( pksize < 4 ) return break_sess( s, msgq, epfd );
            if ( cur + 4 + pksize > end ) break;

            to = ntohl(*(unsigned int*)(cur+4));
            pktype = ntohl(*(unsigned int*)(cur+8));
            if ( pktype == NET_ROUTER ) {
                tbuf = NEW_BUF( pksize + 4 );
                memcpy( tbuf->h, cur, pksize + 4 );
                tbuf->t += ( pksize + 4 );
                tbuf->sid = to;
                LIST_ADD_TAIL( &tbuf->link, msgq);
            
            } else if ( pktype == NET_SIGNIN ) {
                tbuf = make_cmd(CMD_SIGNIN, s->sid, to, 0, 0, 0);
                LIST_ADD_TAIL( &tbuf->link, msgq);

            } else if ( pktype == NET_SIGNOUT ) {
                tbuf = make_cmd(CMD_SIGNOUT, s->sid, to, 0, 0, 0);
                LIST_ADD_TAIL( &tbuf->link, msgq);
            }
            cur += ( pksize + 4 );
        }

    }
}


int onRead_trans_gate(Sess *s, struct list_head *msgq, int epfd)
{}


FUNC_R onRead_funcs[ MODE_MAX ] = { onR_null, onAccept_cli, onAccept_srv, onRead_cli, onRead_srv, onRead_trans_gate };

int make_sid(int fd)
{
    static int sn = 0;
    sn++;
    if (sn >= 0x080000000 ) sn = 1;
    return (sn << 16) + fd;
}

void do_cmd(struct Buf *buf, int epfd, struct list_head *msgq)
{
    int cmd, sid, map, pid, mid, fd, mode, flags;
    Sess *sess;
    char *cur;
    struct Buf *tbuf;
    cmd = *(unsigned int*)(buf->h);
    sid = *(unsigned int*)(buf->h+4);
    switch (cmd) {
        case CMD_INCOME_CLI:
            printf("do_cmd, income_cli\n");
            sess = &vSess[ sid ];
            if (sess) {
                flags = fcntl(sid, F_GETFL, 0);
                fcntl(sid, F_SETFL, flags|O_NONBLOCK);

                sess->fd = sid;
                sess->state = STATE_SHAKE;
                sess->mode = MODE_CLI;
                sess->sid = make_sid( sid );
                sess->ev.events = EPOLLOUT;
                sess->ev.data.fd = sid;
                epoll_ctl(epfd, EPOLL_CTL_ADD, sess->fd, &sess->ev);
            }
            break;

        case CMD_INCOME_SRV:
            sess = &vSess[ sid ];
            if (sess) {
                flags = fcntl(sid, F_GETFL, 0);
                fcntl(sid, F_SETFL, flags|O_NONBLOCK);

                sess->fd = sid;
                sess->state = STATE_ON;
                sess->mode = MODE_SRV;
                sess->sid = make_sid( sid );
                sess->ev.events = EPOLLIN;
                sess->ev.data.fd = sid;
                epoll_ctl(epfd, EPOLL_CTL_ADD, sess->fd, &sess->ev);
            }
            break;

        case CMD_SIGNIN:
            // just client will go here
            sid = *(unsigned int*)(buf->h+4);
            sess = get_sess(sid);
            if (sess) {
                sess->state = STATE_ON;
                sess->ev.events = EPOLLIN;
                epoll_ctl(epfd, EPOLL_CTL_MOD, sess->fd, &sess->ev);

                tbuf = NEW_BUF(0);

                cur = tbuf->t;
                *(unsigned int*)cur = htonl(12); cur += 4;
                *(unsigned int*)cur = htonl(sess->pid); cur += 4;
                *(unsigned int*)cur = htonl(NET_LOGIN); cur += 4;
                *(unsigned int*)cur = htonl(sess->pid); cur += 4;
                tbuf->t = cur;
                tbuf->sid = sess->map;
                LIST_ADD_TAIL( &tbuf->link, msgq );
                printf( "send login, pid = %d, map = %d\n", sess->pid, sess->map );
            }
            break;

        case CMD_LISTEN:
            sess = &vSess[ sid ];
            if (sess) {
                sess->fd = sid;
                sess->state = STATE_ON;
                sess->sid = make_sid( sid );
                sess->ev.events = EPOLLIN;
                sess->ev.data.fd = sid;
                epoll_ctl(epfd, EPOLL_CTL_ADD, sess->fd, &sess->ev);

                mode = *(unsigned int*)(buf->h+8);
                if ( mode == MODE_CLI ) sess->mode = MODE_CLI_LISTEN;
                else sess->mode = MODE_SRV_LISTEN;

                listen( sess->fd, 1024 );
            }
            break;

        case CMD_CONNECT:
            if (sess) {
                sess->fd = sid;
                sess->state = STATE_ON;
                sess->mode = MODE_ROUTER;
                sess->sid = make_sid( sid );
                sess->ev.events = EPOLLIN;
                sess->ev.data.fd = sid;
                epoll_ctl(epfd, EPOLL_CTL_ADD, sess->fd, &sess->ev);

                mode = *(unsigned int*)(buf->h+8);
                sess->mode = mode;
            }

    }
    DEL_BUF(buf);
}

void* loop(void* arg)
{
    long idx = (long)arg;
    Thread *thread = &vThread[ idx ];
    INIT_LIST_HEAD( &thread->qw );
    pthread_mutex_init( &thread->qwl, NULL );

    Sess *sess;
    int epfd = epoll_create( HASH_SIZE );
    thread->epfd = epfd;

    int pfd[ 2 ] = { 0, };
    if ( pipe( pfd ) ) { perror( "pipe" ); exit(-1); }

    thread->sockw = pfd[ 1 ];
    int rfd = pfd[ 0 ];
    sess = &vSess[ rfd ];
    sess->fd = rfd;
    sess->mode = MODE_SIGNAL;
    sess->ev.data.fd = rfd;
    sess->ev.events = EPOLLIN;
    epoll_ctl(epfd, EPOLL_CTL_ADD, sess->fd, &sess->ev);

    __sync_fetch_and_add(&g_nthread, 1);

    struct epoll_event events[1024];
    int nfds, i, fd, cmd, len, count;
    struct Buf *buf, *tbuf;
    long sig;
    char *cur;
    char sigs[ 128 ];

    struct list_head *pos;
    struct list_head msgSend, msgRecv;

    while (gOn) {
        INIT_LIST_HEAD(&msgSend);
        INIT_LIST_HEAD(&msgRecv);
        nfds = epoll_wait(epfd, events, 1024, -1);
        for (i = 0; i < nfds; ++i) {
            fd = events[ i ].data.fd;
            Sess *s = &vSess[ fd ];
            if(events[i].events & EPOLLIN) {
                if (s->mode == MODE_SIGNAL) {
                    read( fd, sigs, sizeof(sigs) );

                    pthread_mutex_lock(&thread->qwl);
                    LIST_SPLICE_TAIL(&thread->qw, &msgSend);
                    thread->nw = 0;
                    INIT_LIST_HEAD( &thread->qw );
                    pthread_mutex_unlock(&thread->qwl);

                    while ( !LIST_EMPTY(&msgSend) ) {
                        pos = msgSend.next;
                        LIST_DEL(pos);
                        buf = LIST_ENTRY(pos, struct Buf, link);
                        if (buf->sid) {
                            sess = &vSess[ buf->sid & 0x0FFFF ];
                            if (sess->sid == buf->sid) {
                                if ( !(sess->ev.events & EPOLLOUT) ) {
                                    sess->ev.events |= EPOLLOUT;
                                    epoll_ctl(epfd, EPOLL_CTL_MOD, sess->fd, &sess->ev);
                                }
                                LIST_ADD_TAIL(&buf->link, &sess->bufwq);
                            } else {
                                DEL_BUF(buf);
                            }
                        } else {
                            do_cmd(buf, epfd, &msgRecv);
                        }
                    }
                } else {
                    onRead_funcs[ s->mode ]( s, &msgRecv, epfd );
                }

            } else if (events[i].events & EPOLLOUT) {
                if (s->state == STATE_SHAKE) {
                    char seed[12] = {0,};
                    cur = seed;
                    *(unsigned int*)cur = htonl(8); cur += 4;
                    *(unsigned int*)cur = htonl(0); cur += 4;
                    *(unsigned int*)cur = htonl(s->sid); cur += 4;
                    //printf("seed = %d\n", s->sid);
                    //send(s->fd, seed, 8, 0);
                    s->state = STATE_ON;
                    s->ev.events = EPOLLIN;
                    epoll_ctl(epfd, EPOLL_CTL_MOD, s->fd, &s->ev);

                } else {
                    if ( !s->bufw && !LIST_EMPTY( &s->bufwq ) ) {
                        pos = s->bufwq.next;
                        LIST_DEL( pos );
                        buf = LIST_ENTRY(pos, struct Buf, link);
                        while ( !LIST_EMPTY( &s->bufwq ) ) {
                            pos = s->bufwq.next;
                            tbuf = LIST_ENTRY(pos, struct Buf, link);
                            if (buf->e - buf->t > tbuf->t - tbuf->h) {
                                LIST_DEL(pos);
                                len = tbuf->t - tbuf->h;
                                memcpy(buf->t, tbuf->h, len);
                                buf->t += len;
                                DEL_BUF( tbuf );
                            } else {
                                break;
                            }
                        }
                        s->bufw = buf;
                        if ( s->mode == MODE_CLI ) {
                            //ctx_encode( s->ctxw, buf->h, buf->t - buf->h );
                        }
                    }

                    buf = s->bufw;
                    if (buf) {
                        len = send(s->fd, buf->h, buf->t - buf->h, 0);
                        buf->h += len;
                        if (buf->h >= buf->t) {
                            s->bufw = NULL;
                            DEL_BUF(buf);

                            if ( LIST_EMPTY( &s->bufwq ) ) {
                                s->ev.events = EPOLLIN;
                                epoll_ctl(epfd, EPOLL_CTL_MOD, s->fd, &s->ev);
                            }
                        }
                    }
                }
            }
        }
        QuePutAll( &exchange_msg, &msgRecv );
    }
}



int sid_from_pid(int pid)
{
    int idx = pid & HASH_MARK;
    struct list_head *pos;
    Node *node;
    LIST_FOR_EACH( pos, &vPid2Sid[ idx ] ) {
        node = LIST_ENTRY( pos, Node, link );
        if ( node->key == pid ) return node->val;
    }
    return 0;
}

void do_rem_key( int key, struct list_head *vec )
{
    int idx = key & HASH_MARK;
    struct list_head *pos;
    Node *node;
    LIST_FOR_EACH( pos, vec+idx ) {
        node = LIST_ENTRY( pos, Node, link );
        if ( node->key == key ) {
            LIST_DEL( pos );
            free( node );
            return;
        }
    }
}

void do_add_hash( int key, int val, struct list_head* vec )
{
    do_rem_key( key, vec );

    int idx = key & HASH_MARK;
    Node *node = calloc( sizeof( Node ), 1 );
    node->key = key;
    node->val = val;
    LIST_ADD_TAIL( &node->link, vec + idx );
}


void add_cli(int sid, int pid)
{
    do_add_hash( pid, sid, &vPid2Sid[0] );
}

void rem_cli(int pid)
{
    do_rem_key( pid, &vPid2Sid[0] );
}

int thread_idx( int sid )
{
    return sid & THREAD_MARK;
}


void* exchange_loop(void *arg)
{
    printf("thread exchange\n");
    QueInit(&exchange_msg);

    struct list_head msgs;
    INIT_LIST_HEAD(&msgs);

    struct list_head *pos;
    struct Buf *buf, *tbuf;
    struct list_head vq[ MAX_THREAD ];
    char *cur, *end, *start;
    int size, num, i, pid, sid, sig, map, mid;
    Sess *sess;
    Thread *dest;
    int cmd, fd;

    for( i = 0; i < MAX_THREAD; ++i ) INIT_LIST_HEAD( &vq[ i ] );
   
    while (gOn) {
        INIT_LIST_HEAD( &msgs );
        QueGetAll( &exchange_msg, &msgs );
        while ( !LIST_EMPTY( &msgs ) ) {
            pos = msgs.next;
            LIST_DEL(pos);
            buf = LIST_ENTRY(pos, struct Buf, link);
            if ( buf->sid ) { // sid is player
                pid = buf->sid;
                sid = sid_from_pid( pid );
                if ( sid ) {
                    buf->sid = sid;
                    LIST_ADD_TAIL( &buf->link, &vq[ thread_idx(buf->sid) ] );

                } else {
                    if ( gSidRouter ) {
                        size = buf->t - buf->h + 16;
                        tbuf = NEW_BUF( size );
                        cur = tbuf->h;
                        *( unsigned int *)cur = htonl( size - 4 ); cur += 4;
                        *( unsigned int *)cur = htonl( NET_ROUTER ); cur += 4;
                        *( unsigned int *)cur = htonl( pid ); cur += 4;
                        *( unsigned int *)cur = htonl( buf->from ); cur += 4;
                        memcpy( cur, buf->h, buf->t - buf->h ); cur += ( buf->t - buf->h );
                        tbuf->sid = gSidRouter;
                        LIST_ADD_TAIL( &buf->link, &vq[ thread_idx(gSidRouter) ] );
                        DEL_BUF( buf );
                    
                    } else {
                        DEL_BUF( buf );
                    }
                }

            } else {
                cmd = *(unsigned int*)(buf->h);
                sid = *(unsigned int*)(buf->h+4);
                pid = *(unsigned int*)(buf->h+8);
                switch (cmd) {
                    case CMD_SIGNIN:
                        if ( pid > 0 ) {
                            add_cli( sid, pid );
                            if ( pid >= 10000 && gIsGate) {
                                sess = get_sess( sid );
                                if ( sess ) {
                                    map = *(unsigned int*)(buf->h+12);
                                    sess->pid = pid;
                                    sess->map = map;
                                    sess->state = STATE_ON;
                                    mid = sid_from_pid( map );
                                    if ( mid > 0 ) {
                                        LIST_ADD_TAIL( &buf->link, &vq[ thread_idx(mid) ] );
                                        continue;
                                    }
                                }
                            }
                        }
                        DEL_BUF(buf);
                        break;

                    case CMD_SIGNOUT:
                        if ( pid > 0 ) rem_cli( pid );
                        sess = get_sess(sid); if ( sess ) close_sess( sess );
                        DEL_BUF(buf);
                        break;
                    
                    case CMD_SEND_ALL:
                        map = sid;
                        cur = buf->h + 8;
                        end = buf->t;
                        size = buf->t - cur;
                        //printf( "send all, map=%d, size=%d\n", map, size);
                        for ( i = 0; i < HASH_SIZE; ++i ) {
                            sess = &vSess[ i ];
                            if ( sess->map == map && sess->state == STATE_ON && sess->mode == MODE_CLI ) {
                                tbuf = NEW_BUF( size );
                                memcpy( tbuf->h, cur, size );
                                tbuf->t += size;
                                tbuf->sid = sess->sid;
                                LIST_ADD_TAIL( &tbuf->link, &vq[ thread_idx(sess->sid) ] );
                            }
                        }
                        DEL_BUF( buf );
                        break;

                    case CMD_SEND_MUL:
                        cur = buf->h + 4;
                        num = ntohl(*( unsigned int* )cur);  cur += 4;
                        start = cur + num * 4;
                        end = buf->t;
                        size = end - start;
                        if ( size > 0 ) {
                            for ( i = 0; i < num; ++i ) {
                                pid = ntohl( *( int* )cur ); cur += 4;
                                sid = sid_from_pid( pid );
                                if ( sid > 0 ) {
                                    tbuf = NEW_BUF( size + 4 );
                                    *( unsigned int* )tbuf->h = htonl( size );
                                    memcpy( tbuf->h + 4, start, size );
                                    tbuf->t = tbuf->h + 4 + size;
                                    tbuf->sid = sess->sid;
                                    LIST_ADD_TAIL( &tbuf->link, &vq[ thread_idx(sess->sid) ] );
                                }
                            }
                        }
                        DEL_BUF( buf );
                        break;

                    case CMD_INCOME_CLI:
                    case CMD_INCOME_SRV:
                    case CMD_LISTEN:
                    case CMD_CONNECT:
                        buf->sid = 0;
                        LIST_ADD_TAIL( &buf->link, &vq[ thread_idx(sid) ] );
                        break;
                }
            }
        } // while ( !LIST_EMPTY( &msgs ) ) {

        for (i = 0; i < MAX_THREAD; ++i) {
            if (!LIST_EMPTY( &vq[ i ] )) {
                dest = &vThread[ i ];

                sig = 0;
                pthread_mutex_lock(&dest->qwl);
                sig = dest->nw;
                dest->nw++;
                LIST_SPLICE_TAIL(&vq[i], &dest->qw);
                INIT_LIST_HEAD(&vq[i]);
                pthread_mutex_unlock(&dest->qwl);

                if ( !sig ) write(dest->sockw, "1", 1);
            }
        }
    }
}

int main(int argc, char *argv[])
{
    int i = 0;
    for (i = 0; i < HASH_SIZE; ++i) {
        memset(&vSess[i], 0, sizeof(Sess));
        vSess[i].fd = i;
        INIT_LIST_HEAD( &vSess[i].bufwq );
    }

    for ( i = 0; i < HASH_SIZE; ++i ) {
        INIT_LIST_HEAD( &vPid2Sid[ i ] );
    }

    pthread_t tid; 
    pthread_attr_t attr;

    pthread_attr_init(&attr); 
    pthread_create(&tid,&attr,exchange_loop,NULL);
    pthread_attr_destroy(&attr);

    for ( i = 0; i < MAX_THREAD; ++i ) {
        pthread_attr_init(&attr); 
        pthread_create(&tid, &attr, loop, (void*)(long)i);
        pthread_attr_destroy(&attr);
    }

    while ( g_nthread < MAX_THREAD ) usleep( 1000 );

    start_listen(18001, MODE_CLI);
    start_listen(18002, MODE_SRV);

    printf("sess = %d\n", sizeof(vSess));
    while (1) {
        printf( "gBufCount = %d\n", gBufCount );
        sleep(60);
    }

    return 0;
}

