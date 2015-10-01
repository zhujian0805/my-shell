#!/bin/bash - 
#===============================================================================
#
#          FILE: dup-array.sh
# 
#         USAGE: ./dup-array.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: James Zhu (), zhujian0805@gmail.com
#  ORGANIZATION: ZJ
#       CREATED: 2015年10月01日 20:55
#      REVISION:  ---
#===============================================================================

#set -o nounset                              # Treat unset variables as an error

Unix=('Debian' 'Red hat' 'Ubuntu' 'Suse' 'Fedora' 'UTS' 'OpenLinux');
Shell=('bash' 'csh' 'jsh' 'rsh' 'ksh' 'rc' 'tcsh');
 
UnixShell=("${Unix[@]}" "${Shell[@]}")
unset UnixShell
echo ${#UnixShell[@]}
