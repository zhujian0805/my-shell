#!/bin/bash
#===============================================================================
#
#          FILE: forward.sh
# 
#         USAGE: ./forward.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: James Zhu (000), 
#  ORGANIZATION: 
#       CREATED: Monday, October 14, 2013 01:25:37 CST CST
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

service iptables restart
iptables -F
iptables -X
iptables -Z
iptables -t nat -A PREROUTING -i eth0 -p tcp -d 33129.248.70 --dport 80 -j LOG --log-level 1 --log-prefix 'HTTPForward: '
iptables -t nat -A PREROUTING -p tcp -d 33129.248.70 --dport 80 -j DNAT --to-destination 33129.248.244
iptables -t nat -A POSTROUTING -p tcp --dst 33129.248.244 --dport 80 -j SNAT --to-source 33129.248.70
iptables -t nat -A OUTPUT --dst 33129.248.70 -p tcp --dport 80 -j DNAT --to-destination 33129.248.244


