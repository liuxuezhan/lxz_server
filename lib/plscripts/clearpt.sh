#!/bin/bash

if [ $# == 1 ]
then
    mysql -h192.168.103.240 --port=3306 -uroot -proot -Dcommon_warx -e"delete from player_server where logic = $1"
    echo "execute successful!"
else
    echo "you must set a serverid!"
fi

