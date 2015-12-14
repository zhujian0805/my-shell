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
#  NAME:               sql.ksh	 
#
#  DESCRIPTION:        This korn shell script provides automated batch 
#                      initiation, logging functionality and error 
#                      handling for executing step one of the 
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
#                      ORACLE_SID   (this is over-riden by $2 unless $2 is "DEFAULT")
#                      BATCH_BIN    directory containing executable code
#                      BATCH_SQLBIN directory containing sql code
#                      BATCH_LOGS   directory containing log files
#                      BATCH_ETC    directory containing configuration files
#                      batch_working_directory  directory containing the 
#                                   output files as they are beeing created.  
#                                   The standard batchend routine will move all 
#                                   output files into $BATCH_OUTPUT upon successful 
#                                   completion.  
#                      BATCH_OUTPUT directory containing batch output after the 
#                                   program has completed successfully -- this 
#                                   directory is monitored by FPA which moves 
#                                   the output files to $BATCH_OUTPUT_archive 
#                                   and processes them according to the configuration 
#                                   files.  This sql.ksh routine cd's to 
#                                   $batch_working_directory (which is defined and 
#                                   created in the batchstart function) so sql code
#                                   can simply spool output to a filename 
#                                   and the file will be created in the proper
#                                   directory.  NOTE: This means that if the
#                                   sql code calls other sql code, it must
#                                   use @@ rather than @ so that sqlplus will
#                                   find the code in the $BATCH_SQLBIN directory.
#                      Note also, that when the job completes successfully, the 
#                      batchend function will automatically record a long listing 
#                      of the batch_working_directory and will then MOVE each 
#                      output file to $BATCH_OUTPUT, and will finally rmdir 
#                      batch_working_directory.  If the job exits with a failure 
#                      status, the files will NOT be moved, but will need to be 
#                      manually cleaned up.   
#                                   tmp_param=`echo "${3}" | sed s:batch_working_directory:${batch_working_directory}:g`
#   
#  INPUT:            
#
#  OUTPUT:             Standard log file in $BATCH_LOGS 
#                      Optional output files depending on which sql is specified
#                      in $1.
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
# 11/05/2001   J. Thiessen      New code. 
# 06/11/2002   J. Thiessen      Now allowing more than 6 sql parameters, tested
#                               50 parameters successfully.
# 07/18/2002   J. Thiessen      The oracle username information is now extracted
#                               during run time rather than using the default 
#                               values from the environment.
# 12/19/2002   J. Thiessen      Added code to translate  the parameter 'NULL' 
#                               to just NULL without the ticks. 
# 03/10/2003   J. Thiessen      Removed explicit path references so that the PATH
#                               variable will be used to select the proper code 
#                               from the proper directory.  
# 03/10/2003   J. Thiessen      removed explicit path references to allow the 
#                               PATH to select the proper version or custom
#                               executables. 
# 12/13/2006   J. Thiessen      Added 'sho err' command to record error details
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
  logfilename="sql.ksh.${batch_start_dtm}.log"
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

