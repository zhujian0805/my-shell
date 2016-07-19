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
/sbin/iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 389 -j LOG --log-prefix 'LDAPForward: '
/sbin/iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 389 -j DNAT --to 10.130.0.81:389
/sbin/iptables -t nat -A POSTROUTING -o eth0 -p tcp -d 10.130.0.81 --dport 389 -j SNAT --to-source 172.31.248.244

/sbin/iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 636 -j LOG --log-prefix 'LDAPForward: '
/sbin/iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 636 -j DNAT --to 10.130.0.81:636
/sbin/iptables -t nat -A POSTROUTING -o eth0 -p tcp -d 10.130.0.81 --dport 636 -j SNAT --to-source 172.31.248.244

/sbin/iptables -t nat -A PREROUTING -i eth0 -p tcp -d 172.31.248.244 --dport 80 -j LOG --log-level 1 --log-prefix 'HTTPForward: '
iptables -t nat -A PREROUTING -p tcp -d 172.31.248.244 --dport 80 -j DNAT --to-destination 10.47.5.242
iptables -t nat -A POSTROUTING -p tcp --dst 10.47.5.242 --dport 80 -j SNAT --to-source 172.31.248.244
iptables -t nat -A OUTPUT --dst 172.31.248.244 -p tcp --dport 80 -j DNAT --to-destination 10.47.5.242
