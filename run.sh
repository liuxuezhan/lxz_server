#!/bin/sh

if [ $# -gt 0 ];then
    if [ $1 == "warx_pub" ]; then
        skynet/skynet $1/etc/skynet.conf
    else
        if [ $# -gt 1 ]; then
            sed -i "s/preload.*/preload = \"$1\/etc\/def.lua\" /g" $1/etc/skynet.conf
            sed -i "s/start.*/start = \"$1\/$2\" /g" $1/etc/skynet.conf
            sed -i "s/cluster.*/cluster = \"$1\/etc\/clustername.lua\" /g" $1/etc/skynet.conf
            skynet/skynet $1/etc/skynet.conf
        else
            echo "服务名字 "
        fi
    fi

else
    echo "指定目录 "
fi
