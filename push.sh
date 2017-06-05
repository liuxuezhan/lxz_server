#!/bin/sh

git add -A . 
if [ $# == 1 ]
then
   git commit -m "'$1'" 
else
   #timestamp=`date +%s` 
   timestamp=`date "+%Y-%m-%d %H:%M:%S"` 
   git commit -m "$timestamp" 
   echo "日志名：$timestamp"
fi
git push origin master --recurse-submodules=check
