#!/bin/ksh
# whichday.ksh: runs a command only in a  given day of the month from the end of the month.
#   $1 is the number of days before the end of the month.
#      Example: 0 = last day of month; 1 = next to last day of month
#   $2 ... $n are a command
#
# Modification History:
# 8/2005 Rodney Crawford Initial Release
#
# Note: that this now depends upon the format of the 'cal' command. 
day=$1
shift
command=$*
# get today's date (day in month) into a variable
today=`date +%d`
# for counting backwards from end of month  
  tmp=`cal | tail -1`
  eom=${tmp##* }
  if [ ${#eom} -eq 0 ];then   ## cal returns 6 lines of numbers - the last one or two lines may be blank
    tmp=`cal | tail -2 | head -1`
    eom=${tmp##* }
    if [ ${#eom} -eq 0 ];then 
      tmp=`cal | tail -3 | head -1`
      eom=${tmp##* }
      if [ ${#eom} -eq 0 ];then exit 3; fi  #ERROR -- cal is not returning an expected result.
    fi
  fi
eom=`expr $eom - $day`
if [ $today -ne $eom ]; then exit 0; fi
$command

