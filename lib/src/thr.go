package main  
  
/* 
#include <stdio.h> 
#include <stdlib.h> 
#include <unistd.h> 
#include <string.h>
#include <stdint.h>

extern int create_lua();
#cgo linux LDFLAGS: -lm  -DLUA_USE_READLINE -ldl  -Wl,-E  -lrt  -ldl /home/lxz/skynet/lxzserver/lib/robot.so
 
*/  
import "C"  
  
func main() {  
    C.create_lua()
}  
  
