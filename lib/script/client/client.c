#include <netinet/in.h>    // for sockaddr_in
#include <sys/types.h>    // for socket
#include <sys/socket.h>    // for socket
#include <stdio.h>        // for printf
#include <stdlib.h>        // for exit
#include <string.h>        // for bzero

#include <ctype.h>
#include <limits.h>
#include <stddef.h>
#include <stdio.h>

/* maximum size (in bytes) for integral types */


//typedef unsigned __int8   uint8_t;

static inline void
write_size(uint8_t * buffer, int len) {
	buffer[0] = (len >> 8) & 0xff;
	buffer[1] = len & 0xff;
}

#if 0
static int
ltostring(lua_State *L) {
	void * ptr = lua_touserdata(L, 1);
	int size = luaL_checkinteger(L, 2);
	if (ptr == NULL) {
		lua_pushliteral(L, "");
	} else {
		lua_pushlstring(L, (const char *)ptr, size);
		skynet_free(ptr);
	}
	return 1;
}
#endif



#if 1

#define HELLO_WORLD_SERVER_PORT    88880
#define BUFFER_SIZE 1024

int main(int argc, char **argv)
{


    //设置一个socket地址结构client_addr,代表客户机internet地址, 端口
    struct sockaddr_in client_addr;
    bzero(&client_addr,sizeof(client_addr)); //把一段内存区的内容全部设置为0
    client_addr.sin_family = AF_INET;    //internet协议族
    client_addr.sin_addr.s_addr = htons(INADDR_ANY);//INADDR_ANY表示自动获取本机地址
    client_addr.sin_port = htons(0);    //0表示让系统自动分配一个空闲端口
    //创建用于internet的流协议(TCP)socket,用client_socket代表客户机socket
    int client_socket = socket(AF_INET,SOCK_STREAM,0);
    if( client_socket < 0)
    {
        printf("Create Socket Failed!\n");
        exit(1);
    }
    //把客户机的socket和客户机的socket地址结构联系起来
    if( bind(client_socket,(struct sockaddr*)&client_addr,sizeof(client_addr)))
    {
        printf("Client Bind Port Failed!\n");
        exit(1);
    }

    //设置一个socket地址结构server_addr,代表服务器的internet地址, 端口
    struct sockaddr_in server_addr;
    bzero(&server_addr,sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    if(inet_aton("127.0.0.1",&server_addr.sin_addr) == 0) //服务器的IP地址来自程序的参数
    {
        printf("Server IP Address Error!\n");
        exit(1);
    }
    server_addr.sin_port = htons(HELLO_WORLD_SERVER_PORT);
    socklen_t server_addr_length = sizeof(server_addr);
    //向服务器发起连接,连接成功后client_socket代表了客户机和服务器的一个socket连接
    if(connect(client_socket,(struct sockaddr*)&server_addr, server_addr_length) < 0)
    {
        printf("Can Not Connect To 127.0.0.1!\n");
        exit(1);
    }



	 char* ptr={"我们"};
	 size_t size = strlen(ptr);
	if (size > 0x10000) {
		return printf( "Invalid size (too long) of data : %d", (int)size);
	}

	uint8_t * buf = malloc(size + 2);
	write_size(buf, size);
	memcpy(buf+2, ptr, size);

	size=size+2;

    //向服务器发送buf中的数据
    send(client_socket,buf,size,0);

//    int fp = open(file_name, O_WRONLY|O_CREAT);
//    if( fp < 0 )

    //从服务器接收数据到buf中

	uint8_t * buf1 = malloc(512);

    int length = 0;
    while( length = recv(client_socket,buf1,75,0))
    {
		printf("buf=%s\n",buf1);
        if(length < 0)
        {
            printf("Recieve Data From Server Failed!\n");
            break;
        }
//        int write_length = write(fp, buf,length);
      //  printf("rev:%s\n",buf);

    }
    printf("Recieve File From Server Finished\n");

    //关闭socket
    close(client_socket);
    return 0;
}
#endif
