#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <pthread.h>
#include "que.h"
#include "buf.h"

Que gQueDbgPut;
Que gQueDbgGet;

#define PT_debugStart 1434361156
#define PT_debugInput 1828792140
#define PT_debugClose 1434361156

int gTelDebug = 0;

void* dbg(void *arg) 
{   
    gTelDebug = 1;
    QueInit(&gQueDbgPut);
    QueInit(&gQueDbgGet);

    struct Buf *buf = NULL;
    struct Buf *bufw = NULL;
    char *cur;
    struct list_head *pos;

    fd_set         fdread;   
    fd_set fdr, fdw, fde;

    char input[1024];

    int port = (long)arg;
    int sockfd,new_fd;
    struct sockaddr_in my_addr;
    struct sockaddr_in their_addr;
    int sin_size;

    if((sockfd = socket(AF_INET,SOCK_STREAM,0))==-1) {
        printf("create socket error");
        perror("socket");
        exit(1);
    }

    my_addr.sin_family = AF_INET;
    my_addr.sin_port = htons(port);
    my_addr.sin_addr.s_addr = INADDR_ANY;
    bzero(&(my_addr.sin_zero),8);

    int flag = 1;
    int len = sizeof(flag);
    setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR,  &flag, len);
    if(bind(sockfd,(struct sockaddr *)&my_addr,sizeof(struct sockaddr))==-1) {
        perror("bind socket error");
        exit(1);
    }

    if(listen(sockfd,10)==-1) {
        perror("listen");
        exit(1);
    }

    printf("start debug %d\n", port);

    while(1) {
        sin_size = sizeof(struct sockaddr_in);
        if((new_fd = accept(sockfd,(struct sockaddr *)&their_addr,(socklen_t*)&sin_size))==-1) {
            perror("accept");
            exit(1);
        }
        printf("accept debug input %d\n", new_fd);

        //buf = new_buf(0);
        //cur = buf->t;
        //*(int*)cur = htonl(8); cur+=4;
        //*(int*)cur = htonl(0); cur+=4;
        //*(int*)cur = htonl(PT_debugStart); cur+=4;
        //buf->t = cur;
        //buf->sid = new_fd;
        //QuePut(&gQueDbgGet, &buf->link);

        fcntl(new_fd, F_SETFL, O_NONBLOCK);

        struct timeval tv;
        int ret;
        struct list_head wq;

        bufw = NULL;
        INIT_LIST_HEAD(&wq);
        while (1) {
            QueTryAll(&gQueDbgPut, &wq);

            tv.tv_sec = 1;
            tv.tv_usec = 0;
            FD_ZERO(&fdr); FD_ZERO(&fdw); FD_ZERO(&fde);
            FD_SET(new_fd, &fdr);

            if (!bufw && LIST_EMPTY(&wq)) {
                ret = select(new_fd+1, &fdr, NULL, &fde, &tv); 
            } else {
                ret = select(new_fd+1, &fdr, &fdw, &fde, &tv); 
            }
            if (!ret) continue;
            if (ret < 0) break;
            if (FD_ISSET(new_fd, &fde)) break;

            if (FD_ISSET(new_fd, &fdr)) {
                memset(input, 0, sizeof(input));
                ret = recv(new_fd, input, sizeof(input), 0);
                if (ret <= 0) break;
                buf = new_buf(ret);
                cur = buf->t;
                cur += 4; // for len;
                *(int*)cur = 0; cur+=4; // pid
                *(int*)cur = htonl(PT_debugInput); cur+=4; // packet type
                *(unsigned short*)cur = htons(ret); cur+=2; //string length
                memcpy(cur, input, ret); cur+=ret;
                buf->t = cur;
                *(int*)(buf->h) = htonl(buf->t - buf->h - 4);
                QuePut(&gQueDbgGet, &buf->link);

            } else if(FD_ISSET(new_fd, &fdw)) {
                while (1) {
                    if (!bufw) {
                        if (!LIST_EMPTY(&wq)) {
                            pos = wq.next;
                            LIST_DEL(pos);
                            bufw = LIST_ENTRY(pos, struct Buf, link);
                        }
                    }
                    if (!bufw) break;

                    if (bufw->h < bufw->t) {
                        ret = send(new_fd, bufw->h, bufw->t - bufw->h, 0);
                        if (ret <= 0) break;
                        bufw->h += ret;
                        if (bufw->h == bufw->t) {
                            del_buf(bufw);
                            bufw = NULL;
                        } else {
                            break;
                        }
                    }
                }
            }
        }
        close(new_fd);
        //buf = new_buf(0);
        //cur = buf->t;
        //*(int*)cur = htonl(8); cur+=4;
        //*(int*)cur = htonl(0); cur+=4;
        //*(int*)cur = htonl(PT_debugClose); cur+=4;
        //buf->t = cur;
        //buf->sid = new_fd;
        //QuePut(&gQueDbgGet, &buf->link);
    }
}


void create_dbg(int port)
{
    long lp = port;
    pthread_t tid; 
    pthread_attr_t attr;
    pthread_attr_init(&attr); 
    pthread_create(&tid,&attr, dbg, (void*)lp);
    pthread_attr_destroy(&attr);
}

int recv_debugq( struct list_head *q)
{
    return QueTryAll(&gQueDbgGet, q);
}

void ack_dbg(struct Buf *buf)
{
    QuePut(&gQueDbgPut, &buf->link);
}

