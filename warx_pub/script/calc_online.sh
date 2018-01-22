#!/bin/bash
cur=$(date +%s)
echo ${cur}
cur=$((cur-650))
echo ${cur}
file="TXWM_online_$(date +%Y%m%d%H%M).log"
mongoexport -d warxG -c onlinecnt -f gameappid,timekey,gsid,onlinecntios,onlinecntandroid,zoneareaid -q "{ timekey: { \$gte: ${cur} } }"  --type csv --sort '{gsid:1, timekey:1}' | sed '1 d' | tr "," '|' > ${file}
