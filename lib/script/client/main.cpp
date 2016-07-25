#include <iostream>
#include <sys/syscall.h>

#include <string.h>
#include <stdint.h>
#include <pthread.h>
#include <stdlib.h>
#include <signal.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>

extern "C"
{
    #include <stdio.h>
    #include <lua.h>
    #include <lualib.h>
    #include <lauxlib.h>
}
int  m_bProcExit = 0;
int  m_exitnum = 0;

#define ISQ_SYSTEM_VERSION  "lxz_server-debug-2015.8.25"

char* reload_lua(lua_State* L,char* path)
{
    luaL_openlibs(L);
    if (luaL_dofile(L, path) != 0)
    {
          printf(lua_tostring(L,-1));
          lua_pop(L, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */
    }

    return NULL;
}

class CThread
{
public:
    pthread_attr_t attr;
    CThread(int lv)
    {
        m_bRunning = false;
        m_pid = 0;
        int ret = pthread_attr_init(&attr);
        ret = pthread_attr_setscope (&attr, PTHREAD_SCOPE_SYSTEM);
        ret = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
        ret = pthread_attr_setschedpolicy(&attr, SCHED_RR);
        struct sched_param sched;
        sched.sched_priority = lv;
        ret = pthread_attr_setschedparam(&attr,&sched);
    }
    virtual ~CThread(void)
    {
        if (m_bRunning) { Stop(); }
    }
public:
    pthread_t m_hThread;
    pid_t m_pid;
    static void* ThreadFunc(void* pParam = NULL)
    {
        m_exitnum++;
        CThread* pThread = (CThread*)pParam;
        pthread_detach(pthread_self());
        if ( NULL != pThread ) {   pThread->Run();  }
        return NULL;
    }
    void   Run(void)
    {
        m_pid = syscall(SYS_gettid);
        printf("创建线程%d[%lu]\n",m_exitnum,m_pid);

        m_bRunning = true;

        Execute();
        m_bRunning = false;
        m_exitnum--;
        printf("退出线程%d[%lu]\n",m_exitnum,m_pid);

        Destory();
    }

    bool   Start(void)
    {
        if (m_bRunning){   return false; }

        if ( !OnStart() ) { return m_bRunning;}

        if (pthread_create(&m_hThread, &attr, ThreadFunc, (void*)this) != 0)
        {
            return m_bRunning;
        }

        m_bRunning = true;
        return m_bRunning;
    }

    void   Stop(void)
    {
        m_bRunning = false;
        OnStop();
    }

    bool   IsRunning(void) const
    {
        return m_bRunning;
    }

protected:

    void   Destory(void){ pthread_exit(NULL);}
    virtual bool  OnStart(void){return true;}
    virtual void  OnStop(void){};
    virtual void  Execute(void) = 0;
private:

private:
    bool      m_bRunning;
};


class ROBOT : public CThread
{
public:
    ROBOT(uint32_t n) :m_id(n),CThread(99)
    {
        m_l = NULL;
		cmd = 0;
		sp = 0;
    };
    virtual ~ROBOT(void){};
public:
    lua_State* m_l;
	int cmd;
	int sp;
private:
    uint32_t    m_id;// 子线程ID

    bool OnStart(void)
    {
		/*调用lua函数处理消息并返回*/
		lua_getglobal(m_l, "robot_init");
		lua_pushnumber(m_l, m_id);

		if (lua_pcall(m_l, 1, 0, 0) != 0) /* pcall(Lua_state, 参数个数, 返回值个数, 错误处理函数所在的索引)，最后一个参数暂时先忽略 */
		{
			printf("-----(%d)--------(%s)\n", __LINE__,lua_tostring(m_l,-1));
			lua_pop(m_l, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */
			return false;
		}

		lua_pop(m_l, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */
        return true;
    }
    void Execute(void)  // 功能: 事务处理者线程接口
    {

        while (CThread::IsRunning())
        {

            if (1==m_bProcExit) { break;}

			if (sp>=cmd ) {
				sleep(1);
				continue;
			}


			/*调用lua函数处理消息并返回*/
			lua_getglobal(m_l, "robot_start");

			if (lua_pcall(m_l, 0, 1, 0) != 0) /* pcall(Lua_state, 参数个数, 返回值个数, 错误处理函数所在的索引)，最后一个参数暂时先忽略 */
			{
				printf("-----(%d)--------(%s)\n", __LINE__,lua_tostring(m_l,-1));
				lua_pop(m_l, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */
				break;
			}

			int ret = lua_tonumber(m_l, -1);
			lua_pop(m_l, 1);/* 将返回值弹出堆栈，将堆栈恢复到调用前的样子 */

			if (ret==1) {
				break;
			}
			sp ++;
        }
		lua_close(m_l);

    }

    void OnStop(void){};

};

class SERVER : public CThread
{
public:
	ROBOT * m_probot[10000]={NULL};
	int m_num;
	int cmd;
    lua_State* m_l;

    SERVER(uint32_t i):m_num(i),CThread(99)
    {

		cmd=0;

		// 创建子线程
        for (uint32_t n = 0 ; n < m_num ; n ++)
        {
            m_probot[n] = new ROBOT(n);
			m_probot[n]->m_l =  luaL_newstate();

			reload_lua(m_probot[n]->m_l, "client.lua");
        }

        if (!Start()) //创建一个主线程
        {
            printf("server start fail, main exit\n");
        }

    };

    virtual ~SERVER(void){};

	bool OnStart(void)
    {

        for (uint32_t n = 0 ; n < m_num ; n ++)
        {
            if (NULL != m_probot[n]){

				m_probot[n]->Start();
			}
        }

        return true;
    };

	void   Execute(void){
		while (1)
		{
			sleep(1);
			//判断子线程状态
			int f =0;
			for (uint32_t n = 0 ; n < m_num ; n ++)
			{
				if (m_probot[n]->sp != m_probot[n]->cmd){
					f =1;
					break;
				}
			}
			if (f==1) {	continue;}


			printf("请输入执行几步:");
			scanf("%d",&cmd);

			for (uint32_t n = 0 ; n < m_num ; n ++)
			{
				m_probot[n]->cmd = cmd;
				m_probot[n]->sp = 0;
			}
		}

	};//新建线程运行的函数

protected:

private:

};


SERVER* pMgr=NULL;


void CatchSysSignal(int iSignal);
void sig_reload_lua_1()
{

}

void sig_reload_lua_2()
{

}

void server_quit()
{

    delete pMgr;
}

void CatchSysSignal(int iSignal)
{

    printf( "捕获信号: [%d ]",iSignal);

    switch(iSignal)
    {
    case SIGUSR1:
        {
            sig_reload_lua_1();
            break;
        }
    case SIGUSR2:
        {
            sig_reload_lua_2();
            break;
        }
    case SIGINT:
    case SIGTERM:
    case SIGSYS:
    case SIGTRAP:
        {//正常退出
            server_quit();
            exit(0);
        }
    case SIGILL:
    case SIGQUIT:
    case SIGBUS:
    case SIGSEGV:
    case SIGFPE:
    case SIGXCPU:
    case SIGXFSZ:
        {//非法退出
        //    server_quit();
            abort();
        }
    default:
        break;
    }
}

void InstallSysSignal(void)
{
    struct sigaction sigact;
    struct sigaction old;

    sigact.sa_handler = CatchSysSignal;
    sigfillset(&sigact.sa_mask);//执行时屏蔽所有信号
    sigact.sa_flags = 0;

    if (sigaction(SIGINT, &sigact, &old) < 0)
    {
        printf( "安装信号失败: SIGINT");
    }
    if (sigaction(SIGTERM, &sigact, NULL) < 0)
    {
        printf( "安装信号失败: SIGTERM");
    }
    if (sigaction(SIGQUIT, &sigact, NULL) < 0)
    {
        printf("安装信号失败: SIGQUIT");
    }

    if (sigaction(SIGHUP, &sigact, NULL) < 0)
    {
        printf( "安装信号失败: SIGHUP");
    }
    if (sigaction(SIGUSR1, &sigact, NULL) < 0)
    {
        printf( "安装信号失败: SIGUSR1");
    }
    if (sigaction(SIGUSR2, &sigact, NULL) < 0)
    {
        printf( "安装信号失败: SIGUSR2");
    }
    if (sigaction(SIGALRM, &sigact, NULL) < 0)
    {
        printf( "安装信号失败: SIGALRM");
    }
    if (sigaction(SIGSYS, &sigact, NULL) < 0)
    {
		printf( "安装信号失败: SIGSYS");
    }

    if (sigaction(SIGBUS, &sigact, NULL) < 0)
    {
        printf( "安装信号失败: SIGBUS");
    }
    if (sigaction(SIGILL, &sigact, NULL) < 0)
    {
        printf( "安装信号失败: SIGILL");
    }

    if (sigaction(SIGFPE, &sigact, NULL) < 0)
    {
        printf( "安装信号失败: SIGFPE");
    }

    if (sigaction(SIGSEGV, &sigact, NULL) < 0)
    {
        printf( "安装信号失败: SIGSEGV");
    }

    if (sigaction(SIGTRAP, &sigact, NULL) < 0)
    {
        printf( "安装信号失败: SIGTRAP");
    }

    if (sigaction(SIGXCPU, &sigact, NULL) < 0)
    {
        printf("安装信号失败: SIGXCPU");
    }

    if (sigaction(SIGXFSZ, &sigact, NULL) < 0)
    {
        printf( "安装信号失败: SIGXFSZ");
    }

}

void ShowSysVersion( void )
{
    char szVer[64] = {0};

    sprintf(szVer, "版本: %s 编译时间: %s %s", ISQ_SYSTEM_VERSION, __DATE__, __TIME__);
    printf("%s\n",szVer);
}



int32_t main(int32_t argc, char** argv)
{
	int i = 1;

	if (argc > 1 ) {
		i = atoi(argv[1]);
	}

    signal(SIGPIPE, SIG_IGN);//socket连接断开不处理


    InstallSysSignal();//安装信号

    pMgr= new SERVER(i);

    while (1) {

      //  printf("未退出线程数 = %d\n",m_exitnum);
        sleep(1);
    }

    return 0;
}
