#include "log.h"
#include "que.h"
#include "tlog/include/pal/tos.h"
#include "tlog/include/tdr/tdr.h"
#include "tlog/include/tlog/tlog.h"
#include "tlog/include/tloghelp/tlogload.h"

#define MSG_SIZE 1024

Que gTlogQue;
int gTlogVer = 0;
unsigned int gTlogThread = 0;

typedef struct {
    LPTLOGCTX ctx;
    LPTLOGCATEGORYINST cat;
    int ver;
} TlogNode;

typedef struct {
    char msg[ MSG_SIZE ];
    struct list_head link;
} Tlog;

static void *worker( void *arg )
{
    TlogNode *node = (TlogNode*)arg;
    int version = node->ver;
    struct list_head head, *pos;
    Tlog *msg;

    INFO("TLOG, IN %d", version );
    __sync_fetch_and_add(&gTlogThread, 1);
    while ( version == gTlogVer ) {
        INIT_LIST_HEAD( &head );
        QueGetAll( &gTlogQue, &head );
        while ( !LIST_EMPTY( &head ) ) {
            pos = head.next;
            LIST_DEL( pos );
            msg = LIST_ENTRY( pos, Tlog, link );
            if ( version == gTlogVer ) {
                tlog_info(node->cat, 0, 0, msg->msg );
                free( msg );
            } else {
                QuePut( &gTlogQue, &msg->link );
            }
        }
    }
    tlog_fini_ctx( &node->ctx );
    INFO("TLOG, OUT %d", version );
    __sync_fetch_and_sub(&gTlogThread, 1);
}


void tlog_start( const char *xml )
{
    if ( !gTlogVer ) {
        QueInit( &gTlogQue );
        gTlogVer = 1;
    }

    int i;
    LPTLOGCTX           pstLogCtx;
    LPTLOGCATEGORYINST  pstCat;
    char name[ 64 ] = {0,};
    TlogNode *node;
    gTlogVer++;

    pthread_t tid; 
    pthread_attr_t attr;
    pthread_attr_init(&attr); 

    for ( i = 1; i <= 20; ++i ) {
        pstLogCtx = tlog_init_from_file(xml);
        if ( pstLogCtx ) {
            snprintf( name, sizeof( name ), "test%d", i );
            pstCat = tlog_get_category( pstLogCtx, name );
            if ( pstCat ) {
                node = ( TlogNode *)calloc( sizeof( TlogNode ), 1 );
                node->ctx = pstLogCtx;
                node->cat = pstCat;
                node->ver = gTlogVer;
                pthread_create(&tid,&attr,worker,node);
                pthread_attr_destroy(&attr);
                continue;
            } else {
                INFO( "TLOG, %s, ERROR\n", name );
            }
        } else {
            INFO( "TLOG, %s, ERROR\n", xml );
        }
    }
}

void tlog( char *msg )
{
    Tlog *tlog = (Tlog*)calloc( sizeof( Tlog ), 1 );
    INIT_LIST_HEAD( &tlog->link );
    snprintf( tlog->msg, MSG_SIZE-1, msg );
    QuePut( &gTlogQue, &tlog->link );
}

void tlog_stop( char *xml )
{
    gTlogVer++;
    while ( gTlogThread > 0 ) {
        sleep(1);
    }
}

