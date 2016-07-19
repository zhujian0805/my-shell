#!/bin/ksh
#--------------------------- COPYRIGHT NOTICE ----------------------------------
#*******************************************************************************
#
# Copyright (c) 2000 Perot Systems Corporation 
# All Rights Reserved
# Copyright Notice Does Not Imply Publication
#
#*******************************************************************************
#
#  NAME:               FPA_schedulejob.ksh
#
#  DESCRIPTION:        This script is designed to be used within the FPA in
#                      order to use cron to schedule jobs to be initiated by 
#                      the automation.  This method is prefered over using 
#                      cron to directly start a batch process for several 
#                      reasons:
#                      1.  The job can be scheduled to run early in the day 
#                          so the users can verify that the job is scheduled 
#                          to run.
#                      2.  The users can cancel the run without PSC interaction 
#                          by removing the jobcard via ftp without PSC 
#                          interaction.
#                      3.  If there is system downtime during the night, the 
#                          job will run when cron is activated again rather 
#                          than just skipping the run. 
#                      4.  Keeps ALL job initiation consolidated in the 
#                          automation, helps to prevent forgetting about jobs 
#                          scheduled in cron. 
#                      
#                      This script requires 1 positional argument.  
#
#                      The first argument is the name (without the path!) of 
#                      the Jobcard template to be scheduled.
#                      The optional second argument is the "RunAfter" datetime and may use the following formats:
#                      YYYYMMDDHHMMSS or 
#                      MMDDHHMMSS or 
#                      DDHHMMSS or 
#                      HHMMSS  
#
#                      It is an error to call this script without proper 
#                      arguments.
#
#  
#  EXT DATA FILES:     The JobCard file that contains the 
#                      instructions for running the job must reside 
#                      in the BATCH_ETC directory.  It should use the naming
#                      convention, "JOBNAME.job" or "JOBNAME.template" 
#                       
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
# 2003.12.10   J. Thiessen      New code. 
#
#
#*******************************************************************************


##########################################################################
#   main script                                                          #
##########################################################################

. ~/.FPAprofile     
. batchlog.ksh
. ksh_functions.ksh               #  READS THE DATE AND RUN_SEQUENCE FUNCTIONS
NO_OUTPUT="TRUE"
NO_SUMMARY_MSGS=TRUE              # be sure that the job started does NOT have this variable set. (don't export it!!)
APPEND_LOG_FILE=TRUE      # be sure that the job started does NOT have this variable set.
setlog ${batch_prg}.`date +'%Y%m%d'`
batchstart
unset FPA_OUTPUTFILEPREFIX     # be sure that this variable is not still defined

usage="${batch_prg} JOBCARD.job [ start-after ] "
now_Y=`echo ${batch_start_dtm} | cut -c1-4`
now_m=`echo ${batch_start_dtm} | cut -c5-6`
now_d=`echo ${batch_start_dtm} | cut -c7-8`
now_H=`echo ${batch_start_dtm} | cut -c9-10`
now_M=`echo ${batch_start_dtm} | cut -c11-12`
now_S=`echo ${batch_start_dtm} | cut -c13-14`
num_args=${#}
if [ ${num_args} -lt 1 ]
then
  msg="${batch_prg} ERROR -- Improper arguments:-->${*:-NoArguments}<-- USAGE: ${usage}"
  batcherror_notify "${msg}"
fi
if [ ${num_args} -eq 1 ]
then
  start_after=${batch_start_dtm}
else
  arg2_length=${#2}
  case ${arg2_length} in
      6)    start_after="${now_Y}${now_m}${now_d}${2}"
            if [ ${start_after} -lt ${batch_start_dtm} ]; then
              start_after="`Tomorrow_Date`${2}"
            fi;;
      8)    start_after="${now_Y}${now_m}${2}";;
     10)    start_after="${now_Y}${2}";;
     14)    start_after="${2}";;
      *)    batcherror_notify "${batch_prg} ERROR -- Invalid datetime ${2}  Must be formatted as YYYYMMDDHHMMSS or MMDDHHMMSS or DDHHMMSS or HHMMSS  ";;
  esac
fi
jobname=${1%.*}

if [ ! -r ${BATCH_ETC}/${1} ]; then
  msg="${batch_prg} ERROR -- cannot read JOBCARD template ${1}"
  batcherror_notify "${msg}"
fi

cp ${BATCH_ETC}/${1} ${BATCH_JOBCARDS}/RunAfter${start_after}.${jobname}.${batch_start_dtm}
ReturnCode=$?

if [ ! -r ${BATCH_JOBCARDS}/RunAfter${start_after}.${jobname}.${batch_start_dtm} ]; then
  msg="${batch_prg} ERROR -- Unable to create jobcard. ReturnCode=${ReturnCode}"
  batcherror_notify "${msg}"
fi
if [ "${ReturnCode}" != "0" ]; then
  msg="${batch_prg} ERROR -- Error copying the jobcard template. ReturnCode=${ReturnCode}"
  batcherror_notify "${msg}"
fi

chmod 777 ${BATCH_JOBCARDS}/RunAfter${start_after}.${jobname}.${batch_start_dtm}
ReturnCode=$?
if [ "${ReturnCode}" != "0" ]; then
  msg="${batch_prg} ERROR -- Permissions error on the jobcard template. ReturnCode=${ReturnCode}"
  batcherror_notify "${msg}"
fi

messagelog "${batch_prg} SUCCESSFULLY created jobcard RunAfter${start_after}.${jobname}.${batch_start_dtm} "

batchend

