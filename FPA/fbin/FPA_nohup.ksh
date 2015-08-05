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
#  NAME:              FPA_nohup.ksh 
#
#  DESCRIPTION:       This module executes a script in the background.
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
# 01/26/2000    J. Thiessen      New code. 
# 03/10/2003    J. Thiessen      removed explicit path references to allow the 
#                                PATH to select the proper version or custom
#                                executables. 
# 09/15/2005    R. Crawford      Replaced /tmp with ${BATCH_TMP} to help 
#                                segregate the accounts on the mid-tier structure
# 06/05/2006    J. Thiessen      improved error handling. 
#
#*******************************************************************************

##########################################################################
#   main script                                                          #
##########################################################################

. ~/.FPAprofile     
. batchlog.ksh
NO_SUMMARY_MSGS="TRUE"
NO_OUTPUT="TRUE"
APPEND_LOG_FILE=TRUE      # don't export to be sure that the job started does NOT have this variable set.
setlog ${batch_prg}.`date +'%Y%m%d'`
batchstart

####  
####  make sure that the job to be started actually exists. 
####  
job=${1}
which ${job} > /dev/null 2>&1
ret_stat=$?
if [ ${ret_stat} -gt 0 ]; then
  messagelog_notify "NOHUP ERROR #${ret_stat} cannot find command: $*"
else
  nohup $* & >> ${BATCH_TMP}/nohup.out 2>&1
  OK=$?
  messagelog "The status of the nohup is ${OK}"
  if [ ${OK} -eq 126 -o ${OK} -eq 127 ] 
  then 
      messagelog_notify "NOHUP ERROR #${OK} on command: $*" 
  fi
fi

batchend
