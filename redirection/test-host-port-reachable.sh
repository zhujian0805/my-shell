#!/bin/bash - 
#===============================================================================
#
#          FILE: test-host-port-reachable.sh
# 
#         USAGE: ./test-host-port-reachable.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: James Zhu (), zhujian0805@gmail.com
#  ORGANIZATION: ZJ
#       CREATED: 07/12/2017 15:01
#      REVISION:  ---
#===============================================================================

# If host is a valid hostname or Internet address, and port is an integer port number or service name, bash attempts to open the corresponding TCP socket.
#echo somthing > /dev/tcp/host/port
echo somthing > /dev/tcp/localhost/22
echo $?

# If host is a valid hostname or Internet address, and port is an integer port number or service name, bash attempts to open the corresponding UDP socket.
#echo something > /dev/udp/host/port
echo somthing > /dev/tcp/localhost/22
echo $?

# For example, you can connect to the 22 on localhost
cat < /dev/tcp/localhost/22
