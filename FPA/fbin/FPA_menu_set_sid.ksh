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
#  NAME:              FPA_menu_set_sid.ksh
#
#  DESCRIPTION:       Allows the menu to be pointed to a specified database.
#  
#  EXT DATA FILES: 
#
#  ENV VARIABLES:   
#   
#  INPUT:             The only parameter is the database to use. 
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
# 07/16/2002   J. Thiessen      New code. 
#
#
#*******************************************************************************

##########################################################################
#   main script                                                          #
##########################################################################

. ~/.FPAprofile     
. /wlpdev/va_test/vabatcht/bin/dev/batchlog.ksh
. /wlpdev/va_test/vabatcht/bin/dev/ksh_functions.ksh
NO_SUMMARY_MSGS="TRUE"
NO_OUTPUT="TRUE"
APPEND_LOG_FILE=TRUE      # be sure that the job started does NOT have this variable set.
setlog ${batch_prg}.`date +'%Y%m%d'`
batchstart
  new_sid=`echo ${1:-UNSPECIFIED} | tr "a-z" "A-Z"`
  set_oracle_sid ${new_sid}

## ## grep "#allowed_db 
## ## if [ "${1:-UNSPECIFIED}" = "UNSPECIFIED" ];then
## ## 
## ## else
  ## ## set_oracle_sid ${1}
## ## 
## ## fi

batchend
