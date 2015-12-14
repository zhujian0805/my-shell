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
#  NAME:               batchlog.ksh
#
#  DESCRIPTION:        This is the standard batch logging program for Korn. It
#                      is to be "sourced" into all korn shell scripts, it will
#                      not be executed as a standand alone program.  It has no
#                      arguments, but uses system variables like $$ and $0 to
#                      obtain and log the the process-id and the script-name 
#                      respectively.
#
#                      NOTE:  if the NO_OUTPUT variable is NOT defined then 
#                      batchstart causes the process to cd into the 
#                      directory $batch_working_directory
#  
#  EXT DATA FILES:     N/A
#
#  ENV VARIABLES:      LOGNAME
#                      BATCH_LOGS
#                      
#                      The following list of variables are not environment
#                      variables, but they are available to all korn shell
#                      scripts that use standard batchlog.
#                          batch_log
#                          batch_prg
#                          batch_sys
#                          batch_args
#                      
#                      Additionally, this routine uses the following variables 
#                      so if the korn shell script also uses variables of the 
#                      same name, they will be modified by calls to batchlog 
#                      functions.  
#                          currdtm_dt
#                          currdtm_tm
#                          txtmsg
#                          logmsg
#                          return_status
#                      
#                      
#   
#  INPUT:              system variables like ${$} and ${0}
#                     
#
#  OUTPUT:             Writes messages to the logfile contained in $batch_log.
#                      Unless the korn shell program overrides the default
#                      value of $batch_log by calling the setlog function 
#                      before calling batchstart, the $batch_log will 
#                      be "${0}.log".
#
#  TEMPORARY FILES:    N/A
#
#  EXT FUNC CALLS:     N/A
#
#  EXT MOD CALLS:      N/A
#
#*******************************************************************************
# Date         Programmmer      Description
# ----------   --------------   ------------------------------------------
# 11/05/2001   J. Thiessen      New code. 
# 01/02/2002   J. Thiessen      Added batchstartsync functionality. 
# 02/08/2002   J. Thiessen      Added subject line to error messages.
# 03/27/2002   J. Thiessen      Modified to create a working directory for the 
#                               output of each job and to move these output 
#                               files into $BATCH_OUTPUT upon successful 
#                               completion. 
# 05/02/2002   J. Thiessen      Moved error messages to its own daily log file.
# 05/07/2002   J. Thiessen      Moved SYNC files to sync_files directory and 
#                               added the master archive directory to store 
#                               output before cp-ing from batch_working_directory
# 03/10/2003   J. Thiessen      removed explicit path references to allow the 
#                               PATH to select the proper version or custom
#                               executables. 
# 06/18/2003   J. Thiessen      Added cleanup for my_tmp_queue files. 
# 04/06/2004   J. Thiessen      Added variable batch_run_dhm for ftp sync-ing. 
# 04/07/2004   J. Thiessen      Added function messagelog_summary 
# 10/25/2004   J. Thiessen      Adding batchstartunique 
#
#*******************************************************************************

####----------------------------------------------------------------------------
####
####  The function writelog is the function that actually places the message
####  into the log file.
####

writelog() {
currdtm
echo "\nDate: ${currdtm_dt}    Time: ${currdtm_tm}\n${1}"  >> ${batch_log}
}  ####  END FUNCTION writelog

####----------------------------------------------------------------------------
####
####  The function currdtm updates the variables, currdtm_dt and currdtm_tm
####  containing the current date and time respectively.
####

currdtm() { 
currdtm_dt=`date +'%m/%d/%Y'`
currdtm_tm=`date +'%H:%M:%S'`
}  ####  END FUNCTION currdtm

####----------------------------------------------------------------------------
####
####  The function batchstartunique checks to be sure that an incompatible job 
####  is not currently running and simply exits if an incompatible job is 
####  running.  batchstartunique is similar to batchstartsync, but 
####  batchstartunique will not begin executing the job if an 
####  incompatibility is discovered while batchstartsync will queue the 
####  current job to begin after the conflicting job(s) has completed.  
####  batchstartunique will accept a parameter to indicate the name of the 
####  file to be used to determine whether or not an incompatible job is 
####  running, but will default to the name of the job being executed with 
####  a suffix of '.uni'.  This file will be located in the 
####  $BATCH_SYSTEM/sync_files directory.  
####
####  batchstartunique will create this file if it does not exist, and each 
####  of the 'exit' processes will remove this file if the job created it.  
####
####  NOTE: If a job is killed by a system downtime or by an explicit kill 
####  command etc. then this file will need to be removed manually. 
####

batchstartunique() { 
####  
####  First, issue the batchstart to record the attempt to start.  
####  
batchstart
batchuniquefilename=${BATCH_SYSTEM}/sync_files/${1:-${batch_prg}}.uni
err_flag_name=${BATCH_FLAGS}/`basename ${batchuniquefilename}`

if [ -a ${batchuniquefilename} ]; then 
  conflict_msg=`head -1 ${batchuniquefilename}`
  messagelog_summary "NOTICE: Will not start ${batch_prg} due to conflicting job: ${conflict_msg:-UnknownJob}"
  echo "NOTICE: Will not start ${batch_prg} due to conflicting job: ${conflict_msg:-UnknownJob}" >> ${err_flag_name}
  echo "NOTICE: Will not start ${batch_prg} due to conflicting job: ${conflict_msg:-UnknownJob}" >> ${batchuniquefilename}
  unset batchuniquefilename     ## Do not let batchend remove batchuniquefilename because the previous job is still running. 
  batchend   ## exit the program.
else
  batchuniquestring="Job PID ${$} is ${batch_prg:-UnknownProgram} ${batch_args:-NoArgs} started at ${batch_start_dtm:-UnknownTime}"
  echo "${batchuniquestring}" >> ${batchuniquefilename}
  sleep `expr $$ % 10`    ## sleep for a 'random' number of seconds as a precaution against concurrent updates.
  conflict_msg=`head -1 ${batchuniquefilename}`
  if [ "-->${conflict_msg}<--" != "-->${batchuniquestring}<--" ]; then
    messagelog_summary "NOTICE:   Will not start ${batch_prg} due to conflicting job: ${conflict_msg:-UnknownJob}"
    echo "NOTICE: Will not start ${batch_prg} due to conflicting job: ${conflict_msg:-UnknownJob}" >> ${err_flag_name}
    echo "NOTICE: Will not start ${batch_prg} due to conflicting job: ${conflict_msg:-UnknownJob}" >> ${batchuniquefilename}
    unset batchuniquefilename  ## Do not let batchend remove batchuniquefilename because the previous job is still running.
    batchend   ## exit the program.
  fi
  unset conflict_msg
fi

 
}  ####  END FUNCTION batchstartunique

####----------------------------------------------------------------------------
####
####  The function batchstartsync checks to be sure that incompatible jobs are
####  not currently running before calling batchstart to begin execution.  This 
####  is accomplished by means of a syncfile in the $BATCH_SYSTEM/sync_files directory.  This
####  function examines the variable $batchsync_filename to determine the name 
####  of the file on which to synchronize.  If the variable is not set the 
####  process will abort. 
####  This function will also examine the variables $batchsync_interval, 
####  $batchsync_too_many_cycles $batchsync_clear_sync_on_error for additional 
####  configuration, but will use defaults for these values if they are not 
####  already set. 
####  The queueing method will ensure that multiple synchronized jobs are run 
####  in the order in which they were first processed, measured down to the 
####  second -- the FPA sleeps 1 second between processing files to ensure 
####  that each process begins in a different second.  
####  batchend must also be modified to clear (that is, delete the entry from 
####  the file $batchsync_filename upon successful completion. 
####  Each batch abort option must also be modified to examine 
####  $batchsync_clear_sync_on_error to determine whether or not to clear 
####  the $batchsync_filename .  
####  
####  
####  batchsync_filename
####  batchsync_interval
####  batchsync_too_many_cycles
####  batchsync_clear_sync_on_error
####  
####  
####  
####  

batchstartsync() {
####  
####  First, issue the batchstart to record the attempt to start.  
####  

syncing=TRUE
batchstart

####  
####  Check to be sure that $batchsync_filename is defined -- abort if 
####  it has not been defined.  
####  
if [ "${batchsync_filename:-X}" = "X" ];then
  logmsg="--ERROR  batchsync_filename has not been defined.  "
  batcherror_notify "${logmsg}"
fi
    
####
####  Check and define undefined variables.
####  
#sleep_period=${batchsync_interval:=30}   ## Default to 30 seconds if not set. FOR TESTING
sleep_period=${batchsync_interval:=600}   ## Default to 10 minutes if not set.
max_wait=${batchsync_too_many_cycles:=3}   ## Default to 3 loops before sending warnings.

####  
####  Create or append to the queue file, ie the sync-file
####  
sync_line="$$ at ${batch_start_dtm} from job ${batch_log##*/} ${batch_args} in thread ${batchthread_start_dtm:-NoThread}" 
echo ${sync_line}  >>  ${BATCH_SYSTEM}/sync_files/${batchsync_filename}
if [ $? -ne 0 ];then 
  batcherror_notify "--ERROR  Problem appending ${sync_line} to the sync-file: ${BATCH_SYSTEM}/sync_files/${batchsync_filename} "
fi
if [ ! -a  ${BATCH_SYSTEM}/sync_files/${batchsync_filename} ];then
   batcherror_notify "--ERROR  Problem creating the sync-file: ${BATCH_SYSTEM}/sync_files/${batchsync_filename} "
fi
messagelog "Syncing on file ${batchsync_filename} -- contents shown below "
cat  ${BATCH_SYSTEM}/sync_files/${batchsync_filename} >> ${batch_log}
echo "-- SYNC FILE CONTENTS SHOWN ABOVE --"  >> ${batch_log}

####  
####  Loop until this process is first in the queue file (sync-file)
####  
my_tmp_queue=${BATCH_TMP}/${batchsync_filename}.PID$$
my_place=99
waiting=0
while [ ${my_place} -ne 1 ]
do
  ####  
  #### Confirm that the queue exists...
  ####  
  if [ -a  ${BATCH_SYSTEM}/sync_files/${batchsync_filename} ];then
    cp ${BATCH_SYSTEM}/sync_files/${batchsync_filename} ${my_tmp_queue}
    if [ $? -ne 0 ]; then 
      sleep 2
      cp ${BATCH_SYSTEM}/sync_files/${batchsync_filename} ${my_tmp_queue}
      if [ $? -ne 0 ]; then 
        batcherror_notify "--ERROR  unable to create my_tmp_queue by: cp ${BATCH_SYSTEM}/sync_files/${batchsync_filename} ${my_tmp_queue} "
      fi
    fi
    sync         # ensure that the file is completely copied
    queue_size=`wc -l ${my_tmp_queue} |awk '{print $1}'`
  else
    messagelog "--WARNING. SOMETHING DELETED the sync file ${BATCH_SYSTEM}/sync_files/${batchsync_filename} including this process ->${sync_line}<- "
    echo "${sync_line}"  >>  ${BATCH_SYSTEM}/sync_files/${batchsync_filename}
    if [ $? -ne 0 ];then 
      batcherror_notify "--ERROR  problem recreating sync-file ${BATCH_SYSTEM}/sync_files/${batchsync_filename} with ${sync_line} "
    fi
    queue_size=1
  fi
  if [ ${queue_size} -lt 1 ];then
     batcherror_notify "--ERROR  Invalid queue_size ${queue_size} in ${BATCH_SYSTEM}/sync_files/${batchsync_filename} "
  fi
  ####  
  ####  Find my_place in the queue...
  ####  
  count=0
  my_place=0
  while [ ${count} -lt ${queue_size} ]
  do
    count=`expr ${count} + 1`
    a_sync_line=`sed -n ${count}p ${my_tmp_queue}`
    echo "#${a_sync_line}#" | grep "#${sync_line}#" > /dev/null 2>&1
    ret_val=$?
    if [ ${ret_val} -eq 0 ]; then
      if [ ${my_place} -eq 0 ];then
        my_place=${count}
        break    ####  No need to continue looking...
      else 
        batcherror_notify "--ERROR  Duplicate entry in ${BATCH_SYSTEM}/sync_files/${batchsync_filename}: #${sync_line}#"
      fi
    fi
  done

  ####  
  ####  Confirm that the queue values are reasonable...
  ####  
  if [ ${my_place} -eq 0 ];then
    my_place=98
    grep "^${sync_line}$" ${BATCH_SYSTEM}/sync_files/${batchsync_filename}
    if [ $? -ne 0 ]; then
      messagelog "--WARNING  PROCESS DELETED: this process ->${sync_line}<- was deleted from the sync queue ${BATCH_SYSTEM}/sync_files/${batchsync_filename} "
      echo ${sync_line}  >>  ${BATCH_SYSTEM}/sync_files/${batchsync_filename}
      if [ $? -ne 0 ];then 
        batcherror_notify "--ERROR  problem appending ${sync_line} to the sync-file: ${BATCH_SYSTEM}/sync_files/${batchsync_filename} "
      fi
    else
      FPA_email.ksh  dl.psc_support ${BATCH_SYSTEM}/sync_files/${batchsync_filename} FPA SYNC FILE--WARNING temporarily misplaced syncline ${sync_line}
      FPA_email.ksh  dl.psc_support ${my_tmp_queue} my_tmp_queue SYNC FILE--WARNING temporarily misplaced syncline ${sync_line}
      messagelog "--WARNING temporarily misplaced syncline ${sync_line} in ${BATCH_SYSTEM}/sync_files/${batchsync_filename} "
    fi
  fi
  if [ ${my_place} -ne 1 ];then
    waiting=`expr ${waiting} + 1`
    if [ ${waiting} -eq ${max_wait} ];then
       batch_notify "--WARNING  ${waiting} waits for ->${sync_line}<- is #${my_place} in queue. There may be a problem. "
    else
      num_ahead=`expr ${my_place} - 1`
      messagelog "--SYNC  ${waiting} Waiting for ${num_ahead} of ${queue_size} other jobs to complete before starting.  "
    fi
    sleep ${sleep_period}
  fi

done
if [ -a ${my_tmp_queue} ];then   #  JPT 20030618  remove the tmp_queue file when done...
   rm ${my_tmp_queue}
fi
set_startflag
messagelog "--SYNC  ${waiting} Now ready to run. "

}  ####  END FUNCTION batchstartsync

####----------------------------------------------------------------------------
####
####  The function remove_sync
####
remove_sync() {
messagelog "REMOVING SYNC FROM file ${batchsync_filename} "
cat  ${BATCH_SYSTEM}/sync_files/${batchsync_filename} >> ${batch_log}
echo "-- SYNC FILE CONTENTS SHOWN ABOVE --"  >> ${batch_log}
sleep 5
batchsync_clear_sync_on_error="FALSE"        ####  be sure to prevent looping if this process errs.
####  
####  Check to be sure that the required variables are defined -- error_notify if 
####  variables are missing.
####      $batchsync_filename 
####      $sync_line
####  
if [ "${batchsync_filename:-X}" = "X" ];then
  logmsg="--ERROR in remove_sync:  batchsync_filename has not been defined.  "
  batcherror_notify "${logmsg}"
fi
if [ "${sync_line:-X}" = "X" ];then
  logmsg="--ERROR in remove_sync:  sync_line has not been defined.  "
  batcherror_notify "${logmsg}"
fi
if [ ! -w ${BATCH_SYSTEM}/sync_files/${batchsync_filename} ];then
  logmsg="--ERROR in remove_sync:  ${BATCH_SYSTEM}/sync_files/${batchsync_filename} is not writable.  "
  batcherror_notify "${logmsg}"
fi

####  check the first line of the file and cut it
####  walk through the file once
queue_size=`wc -l ${BATCH_SYSTEM}/sync_files/${batchsync_filename} | awk '{print $1}'`
a_sync_line=`sed -n 1p ${BATCH_SYSTEM}/sync_files/${batchsync_filename}`
echo "#${a_sync_line}#" | grep "#${sync_line}#" > /dev/null 2>&1
ret_val=$?
if [ ${ret_val} -ne 0 ]; then
  batcherror_notify "--ERROR  Cannot remove sync_line from ${BATCH_SYSTEM}/sync_files/${batchsync_filename}: #${sync_line}#"
fi
if [ ${queue_size} -eq 1 ]; then
  rm -f ${BATCH_SYSTEM}/sync_files/${batchsync_filename}
  ret_val=$?
  if [ ${ret_val} -ne 0 ]; then
    batcherror_notify "--ERROR  Cannot remove the file ${BATCH_SYSTEM}/sync_files/${batchsync_filename}: #${sync_line}#"
  fi
else
  cp ${BATCH_SYSTEM}/sync_files/${batchsync_filename} ${BATCH_SYSTEM}/sync_files/${batchsync_filename}.lock
  sed 1,1d ${BATCH_SYSTEM}/sync_files/${batchsync_filename}.lock > ${BATCH_SYSTEM}/sync_files/${batchsync_filename}
  ret_val=$?
  if [ ${ret_val} -ne 0 ]; then
    batcherror_notify "--ERROR  Problem removing sync_line from ${BATCH_SYSTEM}/sync_files/${batchsync_filename}: #${sync_line}#"
  fi
  rm -f ${BATCH_SYSTEM}/sync_files/${batchsync_filename}.lock
fi

}  ####  END FUNCTION remove_sync


####----------------------------------------------------------------------------
####
####  The function batchstart creates a logfile for jobs that are running for
####  the first time, and appends a standard message indicating the initiation
####  of the batch job that calls it.  It also creates and cd's to a "working 
####  directory" named $PID in the ${BATCH_SYSTEM}/jobs/running directory. 
####
batchstart() {

if [ ! -a ${batch_log} ] 
then
  echo "" >> ${batch_log}
  chmod 666 ${batch_log}
fi
if [ ! -w ${batch_log} ]
then
  currdtm
  txtmsg="--ERROR in ${batch_prg} :ON ${batch_sys}:Unable to write to ${batch_log} "
  logmsg="${txtmsg} | AT ${currdtm_dt} ${currdtm_tm} | USER=${LOGNAME} | "
  logmsg="${logmsg}PID=$$  | ARGS=${batch_args} | "
  setlog "batchlog.ksh.log"
  messagelog "${logmsg}"   
  batcherror_notify "${txtmsg}"
fi
currdtm
logmsg="--START ${batch_prg} | ON ${batch_sys} | AT ${currdtm_dt} ${currdtm_tm} | USER=${LOGNAME} | PID=$$ | ARGS=${batch_args} | THREAD=${batchthread_start_dtm:-NA} |"
if [ "${NO_SUMMARY_MSGS:-X}" != "TRUE" ];then
  echo "${logmsg}" >> ${BATCH_LOGS}/batch_summary.`date +'%Y%m%d'`
fi
writelog "${logmsg}"

if [ "${syncing:-X}" != "TRUE" ];then
  set_startflag
fi

####  
####  Create working directory if needed...
####  
if [ "${NO_OUTPUT:-X}" = "X" ]; then
  messagelog "The output file prefix is: ${FPA_OUTPUTFILEPREFIX:-NULL} for the output from this job."
  batch_working_directory="${BATCH_SYSTEM}/jobs/running/`basename ${batch_log} | cut -d. -f1-2`.$$"
  batch_working_directory=`echo "${batch_working_directory}" | sed 's/\./-/g'`
  if [ -d ${batch_working_directory} ]; then
    msg="ERROR -- cannot overwrite working directory ${batch_working_directory} " 
    batcherror_notify "${msg}"
  fi
  mkdir "${batch_working_directory}" >> ${batch_log} 2>&1
  error_code=$?
  cd "${batch_working_directory}" >> ${batch_log} 2>&1
  error_code=`expr ${error_code} + $?`
  if [ ${error_code} -ne 0 ]; then
    msg="ERROR -- cannot create working directory ${batch_working_directory} "
    batcherror_notify "${msg}"
  fi
else
  batch_working_directory=${BATCH_OUTPUT} 
  cd "${batch_working_directory}"
fi

#### ### ## # if [ "${APPEND_LOG_FILE:-X}" = "X" ];then
#### ### ## #   batch_start_flag=${BATCH_FLAGS}/`basename ${batch_log}`.${$}.START
#### ### ## #   if [ -a ${batch_start_flag} ]; then
#### ### ## #     logmsg="--ERROR  batch_start_flag ${batch_start_flag} already exists."
#### ### ## #     batcherror_notify "${logmsg}"
#### ### ## #   fi
#### ### ## #   touch ${batch_start_flag}
#### ### ## #   if [ -a ${batch_start_flag} ]; then
#### ### ## #     chmod 664 ${batch_start_flag}
#### ### ## #     if [ "${?}" != "0" ]; then
#### ### ## #       logmsg="--ERROR  cannot change permissions on batch_start_flag ${batch_start_flag} "
#### ### ## #       batcherror_notify "${logmsg}"
#### ### ## #     fi
#### ### ## #   else
#### ### ## #     logmsg="--ERROR  cannot change permissions on batch_start_flag ${batch_start_flag} ."
#### ### ## #     batcherror_notify "${logmsg}"
#### ### ## #   fi
#### ### ## # fi

sleep 2       # be sure that subsequent batch starts occur in a different second
 
}  ####  END FUNCTION batchstart

####----------------------------------------------------------------------------
####
####  The function set_startflag
####

set_startflag() {
if [ "${APPEND_LOG_FILE:-X}" = "X" ];then
  batch_start_flag=${BATCH_FLAGS}/`basename ${batch_log}`.${$}.START
  if [ -a ${batch_start_flag} ]; then
    logmsg="--ERROR  batch_start_flag ${batch_start_flag} already exists."
    batcherror_notify "${logmsg}"
  fi
  touch ${batch_start_flag}
  if [ -a ${batch_start_flag} ]; then
    chmod 664 ${batch_start_flag}
    if [ "${?}" != "0" ]; then
      logmsg="--ERROR  cannot change permissions on batch_start_flag ${batch_start_flag} "
      batcherror_notify "${logmsg}"
    fi
  else
    logmsg="--ERROR  cannot change permissions on batch_start_flag ${batch_start_flag} ."
    batcherror_notify "${logmsg}"
  fi
fi 

}  ####  END FUNCTION set_startflag


####----------------------------------------------------------------------------
####
####  The function set_flag
####
####  Creates a flagfile with the specified suffix.
####  NOTE:  Does not create flag if the job appends to a log file 
####  

set_flag() {
if [ "${1:-X}" = "X" ]; then
  :    #  Do not create flag if no suffix is passed to this function 
elif [ "${APPEND_LOG_FILE:-X}" = "X" ];then
  #  Create flag if this job writes a new log file for each run  
  batch_flag=${BATCH_FLAGS}/`basename ${batch_log}`.${$}.${1}
  if [ -a ${batch_flag} ]; then
    logmsg="--ERROR  batch_flag ${batch_flag} already exists."
    batcherror_notify "${logmsg}"
  fi
  echo "`date +'%Y%m%d%H%M%S'` ${1} ${batch_prg} ARGS ${batch_args} \n${batch_start_dtm} ${batch_log}\nTHREAD=${batchthread_start_dtm:-NA}" >> ${batch_flag}
  if [ -a ${batch_flag} ]; then
    chmod 664 ${batch_flag}
    if [ "${?}" != "0" ]; then
      logmsg="--ERROR  cannot change permissions on batch_flag ${batch_flag} "
      batcherror_notify "${logmsg}"
    fi
  else
    logmsg="--ERROR  cannot create batch_flag ${batch_flag} ."
    batcherror_notify "${logmsg}"
  fi
fi 

}  ####  END FUNCTION set_flag

####----------------------------------------------------------------------------
####
####  The function list_the_working_directory
####

list_the_working_directory() {

echo "-- LISTING THE CONTENTS OF THE WORKING DIRECTORY: ${batch_working_directory}" >> ${batch_log}
ls -lA ${batch_working_directory} >> ${batch_log}
echo "----------- LIST OF THE WORKING DIRECTORY CONTENTS SHOWN ABOVE: ${batch_working_directory}" >> ${batch_log}

}  ####  END FUNCTION list_the_working_directory


####----------------------------------------------------------------------------
####
####  The function cleanup_working_directory
####
####      This function accepts one parameter to indicate that the cleanup is 
####      for an ERROR, so the directory needs to be moved to 
####      ${BATCH_SYSTEM}/jobs/aborted 
####      
####      It checks to prevent looping if an error occurs within this function 
####      which would call batcherror_notify which would call this function etc.  
####  
####      As it stands right now, this function will NOT move the data to the 
####      "jobs/aborted/`basename $batch_working_directory` directory IF there 
####      are errors within this function.  if the *program* calls an error* 
####      function, then this working directory will be moved to the jobs/aborted 
####      area.

cleanup_working_directory() {

####  
####  do not loop on errors encountered in this function
####  
if [ "${started_cleanup_workdir:-X}" != "X" ]; then
  msg="Instructed to NOT cleanup the directory: ${batch_working_directory:-X} "
  messagelog_notify "${msg}"
  return 
fi
started_cleanup_workdir=1

####  
####  Check to see that this job is using batch_working_directory
####  
if [[ ( "${batch_working_directory:-X}" = "X" ) || ("${batch_working_directory:-X}" = "${BATCH_OUTPUT}" ) ]];then
  return
fi
if [ "${1:-NotDefined}" = "ERROR" ]; then
  destination_dir="${BATCH_SYSTEM}/jobs/aborted/`basename ${batch_working_directory}`"
  if [ -d ${destination_dir} ]; then
    err_msg="ERROR: cleanup_working_directory: directory already exists -- ${destination_dir} "
    batcherror_notify "${err_msg}"
  fi
  mkdir ${destination_dir} >> ${batch_log} 2>&1
  if [ ! -d ${destination_dir} ]; then
    err_msg="ERROR: cleanup_working_directory: cannot create ${destination_dir} "
    batcherror_notify "${err_msg}"
  fi
else 
  destination_dir=${BATCH_OUTPUT}
fi

if [ ! -d ${batch_working_directory} ]; then
  err_msg="ERROR: working directory ${batch_working_directory} does not exist, cannot cleanup. "
  batcherror_notify "${err_msg}"
fi
cd ${batch_working_directory} 2>> ${batch_log}
list_the_working_directory

max_loop_count=5
err_count=0
err_msg=""
for x in `ls -1A`
do
  loop_count=0
  max_loop_count=5
  still_waiting=0
  if [[ ( "${x}" = "." ) || ( "${x}" = ".." ) ]]; then
    max_loop_count=0
  fi
  while [ ${loop_count} -lt ${max_loop_count} ]
  do
    ####  JJJ  20030205 ####  if [ -a ${destination_dir}/${x} ]; then   # Check to avoid overwriting a file...
    if [ -a ${destination_dir}/${FPA_OUTPUTFILEPREFIX:-}${FPA_OUTPUTFILEPREFIX:+.}${x##*/} ]; then   # Check to avoid overwriting a file...
      loop_count=`expr ${loop_count} + 1`
      sleep 14  
    else
      loop_count=`expr ${max_loop_count} + ${max_loop_count}`
    fi
  done  # done with loop_count 
  if [ ${max_loop_count} -eq 0 ]; then
    :     # do nothing, just loop around again
  elif [ ${loop_count} -eq `expr ${max_loop_count} + ${max_loop_count}` ]; then
    ####  
    ####  COPY output into masterarchive with a unique ID, record in logfile. 
    ####  
    ### COMMENTED -- DONE IN FPA_commands.dat my_id=`get_run_seq OUTPUT_ID.SEQ`
    ### COMMENTED -- DONE IN FPA_commands.dat archive_filename="${BATCH_ARCHIVE}/${x##*/}.ID${my_id}"
    ### COMMENTED -- DONE IN FPA_commands.dat msg="archiving ${x} to ${archive_filename} with tracking id ${my_id}"
    ### COMMENTED -- DONE IN FPA_commands.dat messagelog "${msg}"
    ### COMMENTED -- DONE IN FPA_commands.dat cp ${x} ${archive_filename}
    ### COMMENTED -- DONE IN FPA_commands.dat cmd_status=$?
    ### COMMENTED -- DONE IN FPA_commands.dat if [ ${cmd_status} -ne 0 ]; then
      ### COMMENTED -- DONE IN FPA_commands.dat err_count=`expr ${err_count} + 1`
      ### COMMENTED -- DONE IN FPA_commands.dat err_msg="${err_msg}ERROR -- FAILED, STATUS ${cmd_status}: to cp output file ${x} to ${archive_filename} | "
    ### COMMENTED -- DONE IN FPA_commands.dat elif [ ! -a ${archive_filename} ]; then
      ### COMMENTED -- DONE IN FPA_commands.dat err_count=`expr ${err_count} + 1`
      ### COMMENTED -- DONE IN FPA_commands.dat err_msg="${err_msg}ERROR -- FAILED to cp output file ${x} to ${archive_filename} | "
    ### COMMENTED -- DONE IN FPA_commands.dat fi

    ####  
    ####  MOVE output into destination_dir
    ####  
    ####  JJJ  20030205 ####  mv ${x} ${destination_dir} >> ${batch_log} 2>&1
    # echo "mv ${x} ${destination_dir}/${FPA_OUTPUTFILEPREFIX:-}${FPA_OUTPUTFILEPREFIX:+.}${x##*/}" >> ${batch_log} 2>&1
    mv ${x} ${destination_dir}/${FPA_OUTPUTFILEPREFIX:-}${FPA_OUTPUTFILEPREFIX:+.}${x##*/} >> ${batch_log} 2>&1 
    cmd_status=$?
    if [ ${cmd_status} -ne 0 ]; then
      err_count=`expr ${err_count} + 1`
      err_msg="${err_msg}ERROR -- FAILED, STATUS ${cmd_status}: to mv output file ${x} to ${destination_dir} | "
    elif [ ! -a ${destination_dir}/${FPA_OUTPUTFILEPREFIX:-}${FPA_OUTPUTFILEPREFIX:+.}${x##*/} ]; then
      err_count=`expr ${err_count} + 1`
      err_msg="${err_msg}ERROR -- FAILED to mv output file ${x} to ${destination_dir} | "
    fi
  else
    err_count=`expr ${err_count} + 1`
    err_msg="${err_msg}ERROR -- FAILED NO OVERWRITE: to mv output file ${x} to ${destination_dir} with prefix ${FPA_OUTPUTFILEPREFIX:-no_prefix_added} | "
  fi
done
if [ "${err_msg:-""}" != "" ]; then
  batcherror_notify "${err_msg}"     # this will exit 
fi

####  
####  Make sure that the working directory is now empty
####  
x=`ls -1A | wc -l`    #  should be 0 
if [ ${x} -ne 0 ]; then
  list_the_working_directory
  msg="ERROR -- working directory ${batch_working_directory} is not empty: ${x}"
  batcherror_notify "${msg}"
fi

####  
####  Remove the working directory 
####  
cd ..
rmdir  ${batch_working_directory}
cmd_status=$?
if [ ${cmd_status} -ne 0 ]; then
  err_msg="ERROR ${cmd_status}: CANNOT REMOVE directory ${batch_working_directory} "
  batcherror_notify "${err_msg}"
elif [ -d ${batch_working_directory} ]; then
  err_msg="ERROR: DID NOT REMOVE directory ${batch_working_directory} "
  batcherror_notify "${err_msg}"
fi

}  ####  END FUNCTION cleanup_working_directory


####----------------------------------------------------------------------------
####
####  The function batcherror_notify
####

batcherror_notify() {

currdtm
logmsg="--ERROR_NOTIFY ${batch_prg} | ON ${batch_sys} | AT ${currdtm_dt} ${currdtm_tm} | USER=${LOGNAME} | PID=$$ | MSG=${1} | "
writelog "${logmsg}"
echo "${logmsg}" >> ${BATCH_LOGS}/batch_summary.`date +'%Y%m%d'`
batch_notify "${logmsg}"
if [ "${batchsync_filename:-X}" != "X" ];then
  if [ "${batchsync_clear_sync_on_error:-X}" != "FALSE" ];then
    remove_sync
  fi
fi
if [ "${batchuniquefilename:-X}" != "X" ]; then
  mv ${batchuniquefilename} ${BATCH_TMP}/`basename ${batchuniquefilename}`.`get_run_seq misc.seq`
  rc=$?
  if [${rc} -eq 0 -o -a  ${batchuniquefilename} ]; then
    messagelog "WARNING: Unable to move batchstartunique file `basename  ${batchuniquefilename}`. "
  fi
fi
cleanup_working_directory ERROR
set_flag ERROR
exit 2
 
}  ####  END FUNCTION batcherror_notify

####----------------------------------------------------------------------------
####
####  The function batcherror
####

batcherror() {

currdtm
logmsg="--ERROR ${batch_prg} | ON ${batch_sys} | AT ${currdtm_dt} ${currdtm_tm} | USER=${LOGNAME} | PID=$$ | MSG=${1} | "
echo "${logmsg}" >> ${BATCH_LOGS}/batch_summary.`date +'%Y%m%d'`
writelog "${logmsg}"
if [ "${batchsync_filename:-X}" != "X" ];then
  if [ "${batchsync_clear_sync_on_error:-X}" != "FALSE" ];then
    remove_sync
  fi
fi
if [ "${batchuniquefilename:-X}" != "X" ]; then
  mv ${batchuniquefilename} ${BATCH_TMP}/`basename ${batchuniquefilename}`.`get_run_seq misc.seq`
  rc=$?
  if [${rc} -eq 0 -o -a  ${batchuniquefilename} ]; then
    messagelog "WARNING: Unable to move batchstartunique file `basename  ${batchuniquefilename}`. "
  fi
fi
cleanup_working_directory ERROR
set_flag ERROR
exit 1
 
}  ####  END FUNCTION batcherror

####----------------------------------------------------------------------------
####
####  The function batchend
####

batchend() {

currdtm
logmsg="--END ${batch_prg} | ON ${batch_sys} | AT ${currdtm_dt} ${currdtm_tm} | USER=${LOGNAME} | PID=$$ | MSG=Completed Successfully | "
if [ "${NO_SUMMARY_MSGS:-X}" != "TRUE" ];then
  echo "${logmsg}" >> ${BATCH_LOGS}/batch_summary.`date +'%Y%m%d'`
fi
writelog "${logmsg}"
if [ "${batchsync_filename:-X}" != "X" ];then
  remove_sync
fi
if [ "${batchuniquefilename:-X}" != "X" ]; then
  mv ${batchuniquefilename} ${BATCH_TMP}/`basename ${batchuniquefilename}`.`get_run_seq misc.seq`
  rc=$?
  if [ ${rc} -ne 0 -o -a ${batchuniquefilename} ]; then
    messagelog "WARNING: Unable to move batchstartunique file `basename  ${batchuniquefilename}` "
  fi
fi
cleanup_working_directory
set_flag SUCCESS
exit 0
 
}  ####  END FUNCTION batchend

####----------------------------------------------------------------------------
####
####  The function setlog
####

setlog() {

batch_log="${BATCH_LOGS}/${1}"
 
}  ####  END FUNCTION setlog

####----------------------------------------------------------------------------
####
####  The function messagelog_notify
####

messagelog_notify() {

logmsg="--PID=$$ | MSG=${1} | "
writelog "${logmsg}"
batch_notify "${logmsg}"
 
}  ####  END FUNCTION messagelog_notify

####----------------------------------------------------------------------------
####
####  The function messagelog_summary places a message in the log file 
####  AND ALSO places the message in the daily summary log file. 
####

messagelog_summary() {

logmsg="--PID=$$ | MSG=${1:-Undefined_Message} | "
writelog "${logmsg}"
echo "----MSG from ${$}: ${1:-Undefined_Message}" >> ${BATCH_LOGS}/batch_summary.`date +'%Y%m%d'`
 
}  ####  END FUNCTION messagelog_summary

####----------------------------------------------------------------------------
####
####  The function messagelog
####

messagelog() {
logmsg="--PID=$$ | MSG=${1} | "
writelog "${logmsg}"
}  ####  END FUNCTION messagelog

####----------------------------------------------------------------------------
####
####  The function batch_notify
####

batch_notify() {

####
####  Send e-mail to the notify-distribution list -- can send e-mail to pagers with error message
####
mailtousers=`cat ${BATCH_ETC}/dl.FPAnotifyusers | tr '\012' ' '`
mailx -s "d950 job: ${batch_prg}" ${mailtousers} << EOT
"${1}"
~.
EOT
return_status=$?
:

####
####  confirm that the e-mail was sent (only confirms from the Unix send, NOT routing or delivery)
####  store this information in a tmp file during initial rollout.
####  THIS NOTIFICATION PROCESS NEEDS TO BE DEFINED 
####
date  >> ${BATCH_LOGS}/batchlog-batch_notify.`date +'%Y%m%d'`
echo "Status is ${return_status} from the batch_notify" >> ${BATCH_LOGS}/batchlog-batch_notify.`date +'%Y%m%d'`

date >> ${BATCH_LOGS}/batchlog-batch_notify.`date +'%Y%m%d'`
echo "${1}\n\n" >> ${BATCH_LOGS}/batchlog-batch_notify.`date +'%Y%m%d'`
currdtm
if [ return_status -ne 0 ]; then
  logmsg="--NOTIFICATION FAILURE ${batch_prg} | ON ${batch_sys} | AT ${currdtm_dt} ${currdtm_tm} | USER=${LOGNAME} | PID=${$} | MSG=FAILED to complete nofication process | "
  echo "${logmsg}" >> ${BATCH_LOGS}/batch_summary.`date +'%Y%m%d'`
else
  logmsg="--NOTIFICATION COMPLETED ${batch_prg} | ON ${batch_sys} | AT ${currdtm_dt} ${currdtm_tm} | USER=${LOGNAME} | PID=$$ | MSG=Notification sent properly. | "
fi
writelog "${logmsg}"
 
}  ####  END FUNCTION batch_notify


##########################################################################
#   main script                                                          #
##########################################################################

. ksh_functions.ksh               #  READS THE DATE AND RUN_SEQUENCE FUNCTIONS
batch_start_dtm=`date +'%Y%m%d%H%M%S'`
batch_start_sec=`date +'%s'`     # JPT 20050407 for elapsed time calc, requires GNU date function
batch_run_dhm=`echo ${batch_start_dtm} |cut -c7-12`
batch_prg=`basename $0`
if [ "${#*}" = "0" ]; then
  batch_args='N/A'
else
  batch_args=${*}
fi
setlog "${batch_prg}.${batch_start_dtm}.log"
batch_sys=`uname -n`

