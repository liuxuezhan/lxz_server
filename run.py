#!/usr/bin/python
#coding=utf-8
import os
import datetime
import time
import sys
import re
import socket,fcntl,struct
from datetime import *

def get_ip(ifname):
        s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
        return socket.inet_ntoa(fcntl.ioctl(
                s.fileno(),
                0x8915,
                struct.pack('256s',ifname[:15])
        )[20:24])

if __name__ == "__main__":
   #ip = socket.gethostbyname(socket.gethostname())
    ip = get_ip("eth0")
    #ip = sys.argv[2]
   #print ip
    if len(sys.argv) < 2:
        print "输入路径"
        exit() 
    (path,name) = os.path.split(sys.argv[1])
    (name,ext) = os.path.splitext(name)
    print ip
    print path
    lua_path = "skynet/?.lua;skynet/lualib/?.lua;lib/?.lua;lualib/?.lua;lib/rpc/?.lua;?.lua;%s/?.lua"%(path)

    if name == "warx":
        lua_path = lua_path + ";%s/script_new/?.lua"%(path)

    if name == "robot_t":
        os.system("lib/robot %s"%(sys.argv[1]))
    else:

        lua_conf = '%s/etc/def.lua'%(path)
        data = re.sub("g_host.*", "g_host = \"%s\""%(ip), open(lua_conf).read())
        open(lua_conf, 'w').write(data)

        cluster = '%s/etc/clustername.lua'%(path)
        data = re.sub("login1.*", "login1 = \"%s:2528\""%(ip), open("lib/clustername.lua").read())
        data = re.sub("game1.*", "game1 = \"%s:2529\""%(ip),data )
        open(cluster, 'w').write(data)

        conf = '%s/etc/skynet.conf'%(path)
        data = re.sub(  "preload.*", "preload = \"%s\""%(lua_conf), open("lib/skynet.conf").read())
        data = re.sub(  "start.*",   "start = \"%s/%s\""%(path,name), data)
        data = re.sub(  "cluster.*", "cluster = \"%s\""%(cluster), data)
        data = re.sub(  "lua_path.*", "lua_path = \"%s\""%(lua_path), data)
        open(conf, 'w').write(data)

        os.system('skynet/skynet %s'%(conf))


