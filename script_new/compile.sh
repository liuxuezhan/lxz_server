#!/bin/bash
find . -name "*.lua" -exec luac -o {} {} \;
