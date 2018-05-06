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

if ETHPCI=$(lspci |grep -i ether || dmesg|grep -i ether)
then
    echo "Ethnet PCI devices is present:"
    echo "----------------------------------------------"
    echo "$ETHPCI"
fi

ifconfig

route -n
