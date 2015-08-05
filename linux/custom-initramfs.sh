#!/bin/bash

set -u

mount /proc
LINE=$(cat /proc/cmdline)
SIZE=$(/usr/bin/expr "$LINE" : '.*tmpfs_size=\([0-9]*M\)')
umount /proc

if [ -z $SIZE ]
then
    SIZE=2000M
fi

mkdir /sysroot
mount -t tmpfs -o size=$SIZE none /sysroot
echo "exploding root file system..."
find / -depth -xdev -print0 | cpio --null -pdum /sysroot
echo "complete"

exec /sbin/switch_root /sysroot /sbin/init
