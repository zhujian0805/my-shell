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


if [ $# -lt 2 ]
then
    echo "Need 1 parameter"
    exit
fi


while [ $# -ge 1 ]
do
    arg="$1"
    case "$arg" in
        -a)
            shift;
            A="$1";
            shift;;
        -b)
            shift;
            B="$1";
            shift;;
        *)
            echo others;
            exit;;
    esac
done

if ! [ x"$A" = 'x' ]
then
    echo A is "$A"
fi

if ! [ x"$B" = 'x' ]
then
    echo B is "$B"
fi
