#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/epoll.h>
#include <linux/tcp.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <string.h>
#include <malloc_extension_c.h>
#include "mylist.h"
#include "pike.h"
#include "buf.h"
#include "que.h"
#include "log.h"

int gOn = 1;
int gIsGate = 1;
int gIsCore = 0;
int gSidCore = 0;
int gSidTool = 0;
int gCountPly = 0;
int gCountSrv = 0;
int gCountSck = 0;
int gCountPlyTotal = 0;


Que exchange_msg;
extern unsigned int gBufCount;

#define MAX_THREAD 16
#define HASH_SIZE 0x010000
#define HASH_MARK 0x00FFFF
#define PID_CORE 9000
#define PID_TOOL 9001

#define CERT_WRONG_PASW 1
#define CERT_BLOCK      2
#define CERT_MAINTAIN   3
#define CERT_DUPLICATE  4

#define NET_ECHO 12
#define NET_MSG_CLOSE   6
#define NET_SET_MAP_ID  8
#define NET_SET_SRV_ID  9
#define NET_CERTIFY     14
#define NET_SEND_MUL    15
#define NET_SNAPSHOT    17

#define NET_P2P         1612229045
#define NET_P2PS        215171762
#define NET_LOGIN       1233071922
#define NET_FIRST_PACKET    1122052733
#define NET_FIRST_PACKET2   393583197
#define NET_ROUTER      1276860164
#define NET_ROUTER_TRY  1398336378
#define NET_SIGNIN      999243419
#define NET_SIGNOUT     1378554184
#define NET_QRY_TOOL    1499206028
#define NET_ACK_TOOL    1238314001

#define NET_SEND_ALL_SRV 53150297
#define NET_SEND_ALL_CLI 1708404662
#define NET_SEND_TO_SCK 730939457

#define MAX_CLIENT_PACKET_SIZE 0x04000

enum {STATE_NULL=0, STATE_SHAKE, STATE_NEW, STATE_LOGIN, STATE_ON, STATE_BREAK};
enum {MODE_NULL=0, MODE_LISTEN, MODE_CLI, MODE_SRV, MODE_TRANS_GATE, MODE_TRANS_CORE, MODE_TOOL, MODE_SIGNAL, MODE_MAX};
enum {CMD_LISTEN, CMD_CONNECT, CMD_SIGNIN_SRV, CMD_SIGNIN_CLI, CMD_SIGNOUT, CMD_SEND_ALL, CMD_SEND_MUL, CMD_INCOME, CMD_RESET_MERGE};

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
    int pid; // server is also a player, pid < 10000, server_tool is PID_TOOL, server_core is PID_CORE
    int map;
    int state, mode, type, encode;
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
int vMerge[1024][2] = { {0,0}, };

unsigned int gMsec;
unsigned int gTime;
struct timeval tsStart;

int thread_idx( int sid )
{
    return sid % MAX_THREAD;
}

void setTime()
{
    struct timeval tsNow;
    gettimeofday(&tsNow, NULL);

    gTime = tsNow.tv_sec;
    gMsec = (tsNow.tv_sec - tsStart.tv_sec) * 1000 + tsNow.tv_usec * 0.001;
}

void *thread_time( void *arg )
{
    gettimeofday(&tsStart, NULL);
    tsStart.tv_usec = 0;
    gTime = tsStart.tv_sec;
    gMsec = 0;

    while ( gOn ) {
        setTime();
        usleep(0);
    }
}

void status()
{
    size_t sz = 0, hsz = 0;
    MallocExtension_GetNumericProperty("generic.current_allocated_bytes", &sz);
    MallocExtension_GetNumericProperty("generic.heap_size", &hsz);
    sz >>= 20;
    hsz >>= 20;
    LOG( "alloc=%d, heap=%d, buf=%d, srv=%d, ply=%d, sck=%d, total=%d\n", sz, hsz, gBufCount, gCountSrv, gCountPly, gCountSck, gCountPlyTotal );
    if ( gCountSrv + gCountPly > gCountSck ) WARN( "ERROR, srv=%d, cli=%d, sck=%d", gCountSrv, gCountPly, gCountSck );
}

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

struct Buf* make_packet_fix( int from, int to, int pktype, int d0, int d1)
{
    int data[2];
    data[ 0 ] = htonl( d0 );
    data[ 1 ] = htonl( d1 );
    char *head = ( char* )data;
    char *tail = head + sizeof( data );

    struct Buf *buf = NULL;
    if ( to < 10000 ) {
        // send to server, should add infomation from
        buf = NEW_BUF( tail - head + 12 );
        char *cur = buf->t;
        *( unsigned int *)cur = htonl( tail - head + 8 ); cur += 4;
        *( unsigned int *)cur = htonl( from ); cur += 4;
        *( unsigned int *)cur = htonl( pktype ); cur += 4;
        if ( tail > head ) {
            memcpy( cur, head, tail - head ); cur += ( tail - head );
        }
        buf->t = cur;
        buf->from = from;
        buf->sid = to;

    } else {
        buf = NEW_BUF( tail - head + 8 );
        char *cur = buf->t;
        *( unsigned int *)cur = htonl( tail - head + 4 ); cur += 4;
        *( unsigned int *)cur = htonl( pktype ); cur += 4;
        if ( tail > head ) {
            memcpy( cur, head, tail - head ); cur += ( tail - head );
        }
        buf->t = cur;
        buf->from = from;
        buf->sid = to;
    }
    return buf;
}



struct Buf* make_packet( int from, int to, int pktype, char *head, char *tail )
{
    struct Buf *buf = NULL;
    if ( to < 10000 ) {
        // send to server, should add infomation from
        buf = NEW_BUF( tail - head + 12 );
        char *cur = buf->t;
        *( unsigned int *)cur = htonl( tail - head + 8 ); cur += 4;
        *( unsigned int *)cur = htonl( from ); cur += 4;
        *( unsigned int *)cur = htonl( pktype ); cur += 4;
        if ( tail > head ) {
            memcpy( cur, head, tail - head ); cur += ( tail - head );
        }
        buf->t = cur;
        buf->from = from;
        buf->sid = to;

    } else {
        buf = NEW_BUF( tail - head + 8 );
        char *cur = buf->t;
        *( unsigned int *)cur = htonl( tail - head + 4 ); cur += 4;
        *( unsigned int *)cur = htonl( pktype ); cur += 4;
        if ( tail > head ) {
            memcpy( cur, head, tail - head ); cur += ( tail - head );
        }
        buf->t = cur;
        buf->from = from;
        buf->sid = to;
    }
    return buf;
}

void send_to_sck( int sid, struct Buf *buf )
{
    buf->sid = sid;
    int idx = thread_idx( sid );
    Thread *dest = &vThread[ idx ];

    int sig = 0;
    pthread_mutex_lock(&dest->qwl);
    sig = dest->nw;
    dest->nw++;
    LIST_ADD_TAIL( &buf->link, &dest->qw );
    pthread_mutex_unlock(&dest->qwl);

    if ( !sig ) write(dest->sockw, "1", 1);
}

int break_sess( Sess *s, struct list_head *msgq, int epfd )
{
    if ( s->state != STATE_BREAK ) {
        s->state = STATE_BREAK;
        epoll_ctl(epfd, EPOLL_CTL_DEL, s->fd, &s->ev);

        struct Buf *tbuf = make_cmd(CMD_SIGNOUT, s->sid, s->pid, 0, 0, 0);
        LIST_ADD_TAIL( &tbuf->link, msgq );
        if ( s->mode == MODE_CLI && s->pid > 0 ) {
            struct Buf *buf = make_packet( s->pid, s->map, NET_MSG_CLOSE, NULL, NULL );
            LIST_ADD_TAIL( &buf->link, msgq );
        }
    }
    return -1;
}

void close_sess( Sess *s )
{
    struct list_head *pos;
    struct Buf *buf;

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

int start_listen( int port, int mode, int encode )
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

    struct Buf *buf = make_cmd(CMD_LISTEN, fd, mode, encode, 0, 0);
    buf->sid = 0;
    QuePut( &exchange_msg, &buf->link );
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
        return 0;

    } else {
        close( fd );
        return -1;
    }
}

int onR_null(Sess *s, struct list_head *msgq, int epfd)
{
    // todo
    WARN("sid = %d, onR_null\n", s->sid);
    return -1;
}

int do_packet( int pid, int pktype, char *head, char *tail, struct list_head *msgq, Sess *s, int epfd)
{
    struct Buf *buf;
    char *cur, *start;
    int map, sid, to, size, i;
    unsigned short num;
    
    switch ( s->mode ) {
        case MODE_CLI:
            switch ( pktype ) {
                case NET_FIRST_PACKET:
                    if ( s->pid ) return -1;
                    if ( tail - head < 4 ) return -1;
                    if ( s->state != STATE_NEW ) return -1;
                    s->state = STATE_LOGIN;

                    map = ntohl( *( unsigned int* )( head ) );
                    buf = NEW_BUF( tail - head + 16 );
                    cur = buf->t;
                    *( unsigned int* )cur = htonl( tail - head + 12 ); cur += 4;
                    *( unsigned int* )cur = htonl( 0 ); cur += 4;
                    *( unsigned int* )cur = htonl( NET_FIRST_PACKET2 ); cur += 4;
                    *( unsigned int* )cur = htonl( s->sid ); cur += 4;
                    memcpy( cur, head, tail - head ); cur += ( tail - head );
                    buf->t = cur;
                    buf->sid = map;
                    LIST_ADD_TAIL( &buf->link, msgq );
                    break;

                case NET_ECHO:
                    if ( !(s->ev.events & EPOLLOUT) ) {
                        s->ev.events |= EPOLLOUT;
                        epoll_ctl(epfd, EPOLL_CTL_MOD, s->fd, &s->ev);
                    }
                    buf = make_packet( s->pid, 10000, pktype, head, tail );
                    LIST_ADD_TAIL( &buf->link, &s->bufwq );
                    break;

                case NET_P2P:
                    // recv: len, NET_P2P, to, ...
                    // send: len, NET_P2P, from, ...
                    to = ntohl( *( int* )( head ) );
                    if ( to >= 10000 ) {
                        head -= 8;
                        buf = NEW_BUF( tail - head );
                        memcpy( buf->t, head, tail - head );
                        buf->t += (tail - head );
                        *( unsigned int *)( buf->h + 8 ) = htonl( s->pid );
                        buf->sid = to;
                        buf->from = s->pid;
                        LIST_ADD_TAIL( &buf->link, msgq );
                    }
                    break;

                case NET_P2PS:
                    num = ntohs( *(unsigned short*)( head ) );
                    if ( num > 0 ) {
                        head += 2;
                        // recv: len, NET_P2PS, num, c1, c2, data, ...
                        // send: len, NET_P2P,  from, ...
                        if ( head + 4 * num < tail ) {
                            start = head + 4 * num - 4;
                            for ( i = 0; i < num; ++i ) {
                                pid = ntohl( *( unsigned int *)( head ) );
                                LOG( "NET_P2PS, from=%d, to=%d", s->pid, pid );
                                if ( pid >= 10000 ) {
                                    buf = make_packet( s->pid, pid, NET_P2P, start, tail );
                                    *( unsigned int *)( buf->h + 8 ) = htonl( s->pid );
                                    LIST_ADD_TAIL( &buf->link, msgq );
                                }
                                head += 4;
                            }
                        }
                    }
                    break;

                default:
                    if ( s->state != STATE_ON ) return -1;
                    if ( !s->pid ) return -1;
                    buf = make_packet( s->pid, s->map, pktype, head, tail );
                    LIST_ADD_TAIL( &buf->link, msgq );
                    break;
            }
            break;

        case MODE_SRV:
            if ( pid > 0 ) {
                if ( pktype == NET_SNAPSHOT ) {
                    buf = NEW_BUF( tail - head );
                    memcpy( buf->t, head, tail - head );
                    buf->t += ( tail - head );
                    buf->from = s->pid;
                    buf->sid = pid;
                    LIST_ADD_TAIL( &buf->link, msgq );

                } else {
                    buf = make_packet( s->pid, pid, pktype, head, tail );
                    LIST_ADD_TAIL( &buf->link, msgq );

                }
            
            } else if ( pid == 0 ) {
                switch ( pktype ) {
                    case NET_SET_MAP_ID:
                        map = ntohl( *(unsigned int*)( head ) );
                        s->map = map;
                        s->pid = map;
                        s->state = STATE_ON;
                        buf = make_cmd( CMD_SIGNIN_SRV, s->sid, map, 0, 0, 0 );
                        LIST_ADD_TAIL( &buf->link, msgq );

                        if ( gSidCore ) {
                            buf = NEW_BUF( 12 );
                            cur = buf->t;
                            *( unsigned int *)cur = htonl( 8 ); cur += 4;
                            *( unsigned int *)cur = htonl( s->pid ); cur += 4;
                            *( unsigned int *)cur = htonl( NET_SIGNIN ); cur += 4;
                            buf->t = cur;
                            buf->sid = gSidCore;

                            LIST_ADD_TAIL( &buf->link, msgq );
                        }
                        break;

                    case NET_SET_SRV_ID:
                        sid = ntohl( *(unsigned int*)(head) );
                        map = ntohl( *(unsigned int*)(head+4) );
                        pid = ntohl( *(unsigned int*)(head+8) );
                        buf = make_cmd( CMD_SIGNIN_CLI, sid, pid, map, 0, 0 );
                        LIST_ADD_TAIL( &buf->link, msgq );
                        break;

                    case NET_SEND_MUL:
                        buf = NEW_BUF( tail - head + 4 );
                        cur = buf->t;
                        *( unsigned int* )cur = CMD_SEND_MUL; cur += 4;
                        memcpy( cur, head, tail - head ); cur += ( tail - head );
                        buf->t = cur;
                        buf->from = s->pid;
                        LIST_ADD_TAIL( &buf->link, msgq );
                        break;

                    case NET_QRY_TOOL:
                        head -= 12;
                        buf = NEW_BUF( tail - head );
                        memcpy( buf->t, head, tail - head ); buf->t += ( tail - head );
                        buf->from = s->pid;
                        buf->sid = PID_TOOL;
                        *( unsigned int* )( buf->h + 4 ) = htonl( s->map );
                        LIST_ADD_TAIL( &buf->link, msgq);
                        break;

                    case NET_SEND_ALL_SRV:
                        // todo
                        break;

                    case NET_SEND_ALL_CLI:
                        // todo
                        break;

                    case NET_SEND_TO_SCK:
                        sid = ntohl( *(unsigned int*)(head) ); 
                        buf = NEW_BUF( tail - head );
                        memcpy( buf->t, head, tail - head );
                        buf->t += ( tail - head );
                        *( unsigned int*)(buf->h) = htonl( tail - head - 4 );
                        send_to_sck( sid, buf );
                        break;

                    default:
                        WARN( "%s:%d, pktype=%d", __FILE__, __LINE__, pktype );
                        break;

                }
            } else {
                // SEND_ALL
                // pksize, -1, pktype, ...
                buf = NEW_BUF( tail - head + 16 );
                cur = buf->t;
                *( unsigned int *)cur = CMD_SEND_ALL; cur += 4;
                *( unsigned int *)cur = s->map; cur += 4;
                *( unsigned int *)cur = htonl( tail - head + 4 ); cur += 4;
                *( unsigned int *)cur = htonl( pktype ); cur += 4;
                memcpy( cur, head, tail - head ); cur += ( tail - head );
                buf->t = cur;
                LIST_ADD_TAIL( &buf->link, msgq);
            }
            break;

        case MODE_TRANS_GATE:
            // Len, To, NET_ROUTER, From, REAL_PACKET, 
            switch ( pktype ) {
                case NET_ROUTER:
                    head += 4;
                    buf = NEW_BUF( tail - head );
                    memcpy( buf->t, head, tail - head ); buf->t += ( tail - head );
                    buf->sid = pid;
                    LIST_ADD_TAIL( &buf->link, msgq);
                    break;
            }
            break;

        case MODE_TRANS_CORE:
            switch ( pktype ) {
                case NET_ROUTER:
                    head -= 12;
                    buf = NEW_BUF( tail - head );
                    memcpy( buf->t, head, tail - head ); buf->t += ( tail - head );
                    buf->sid = pid;
                    LIST_ADD_TAIL( &buf->link, msgq);
                    break;

                case NET_SIGNIN:
                    buf = make_cmd(CMD_SIGNIN_SRV, s->sid, pid, 0, 0, 0);
                    LIST_ADD_TAIL( &buf->link, msgq);
                    break;
            
            }
            break;

        case MODE_TOOL:
            if ( pktype == NET_ACK_TOOL ) {
                head -= 12;
                buf = NEW_BUF( tail - head );
                memcpy( buf->t, head, tail - head ); buf->t += ( tail - head );
                buf->sid = pid;
                LIST_ADD_TAIL( &buf->link, msgq);
            }
            break;
    }
    return 0;
}


int do_read(Sess *s, struct list_head *msgq, int epfd)
{
    char *cur, *end, *p;
    int pktype, pksize, pid, remain;

    struct Buf *tbuf = NULL;
    struct Buf *buf = s->bufr;
    if (!buf) { 
        buf = NEW_BUF(0); 
        s->bufr = buf; 
    }

    int len = recv(s->fd, buf->t, buf->e - buf->t, 0);
    if (len <= 0) {
        break_sess( s, msgq, epfd );
        if ( s->mode == MODE_TRANS_GATE ) gSidCore = 0;
        if ( s->mode == MODE_TOOL ) gSidTool = 0;
        return -1;

    } else {
        if ( s->encode ) {
            if ( !s->ctxr ) {
                s->ctxr = (Ctx*)calloc( sizeof( Ctx ), 1 );
                ctx_init( s->sid, s->ctxr );
            }
            ctx_encode( s->ctxr, buf->t, len );
        }

        buf->t += len;
        cur = buf->h;
        end = buf->t;

        while (end - cur >= 4) {
            pksize = ntohl(*(unsigned int*)cur);
            if ( pksize < 4 ) return break_sess( s, msgq, epfd );

            if ( s->mode == MODE_CLI && s->pid == 0 ) {
                if ( pksize > 256 ) return break_sess( s, msgq, epfd );
                if ( cur + 4 + pksize != end ) return break_sess( s, msgq, epfd );
            }

            if ( cur + 4 + pksize > end ) break;

            if ( s->mode == MODE_CLI ) {
                // len, pktype, ...
                pid = s->pid;
                pktype = ntohl( *(int*)(cur+4) );
                if ( do_packet( pid, pktype, cur + 8, cur + 4 + pksize, msgq, s, epfd ) < 0 ) return break_sess( s, msgq, epfd );
            
            } else {
                // len, topid, pktype, ...
                pid = ntohl( *(int*)(cur+4) );
                pktype = ntohl( *(int*)(cur+8) );
                if ( do_packet( pid, pktype, cur + 12, cur + 4 + pksize, msgq, s, epfd ) < 0 ) return break_sess( s, msgq, epfd );
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
                    if ( s->mode == MODE_CLI ) return break_sess( s, msgq, epfd ); 

                    s->bufr = NULL;
                    tbuf = NEW_BUF(pksize+4);
                    if (tbuf) {
                        memcpy(tbuf->h, cur, remain);
                        tbuf->t = tbuf->h + remain;
                        s->bufr = tbuf;
                    } else {
                        break_sess( s, msgq, epfd );
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

int onAccept(Sess *s, struct list_head *msgq, int epfd)
{
    struct sockaddr_in addr;
    socklen_t len = sizeof( addr );
    int fd = accept( s->fd, (struct sockaddr *)&addr, &len);
    if (fd > 0) {
        struct Buf *buf = make_cmd(CMD_INCOME, fd, s->type, s->encode, 0, 0);
        LIST_ADD_TAIL( &buf->link, msgq );
    }
    return 0;
}

//enum {MODE_NULL=0, MODE_LISTEN, MODE_CLI, MODE_SRV, MODE_TRANS_GATE, MODE_TRANS_CORE, MODE_TOOL, MODE_SIGNAL, MODE_MAX};
FUNC_R onRead_funcs[ MODE_MAX ] = { onR_null, onAccept, do_read, do_read, do_read, do_read, do_read };

int make_sid(int fd)
{
    static int sn = 0;
    sn++;
    if (sn >= 0x08000 ) sn = 1;
    return (sn << 16) + fd;
}

void do_cmd(struct Buf *buf, int epfd, struct list_head *msgq)
{
    int cmd, sid, mode, flags, i, count, pid, map, fd;
    Sess *sess, *s;
    char *cur;
    struct Buf *tbuf;
    cmd = *(unsigned int*)(buf->h);
    sid = *(unsigned int*)(buf->h+4);
    switch (cmd) {
        case CMD_INCOME:
            sess = &vSess[ sid ];
            if (sess) {
                fd = sid;
                flags = fcntl(sid, F_GETFL, 0);
                fcntl(sid, F_SETFL, flags|O_NONBLOCK);

                int enable = 1;
                // linux/tcp.h TCP_NODELAY = 1
                setsockopt( sid, IPPROTO_TCP, TCP_NODELAY, (void*)&enable, sizeof(enable) );

                sess->fd = fd;
                mode = *(unsigned int*)(buf->h+8);
                sess->mode = mode;
                sess->encode = *(unsigned int*)(buf->h+12);
                sess->sid = make_sid( fd );
                sess->ev.data.fd = sid;
                LOG( "income, fd=%d, mode=%d, sid=0x%08x, pid=%d", sess->fd, sess->mode, sess->sid, sess->pid );
                status();

                if ( sess->encode ) {
                    sess->state = STATE_SHAKE;
                    sess->ev.events = EPOLLOUT;
                } else {
                    sess->state = STATE_NEW;
                    sess->ev.events = EPOLLIN;
                }
                epoll_ctl(epfd, EPOLL_CTL_ADD, sess->fd, &sess->ev);
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
                sess->mode = MODE_LISTEN;
                sess->type = *(unsigned int*)(buf->h+8);
                sess->encode = *(unsigned int*)(buf->h+12);

                listen( sess->fd, 1024 );
            }
            break;

        case CMD_CONNECT:
            sess = &vSess[ sid ];
            if (sess) {
                sess->fd = sid;
                sess->mode = *(unsigned int*)(buf->h+8);
                sess->state = STATE_ON;
                sess->sid = make_sid( sid );
                sess->ev.events = EPOLLIN;
                sess->ev.data.fd = sid;
                epoll_ctl(epfd, EPOLL_CTL_ADD, sess->fd, &sess->ev);

                if ( sess->mode == MODE_TRANS_GATE ) {
                    gSidCore = sess->sid;
                    count = 0;
                    for ( i = 0; i < HASH_SIZE; ++i ) {
                        s = &vSess[ i ];
                        if ( s->state == STATE_ON && s->mode == MODE_SRV ) {
                            count++;
                            tbuf = NEW_BUF( 12 );
                            cur = tbuf->t;
                            *( unsigned int *)cur = htonl( 8 ); cur += 4;
                            *( unsigned int *)cur = htonl( s->pid ); cur += 4;
                            *( unsigned int *)cur = htonl( NET_SIGNIN ); cur += 4;
                            tbuf->t = cur;
                            LIST_ADD_TAIL( &tbuf->link, &sess->bufwq );
                        }
                    }
                    if ( count ) {
                        sess->ev.events |= EPOLLOUT;
                        epoll_ctl(epfd, EPOLL_CTL_MOD, sess->fd, &sess->ev);
                    }

                } else if ( sess->mode == MODE_TOOL ) {
                    gSidTool = sess->sid;
                    sess->pid = PID_TOOL;
                    tbuf = make_cmd( CMD_SIGNIN_SRV, sess->sid, PID_TOOL, 0, 0, 0 );
                    LIST_ADD_TAIL( &tbuf->link, msgq );
                
                }
            }
            break;

        default:
            break;
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
    int epfd = epoll_create( HASH_SIZE / MAX_THREAD );
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
                    send(s->fd, seed, 12, 0);
                    s->state = STATE_NEW;
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
                        if ( s->encode ) {
                            if ( !s->ctxw ) {
                                s->ctxw = (Ctx*)calloc( sizeof( Ctx ), 1 );
                                ctx_init( s->sid, s->ctxw );
                            } 
                            ctx_encode( s->ctxw, buf->h, buf->t - buf->h );
                        }
                    }

                    buf = s->bufw;
                    if (buf) {
                        len = send(s->fd, buf->h, buf->t - buf->h, 0);
                        buf->h += len;
                        if (buf->h >= buf->t) {
                            printf( "send %d\n", gMsec );
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



void* exchange_loop(void *arg)
{
    QueInit(&exchange_msg);

    struct list_head msgs;
    INIT_LIST_HEAD(&msgs);

    struct list_head *pos;
    struct Buf *buf, *tbuf;
    struct list_head vq[ MAX_THREAD ];
    char *cur, *end, *start;
    int size, num, i, pid, sid, sig, map, mid, mode, tsid;
    Sess *sess, *tsess;
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
                    if ( gSidCore && buf->from ) {
                        size = buf->t - buf->h + 16;
                        tbuf = NEW_BUF( size );
                        cur = tbuf->h;
                        // len, to, NET_ROUTER, from, ...
                        *( unsigned int *)cur = htonl( size - 4 ); cur += 4;
                        *( unsigned int *)cur = htonl( pid ); cur += 4;
                        *( unsigned int *)cur = htonl( NET_ROUTER ); cur += 4;
                        *( unsigned int *)cur = htonl( buf->from ); cur += 4;
                        memcpy( cur, buf->h, buf->t - buf->h ); cur += ( buf->t - buf->h );
                        tbuf->t = cur;
                        tbuf->sid = gSidCore;
                        LIST_ADD_TAIL( &tbuf->link, &vq[ thread_idx(gSidCore) ] );
                    }
                    DEL_BUF( buf );
                }

            } else {
                cmd = *(unsigned int*)(buf->h);
                sid = *(unsigned int*)(buf->h+4);
                pid = *(unsigned int*)(buf->h+8);
                switch (cmd) {
                    case CMD_SIGNIN_SRV:
                        if ( pid > 0 ) {
                            sess = get_sess( sid );
                            if ( sess ) {
                                sess->state = STATE_ON;
                                add_cli( sid, pid );
                                LOG( "signin, fd=%d, mode=%d, sid=0x%08x, pid=%d", sess->fd, sess->mode, sess->sid, sess->pid );
                                gCountSrv++;
                                if ( pid < 10000 ) {
                                    for ( i == 0; i < 1024; ++i ) {
                                        if ( vMerge[ i ][ 0 ] == 0 ) break;
                                        if ( vMerge[ i ][ 1 ] == pid ) {
                                            add_cli( sid, vMerge[ i ][ 0 ] );
                                        }
                                    }
                                }
                            }
                        }
                        DEL_BUF(buf);
                        status();
                        break;

                    case CMD_SIGNIN_CLI:
                        sess = get_sess( sid );
                        if ( sess ) {
                            tsid = sid_from_pid( pid );
                            if ( tsid ) {
                                tsess = get_sess( tsid );
                                if ( tsess ) {
                                    LOG( "duplicate, fd=%d, mode=%d, sid=0x%08x, pid=%d", tsess->fd, tsess->mode, tsess->sid, tsess->pid );
                                    tsess->pid = 0;
                                    tsess->map = 0;
                                    tbuf = make_packet_fix( 0, pid, NET_CERTIFY, CERT_DUPLICATE, 0);
                                    tbuf->sid = tsid;
                                    LIST_ADD_TAIL( &tbuf->link, &vq[ thread_idx(tsid) ] );

                                    if ( pid >= 10000 ) gCountPly--; 

                                }
                            }

                            if ( sess->state != STATE_LOGIN || sess->pid ) LOG( "ERROR, signin, fd=%d, mode=%d, sid=0x%08x, pid=%d, state=%d, why?", sess->fd, sess->mode, sess->sid, sess->pid, sess->state );
                            map = *(unsigned int*)(buf->h+12);
                            sess->map = map;
                            sess->pid = pid;
                            sess->state = STATE_ON;

                            LOG( "signin, fd=%d, mode=%d, sid=0x%08x, pid=%d", sess->fd, sess->mode, sess->sid, sess->pid );
                            add_cli( sid, pid );
                            if ( pid >= 10000 ) { gCountPly++; gCountPlyTotal++;}
                        }
                        DEL_BUF( buf );
                        status();
                        break;

                    case CMD_SIGNOUT:
                        sess = get_sess(sid); 
                        if ( sess ) {
                            LOG( "break,  fd=%d, mode=%d, sid=0x%08x, pid=%d", sess->fd, sess->mode, sess->sid, sess->pid );
                            pid = sess->pid;
                            if ( pid > 0 ) {
                                rem_cli( pid );
                                if ( pid < 9000 ) {
                                    gCountSrv--;
                                    for ( i == 0; i < 1024; ++i ) {
                                        if ( vMerge[ i ][ 0 ] == 0 ) break;
                                        if ( vMerge[ i ][ 1 ] == pid ) {
                                            rem_cli( vMerge[ i ][ 0 ] );
                                        }
                                    }

                                } else if ( pid < 10000 ) {

                                } else if ( pid >= 10000 ) {
                                    gCountPly--;
                                }
                            }
                            close_sess( sess );
                            gCountSck--;
                        }
                        DEL_BUF(buf);
                        status();
                        break;
                    
                    case CMD_SEND_ALL:
                        map = sid;
                        cur = buf->h + 8;
                        end = buf->t;
                        size = buf->t - cur;
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
                                    sess = get_sess( sid );
                                    if ( sess ) {
                                        tbuf = NEW_BUF( size + 4 );
                                        *( unsigned int* )tbuf->h = htonl( size );
                                        memcpy( tbuf->h + 4, start, size );
                                        tbuf->t = tbuf->h + 4 + size;
                                        tbuf->sid = sess->sid;
                                        tbuf->from = buf->from;
                                        LIST_ADD_TAIL( &tbuf->link, &vq[ thread_idx(sess->sid) ] );
                                    }
                                }
                            }
                        }
                        DEL_BUF( buf );
                        break;

                    case CMD_INCOME:
                        gCountSck++;
                    case CMD_CONNECT:
                    case CMD_LISTEN:
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

int load_merge()
{
    char line[ 64 ] = {0,};
    int from = 0;
    int to = 0;
    int idx = 0;
    FILE *fp = fopen( "merge.txt", "r" );
    if ( !fp ) {
        printf( "no merge\n" );
        return -1;
    }

    memset( vMerge, 0, sizeof( vMerge ) );
    while ( fgets( line, sizeof(line), fp ) ) {
        if ( line[0] != '/' ) {
            sscanf( line, "%d,%d", &from, &to );
            vMerge[ idx ][ 0 ] = from;
            vMerge[ idx ][ 1 ] = from;
            idx += 1;
        }
    }
    fclose( fp );
    return 0;
}


void usage() {
    printf( "usage: ./gate -c port_cli -s port_srv -e\n" );
    printf( "usage: ./gate -c 9001 -s 9002 -e\n" );
    printf( "usage: -e is encode\n" );
    exit( -1 );
}

int main(int argc, char *argv[])
{
    //load_merge();
    //return 0;

    int opt;
    char * optstring = "c:s:ed";
    int port_cli = 0;
    int port_srv = 0;
    int encode = 0;
    int daemon = 0;

    while ((opt = getopt(argc, argv, optstring)) != -1) {
        switch ( opt ) {
            case 'c' :
                port_cli = atoi( optarg );
                if ( !port_cli ) usage();
                break;

            case 's':
                port_srv = atoi( optarg );
                if ( !port_srv ) usage();
                break;

            case 'e':
                encode = 1;
                break;

            case 'd':
                daemon = 1;
                break;
        }
    }

    if ( port_cli == 0 || port_srv == 0 ) {
        gIsGate = 0;
        gIsCore = 1;
        init_log( "core" );
        printf( "is it a core server !!!!!\n" );
        printf( "usage: ./gate -c port_cli -s port_srv -e -d\n" );
        return;

    } else if ( port_cli && port_srv ) {
        gIsGate = port_cli;
        gIsCore = 0;
        char tips[32] = {0,};
        snprintf( tips, sizeof(tips), "gate_%d", port_cli );
        init_log( tips );

    } else {
        usage();
    }
    printf( "port_cli=%d, port_srv=%d, encode=%d, daemon=%d\n", port_cli, port_srv, encode, daemon );

    if ( daemon ) be_daemon();

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

    pthread_attr_init(&attr); 
    pthread_create(&tid,&attr,&thread_time,NULL);
    pthread_attr_destroy(&attr);


    for ( i = 0; i < MAX_THREAD; ++i ) {
        pthread_attr_init(&attr); 
        pthread_create(&tid, &attr, loop, (void*)(long)i);
        pthread_attr_destroy(&attr);
    }
    while ( g_nthread < MAX_THREAD ) usleep( 1000 );

    if ( gIsGate ) {
        start_listen( port_cli, MODE_CLI, encode );
        start_listen( port_srv, MODE_SRV, 0 );

    } else {
        start_listen(18000, MODE_TRANS_CORE, 0);
        gIsGate = 0;
        gIsCore = 1;
    }

    while (1) {
        status();
        if ( gIsGate && !gSidCore ) start_connect( "192.168.100.12", 18000, MODE_TRANS_GATE );
        if ( gIsGate && !gSidTool ) start_connect( "192.168.100.12", 17000, MODE_TOOL );
        sleep(60);
    }

    return 0;
}

