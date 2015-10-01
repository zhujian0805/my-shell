#!/bin/bash - 
#===============================================================================
#
#          FILE: slice-array.sh
# 
#         USAGE: ./slice-array.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: James Zhu (), zhujian0805@gmail.com
#  ORGANIZATION: ZJ
#       CREATED: 2015年10月01日 20:45
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
Unix=('Debian' 'Red hat' 'Ubuntu' 'Suse' 'Fedora' 'UTS' 'OpenLinux');
echo ${Unix[2]:3:2}

