#!/bin/sh

if [ $# == 1 ]
then
   git add --all
   git commit -m "'$1'" 
   git push all 
else
    echo "you must set log "
fi
