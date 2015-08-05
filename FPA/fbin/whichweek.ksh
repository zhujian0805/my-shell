#!/bin/ksh
# whichweek.ksh: runs a command only in a  given week of the month.
#   $1 is the week number, now permits negative numbers for nth last week of month
#   $2 ... $n are a command
# From PowerTools, but modified for negative weeks which indicate 
# the nth-to-the-last week of the month...
# Note that this now depends upon the format of the 'cal' command. 
week=$1
shift
command=$*
# get today's date (day in month) into a variable
today=`date +%d`
# figure out when the week begins and ends
if [ $week -ge 0 ]; then  
  startdate=`expr \( $week - 1 \) \* 7 + 1`
  enddate=`expr $week \* 7`
else  # for counting backwards from end of month  
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
  startdate=`expr \( $week \) \* 7 + $eom + 1`
  enddate=`expr \( $week + 1 \) \* 7 + $eom`
fi
if [ $today -lt $startdate -o $today -gt $enddate ]; then exit 0; fi
$command
