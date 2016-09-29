#!/bin/bash

if [ $# > 2 ];then
    timestamp=`date +%s`
    if [ $# > 3 ];then
        mysql -h192.168.103.240 --port=3306 -uroot -proot -Dcommon_warx -e"delete from sns_tbl where  locate('$1',device_id)> 0 "
    fi

    start=$2
    sum=`expr $3 + 1`
    while [ $start -lt $sum ]
    do
        did=$1$start 
        open_id=$1$start
        max=$(($start%1500))

        if [ $max = 1 ];then
            value=${value}"('$did','c67sahejr578aqo3l8912oic9',1,0,'$open_id','aos',$timestamp,NOW())"
        else
            value=${value}",('$did','c67sahejr578aqo3l8912oic9',1,0,'$open_id','aos',$timestamp,NOW())"
        fi

        if [ $max = 0 ];then
            mysql -h192.168.103.240 --port=3306 -uroot -proot -Dcommon_warx -e"insert into sns_tbl (device_id, token, platform_type, old_platform_type, open_id, os, update_time, insert_time) values$value"
            value=""
        fi
        start=`expr $start + 1`
    done
    if [ ${#value} > 1 ];then
        mysql -h192.168.103.240 --port=3306 -uroot -proot -Dcommon_warx -e"insert into sns_tbl (device_id, token, platform_type, old_platform_type, open_id, os, update_time, insert_time) values$value"
    fi
else
    echo "you must set username, startnum, endnum"
fi

