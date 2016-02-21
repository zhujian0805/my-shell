#!/bin/bash - 
#===============================================================================
#
#          FILE: append-element-to-arrya.sh
# 
#         USAGE: ./append-element-to-arrya.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: James Zhu (), zhujian0805@gmail.com
#  ORGANIZATION: ZJ
#       CREATED: 2015年10月01日 20:49
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
Unix=('Debian' 'Red hat' 'Ubuntu' 'Suse' 'Fedora' 'UTS' 'OpenLinux');
Unix=("${Unix[@]}" "AIX" "HP-UX")
echo ${Unix[7]}

