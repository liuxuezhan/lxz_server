#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <string.h>
#include <stdint.h>
#include <pthread.h>
#include <stdlib.h>

#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>


void dump(void* src, int len, const char *tip )
{
    int lc = 16;
    int pos = 0;
    int line = 0;
    int tmplen;
    int i;
    unsigned int X;
    char node[4];

    char val[ 256 ] = { 0, };
    char part3[ 16 + 1 ] = { 0, };
    for( ; len > 0; len -= lc ) {
        memset( val, 0, sizeof(val) );
        memset( part3, 0, sizeof(part3) );

        sprintf( val, "%08X : ", line );
        tmplen = len;
        if( tmplen > lc ) tmplen = lc;
        for( i = 0; i < tmplen; ++i ) {
            X = *(unsigned char*)((unsigned char*)src+pos);
            pos++;
            //*(unsigned int*)node = 0;
            sprintf( node, "%02X ", X );
            strcat( val, node );

            memset( node, 0, sizeof(node) );
            if( X >= '!' && X <= '~' ) {
                node[ 0 ] = X;
            } else {
                node[ 0 ] = '.';
            }
            strcat( part3, node );
        }

        for( ; i < lc; ++i ) {
            strcat( val, "   " );
        }

        strcat( val, " ; " );
        strcat( val, part3 );
        printf("%s | %s\n", tip, val);
        line++;

        //return; // extra, kill dump
    }
}

//----------------------------------socker处理--------------------------------------

#define CACHE_SIZE 0x1000

static int
lconnect(lua_State *L) {
	const char * addr = luaL_checkstring(L, 1);
	int port = luaL_checkinteger(L, 2);
	int fd = socket(AF_INET,SOCK_STREAM,0);
	struct sockaddr_in my_addr;

	my_addr.sin_addr.s_addr=inet_addr(addr);
	my_addr.sin_family=AF_INET;
	my_addr.sin_port=htons(port);

	int r = connect(fd,(struct sockaddr *)&my_addr,sizeof(struct sockaddr_in));

	if (r == -1) {
		luaL_error(L, "Connect %s %d failed", addr, port);
		lua_pushinteger(L, 0);
		return 1;
	}

	int flag = fcntl(fd, F_GETFL, 0);
	fcntl(fd, F_SETFL, flag | O_NONBLOCK);

	lua_pushinteger(L, fd);

	return 1;
}

static int
lclose(lua_State *L) {
	int fd = luaL_checkinteger(L, 1);
	close(fd);

	return 0;
}

static void
block_send(lua_State *L, int fd, const char * buffer, int sz) {
	while(sz > 0) {
		int r = send(fd, buffer, sz, 0);
		if (r < 0) {
			if (errno == EAGAIN || errno == EINTR)
				continue;
			luaL_error(L, "socket error: %s", strerror(errno));
		}
		buffer += r;
		sz -= r;
	}
}

/*
	integer fd
	string message
 */
static int
lsend(lua_State *L) {
	size_t sz = 0;
	int fd = luaL_checkinteger(L,1);
	const char * msg = luaL_checklstring(L, 2, &sz);

    //dump(msg,sz,"send");
	block_send(L, fd, msg, (int)sz);

	return 0;
}

/*
	intger fd
	string last
	table result

	return
		boolean (true: data, false: block, nil: close)
		string last
 */

struct socket_buffer {
	void * buffer;
	int sz;
};

static int
lrecv(lua_State *L) {
	int fd = luaL_checkinteger(L,1);

   // printf("rev fd %d\n",fd);
	char len[4]={0};
	int r = recv(fd, len, 4, 0);
   // printf("rev head len %d\n",r);
   // dump(len,4,"head");
	if (r < 0) {
		if (errno == EAGAIN || errno == EINTR) {
			return 0;
		}
		luaL_error(L, "socket error: %s", strerror(errno));
	}
	if (r != 4) {
		luaL_error(L, "head len error: %s", r);
		lua_pushliteral(L, "");
		return 1;
	}

    int l = ntohl(*(int*)len);
    //printf("rev head len2 %d\n",l);

	char buffer[l];
	r = recv(fd, buffer, l, 0);
   // printf("rev head len3 %d\n",r);
   // dump(buffer,l,"data");
	if (r < 0) {
		if (errno == EAGAIN || errno == EINTR) {
			return 0;
		}
		luaL_error(L, "socket error: %s", strerror(errno));
	}
	if (r != l) {
		luaL_error(L, "data len error: %s", r);
		lua_pushliteral(L, "");
		return 1;
	}

	lua_pushlstring(L, buffer, r);
	return 1;
}

static int
lusleep(lua_State *L) {
	int n = luaL_checknumber(L, 1);
	usleep(n);
	return 0;
}

// quick and dirty none block stdin readline

#define QUEUE_SIZE 1024

struct queue {
	pthread_mutex_t lock;
	int head;
	int tail;
	char * queue[QUEUE_SIZE];
};

static void *
readline_stdin(void * arg) {
	struct queue * q = arg;
	char tmp[1024];
	while (!feof(stdin)) {
		if (fgets(tmp,sizeof(tmp),stdin) == NULL) {
			// read stdin failed
			exit(1);
		}
		int n = strlen(tmp) -1;

		char * str = malloc(n+1);
		memcpy(str, tmp, n);
		str[n] = 0;

		pthread_mutex_lock(&q->lock);
		q->queue[q->tail] = str;

		if (++q->tail >= QUEUE_SIZE) {
			q->tail = 0;
		}
		if (q->head == q->tail) {
			// queue overflow
			exit(1);
		}
		pthread_mutex_unlock(&q->lock);
	}
	return NULL;
}

static int
lreadstdin(lua_State *L) {
	struct queue *q = lua_touserdata(L, lua_upvalueindex(1));
	pthread_mutex_lock(&q->lock);
	if (q->head == q->tail) {
		pthread_mutex_unlock(&q->lock);
		return 0;
	}
	char * str = q->queue[q->head];
	if (++q->head >= QUEUE_SIZE) {
		q->head = 0;
	}
	pthread_mutex_unlock(&q->lock);
	lua_pushstring(L, str);
	free(str);
	return 1;
}

//----------------------------------二进制流处理--------------------------------------

int
luaopen_socket(lua_State *L) {


	 luaL_Reg s[] ={
				{ "connect", lconnect },
				{ "recv", lrecv },
				{ "send", lsend },
				{ "close", lclose },
				{ "usleep", lusleep },
				{ NULL, NULL },
	 };

     luaL_register(L, "socket",s);

	struct queue * q = lua_newuserdata(L, sizeof(*q));
	memset(q, 0, sizeof(*q));
	pthread_mutex_init(&q->lock, NULL);
	lua_pushcclosure(L, lreadstdin, 1);
	lua_setfield(L, -2, "readstdin");

	pthread_t pid ;
//	pthread_create(&pid, NULL, readline_stdin, q);

     return 1;
}


