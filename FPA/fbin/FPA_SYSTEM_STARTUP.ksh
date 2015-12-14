#!/bin/ksh
#--------------------------- COPYRIGHT NOTICE ----------------------------------
#*******************************************************************************
#
# Copyright (c) 2003 Perot Systems Corporation
# All Rights Reserved
# Copyright Notice Does Not Imply Publication
#
#*******************************************************************************
# SCCS_ID: %Z% %M% %I% %G%
#*******************************************************************************
#
#  NAME:               FPA_SYSTEM_STARTUP.ksh
#
#  DESCRIPTION:        This script is designed to be run as part of the system startup procedures.  It will confirm that all FPA environments on a particular computer are clean and ready to start and will clear any sync files that were orphaned by the system shutdown.  
#        will CLEAR all sync files  all FPA environments on the system. It is designed to be called as part of the rc scripts to reduce the possiblility of an orphan FPA flag file.  The key elements are to 1) create the SUSPEND flag file and 2) sleep for enough time that normal FPA processes have time to clear their own sync files.  

#
#  USAGE:              FPA_SYSTEM_STARTUP.ksh [FPA-Environment]  
#
#  EXT DATA FILES:
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
# 2006/07/14   J Thiessen       New code.
#
# SCCS_COMMENT: Original code checkin.
#
#***    ALWAYS UPDATE THE SCCS_COMMENT BEFORE CHECKING THE CODE INTO SCCS     **
#*******************************************************************************

##########################################################################
#   main script                                                          #
##########################################################################

####  get list of FPA logins
user_list=`grep "^[a-zA-Z]*fpa" /etc/passwd | cut -d: -f1`


####  for each FPA login, check to see if the FPA environment is active and if so, clear all sync files. 
active_fpa=`crontab -l ${myuser} | grep -v "^#" | cut -d"#" -f1 | grep "/FPA.ksh " | wc -l`


if [ ${active_fpa} -gt 0 ]; then ####  this FPA environment is active.  
  ## su to the user
  su - ${myuser}  
  my_sync_dir=${BATCH_SYSTEM:-not_defined}/sync_files
  if [ -a ${my_sync_dir} ]; then
  else
  fi
  cd ${BATCH_SYSTEM:-not_defined}/sync_files
  ##  Get the sync directory  
fi





















num_args=${#@}
if [ ${num_args} -lt 3 ]; then
  echo "ERROR -- USAGE:  FPA_SYSTEM_STARTUP.ksh release_time notify_time message.... "
  ret_code=1
else
  release_time=${1:-}
  shift
  notify_time=${1:-}
  shift
  msg=${*:-}
  ####
  ####  Format the RELEASE TIME STRING if available.
  ####
  tmp=`echo ${release_time:-} | grep [^0-9]`  # Confirm that this variable is numeric
  if [ ${#release_time} -ne 14 ]; then
    rel_str="# WARNING:  No RELEASE TIME specified. (YYYYMMDDHHMNSS)  ${release_time:-}"
    echo "\n${RVON}${rel_str}${RVOF}" 
    echo "${RVON}Did NOT alter FPA SUSPEND settings. ${RVOF}" 
    ret_code=1
  elif [ ${#tmp} -gt 0 ]; then
    rel_str="# WARNING:  INVALID RELEASE TIME specified. (YYYYMMDDHHMNSS)  ${release_time:-}"
    echo "\n${RVON}${rel_str}${RVOF}" 
    echo "${RVON}Did NOT alter FPA SUSPEND settings. ${RVOF}" 
    ret_code=1
  else
    rel_str="#RELEASE_AFTER: ${release_time}"
  fi
  ####
  ####  Format the NOTIFY TIME STRING if available.
  ####
  tmp=`echo ${notify_time:-} | grep [^0-9]`  # Confirm that this variable is numeric
  if [ ${#notify_time} -ne 14 ]; then
    not_str="# WARNING:  No NOTIFY TIME specified. (YYYYMMDDHHMNSS)  ${notify_time:-}"
    echo "\n${RVON}${not_str}${RVOF}" 
    echo "${RVON}Did NOT alter FPA SUSPEND settings. ${RVOF}" 
    ret_code=1
  elif [ ${#tmp} -gt 0 ]; then
    not_str="# WARNING:  No NOTIFY TIME specified. (YYYYMMDDHHMNSS)  ${notify_time:-}"
    echo "\n${RVON}${not_str}${RVOF}" 
    echo "${RVON}Did NOT alter FPA SUSPEND settings. ${RVOF}" 
    ret_code=1
  else
    not_str="#NOTIFY_AFTER: ${notify_time}"
  fi
  
  if [ "${ret_code:-0}" = "0" ]; then
    ####
    ####  Create the SUSPEND FILE if there were no errors in parameters
    ####
    my_verb="Created"
    if [ -w ${BATCH_JOBCARDS}/FPA_IS_SUSPENDED.DAT ]; then
      ## ##  echo "##### The following shows the previous content of FPA_IS_SUSPENDED.DAT:"
      ## ##  cat ${BATCH_JOBCARDS}/FPA_IS_SUSPENDED.DAT
      ## ##  echo "##### The above shows the previous content of FPA_IS_SUSPENDED.DAT \n\n"
      my_verb="Updated"
    fi
    echo "# ${0} is suspending the FPA at `date` " >>  ${BATCH_JOBCARDS}/FPA_IS_SUSPENDED.DAT
    echo "#MSG_TO_USERS: ${msg:-} " >> ${BATCH_JOBCARDS}/FPA_IS_SUSPENDED.DAT
    echo "${rel_str:-} "   >> ${BATCH_JOBCARDS}/FPA_IS_SUSPENDED.DAT
    echo "${not_str:-} "   >> ${BATCH_JOBCARDS}/FPA_IS_SUSPENDED.DAT
    ret_code=0
  
    if [ -a ${BATCH_JOBCARDS}/FPA_IS_SUSPENDED.DAT ]; then
      echo "\n\n${my_verb} SUSPEND file: ${BATCH_JOBCARDS}/FPA_IS_SUSPENDED.DAT "
      cat ${BATCH_JOBCARDS}/FPA_IS_SUSPENDED.DAT
      echo "${my_verb} SUSPEND file: The text above is the contents of the SUSPEND FILE. "
    else
      ret_code=1
      echo "ERROR: CANNOT suspend FPA, CANNOT create ${BATCH_JOBCARDS}/FPA_IS_SUSPENDED.DAT  "
    fi
  fi
fi
return ${ret_code:-1}

