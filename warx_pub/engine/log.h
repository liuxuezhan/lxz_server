#ifndef LOG_H
#define LOG_H

void init_log(const char*tip);
void LOG(const char *fmt, ...);
void INFO(const char *fmt, ...);
void WARN(const char *fmt, ...);
void dump(void* src, int len, const char *tip );

#endif
