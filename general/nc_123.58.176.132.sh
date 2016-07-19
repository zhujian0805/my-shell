#!/bin/bash - 

set -o nounset                              # Treat unset variables as an error

while true
do
            date >> /tmp/123.58.176.132.log
            if ! nc -w 1 -zv 123.58.176.132 80 >> /tmp/123.58.176.132.log 2>&1
            then
                echo $? >> /tmp/123.58.176.132.log
                traceroute -I 123.58.176.132 >> /tmp/123.58.176.132.log 2>&1 
            fi
            sleep 1 
done
