#!/bin/sh
git clone https://github.com/liuxuezhan/skynet.git
cd skynet
make linux SKYNET_DEFINES=-DMEMORY_CHECK
