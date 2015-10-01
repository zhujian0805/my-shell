#!/bin/bash - 
#===============================================================================
#
#          FILE: array-lenth.sh
# 
#         USAGE: ./array-lenth.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: James Zhu (), zhujian0805@gmail.com
#  ORGANIZATION: ZJ
#       CREATED: 2015年10月01日 20:43
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
declare -a Unix=('Debian' 'Red hat' 'Suse' 'Fedora');
echo ${#Unix[@]} #Number of elements in the array
echo ${#Unix}  #Number of characters in the first element of the array.i.e Debian

