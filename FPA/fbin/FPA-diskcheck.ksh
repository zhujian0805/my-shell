#!/bin/ksh
#IDENT "SCCS_ID:  %Z% PSCFPA %M% %I% %H%"
#IDENT "DELTA_ID: %Z% PSCFPA Last Modified %G% %U%"
#--------------------------- COPYRIGHT NOTICE ----------------------------------
#*******************************************************************************
#
# Copyright (c) 2000 Perot Systems Corporation 
# All Rights Reserved
# Copyright Notice Does Not Imply Publication
#
#*******************************************************************************
#
#  NAME:               FPA.ksh  
#                      The name is FPA.ksh the name of the FPA AUTOMATION 
#                      environment must be passed as the first parameter so 
#                      prevent multiple versions from running in the same 
#                      environment concurrently.  
#
#  DESCRIPTION:        Script to automate the processing of files.  This script
#                      is designed to be run periodically from a scheduler such
#                      as cron.  NOTE that the full path must be specified in the 
#                      scheduler and the parameter must also be specified. 
#
#                      The acronym FPA stands for File Processing Application.
#                      FPA.ksh searches certain directories specified by the
#                      environment variable FPA_SEARCH_PATH for all files of 
#                      type regular file.  For each regular file it finds in 
#                      any of the directories included in FPA_SEARCH_PATH, the 
#                      script attempts to match the filename against a set of 
#                      filename templates included in a file specified by the 
#                      environment variable FPA_FILE_TEMPLATES located in the
#                      directory specified by the environment variable
#                      BATCH_ETC.  An index number is retrieved from the 
#                      FPA_FILE_TEMPLATES file from the record for the first 
#                      filename template which matches the filename.  The
#                      script then uses the index to search a file of commands 
#                      to be executed.  The commands file is specified by
#                      the environment variable FPA_COMMANDS located in the
#                      directory specified by the environment variable BATCH_ETC.
#                      FPA.ksh then executes the commands associated with
#                      the index number.  The commands are executed 
#                      sequentially, and the success or failure of the commands
#                      are logged in the batch log for FPA.ksh.
#
#                      In the event that a file name matches multiple entries
#                      templates in FPA_FILE_TEMPLATES, only the commands for
#                      the first match will be executed.  
#
#                      Any regular files found in the FPA_SEARCH_PATH whose 
#                      names do not match any of the filename templates in
#                      FPA_FILE_TEMPLATES are moved to a directory specified
#                      by the environment variable FPA_UNIDENTIFIED.
#
#  EXT DATA FILES:     BATCH_ETC/FPA_FILE_TEMPLATES - path/file containing 
#                          filename templates
#                      BATCH_ETC/FPA_COMMANDS - path/file containing commands
#                          to be processed for each file template 
#                      BATCH_LOGS/FPA.ksh.log - batch log
#                      ~/.FPAprofile - the profile that FPA uses. Prevents the
#                          terminal commands in an interactive profile from 
#                          creating error messages in the cron logs.
#                      BATCH_LOGS/.FPAvaprod.cron.log - the cron log file 
#
#  ENV VARIABLES:      FPA_MAX_CYCLES - threshold for determining how long to 
#                          wait (number of consecutive unsuccessful attempts to 
#                          run FPA.ksh) before initiating notification. 
#                      BATCH_ETC - the directory containing the FPA_FILE_TEMPLATES
#                          file and the FPA_COMMANDS file.
#                      FPA_CHECK_ENV - the file containing the list of scripts 
#                          that must successfully complete before continuing 
#                          FPA processing.  If one of these checks fails, 
#                          FPA will issue a warning and exit without processing 
#                          files or jobs.  This file must live in the 
#                          BATCH_ETC directory. 
#                      FPA_BACKGROUND_JOBS - the file containing the list 
#                          of scripts/commands to be executed in the 
#                          background every time that the FPA runs.  The 
#                          FPA will continue processing regardless of 
#                          whether or not any of these processes fail.  
#                          Each process listed in the file will issue all 
#                          necessary warnings and messages.  This file must 
#                          live in the BATCH_ETC directory. 
#                      FPA_FILE_TEMPLATES - the file containing the filename
#                          templates against which the script tries to match
#                          the filenames of regular files found in the 
#                          directories contained in the environment variable
#                          FPA_SEARCH_PATH.
#                      FPA_SEARCH_PATH - a colon-delimited list of directory
#                          names which this script will search for regular
#                          files to process by running the commmands in the
#                          file FPA_COMMANDS.
#                      BATCH_TMP - a directory the script uses to store a 
#                          lists of the regular files found in the directories
#                          of the FPA_SEARCH_PATH.
#                      FPA_SLEEP_TIME - time in seconds between the creation
#                          of the fpa_file_list.before file and the creation 
#                          of the fpa_file_list.after file.  These files are
#                          long listings of the regular files in the 
#                          FPA_SEARCH_PATH.
#                      FPA_UNIDENTIFIED - a directory to which files are moved
#                          if their filenames do not match any of the templates
#                          in FPA_FILE_TEMPLATES.
#                      BATCH_LOGS - a directory containing the log files for 
#                          production processes.  
#                      
#  INPUT:              FPA.ksh requires one command line argument indicating 
#                          name of the UNIX automation environment where it 
#                          is running.
#
#  OUTPUT:             FPA.ksh logs it's activity to the file FPA.ksh.log
#                      in the directory specified by the environment variable
#                      BATCH_LOGS.
#
#  TEMPORARY FILES:    fpa_file_list.before - this file is created by FPA.ksh and
#                          contains a long listing including the full path of 
#                          each regular file located in any of the directories
#                          of FPA_SEARCH_PATH.  This file is created for the 
#                          purpose of obtaining a "snapshot" of the state of 
#                          all of the regular files contained in the 
#                          FPA_SEARCH_PATH directories.  fpa_file_list.before
#                          is compared with fpa_file_list.after to ensure that 
#                          only static (i.e. non-growing) files are processed.  
#                          This file is located in the directory identified by 
#                          the environment variable BATCH_TMP.
#                      fpa_file_list.after - this file is a second "snapshot" 
#                          of the files in the FPA_SEARCH_PATH directories.
#                          fpa_file_list.after is a long listing of the files
#                          created a specified period after fpa_file_list.before
#                          and is used to ensure that only static files are 
#                          processed. 
#	               fpa_runs_since_successful.txt - this file contains a 
#                          counter of the number of times FPA.ksh has been
#                          started since the last successful completion of
#                          FPA.ksh along with each time that the FPA tried to 
#                          start and the PID.  This information is used to 
#                          send notification that FPA.ksh is hung after 
#                          a specified period.
#
#  EXT FUNC CALLS:     Standard batch messaging functions in batchlog.ksh
#
#  EXT MOD CALLS:      batchlog.ksh
#
#*******************************************************************************
# Date         Programmmer      Description
# ----------   --------------   ------------------------------------------
# 12/12/2001   J Thiessen       Grandfathered from prior FPA versions.
# 03/11/2003   J Thiessen       Removed the restrictions of being run only by
#                               specific users.
# 02/12/2004   J. Thiessen      Removed If_Currently_Running - moved to ksh_functions.ksh
# 04/01/2004   J Thiessen       Fix. pass a parameter to If_Currently_Running 
# 07/22/2004   J Thiessen       Added logic to initiate environemnt checks 
#                               and background jobs, added FPA_CHECK_ENV and 
#                               FPA_BACKGROUND_JOBS
# 02/15/2005   J Thiessen       Now creates batch_summary log file one day 
#                               before it is used to be sure that the menu 
#                               users never need to create it. SR# 3250257
#
#*******************************************************************************

####----------------------------------------------------------------------------
####
####  The function Process_File recieves as an argument a filename of  
####  a file found in the FPA_SEARCH_PATH.  This function looks up the
####  filename in the FPA_FILE_TEMPLATES file and executes related
####  commands in the FPA_COMMANDS file.
####

Process_File()
{

####
####  Define FPA_timestamp for use by commands in the FPA_COMMANDS file.
####
FPA_datetimestamp=`date +\%Y\%m\%d\%H\%M\%S`

num_instances=`wc -l ${BATCH_ETC}/${FPA_FILE_TEMPLATES} | awk '{print $1}'` 
count=0
while [ ${count} -lt ${num_instances} ]
do
  count=`expr ${count} + 1`

####
####  Evaluate this template from the FPA_FILE_TEMPLATES file to prepare 
####  for matching comparison with the current filename.
####
  file_template_line=`sed -n ${count}p ${BATCH_ETC}/${FPA_FILE_TEMPLATES}`
  file_template=`echo "${file_template_line}" | \
      awk 'BEGIN {FS ="<##>"}{print $2}'`
####        /usr/xpg4/bin/awk 'BEGIN {FS ="<##>"}{print $2}'`
  file_template=`eval echo "${file_template}"`

####
####  If the filename is included in the list of files that match this template 
####  from the FPA_FILE_TEMPLATES file, then determine which commands to run 
####  from the FPA_COMMANDS file.
####

  echo "#${file_template}#" | sed 's/ /#/g' | grep "#${1}#" > /dev/null 2>&1
  ret_val3=$?
  if [ ${ret_val3} -eq 0 ]; then
    index=`echo "${file_template_line}" | \
            awk 'BEGIN {FS="<##>"}{print $3}'`
####            /usr/xpg4/bin/awk 'BEGIN {FS="<##>"}{print $3}'`
    search_string="<##>${index}<##>"

####
####  Determine how many commands need to be processed for the file.
####
    num_cmds=`grep "${search_string}" ${BATCH_ETC}/${FPA_COMMANDS} | wc -l`
    counter2=0
    while [ ${num_cmds} -gt ${counter2} ]
    do
      counter2=`expr ${counter2} + 1`
      cmd_search_string="${search_string}${counter2}<##>"
####
####  Parse out the actual command to run from the FPA_COMMANDS file.
####
      cmd_line=`grep "${cmd_search_string}" ${BATCH_ETC}/${FPA_COMMANDS}`
      cmd=`echo "${cmd_line}" | \
          awk 'BEGIN {FS="<##>"}{print $4}'`
####                /usr/xpg4/bin/awk 'BEGIN {FS="<##>"}{print $4}'`
####
####  Run the command.
####
            eval ${cmd}
	    cmd_return=$?
####
####  Log whether the command was successful or not.  (Note for nohup commands
####  that are initiated in the background, successful indicates that the
####  sub-shell was successfully created.  It does not indicate that the
####  nohup was successful in executing its command.
####
            if [ ${cmd_return} -eq 0 ]; then
	        messagelog "SUCCESS - Index ${index} command ${counter2}, \"${cmd}\", in file ${FPA_COMMANDS} running for file ${1} executed successfully."
            else
                messagelog_notify "FAILURE - Index ${index} command ${counter2}, \"${cmd}\", in file ${FPA_COMMANDS} running for file ${1} did not execute successfully. Exit code was ${cmd_return}."
	        break
            fi
        done	

####
####  If a match was found in FPA_FILE_TEMPLATES for the filename, exit
####  the Process_File function and continue processing for the next
####  filename in the list.
####

    return 
    fi

done

####
####  If the end of the FPA_FILE_TEMPLATES file was reached and no template
####  was found to match the filename, the file is considered "unidentified"
####  and should be moved to the FPA_UNIDENTIFIED directory.
####

if [ ${count} -eq ${num_instances} ]; then
    mv ${1} ${FPA_UNIDENTIFIED}/`basename ${1}`.${FPA_datetimestamp}
    messagelog_notify "File ${1} could not be identified and was not processed.  This file was moved to the ${FPA_UNIDENTIFIED} directory."
fi

}  ####  END FUNCTION Process_File

#-------------------------------------------------------------------------------
####
####  The function subst_date recieves as an argument a filename containing
####  the string CCYYMMDDHHMNSS or a subset of the fields CCYY, YY, MM, DD,
####  HH, MN, and SS.
####  This function will normally be called by a command in the FPA_COMMANDS
####  file.  The function substitutes the current date for the date format
####  string, and sets a variable, destfile, to the filename containing the
####  current date.  The variable destfile can then be used to rename 
####  output files with a current date stamp.
####

Subst_Date() 
{
    CCYY=`date +"%Y"`
    YY=`date +"%y"`
    MM=`date +"%m"`
    DD=`date +"%d"`
    HH=`date +"%H"`
    MN=`date +"%M"`
    SS=`date +"%S"`

    destfile=`echo ${1} | sed -e "s/CCYY/${CCYY}/g" -e "s/YY/${YY}/g" \
                              -e "s/MM/${MM}/g"     -e "s/DD/${DD}/g" \
			      -e "s/HH/${HH}/g"     -e "s/MN/${MN}/g" \
                              -e "s/SS/${SS}/g"`

}  ####  END FUNCTION Subst_Date

##########################################################################
#   main script                                                          #
##########################################################################

. ~/.FPAprofile     
. batchlog.ksh
. ksh_functions.ksh               #  READS THE DATE AND RUN_SEQUENCE FUNCTIONS
NO_OUTPUT="TRUE"        ## only for FPA itself, do not create a working directory
NO_SUMMARY_MSGS=TRUE    ## set this variable only for the FPA itself
APPEND_LOG_FILE=TRUE    ## set this variable only for the FPA itself
setlog ${batch_prg}.`date +'%Y%m%d'`
if [ ! -a ${batch_log} ];then
  first_run_of_day=TRUE
fi
batchstart

####
####  Check for the required parameter.  NOTE that the If_Currently_Running 
####  procedure will search for the string "$$ ${1}" in the output of 
####  'ps -ef' -- keep these names short to prevent truncation. HPUX 11 
####  displays only 60 characters for the full path filename and parameters.
####  And don't forget that starting it in cron prefixes the whole thing with 
####  '/bin/ksh '!!
####
if [ $# -ne 1 ]; then
  msg="Usage:  'FPA.ksh environment_name' where environment_name is the system-unique, one-word name of the UNIX Automation environment" 
  batcherror "${msg} "
fi
ThisUser="${1}"

####
####  Ensure that this script is only running once.  
####
cycle_counter=0
If_Currently_Running "${ThisUser}"
ReturnCode=$?
if [ "${ReturnCode}" = "0" ]; then
    cycle_counter=`tail -1 ${BATCH_TMP}/fpa_runs_since_successful.txt |cut  -d" " -f1`
    cycle_counter=`expr ${cycle_counter} + 1`

    if [ ${cycle_counter} -lt ${FPA_MAX_CYCLES} ]; then
	messagelog "${batch_prg} is currently running.  This attempt to run ${batch_prg} is attempt number ${cycle_counter} since the last successful completion."
    else
	messagelog_notify "WARNING:  ${batch_prg} is running longer than usual. It has tried to start ${cycle_counter} times while a previous run continues. This may indicate that there are many tasks for ${batch_prg} to perform or there may be a problem with ${batch_prg} or system performance. "
      #### Update this message to include the time of the START for the job that is still running. 
    fi
    echo "${cycle_counter} ${batch_start_dtm} PID=${$}" >> ${BATCH_TMP}/fpa_runs_since_successful.txt   # Append to the counter file...
    batchend
fi             

####
####  Check disk space before starting. Default value is 95% if $FPA_DISABLE_DISKFULL is not defined. 
####
my_disk_used=`get_disk_used`    # add to ksh_functions.ksh   # JPT 20050706 
if [ ${my_disk_used:-100} -gt ${FPA_DISABLE_DISKFULL:-98} -gt 0 ]; then
  if [ -r HERE HERE HERE HERE 

fi

####
####  If there are defined environment checks, check them before starting to run the FPA 
####
if [ ${#FPA_CHECK_ENV} -gt 0 ]; then
  if [ ! -r ${BATCH_ETC}/${FPA_CHECK_ENV} ]; then
    msg="ERROR -- Cannot read ${FAP_CHECK_ENV} to check this FPA environment"
    batcherror_notify "${msg}"   # EXIT WITH ERROR
  fi
  cat ${BATCH_ETC}/${FPA_CHECK_ENV} |grep -v "^#" |
  while read job
  do
    messagelog "about to start the environment check job --->${job-UNKNOWN}<--- "
    ${job}
    ret_stat=$?
    if [ ${ret_stat} -eq 0 ]; then
      messagelog "Successfully executed environment check job: ${job}"
    else
      batcherror_notify "ERROR -- FAILED TO EXECUTE environment check job: ${job}"   # EXIT WITH ERROR
    fi
  done
fi

####
####  If there are defined background jobs, initiate them now. 
####
if [ ${#FPA_BACKGROUND_JOBS} -gt 0 ]; then
  if [ ! -r ${BATCH_ETC}/${FPA_BACKGROUND_JOBS} ]; then
    msg="ERROR -- Cannot read ${FPA_BACKGROUND_JOBS} to check this FPA environment"
    messagelog "${msg}"   # log the error
  fi
  cat ${BATCH_ETC}/${FPA_BACKGROUND_JOBS} |grep -v "^#" |
  while read job
  do
    FPA_nohup.ksh ${job}
    if [ $? -eq 0 ]; then
      messagelog "Successfully nohup'd background job: ${job}"
    else
      messagelog "ERROR -- Failed to nohup background job: ${job}"
    fi
  done
fi

####  
####  Create a list of files currently in the directories
####  of the FPA search path.
####
export search_path=`echo ${FPA_SEARCH_PATH} | sed 's/:/ /g'`
for x in ${search_path}
do
    find $x \( -type d ! -name ${x##*/} -prune \) -o \( -type f -print \) | grep -v "^d" | grep -v "^total "
done > ${BATCH_TMP}/fpa_file_list.tmp

num_lines=`wc -l ${BATCH_TMP}/fpa_file_list.tmp | awk -F" " '{ print $1 }'`

if [ ${num_lines} -gt 0 ];then
    ls -ltr `cat ${BATCH_TMP}/fpa_file_list.tmp` | \
    grep -v "^d" | grep -v "^total " | \
    sed "s/  */ /g" > ${BATCH_TMP}/fpa_file_list.before
else
    echo " " > ${BATCH_TMP}/fpa_file_list.before
fi

####  
####  look for and process all scheduled jobs.
####  
ksh FPA_processjobcards.ksh
if [ $? -ne 0 ]; then
  msg="WARNING -- PROBLEM executing FPA_processjobcards.ksh"
  messagelog_notify "${msg}"
fi

####  
####  if first_run_of_day then compress files in FPA_ZIP_DIRS. 
####  
if [ "${first_run_of_day:-X}" = "TRUE" ];then
  messagelog "FIRST RUN OF THE DAY"
  touch ${BATCH_LOGS}/batch_summary.`Tomorrow_Date`  # Be sure that the menu users never try to create the batch_summary file
  if [ "${FPA_ZIP_DIRS:-X}" != "X" ];then
    export zip_dirs=`echo ${FPA_ZIP_DIRS} | sed 's/:/ /g'`
    FPA_nohup.ksh FPA_zipdir.ksh ${zip_dirs}
    if [ $? -ne 0 ]; then
      msg="WARNING -- PROBLEM executing FPA_zipdir.ksh"
      messagelog_notify "${msg}"
    fi
  fi
fi

####  
####  Monitor PENDING ftp q cards   (do this as part of the delay between file listings) 
####  
sleep ${FPA_SLEEP_TIME}

####  
####  Create a second list of files in the directories
####  of the FPA search path for the purpose of determining
####  whether any of the files in the first list are 
####  changing.  (Should not process files which are not
####  static.)
####

for x in ${search_path}
do
    find $x \( -type d ! -name ${x##*/} -prune \) -o \( -type f -print \) | \
    grep -v "^d" | grep -v "^total " 
done > ${BATCH_TMP}/fpa_file_list2.tmp

num_lines2=`wc -l ${BATCH_TMP}/fpa_file_list2.tmp | awk -F" " '{ print $1 }'`

if [ ${num_lines2} -gt 0 ];then
    ls -ltr `cat ${BATCH_TMP}/fpa_file_list2.tmp` | \
    grep -v "^d" | grep -v "^total " | \
    sed "s/  */ /g" > ${BATCH_TMP}/fpa_file_list.after
else
    echo " " > ${BATCH_TMP}/fpa_file_list.after
fi

counter1=0
while [ ${counter1} -lt ${num_lines} ]
do          
    counter1=`expr ${counter1} + 1`
    inlineraw=`sed -n ${counter1}p ${BATCH_TMP}/fpa_file_list.before`
    inline=`sed -n ${counter1}p ${BATCH_TMP}/fpa_file_list.before |sed 's/\-\-\-/\.\*/g'`

####  
####  Only process those files which are the same when the 
####  fpa_file_list.before file was created as when the 
####  fpa_file_list.after file was created.  (I.e. only
####  process static files.)
####

    grep -- "${inline}" ${BATCH_TMP}/fpa_file_list.after > /dev/null 2>&1 
    Return_Status=$?
    if [ ${Return_Status} -eq 0 ]; then
        filename=`echo "${inlineraw}" | cut -d" " -f9`    #### JPT 20040813  do not use the asterisks in Process_File...
        if [ ${#filename} -lt 3 ]; then    
          echo "FPA.ksh ERROR at ${batch_start_dtm} NULL INPUT FILE counter1-->${counter1}<--  filename-->${filename}<--" >> ${BATCH_ROOT}/local/debug/FPA.ksh.debug.${batch_start_dtm}
          echo "FPA.ksh ERROR at ${batch_start_dtm} NULL INPUT FILE inline-->${inline}<-- " >> ${BATCH_ROOT}/local/debug/FPA.ksh.debug.${batch_start_dtm}
          echo "FPA.ksh ERROR at ${batch_start_dtm} NULL INPUT FILE inlineraw-->${inlineraw}<-- " >> ${BATCH_ROOT}/local/debug/FPA.ksh.debug.${batch_start_dtm}
          cp ${BATCH_TMP}/fpa_file_list.before ${BATCH_ROOT}/local/debug/fpa_file_list.before.${batch_start_dtm}
        else       
          ####
          ####  Call Process_File if there is a file to process...
          ####
          Process_File ${filename}
          Return_Status=$?
          if [  ${Return_Status} -ne 0 ]; then
            msg="ERROR ${Return_Status} in function Process_File for file ${filename} "
            messagelog_notify "${msg}"
          fi
        fi
        sleep 3             ##  sleep to be sure that subsequent processes are started in different seconds.
    fi
done

####  
####  Sleep to be sure that all FTP q cards that are being created have time to be 
####  written to disk and can be processed in this run.  
####  
sleep 10

####  
####  Build list of FTP destinations with files waiting to be sent
####  
tmp_list=""
######  JPT 20050131 CHanged def of BATCH_FTP_QUEUE ######  for x in `find ${BATCH_FTP_QUEUE} \( -type d ! -name ${BATCH_FTP_QUEUE##*/} -prune \) -o \( -type f -print \)`
for x in `find ${BATCH_FTP_QUEUE}/ready -type f -print `
do
  tmp1=`basename ${x} | awk -F\. '{ print $1 }'`
  tmp2=`echo ${tmp_list} | grep "${tmp1} #"`
  if [ ${#tmp2} -lt 2 ]; then
    tmp_list="${tmp_list}${tmp1} # "  ##  Add to list of waiting destinations if not already in list.
  fi
done
set -A dest_list `echo ${tmp_list} |sed 's/ #//g'`

####  
####  Start ftp_deliver for each listed destination 
####  
for x in ${dest_list[*]:-}
do
  FPA_nohup.ksh ftp_deliver.ksh ${x}
  if [ $? -ne 0 ]; then
    msg="WARNING -- PROBLEM executing FPA_nohup.ksh ftp_deliver.ksh ${x} "
    messagelog_notify "${msg}"
  fi
  sleep 10   ## stagger starting FTP processes, this does not cause any other delay since it is at the end of this program. 
done

echo "0 ${batch_start_dtm} PID=${$}" > ${BATCH_TMP}/fpa_runs_since_successful.txt   ## overwrite the counter file
batchend

