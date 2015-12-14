#!/bin/bash - 
#===============================================================================
#
#          FILE: substitute-element.sh
# 
#         USAGE: ./substitute-element.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: James Zhu (), zhujian0805@gmail.com
#  ORGANIZATION: ZJ
#       CREATED: 2015年10月01日 20:47
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
Unix=('Debian' 'Red hat' 'Ubuntu' 'Suse' 'Fedora' 'UTS' 'OpenLinux');
 
unset Unix[3]
echo ${Unix[3]:-Not Set}
echo ${Unix[2]:-Not Set}
echo ${Unix[4]:-Not Set}
echo ${Unix[@]}
