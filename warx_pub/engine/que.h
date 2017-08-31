#ifndef _QUE_H_
#define _QUE_H_

#include <pthread.h>
#include "mylist.h"

typedef struct {
    struct list_head chain;
    pthread_mutex_t mut;
    pthread_cond_t cond;
    int wait;
} Que;

void QueInit(Que *q);
struct list_head* QueGet(Que *q);
void QueGetAll(Que *q, struct list_head *head);
void QuePut(Que *q, struct list_head *it);
void QuePutAll(Que *q, struct list_head *it);
struct list_head* QueTry(Que *q);
int QueTryAll(Que *q, struct list_head *head);
int QuePeek(Que *q);

#endif

