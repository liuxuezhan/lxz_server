#ifndef BUF_H
#define BUF_H

#include "mylist.h"

#define BUF_SIZE (16 * 1024)
#define MAX_BUF_SIZE (0x0F00000)
#define DUL_BUF (32 * 1024)
#define HLF_BUF (8 * 1024)

struct Buf {
        struct list_head link;
        char *h, *t, *b, *e;    // head, tail, begin, end
        unsigned int sid;   // client id; gate id
        unsigned int pknum;     // packet num
        int mode;                // for special use
        int magic;
        int from;
        char pool[BUF_SIZE];
};

void del_buf(struct Buf* buf);
void del_buf_mark(struct Buf *buf, int line, const char *file);
struct Buf* new_buf(int size);
struct Buf* new_buf_mark(int size, int line, const char* file);
struct Buf* clone_buf(struct Buf *buf);
int fill_buf(struct Buf *b, void *val, int len);

#endif
