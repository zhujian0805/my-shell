#!/bin/bash - 
#===============================================================================
#
#          FILE: file-contents-to-array.sh
# 
#         USAGE: ./file-contents-to-array.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: James Zhu (), zhujian0805@gmail.com
#  ORGANIZATION: ZJ
#       CREATED: 2015年10月01日 20:58
#      REVISION:  ---
#===============================================================================

filecontent=( `cat "/etc/passwd" `)
 
for t in "${filecontent[@]}"
do
    echo "$t"
done
echo "Read file content!"
