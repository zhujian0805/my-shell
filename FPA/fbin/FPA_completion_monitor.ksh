#!/bin/ksh
#--------------------------- COPYRIGHT NOTICE ----------------------------------
#*******************************************************************************
#
# Copyright (c) 2006 Perot Systems Corporation 
# All Rights Reserved
# Copyright Notice Does Not Imply Publication
#
#*******************************************************************************
#
#  NAME:              FPA_completion_monitor.ksh  
#
#  DESCRIPTION:       This module tests to see that a specified process has 
#                     completed within a specified number of seconds and sends 
#                     notification if the process has not completed.  
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
# 06/13/2006   J. Thiessen      New code. 
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
APPEND_LOG_FILE=TRUE      
logfilename="FPA_completion_monitor.`date +'%Y%m%d'`.log"
setlog ${logfilename}
batchstart

set -A arg_list ${*}
num_args=${#@}
if [ ${num_args} -lt 3 ]; then
  ##  ISSUE AN ERROR AND ABORT
  msg="ERROR -- USAGE: FPA_completion_monitor.ksh  PID  SLEEPTIME DIST_LIST [ SEVERITY ] "
  batcherror "${msg}"
fi

the_pid=${1}
sleep_time=${2}     # in seconds
the_dl=${3}
the_severity=${4:-Warning}
if [ ! -r ${BATCH_ETC}/${the_dl} ]; then
  batcherror_notify "ERROR Unreadable distribution list for FPA_completion_monitor: ${the_dl} "
fi

the_notif_text=${BATCH_OUTPUT}_archive/FPA_completion_monitor.${batch_start_dtm}.$$.msg
raw_ref_line=`ps -ef | grep "^ *${UNAME} *${the_pid} "`

if [ ${#raw_ref_line} -eq 0 ]; then
  messagelog "Cannot find the process to monitor: ${arg_list[*]} "
else
  ref_line=`echo "${raw_ref_line}" | sed 's/^ *//' |sed 's/  */ /g' | grep "^${UNAME} ${the_pid}"`
  the_cmd=`echo ${ref_line} | cut -d" " -f8- `

  ####
  ####  WAIT 
  ####  
  sleep ${sleep_time}

  ####
  ####  Check to see if process is still running.  
  ####  
  raw_line=`ps -ef | grep "^ *${UNAME} *${the_pid} " | grep "${the_cmd}" `
  if [ ${#raw_line} -eq 0 ]; then
    messagelog "Completed without delay: ${arg_list[*]} "
  else
    process_name=`echo "${raw_ref_line}" | cut -c48- | cut -d" " -f2- `
    echo "${the_severity} DELAY: `basename ${process_name%% *}` ${UNAME} ${BATCH_ENVIRONMENT} ${BATCH_ACCOUNT_NAME} at `date`  " > ${the_notif_text}
    echo "Started monitoring at ${batch_start_dtm} and found the following process: " >> ${the_notif_text}
    echo "${raw_ref_line} \n" >> ${the_notif_text}
    echo "Waited for ${sleep_time} seconds until `date +'%Y%m%d%H%M%S'` and found the following process: " >> ${the_notif_text}
    echo "${raw_line} \n" >> ${the_notif_text}
    messagelog_summary "${the_severity} DELAY: ${BATCH_ENVIRONMENT} ${BATCH_ACCOUNT_NAME} on ${UNAME} at `date` "
    FPA_nohup.ksh FPA_email.ksh ${the_dl} ${the_notif_text} "${the_severity} DELAY msg 1of2: ${BATCH_ENVIRONMENT} ${BATCH_ACCOUNT_NAME} on ${UNAME} at `date` "
    sleep ${FPA_completion_monitor_SecBtwnEmail:-300}
    FPA_nohup.ksh FPA_email.ksh ${the_dl} ${the_notif_text} "${the_severity} DELAY msg 2of2: ${BATCH_ENVIRONMENT} ${BATCH_ACCOUNT_NAME} on ${UNAME} at `date` "
  fi
fi

batchend
