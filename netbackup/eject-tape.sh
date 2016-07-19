#!/bin/ksh
#===============================================================================
#
#          FILE: eject-tape.sh
# 
#         USAGE: ./eject-tape.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: James Zhu (000), zhujian0805@gmail.com
#  ORGANIZATION: JZ
#       CREATED: 2015年04月14日 17时46分53秒 CST
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

MEDIA_HOST=cn5-admin-backup
#if [[ $# != 1 ]]
#then    echo "enter tape #'s seperated by colons (i.e. A2200:A2201:A2202)"
#        read j
#        echo "Ejecting Tapes: $j"
#else    j=$1
j=$1
#fi

i=`echo $j | /usr/bin/tr "[:lower:]" "[:upper:]"`

COMMAND1="/usr/openv/volmgr/bin/vmupdate -rt tld -rn 0 -rh $MEDIA_HOST -vh $MEDIA_HOST \
    -use_barcode_rules -empty_map"

COMMAND2="/usr/openv/volmgr/bin/vmchange -res -multi_eject -w -verbose -rn 0 -rt TLD \
    -rh $MEDIA_HOST -ml $i -single_cycle"

echo "Updating Tape List $COMMAND1"
$COMMAND1

echo;
echo "Running: $COMMAND2"
$COMMAND2
