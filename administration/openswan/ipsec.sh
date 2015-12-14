#!/bin/bash
#===============================================================================
#
#          FILE: ipsec.sh
# 
#         USAGE: ./ipsec.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: James Zhu (000), zhujian0805@gmail.com
#  ORGANIZATION: JZ
#       CREATED: 2015年04月22日 14时47分48秒 CST
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

yum -y update

yum -y install libreswan

systemctl restart ipsec

for i in /proc/sys/net/ipv4/conf/*/send_redirects
do
    echo 0 > $i
done

for i in /proc/sys/net/ipv4/conf/*/accept_redirects
do
    echo 0 > $i
done

echo 0 > /proc/sys/net/ipv4/conf/default/rp_filter
echo 0 > /proc/sys/net/ipv4/conf/eth0/rp_filter
echo 0 > /proc/sys/net/ipv4/conf/ip_vti0/rp_filter
echo 1 > /proc/sys/net/ipv4/ip_forward

systemctl restart ipsec

ipsec auto --add jameszhu
ipsec auto --up jameszhu
