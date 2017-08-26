#!/bin/bash - 
#===============================================================================
#
#          FILE: test.sh
# 
#         USAGE: ./test.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: James Zhu (), zhujian0805@gmail.com
#  ORGANIZATION: ZJ
#       CREATED: 08/26/2017 20:40
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error


while [ $# -ge 1 ]
do
    arg="$1"
    case "$arg" in
        -a)
            shift;
            A="$1";
            shift;
            echo "$A";;
        -b)
            shift;
            B="$1";
            echo "$B";
            shift;;
        *)
            echo others;
            exit;;
    esac
done

echo A is "$A"

echo B is "$B"
