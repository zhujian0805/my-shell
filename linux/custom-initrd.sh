#!/bin/bash
#===============================================================================
#
#          FILE: custom-initrd.sh
# 
#         USAGE: ./custom-initrd.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: James Zhu (000), zhujian0805@gmail.com
#  ORGANIZATION: JZ
#       CREATED: 2014年08月05日 09时13分56秒 CST
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
set -u

mount /proc
LINE=$(cat /proc/cmdline)
SIZE=$(/usr/bin/expr "$LINE" : '.*tmpfs_size=\([0-9]*M\)')
umount /proc

if [ -z $SIZE ]
then
  SIZE=400M
fi

mkdir /new-root
mount -t tmpfs -o size=$SIZE /dev/root /new-root
/usr/bin/find / -xdev | cpio -pdumv /new-root
cd /new-root
mkdir old-root
/sbin/pivot_root . old-root
mknod /dev/ram0 b 1 0
exec /usr/sbin/chroot . bash -c 'umount /old-root; /sbin/blockdev --flushbufs /dev/ram0;
exec /sbin/init' <dev/console >dev/console 2>&1
