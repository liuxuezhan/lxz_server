#include <string.h>
#include <stdio.h>
#include "buf.h"
#include "stdlib.h"
#include "log.h"

unsigned int gBufCount = 0;
unsigned int gBufExtra = 0;

void del_buf(struct Buf* buf)
{
    if (buf) {
        if (buf->b != buf->pool) {
            __sync_fetch_and_sub(&gBufExtra, buf->e - buf->b);
            free(buf->b);
        }
        free(buf);
        __sync_fetch_and_sub(&gBufCount, 1);
    }
}


struct Buf* new_buf_mark(int size, int line, const char *file) 
{
    struct Buf *buf = new_buf( size );
    printf("NEW_BUF, %p, %d, %s\n", buf, line, file);
    return new_buf( size );
}

void del_buf_mark(struct Buf *buf, int line, const char *file) 
{
    printf("DEL_BUF, %p, %d, %s\n", buf, line, file);
    del_buf( buf );
}


struct Buf* new_buf(int size) 
{
    if ( size >= MAX_BUF_SIZE ) return NULL;
    struct Buf *b = (struct Buf*)calloc(sizeof(struct Buf), 1);
    if (b) {
        INIT_LIST_HEAD(&b->link);
        if (size <= BUF_SIZE) {
            size = BUF_SIZE;
            b->b = b->pool;  // notice
        } else {
            b->b = (char*)calloc(size, 1);
            __sync_fetch_and_add(&gBufExtra, size);
        }
        b->h = b->b;
        b->t = b->b;
        b->e = b->b + size;
        b->magic = 19780528;
        __sync_fetch_and_add(&gBufCount, 1);
        return b;
    }
    return NULL;
}


struct Buf* new_buf2(int size) 
{
    // todo
    // buf link queue, buf pool
    if ( size >= MAX_BUF_SIZE ) return NULL;
    struct Buf *b = (struct Buf*)calloc(sizeof(struct Buf), 1);
    if (b) {
        INIT_LIST_HEAD(&b->link);
        if (size <= BUF_SIZE) {
            size = BUF_SIZE;
            b->b = b->pool;  // notice
        } else {
            b->b = (char*)calloc(size, 1);
            __sync_fetch_and_add(&gBufExtra, size);
        }
        b->h = b->b;
        b->t = b->b;
        b->e = b->b + size;
        b->magic = 19780528;
        __sync_fetch_and_add(&gBufCount, 1);
        return b;
    }
    return NULL;
}


struct Buf *clone_buf(struct Buf *b)
{
    int size = b->t - b->h;
    struct Buf *n = new_buf(size);
    memcpy(n->h, b->h, size);
    n->t += size;
    n->sid = b->sid;
    n->pknum = b->pknum;
    n->mode = b->mode;
    n->magic = b->magic;
    return n;
}

int fill_buf(struct Buf *b, void *val, int len)
{
    if (!val) return 0;
    if (len <= 0 || len > BUF_SIZE) return 0;
    if (b->e - b->t >= len) {
        memcpy(b->t, val, len);
        b->t += len;
        return b->e-b->t;
    }

    int remain = b->t - b->h;
    unsigned int size = (remain + len + BUF_SIZE);
    size -= (size % BUF_SIZE);
    char *p = (char*)calloc(size, 1);
    memcpy(p, b->h, remain);
    memcpy(p+remain, val, len);

    if (b->b != b->pool) free(b->b);

    b->h = p;
    b->b = p;
    b->t = p+remain+len;
    b->e = p + size;
    return b->e - b->t;
}

