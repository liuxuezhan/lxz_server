#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
//#include <sys/wait.h>

void be_daemon()
{
    int i;
    pid_t pc = fork();
    if ( pc ) exit( 0 );

    setsid();
    chdir("/");
    umask(0);
    for(i=0; i<65536; i++) close(i);
}

