#!/bin/bash
#===============================================================================
#
#          FILE: test-if.sh
# 
#         USAGE: ./test-if.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: James Zhu (000), zhujian0805@gmail.com
#  ORGANIZATION: JZ
#       CREATED: 2014年09月01日 11时12分51秒 CST
#      REVISION:  ---
#===============================================================================

#set -o nounset                              # Treat unset variables as an error



if [ x$a != x'abc' ] ## Adding 'x' to avoid no defined $a
#if [ $a != 'abc' ]
then
    echo YES
fi 


echo Hiiiiiiiii, Wrong!!
