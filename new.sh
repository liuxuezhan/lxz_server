#!/bin/sh
git config --global user.email "253550465@qq.com"
git config --global user.name "liuxuezhan"
git submodule update --init --recursive
git checkout master

cd k-vim
git checkout master
cd ..

cd skynet
git checkout v1.0.0
make linux
