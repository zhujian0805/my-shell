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
#  NAME:               java.ksh	 
#
#  DESCRIPTION:        This korn shell script provides automated batch 
#                      initiation, logging functionality and error 
#                      handling for running a java executable.  
#
#                      NOTE: It is important to redirect
#                      standard output and standard error to the logfile
#                      ${batch_log} in order to confirm successful completion
#                      and initiate problem notification and escalation 
#                      procedures if errors have occured.  Java can exit with
#                      a successful status after encountering errors / exceptions
#                      depending on how the application is designed. 
#  
#                      NOTE: The oracle variables are initialized but not yet 
#                      used due to the way this first java object has hard-coded 
#                      oracle values.  This functionality must be added later. 
#  
#  EXT DATA FILES: 
#
#  ENV VARIABLES:      Standard Batch Variables (
#                      USER_PASS
#                      ORACLE_SID   (-----------------------------------------------)
#                      BATCH_BIN    directory containing local (custom) executable code
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
#                                   files.  This java.ksh routine cd's to 
#                                   $batch_working_directory (which is defined and 
#                                   created in the batchstart function) so java code
#                                   can simply spool output to a filename 
#                                   and the file will be created in the proper
#                                   directory.  NOTE: This means that if the
#                                   java code calls other java code, the paths 
#                                   must be properly defined. 
#                      Note also, that when the job completes successfully, the 
#                      batchend function will automatically record a long listing 
#                      of the batch_working_directory and will then MOVE each 
#                      output file to $BATCH_OUTPUT, and will finally rmdir 
#                      batch_working_directory.  If the job exits with a failure 
#                      status, the files will NOT be moved, but will need to be 
#                      manually cleaned up.   
#   
#  INPUT:              The first parameter is required and must contain the name 
#                      of the java object to be executed.   
#
#                      java is initiated as 'java -cp ' and the classpath must be 
#                      specified in the next set of parameters.  Since colons (:) 
#                      are not allowed in the menu configuration files, the colon 
#                      delimited classpath must be built within this code from the 
#                      parameters specified.  The string 'END_PATH' must be sent 
#                      as a parameter to signal the end of the classpath values 
#                      and the beginning of the paramters that are to be passed 
#                      to the java object being executed.  
#
#                      There can be an arbitrary number of paramters passed to the 
#                      java object. 
#
#  OUTPUT:             Standard log file in $BATCH_LOGS 
#                      Optional output files depending on which java object 
#                      is specified in $1.
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
# 12/03/2003   J. Thiessen      New code. 
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
  logfilestring=${1##*/}
  java_exe=${1%%/*}
  if [ "${logfilestring}" = "${java_exe}" ]; then
    logfilename="${java_exe}.${batch_start_dtm}.log"
  else
    logfilename="${java_exe}.${logfilestring}.${batch_start_dtm}.log"
  fi
else
  logfilename="java.ksh.${batch_start_dtm}.log"
fi
setlog "${logfilename}"
batchstart

batch_log_path=${batch_log%/*}
batch_log_name=`basename ${batch_log}`
flagfile="${BATCH_FLAGS}/${batch_log_name%%.log}.done"

####
####  All checking for available disk space, tablespace, or 
####  other conditions that need to be satisfied before initiating the 
####  code, is handled here.
####

usage="Usage: ${batch_prg} java_exe/logfilename java_path END_PATH [ java parameters ]"
num_args=${#}
java_parameters=""
set -A parameters `echo ${*} | sed s:batch_working_directory:${batch_working_directory}:g`

if [ ${num_args} -gt 0 ]; then
  java_exe=${1%%/*}
else
  msg="ERROR -- java_exe value required.  ${usage}"
  batcherror_notify "${msg}"
fi

if [ ${num_args} -gt 1 ]; then
  java_path="${2}"
else
  msg="ERROR -- java_path value required.  ${usage}"
  batcherror_notify "${msg}"
fi

this_parameter=2
if [ ${num_args} -gt 2 ]; then
  continue=TRUE
else
  continue=FALSE
fi
while [ "${continue}" = "TRUE" ]
do
  if [ "${parameters[${this_parameter}]}" = "END_PATH" ]; then
    continue=FALSE
  else
    java_path="${java_path:-}:${parameters[${this_parameter}]}"
  fi
  this_parameter=`expr ${this_parameter} + 1`
  if [ ${this_parameter} -ge ${num_args} ];then
    continue=FALSE
  fi
done

while [ ${this_parameter} -lt ${num_args} ]
do
  java_parameters="${java_parameters:-}${parameters[${this_parameter}]} "
  this_parameter=`expr ${this_parameter} + 1`
done

cd ${batch_working_directory}
messagelog "java_exe:${java_exe} java_path:${java_path} java_parameters:${java_parameters} ORACLE_USER:${USER_PASS%%/*} ORACLE_SID:${ORACLE_SID}  OUTPUT:${batch_working_directory}"

#### 
####  Starting java procedure.  Need to capture standard output to
####  ${batch_log} so that error handling can be performed.  
####
java -Xms64m -Xmx128m -cp ${java_path} ${java_exe} ${java_parameters} 1>>${batch_log} 2>&1

####
####  Capture return status of java for later evaluation.
####
javareturn_code=$?

#### 
####  Examine the log file to check the exit status.  
####  error strings include "Exception in thread ", "Sql exception ", "ORA-[0-9]", 
####

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
####  Examine the log file to check for "ORA-[0-9]" errors.
####
returnline=`grep 'ORA-[0-9]' ${batch_log}`
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
####  Examine the log file to check for "SQLException" errors.
####
returnline=`grep 'SQLException' ${batch_log}`
debug_var="--->${returnline}<---"
if [ "${returnline:-X}" != "X" ];then
    msg="Error-- ORACLE SQLException errors: --->${returnline}<---. Writing logfile ${batch_log_name}"
    batcherror_notify "${msg}"
fi

####
####  Examine the log file to check for "SQL exception " errors.
####
returnline=`grep 'SQL exception ' ${batch_log}`
debug_var="--->${returnline}<---"
if [ "${returnline:-X}" != "X" ];then
    msg="Error-- ORACLE SQL exception errors: --->${returnline}<---. Writing logfile ${batch_log_name}"
    batcherror_notify "${msg}"
fi

####
####  Examine the log file to check for "java:nnn)" errors.
####
returnline=`grep 'java:[0-9]\{1,\})' ${batch_log}`
debug_var="--->${returnline}<---"
if [ "${returnline:-X}" != "X" ];then
    msg="Error-- JAVA java:nnn) errors: --->${returnline}<---. Writing logfile ${batch_log_name}"
    batcherror_notify "${msg}"
fi

####
####  Examine the log file to check for "Exception in thread " errors.
####
returnline=`grep 'Exception in thread ' ${batch_log}`
debug_var="--->${returnline}<---"
if [ "${returnline:-X}" != "X" ];then
    msg="Error-- JAVA Exception in thread errors: --->${returnline}<---. Writing logfile ${batch_log_name}"
    batcherror_notify "${msg}"
fi

#### 
####  Check to be sure that java successfully started and completed.
####  Perform all error handling here for java errors.  
####
if [ ${javareturn_code} -ne 0 ];then
    msg="Error-- java did not complete successfully. Writing logfile ${batch_log_name}"
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

