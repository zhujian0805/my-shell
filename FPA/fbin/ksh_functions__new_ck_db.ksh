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
#  NAME:               ksh_functions.ksh
#
#  DESCRIPTION:        This script contains the additional functions for
#                      use in korn shell scripts.  
#                      Scripts that need to use these functions must source 
#                      this script before calling any function contained here.
#            1:        get_next_month  - echos the string MMDDYYYY for the first
#                      of the following month.  
#  
#            2:        get_run_seq  -- echoes the numeric string of the next 
#                      sequence number for the current $batch_prg. Reads and 
#                      writes ${BATCH_ETC}/${batch_prg}.seq to contain the 
#                      sequence number being used at this time.
#  
#  EXT DATA FILES:     N/A
#
#  ENV VARIABLES:      LOGNAME
#                      BATCH_LOGS
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
# 01/21/2002   J. Thiessen      New Code.
# 04/30/2002   J. Thiessen      Added get_jobs_starttime 
# 06/21/2002   J. Thiessen      Changed the default response to 19000101000000
#                               for the get_jobs_starttime function.
# 06/26/2002   J. Thiessen      Added check_for_ftp_errors function.
# 07/17/2002   J. Thiessen      Added set_oracle_sid function.
# 07/17/2002   J. Thiessen      Added get_user_pass function.
# 02/26/2003   J. Thiessen      Added get_ftp_info function.
# 03/20/2003   J. Thiessen      Added get_name_from_semaphore function.
# 02/12/2004   J. Thiessen      Added If_Currently_Running -- moved here from FPA.ksh
# 02/24/2004   J. Thiessen      Changed set_oracle_sid to use oraenv 
# 03/16/2004   J. Thiessen      added check_ftp_permissions function
# 04/01/2004   J. Thiessen      added ' view ' check in If_Currently_Running
# 04/06/2004   J. Thiessen      added ftp_mkready function 
# 09/09/2004   J. Thiessen      added make_dir function 
# 02/04/2005   J. Thiessen      Added -p to create intermediate dirs also
# 03/08/2005   J. Thiessen      Added Yesterday_Date for Greg 
# 04/08/2005   J. Thiessen      Moved format_input from menu.ksh to ksh_functions
# 04/08/2005   J. Thiessen      Added elapsed_time, used by batchlog  (requires GNU date !! )
# 09/15/2005   R. Crawford      Replaced /tmp with ${BATCH_TMP} to help 
#                               modify the accounts on the mid-tier structure
# 10/12/2005   J. Thiessen      Checks $BATCH_ETC/ksh_functions_custom.ksh for
#                               custom ksh functions. 
# 01/24/2006   R. Crawford      Added copy_file function
# 02/13/2006   J. Thiessen      Added Call_Java and Check_Log 
# 02/20/2006   J. Thiessen      Added collapse_dirname function. 
# 04/17/2006   J. Thiessen      Modified get_run_seq to prevent concurrency problems
# 04/24/2006   J. Thiessen      Added BATCH_WINDOW functions. 
# 05/20/2006   J. Thiessen      Added functions to return DDS names tradingPartnerRoot directory
# 08/21/2006   J. Thiessen      Added Call_Sql_Stored 
# 09/22/2006   J. Thiessen      Added Check_Last_XML_Tag, Get_Simple_XML_Field_Value and File_Newer_Than
# 10/04/2006   J. Thiessen      Added 
# 01/11/2007   J. Thiessen      Added move_file
# 2007-04-14   J. Thiessen      Added ck_db
# 2007-04-24   J. Thiessen      Added Call_Sql
# 2007-05-16   J. Thiessen      Updated ck_db to time out if no response
# 
#*******************************************************************************

####----------------------------------------------------------------------------
####  NOTE:  The db_connect function is intended to be executed as a background process o connect to the specified database and exit. While this process does return wiht an appropriate status indication of success or failure and is also monitored via the "jobs" command.  
db_connect() {

  set -vx
  sleep 15
  my_prefix="PID=$$    `date +'%Y%m%d%H%M%S'`    STARTING  "
if [ $# -ne 1 ]; then     #### Validate USAGE
  return_stat=7
  return_msg="ERROR: ck_db USAGE: ck_db requires the database name as the only parameter. ($@) "
fi

  my_userpass=`grep -i "^#allowed_db ${my_sid:-UNDEFINED}" ${BATCH_ETC}/.oracle.batch.profile | head -1 |awk -F" " '{print $3}'`
  my_userpass="ppadmin/pppsc"       #### These are just for testing....DEBUG
  my_sid=pphsdev                    #### These are just for testing....DEBUG


  echo "${my_prefix}    STARTING  $0"  >> /asp/FPA/j.ck.log 2>&1    #### These are just for testing....DEBUG
    my_ans=`sqlplus /nolog  <<-ENDSQL
         connect ${my_userpass}@${my_sid};
         set head off;
         select 'FPAuser='|| user ||' on database '|| global_name ||' at '||to_char(sysdate,'YYYY-MM-DD HH24:MI:SS') from global_name;
         select 'DATETIME_ON_DATABASE='|| to_char(sysdate,'YYYYMMDDHH24MISS') from global_name;
         exit;
ENDSQL`
    my_count=`echo ${my_ans} | grep -i "FPAuser=${my_userpass%/*} on database ${my_sid}"   | wc -l`
    if [ ${my_count} = 1 ];then      ##  Success, the database is accessible.
      return_stat=10
      return_msg="SUCCESS: ck_db   The ${my_sid} database is accessible. "
      echo "${my_prefix}    SUCCESS SUCCESS SUCCESS SUCCESS  \nMY_ANS\n${my_ans}\nEND_OF_MY_ANS"  >> /asp/FPA/j.ck.log 2>&1    #### These are just for testing....DEBUG
    else
      return_stat=11
      echo "${my_prefix}    DB_DOWN   DB_DOWN  DB_DOWN  DB_DOWN   \nMY_ANS\n${my_ans}\nEND_OF_MY_ANS"  >> /asp/FPA/j.ck.log 2>&1    #### These are just for testing....DEBUG
    fi

      echo "${my_prefix}    RETURNING ${return_stat}   \n\n"  >> /asp/FPA/j.ck.log 2>&1    #### These are just for testing....DEBUG
  return ${return_stat}


}  ####  END FUNCTION db_connect



####----------------------------------------------------------------------------
####  NOTE:  The ck_db function  returns wiht a zero status if the database 
####  specified in parameter 1 is accessible (non-zero return status means 
####  that the database is NOT accessible).  
####  Accessible means that this FPA environment is permitted to interact with 
####  the specified database AND that the database is responding to simple 
####  commands.  
####  Each time it runs, this function overwrites its own current status file 
####  which resides in BATCH_TMP and is named ck_db.<SID>.log   
####  In addition, this routine creates teh ck_db.<SID>.UP and ck_db.<SID>.DOWN 
####  files in BATCH_ETC as needed and moves these files to BATCH_LOGS when 
####  they become obsolete. 
####   
ck_db_j() {
set -vx
echo "DEBUG DEBUG DEBUG  ENTRING THE DEBUG ZONE"
unset return_stat return_msg my_sid my_status_file my_down_file my_up_file myline my_userpass my_ans my_count my_time my_connect_stat
my_time=`date +'%Y%m%d%H%M%S'`
my_status_file=${BATCH_TMP:-/BATCH_TMP/is/not/defined}/ck_db.${my_sid:-NoSID}.log
if [ $# -ne 1 ]; then     #### Validate USAGE
  return_stat=7
  return_msg="ERROR: ck_db USAGE: ck_db requires the database name as the only parameter. (${@:-NoParameters}) "
else
  my_sid=`echo ${1} | tr [a-z] [A-Z]`    ## be sure the database is specified in uppercase characters. 
  my_status_file=${BATCH_TMP:-/BATCH_TMP/is/not/defined}/ck_db.${my_sid}.log
  my_down_file=${BATCH_ETC:-/BATCH_ETC/is/not/defined}/ck_db.${my_sid}.DOWN
  my_up_file=${BATCH_ETC:-/BATCH_ETC/is/not/defined}/ck_db.${my_sid}.UP
  myline=`grep -i "^#allowed_db ${my_sid:-UNDEFINED}" ${BATCH_ETC}/.oracle.batch.profile `
  if [ ${?} -ne 0 ];then     #### Validate permission to access the database
    return_stat=8
    return_msg="ERROR: ck_db   This FPA environment is not permitted to access the ${1} database. "
  else 
    my_userpass=`grep -i "^#allowed_db ${my_sid:-UNDEFINED}" ${BATCH_ETC}/.oracle.batch.profile | head -1 |awk -F" " '{print $3}'`
    ####  
    ####  Loop to be sure this process does not get hung
    ####
    return_stat=11 
    responded=FALSE
    loopcount=0
    max_loops=10  ## if the database does not respond in this number of seconds then declare it unavailable. 
    prev_line=""
    curr_line=""
    db_connect ${my_sid}  >> ${batch_log} 2>&1  &   #### Connect to the database in the background to prevent this process from hanging. 
    while [ ${responded} = "FALSE" -a ${loopcount} -lt ${max_loops} ]
    do
      let loopcount=loopcount+1 
      prev_line="${curr_line}"
      curr_line=`jobs -l`
      ndone=`echo ${curr_line} | grep " Done(" | wc -l`
      nrun=`echo ${curr_line} | grep " Running " | wc -l`
      if [ ${ndone} -eq 1 ];then
        responded=TRUE
      elif [ ${nrun} -eq 1 ];then
        sleep 1
      else
        log_line="Database ${my_sid} did not respond after ${loopcount} seconds.  \n## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> CURRENT LINE: \n${curr_line}\n## <<<<<<<<<<<<<<<<<<<<< end of CURRENT LINE"  
        echo ${log_line} >> ${batch_log} 2>&1       ####  DEBUG
      fi
    done
    echo "\nDEBUG DEBUG prev_line=${prev_line}"   ${batch_log} 2>&1  
    echo   "DEBUG DEBUG curr_line=${curr_line}\n" ${batch_log} 2>&1  
    my_connect_stat=`echo ${curr_line##*\(} |cut -d\) -f1`


    if [ ${responded} = "TRUE" ]; then
      my_connect_stat=`echo ${curr_line##*\(} |cut -d\) -f1`
    else
      my_connect_stat=1
    fi

####     HERE HERE HERE HERE HERE HERE  
####  y=[1] + 561272   Running                 db_connect > jj.jj.jj.log 2>&1 &
####[1] +  Done(2)                 db_connect > jj.jj.jj.log 2>&1 &
####a
####     HERE HERE HERE HERE HERE HERE  



    if [ "${my_connect_stat}" = "10" ];then      ##  Success, the database is accessible.
      return_stat=0
      return_msg="SUCCESS: ck_db   The ${my_sid} database is accessible. "
      ####
      ####  Clear the "db_down" file if it exists
      ####
      if [ -a ${my_down_file} ];then
        mv ${my_down_file} ${BATCH_LOGS}/${my_down_file##*/}.BackUpAt${my_time} 
        echo "${my_sid} came up at ${my_time} \n${return_msg}\nSTATUS is ${return_stat}\n${my_ans:-Unable to connect to the database}" >${my_up_file} 
        messagelog_notify "RESOLVED:  From ${UNAME:-unknown}:  The database, ${my_sid}, is now available at ${my_time} "
      fi
      if [ ! -a ${my_up_file} ];then
        echo "${my_sid} is (still) up at ${my_time} \n${return_msg}\nSTATUS is ${return_stat}\n${my_ans:-Unable to connect to the database}" >${my_up_file} 
      fi
    else      #### permitted to access teh databse but the database is not accessible.  
      if [ "${my_connect_stat}" = "11" ];then        ##  local system determined that the database is down.
        return_stat=9
        return_msg="ERROR: ck_db   The ${my_sid} database is DOWN  (not accessible). "
      else                                           ##  this process took to long (hung?) so we will treat the DB as if it is down. 
        return_stat=8
        return_msg="ERROR: ck_db   The ${my_sid} database is NOT RESPONDING  (not accessible). "
      fi
      ####
      ####  Clear the "db_up" file if it exists
      ####
      if [ -a ${my_up_file} ];then
        mv ${my_up_file} ${BATCH_LOGS}/${my_up_file##*/}.WentDownAt${my_time} 
        echo "${my_sid} went down at ${my_time} \n${return_msg}\nSTATUS is ${return_stat}\n${my_ans:-Unable to connect to the database}" >${my_down_file} 
        messagelog_notify "ALARM:  From ${UNAME:-unknown}:  The database ${my_sid} went down at ${my_time} "
      fi
      if [ ! -a ${my_down_file} ];then
        echo "${my_sid} is (still) down at ${my_time} \n${return_msg}\nSTATUS is ${return_stat}\n${my_ans:-Unable to connect to the database}" >${my_down_file} 
      fi
    fi
  fi 

fi
echo "${return_msg}\nSTATUS is ${return_stat}\n${my_ans:-Unable to connect to the database}" > ${my_status_file}  ##  Overwrite the status file.  
return ${return_stat}

}  ####  END FUNCTION ck_db


####----------------------------------------------------------------------------
####
####  This function 
####  $1  Integer Value
####  $2  Units for integer value (seconds, minutes, days, months, years) 
####  $3  Filename (full or relative path) 
####  
####  
####  

File_Newer_Than ()
{
  ## ## set -vx
  response="ERROR in File_Newer_Than Failed to start:  "
  ret_stat=1  # return error status unless function completes.
  if [ ${#} -ne 3 ]; then   #abort if called with wrong number of parameters.
    response="ERROR in File_Newer_Than Invalid parameters: ${*:-}"
  elif [ ! -r ${3:-/No/File/Specified} ]; then   # Does the input file exist?
    response="ERROR in File_Newer_Than File ${2:-/No/File/Specified} does not exist"
  else   # Parameters are valid, begin the check
    cmd_string="date --date='-${1} ${2}' +%m%d%H%M%y"
    compare_date=`eval ${cmd_string}` 
    compare_file="${BATCH_TMP}/File_Newer_Than.${compare_date}.$$.dat"
    touch ${compare_date} ${compare_file}
    if [ ! -a ${compare_file} ]; then
      #### Error if file does not exist
      response="ERROR in File_Newer_Than: compare_file does not exist: ${compare_file} "
    else
      my_dir="`dirname ${3}`"
      my_file="`basename ${3}`"
      ##### HERE find ${my_dir} \( -type d ! -name ${my_dir##*/} -prune \) -o \( -type f -name ${my_file} -newer ${compare_file} -print \)
      found_file=`find ${my_dir} \( -type d ! -name ${my_dir##*/} -prune \) -o \( -type f -name ${my_file} -newer ${compare_file} -print \)`
      if [ ${#found_file} -gt 0 ]; then
        #### File is newer than target. 
        response="NEWER: file ${3} is newer than ${compare_date}"
      else
        #### File is older than target. 
        response="OLDER: file ${3} is older than ${compare_date}"
      fi
      ret_stat=0  # return successful status 
    fi
  fi
  echo "${response}"
  return ${ret_stat}

}  ####  END FUNCTION File_Newer_Than



####----------------------------------------------------------------------------
####
####  This function tests that the 837 outbound x12 file indicated in 
####  parameter 1 contains the "RP" code for ENCOUNTERS ONLY, and if not, 
####  it changes this field to indicate RP. 
####  If changing the file, it will be renamed to  the same filename as 
####  before but will end with the string "_resetBHT.x12" instead of just ".x12" 
####  
Set_BHT_to_Encounters ()
{
  file_name=${1:-ERROR}
  if [ ! ${file_name}  ]; then
    errmsg="ERROR  Set_BHT_to_Encounters: File ${1} is not readable." 
    batcherror_notify "${errmsg}"  ##  exit w/ error here...
  fi
  tmp_line=`head -4 ${file_name} |tail -1 `  >>  ${batch_log}
  if [ "`echo ${tmp_line:-jnk} |cut -c1-3`" != "BHT" ]; then
    errmsg="ERROR  File ${1} does not have a properly formatted BHT segment." 
    batcherror_notify "${errmsg}"  ##  exit w/ error here...
  fi
  tmp_line2=`echo ${tmp_line:-jnk} |grep "CH$"`  ## Look for the code for either CLAIMS or ENCOUNTERS 
  tmp_line3=`echo ${tmp_line:-jnk} |grep "RP$"`  ## Look for the ENCOUNTERS ONLY code
  if [ ${#tmp_line3} -gt 0 ]; then
    msg="The x12 file is already set to ENCOUNTERS ONLY -- No need to change this file. "
    messagelog "${msg}"
  elif [ ${#tmp_line2} -gt 0 ]; then
    msg="Need to reset the code to ENCOUNTERS ONLY. " 
    messagelog "${msg}"
    my_file=${1##*/}
    my_path=${1%/*} 
    my_new_file=${my_path}/${my_file%.*}_resetBHT.${my_file##*.}
    sed 4s/CH$/RP/ ${1} > ${my_new_file}    # Change the value in the file
    ck_line=`head -4 ${my_new_file} |tail -1 |grep "^BH" |grep "RP$"`
    my_diff_num=`diff ${my_new_file} ${1} | wc -l`
    if [ ${#ck_line} -gt 9 -a ${my_diff_num} -eq 4 ]; then
      rm -f ${1}      ###  Remove the original file. 
      if [ -a ${1} ]; then
        msg="ERROR:  Unable to remove unedited x12 file. "
        batcherror_notify "${msg}"  ##  exit w/ error here...  otherwise we might process both files. 
      fi
    else
      msg="ERROR: BHT Unable to modify BHT06 segment in file ${1}"
      batcherror_notify "${msg}"  ##  exit w/ error here...  otherwise we might process a bad file. 
    fi
  
  else
    msg="ERROR:  the file ${1} has a badly formed BHT 06 segment "
    batcherror_notify "${msg}"  ##  exit w/ error here...  otherwise we might process a bad file. 
  fi
}  ####  END FUNCTION Set_BHT_to_Encounters



####----------------------------------------------------------------------------
####
####  This function simply echoes its parameter string 
####  
Echo_Parms ()
{
  echo ${*:-}

}  ####  END FUNCTION Echo_Parms



####----------------------------------------------------------------------------
####
####  This function calls Check_Last_XML_Tag to confirm that the xml input 
####  file is complete.  
####  If complete, it calls calls Get_Simple_XML_Field_Value to 
####  pull the TransactionType from the file specified in $1.  
####  If incomplete, it calls File_Newer_Than to determine whether or not 
####  to remove an orphaned file.  
####  

Get_TransactionType ()
{
  ## ##  set -vx
  write_delay_ok=60  ## After this number of minutes without a change, treat the incomplete file as an orphaned ftp file. 
  response="ERROR Generic error for File: ${1:-NoFileSpecified}"
  ret_stat=1  # return error status unless function completes.
  if [ ${#} -ne 1 ]; then   #abort if called with wrong number of parameters.
    response="ERROR: Get_TransactionType requires one parameter to specify the File: ${*:-} "
  else
    #### Check to see if input file is complete.
    last_field=`Check_Last_XML_Tag CommandHeader ${1}`
    if [ "${last_field%% *}" = "FOUND:" ]; then
      ####  Input file is ready for processing.  
      tmp=`Get_Simple_XML_Field_Value TransactionType ${1}`    #### Get the TransactionType...
      ret_stat=$?
      if [ ${ret_stat} -ne 0 ]; then 
        #### Error finding the xml element, leave function...
        response="ERROR finding the xml element: ${tmp:-Undefined}"
      else
        #### Found value. process the data...
        my_value=`echo ${tmp} | grep "^<Value>" | cut -c8- |cut -d\< -f1`
        if [ ${#my_value} -gt 0 ]; then
          response="${my_value}"
        else
          response="ERROR TransactionType is not defined in ${1}"
        fi
      fi   ## close TransactionType test statement
    else
     :  
###########################################################################################################################  HERE HERE HERE 
########### Finish this error handling tomorrow....   #####################################################################  HERE HERE HERE 

      ####  The input file is not complete.  
      set -A tmpa `File_Newer_Than ${write_delay_ok} minutes ${1}`
      ret_stat=$?
      tmp="${ret_stat}${tmpa[0]:-Undefined}"
      if [ "${tmp}" = "0NEWER:" ]; then 
        #### Wait, the input file is still being written...
        response="WAIT: The input file is still being written: ${1} "
      elif [ "${tmp}" = "0OLDER:" ]; then
        #### The process writing the input file has apparently failed before completely writing the file. 
        response="ORPHAN_FILE: The process writing the input file has apparently failed before completely writing the file ${1} "
      else
        #### There was a problem determining the age of the input file...
        response="ERROR finding the xml element: ${tmp:-Undefined}"
      fi   ####  Handled both complete and incomplete file...

    fi  # Closing the test for for the input file being completely written.
  fi  # Closing test for proper arguments to this function. 
  echo "${response}"
  return ${ret_stat}

}  ####  END FUNCTION Get_TransactionType


####----------------------------------------------------------------------------
####
####  This function looks at the first 512 * 20 bytes (or 20 lines if there 
####  are linefeeds) of the file specified in $2 to find the VALUE associated 
####  with the XML field name is specified in $1
####  The value of the field is echo'd by this function. 
####  If the field is repeated, only the first value is returned.  
####  NOTE: if the value contains the character "<" only the string preceeding 
####  the "<" will be returned.
####  

Get_Simple_XML_Field_Value ()
{
  ## ## set -vx
  response="<ERROR_Message>Get_Simple_XML_Field_Value Failed to start </ERROR_Message> "
  ret_stat=1  # return error status unless function completes.
  if [ ${#} -ne 2 ]; then   #abort if called with wrong number of parameters.
    response="<ERROR_Message>Get_Simple_XML_Field_Value Field File Invalid parameters: ${*:-} </ERROR_Message>"
  elif [ ! -r ${2:-/No/File/Specified} ]; then   # Does the input file exist?
    response="<ERROR_Message>Get_Simple_XML_Field_Value File ${2:-/No/File/Specified} does not exist.</ERROR_Message>"
  else   # Parameters are valid, begin the check
    now=`date +'%Y%m%d%H%M%S'`
    tmp_file=${BATCH_TMP}/Get_Simple_XML_Field_Value.${now}.${$}
    field_len=${#1}
    fold -w 512 ${2} |head -20 | tr -d '\012' | cut -c1- | sed 's/\</\
\</g' |grep "^\<${1}\>" > ${tmp_file}

    ret_stat=${?}
    if [ ${ret_stat} -ne 0 ]; then  
      response="<ERROR_Message>Get_Simple_XML_Field_Value ret_stat=${ret_stat} Field ${1} was not found in beginning of file ${2:-/No/File/Specified} </ERROR_Message>"
    elif [ -s ${tmp_file} ]; then  
      ####  The field was found...
      len3=`expr ${#1} + 3`
      my_value=`head -1 ${tmp_file} | cut -c${len3}-` 
      if [ ${#my_value} -gt 0 ]; then 
        ####  The field contains data...
        response="<Value>${my_value}</Value>"
      else
        ####  The field does NOT contain data...
        response="<NoValue>Field ${1} contains no data</NoValue>"
      fi
    else
      #### Should never get to this condition. The field does NOT exist...
      response="<ERROR_Message>Field ${1} was not found in beginning of file ${2:-/No/File/Specified}</ERROR_Message>"
    fi

  fi
  echo "${response}"
  return ${ret_stat}
}  ####  END FUNCTION Get_Simple_XML_Field_Value


####----------------------------------------------------------------------------
####
####  This function checks that the file specified in $2 ends by closing the field specifed in $1. 
####  Specifically searching for "</${1}>" as the last characters in the file.
####  
####  
####  
####  

Check_Last_XML_Tag ()
{
  ## ## set -vx
  response="ERROR in Check_XML_File: Failed to start:  " 
  ret_stat=1  # return error status unless function completes. 
  if [ ${#} -ne 2 ]; then   #abort if called with wrong number of parameters.
    response="ERROR in Check_XML_File: Invalid parameters: ${*:-}"
  elif [ ! -r ${2:-/No/File/Specified} ]; then   # Does the input file exist? 
    response="ERROR in Check_XML_File: File ${2:-/No/File/Specified} does not exist"
  else   # Parameters are valid, begin the check
    field_len=${#1}
    ####  extract last 512-to-1024 characters and remove all spaces and tabs. 
    ######################################temp=`fold -w 512 ${2} |tail -2 | tr -d '\012' |sed 's/[        ][      ]*//g'` 
    temp=`fold -w 512 ${2} |tail -2 | tr -d '\012' `
    temp_len=${#temp}  
    if [ ${temp_len} -lt ${field_len} ]; then 
      ####  extract last 1024-to-1536 characters and remove all spaces and tabs. 
      temp=`fold -w 512 ${2} |tail -3 | tr -d '\012' `
      temp_len=${#temp}  
    fi
    temp1=`echo "${temp}" | grep "</${1}>$"`
    if [ $? -eq 0 ]; then
      ####  Last xml tag in file is  closing $1. 
      response="FOUND: Last XML tag in `basename ${2}` is </${1}>"
      ret_stat=0  # return successful status 
    else
      ####  Successfully examined file, but the last xml tag in file is NOT $1. 
      response="NOMATCH: Last XML tag in `basename ${2}` is NOT </${1}>"
      ret_stat=0  # return successful status 
    fi
  fi
  echo "${response}"
  return ${ret_stat}
}  ####  END FUNCTION Check_Last_XML_Tag


####----------------------------------------------------------------------------
####
####  The function format_input formats user input according to specified rules.
####  For integers: $1 must = "i", $2 is the value to be checked, $3 must be 
####  an integer, the width of the field
####  To left-pad strings: $1 must = "l", $2 is the value to be checked, $3 must be 
####  an integer, the width of the field, $4 is the character to pad with (defaults 
####  to a space) 
####  To right-pad strings: $1 must = "r", $2 is the value to be checked, $3 must be 
####  an integer, the width of the field, $4 is the character to pad with (defaults 
####  to a space) 
####  To left-pad strings and convert them to uppercase: $1 must = "L", $2 is 
####  the value to be checked, $3 must be an integer, the width of the field, 
####  and $4 is the character to pad with (defaults to a space) 
####  To right-pad strings and convert them to uppercase: $1 must = "R", $2 is 
####  the value to be checked, $3 must be an integer, the width of the field, 
####  and $4 is the character to pad with (defaults to a space) 
####  JPT 20030111
####  If a width of zero (0) is specified, any width is accepted and no padding
####  will be used.  
####
function format_input {
####  set -vx
bad=0
ret_val=""
if [ $# -lt 3 ];then
  echo "ERROR ABORTING parms:-->${*}<--"
  exit 8
fi
t1=${1}
t2=${2}
t3=${3}
t4=${4:- }

if [ ${t3} -eq 0 ];then
  t3=${#t2}          ## use length of variable with no padding if width is zero.  JPT 20031011 
fi
case ${t1} in
  i)  echo "${t2}" | grep "[^0-9]" > /dev/null 2>&1
      if [ $? -eq 0 ];then
        bad=1
        t0=FORMAT_INPUT_ERROR
        ret_val=FORMAT_INPUT_ERROR
      else
        jnk=`echo "DEBUG t1=$t1 t2=$t2 t3=$t3 "`
        ret_val=${t2}
        typeset -Z${t3} t0
        t0=${t2}
      fi ;;
  L)  tmp=`echo ${t2} | tr "a-z" "A-Z"`
      t2=${tmp}
      if [ ${#t2} -ge ${t3} ];then
        t0=`echo ${t2} | cut -c1-${t3}`
      else
        while [ ${#t2} -lt ${t3} ]
        do
          t2="${t4}${t2}"
        done
        t0="${t2}"
      fi ;;
  l)  if [ ${#t2} -ge ${t3} ];then
        t0=`echo ${t2} | cut -c1-${t3}`
      else
        while [ ${#t2} -lt ${t3} ]
        do
          t2="${t4}${t2}"
        done
        t0="${t2}"
      fi ;;
  R)  tmp=`echo ${t2} | tr "a-z" "A-Z"`
      t2=${tmp}
      if [ ${#t2} -ge ${t3} ];then
        t0=`echo ${t2} | cut -c1-${t3}`
      else
        while [ ${#t2} -lt ${t3} ]
        do
          t2="${t2}${t4}"
        done
        t0="${t2}"
      fi ;;
  r)  if [ ${#t2} -ge ${t3} ];then
        t0=`echo ${t2} | cut -c1-${t3}`
      else
        while [ ${#t2} -lt ${t3} ]
        do
          t2="${t2}${t4}"
        done
        t0="${t2}"
      fi ;;
  *)  :;;
esac

# echo "DEBUG RETURN-VALUE=--->${t0}<---"
ret_val="${t0}"
echo "${ret_val}"
####  set -

}  ####  END FUNCTION format_input

####----------------------------------------------------------------------------
####
####  This function
####      INTERACTIVE
####
####

view_batch_window_data ()
{
  check_batch_window
  if [ -a ${BATCH_SYSTEM}/client_config/batch_window_data.dat ]; then
    response=`grep "^#SET FPA_BATCH_WINDOW" ${BATCH_SYSTEM}/client_config/batch_window_data.dat`
    if [ ${#response} -gt 0 ]; then
      msg1="The Client Configuration is: "
      echo "${msg1} \n${response}" 
    fi
  fi
  response=`env | grep FPA_BATCH_WINDOW | sort`
  if [ ${#response} -gt 0 ]; then
    msg2="\n\nThe Current Settings are:  "
  echo "${msg2} \n${response}" 
  fi
}  ####  END FUNCTION view_batch_window_data


####----------------------------------------------------------------------------
####
####  This function
####      INTERACTIVE 
#### 
####

set_batch_window_days ()
{
####set -vx
  new_days=`echo ${@:-UNDEFINED} |sed 's/ //g' |tr '[a-z]' '[A-Z]'`
  valid_days=",SUN,MON,TUE,WED,THU,FRI,SAT,"
  set -A tmp_days `echo ${new_days} |sed 's/,/ /g'`
  iloop=0
  unset bad_day
  while [ ${iloop} -lt ${#tmp_days[*]} ]
  do
    tmp=`echo ${valid_days} | grep ",${tmp_days[${iloop}]}," `
    if [ ${#tmp} -eq 0 ]; then    ## INVALID ENTRY
      bad_day="${bad_day:-}${bad_day:+ and }${tmp_days[${iloop}]}"
    fi
    iloop=`expr ${iloop} + 1`
  done
  if [ ${#bad_day} -gt 0 ]; then
    echo "ERROR: Invalid entry: ${bad_day}  "
  else
    if [ -a ${BATCH_SYSTEM}/client_config/batch_window_data.dat ]; then
      grep -v "^#SET FPA_BATCH_WINDOW_DAYS " ${BATCH_SYSTEM}/client_config/batch_window_data.dat > ${BATCH_SYSTEM}/client_config/batch_window_data.dat.$$  
    else
      echo "##
## This file contains the information over-riding the default values which 
## define the time allotted for 'running batch jobs'.  
## Note that these variables are used to define FPA_SEARCH_PATH so the 
## FPA will still run processes and jobs that are triggered by files in the FPA_SEARCH_PATH
## SCHEDULED JOBS ARE NOT AFFECTED BY THESE SETTINGS!  
## Three variables may be defined in this file using the following syntax 
##   Each line not beginning with '#SET ' will be ignored
##   The next words on the line must be one of the following:
##                       FPA_BATCH_WINDOW_START hhmm
##                       FPA_BATCH_WINDOW_STOP  hhmm
##                       FPA_BATCH_WINDOW_DAYS  day,day,day
##   where hhmm is the hour and minute based on a 24 hour clock in the FPA's timezone (1900 is 7:00 pm)
##   and day,day,day refers to a comma separated list of 3-character days (SUN,MON,TUE,WED,THU,FRI,SAT) 
## If there are multiple entries for a single variable the last entry will be used. 
## if there are non-numeric characters in the hhmm fields the value will be ignored. 
##  " > ${BATCH_SYSTEM}/client_config/batch_window_data.dat.$$

    fi
    echo "#SET FPA_BATCH_WINDOW_DAYS ${new_days}" >> ${BATCH_SYSTEM}/client_config/batch_window_data.dat.$$
    cp ${BATCH_SYSTEM}/client_config/batch_window_data.dat.$$ ${BATCH_SYSTEM}/client_config/batch_window_data.dat
    mv ${BATCH_SYSTEM}/client_config/batch_window_data.dat.$$ ${BATCH_ARCHIVE}/batch_window_data.dat.ID`get_run_seq OUTPUT_ID.SEQ`
  fi
####set -
}  ####  END FUNCTION set_batch_window_days

####----------------------------------------------------------------------------
####
####  This function
####      INTERACTIVE 
#### 
####

set_batch_window_stop ()
{
####set -vx
  new_stop=`format_input l ${1:-UNDEFINED} 4 0`
  unset tmp
  tmp=`echo ${new_stop} |sed 's/[0-9]//g'`
  if [ ${#tmp} -ne 0 ]; then
    echo "ERROR: must provide a stop time in hhmm format based on a 24 hour clock. " 
  else
    new_stop=`format_input l ${1} 4 0`
    if [ -a ${BATCH_SYSTEM}/client_config/batch_window_data.dat ]; then
      grep -v "^#SET FPA_BATCH_WINDOW_STOP " ${BATCH_SYSTEM}/client_config/batch_window_data.dat > ${BATCH_SYSTEM}/client_config/batch_window_data.dat.$$  
    else
      echo "##
## This file contains the information over-riding the default values which 
## define the time allotted for 'running batch jobs'.  
## Note that these variables are used to define FPA_SEARCH_PATH so the 
## FPA will still run processes and jobs that are triggered by files in the FPA_SEARCH_PATH
## SCHEDULED JOBS ARE NOT AFFECTED BY THESE SETTINGS!  
## Three variables may be defined in this file using the following syntax 
##   Each line not beginning with '#SET ' will be ignored
##   The next words on the line must be one of the following:
##                       FPA_BATCH_WINDOW_START hhmm
##                       FPA_BATCH_WINDOW_STOP  hhmm
##                       FPA_BATCH_WINDOW_DAYS  day,day,day
##   where hhmm is the hour and minute based on a 24 hour clock in the FPA's timezone (1900 is 7:00 pm)
##   and day,day,day refers to a comma separated list of 3-character days (SUN,MON,TUE,WED,THU,FRI,SAT) 
## If there are multiple entries for a single variable the last entry will be used. 
## if there are non-numeric characters in the hhmm fields the value will be ignored. 
##  " > ${BATCH_SYSTEM}/client_config/batch_window_data.dat.$$

    fi
    echo "#SET FPA_BATCH_WINDOW_STOP ${new_stop}" >> ${BATCH_SYSTEM}/client_config/batch_window_data.dat.$$
    cp ${BATCH_SYSTEM}/client_config/batch_window_data.dat.$$ ${BATCH_SYSTEM}/client_config/batch_window_data.dat
    mv ${BATCH_SYSTEM}/client_config/batch_window_data.dat.$$ ${BATCH_ARCHIVE}/batch_window_data.dat.ID`get_run_seq OUTPUT_ID.SEQ`
  fi
####set -
}  ####  END FUNCTION set_batch_window_stop


####----------------------------------------------------------------------------
####
####  This function
####      INTERACTIVE 
#### 
####

set_batch_window_start ()
{
####set -vx
  new_start=`format_input l ${1:-UNDEFINED} 4 0`
  unset tmp
  tmp=`echo ${new_start} |sed 's/[0-9]//g'`
  if [ ${#tmp} -ne 0 ]; then
    echo "ERROR: must provide a start time in hhmm format based on a 24 hour clock. " 
  else
    new_start=`format_input l ${1} 4 0`
    if [ -a ${BATCH_SYSTEM}/client_config/batch_window_data.dat ]; then
      grep -v "^#SET FPA_BATCH_WINDOW_START " ${BATCH_SYSTEM}/client_config/batch_window_data.dat > ${BATCH_SYSTEM}/client_config/batch_window_data.dat.$$  
    else
      echo "##
## This file contains the information over-riding the default values which 
## define the time allotted for 'running batch jobs'.  
## Note that these variables are used to define FPA_SEARCH_PATH so the 
## FPA will still run processes and jobs that are triggered by files in the FPA_SEARCH_PATH
## SCHEDULED JOBS ARE NOT AFFECTED BY THESE SETTINGS!  
## Three variables may be defined in this file using the following syntax 
##   Each line not beginning with '#SET ' will be ignored
##   The next words on the line must be one of the following:
##                       FPA_BATCH_WINDOW_START hhmm
##                       FPA_BATCH_WINDOW_STOP  hhmm
##                       FPA_BATCH_WINDOW_DAYS  day,day,day
##   where hhmm is the hour and minute based on a 24 hour clock in the FPA's timezone (1900 is 7:00 pm)
##   and day,day,day refers to a comma separated list of 3-character days (SUN,MON,TUE,WED,THU,FRI,SAT) 
## If there are multiple entries for a single variable the last entry will be used. 
## if there are non-numeric characters in the hhmm fields the value will be ignored. 
##  " > ${BATCH_SYSTEM}/client_config/batch_window_data.dat.$$

    fi
    echo "#SET FPA_BATCH_WINDOW_START ${new_start}" >> ${BATCH_SYSTEM}/client_config/batch_window_data.dat.$$
    cp ${BATCH_SYSTEM}/client_config/batch_window_data.dat.$$ ${BATCH_SYSTEM}/client_config/batch_window_data.dat
    mv ${BATCH_SYSTEM}/client_config/batch_window_data.dat.$$ ${BATCH_ARCHIVE}/batch_window_data.dat.ID`get_run_seq OUTPUT_ID.SEQ`
  fi
####set -
}  ####  END FUNCTION set_batch_window_start


####----------------------------------------------------------------------------
####
####  This function 
####  
####  
####

check_batch_window ()
{
####set -vx
  default_batch_window_start=1900
  default_batch_window_stop=0700
  default_batch_window_days="SAT,SUN"
  if [ -a ${BATCH_SYSTEM}/client_config/batch_window_data.dat ]; then
####  read the client's defined values if they exist.  These values will override the default values specified in the .FPAprofile. 
    cat  ${BATCH_SYSTEM}/client_config/batch_window_data.dat |
    while read w1 w2 w3 
    do
      if [ "${w1}" = "#SET" ]; then 
        case "${w2}" in 
          FPA_BATCH_WINDOW_START) export FPA_BATCH_WINDOW_START=${w3:-${default_batch_window_start}} ;;
          FPA_BATCH_WINDOW_STOP)  export FPA_BATCH_WINDOW_STOP=${w3:-${default_batch_window_stop}} ;;
          FPA_BATCH_WINDOW_DAYS)  export FPA_BATCH_WINDOW_DAYS=${w3:-${default_batch_window_days}} ;;
          *) : ;;
        esac
      fi
    done
  fi
  my_batch_window_start=`format_input l ${FPA_BATCH_WINDOW_START:-${default_batch_window_start}} 4 0`
  my_batch_window_stop=`format_input l ${FPA_BATCH_WINDOW_STOP:-${default_batch_window_stop}} 4 0`
  my_batch_window_days=",`echo ${FPA_BATCH_WINDOW_DAYS:-${default_batch_window_days}} |sed 's/ //g' |tr [a-z] [A-Z]`,"
  unset tmp
  tmp=`echo ${my_batch_window_start} |sed 's/[0-9]//g'`
  if [ ${#tmp} -ne 0 ]; then
    my_batch_window_start=${default_batch_window_start}
  fi
  unset tmp
  tmp=`echo ${my_batch_window_stop} |sed 's/[0-9]//g'`
  if [ ${#tmp} -ne 0 ]; then
    my_batch_window_stop=${default_batch_window_stop}
  fi
  now=`date +'%H%M'`
  dow=`date +'%a'|tr [a-z] [A-Z]`
  ## dow_allowed=",`echo ${my_batch_window_days}|tr [a-z] [A-Z]`,"
  echo "${my_batch_window_days}" | grep ",${dow}," > /dev/null 2>&1    
  grep_stat=$?
  if [ ${grep_stat} -eq 0 ]; then
    export FPA_BATCH_WINDOW=TRUE
    #### echo "IF"
  ###elif [[ "A${now}Z" > "A${my_batch_window_stop}Z" && "A${my_batch_window_start}Z" > "A${now}Z" ]]; then  
  elif [[ ${now} -gt ${my_batch_window_stop} && ${now} -lt ${my_batch_window_start} ]]; then  
    export FPA_BATCH_WINDOW=FALSE
    #### echo "ELIF"
  else
    export FPA_BATCH_WINDOW=TRUE
    #### echo "ELSE"
  fi

####set -

}  ####  END FUNCTION check_batch_window

####----------------------------------------------------------------------------
####
####  This function generates (overwrites) the ${BATCH_ETC}/BATCH_envname.dat 
####  file which is used by the collapse_dirname function.  
####  
####

mk_envname_list ()
{
  outputfilename=${BATCH_ETC}/BATCH_envname.dat
  typeset -Z6 my_output
  env | grep BATCH |
  while read line
  do
    envvarname=${line%=*}
    envdef=${line#*=}
    length_envdef=${#envdef}
    my_output=${length_envdef}
    echo "${my_output} ${envdef} = ${envvarname} "
  done  | sort -run > ${outputfilename}

}  ####  END FUNCTION mk_envname_list


####----------------------------------------------------------------------------
####
####  This function replaces the directory path specified in P1 with a BATCH* 
####  environment variable if an appropriate environment variable exists.  
####  The order of attempted substitutions is by decreasing length of the 
####  path associated with the environment variable -- ie the longest path 
####  substitutions are attempted first. 
####  
####

collapse_dirname ()
{
  orig_dirname=${1:-0} 
  my_dirname=${orig_dirname}
  if [ -r ${BATCH_ETC}/BATCH_envname.dat ];then
    ##  collapsed=FALSE     ##  Uncomment if we only want to use the first translation instead of multiple translations... 
    cat ${BATCH_ETC}/BATCH_envname.dat |
    while read dirlen dirname delim envname
    do
      # if [ ${collapsed} = "FALSE" ];then    ##  Uncomment if we only want to use the first translation instead of multiple translations... 
        ##  echo ${orig_dirname} | eval sed `echo "'s:${dirname}:${envname}:'"`
        cmd_string="sed 's:${dirname}:/${envname}:'"
        c_dir=`echo ${my_dirname} | eval ${cmd_string} `
        my_dirname=${c_dir}
        # echo ${orig_dirname} | grep ${dirname} >/dev/null 2>&1
      # fi    ##  Uncomment if we only want to use the first translation instead of multiple translations... 
    done
  fi
  echo "${my_dirname}"

}  ####  END FUNCTION collapse_dirname


####----------------------------------------------------------------------------
####
####  This function requires two integer parameters (indicating seconds) and 
####  returns a string in the format h:mm:ss indicating the number of hours 
####  minutes and seconds between the two parameters.    
####  
####

elapsed_time ()
{
  my_start_sec=${1:-0} 
  my_stop_sec=${2:-0} 
  ##  s_day=86400  # seconds in a day   ## Report time in hours:minutes:seconds, no days. 
  s_hour=3600  # seconds in an hour
  s_min=60     # seconds in a minute
  let "my_time_sec = my_stop_sec - my_start_sec" 2>/dev/null  ##  Assign variable and confirm that values are integers
  my_status=$?
  if [ my_status -ne 0 ]; then
    elapsed_time_string="Unknown"
  elif [ \( my_start_sec -le 0 \) -o \( my_stop_sec -le my_start_sec \) ]; then
    elapsed_time_string="Invalid"
  else
    ##  let "elapsed_days = my_time_sec / s_day"
    ##  if [ $elapsed_days -gt 0 ]; then let "my_time_sec = my_time_sec - (elapsed_days * s_day)"; fi
    let "elapsed_hours = my_time_sec / s_hour"
    if [ $elapsed_hours -gt 0 ]; then let "my_time_sec = my_time_sec - (elapsed_hours * s_hour)"; fi
    let "elapsed_min = my_time_sec / s_min"
    if [ $elapsed_min -gt 0 ]; then let "my_time_sec = my_time_sec - (elapsed_min * s_min)"; fi
    elapsed_sec=${my_time_sec}

    elapsed_time_string="${elapsed_hours}:`format_input i ${elapsed_min} 2`:`format_input i ${elapsed_sec} 2`"
  fi 2>/dev/null
  
  echo "${elapsed_time_string}"

}  ####  END FUNCTION elapsed_time

####----------------------------------------------------------------------------
####
####  This function returns yesterday's date in format %Y%m%d unless mdY or 
####  dmY is specified as a parameter. 
####

Yesterday_Date ()
{
  dFormat=${1:-Ymd}
  base_TZ=${TZ}
  tmp_TZ_num=`echo ${base_TZ} | cut -c4`
  let tmp_TZ_num=${tmp_TZ_num}+24
  TZ="TMP${tmp_TZ_num}tmp"
  case ${dFormat} in 
    Ymd) t_YMD=`date  +"%Y%m%d"`;;
    mdY) t_YMD=`date  +"%m%d%Y"`;;
    dmY) t_YMD=`date  +"%d%m%Y"`;;
    *)   t_YMD="BADformt" ;;
  esac
  TZ=${base_TZ}
  
  echo "${t_YMD}"

}  ####  END FUNCTION Yesterday_Date

####----------------------------------------------------------------------------
####
####  This function returns tomorrow's date in format %Y%m%d   
####  Parameter 1 optionally provides the number of days in the future, 1=tomorrow
####  Parameter 2 optionally provides the date in %Y%m%d format from which to 
####  calculate 'tomorrow'
####  Requires the GNU date function
####  

Tomorrow_Date ()
{
  if [ "${2:-X}" = "X" ]; then   # Use current date as base if no date is provided
    number="'${1:-1} day'"
    eval date --date=${number} +"%Y%m%d"
  else
    number="'${2} ${1:-1} day'"
    eval date --date=${number} +"%Y%m%d"
  fi

}  ####  END FUNCTION Tomorrow_Date

####----------------------------------------------------------------------------
####
####  This function moves an ftp_q_card from the pending directory to the 
####  ${BATCH_FTP_QUEUE}/ready directory.  It issues a warning message if the 
####  q_card does not exist -- so that re-sends will generate warning msgs 
####  rather than error msgs.  
####  NOTE: to match on a wildcard, the filename ($3) must contain the string "---"
####  Errors if there are multiple matches ?
####

ftp_mkready ()
{
  next_dest=${1:-NONE}
  next_runid=${2:-r}
  next_file=`echo "${3:-NONE}" | sed 's/\-\-\-/\*/g'`   ##  allow wildcards. replace "---" with "*" in the filename.
  if [ "${next_runid}" = "r" ];then
    next_runid='r*'
  fi
  next_tmp="${next_dest}.${next_runid}.q*.${next_file}"
  num_pending=`ls -l ${BATCH_FTP_QUEUE}/pending/${next_tmp} |wc -l`
  if [ ${num_pending} -lt 1 ]; then
    msg="Warning: Cannot find ftp_q_card ${next_tmp} "
    messagelog_notify "${msg}" 
  elif [ ${num_pending} -gt 1 ]; then 
    msg="Warning: Found ${num_pending} ftp_q_cards matching ${next_tmp} "
    messagelog_notify "${msg}" 
  elif [ ${num_pending} -eq 1 ]; then
    next_q_card="${next_dest}.${next_runid}.q*.${next_file}*"
    msg="Moving ${BATCH_FTP_QUEUE}/pending/${next_q_card} ${BATCH_FTP_QUEUE}/ready "
    messagelog "${msg}"    ##  JPT 20040701 Just log it, no Longer sending email notification. 
    mv ${BATCH_FTP_QUEUE}/pending/${next_q_card} ${BATCH_FTP_QUEUE}/ready
    if [ $? -ne 0 ]; then
      msg="ERROR: Problem in ftp_mkready moving ${next_q_card} from pending to ${BATCH_FTP_QUEUE}/ready "
      messagelog_notify "${msg}" 
    fi
  else
    msg="Warning: Problem in ftp_mkready ${num_pending} ftp_q_cards matching ${next_q_card} "
    messagelog_notify "${msg}" 
  fi
  
}  ####  END FUNCTION ftp_mkready

####----------------------------------------------------------------------------
####
####  This function ensures that this script is only running once on the
####  system.
####

If_Currently_Running ()
{
  ThisPID=$$
  ps -ef | grep "${batch_prg} ${1-}" | grep -v ' grep ' | grep -v ' vi ' | \
  grep -v ' view ' | grep -v ' more ' | grep -v ' less ' | \
  grep -v ' tail ' | grep -v " ${ThisPID} " | \
  grep -v '^.\{15,\} \{4,\}1 ' |\
  grep -v "sh -c" >> /dev/null 2>&1
  ret_val=$?
  if [ $ret_val -eq 0 ]; then
    return 0
  else
    return 1
  fi

}  ####  END FUNCTION If_Currently_Running

####----------------------------------------------------------------------------
####
####  The function check_ftp_permissions uses the full directory name of the files 
####  as it's one required parameter.  This function returns 0 if it is 
####  permissible to send the file, and non-zero if the file cannot be sent.  
####  Additional logic for checking permissions can be added here.  
####  RETURN VALUES:
####      0 = file is ready to send (file is readable and approved to send)
####      1 = General usage error 
####      2 = MAY NOT SEND THIS FILE 
####      3 = souce directory does not exist
####      4 = cannot access souce directory 
####      5 = file does not exist
####      6 = file is not readable
####      9 = unable to determine
####  
####  check_ftp_permissions /full/path/file.name
####  
check_ftp_permissions()
{
  unset tmp_ret tmp_dir
  tmp_ret=9
  msg="check_ftp_permissions: unable to determine"
  tmp_filename="${1:-UNDEFINED}"
  tmp_path=`dirname ${tmp_filename}`
  tmp_dir=`pwd`
  cd ${tmp_path} 2>/dev/null
  cd_ret=${?}
  if [ "${cd_ret}" = "0" ];then tmp_path=`pwd`; fi
  cd ${tmp_dir}
  in_ftp_dirs=`echo ${tmp_path} | grep ${BATCH_FTP} | wc -l`

  if [ "${tmp_filename}" = "UNDEFINED" ]; then
    tmp_ret="1"
    msg="check_ftp_permissions: General usage error"
  elif [ ! -d ${tmp_path} ]; then
    tmp_ret="3"
    msg="check_ftp_permissions: souce directory does not exist"  
  elif [ "${cd_ret}" != "0" ]; then
    tmp_ret="4"
    msg="check_ftp_permissions: cannot access souce directory" 
  elif [ ${in_ftp_dirs} -ne 1 ]; then  # JPT 20050128 changed syntax
    tmp_ret=2
    msg="check_ftp_permissions: MAY NOT SEND THIS FILE" 
  elif [ ! -a ${tmp_filename} ]; then
    tmp_ret="5"
    msg="check_ftp_permissions, file does not exist" 
  elif [ ! -r ${tmp_filename} ]; then
    tmp_ret="6"
    msg="check_ftp_permissions: file is not readable" 
  else
    tmp_ret="0"
    msg="check_ftp_permissions: file is ready to send"
  fi

  echo "${tmp_ret} ${msg}"
  return ${tmp_ret}
}  ####  END FUNCTION check_ftp_permissions

####----------------------------------------------------------------------------
####
####  The function set_oracle_sid scans a configuration file for oracle databases
####  and defines ORACLE_SID to be $1 if the requested database is allowed.  
####  NOTE:  this function is designed to be used in the menu.ksh program and 
####  provides success and error feedback through standard output.  
####

set_oracle_sid() 
{
myline=`grep -i "^#allowed_db ${1:-UNDEFINED}" ${BATCH_ETC}/.oracle.batch.profile `
if [ ${?} -ne 0 ];then
  echo "\nERROR -- Unable to access database ${1:-UNDEFINED} "
  #### batcherror_notify "ERROR  Unable to access database ${1:-UNDEFINED} "
else
  my_sid=`grep -i "^#allowed_db ${1:-UNDEFINED}" ${BATCH_ETC}/.oracle.batch.profile | head -1 |awk -F" " '{print $2}'`
  export ORAENV_ASK=NO  
  export ORACLE_SID=${my_sid}
  . oraenv
  echo "\nSuccessfully directed this menu session to run in database ${1:-UNDEFINED} "
fi

}  ####  END FUNCTION set_oracle_sid

####----------------------------------------------------------------------------
####
####  The function get_name_from_semaphore extracts the orignal filename that 
####  satisfied one of the semaphore conditions.  it must be provided the 
####  following parameters:
####    1:  name of the completed semaphore file. 
####    2:  A fragment of the desired filename to uniquely identify the specific filename.  
####    3:  name of the completed semaphore file. 
####    4:  name of the completed semaphore file. 
####  NOTE:  this function returns the desired filename or a null string, the 
####  calling program must check for the null string error condition.
####

get_name_from_semaphore() {
my_semaphore_file=${1:-/dev/null}
my_partial_name=${2:-DoNotMatchAnyFile}
tmp=`grep "^#MATCHED " ${my_semaphore_file} | grep ${my_partial_name} | tail -1 | sed "s/  *//g"`
if [ ${#tmp} -eq 0 ]; then
  echo ""
else
  echo $tmp | cut -d"|" -f3 |  sed "s/  *//g"
fi

}  ####  END FUNCTION get_name_from_semaphore

####----------------------------------------------------------------------------
####
####  The function get_ftp_info scans a configuration file for the specified 
####  ftp destination.  If no information can be found, the process aborts 
####  with error_notify.
####      
####

get_ftp_info() {

myline=`grep -i "^#allowed_ftp ${1:-UNDEFINED}" ${BATCH_ETC}/.ftp.batch.profile `
if [ ${?} -ne 0 ];then
  batcherror_notify "ERROR  Unable to access ftp information for ${1:-UNDEFINED} "
fi
ftp_userpass=`grep -i "^#allowed_db ${1:-UNDEFINED}" ${BATCH_ETC}/.ftp.batch.profile | head -1 |awk -F" " '{print $3}'`
#### export USER_PASS=${my_userpass}
echo ${ftp_userpass}
}  ####  END FUNCTION get_ftp_info

####----------------------------------------------------------------------------
####
####  The function get_user_pass scans a configuration file for the oracle 
####  database specified in ORACLE_SID and defines USER_PASS .  If a USER_PASS
####  cannot be found, the process aborts with error_notify.
####      
####

get_user_pass() {

myline=`grep -i "^#allowed_db ${ORACLE_SID:-UNDEFINED}" ${BATCH_ETC}/.oracle.batch.profile `
if [ ${?} -ne 0 ];then
  batcherror_notify "ERROR  Unable to access database ${ORACLE_SID:-UNDEFINED} "
fi
my_userpass=`grep -i "^#allowed_db ${ORACLE_SID:-UNDEFINED}" ${BATCH_ETC}/.oracle.batch.profile | head -1 |awk -F" " '{print $3}'`
export USER_PASS=${my_userpass}
}  ####  END FUNCTION get_user_pass

####----------------------------------------------------------------------------
####
####  The function Call_Java starts a java program from a korn shell 
####  script without the normal job startup overhead like creating a 
####  new log file, creating a batch_working_directory, etc. 
####  To manage errors properly, this function creates a temporary log 
####  file after validating the syntax of the call.  This file is 
####  named cj.cj_java_exe.cj_run_id and is initially written in the 
####  batch_working_directory.  upon completion of the java process, 
####  this file is examined for errors and then cat'd into the 
####  $batch_log of the program that is running this Call_Java function.  
####  Note that if hte java executable dies or is killed ...
####

Call_Java() {
cj_usage="Usage: Call_Java cj_java_exe cj_java_path END_PATH [ java parameters ]"
cj_num_args=${#}
cj_java_parameters=""
set -A cj_parameters `echo ${*} | sed s:batch_working_directory:${batch_working_directory}:g`

####  
####  Read name of java executable.  
####  
if [ ${cj_num_args} -gt 0 ]; then
  cj_java_exe=${1%%/*}
else
  msg="ERROR -- cj_java_exe value required.  ${cj_usage}"
  batcherror_notify "${msg}"   #### This exits from the entire program not just this Call_Java function. 
fi

####  
####  Build java path list.   
####  
invalid_java_path=TRUE     ## Clear this error flag if a path is successfully built. 
if [ ${cj_num_args} -gt 1 ]; then
  cj_java_path="${2}"
else
  msg="ERROR -- cj_java_path value required.  ${usage}"
  batcherror_notify "${msg}"   #### This exits from the entire program not just this Call_Java function.
fi
cj_this_parameter=2
if [ ${cj_num_args} -gt 2 ]; then
  cj_continue=TRUE
else
  cj_continue=FALSE
fi
while [ "${cj_continue}" = "TRUE" ]
do
  if [ "${cj_parameters[${cj_this_parameter}]}" = "END_PATH" ]; then
    invalid_java_path=FALSE     ## Clear this error flag now that END_PATH has been found. 
    cj_continue=FALSE
  else
    cj_java_path="${cj_java_path:-}:${cj_parameters[${cj_this_parameter}]}"
  fi
  cj_this_parameter=`expr ${cj_this_parameter} + 1`
  if [ ${cj_this_parameter} -ge ${cj_num_args} ];then
    cj_continue=FALSE
  fi
done
if [ "${invalid_java_path}" = "TRUE" ];then
  msg="ERROR - Invalid java path: No END_PATH specified. "
  messagelog "${msg}"
  return 9
fi

####  
####  Build list of parameters to pass to the java executable.  
####  
while [ ${cj_this_parameter} -lt ${cj_num_args} ]
do
  cj_java_parameters="${cj_java_parameters:-}${cj_parameters[${cj_this_parameter}]} "
  cj_this_parameter=`expr ${cj_this_parameter} + 1`
done

####  
####  Create the temporary cj_logfile. 
####  
cj_logfile="cj.${cj_java_exe}.`get_run_seq seq.Call_Java_function.seq`"

my_prog_name=${batch_prg:-${0}}
if [ "${my_prog_name}" = "-ksh" ];then
  my_prog_name=INTERACTIVE_`whoami`
fi
msg="NOTICE:  ${my_prog_name##*/} is calling Call_Java:  cj_java_exe:${cj_java_exe} cj_java_path:${cj_java_path} cj_java_parameters:${cj_java_parameters} OUTPUT:${batch_working_directory}  TEMP_LOG:${cj_logfile} "
messagelog "${msg}"

####
####  Starting java procedure.  Need to capture standard output to
####  ${cj_logfile} so that error handling can be performed.
####
java -Xms64m -Xmx128m -cp ${cj_java_path} ${cj_java_exe} ${cj_java_parameters} 1>>${batch_working_directory}/${cj_logfile} 2>&1

####
####  Capture return status of java for later evaluation.
####
cj_java_return_code=$?

####
####  Check temporary log file for erros messages, append it to primary log file, and move it out of bwd. 
####
Check_Log ${batch_working_directory}/${cj_logfile}
check_log_status=$?
if [ -r ${batch_working_directory}/${cj_logfile} ];then 
  sed 's/^/##> cj_logfile <##| /' ${batch_working_directory}/${cj_logfile} >> ${batch_log}
  ####  cat ${batch_working_directory}/${cj_logfile} >> ${batch_log}
  mv ${batch_working_directory}/${cj_logfile} ${BATCH_TMP}
else 
  msg="ERROR -- cannot read cj_logfile ${batch_working_directory}/${cj_logfile}"
  messagelog "${msg}"
fi

}  ####  END FUNCTION Call_Java


####----------------------------------------------------------------------------
####
####  The function Call_Sql starts a sql script from a korn shell 
####  script without the FPA job startup overhead like creating a 
####  new log file, creating a batch_working_directory, etc. 
####  It is intended for cases where it is convenient to write a korn shell 
####  script to sequentially run many sql scripts.  
####  To manage errors properly, this function creates a temporary log 
####  file after validating the syntax of the call.  This file is 
####  named cs.[cs_exe].[cs_run_id] and is initially written in the 
####  batch_working_directory.  Upon completion of the process, 
####  this file is examined for errors and then cat'd into the 
####  $batch_log of the program that is running this Call_Sql function.  
####  Note that if the sql script dies or is killed ...
####

Call_Sql() {
cs_usage="Usage: Call_Sql sql_script.sql  [ ORACLE_SID [ sql parameters ] ]"
cs_num_args=${#}
cs_parameters=""
set -A parameters `echo ${*} | sed s:batch_working_directory:${batch_working_directory}:g`

####  
####  Read name of executable.  
####  
if [ ${cs_num_args} -gt 0 ]; then
  cs_exe=${1%%/*}
else
  msg="ERROR -- cs_exe value required.  ${cs_usage}"
  batcherror_notify "${msg}"   #### This exits from the entire program not just this Call_Sql function. 
fi

####  
####  Get ORACLE_SID if specified. 
####  
if [ ${cs_num_args} -gt 1 ]; then
  if [ "${2}" != "DEFAULT" ];then
    ORACLE_SID="${2}"
  fi
fi

####
####  Get the oracle batch login information for this database.
####
get_user_pass

this_parameter=2
while [ ${this_parameter} -lt ${cs_num_args} ]
do
  cs_parameters="${cs_parameters:-}${parameters[${this_parameter}]} "
  this_parameter=`expr ${this_parameter} + 1`
done

####  
####  Create the temporary cs_logfile. 
####  
cs_logfile="cs.${cs_exe}.`get_run_seq seq.Call_Sql.seq`"

cd ${batch_working_directory}
cs_parameters=`echo ${cs_parameters} | sed s:\'NULL\':NULL:g`     ## The quoted string 'NULL' is replaced with NULL which oracle treats as a NULL character.
messagelog "cs_exe:${cs_exe} ORACLE_USER:${USER_PASS%%/*} ORACLE_SID:${ORACLE_SID}  OUTPUT:${PWD}"

my_prog_name=${batch_prg:-${0}}
if [ "${my_prog_name}" = "-ksh" ];then
  my_prog_name=INTERACTIVE_`whoami`
fi
msg="NOTICE:  ${my_prog_name##*/} environment ORACLE_USER:${USER_PASS%%/*} ORACLE_SID:${ORACLE_SID} OUTPUT:${batch_working_directory} TEMP_LOG:${cs_logfile} "
messagelog "${msg}"
cs_usage="Usage: Call_Sql sql_package.stored_procedure  [ ORACLE_SID [ sql parameters ] ]"
msg="CALLING Call_Sql ${cs_exe} ${cs_parameters} "
messagelog "${msg}"

####
####  Starting pl/sql procedure.  Need to capture standard output to
####  ${cs_logfile} so that error handling can be performed.
####  
sqlplus /nolog <<-ENDSQL 1>>${cs_logfile} 2>&1
    connect ${USER_PASS}@${ORACLE_SID};
    whenever sqlerror exit failure
    set echo off
    -- set serveroutput on size 200000;
    @${BATCH_SQLBIN}/${cs_exe} ${cs_parameters}
    show err;
    exit;
ENDSQL

####
####  Capture return status of sqlplus for later evaluation.
####
cs_return_code=$?

####
####  Check temporary log file for error messages, append it to primary log file, and move it out of bwd. 
####
Check_Log ${batch_working_directory}/${cs_logfile}
check_log_status=$?
if [ -r ${batch_working_directory}/${cs_logfile} ];then 
  sed 's/^/##> cs_logfile <##| /' ${batch_working_directory}/${cs_logfile} >> ${batch_log}
  ####  cat ${batch_working_directory}/${cs_logfile} >> ${batch_log}
  mv ${batch_working_directory}/${cs_logfile} ${BATCH_TMP}
else 
  msg="ERROR -- cannot read cs_logfile ${batch_working_directory}/${cs_logfile}"
  messagelog "${msg}"
fi

}  ####  END FUNCTION Call_Sql 

####----------------------------------------------------------------------------
####
####  The function Call_Sql_Stored starts a package or stored procedure from a korn shell 
####  script without the job startup overhead like creating a 
####  new log file, creating a batch_working_directory, etc. 
####  It is intended for cases where it is easier to write a korn shell 
####  script to sequentially run many stored procedures than to write a 
####  stored procedure to do this.  
####  To manage errors properly, this function creates a temporary log 
####  file after validating the syntax of the call.  This file is 
####  named css.[css_exe].[css_run_id] and is initially written in the 
####  batch_working_directory.  Upon completion of the process, 
####  this file is examined for errors and then cat'd into the 
####  $batch_log of the program that is running this Call_Sql_Stored function.  
####  Note that if the stored procedure dies or is killed ...
####

Call_Sql_Stored() {
css_usage="Usage: Call_Sql_Stored sql_package.stored_procedure  [ ORACLE_SID [ sql parameters ] ]"
css_num_args=${#}
css_parameters=""
set -A parameters `echo ${*} | sed s:batch_working_directory:${batch_working_directory}:g`

####  
####  Read name of executable.  
####  
if [ ${css_num_args} -gt 0 ]; then
  css_exe=${1%%/*}
else
  msg="ERROR -- css_exe value required.  ${css_usage}"
  batcherror_notify "${msg}"   #### This exits from the entire program not just this Call_Sql_Stored function. 
fi

####  
####  Get ORACLE_SID if specified. 
####  
if [ ${css_num_args} -gt 1 ]; then
  if [ "${2}" != "DEFAULT" ];then
    ORACLE_SID="${2}"
  fi
fi

####
####  Get the oracle batch login information for this database.
####
get_user_pass

this_parameter=2
while [ ${this_parameter} -lt ${css_num_args} ]
do
  css_parameters="${css_parameters:+${css_parameters},}'${parameters[${this_parameter}]}'"
  this_parameter=`expr ${this_parameter} + 1`
done

####  
####  Create the temporary css_logfile. 
####  
css_logfile="css.${css_exe}.`get_run_seq seq.Call_Sql_Stored.seq`"

cd ${batch_working_directory}
css_parameters=`echo ${css_parameters} | sed s:\'NULL\':NULL:g`     ## The quoted string 'NULL' is replaced with NULL which oracle treats as a NULL character.
messagelog "css_exe:${css_exe} ORACLE_USER:${USER_PASS%%/*} ORACLE_SID:${ORACLE_SID}  OUTPUT:${PWD}"

my_prog_name=${batch_prg:-${0}}
if [ "${my_prog_name}" = "-ksh" ];then
  my_prog_name=INTERACTIVE_`whoami`
fi
msg="NOTICE:  ${my_prog_name##*/} environment ORACLE_USER:${USER_PASS%%/*} ORACLE_SID:${ORACLE_SID} OUTPUT:${batch_working_directory} TEMP_LOG:${css_logfile} "
messagelog "${msg}"
css_usage="Usage: Call_Sql_Stored sql_package.stored_procedure  [ ORACLE_SID [ sql parameters ] ]"
msg="CALLING Call_Sql_Stored ${css_exe}(${css_parameters})"
messagelog "${msg}"

####
####  Starting pl/sql procedure.  Need to capture standard output to
####  ${css_logfile} so that error handling can be performed.
####  
sqlplus /nolog <<-ENDSQL 1>>${css_logfile} 2>&1
    connect ${USER_PASS}@${ORACLE_SID};
    whenever sqlerror exit failure
    set echo off
    -- set serveroutput on size 200000;
    execute ${css_exe}(${css_parameters});
    exit;
ENDSQL

####
####  Capture return status of sqlplus for later evaluation.
####
css_return_code=$?

####
####  Check temporary log file for error messages, append it to primary log file, and move it out of bwd. 
####
Check_Log ${batch_working_directory}/${css_logfile}
check_log_status=$?
if [ -r ${batch_working_directory}/${css_logfile} ];then 
  sed 's/^/##> css_logfile <##| /' ${batch_working_directory}/${css_logfile} >> ${batch_log}
  ####  cat ${batch_working_directory}/${css_logfile} >> ${batch_log}
  mv ${batch_working_directory}/${css_logfile} ${BATCH_TMP}
else 
  msg="ERROR -- cannot read css_logfile ${batch_working_directory}/${css_logfile}"
  messagelog "${msg}"
fi

}  ####  END FUNCTION Call_Sql_Stored


####----------------------------------------------------------------------------
####
####  The function Check_Log scans the log file specified in parameter1 for error messages.  
####      
####

Check_Log() {
cl_errors=0
unset cl_err_msg  ## Be sure to start with cl_err_msg undefined. 
cl_num_args=${#}
set -A cl_parameters `echo ${*} | sed s:batch_working_directory:${batch_working_directory}:g`
if [ ${cl_num_args} -gt 0 ];then
  cl_logfilename=${1:-DoesNotExist}
else
  cl_logfilename=${batch_log:-DoesNotExist}
fi
if [ ! -r ${cl_logfilename} ];then
  msg="ERROR in Check_Log:  cannot read logfile ${cl_logfilename} "
  messagelog "${msg}"
  return 127     ##  Exit this function with error status if unable to read specified file. 
fi
####
####  Examine the log file to check for "ORA-" errors.
####
returnline=`grep 'ORA-' ${cl_logfilename}`
debug_var="--->${returnline}<---"
if [ "${returnline:-X}" != "X" ];then
  cl_errors=`expr ${cl_errors} + 1`
  cl_err_msg="${cl_err_msg:-}${cl_err_msg:+\n}Error-- ORACLE encountered errors: --->${returnline}<---"
fi

####
####  Examine the log file to check for "SP2-" errors.
####
returnline=`grep 'SP2-' ${cl_logfilename}`
debug_var="--->${returnline}<---"
if [ "${returnline:-X}" != "X" ];then
  cl_errors=`expr ${cl_errors} + 1`
  cl_err_msg="${cl_err_msg:-}${cl_err_msg:+\n}Error-- ORACLE SQL encountered errors: --->${returnline}<---"
fi
####
####  Examine the log file to check for "SQLException" errors.
####
returnline=`grep 'SQLException' ${cl_logfilename}`
debug_var="--->${returnline}<---"
if [ "${returnline:-X}" != "X" ];then
  cl_errors=`expr ${cl_errors} + 1`
  cl_err_msg="${cl_err_msg:-}${cl_err_msg:+\n}Error-- ORACLE SQLException errors: --->${returnline}<---"
fi

####
####  Examine the log file to check for "SQL exception " errors.
####
returnline=`grep 'SQL exception ' ${cl_logfilename}`
debug_var="--->${returnline}<---"
if [ "${returnline:-X}" != "X" ];then
  cl_errors=`expr ${cl_errors} + 1`
  cl_err_msg="${cl_err_msg:-}${cl_err_msg:+\n}Error-- ORACLE SQL exception errors: --->${returnline}<---"
fi

####
####  Examine the log file to check for "java:nnn)" errors.
####
returnline=`grep 'java:[0-9]\{1,\})' ${cl_logfilename}`
debug_var="--->${returnline}<---"
if [ "${returnline:-X}" != "X" ];then
  cl_errors=`expr ${cl_errors} + 1`
  cl_err_msg="${cl_err_msg:-}${cl_err_msg:+\n}Error-- JAVA java:nnn) errors: --->${returnline}<---"
fi

####
####  Examine the log file to check for "Exception in thread " errors.
####
returnline=`grep 'Exception in thread ' ${cl_logfilename}`
debug_var="--->${returnline}<---"
if [ "${returnline:-X}" != "X" ];then
  cl_errors=`expr ${cl_errors} + 1`
  cl_err_msg="${cl_err_msg:-}${cl_err_msg:+\n}Error-- JAVA Exception in thread errors: --->${returnline}<---"
fi

####
####  Examine the log file to check for "Usage" errors, First word on line, case insensitive.
####
returnline=`grep -i '^USAGE' ${cl_logfilename}`
debug_var="--->${returnline}<---"
if [ "${returnline:-X}" != "X" ];then
  cl_errors=`expr ${cl_errors} + 1`
  cl_err_msg="${cl_err_msg:-}${cl_err_msg:+\n}Error-- USAGE errors: --->${returnline}<---"
fi

####
####  Examine the log file to check for "File not found:" errors, First word on line, case insensitive.
####
returnline=`grep -i 'File not found:' ${cl_logfilename}`
debug_var="--->${returnline}<---"
if [ "${returnline:-X}" != "X" ];then
  cl_errors=`expr ${cl_errors} + 1`
  cl_err_msg="${cl_err_msg:-}${cl_err_msg:+\n}Error-- File not found: errors: --->${returnline}<---"
fi

####
####  Examine the log file to check for "SQL Error:" errors, First word on line, case insensitive.
####
returnline=`grep -i '^SQL Error:' ${cl_logfilename}`
debug_var="--->${returnline}<---"
if [ "${returnline:-X}" != "X" ];then
  cl_errors=`expr ${cl_errors} + 1`
  cl_err_msg="${cl_err_msg:-}${cl_err_msg:+\n}Error-- SQL Error: errors: --->${returnline}<---"
fi

####
####  Examine the log file to check for "FileNotFoundException:" errors, First word on line, case insensitive.
####
returnline=`grep -i '^FileNotFoundException:' ${cl_logfilename}`
debug_var="--->${returnline}<---"
if [ "${returnline:-X}" != "X" ];then
  cl_errors=`expr ${cl_errors} + 1`
  cl_err_msg="${cl_err_msg:-}${cl_err_msg:+\n}Error-- FileNotFoundException: errors: --->${returnline}<---"
fi

####  
####  Now write message to log file. 
####  
if [ ${cl_errors} -eq 0 ];then
  cl_err_msg="No errors recorded in ${cl_logfilename}"
else
  messagelog "ERROR:  There were ${cl_errors} error(s) detected in ${cl_logfilename}"
fi
messagelog "${cl_err_msg}"

return ${cl_errors}     ## Use return status to indicate number of errors found in log file (note 127==>couldn't read the log file)

}  ####  END FUNCTION Check_Log

####----------------------------------------------------------------------------
####
####  The function check_for_ftp_errors scans the current log file for FTP 
####  error messages
####      
####

check_for_ftp_errors() {

ftp_errs=""

line=`grep -i " Connection timed out" ${batch_log} `
if [ ${#line} -gt 6 ]; then
  ftp_errs="${ftp_errs}${line} "
fi
line=`grep -i " cannot " ${batch_log} `
if [ ${#line} -gt 6 ]; then
  ftp_errs="${ftp_errs}${line} "
fi
line=`grep -i " aborted" ${batch_log} `
if [ ${#line} -gt 6 ]; then
  ftp_errs="${ftp_errs}${line} "
fi
line=`grep -i " No such file or directory" ${batch_log} `
if [ ${#line} -gt 6 ]; then
  ftp_errs="${ftp_errs}${line} "
fi
line=`grep -i " Connection reset by peer." ${batch_log} `
if [ ${#line} -gt 6 ]; then
  ftp_errs="${ftp_errs}${line} "
fi
line=`grep -i "Service not available" ${batch_log} `
if [ ${#line} -gt 6 ]; then
  ftp_errs="${ftp_errs}${line} "
fi
line=`grep -i "Login failed" ${batch_log} `
if [ ${#line} -gt 6 ]; then
  ftp_errs="${ftp_errs}${line} "
fi

echo "${ftp_errs}"
return

}  ####  END FUNCTION check_for_ftp_errors


####----------------------------------------------------------------------------
####
####  The function ck_stat evaluates the cmd status $? and logs it's findings 
####  in the summary_batch_log.  then it either exits or increments the job_step
####  counter depending if $? was respectively non-zero or zero.  
####  The required variables are:
####      job_step
####      
####

ck_stat_keep_me() {

cmd_stat=$?         #  MUST BE FIRST LINE IN FUNCTION !!!!!
let job_step=${job_step:=22}
sbl="${BATCH_LOGS}/batch_summary.`date +'%Y%m%d'`"
if [ ${cmd_stat} -eq 0 ];then
  echo "Successfully Completed STEP ${job_step}">>${sbl}
  job_step=`expr ${job_step} + 1`
else
  echo "ERROR ${cmd_stat} IN STEP ${job_step}">>${sbl}
  echo "exit ${cmd_stat}">>${sbl}
  exit ${cmd_stat}
fi

}  ####  END FUNCTION ck_stat-keep-me


####----------------------------------------------------------------------------
####
####  The function ck_stat evaluates the cmd status $? and logs it's findings 
####  in the summary_batch_log.  then it either exits or increments the job_step
####  counter depending if $? was respectively non-zero or zero.  
####  The required variables are:
####      job_step
####      
####

ck_stat() {

cmd_stat=$?         #  MUST BE FIRST LINE IN FUNCTION !!!!!
let job_step=${job_step:=22}
sbl="${BATCH_LOGS}/batch_summary.`date +'%Y%m%d'`"
if [ ${cmd_stat} -eq 0 ];then
  messagelog "Successfully Completed STEP ${job_step} of THREAD ${batchthread_name:-Undefined} ${batchthread_start_dtm:-00001122001122}"
  job_step=`expr ${job_step} + 1`
else
  batcherror_notify "ERROR ${cmd_stat} IN STEP ${job_step} of THREAD ${batchthread_name:-Undefined} ${batchthread_start_dtm:-00001122001122} "
fi

}  ####  END FUNCTION ck_stat


####----------------------------------------------------------------------------
####
####  The function get_next_month returns the string MMDDYYYY for the first 
####  of the following month. It can be extended (later) to acceept parameters 
####  to indicate an alternative output format for the date and a start date to
####  be used to generate the "next" month.  
####

get_next_month() {

f_startyear=`date +'%Y'`
f_startmon=`date +'%m'`
f_startdom=`date +'%d'`

if [ ${f_startmon} -gt 12 ];then
  return_value="00000000"
  echo "${return_value}"
  return 1
else
  if [ ${f_startmon} -eq 12 ];then
    return_value="0101`expr ${f_startyear} + 1`"
  else
    if [ ${f_startmon} -lt 9 ];then     # zero-pad
      mon="0`expr ${f_startmon} + 1`"
    else
      mon="`expr ${f_startmon} + 1`"
    fi
    return_value="${mon}01${f_startyear}"
  fi
fi
echo "${return_value}"
return 0

}  ####  END FUNCTION get_next_month

####----------------------------------------------------------------------------
####
####  The function get_jobs_starttime returns the date-time string of the start 
####  of the specified jobtaken from the *.START flag in the ${BATCH_FLAGS} 
####  direcgtory.  The required parameters are the prefix of the *.START file
####  from which to obtain the start date-time string.  
####  
####  The optional second parameter is the 'recency' of the *.START file to
####  use in extracting the value.  By default this function will return the
####  date-time string from the most recent *.START file that matches the 
####  specified prefix.  If the second parameter is a 2, this function will 
####  return the most recent start, but the previous start time. etc.  
####  If there is no log file for any reason including specifying a second
####  parameter value that is higher than there are *.START files in the 
####  ${BATCH_FLAGS} directory, this function will return zeroes.
####  
####

get_jobs_starttime() {

if [ ${#} -lt 1 ];then
  tmp_prefix=`basename ${0}`
else
  tmp_prefix="${1}"
fi
if [ ${#} -gt 1 ];then
  recency=${2}
else
  recency=1
fi

#### JPT 20050131 changed to use the _archive directory rather than .../archive.
ls -1t ${BATCH_FLAGS}_archive/${tmp_prefix}*.log.[0-9]*.START > ${BATCH_TMP}/get_jobs_starttime.$$.${batch_start_dtm} 2>${BATCH_TMP}/get_jobs_starttime.$$.${batch_start_dtm}.err 
if [ -s ${BATCH_TMP}/get_jobs_starttime.$$.${batch_start_dtm}.err ]; then
  return_value="20030101111111"
elif [ `wc -l ${BATCH_TMP}/get_jobs_starttime.$$.${batch_start_dtm}| awk '{print $1}'` -lt ${recency} ]; then  # JPT 20050128 changed syntax for AIX wc format 
  return_value="20030101000000"
else
  tmp_line=`head -${recency} ${BATCH_TMP}/get_jobs_starttime.$$.${batch_start_dtm} | tail -1`
  tmp_line=${tmp_line%.*}                  #  drop the .START
  tmp_line=${tmp_line%.*}                  #  drop the .PID
  tmp_line=${tmp_line%.*}                  #  drop the .log
  return_value=${tmp_line##*.}             #  grab the date-time 
fi


echo "${return_value}"
return 0

}  ####  END FUNCTION get_jobs_starttime

####----------------------------------------------------------------------------
####
####  The function get_run_seq returns the numeric string to be used as a 
####  sequential run id for the process ${batch_prg}.  
####  It uses the file ${BATCH_ETC}/${1:-${batch_prg}}.seq to store the number 
####  that it has used and uses the file ${1:-${batch_prg}}.seq.lock.[datetimestamp] to prevent 
####  simultaneous update errors.  
####

get_run_seq() {

seq_file=${BATCH_ETC}/${1:-${batch_prg:-INTERACTIVE}.seq}    # use batch_prg if no parameter is defined

if [ ! -a ${seq_file} ];then
  if [ "${BATCH_ENVIRONMENT:-X}" = "PRODUCTION" ]; then 
    first_num=10000
  else 
    first_num=900000
  fi
  msg="NOTICE -- CREATING RUN SEQUENCE FILE ${seq_file} starting at ${first_num}"
  if [ "${batch_prg:-UNDEFINED}" = "UNDEFINED" ]; then    #### JPT 2060425   echo msg if running interactively
    echo ${msg} >&2
  else
    messagelog "${msg}"
  fi
  echo "${first_num} AutoCreated run sequence number for ${batch_prg:-INTERACTIVE} " > ${seq_file}
  chmod 666 ${seq_file}
fi
if [ ! -w ${seq_file} ];then
  msg="ERROR -- permissions.  Cannot update ${seq_file} "
  if [ "${batch_prg:-UNDEFINED}" = "UNDEFINED" ]; then    #### JPT 2060425   echo msg if running interactively
    echo ${msg} >&2
  else
    batch_notify "${msg}"
  fi
  echo "0"
  return 1
fi
my_lockfile=${seq_file}.lock.`date +"%Y%m%d%H%M%S%N"`
max_loops=4
locked=1
while [ locked -gt 0 ]
do
  echo "${$} # ${locked} at `date`" >> ${my_lockfile}
  unset lockedlist
  set -A lockedlist `ls ${seq_file}.lock.* 2>/dev/null`
  numlocks=${#lockedlist[*]}
  if [ "${lockedlist[0]}" = "${my_lockfile}" ];then  ## If first on the list then continue
    locked=0
  else    ## If not first in list, sleep and try again.  
    if [ ${locked} -gt ${max_loops} ];then
      msg="ERROR -- ${locked} cannot update get_run_seq for ${batch_prg:-INTERACTIVE} see -->${lockedlist}<--"
      if [ "${batch_prg:-UNDEFINED}" = "UNDEFINED" ]; then    #### JPT 2060425   echo msg if running interactively
        echo ${msg} >&2
      else
        batch_notify "${msg}"
      fi
    fi
    locked=`expr ${locked} + 1`
    sleep `expr $$ \% \( ${locked} + 3 \)`
  fi
done
 
####  
####  Now get the previously used value and increment it.
####  
inline=`head -1 ${seq_file}`
seqnum=`echo ${inline} | cut -d' ' -f1 `
invalidnumber=`echo ${seqnum:-undefined} |grep  [^0-9]`
if [ ${?} -ne 1 ];then
  msg="ERROR -- Corrupted run sequence number file: ${seq_file} "
  msg1="To correct, create the file ${seq_file} containing one line beginning with the highest used run sequence number for ${batch_prg:-INTERACTIVE}, check to if jobs are waiting for this run sequence number, and remove the '.lock' file "
  if [ "${batch_prg:-UNDEFINED}" = "UNDEFINED" ]; then    #### JPT 2060425   echo msg if running interactively
    echo ${msg} >&2
    echo ${msg1} >&2
  else
    batch_notify "${msg}"
    messagelog "${msg1}"
  fi
  echo "0"
  return 1
fi
seqnum=`expr ${seqnum} + 1`
( echo "${seqnum} has been used as the sequence number for ${batch_prg:-INTERACTIVE}" > ${seq_file} ) > /dev/null 2>&1  # overwrite the seq_num file with new value.  
rm -f ${my_lockfile}
echo "${seqnum}"
return 0

}  ####  END FUNCTION get_run_seq

####----------------------------------------------------------------------------
####
####  The function center_text requires a string as input and returns the same 
####  string as output padded with spaces (not tabs) so that it is centered 
####  on an ${center_text_width} display.  If ${center_text_width} is not 
####  defined, 80 is assumed.  
####

center_text() {
echo "${*}" |
sed '
   s/^[         ]*//
   s/[ ]*$//
   :a
   s/^.\{1,72\}$/ &/
   ta
   s/\( *\)\1/\1/
  '
}  ####  END FUNCTION center_text

####----------------------------------------------------------------------------
####
####  The function make_dir
make_dir()
{
####
####  Make the specified directory with the specified permissions. If the
####  IGNORE parameter exists, then do not error if directory already exists.
####
num_params=${#@}
dir_name=${1}
####  echo ">>>make_dir function creating dir: ${dir_name} " # JPT 20050420 removed
unset perm stop_on_err
if [ ${num_params} -gt 1 ]; then
  perm=${2}
fi
if [ ${num_params} -gt 2 ]; then
  stop_on_err=${3}
fi

if [ -d ${dir_name} ]; then
  echo "--make_dir: Directory ${dir_name} already exists"
  if [ "${stop_on_err:-X}" != "IGNORE" ]; then
    echo "--make_dir: Aborting...  "
    return 5
  fi
else
  mkdir -p ${dir_name}    #  JPT 20050204 Added -p to create intermediate dirs also
  cmd_status=$?
  if [ "${cmd_status}" != "0" ];then
    echo "--make_dir: ERROR creating ${dir_name} "
  fi
  if [ -d ${dir_name} ];then
    if [ ${#perm} -gt 0 ];then
      chmod ${perm} ${dir_name}
      cmd_status=$?
      if [ "${cmd_status}" != "0" ];then
        echo "--make_dir: ERROR during chmod ${perm} ${dir_name}"
      fi
    fi
  else
    echo "--make_dir: ERROR, ${dir_name} does not exist after mkdir "
  fi

fi

}  ####  END FUNCTION make_dir

####----------------------------------------------------------------------------
####
####  The function move_file simply calls copy_file and then removes the 
####  source file if the copy was successful.  
move_file()
{
####
####  move the specified file wiht the specified permissions. If the
####  OVERWRITE parameter exists, then do not error if destination file already exists.
####  P1  source file
####  P2  destination file or directory
####  P3  permissions on destination (optional)
####  P4  OVERWRITE parameter (optional) 
####
copy_msg=`copy_file "$@"`
copy_status=$?
if [ ${#copy_msg} -ne 0 ]; then
  move_msg=`echo ${copy_msg} |sed s/copy_file/move_file/g`
  echo ${move_msg}
  return 1
elif [ ${copy_status} -ne 0 ]; then
  move_msg="--move_file: ERROR creating new file"
  echo ${move_msg}
  return 1
else
  rm -f ${1:-ERROR}
  rm_status=$?
  if [ ${rm_status} -ne 0 ]; then
    move_msg="--move_file: ERROR removing source file."
    echo ${move_msg}
    return 1
  elif [ -a ${1:-ERROR} ]; then
    move_msg="--move_file: ERROR source file still exists."
    echo ${move_msg}
    return 1
  fi
fi

}  ####  END FUNCTION move_file

####----------------------------------------------------------------------------
####
####  The function copy_file
copy_file()
{
####
####  Copy the specified file wiht the specified permissions. If the
####  OVERWRITE parameter exists, then do not error if destination file already exists.
####  P1  source file
####  P2  destination file or directory
####  P3  permissions on destination (optional)
####  P4  OVERWRITE parameter (optional) 
####
num_params=${#@}
source_name=${1:-ERROR}
dest_name=${2:-ERROR}
unset perm stop_on_err
if [ ${num_params} -gt 2 ]; then
  perm=${3}
fi
if [ ${num_params} -gt 3 ]; then
  stop_on_err=${4}
fi

if [ ! -a ${source_name} ]; then
  echo "--copy_file: ${source_name} does not exists"
  if [ "${stop_on_err:-X}" != "IGNORE" ]; then
    echo "--copy_file: Aborting...  "
    return 5
  fi
fi

if [ -d ${dest_name} ]; then
  dest_name="${dest_name}/`basename ${source_name}`"
else
  if [ ! -d `dirname ${dest_name}` ]; then
    echo "--copy_file: Invalid Destination Directory. "
    return 6
  fi
fi

if [ -a ${dest_name} ]; then
  echo "--copy_file: ${dest_name} already exists"
  if [ "${stop_on_err:-X}" != "IGNORE" ]; then
    echo "--copy_file: Aborting...  "
    return 5
  fi
fi

####  
####  The actual copy...
####  
cp -f ${source_name} ${dest_name} 2>&1
cmd_status=$?
if [ "${cmd_status}" != "0" ];then
  echo "--copy_file: ERROR ${cmd_status} copying ${source_name} TO ${dest_name} "
fi


  if [ -a ${dest_name} ];then
    if [ ${#perm} -gt 0 ];then
      chmod ${perm} ${dest_name}
      cmd_status=$?
      if [ "${cmd_status}" != "0" ];then
        echo "--copy_file: ERROR during chmod ${perm} ${dest_name}"
      fi
    fi
  else
    echo "--copy_file: ERROR, ${dest_name} does not exist after copy_file "
fi

}  ####  END FUNCTION copy_file

####----------------------------------------------------------------------------
####
####  Gets the DDS tradingPartnerRoot directory from the database name passed as
####  parameter 1.  Uses ORACLE_SID for the database if no parameter is specified
####
get_tpr_dir ()
{
  myenv=`echo ${1:-${ORACLE_SID:-get_tpr_dir-requires-a-parameter}} | cut -c5-| tr [a-z] [A-Z]`
  mytpr=${BATCH_FTP}/DDS_${myenv}/tradingPartnerRoot
  if [ -d ${mytpr} ];then
    echo ${mytpr}
  else
    echo "ERROR_DIR____${mytpr}____Does_Not_Exist"
  fi
}  ####  END FUNCTION get_tpr_dir



##########################################################################
#   main script                                                          #
##########################################################################
if [ -r ${BATCH_BIN:-UNDEFINED}/ksh_functions_custom.ksh ]; then
  . ${BATCH_BIN:-UNDEFINED}/ksh_functions_custom.ksh
fi
