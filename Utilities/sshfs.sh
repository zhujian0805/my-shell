#!/usr/bin/sh 
#===============================================================================
#
#          FILE: sshfs.sh
# 
#         USAGE: ./sshfs.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: Wednesday, March 27, 2013 04:37:11 CST CST
#      REVISION:  ---
#===============================================================================
#

Mount the remote filesystem with

sshfs user@host:/path /local/mount/point

and unmount with

fusermount -u /local/mount/point
