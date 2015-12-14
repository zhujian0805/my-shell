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
#  NAME:               test_params.ksh	 
#
#  DESCRIPTION:        This korn shell script tests the parameters sent to it...
#
#  
#  EXT DATA FILES: 
#
#  ENV VARIABLES:      Standard Batch Variables (
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
# 11/05/2001   J. Thiessen      New code. 
#
#
#*******************************************************************************

##########################################################################
#   main script                                                          #
##########################################################################

. ${BATCH_ETC}/.oracle.batch.profile
. ksh_functions.ksh
. batchlog.ksh
batchstart

batch_log_path=${batch_log%/*}
batch_log_name=`basename ${batch_log}`

usage="Usage: ${batch_prg} parameters "
num_args=${#}
sql_parameters=""
set -A parameters `echo ${*} | sed s:batch_working_directory:${batch_working_directory}:g`

this_parameter=0
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
echo | cat <<-ENDSQL 1>>${batch_log} 2>&1
    whenever sqlerror exit failure
    set echo off
--    set serveroutput on size 200000;
    @${BATCH_SQLBIN}/${sql_name} ${sql_parameters}
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
####  Check to be sure that the pl/sql procedure successfully started 
####  and completed.
####  Perform all error handling here for pl/sql errors.  
####
if [ ${procreturn_code} -ne 0 ];then
    msg="Error in SQL in ${batch_prg}"
    batcherror_notify "${msg}"
fi

batchend

