#!/bin/bash
# Website Bandwidth Stress Test v1.0-SH | https://saputra.ch
while true
do
        curl -o /dev/null http://cachefly.cachefly.net/100mb.test
        sleep 0
done
