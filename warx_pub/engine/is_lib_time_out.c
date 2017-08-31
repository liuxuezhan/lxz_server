#include <time.h>
#include "log.h"

#define YEAR ((((__DATE__ [7] - '0') * 10 + (__DATE__ [8] - '0')) * 10 + (__DATE__ [9] - '0')) * 10 + (__DATE__ [10] - '0'))

#define MONTH (__DATE__ [2] == 'n' ? (__DATE__[1] == 'a' ? 0 : 5)  \
        : __DATE__ [2] == 'b' ? 1 \
        : __DATE__ [2] == 'r' ? (__DATE__ [0] == 'M' ? 2 : 3) \
        : __DATE__ [2] == 'y' ? 4 \
        : __DATE__ [2] == 'l' ? 6 \
        : __DATE__ [2] == 'g' ? 7 \
        : __DATE__ [2] == 'p' ? 8 \
        : __DATE__ [2] == 't' ? 9 \
        : __DATE__ [2] == 'v' ? 10 : 11)

#define DAY ((__DATE__ [4] == ' ' ? 0 : __DATE__ [4] - '0') * 10 + (__DATE__ [5] - '0'))

#define DATE_AS_INT (((YEAR - 1900) * 12 + MONTH) * 31 + DAY)

//故意放宽限制条件到120天
#define LIB_TIMEOUT_DAY 120

int is_lib_time_out()
{
#ifdef DEBUG
    return 0;
#else
    time_t timep;
    struct tm *p; 
    time(&timep);
    p=gmtime(&timep);
    //注意tm_year已经是距离1900的年数
    long date_as_int = (p->tm_year * 12 + p->tm_mon) * 31 + p->tm_mday;
    if( date_as_int <= DATE_AS_INT + LIB_TIMEOUT_DAY )
    {   
        if( date_as_int >= DATE_AS_INT + (LIB_TIMEOUT_DAY/2) )
        {   
            WARN( "[MISC]LIB WILL TIMEOUT, PLEASE REBUILD LIB" );
            return -1; 
        }   
        return 0;
    }   
    WARN( "[MISC]LIB ALREADY TIMEOUT, PLEASE REBUILD LIB" );
    return 1;  
#endif
}
