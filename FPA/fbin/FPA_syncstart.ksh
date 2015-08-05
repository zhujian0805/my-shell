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
#  NAME:              FPA_syncstart.ksh
#
#  DESCRIPTION:       This module confirms that no jobs specified as 
#                     incompatible are currently running and then executes a 
#                     script, waiting for the script to complete before 
#                     completing.  this is done through the batchstartsync 
#                     functionality in batchlog.  see batchlog for additional 
#                     description. 
#                     This logfile for this job is named 
#                     FPA_syncstart.<SYNCFILENAME>.<JOBNAME> 
#                     While this routine does not log it's start and stop 
#                     messages in the daily summary log, it does make an 
#                     entry in the daily summary log to indicate that the 
#                     specific job has been successfully synchronized and 
#                     will be starting later.  This will provide the user 
#                     with feedback in the summary log AT the time that the 
#                     FPA tries to initiate the job.  Unless there is a 
#                     synchronization conflict, this message and the start 
#                     message for the job will appear almost simultaneously 
#                     in the daily summary log file.  In addition to clarifying 
#                     what is happening with the current job schedule, 
#                     displaying this message will also raise awareness of 
#                     the job conflicts.  
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
# 04/09/2002   J. Thiessen      New code. 
# 05/24/2002   J. Thiessen      Modified to use daily log files.
# 03/10/2003   J. Thiessen      removed explicit path references to allow the 
#                               PATH to select the proper version or custom
#                               executables. 
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
  third_segment=${3:-SqlNotSpecified}
else
  third_segment=${jobname}
fi
logfilename="FPA_syncstart.${batchsync_filename}.${third_segment}.`date +'%Y%m%d'`.log"
echo "SYNC-STARTING ${third_segment} with sync-file: ${batchsync_filename} " >> ${BATCH_LOGS}/batch_summary.`date +'%Y%m%d'`
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
  first_word=`echo ${cmd} |awk '{print $1}'`
  msg="Problem executing ${cmd} ( `which ${first_word}` ) "
  batcherror_notify "${msg}"
fi

batchend
