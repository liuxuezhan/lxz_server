//
// $Id: timer.h 31014 2007-11-02 02:54:12Z loon $
//

#ifndef __TIMER_MNG_H__
#define __TIMER_MNG_H__

#include "mylist.h"

#define TVN_BITS 6
#define TVR_BITS 8
#define TVN_SIZE (1 << TVN_BITS)
#define TVR_SIZE (1 << TVR_BITS)
#define TVN_MASK (TVN_SIZE - 1)
#define TVR_MASK (TVR_SIZE - 1)
#define NOOF_TVECS 5

//#define TIMER_TICK 50
#define TIMER_TICK 10

typedef struct {
	struct list_head link;
	unsigned long expires;
	long id;
	long tag;
    int d1;
} timer_list;
	
struct timer_vec {
	int index;
	struct list_head vec[TVN_SIZE];
};

struct timer_vec_root {
	int index;
	struct list_head vec[TVR_SIZE];
};

void add_timer(long expires, long id, long tag);
void start_timer();
int recv_timerq(struct list_head *q);

int timer_time_set_start(unsigned int curSec);
int timer_time_step(unsigned int curSec);

#endif

