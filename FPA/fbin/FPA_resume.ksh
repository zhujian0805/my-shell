#!/bin/ksh
#--------------------------- COPYRIGHT NOTICE ----------------------------------
#*******************************************************************************
#
# Copyright (c) 2006 Perot Systems Corporation
# All Rights Reserved
# Copyright Notice Does Not Imply Publication
#
#*******************************************************************************
# SCCS_ID: %Z% %M% %I% %G%
#*******************************************************************************
#
#  NAME:               FPA_resume.ksh
#
#  DESCRIPTION:        This script will SUSPEND the FPA. It is designed to be
#                      called from the FPA MENU interactively so it does not
#                      define any of the standard environment variables.
#
#  USAGE:              FPA_resume.ksh message
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
# 2006/12/15   J Thiessen       New code.
#
# SCCS_COMMENT: Original code checkin.
#
#***    ALWAYS UPDATE THE SCCS_COMMENT BEFORE CHECKING THE CODE INTO SCCS     **
#*******************************************************************************

##########################################################################
#   main script                                                          #
##########################################################################

num_args=${#@}
if [ ${num_args} -lt 1 ]; then
  echo "\n\nERROR:  USAGE:  FPA_resume.ksh message.... "
  ret_code=1
elif [ ! -a ${BATCH_JOBCARDS}/FPA_IS_SUSPENDED.DAT ]; then
  echo "\n\n${RVON}ERROR:  The file FPA_IS_SUSPENDED.DAT does not exist. \nThis FPA Environment was not and is not Suspended.${RVOF}"
elif [ ! -a ${BATCH_JOBCARDS}/FPA_IS_SUSPENDED.DAT ]; then
  echo "\n\n${RVON}ERROR:  The file FPA_IS_SUSPENDED.DAT does not exist. \nThis FPA Environment was not and is not Suspended.${RVOF}"
else
  msg=${*:-}
  echo "## At `date +'%Y%m%d%H%M%S'` ${0##*/} is Releasing this FPA Environment. \n## Message from ${0##*/} ---> ${msg:-}" >> ${BATCH_JOBCARDS}/FPA_IS_SUSPENDED.DAT
  if [ $? -ne 0 ];then
    echo "\nWARNING:  Unable to append to FPA_IS_SUSPENDED.DAT\n"
  fi
  mv ${BATCH_JOBCARDS}/FPA_IS_SUSPENDED.DAT ${BATCH_JOBCARDS}_archive/FPA_IS_SUSPENDED.DAT.$$.ResumedAt.`date +'%Y%m%d%H%M%S'` 
  if [ $? -ne 0 ];then
    echo "\nERROR :  Unable to move FPA_IS_SUSPENDED.DAT\n"
  fi
  if [ -a ${BATCH_JOBCARDS}/FPA_IS_SUSPENDED.DAT ]; then
    echo "\n${RVON}ERROR:  This FPA environment is still SUSPENDED${RVOF}\n\n"
  else
    echo "\n\nSuccessfully resumed processing for the FPA environment.\n\n"
  fi
fi
return ${ret_code:-1}

