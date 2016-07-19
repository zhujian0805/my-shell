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
#  NAME:               FPA_processjobcards.ksh
#
#  DESCRIPTION:        This script is designed to be used within the FPA in
#                      order to monitor the scheduled JobCards and process 
#                      those that are now supposed to run.  
#
#                      This process is designed to be called by the FPA, though
#                      it could also be initiated directly from cron.  
#                      
#                      The program flow is as follows:
#                      1)  produce a listing ($BATCH_TMP/JobList.processing) of the job cards in the $BATCH_JOBCARDS directory
#                      2)  compare this listing with JobList.previous and record any differences in the daily batch_summary file.
#                      3)  walk through the listing, processing each JobCard, until finding a JobCard with a future date-time or reaching the end of list.
#                      4)  record each start in the daily batch_summary file ??
#                      5)  If JobList has changed, then copy JobList.processing to JobList.previous 
#                      5)  Move JobList.processing to JobList.most_recent 
#                      6)  NOTE: that JobCards processed here will be moved to the processing directory and then the archive directory, so there will be reported as changes in the next run.  Want to indicate that these jobs were processed properly to differentiate from those jobs that were deleted or altered.
#                      7)  
#                      8)  
#                      9)  
#                     
#                      For each job to be started a "Job-Card" must be created 
#                      in the $BATCH_JOBCARDS directory .  The "Job-Card" must be 
#                      named "RunAfterCCYYMMDDHHMISS.<TITLE>.CCYYMMDDHHMISS" 
#                      where 
#                      the prefix indicates "start the job after this time"; 
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
#                      The subsequent lines contain the parameter values that 
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
#                      jobs.

#                      h




#
#
#
#  
#  EXT DATA FILES:     The JobCard file which contains the instructions for
#                          running a job.
#                      JobList.processing in $BATCH_TMP contains the list 
#                          of JobCards being processed. (only exists while 
#                          this job is running.)
#                      JobList.previous in $BATCH_TMP contains the previous 
#                          list of JobCards.  This list updated only when 
#                          the list JobList changes, not every run.  
#                      JobList.most_recent in $BATCH_TMP contains the list 
#                          of JobCards from the most recent prior run.  This 
#                          list updated at the end of every run.
#                      JobList.diff in $BATCH_TMP contains the differences 
#                          between JobList.processing and JobList.previous 
#                          and is overwritten during each run.
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
####  batchsync_filename="SYNC.${batch_prg}"  #### JPT 20050418 removed. Now using batchstartunique.
NO_OUTPUT="TRUE"
NO_SUMMARY_MSGS=TRUE      # be sure that the job started does NOT have this variable set.
APPEND_LOG_FILE=TRUE      # be sure that the job started does NOT have this variable set.
setlog ${batch_prg}.`date +'%Y%m%d'`
batchstartunique   ####  JPT 20050418 Changed to prevent sync problems with system downtime -- was batchstartsync

if [ ${#} -ne 0 ]
then
  msg="${batch_prg} ERROR -- USAGE: Improper arguments:-->${*}<--"
  batcherror_notify "${msg}"
fi
####  
####  Definitions
####  
my_job_list=JobList.processing
prev_job_list=JobList.previous
num_jobs_started=0
job_list_diff=JobList.diff
most_recent_job_list=JobList.most_recent

####  
####  Be sure previous run completed properly...
####  
if [ -a ${BATCH_TMP}/${my_job_list} ];then
  msg="WARNING -- file ${my_job_list} already exists"
  messagelog "${msg}"
  mv ${BATCH_TMP}/${my_job_list} ${BATCH_LOGS}/${my_job_list}.WARNING.${batch_start_dtm}
  if [ $? -ne 0 ];then
    msg="Cannot recover from an error in a previous run. "
    batcherror_notify "${msg}"
  fi
fi

####  
####  Create the new file listing
####  
echo "${batch_start_dtm} is the date time that this JobCard listing was created. " > ${BATCH_TMP}/${my_job_list}
ls -1 ${BATCH_JOBCARDS}/RunAfter* >> ${BATCH_TMP}/${my_job_list} 2>/dev/null   # JPT 20030619 redirected stderr to eliminate err msgs in cronlog when no JobCards exist.

####  
####  Process the new file listing
####  
my_jobcard_prefix="RunAfter${batch_start_dtm}"
num_job_list_lines=`cat ${BATCH_TMP}/${my_job_list} | wc -l`
count=1               # ignore the first line that contains the time that the list was created.
while [ ${count} -lt ${num_job_list_lines} ]
do
  count=`expr ${count} + 1`
  job_list_line=`sed -n ${count}p ${BATCH_TMP}/${my_job_list}`
  job_card_name=${job_list_line##*/}
  if [[ ${job_card_name} < ${my_jobcard_prefix} ]];then
    num_jobs_started=`expr ${num_jobs_started} + 1`
    msg="Starting job ${num_jobs_started}: ${job_list_line}"
    messagelog "${msg}"
    FPA_startjob.ksh ${job_card_name}
    if [ $? -ne 0 ];then
      msg="Problem starting job: FPA_startjob.ksh ${job_card_name} (`which FPA_startjob.ksh`)"
      batch_notify "${msg}"
    fi
  else
    count=`expr ${num_job_list_lines} + 1`   #  This is a sorted list, no need to continue.
  fi
  sleep 2
done

####  
####  Compare with previous JobCard listing.  
####  
if [ ! -a ${BATCH_TMP}/${prev_job_list} ];then
  msg="WARNING -- No Previous Job List, creating ${BATCH_TMP}/${prev_job_list} "
  messagelog "${msg}"
  cp ${BATCH_TMP}/${my_job_list} ${BATCH_TMP}/${prev_job_list} 
fi
if [  -a ${BATCH_TMP}/${job_list_diff} ];then
  rm -f ${BATCH_TMP}/${job_list_diff} 
fi
diff ${BATCH_TMP}/${prev_job_list} ${BATCH_TMP}/${my_job_list} > ${BATCH_TMP}/${job_list_diff}  # overwrite the file 
if [ ! -a ${BATCH_TMP}/${job_list_diff} ];then
  msg="Problem generating the diff list ${BATCH_TMP}/${job_list_diff} "
  batcherror_notify "${msg}"
fi

####  
####  Record changes if JobCard listing has been modified since last run.
####  There are 4 lines in the diff output if the date-time line is the 
####  only difference in the listings.  
####  
num_diff_lines=`cat ${BATCH_TMP}/${job_list_diff} | wc -l`
if [ ${num_diff_lines} -ne 4 ];then      # JPT NOT VALIDATED AIX
  cp ${BATCH_TMP}/${my_job_list} ${BATCH_LOGS}/scheduled_job_listing.${batch_start_dtm}
  if [ $? -ne 0 ];then
    msg="Problem with: cp ${BATCH_TMP}/${my_job_list} ${BATCH_LOGS}/scheduled_job_listing.${batch_start_dtm} "
    batcherror_notify "${msg}"
  fi
  cp ${BATCH_TMP}/${my_job_list} ${BATCH_TMP}/${prev_job_list}
  if [ $? -ne 0 ];then
    msg="Problem with: cp ${BATCH_TMP}/${my_job_list} ${BATCH_TMP}/${prev_job_list} "
    batcherror_notify "${msg}"
  fi
fi

mv ${BATCH_TMP}/${my_job_list} ${BATCH_TMP}/${most_recent_job_list}
if [ $? -ne 0 ];then
  msg="${batch_prg} ERROR -- unable to mv ${my_job_list} to ${most_recent_job_list} "
  batcherror "${msg}"
fi

batchend
