#!/bin/sh
git config --global user.email "253550465@qq.com"
git config --global user.name "liuxuezhan"
git submodule update --init --recursive

cd skynet
#git checkout v1.0.0
make linux SKYNET_DEFINES=-DMEMORY_CHECK
