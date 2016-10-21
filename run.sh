#!/bin/sh  
if [ $# -gt 1 ];then
    ip=$1
    path=${2%/*}
    name=${2##*/}
    name=${name%.*}

    if [ $name != ""  ]; then
        if [ $name == "robot_t"  ]; then
            lib/robot $path/robot_t.lua
        elif [ $path == "warx_pub"  ]; then
            sed -i "s/g_host.*/g_host = \"$ip\" /g" $path/etc/def.lua
            skynet/skynet $path/etc/skynet.conf
        else
            sed -i "s/preload.*/preload = \"$path\/etc\/def.lua\" /g" $path/etc/skynet.conf
            sed -i "s/start.*/start = \"$path\/$name\" /g" $path/etc/skynet.conf
            sed -i "s/cluster.*/cluster = \"$path\/etc\/clustername.lua\" /g" $path/etc/skynet.conf

            sed -i "s/login1.*/login1 = \"$ip:2528\" /g" $path/etc/clustername.lua
            sed -i "s/game1.*/game1 = \"$ip:2529\" /g" $path/etc/clustername.lua

            sed -i "s/g_host.*/g_host = \"$ip\" /g" $path/etc/def.lua
            skynet/skynet $path/etc/skynet.conf
        fi
    else
        echo "没文件名 "
    fi

else
    echo "指定ip,目录/文件名 "
fi
