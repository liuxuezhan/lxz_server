#!/bin/sh

git add --all
if [ $# == 1 ]
then
   git commit -m "'$1'" 
else
   #timestamp=`date +%s` 
   timestamp=`date "+%Y-%m-%d %H:%M:%S"` 
   git commit -m "$timestamp" 
   echo "WARN: log_name=$timestamp"
fi
git push all 
