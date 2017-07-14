#!/bin/bash - 
#===============================================================================
#
#          FILE: build-initramfs.sh
# 
#         USAGE: ./build-initramfs.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: James Zhu (), zhujian0805@gmail.com
#  ORGANIZATION: ZJ
#       CREATED: 07/14/2017 13:50
#      REVISION:  ---
#===============================================================================

mkdir test
cd test
zcat /boot/initrd-2.6.18-164.6.1.el5.img | cpio -idmv
find . | cpio -o -c | gzip -9 > /boot/test.img

# For image compressed with xz format, the below commands can be used to extract the
# initrd image
mkdir /tmp/initrd
cd /tmp/initrd
xz -dc < initrd.img | cpio --quiet -i --make-directories 
cd /tmp/initrd
find . 2>/dev/null | cpio --quiet -c -o | xz -9 --format=lzma >"new_initrd.img"
