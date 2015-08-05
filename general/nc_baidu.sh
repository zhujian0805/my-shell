#!/bin/bash - 

set -o nounset                              # Treat unset variables as an error

while true
do
            date >> /tmp/baidu.log
            if ! nc -w 1 -zv baidu.com 80 >> /tmp/baidu.log 2>&1
            then
                echo $? >> /tmp/baidu.log
                traceroute -I baidu.com >> /tmp/baidu.log 2>&1 
            fi
            sleep 1 
done
