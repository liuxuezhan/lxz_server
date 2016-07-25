#!/bin/bash
mongoexport -d warx_6 -c player -f account | cut -d"\"" -f6 > account.txt
