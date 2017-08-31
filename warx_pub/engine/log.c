#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <syslog.h>
#include <stdarg.h>
#include "log.h"

static int gInitLog = 0;

void init_log(const char* tip) 
{
    gInitLog = 1;
    openlog(tip, 0, LOG_LOCAL0) ;
}

void LOG(const char *fmt, ...)
{
    if (!gInitLog) {
        openlog(NULL, 0, LOG_LOCAL0) ;
        gInitLog = 1;
    }

    char str[16384] = {0,};
    va_list ap;
    va_start(ap, fmt);
    int len = vsnprintf(str, sizeof(str)-1, fmt, ap);
    va_end(ap);
    str[len] = '\0';

    //vsyslog(LOG_LOCAL0|LOG_DEBUG, fmt, ...);
    syslog(LOG_LOCAL0|LOG_DEBUG, "%.*s", len, str);
}

void INFO(const char *fmt, ...)
{
    char str[16384] = {0,};
    va_list ap;
    va_start(ap, fmt);
    int len = vsnprintf(str, sizeof(str)-1, fmt, ap);
    va_end(ap);
    str[len] = '\0';

    //printf("%s\n", str);

    syslog(LOG_LOCAL0|LOG_INFO, "%.*s", len, str);
    //fprintf(stderr, "%.*s\n", len, str);
    //fflush(stderr);
}

#define RED                  "\e[0;31m"
#define L_RED                "\e[1;31m"
void WARN(const char *fmt, ...)
{
    char str[16384] = {0,};
    va_list ap;
    va_start(ap, fmt);
    int len = vsnprintf(str, sizeof(str)-1, fmt, ap);
    va_end(ap);
    str[len] = '\0';

    //printf("%s\n", str);

    syslog(LOG_LOCAL0|LOG_NOTICE, "%.*s", len, str);
    fprintf(stderr, "\e[0;31m");
    fprintf(stderr, "%.*s\n", len, str);
    fprintf(stderr, "\e[0m");
    fflush(stderr);
}


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
        INFO("%s | %s", tip, val);
        line++; 

        //return; // extra, kill dump
    }    
}

