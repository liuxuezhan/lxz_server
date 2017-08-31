#ifndef DBG_H
#define DBG_H

void create_dbg(int port);
int recv_debugq( struct list_head *q);
void ack_dbg(struct Buf *buf);
extern int gTelDebug;

#endif
