#!/bin/ksh
#--------------------------- COPYRIGHT NOTICE ----------------------------------
#*******************************************************************************
#
# Copyright (c) 2008 Perot Systems Corporation 
# All Rights Reserved
# Copyright Notice Does Not Imply Publication
#
#*******************************************************************************
#
#  NAME:               FPA_oracle_compile.ksh	 
#
#  DESCRIPTION:        This korn shell script compiles oracle packages, procedures, etc. into the specified database.  This process is integrated with change control and sends out special notification messages that will no longer be confused with merssages from jobs that are being executed.  


#                      The allowed directories for code to be promoted are:  DIRECTORY
#
#  
#  EXT DATA FILES: 
#
#  ENV VARIABLES:      Standard Batch Variables (
#   
#  INPUT:            
#
#  OUTPUT:             Standard log file in $BATCH_LOGS 
#                      Email notification for both success and failure. 
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
# 04/30/2008   J. Thiessen      New code. Grandfathered from sql.ksh
#
#
#*******************************************************************************

##########################################################################
#   main script                                                          #
##########################################################################

















































. ${BATCH_ETC}/.oracle.batch.profile
. ksh_functions.ksh
. batchlog.ksh
if [ "${#}" != "0" ]
then
  logfilename="${1}.${3:-NoParameters}.${batch_start_dtm}.log"
else
  logfilename="FPA_oracle_compile.ksh.${batch_start_dtm}.log"
fi
setlog "${logfilename}"
batchstart

batch_log_path=${batch_log%/*}
batch_log_name=`basename ${batch_log}`
flagfile="${BATCH_FLAGS}/${batch_log_name%%.log}.done"

####
####  If there is any checking for available disk space, tablespace, or 
####  other conditions that need to be satisfied before initiating the 
####  SQL, make those checks here.
####

usage="Usage: ${batch_prg} sql_script [ ORACLE_SID [ sql parameters ] ]"
num_args=${#}
sql_parameters=""
set -A parameters `echo ${*} | sed s:batch_working_directory:${batch_working_directory}:g`

if [ ${num_args} -gt 0 ]; then
  sql_name=${1}
else
  msg="ERROR -- SQL name required.  ${usage}"
  batcherror_notify "${msg}"
fi

if [ ${num_args} -gt 1 ]; then
  if [ "${2}" != "DEFAULT" ];then
    ORACLE_SID="${2}"
  fi
fi

####  
####  Get the oracle batch login information for this database.
####  
get_user_pass

this_parameter=2
while [ ${this_parameter} -lt ${num_args} ]
do
  sql_parameters="${sql_parameters:-}${parameters[${this_parameter}]} "
  this_parameter=`expr ${this_parameter} + 1`
done

cd ${batch_working_directory}
sql_parameters=`echo ${sql_parameters} | sed s:'NULL':NULL:g`
messagelog "sql_name:${sql_name} ORACLE_USER:${USER_PASS%%/*} ORACLE_SID:${ORACLE_SID}  OUTPUT:${batch_working_directory}"

#### 
####  Starting pl/sql procedure.  Need to capture standard output to
####  ${batch_log} so that error handling can be performed.  
####  NOTE:  If pl/sql procedure is run outside of korn shell, the
####  user must capture output to verify exit status.  
####
########    connect ${USER_PASS};  ### JPT 20050131 used to use this line...
######## in here-doc...    execute batch_log.init_pkg($$,'${batch_log_path}','${batch_log_name}');
sqlplus /nolog <<-ENDSQL 1>>${batch_log} 2>&1
    connect ${USER_PASS}@${ORACLE_SID};    
    whenever sqlerror exit failure
    set echo off
--    set serveroutput on size 200000;
    @${BATCH_SQLBIN}/${sql_name} ${sql_parameters}
    sho err;
    exit;
ENDSQL

####
####  Capture return status of sqlplus for later evaluation.
####
sqlreturn_code=$?

#### 
####  Examine the log file to check the exit status.  By standard 
####  convention, SQL routines must call batch_log.SQL_EXIT immediately
####  prior to termination of the procedure.  The korn shell script 
####  needs this SQL_EXIT line in order to determine success or failure.
####
returnline=`grep '^--PID='$$ ${batch_log} | grep '|SQL_EXIT=' | tail -1`
debug_var="--->${returnline}<---"
typeset -i procreturn_code=${returnline##*=}
debug_var="--->${procreturn_code}<---"

####
####  Examine the log file to check for "PLS-" errors.
####
returnline=`grep 'PLS-' ${batch_log}`
debug_var="--->${returnline}<---"
if [ "${returnline:-X}" != "X" ];then
    msg="Error-- ORACLE encountered errors: --->${returnline}<---. Writing logfile ${batch_log_name}"
    batcherror_notify "${msg}"
fi

####
####  Examine the log file to check for "ORA-" errors.
####
returnline=`grep 'ORA-' ${batch_log}`
debug_var="--->${returnline}<---"
if [ "${returnline:-X}" != "X" ];then
    msg="Error-- ORACLE encountered errors: --->${returnline}<---. Writing logfile ${batch_log_name}"
    batcherror_notify "${msg}"
fi

####
####  Examine the log file to check for "SP2-" errors.
####
returnline=`grep 'SP2-' ${batch_log}`
debug_var="--->${returnline}<---"
if [ "${returnline:-X}" != "X" ];then
    msg="Error-- ORACLE SQL encountered errors: --->${returnline}<---. Writing logfile ${batch_log_name}"
    batcherror_notify "${msg}"
fi

#### 
####  Check to be sure that sqlplus successfully started and completed.
####  Perform all error handling here for sqlplus errors.  
####
if [ ${sqlreturn_code} -ne 0 ];then
    msg="Error-- sqlplus did not complete successfully. Writing logfile ${batch_log_name}"
    batcherror_notify "${msg}"
fi

####
####  Check to be sure that the pl/sql procedure successfully started 
####  and completed.
####  Perform all error handling here for pl/sql errors.  
####
if [ ${procreturn_code} -ne 0 ];then
    msg="Error in SQL in ${batch_prg}"
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

