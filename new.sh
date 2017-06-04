#!/bin/sh
git submodule update --init --recursive
cd skynet
git checkout v1.0.0
make linux
