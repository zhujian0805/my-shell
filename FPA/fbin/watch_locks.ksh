#!/bin/ksh 
#--------------------------- COPYRIGHT NOTICE ----------------------------------
#*******************************************************************************
#
# Copyright (c) 2004 Perot Systems Corporation 
# All Rights Reserved
# Copyright Notice Does Not Imply Publication
#
#*******************************************************************************
#
#  NAME:               watch_locks.ksh
#
#  DESCRIPTION:        This script will create a file listing all oracle 
#                      processes in a wait state due to a locked database 
#                      object in the database specifed by P1. 
#                      It calls the stored procedure, DORIS.SP_GET_DB_LOCKS and 
#                      displays the results in the summary log file. 
#                      It will repeat P3 times with a delay of P2 minutes
#                      between runs. 
#                      
#  
#  EXT DATA FILES:     
#
#  ENV VARIABLES:      
#   
#  INPUT:              Parameter 1 contains the ORACLE_SID to use
#                      Parameter 2 specifies the number of minutes to sleep between runs.
#                      Parameter 3 specifies how many times to loop.
#                      Parameter 4 **NOT USED** specifies distribution list to use when 
#                          sending out the list of processes in wait-lock 
#                          state.  Email has not been implemented. 
#
#  OUTPUT:             
#                      
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
# 10/13/2004   J. Thiessen      New code. 
#
# Version 1.0
#*******************************************************************************


##########################################################################
#   main script                                                          #
##########################################################################
. ~/.FPAprofile     
. batchlog.ksh
######## NO_SUMMARY_MSGS=TRUE      ## Do not create entries in the batch summary log
######## APPEND_LOG_FILE=TRUE    ## Do not create flags -- .START and .SUCCESS etc.
setlog ${batch_prg}.${1-UNDEFINED}.`date +'%Y%m%d'`
batchstartunique

# P1  ORACLE_SID
# P2  number of minutes to sleep between runs
# P3  number of iterations before stopping 
# P4  distribution list for notification

export ORACLE_SID=${1:-${ORACLE_SID:-DEFAULT}}
let "sleeptime = ${2:-20} * 60"
maxloops=${3:-1}
distlist=${4:-NONE}
sql_name="DORIS.SP_GET_DB_LOCKS"
outfile="LockWaits.`echo ${ORACLE_SID}|tr '[A-Z]' '[a-z]'`"
outdir="${BATCH_SYSTEM}"
sql_parameters="'${outdir}','${outfile}'"

loopcounter=0
while [ ${loopcounter} -lt ${maxloops} ]
do
  let "loopcounter = $loopcounter + 1"
  if [ -a ${outdir}/${outfile} ]; then 
    rm -f  ${outdir}/${outfile}
  fi
  sqlplus /nolog <<ENDSQL 1>>${batch_log} 2>&1
    connect ${USER_PASS}@${ORACLE_SID};    
    whenever sqlerror exit failure
    set echo off
    -- set serveroutput on size 200000;
    execute ${sql_name}(${sql_parameters});
    exit;
ENDSQL
  ret_stat=${?}
  ## check outputfile for locked processes and send email if necessary.
  if [ ! -a ${outdir}/${outfile} ]; then 
    batcherror_notify "Problem checking for wait-lock processes, did not create ${outdir}/${outfile}" 
  fi
  numwords=`wc -w ${outdir}/${outfile} |awk '{print $1}'`
  now=`date +"%H:%M:%S %Z"`
  if [ ${numwords} -lt 5 ]; then
    messagelog_summary "${now} No locked processes in ${ORACLE_SID}"
  else
    morelocks=1
    morelocks=1
    numlocks=`wc -l ${outdir}/${outfile} |awk '{print $1}'`
    exec 5<"${outdir}/${outfile}"
    while [ ${morelocks:-1} -gt 0 ]
    do
      if read -u5 lockline ; then
        messagelog_summary "${now} ALERT:: Locked Process in ${ORACLE_SID} :: ${lockline}"
      else
        morelocks=0  ## reached EOF on ${outdir}/${outfile}
      fi
    done
    exec 5>&-
  fi
  ## sleep unless done 
  if [ ${loopcounter} -lt ${maxloops} ]; then
    sleep ${sleeptime}
  fi
done

batchend
