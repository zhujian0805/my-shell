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
#  NAME:               FPA_code_promtion_monitoring.ksh
#
#  DESCRIPTION:        This shell script moves files from the code_to_production
#                      directory, to the code_to_production_archive, checks for
#                      code of the same name in the code_waiting directory, and 
#                      sends notification that the code is ready to be processed.
#
#  PARAMETERS:         Code file name
#
#
#*******************************************************************************
# Date         Programmmer      Description
# ----------   --------------   ------------------------------------------
# 2008-08-06   R. Crawford      Initial creation.
# 2010-02-23   J. Thiessen      Modified to deliver code to the production server via the shared drive. 
#
#*******************************************************************************
# Version 2.0
#*******************************************************************************

#
#   email_promotion funtion - Send notice from this script as needed.
#

email_promotion ()
{
  #
  #move messages to BATCH_LOGS to allow email of messages
  #
  
  move_file ${logMessage} ${emailMsgFile}
  
  #
  #check move_file status
  #
  
  ret_val=${?}

  if [ ${ret_val} -ne 0 ];then
    batcherror_notify "ERROR - Email from FPA_code_promtion_monitoring.ksh for ${inFileName} failed."
  fi

  #
  #add tail message to email
  #
  cat ${BATCH_MESSAGES}/general_tail.msg >>${emailMsgFile}
  
  #
  #send email
  #
  
  FPA_email.ksh dl.FPA_code_promotion ${emailMsgFile} Code to be promoted - ${inFileName} -

  #
  #check email status
  #
  
  ret_val=${?}

  if [ ${ret_val} -ne 0 ];then
    batcherror_notify "ERROR - Email from FPA_code_promtion_monitoring.ksh for ${inFileName} was not sent."
  fi
 
} ##end function email_promotion

##########################################################################
#   main script                                                          #
##########################################################################
. ${BATCH_ETC}/.oracle.batch.profile
. ksh_functions.ksh
. batchlog.ksh
logfilename="`basename ${0}`.${1##*/}.${batch_start_dtm}.log"
setlog "${logfilename}"
batchstart

####
#### Set Variables and varify input file
####

emailMsgFile="${BATCH_LOGS}/`basename ${0}`.${1##*/}.${batch_start_dtm}.msg"
logMessage="${batch_working_directory}/`basename ${0}`.${1##*/}.${batch_start_dtm}"
echo "" >${logMessage}

num_args=${#}
if [ ${num_args} -ne 1 ]; then
  msg="ERROR -- Incorrect number of parameters.  ${usage}"
  echo "${msg}" >>${logMessage}
  email_promotion
  batcherror "${msg}"
fi

inFileName=${1:-UNDEFINED}
inFileDir=${BATCH_SYSTEM}/code_to_production
inFileDirArch=${inFileDir}_archive
promFileDir=${BATCH_SYSTEM}/code_waiting
shareFileDir=/asp/share/FPAshare/CLIENT_TEST_PROD/${client:-Variable_client_is_not_defined}/test_to_prod
if [ ! -d ${shareFileDir} ];then
  msg="ERROR - the SHARED directory, ${shareFileDir} does not exist.  Code promotion for ${inFileName} cannot continue. "
  echo "${msg}" >>${logMessage}
  email_promotion
  batcherror "${msg}"
fi

####
#### Check for file in code_to_production directory.
####

if [ -a ${inFileDir}/${inFileName} ];then
  messagelog "File to move - ${inFileName}"
  msg="The file ${inFileName} arrived in the code_to_production directory on `date +'%D'`."
  echo "${msg}" >>${logMessage}
  echo "" >>${logMessage}
  msg=`ls -la ${inFileDir}/${inFileName}`
  echo "${msg}" >>${logMessage}
  echo "" >>${logMessage}
else
  msg="ERROR - File ${inFileName} was not found in ${inFileName} directory."
  echo "${msg}" >${logMessage}
  email_promotion
  batcherror "${msg}"
fi

####
#### Check for duplicate code and build proper email message.
####

#Check for dup code.
if [ -a ${promFileDir}/${inFileName} ];then
  #Build email notification when code is already in the code_waiting directory
  echo "There is already a version of ${inFileName} in the code_waiting directory to be promoted." >>${logMessage}
  msg=`ls -la ${promFileDir}/${inFileName}`
  echo "" >>${logMessage}
  echo "The previous file to be promoted is: " >>${logMessage}
  echo "" >>${logMessage}
  echo "${msg}" >>${logMessage}
  echo "" >>${logMessage}
  echo "The file in the code_waiting directory has been overwritten." >>${logMessage}
else
  #Build email notification when code is NOT in the code_waiting directory
  echo "The file, ${inFileName}, in the code_to_promotion directory has been successfully moved to the code_waiting directory." >>${logMessage}
fi

echo "" >>${logMessage}
echo "Normal SLA for this promotion is 2 business days after the proper forms and approvals are recieved." >>${logMessage}
#copy log messages to log file
cat ${logMessage} >>${BATCH_LOGS}/${logfilename}

####
#### Copy code to the code_waiting directory 
####
copy_file ${inFileDir}/${inFileName} ${promFileDir}/${inFileName} 640 IGNORE
ret_val=${?}    #error check the copy
if [ ${ret_val} -ne 0 ];then
  msg="ERROR - File ${inFileName} was not copied out to the ${promFileDir} directory."
  echo "${msg}" >${logMessage}
  echo "${msg}" >> ${BATCH_LOGS}/FPA.*.cron.log.`date +'%B'`
  email_promotion
  batcherror "${msg}"
else
  msg="CODE_PROMOTION - File ${inFileName} was copied to the ${promFileDir} directory on `date +'%D'` at `date +'%R'`"
  echo "${msg}" >> ${BATCH_LOGS}/FPA.*.cron.log.`date +'%B'`
fi

####
#### Copy code to the SHARED directory 
####
copy_file ${inFileDir}/${inFileName} ${shareFileDir}/${inFileName} 644 IGNORE
ret_val=${?}    #error check the copy
if [ ${ret_val} -ne 0 ];then
  msg="ERROR - File ${inFileName} was not copied out to the ${shareFileDir} directory."
  echo "${msg}" >${logMessage}
  echo "${msg}" >> ${BATCH_LOGS}/FPA.*.cron.log.`date +'%B'`
  email_promotion
  batcherror "${msg}"
else
  msg="CODE_PROMOTION - File ${inFileName} was copied to the ${shareFileDir} directory on `date +'%D'` at `date +'%R'`"
  echo "${msg}" >> ${BATCH_LOGS}/FPA.*.cron.log.`date +'%B'`
fi

####
#### Move code to code_to_production_archive with seq number
####
move_file ${inFileDir}/${inFileName} ${inFileDirArch}/${inFileName}.`date +'%m%d%Y%H%M%S'` 640 IGNORE
ret_val=${?}    #error check the move
if [ ${ret_val} -ne 0 ];then
  msg="ERROR - File ${inFileName} was not moved out of ${inFileDir} directory."
  echo "${msg}" >${logMessage}
  email_promotion
  batcherror "${msg}"
fi

####
#### Send proper email to code_promotion distribution list
####

email_promotion

batchend

