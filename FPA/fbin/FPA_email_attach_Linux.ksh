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
#  NAME:              FPA_email_attach.ksh
#
#  DESCRIPTION:       This module sends an email to a specified distribution 
#                     list.  The distribution list is kept in BATCH_ETC and is 
#                     provided as the first parameter.  The contents of the 
#                     e-mail is specified by passing the filename containing 
#                     the contents as the second parameter.  The email's 
#                     subject line is comprised of the remaining parameters.  
#                     Note that the file is sent as included text, not as an 
#                     attachment.  Attachment is the addition to the FPA_email.ksh
#                     code.
#
#                     NOTE: If FPA_email.ksh is modified, this program may also
#                     require modification.
#  
#  EXT DATA FILES: 
#
#  ENV VARIABLES:   
#   
#  INPUT:             $1 is name of distribution list which must be kept in
#                        ${BATCH_ETC} directory.
#                     $2 is the filename of attachment
#                     $3 is the filename (with full path) to be sent.
#                     $4 and all additional args comprise the subject line
#                        for the e-mail.  
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
# 03/29/2005   R.Crawford       New code.  Modification of FPA_email.ksh
# 03/29/2006   R.Crawford       Added comments and error check for attached file
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
setlog ${batch_prg}.`date +'%Y%m%d'`
batchstart

num_args=${#@}
if [ ${num_args} -lt 3 ]; then
  msg="ERROR -- USAGE: FPA_email_attach.ksh DISTRIBUTION_LIST FILENAME <SUBJECT LINE>. ${*:-No_Arguments_Supplied} "
  batcherror_notify "${msg}"
fi


dist_list="${1:-UNDEFINED}"
file_attached="${2:-AttachedFileNotSpecified}"
email_contents="${3:-FileNotSpecified}"
subject=""
set -A arg_list ${*}
loopcnt=3
while [ ${loopcnt} -lt ${num_args} ]
do
  subject="${subject}${arg_list[${loopcnt}]} "
  loopcnt=`expr ${loopcnt} + 1`
done
if [ ${#subject} -eq 0 ]; then
  subject="Diamond ASP Notice `date`"
fi

if [ ! -r ${BATCH_ETC}/${dist_list} ]; then
  msg="INVALID DISTRIBUTION LIST ${dist_list} "
  batcherror_notify "${msg}"
fi
if [ ! -r ${email_contents} ]; then
  msg="CANNOT READ CONTENTS  ${email_contents} "
  batcherror_notify "${msg}"
fi
if [ ! -r ${file_attached} ]; then
  msg="CANNOT FIND ATTACHED FILE - ${file_attached} "
  batcherror_notify "${msg}"
fi
if [ -d ${file_attached} ]; then
  msg="ERROR ATTACHING FILE - ${file_attached} is a directory"
  batcherror_notify "${msg}"
fi
####
####  Confirm that data to be sent is located in a permitted directory.
####
root_dir=${BATCH_LOGS%/*}
echo ":${email_contents}:" | grep  ^:${root_dir} > /dev/null 2>&1
if [ ${?} -ne 0 ]; then  #### successful grep returns zero, found the string
  msg="ERROR -- Cannot Access file ${email_contents} . . . not in path "
  batcherror_notify "${msg}"
fi
###
###  Prevents configuration files are emailed.
###
echo ":${file_attached}:" | grep  ^:${root_dir} > /dev/null 2>&1
if [ ${?} -ne 0 ]; then  #### successful grep returns zero, found the string
  msg="ERROR -- Cannot Access file ${file_attached} . . . not in path "
  batcherror_notify "${msg}"
fi
file_attach_name=`basename ${file_attached}`
mailtousers=`cat ${BATCH_ETC}/${dist_list} | tr '\012' ' '`
###
### For testing the attached file is from BATCH_LOGS.  Must be changed.
###
#mailx -s "${subject} FPA ${BATCH_PROD:+PRODUCTION}${BATCH_TEST:+test} ${ORACLE_SID}" ${mailtousers} <<-EOF
#`cat ${email_contents}`
#~:set mimeheader=no
#~<!awk '{printf "%s\r\n", \$0}' ${file_attached} | uuencode ${file_attach_name}
#EOF
(cat ${email_contents}; uuencode ${file_attached} ${file_attached##*/}) | mail -s "${subject} FPA ${BATCH_PROD:+PRODUCTION}${BATCH_TEST:+test} ${ORACLE_SID}" ${mailtousers}
OK=$?

if [ ${OK} -ne 0 ]; then
  msg="Problem emailing ${email_contents} to ${dist_list} "
  batcherror_notify "${msg}"
fi

batchend
