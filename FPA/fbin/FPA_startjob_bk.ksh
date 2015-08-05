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
#  NAME:               FPA_startjob.ksh
#
#  DESCRIPTION:        This script is designed to be used within the FPA in
#                      order to initiate jobs that have been scheduled to begin
#                      after a specified time.  
#
#                      The following describes the mechanism used to initiate 
#                      the jobs.
#                      
#                     
#                      For each job to be started a "Job-Card" must be created 
#                      in the $BATCH_JOBCARDS directory .  The "Job-Card" must be 
#                      named "RunAfterCCYYMMDDHHMISS.<TITLE>.CCYYMMDDHHMISS" 
#                      where the prefix indicates "start the job after this 
#                      time".
#                      the TITLE can be any alpha-numeric character string 
#                      that describes the job to the user and is the text 
#                      from the menu selection; and the suffix is the 
#                      date-time that the Job-Card was created.
#                      NOTE:  Jobs are initiated by the FPA when it runs,
#                      and since the FPA is currently set to run every 5
#                      minutes, jobs may be started  5 minutes later than 
#                      the time specified in the prefix. The prefix contains 
#                      seconds because it allows the users to sequence the 
#                      initiation of jobs.  Jobs will be initiated in the 
#                      time-order specified in the prefix. 
#                      
#                      this will ensure that jobs are initiated in proper 
#                      sequence, according to the user specification.  
#                      Additionally, the "SYNC" functionality will prevent 
#                      concurrent runs of incompatible jobs as describes 
#                      in their documentation.  Furthermore, if a tighter 
#                      schedule is required thhis can easily be accomplished 
#                      by altering the FPA schedule.  
#                      
#                      The Job-Card consists of a variable number of lines.  
#                      The first line is the statement that will actually be 
#                      executed -- the job name and all the appropriate 
#                      parameters. 
#                      
#                      The second line starts with a pound sign and contains 
#                      the name of the menu option that was selected to 
#                      create the jobcard.
#
#                      Subsequent lines contain the parameter values that 
#                      were set on the menu system, one line for each 
#                      parameter.  Note that the user-definable parameters 
#                      are the ones on the menu and also recorded on these 
#                      lines in the Job-Card.  These user-defined parameters 
#                      are not necessarily the same or in the same order as 
#                      the parameters on the execution line.  These 
#                      subsequent lines are for information only -- changing 
#                      any values on those lines will not change any run 
#                      characteristics of the job, it only tells the users 
#                      what parameters were set when creating this Job-Card 
#                      and the purpose is to clearly differentiate between 
#                      jobs.  each line begins with a # 
#                      the third and second to the last lines describe the 
#                      use of the 'output file prefix' which is stored in 
#                      the last line.  
#                      
#                      Example JOBCARD:
#                         FPA_nohup.ksh sql.ksh member_extract.sql wphsadv M
#                         #  MEMBERS
#                         #  Menu Parameter NOTUSED ## NOTUSED 
#                         #  Menu Parameter Change Vendor Selection (only one character) ## M 
#                         #  If no prefix is desired, the word must be NULL without the quotes.  
#                         #  NULL
#
#
#                      This script requires 1 positional argument.  
#
#                      The first argument is the name (without the path!) of 
#                      the Job-Card to be started.
#
#
#                      It is an error to call this script without proper 
#                      arguments.
#
#  
#  EXT DATA FILES:     The JobCard file which contains the instructions for
#                      running a job.
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
# 02/07/2002   J. Thiessen      New code. 
# 01/11/2003   J. Thiessen      Added coded to set variable for prefixing output
#                               files when specified.  
# 03/10/2003   J. Thiessen      removed explicit path references to allow the 
#                               PATH to select the proper version or custom
#                               executables. 
#
#
#*******************************************************************************


##########################################################################
#   main script                                                          #
##########################################################################

. ~/.FPAprofile     
. batchlog.ksh
batchsync_filename=${batch_prg}.sync
NO_OUTPUT="TRUE"
NO_SUMMARY_MSGS=TRUE              # be sure that the job started does NOT have this variable set. (don't export it!!)
APPEND_LOG_FILE=TRUE      # be sure that the job started does NOT have this variable set.
setlog ${batch_prg}.`date +'%Y%m%d'`
batchstartsync

. ksh_functions.ksh               #  READS THE DATE AND RUN_SEQUENCE FUNCTIONS

unset FPA_OUTPUTFILEPREFIX     # be sure that this variable is not still defined
if [ ${#} -ne 1 ]
then
  msg="${batch_prg} ERROR -- Improper arguments:-->${*:-NoArguments}<--"
  batcherror_notify "${msg}"
fi
my_jobcard="${BATCH_JOBCARDS}_processing/${1}"

mv ${BATCH_JOBCARDS}/${1} ${my_jobcard}
if [ $? -ne 0 ];then
  msg="${batch_prg} ERROR -- unable to mv ${BATCH_JOBCARDS}/${1} to processing directory. "
  batcherror_notify "${msg}"
fi

if [ ! -r ${my_jobcard} ];then
  msg="${batch_prg} ERROR -- cannot read ${my_jobcard}. "
  batcherror_notify "${msg}"
fi

commandline=`head -1 ${my_jobcard}`
if [ $? -ne 0 ];then
  msg="${batch_prg} ERROR -- ${my_jobcard} contains invalid data:-->${commandline:-Line1Undefined}<-- "
  batcherror_notify "${msg}"
fi
####
####  JPT 20030111 set variable for "output file prefix" if necessary
####  
outputprefix=`grep "^#  PREFIX:" ${my_jobcard} | head -1` >/dev/null 2>&1
outputprefix=`echo ${outputprefix:-NULL} | cut -d : -f 2 | sed 's/ //g'`
if [ "${outputprefix:-NULL}" != "NULL" ];then
  export FPA_OUTPUTFILEPREFIX=${outputprefix}
fi

####
####  JPT 20020423 handle job sequences like DAILY JOBS 
####  
n=${#commandline}
tmp=`echo ${commandline} | cut -c$n`
if [ "${tmp:-X}" = "&" ];then
  cmd="${commandline}"
  sbl="${BATCH_LOGS}/batch_summary.`date +'%Y%m%d'`"
  step=1
  ck="if [ \${?} -eq 0 ]\;then echo \"Successfully Completed Step \${step}\">>${sbl}\;step=\`expr \${step} + 1\`\;else echo \"ERROR IN STEP \${step}\">>${sbl}\;exit 5\;fi"

else
  cmd="FPA_nohup.ksh ${commandline}"
fi
 
eval ${cmd}
cmd_return=$?
unset FPA_OUTPUTFILEPREFIX     # explicitly clear this variable 
if [ ${cmd_return} -ne 0 ]; then
  msg="${batch_prg} ERROR -- Problem executing ${cmd:-cmdUndefined} "
  batcherror_notify "${msg}"
fi

messagelog "The command \"${cmd}\" from file ${1} executed successfully. "

mv ${my_jobcard} ${BATCH_JOBCARDS}_archive/${1} 
if [ $? -ne 0 ];then
  msg="${batch_prg} ERROR -- unable to mv ${my_jobcard} to archive directory. "
  batcherror "${msg}"
fi

batchend

