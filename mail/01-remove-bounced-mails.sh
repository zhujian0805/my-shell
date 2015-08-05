#!/bin/bash
#===============================================================================
#
#          FILE: 01-remove-bounced-mails.sh
# 
#         USAGE: ./01-remove-bounced-mails.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: James Zhu (000), zhujian0805@gmail.com
#  ORGANIZATION: JZ
#       CREATED: 2015年04月01日 17时30分20秒 CST
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

for i in $(find /var/spool/postfix/deferred/ -type f)
do  
  if postcat $i|grep "Mailbox not found" >/dev/null 2>&1 
   then  
     MAILID=$(echo $i|awk -F "/" '{print $NF}')
     MAILADD=$(postcat $i|grep "said: 550"|awk '{print $1}'|sed 's/[<>]//g')
     echo removing bounce mail $MAILID sent to $MAILADD
     postsuper -d $MAILID
  fi
done

