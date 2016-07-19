#!/bin/ksh
#--------------------------- COPYRIGHT NOTICE ----------------------------------
#*******************************************************************************
#
# Copyright (c) 2003 Perot Systems Corporation 
# All Rights Reserved
# Copyright Notice Does Not Imply Publication
#
#*******************************************************************************
#
#  NAME:               sql_truncate.ksh
#
#  DESCRIPTION:        This korn shell script provides automated batch 
#                      initiation, logging functionality and error 
#                      handling for truncating specified table(s). 
#
#                      NOTE: When running  pl/sql, it is vital to redirect
#                      standard output and standard error to the logfile
#                      ${batch_log} in order to confirm successful completion
#                      and initiate problem notification and escalation 
#                      procedures if errors have occured.  
#                      NOTE:  The recommended process is that each "HERE
#                      DOCUMENT" (i.e., <<-ENDSQL ... ENDSQL) within a korn 
#                      shell script initiates only one pl/sql routine.  If 
#                      multiple pl/sql routines are executed within a single 
#                      sqlplus session, each pl/sql routine will be executed 
#                      regardless of the completion status of prior routines.  
#                      The korn shell error handling logic must be expanded 
#                      to check for successful completion of each routine.  
#  
#  EXT DATA FILES: 
#
#  ENV VARIABLES:      Standard Batch Variables (
#                      USER_PASS
#                      ORACLE_SID
#                      BATCH_BIN    directory containing executable code
#                      BATCH_SQLBIN directory containing sql code
#                      BATCH_LOGS   directory containing log files
#                      BATCH_ETC    directory containing configuration files
#                      batch_working_directory      directory containing the 
#                          output files as they are beeing created.  The 
#                          standard batchend routine will move all output 
#                          files into $BATCH_OUTPUT upon successful completion.
#                      BATCH_OUTPUT directory containing batch output. this
#                                   routine cd's to $BATCH_OUTPUT to capture 
#                                   all temp files written in the current 
#                                   working directory.  
#   
#  PARAMETERS:         1:  Oracle Instance
#                      2:  Name of table to be truncated
#   
#   
#  INPUT:            
#
#  OUTPUT:             Standard log file in $BATCH_LOGS
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
# 2003/06/22   J. Thiessen      New code. 
# 2005/01/06   J. Thiessen      Removed path for ksh_functions. Let PATH find it
# 12/13/2006   J. Thiessen      Added 'sho err' command to record error details
#
#*******************************************************************************

##########################################################################
#   main script                                                          #
##########################################################################

. ${BATCH_ETC}/.oracle.batch.profile
. ksh_functions.ksh
. batchlog.ksh
logfilename="${0##*/}.${2:-NoTableSpecified}.${batch_start_dtm}.log"
setlog "${logfilename}"
batchstart

batch_log_path=${batch_log%/*}
batch_log_name=`basename ${batch_log}`
flagfile="${BATCH_FLAGS}/${batch_log_name%%.log}.done"

usage="\nUsage: ${batch_prg} ORACLE_SID Table_Name \n"
num_args=${#}
sql_parameters=""
set -A parameters `echo ${*} | sed s:batch_working_directory:${batch_working_directory}:g`

if [ ${num_args} -gt 0 ]
then
  if [ "${1}" != "DEFAULT" ];then
    ORACLE_SID="${1}"
  fi
else
  msg="ERROR -- The Oracle Instance is required.  ${usage}"
  batcherror_notify "${msg}"
fi

if [ ${num_args} -gt 1 ]; then
  if [ "${2}" != "DEFAULT" ];then
    table_name="${2}"
  fi
else
  msg="ERROR -- The Table_Name is required.  ${usage}"
  batcherror_notify "${msg}"
fi

#### 
####  Get the oracle batch login information for this database.
#### 
get_user_pass

this_parameter=2
while [ ${this_parameter} -lt ${num_args} ]
do
  sql_parameters="${sql_parameters:+${sql_parameters},}'${parameters[${this_parameter}]}'"
  this_parameter=`expr ${this_parameter} + 1`
done

cd ${batch_working_directory}
sql_parameters=`echo ${sql_parameters} | sed s:\'NULL\':NULL:g`

####
####  Starting pl/sql procedure.  Need to capture standard output to
####  ${batch_log} so that error handling can be performed.
####  NOTE:  If pl/sql procedure is run outside of korn shell, the
####  user must capture output to verify exit status.
########    connect ${USER_PASS};    # JPT 20050131 used to use this line below...`
####
sqlplus /nolog <<-ENDSQL 1>>${batch_log} 2>&1
    connect ${USER_PASS}@${ORACLE_SID};
    whenever sqlerror exit failure
    set echo off
--    set serveroutput on size 200000;
    TRUNCATE TABLE ${table_name};
    sho err;
    exit;
ENDSQL

####
####  Capture return status for later evaluation.
####
sqlreturn_code=$?

####
####  Examine the log file to check for "ORA-" errors.
####
returnline=`grep '^ORA-' ${batch_log}`
debug_var="--->${returnline}<---"
if [ "${returnline:-X}" != "X" ];then
    msg="Error-- ORACLE encountered errors: --->${returnline}<---. Writing logfile ${batch_log_name}"
    batcherror_notify "${msg}"
fi

#### 
####  Check to be sure that sql successfully started and completed.
####  Perform all error handling here for sql errors.  
####
if [ ${sqlreturn_code} -ne 0 ];then
  msg="Error-- sql did not complete successfully. Writing logfile ${batch_log_name}"
  batcherror_notify "${msg}"
fi

####
####  If the $flagfile already exists, then there is a problem -- so 
####  put a message in the flagfile and initiate the notification process.
####
now=`date`
if [ -a  ${flagfile} ];then
  msg=`ls -l ${flagfile}| sed "s/  */ /g"`
  msg="Error. The flagfile already exists. ${msg}"
  echo "${batch_prg} tried to create this log file at ${now}" >> ${flagfile}
  echo "${msg} \n \n" >> ${flagfile}
  batcherror_notify "${msg}"
fi 

####
####  Create a flag file to indicate successful completion
####
echo "${batch_prg} created ${flagfile} at ${now}" >> ${flagfile}
if [ ! -a  ${flagfile} ];then
  msg="Error. FAILED to create flagfile ${flagfile}"
  batcherror_notify "${msg}"
fi 

batchend

