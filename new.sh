#!/bin/sh
git submodule update --init --recursive
git checkout master

cd k-vim
git checkout master
cd ..

cd skynet
git checkout v1.0.0
make linux
