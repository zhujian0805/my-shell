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

# Check hardware and drivers
lspci |grep -i ether 
dmesg|grep -i ether

# Check ping OK?
ping -c 3 8.8.8.8

# Check IP address configured properly
ifconfig

# Check route table correct
route -n

# Check dns resovable 
host baidu.com

# Check if nscd has bad cache
systemctl status nscd

# Check host name is right?
hostname
cat /etc/hosts

# Ping host
ping -c3 $(hostname)

# Check traceroute path OK?
traceroute -I baidu.com

# Check processes are listening on ports
netstat -tulpa|head -20

# Check if SELinux is enabled
sestatus



