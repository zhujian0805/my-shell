#!/bin/bash - 

set -o nounset                              # Treat unset variables as an error

while true
do
            date >> /tmp/sc2.log
            if ! nc -w 1 -zv sc2.163.com 80 >> /tmp/sc2.log 2>&1
            then
                echo $? >> /tmp/sc2.log
                traceroute -I sc2.163.com >> /tmp/sc2.log 2>&1 
            fi
            sleep 1 
done
