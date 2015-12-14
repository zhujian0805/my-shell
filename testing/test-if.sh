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



if [ $a != 'abc' ]
then
    print YES
fi 


echo Hiiiiiiiii, Wrong!!
