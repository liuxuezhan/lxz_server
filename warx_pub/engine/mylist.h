// This file is part of XeroEngine
// Copyright (c) 2009
//
// $Id: mylist.h 44 2009-02-17 02:22:39Z eric $
//

#ifndef _LIST_H
#define _LIST_H

#include <stddef.h>

struct list_head {
        struct list_head *next, *prev;
};

#define LIST_HEAD_INIT(name) { &(name), &(name) }

#define LIST_HEAD(name) \
        struct list_head name = LIST_HEAD_INIT(name)

#define INIT_LIST_HEAD(ptr) do { \
        (ptr)->next = (ptr); (ptr)->prev = (ptr); \
} while (0)

/*
 * Insert a new entry between two known consecutive entries. 
 *
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 */
static inline void __list_add(struct list_head * it, struct list_head * prev, struct list_head * next)
{
        next->prev = it;
        it->next = next;
        it->prev = prev;
        prev->next = it;
}

/**
 * list_add - add a new entry
 * @new: new entry to be added
 * @head: list head to add it after
 *
 * Insert a new entry after the specified head.
 * This is good for implementing stacks.
 */
static inline void LIST_ADD(struct list_head *it, struct list_head *head)
{
        __list_add(it, head, head->next);
}

/**
 * list_add_tail - add a new entry
 * @new: new entry to be added
 * @head: list head to add it before
 *
 * Insert a new entry before the specified head.
 * This is useful for implementing queues.
 */
static inline void LIST_ADD_TAIL(struct list_head *it, struct list_head *head)
{
        __list_add(it, head->prev, head);
}

/*
 * Delete a list entry by making the prev/next entries
 * point to each other.
 *
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 */
static inline void __list_del(struct list_head * prev,
                                  struct list_head * next)
{
        next->prev = prev;
        prev->next = next;
}

/**
 * list_del - deletes entry from list.
 * @entry: the element to delete from the list.
 * Note: list_empty on entry does not return true after this, the entry is in an undefined state.
 */
static inline void LIST_DEL(struct list_head *entry)
{
        __list_del(entry->prev, entry->next);
}

/**
 * list_del_init - deletes entry from list and reinitialize it.
 * @entry: the element to delete from the list.
 */
static inline void LIST_DEL_INIT(struct list_head *entry)
{
        __list_del(entry->prev, entry->next);
        INIT_LIST_HEAD(entry); 
}

/**
 * list_empty - tests whether a list is empty
 * @head: the list to test.
 */
static inline int LIST_EMPTY(struct list_head *head)
{
        return head->next == head;
}

static inline void LIST_ASSIGN( struct list_head *dest, struct list_head* src )
{
    *dest = *src;
    if( LIST_EMPTY( src ) ) {
        INIT_LIST_HEAD( dest );
    } else {
        src->next->prev = dest;
        src->prev->next = dest;
    } 
}

/**
 * list_splice - join two lists
 * @list: the new list to add.
 * @head: the place to add it in the first list.
 */
static inline void LIST_SPLICE(struct list_head *list, struct list_head *head)
{
        struct list_head *first = list->next;

        if (first != list) {
                struct list_head *last = list->prev;
                struct list_head *at = head->next;

                first->prev = head;
                head->next = first;

                last->next = at;
                at->prev = last;
        }
}

/**
 * list_splice - join two lists
 * @list: the new list to add.
 * @head: the place to add it in the first list.
 */
static inline void LIST_SPLICE_TAIL(struct list_head *list, struct list_head *head)
{
        if(!LIST_EMPTY(list) ) {
            struct list_head *first = list->next;
            struct list_head *last = list->prev;
            struct list_head *at = head->prev;
            
            at->next = first;
            first->prev = at;

            last->next = head;
            head->prev = last;
        }
}



/**
 * list_entry - get the struct for this entry
 * @ptr:        the &struct list_head pointer.
 * @type:       the type of the struct this is embedded in.
 * @member:     the name of the list_struct within the struct.
 */
#define LIST_ENTRY(ptr, type, member) \
 		((type *)((char *)(ptr) + 1 - (unsigned long)(&((type *)1)->member)))

 		//((type *)((char *)(ptr) - offsetof(type,member)))

/**
 * list_for_each        -       iterate over a list
 * @pos:        the &struct list_head to use as a loop counter.
 * @head:       the head for your list.
 */
#define LIST_FOR_EACH(pos, head) \
        for (pos = (head)->next; pos != (head); pos = pos->next)
                
/*
#define list_for_each_safe(pos, n, head) \
        for (pos = (head)->next, n = pos->next; pos != (head); pos = n, n = pos->next)
*/
#define LIST_FOR_EACH_SAFE(pos, shit_pos, head) \
        for (pos = (head)->next, shit_pos = pos->next; pos != (head); pos = shit_pos, shit_pos = pos->next)
/**
 * list_for_each_prev   -       iterate over a list in reverse order
 * @pos:        the &struct list_head to use as a loop counter.
 * @head:       the head for your list.
 */
#define LIST_FOR_EACH_PREV(pos, head) \
        for (pos = (head)->prev; pos != (head); pos = pos->prev )


#endif



