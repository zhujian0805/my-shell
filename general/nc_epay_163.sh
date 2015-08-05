#!/bin/bash - 

set -o nounset                              # Treat unset variables as an error

while true
do
            date >> /tmp/epay.log
            if ! nc -w 1 -zv epay.163.com 443 >> /tmp/epay.log 2>&1
            then
                echo $? >> /tmp/epay.log
                traceroute -I epay.163.com >> /tmp/epay.log 2>&1 
            fi
            sleep 1 
done
