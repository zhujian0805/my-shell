#!/bin/sh

exec 3</etc/passwd

while read line <&3
do
    echo $line
done

exec 3<&-

read line
echo $line
