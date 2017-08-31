#ifndef NET_H
#define NET_H
#include <event2/event.h>
#include "mylist.h"
#include "buf.h"


int init_net();
int start_listen(int port, int encrypt);
int start_tick();
pthread_t start_net();
int recv_bufq(struct list_head *q);
void send_bufq(struct list_head *q);
void send_buf(struct Buf *b, int sid);
void send_command(int pt, int a0, int a1, int a2, int a3);
void disconnect(int sid);
int connect_to(const char *ip, int port, int encrypt, int mode);

#endif
