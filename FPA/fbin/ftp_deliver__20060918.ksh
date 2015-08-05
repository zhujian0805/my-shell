#!/bin/ksh
#--------------------------- COPYRIGHT NOTICE ----------------------------------
#*******************************************************************************
#
# Copyright (c) 2004 Perot Systems Corporation 
# All Rights Reserved
# Copyright Notice Does Not Imply Publication
#
#*******************************************************************************
#
#  NAME:               ftp_deliver.ksh  
#                      The name of the FTP DESTINATION  
#                      must be passed as the first parameter to 
#                      prevent multiple versions from running in the same 
#                      environment concurrently.  
#
#  DESCRIPTION:        This program requires the destination name as a 
#                      parameter.  If this job is already running for the 
#    TO BE ADDED       specified destination, it performs a simple analysis 
#    TO BE ADDED       to see whether or not the previous job is progressing 
#    TO BE ADDED       properly, issuing alerts if problems are detected, 
#                      and exiting without initiating FTP.  This logic can be
#                      significantly improved if necessary, now it is just a 
#                      counter of consecutive times that it tried to start 
#                      while a previous job was still running.
#                       
#                      The specified destination is validated by comparing to 
#                      a list of allowed databases which is located in the 
#                      FPA's etc directory. 
#                       
#                      FTP queue cards are moved into the active FTP queue by 
#                      the FPA or manually.  This program only processes the
#                      files that are ready to be sent at runtime. 
#                       
#                      For each queue card ready to process, the appropriate 
#                      commands are appended to a command file specific to 
#                      this run.  A start-time suffix is appended to the name 
#                      of each queue card when its commands are written in the 
#                      command file and the queue card is moved into the 
#                      subdirectory named 'sending'.
#                       
#                      After all of the queue cards are processed, if the 
#                      command file contains instructions, the file is 
#                      closed with the disconnection commands 
#                      for this destination, making the command file 
#                      executable.  This command file is then executed 
#                      and both the return code and the detailed command 
#                      log are analyzed.  For each file that was successfully 
#                      delivered to its destination, a success flag is 
#                      created in $BATCH_FLAGS and a 'done' suffix is appended to the 
#                      corresponding queue card as it is moved to the 
#                      archive subdirectory.  Likewise, a failure 
#                      flag is created for each file that was not delivered 
#                      successfully and a failure end time suffix is appended 
#                      to the corresponding queue card as it is moved to the 
#                      errors subdirectory.
#                       
#                      The completed, successful queue cards are 
#                      then archived along with the command file, and the 
#                      FPA handles error notification if necessary.  
#
#  EXT DATA FILES:     BATCH_ETC/fpt.<destination>.dat - the file containing 
#                      the connection, login, validation, parameters, and 
#                      disconnection information for the specified destination.  
#                      This file must be manually created for each destination
#                      and must be a korn shell executable.
#                       
#                      BATCH_ETC/dl.ftp_hung - the distribution list for 
#                      notification if this FTP session gets stuck and neither 
#                      fails nor finishes.  
#                      
#
#  ENV VARIABLES:      Many environment variables are defined in 
#                          $BATCH_ETC/ftp.<destination>.dat
#                      
#  INPUT:              ftp_deliver.ksh requires one command line argument 
#                          indicating the name of the FTP destination.  
#
#  OUTPUT:             standard log file
#                      <ftp_dest>.<seq#>.scheduled - this file contains the 
#                          list of ftp_q_cards that were scheduled to be 
#                          processed during this run.  
#                      <ftp_dest>.<seq#>.not_scheduled - this file contains 
#                          the list of ftp_q_cards that FAILED to be 
#                          scheduled to be processed during this run.  
#                      <ftp_dest>.<seq#>.errors - this file contains the 
#                          list of ftp_q_cards that were successfully 
#                          scheduled to be processed during this run, but 
#                          had errors during the run.  
#                      <ftp_dest>.<seq#>.status - this file contains a 
#                          summary status of the actions performed during 
#                          this run. 
#
#  TEMPORARY FILES:    fpa_file_list.before - this file is created by FPA.ksh and
#
#  EXT FUNC CALLS:     Standard batch messaging functions in batchlog.ksh and
#                          ksh_functions.ksh
#
#  EXT MOD CALLS:      Standard tools: batchlog.ksh, ksh_functions.ksh, FPA_completion_monitor.ksh
#
#*******************************************************************************
# Date         Programmmer      Description
# ----------   --------------   ------------------------------------------
# 02/12/2004   J Thiessen       New Code.
#                               Need to add second word validation for successful cmd execution in the analyze function. 
# 04/19/2005   J Thiessen       Handling ftp_setmode if not defined in the the ftp configuration file. 
# 04/20/2005   R Crawford       Consoldidation of log files to one per day.
#                               Modified setlog command. Now using batchstartunique
# 02/20/2006   J Thiessen       Corrected an error in analyzing the log files.  
# 06/12/2006   J Thiessen       Added delay notification to catch hung ftp 
#                               processes. Now requires ${BATCH_ETC}/dl.ftp_hung 
#                               and FPA_completion_monitor.ksh. 
#*******************************************************************************

#-------------------------------------------------------------------------------
####
####  The function check_for_ftp_delay recieves the ftp destination as an 
####  argument.  It examines both the pending and ready ftp queue cards for 
####  this destination and determines whether or not the ftp process should 
####  have been completed by this time.  If so, an error message is created 
####  and the FPA will send the notification.  
check_for_ftp_delay() 
{
  echo ${1:-"Pass a parameter to check_for_ftp_delay!!"}
}  ####  END FUNCTION check_for_ftp_delay



#-------------------------------------------------------------------------------
####
####  The function analyze_session reads it's own log file and output file 
####  and records each FTP transmission as successful or unsuccessful.  Then 
####  it creates the corresponding flagfile.
####  NOTE: all reads from u4 and u5 must be done in a single function, this
####  function, because reading from other functions will not update the file
####  descriptors in this function. 
####  
analyze_session()
{
  leavefunction=no
  detected_error=0 
  errmsgs=""
  err_count=0

  ####  
  ####  Create the log file to be analyzed, translating each leading space
  ####  
  echo "ANALYZING SESSION"
  analyzelog=${BATCH_TMP}/`basename ${batch_log}`
  sed 's/^ /-- /' ${batch_log} > ${analyzelog}
  
  ####  
  ####  Open the FTP commands file for this session.
  ####  
  exec 4<"${ftp_tmp_cmd_file}"     ##  File Descriptor 4 contains ftp commands
  if [ $? -ne 0 ]; then
    msg="ERROR - cannot read the FTP Command file, ${ftp_tmp_cmd_file}"
    batcherror_notify "${msg}"
  fi
  leaveloop=no
  cmdlineno=0
  if read -u4 ftp_cmd ftp_args ;then
    cmdlineno=`expr ${cmdlineno} + 1`
    if [ "${ftp_cmd}" != "ftp" ];then
      err_count=`expr ${err_count} + 1`
      errmsgs="ERROR - ${err_count} - Invalid first FTP command, expected 'ftp', but found -->${ftp_cmd}<--"
    fi
  else
    err_count=`expr ${err_count} + 1`
    errmsgs="ERROR - ${err_count} - Cannot read the FTP command file ${ftp_tmp_cmd_file}"
  fi

  ####  
  ####  Get to the actual 'FTP-connection-log' portion of the log file.
  ####  
  exec 5<"${analyzelog}"           ##  File Descriptor 5 contains logged actions
  leaveloop=no
  loglineno=1
  while [ "${leaveloop}" != "yes" ]
  do
    if read -u5 code line ;then
      echo "STATUS=$?   CODE--->${code}<---  LINE--->${line}<---"
      loglineno=`expr ${loglineno} + 1`
      if [ "${code}" = "BEGINNING_FTP_CONNECTION:" ]; then
        leaveloop="yes"
      fi
    else
      echo "STATUS=$?   CANNOT READ u5 -- MUST BE EOF"
      leaveloop="yes"
      leavefunction="yes"
      detected_error=1
      err_count=`expr ${err_count} + 1`
      errmsgs="${errmsgs}ERROR - ${err_count} - Did not initiate FTP Session. "
    fi
  done
  ####  
  ####  Confirm that the FTP connection is established
  ####  
  leaveloop=no
  while [ "${leaveloop}" != "yes" ]
  do
    if read -u5 code line ;then
      loglineno=`expr ${loglineno} + 1`
      ftpS=`echo ${ftpS_ftp} | grep "==${code}==" |wc -l`
      if [ ${ftpS} -gt 0 ];then
        leaveloop="yes"
      fi      # otherwise ignore and get the next line.
    else
      detected_error=1
      err_count=`expr ${err_count} + 1`
      errmsgs="${errmsgs}ERROR - ${err_count} - Failed to connect to FTP server . "
      leaveloop="yes"
    fi
  done

#+# ftp_scheduled_list=${ftp_dest}.${run_seq}.scheduled
#+# ftp_not_scheduled_list=${ftp_dest}.${run_seq}.not_scheduled
#+# ftp_errors_list=${ftp_dest}.${run_seq}.errors
#+# ftp_status_rpt=${ftp_dest}.${run_seq}.status
  ####  
  ####  Loop through both files, read the command, then see if it logged the proper response.
  ####  Build list of successful and errant commands.
  ####  If FPA_FTPMSGS_IN_SUMMARY is set, then write individual FTP file msgs to the daily summary log.
  ####  Keep track of error messages.
  ####  Set Success and Error flags.
  ####  Each loop processes one FTP command. 
  ####  
  let " num_analyzed = 0 "
  if [ ${err_count} -eq 0 ]; then     ## JPT 20060220  Do not try to look for transfer logs if the FTP session never connected. 
    leaveloop=no
  fi
  while [ "${leaveloop}" != "yes" ]
  do
    ####  need successful "put" command to validate success
    ####  ENHANCEMENT
    ####  should also require a successful "dir" command and analyze the 
    ####  output to be sure the dir shows the new file before concluding 
    ####  that the transfer was successful.  This needs to be added later.

    if read -u4 t_cmd t_cmd_args ;then
      if read -u5 code line ;then
#############==========================================================================================
        my_ftpcmd="${t_cmd}"
        my_params="${t_cmd_args}"
        my_retcod="${code}"
        my_retstr="${line}"
        ####
        ####  Define the success and error return codes.
        ####
        t_cmd="echo \${ftpE_${my_ftpcmd}}"
        this_e_string="`eval ${t_cmd:-ERROR_UNDEFINED_FTP_COMMAND}`"
        t_cmd="echo \${ftpS_${my_ftpcmd}}"
        this_s_string="`eval ${t_cmd:-ERROR_UNDEFINED_FTP_COMMAND}`"
      
        unset cmd_successful
        found_response="no"
        while [ "${found_response}" = "no" ]
        do
          ####
          ####  populate variables.
          ####
          ftpS=`echo ${this_s_string} | grep "==${my_retcod}==" |wc -l`
          ftpE=`echo ${this_e_string} | grep "==${my_retcod}==" |wc -l`
          if [ ${ftpS} -gt 0 ];then
            ####  Check for successful command execution
            found_response="yes"
            cmd_successful="yes"
            ####  success
          elif [ ${ftpE} -gt 0 ];then
            ####  Check for errant command execution
            found_response="yes"
            cmd_successful="no"
          else
            ####  Response not found, read next response line and loop.
            if read -u5 my_retcod my_retstr ;then
              :
              ## echo "READING u5 in analyze_session: my_retcod = --->${my_retcod}<---" >> ${batch_log}.debug
              ## echo "READING u5 in analyze_session: my_retstr = --->${my_retstr}<---" >> ${batch_log}.debug
            else
              detected_error=1
              err_count=`expr ${err_count} + 1`
              errmsgs="${errmsgs}ERROR - ${err_count} - Unexpected end of FTP LOG file. "
              found_response=yes
              cmd_successful="no"
              leaveloop=yes
            fi
          fi
        done   ####  Have found the response for the ftp command

        ####  
        ####  for every "put" command, process the ftp q card...
        ####  
        if [ "${my_ftpcmd:-Undefined}" = "put" ]; then
          let " num_analyzed = num_analyzed + 1 "
          tttmp1="echo \${`eval echo sent_qcard_${num_analyzed}`:-UNDEFINED}"
          this_qcard=`eval ${tttmp1}`
          if [ "${this_qcard}" = "UNDEFINED" ]; then
            msg="ERROR: processing ${num_analyzed} 'put' commands but there are only ${num_files_sending} ftp_q_cards "
            batcherror_notify "${msg}"     ##  cannot continue analysis after this error. exit program. 
          fi
          if [ ! -a ${this_qcard} ]; then
            msg="ERROR: : Cannot read FTP QUEUE CARD ${this_qcard}    Processing ${num_analyzed} 'put' commands: "
            batch_notify "${msg}"     ##  may be able to continue analysis after this error...
          else
            flagfile_suffix=`grep "^##- Flag File *-## " ${this_qcard} |tail -1 |sed 's/##- Flag File *-## //' | sed 's/  *//g'` 
            if [ "${cmd_successful:-Undefined}" = "yes" ]; then
              msg="SUCCESSFUL FTP to ${ftp_dest}, ${my_ftpcmd} ${t_cmd_args} "
              echo "##- MSG FROM ftp_deliver.ksh -## ${msg}"  >> ${this_qcard}   ## contents of $msg used again for status_rpt
              flagfile_prefix="FTP_S."
              if read -u5 my_retstr ; then
                echo "##- MSG FROM ftp_deliver.ksh -## ${my_retstr}"  >> ${this_qcard}  # Handle the line reporting number of bytes sent. 
              else
                detected_error=1
                err_count=`expr ${err_count} + 1`
                errmsgs="${errmsgs}ERROR - ${err_count} - Unexpected end of FTP LOG file. "
                found_response=yes
                cmd_successful="no"
                leaveloop=yes
              fi
              mv ${this_qcard} ${BATCH_FTP_QUEUE}/ready_archive  # move to archive directory
              if [ ! -a ${BATCH_FTP_QUEUE}/ready_archive/`basename ${this_qcard}` ]; then
                messagelog_notify "ERROR in command:  mv ${this_qcard} ${BATCH_FTP_QUEUE}/ready_archive"
              fi
            else
              msg="FAILED FTP to ${ftp_dest}, ${my_ftpcmd} ${t_cmd_args} "
              echo "##- MSG FROM ftp_deliver.ksh -## ${msg}"  >> ${this_qcard}   ## contents of $msg used again for status_rpt
              flagfile_prefix="FTP_E."
              mv ${this_qcard} ${BATCH_FTP_QUEUE}/errors  # move to errors directory
              if [ ! -a ${BATCH_FTP_QUEUE}/errors/`basename ${this_qcard}` ]; then
                messagelog_notify "ERROR in command:  mv ${this_qcard} ${BATCH_FTP_QUEUE}/errors"
              fi
            fi
            echo "${msg}"  >> ${ftp_status_rpt}
            messagelog_summary "${msg}"
            if [ ${#flagfile_suffix} -gt 0 ]; then
              flagfile_name="${flagfile_prefix}${flagfile_suffix}"
              echo "#### ${flagfile_name}    ${batch_start_dtm} \n#  ${ftp_dest}, ${my_ftpcmd} ${t_cmd_args} \n#  ${my_retcod} ${my_retstr} "  >> ${BATCH_FLAGS}/${flagfile_name}
            fi
          fi
        fi
        echo "BACK FROM EVALUATING COMMAND...."
      else        ####  end of u5
        detected_error=1
        err_count=`expr ${err_count} + 1`
        errmsgs="${errmsgs}ERROR - ${err_count} - Unexpected end of FTP LOG file. "
        leaveloop=yes
      fi
    else        ####  end of u4
      detected_error=1
      err_count=`expr ${err_count} + 1`
      errmsgs="${errmsgs}ERROR - ${err_count} - Unexpected end of FTP command file. "
      leaveloop=yes
    fi
    if [ "${my_ftpcmd:-NA}" = "End_Send" ];then leaveloop="yes"; fi;
    if [ "${my_retcod:-NA}" = "COMPLETED_FTP_CONNECTION:" ];then leaveloop="yes"; fi;
  done

  exec 4>&-   # close the file descriptor
  exec 5>&-   # close the file descriptor

  if [ ${err_count} -gt 0 ]; then
    messagelog_notify "${errmsgs}"
  fi

  return  ${err_count}   ## 20060619 JPT return the number of errors detected. 

}  ####  END FUNCTION analyze_session

#-------------------------------------------------------------------------------
####
####  The function check_ftp_prereq recieves as a parameter, the name of the 
####  ftp queue card that is pending.  This ftp queue card is examined for 
####  prerequisites.  then each prerequisite is is evaluated and a 'satisfied' 
####  comment is appended to the appropriate prerequisite line.  If the 
####  prerequisite is not satisfied. Then the ftp queue card is examined to 
####  see whether or not the prerequisites for this ftp queue card are 
####  delayed and a notification message is sent if necessary. 
check_ftp_prereq() 
{
  echo ${1:-"Pass a parameter to check_ftp_prereq!!"}
  HERE HERE HERE HERE HERE HERE 
    
}  ####  END FUNCTION check_ftp_prereq

#-------------------------------------------------------------------------------
####
####  The function open_ftp_commands_file uses no parameters.  This function 
####  creates the beginning of an ftp command file , handling the connection 
####  and initial configuration information for this ftp destination.  
####  open_ftp_commands_file 
open_ftp_commands_file() 
{
    echo "DEBUG in open_ftp_commands_file. "
    if [ -r ${ftp_ini_file} ];then
      grep "^##- Connect *-## " ${ftp_ini_file} |sed 's/##- Connect *-## //' >> ${ftp_tmp_cmd_file}
    else
      msg="ERROR--Cannot read the FTP configuration file (${ftp_ini_file})for ${ftp_dest} "
      batcherror_notify "${msg}"
    fi
}  ####  END FUNCTION open_ftp_commands_file

#-------------------------------------------------------------------------------
####  The function add_ftp_commands requires no parameters.  The name of the
####  ftp queue card to process must be previously stored in the variable 
####  ftp_queue_card.  This function combines the information in the ftp queue 
####  card and the data in the ftp configuration file to construct the proper 
####  commands needed to send the file and validate a successful send.  These 
####  commands are then appended to the open ftp commands file.  
####  This function also appends the name of the ftp_q_card the appropriate 
####  'scheduled' or 'failed-to-schedule' output file. 
####  usage: add_ftp_commands 
####  
add_ftp_commands() 
{
    unset this_mode this_dest_file this_source_file
    this_mode=`grep "^##- Mode *-## " ${ftp_queue_card} |head -1 |sed 's/##- Mode *-## //' `
    this_cmd=`grep "^##- Command *-## " ${ftp_queue_card} |sed 's/##- Command *-## //' `
    this_dest_file=`grep "^##- Dest File *-## " ${ftp_queue_card} |head -1 |sed 's/##- Dest File *-## //' `
    this_source_file=`grep "^##- Source File *-## " ${ftp_queue_card} |head -1 |sed 's/##- Source File *-## //' `

####  
####  Check to be sure the source file is sendable before adding commands to 
####  the FTP-command file and MOVING/RENAMING the ftp_queue_card
####  
    ok_to_send=`check_ftp_permissions ${this_source_file}`
    ret_stat=${?}
    if [ "${ret_stat}" != "0" ];then
      msg="ERROR MSG ${ok_to_send} Filename is ${this_source_file} " 
      messagelog "${msg}"
      echo "ERROR ${msg} FTP QUEUE CARD: ${ftp_queue_card}" >> ${ftp_errors_list}
      echo "##- ERROR MSG -## ${batch_start_dtm} ${msg} " >> ${badlist}
      echo "##- ERROR MSG -## ${batch_start_dtm} ${msg} " >> ${ftp_queue_card}
      echo "##- ERROR MSG -## To re-run, move this file into the  ${BATCH_FTP_QUEUE}/ready directory. " >> ${ftp_queue_card}
      echo "${ftp_queue_card}" >> ${ftp_not_scheduled_list}
      mv ${ftp_queue_card} ${ftp_queue_card_E}
      if [ ! -a ${ftp_queue_card_E} ]; then
        msg="ERROR MSG Problem with mv ${ftp_queue_card} ${ftp_queue_card_E} "
        messagelog "${msg}"
      fi
      echo "Skipped"    # Indicate that this ftp q card was NOT included in the command file. 
    else
      if [ "${prev_mode:-UNDEFINED}" != "${this_mode:-UNDEFINED}" ];then
        echo " ${ftp_setmode-} ${this_mode} " >> ${ftp_tmp_cmd_file}     #### JPT 20050419 changed from ${ftp_setmode} to ${ftp_setmode:-} to gracefully handle the case where a special ftp_setmode command is not defined in the destination-profile. 
      fi
      prev_mode=${this_mode:-UNDEFINED}
      if [ ${#this_cmd} -gt 0 ]; then 
        echo "${this_cmd} " >> ${ftp_tmp_cmd_file}
      fi
      echo " put ${this_source_file} ${this_dest_file} " >> ${ftp_tmp_cmd_file}
      dirstr=`echo " dir ${this_dest_file}" |sed 's/(+1)//g'`
      echo " ${dirstr}" >> ${ftp_tmp_cmd_file}
      echo "Sending  FTP QUEUE CARD: ${ftp_queue_card}" >> ${ftp_status_rpt}
      echo "${ftp_queue_card}" >> ${ftp_scheduled_list}
      mv ${ftp_queue_card} ${ftp_queue_card_S} # move to sending dir while processing, move to errors or archive when analyzing results. 
      if [ ! -a ${ftp_queue_card_S} ]; then
        msg="ERROR MSG Problem with mv ${ftp_queue_card} ${ftp_queue_card_S} "
        messagelog "${msg}"
      fi
      echo "Added"    # Indicate that this ftp q card IS INCLUDED in the command file.
    fi
    
}  ####  END FUNCTION add_ftp_commands

#-------------------------------------------------------------------------------
####
####  The function close_ftp_commands_file uses no parameter.  This functions 
####  appends the final commands to properly disconnect the FTP session, 
####  using the information stored in the ftp configuration file for this 
####  destination.   
####  close_ftp_commands_file 
close_ftp_commands_file() 
{
    echo "DEBUG in close_ftp_commands_file -- "
    unset this_mode this_dest_file this_source_file 
    if [ -r ${ftp_ini_file} ];then
      grep "^##- Disconnect *-## " ${ftp_ini_file} |sed 's/##- Disconnect *-## //' >> ${ftp_tmp_cmd_file}
    else
      msg="ERROR--Cannot read the FTP configuration file (${ftp_ini_file})for ${ftp_dest} "
      batcherror_notify "${msg}"
    fi
}  ####  END FUNCTION close_ftp_commands_file

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
APPEND_LOG_FILE=TRUE    ## Do not export
batch_prg="${batch_prg}.${1:-UNDEFINED}"  ## include the destination in the log file name.  
setlog ${batch_prg}.`date +'%Y%m%d'`
batchstartunique    ## Do not start if previous run is still executing. 

badlist=${batch_prg}.badlist.${batch_start_dtm}

####
####  Check for the required parameter.  NOTE that the If_Currently_Running 
####  procedure will search for the string "$$ ${1}" in the output of 
####  'ps -ef' -- keep these names short to prevent truncation. HPUX 11 
####  displays only 60 characters for the full path filename and parameters.
####  And don't forget that starting it in cron prefixes the whole thing with 
####  '/bin/ksh '!!
####
if [ $# -ne 1 ]; then
  msg="Usage:  'ftp_deliver.ksh <destination> ' where destination is the pre-defined name of the destination FTP host. " 
  batcherror "${msg} "
fi

####  
####  Define some variables 
####
ftp_dest=${1}
run_seq=`get_run_seq ${ftp_dest}.seq`
ftp_tmp_cmd_file="${BATCH_TMP}/ftp_to.${ftp_dest}.${run_seq}.cmd"  ## Used by many local functions 
messagelog "FTP command file for this session is ${ftp_tmp_cmd_file}"  
ftp_scheduled_list=${ftp_dest}.${run_seq}.scheduled
ftp_not_scheduled_list=${ftp_dest}.${run_seq}.not_scheduled
ftp_errors_list=${ftp_dest}.${run_seq}.errors
ftp_status_rpt=${ftp_dest}.${run_seq}.status
let "total_bytes = 0"       	# Initialize total number of bytes transferred
####
####  Validate the destination and load site specific information. 
####
ftp_ini_file="${BATCH_ETC}/ftp.${ftp_dest}.dat"                    ## Used by many functions 
if [ -r ${ftp_ini_file} ]; then
  . ${ftp_ini_file}           ##  
else
  msg="ERROR:  '${ftp_dest}' is not a configured FTP destination. " 
  for x in `ls -1 ${BATCH_FTP_QUEUE}/ready/${ftp_dest}\.*`
  do
    echo "##- MSG FROM ftp_deliver.ksh -## ${msg} " >> ${x}
    mv ${x} ${BATCH_FTP_QUEUE}/errors/${x##*/}.E${run_seq}
  done
  batcherror "${msg} "    ##  exit the program
fi

####
####  Set variables that should be defined by sourcing ${ftp_ini_file} 
####
my_xfer_rate=${ftp_xfer_rate:-80}  # Default to 80 Kbytes/s if not set by the ftp.<destination>.dat file
processing_delay=${ftp_est_processing_delay:-600}   # Default to 600 seconds delay beyond estimated transfer time before sending error alert msg.  

####
####  Ensure that this script is only running once.  
####
cycle_counter=0
If_Currently_Running
ReturnCode=$?
if [ "${ReturnCode}" = "0" ]; then
  date >> ${BATCH_ETC}/${batch_prg}.attempted_starts
  start_count=`cat ${BATCH_ETC}/${batch_prg}.attempted_starts |wc -l |awk '{print $1}'` # JPT 20050128 changed syntax to omit filename from variable. 
  messagelog "${batch_prg} is currently running.  This attempt to run ${batch_prg} is attempt number ${start_count} since the last successful completion."
  check_for_ftp_delay ${ftp_dest}     ## ## ## HERE HERE HERE HERE
  batchend
fi             

######==-- 20040428 ####  
######==-- 20040428 ####  Create and check a list of PENDING files to be sent to this destination. 
######==-- 20040428 ####
######==-- 20040428 num_pending=`ls -1 ${BATCH_FTP_QUEUE}/pending/${ftp_dest}\.* 2>/dev/null |wc -l`
######==-- 20040428 if [ "${num_pending}" = "0" ];then
######==-- 20040428   msg="There are no PENDING FTP files for ${ftp_dest} "
######==-- 20040428   messagelog "${msg}"
######==-- 20040428 else
######==-- 20040428   messagelog "List of pending ftp queue cards for ${ftp_dest} shown below... "
######==-- 20040428   ls -l ${BATCH_FTP_QUEUE}/pending/${ftp_dest}\.*  >> ${batch_log} 2>&1
######==-- 20040428   messagelog "End of pending ftp queue cards for ${ftp_dest} "
######==-- 20040428   for x in `ls -1 ${BATCH_FTP_QUEUE}/pending/${ftp_dest}\.* 2>/dev/null`
######==-- 20040428   do
######==-- 20040428     check_ftp_prereq ${x}
######==-- 20040428   done
######==-- 20040428 fi

####  
####  Create list of files ready to be sent to this destination, exit if none. 
####
set -A ready_files `ls -1 ${BATCH_FTP_QUEUE}/ready/${ftp_dest}\.* 2>/dev/null `
num_files=${#ready_files[*]} 
if [ "${num_files}" = "0" ];then
  msg="There are no FTP files ready to be delivered to ${ftp_dest} "
  messagelog "${msg}"
  batchend
fi

####  
####  Create FTP command file for this destination. 
####
open_ftp_commands_file 

####  
####  Process the list of files READY to be sent to this destination. 
####
let " num_files_sending = 0 "
echo "Preparing to FTP files:" >> ${ftp_status_rpt} 
msg="List of ${num_files} ftp queue cards ready for ${ftp_dest} is: ${ready_files[*]} "
messagelog "${msg}"
for x in ${ready_files[*]} 
do
  export ftp_queue_card=${x}
  if [ -r ${ftp_queue_card} ];then
    echo "Reading the FTP QUEUE CARD: ${ftp_queue_card}" >> ${ftp_status_rpt}
    export ftp_queue_card_S=${BATCH_FTP_QUEUE}/sending/`basename ${ftp_queue_card}`.S${batch_start_dtm} # New name of scheduled ftp queue card. 
    export ftp_queue_card_E=${BATCH_FTP_QUEUE}/errors/`basename ${ftp_queue_card}`.E${batch_start_dtm} # Name for errant ftp queue card. 
    add_commands=`add_ftp_commands ${x}`
    if [ "${add_commands}" = "Added" ]; then
      let " num_files_sending = num_files_sending + 1 "
      file_size=`grep "##- File Size   -## " ${ftp_queue_card_S}  |head -1 |sed 's/##- File Size   -## //' `
      file_size=${file_size:-0}    ## If grep did not match a number, then set to zero 
      let "tmp_total_bytes = total_bytes + file_size "
      if [ ${tmp_total_bytes} -lt 0 ]; then   ##  check for integer overflow and add element to tot_bytes_array if necessary.    
        set -A tot_bytes_array `echo ${tot_bytes_array[*]:-} ${total_bytes}`   # First add element to array... 
        total_bytes=file_size               # Then reset total_bytes to current file_size.  
      else
        let " total_bytes = tmp_total_bytes "
      fi
      eval sent_qcard_${num_files_sending}=${ftp_queue_card_S}
    else
      msg="WARNING--Cannot process commands for the FTP QUEUE CARD: ${ftp_queue_card}"
      messagelog "${msg}"
      echo "Cannot process the FTP QUEUE CARD: ${ftp_queue_card}" >> ${ftp_status_rpt}
      echo "Cannot process the FTP QUEUE CARD: ${ftp_queue_card}" >> ${ftp_errors_list}
    fi
  else
    msg="WARNING--Cannot read the FTP QUEUE CARD: ${ftp_queue_card}"
    messagelog "${msg}"
    echo "Cannot read the FTP QUEUE CARD: ${ftp_queue_card}" >> ${ftp_status_rpt}
    echo "Cannot read the FTP QUEUE CARD: ${ftp_queue_card}" >> ${ftp_errors_list}
  fi
done

####  
####  Close FTP command file for this destination. 
####
close_ftp_commands_file ${ftp_dest} ${run_seq}

####  
####  Remove blank lines before running. 
####
cat ${ftp_tmp_cmd_file} | sed 's/ *$//' | sed '/^$/d' > ${ftp_tmp_cmd_file}.tmp
mv ${ftp_tmp_cmd_file}.tmp ${ftp_tmp_cmd_file}

####  
####  Estimate the required time and start the monitor for delays 
####
kbytes=0
date
if [ ${#tot_bytes_array[*]} -gt 0 ]; then    ##  If there was an integer overflow, include the elements of tot_bytes_array
  count=0
  while [ ${count} -lt ${#tot_bytes_array[*]} ]
  do
    let " kbytes = ${tot_bytes_array[${count}]} / 1000  + kbytes "
    let " count = count + 1 "    
  done
fi
date
let "kbytes = total_bytes / 1000 + kbytes "    ##  Add current total_bytes variable
if [ ${my_xfer_rate} -lt 1 ]; then   ##  Prevent divide by zero errors
  my_xfer_rate=1
fi
expected_duration=`expr ${processing_delay} + \( ${kbytes} / ${my_xfer_rate} \)`
FPA_nohup.ksh FPA_completion_monitor.ksh $$ ${expected_duration} dl.ftp_hung ERROR

####  
####  20060619  Determine the elapsed time
####  
time_before_ftp=`eval date +%s`


####  
####  Execute FTP command file for this destination. 
####
echo "BEGINNING_FTP_CONNECTION:" >> ${batch_log}
set -v                  ################# DEBUG  Uncomment this line for production!!!
. ${ftp_tmp_cmd_file} >> ${batch_log} 2>&1
ReturnCode=$?
set -                   ################# DEBUG  Uncomment this line for production!!!
echo "COMPLETED_FTP_CONNECTION:" >> ${batch_log}

####  
####  20060619  Determine the duration of the ftp connection
####  
####  batch_start_sec
time_after_ftp=`eval date +%s`
let "duration_sec = time_after_ftp - time_before_ftp"




####  
####  Flush the output buffers to disk. 
####  If still not written after 200 seconds, there's a problem so analyze the log file anyway. 
####  
leaveloop=no
let count=0
while [ "${leaveloop}" != "yes" ]
do
  sleep 10
  sync
  jnk=`grep "COMPLETED_FTP_CONNECTION:" ${batch_log} |wc -l`
  if [[ ( ${jnk} -gt 0 ) || ( ${count} -gt 20 ) ]]; then
    leaveloop="yes"
  else
    let count=${count}+1
  fi
done
  


####
####  Analyze results of the FTP session. 
####
analyze_session
if [ "${ReturnCode}" != "0" ]
then
  msg="ERROR -- ${batch_prg}.  Error executing the FTP instruction file ${ftp_tmp_cmd_file}"
  batcherror_notify "${msg}"
fi

####  
####  20060619 JPT  If there were no errors then record the effective transfer rate for the FTP session.
####  
if [ ${duration_sec} -lt 1 ]; then   ##  Prevent divide by zero errors
  duration_sec=1
fi
let "xfer_rate = total_bytes / duration_sec / 1000 "  
messagelog "FTP transfer rate:  ${xfer_rate} kb/s: ${UNAME:-noUser} ${BATCH_ACCOUNT_NAME:-noAcct} ${BATCH_ENVIRONMENT:-noEnv} ${HN:-noHost} sent ${total_bytes} bytes to ${ftp_dest} in ${duration_sec} seconds "

####
####  Clear the attemped_starts file if necessary.
####
###  if [ -a ${BATCH_ETC}/${batch_prg}.attempted_starts ]; then
###    echo "ATTEMPTED STARTS while this program was running:" >> ${batch_log} 2>&1
###    cat ${BATCH_ETC}/${batch_prg}.attempted_starts >> ${batch_log} 2>&1
###    echo "SUCCESSFUL COMPLETION at `date`" >> ${batch_log} 2>&1
###    rm -f ${BATCH_ETC}/${batch_prg}.attempted_starts
###  fi


batchend
