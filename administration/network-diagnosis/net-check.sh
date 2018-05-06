#!/bin/bash - 
#===============================================================================
#
#          FILE: net-check.sh
# 
#         USAGE: ./net-check.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: James Zhu (), zhujian0805@gmail.com
#  ORGANIZATION: ZJ
#       CREATED: 05/06/2018 12:01
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

lspci |grep -i ether 

dmesg|grep -i ether

ping -c 3 8.8.8.8

ifconfig

route -n

host baidu.com

hostname

ping -c3 `hostname`

traceroute -I baidu.com

netstat -tulpa|head -20

sestatus
