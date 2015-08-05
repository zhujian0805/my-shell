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
#  NAME:               FPA_suspend.ksh
#
#  DESCRIPTION:        This script will SUSPEND the FPA. It is designed to be
#                      called from the FPA MENU interactively so it does not
#                      define any of the standard environment variables.
#
#  USAGE:              FPA_suspend.ksh release_time notify_time message
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

num_args=${#@}
if [ ${num_args} -lt 3 ]; then
  echo "ERROR -- USAGE:  FPA_suspend.ksh release_time notify_time message.... "
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

