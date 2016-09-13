#!/bin/sh

if [ $# == 1 ]
then
    if [ $1 == "warx" ]
    then
        sed -i "s/preload*/preload = 'data/define_warx.lua' /g" data/skynet.conf
    else
        sed -i "s/preload*/preload = 'data/def.lua' /g" data/skynet.conf
    fi

    sed -i "s/start.*/start = '$1' /g" data/skynet.conf
    skynet/skynet data/skynet.conf
else
    echo "you must set lua_file "
fi
