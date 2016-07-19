#!/bin/ksh
#--------------------------- COPYRIGHT NOTICE ----------------------------------
#*******************************************************************************
#
# Copyright (c) 2001 Perot Systems Corporation 
# All Rights Reserved
# Copyright Notice Does Not Imply Publication
#
#*******************************************************************************
#
#  NAME:              FPA_staggerstart.ksh
#
#  DESCRIPTION:       This module staggers the start of specified jobs.  It was created to handle automated FTP's in a manner that will prevent errors due to network or system contention.  

HERE HERE HERE 


#  
#  EXT DATA FILES: 
#
#  ENV VARIABLES:   
#   
#  INPUT:            
#
#  OUTPUT:            
#
#  TEMPORARY FILES:    
#
#  EXT FUNC CALLS:     
#
#  EXT MOD CALLS:      
#
#*******************************************************************************
# Date         Programmmer      Description
# ----------   --------------   ------------------------------------------
# 04/09/2002   J. Thiessen      Being developed....  
#
#
#*******************************************************************************

##########################################################################
#   main script                                                          #
##########################################################################

. ~/.FPAprofile     
. batchlog.ksh
NO_SUMMARY_MSGS="TRUE"
NO_OUTPUT="TRUE"
APPEND_LOG_FILE=TRUE      # be sure that the job started does NOT have this variable set.

num_args=${#@}
if [ ${num_args} -lt 2 ]; then
  ##  ISSUE AN ERROR AND ABORT
  batchstart
  msg="ERROR -- USAGE: FPA_syncstart.ksh SYNCFILE <job with optional parameters>. ${*:-SyncfileNotSpecified} "
  batcherror_notify "${msg}"
fi
batchsync_filename="${1:-UNDEFINED}"
jobname="${2:-JobNotSpecified}"
jobname3=`echo ${jobname} | cut -c0-3`
if [ "${jobname3}" = "sql" ]; then
  logfilename="FPA_syncstart.${batchsync_filename}.${3:-SqlNotSpecified}.log"
else
  logfilename="FPA_syncstart.${batchsync_filename}.${jobname}.log"
fi
setlog "${logfilename}"
batchstartsync

set -A arg_list ${*}
cmd=""
loopcnt=1
while [ ${loopcnt} -lt ${num_args} ]
do
  cmd="${cmd}${arg_list[${loopcnt}]} "
  loopcnt=`expr ${loopcnt} + 1`
done

ksh ${cmd}
OK=$?

if [ ${OK} -ne 0 ]; then
  msg="Problem executing ${cmd} "
  batcherror_notify "${msg}"
fi

batchend
