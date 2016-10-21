#!/bin/sh
if [ $# -gt 1 ];then
    if [ $# -gt 2 ]; then
        #1:目录 2：服务器名 3：ip

        sed -i "s/preload.*/preload = \"$1\/etc\/def.lua\" /g" $1/etc/skynet.conf
        sed -i "s/start.*/start = \"$1\/$2\" /g" $1/etc/skynet.conf
        sed -i "s/cluster.*/cluster = \"$1\/etc\/clustername.lua\" /g" $1/etc/skynet.conf

        sed -i "s/login1.*/login1 = \"$3:2528\" /g" $1/etc/clustername.lua
        sed -i "s/game1.*/game1 = \"$3:2529\" /g" $1/etc/clustername.lua

        sed -i "s/g_host.*/g_host = \"$3\" /g" $1/etc/def.lua
    else
        #1:目录 2:ip
        sed -i "s/g_host.*/g_host = \"$2\" /g" $1/etc/def.lua
    fi
    skynet/skynet $1/etc/skynet.conf

else
    echo "指定ip,目录 "
fi
