#include "que.h"

void QueInit(Que *q)
{
    INIT_LIST_HEAD(&q->chain);
    pthread_mutex_init(&q->mut, NULL);
    pthread_cond_init(&q->cond, NULL);
    q->wait = 0;
}

struct list_head* QueGet(Que *q)
{
    struct list_head *pos = NULL;
    pthread_mutex_lock(&q->mut);

    while (LIST_EMPTY(&q->chain)) {
        q->wait += 1;
        pthread_cond_wait(&q->cond, &q->mut);
        q->wait -= 1;
    }
    pos = q->chain.next;
    LIST_DEL(pos);
    pthread_mutex_unlock(&q->mut);
    return pos;
}

void QueGetAll(Que *q, struct list_head *head)
{
    pthread_mutex_lock(&q->mut);
    while (LIST_EMPTY(&q->chain)) {
        q->wait += 1;
        pthread_cond_wait(&q->cond, &q->mut);
        q->wait -= 1;
    }
    LIST_SPLICE_TAIL( &q->chain, head );
    INIT_LIST_HEAD(&q->chain);
    pthread_mutex_unlock(&q->mut);
}



void QuePut(Que *q, struct list_head *it)
{
    int sig = 0;
    pthread_mutex_lock(&q->mut);
    LIST_ADD_TAIL(it, &q->chain);
    sig = q->wait;
    pthread_mutex_unlock(&q->mut);
    if (sig) pthread_cond_signal(&q->cond);
}

void QuePutAll(Que *q, struct list_head *it)
{
    int sig = 0;
    pthread_mutex_lock(&q->mut);
    LIST_SPLICE_TAIL( it, &q->chain );
    sig = q->wait;
    pthread_mutex_unlock(&q->mut);
    if (sig) pthread_cond_signal(&q->cond);
}


struct list_head* QueTry(Que *q)
{
    if (LIST_EMPTY(&q->chain)) return NULL;

    struct list_head *pos = NULL;
    pthread_mutex_lock(&q->mut); 
    if (!LIST_EMPTY(&q->chain)) {
        pos = q->chain.next;
        LIST_DEL(pos);
    }
    pthread_mutex_unlock(&q->mut);
    return pos;
}

int QueTryAll(Que *q, struct list_head *head)
{
    if (LIST_EMPTY(&q->chain)) return 0;
    int flag = 0;
    pthread_mutex_lock(&q->mut); 
    if (!LIST_EMPTY(&q->chain)) {
        LIST_SPLICE_TAIL(&q->chain, head);
        INIT_LIST_HEAD(&q->chain);
        flag = 1;
    }
    pthread_mutex_unlock(&q->mut);
    return flag;
}

int QuePeek(Que *q)
{
    if (LIST_EMPTY(&q->chain)) return 0;
    return 1;
}

