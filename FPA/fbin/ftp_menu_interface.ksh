#!/bin/ksh
#--------------------------- COPYRIGHT NOTICE ----------------------------------
#*******************************************************************************
#
# Copyright (c) 2002 Perot Systems Corporation
# All Rights Reserved
# Copyright Notice Does Not Imply Publication
#
#*******************************************************************************
#
#  NAME:               ftp_menu_interface.ksh
#
#  DESCRIPTION:        This script simply accepts parameters with the directory
#                      path separated from the filename so that the menu 
#                      will look better.  The menu will call this routine 
#                      which will in turn call the regular ftp program. 
#                      This code is designed to work with FTP scripts
#                      that do not require environmental parameters. 
#                      
#  EXT DATA FILES:     
#                      
#  ENV VARIABLES:      
#                      
#  INPUT:              $1 = name of the ftp program to be used
#                      $2 = directory of source file
#                      $3 = name of source file
#                      $4 = directory of destination file -- if $4 is "DEFAULT"
#                           then no destination directory will be used. 
#                      $5 = name of destination file
#                      $6 = mode of transfer (ascii or binary)
#                      
#  OUTPUT:             
#                      
#  TEMPORARY FILES:    
#                      
#  EXT FUNC CALLS:     Standard batch messaging functions in batchlog.ksh
#                      
#
#  EXT MOD CALLS:      batchlog.ksh
#                      
#                      
#  TO DO:              
#
#*******************************************************************************
# Date         Programmmer      Description
# ----------   --------------   ------------------------------------------
# 05/16/2002   J. Thiessen      New code.
# 03/10/2003   J. Thiessen      removed explicit path references to allow the 
#                               PATH to select the proper version or custom
#                               executables. 
#
#*******************************************************************************

##########################################################################
#   main script                                                          #
##########################################################################

. batchlog.ksh
NO_OUTPUT="TRUE"
NO_SUMMARY_MSGS=TRUE    ## do not make entries in the batch_summary log file
APPEND_LOG_FILE=TRUE    ## create only one log file per day
setlog ${batch_prg}.`date +'%Y%m%d'`
batchstart

####  
####  Define variables
####  
datetimestamp=`date +\%Y\%m\%d\%H\%M\%S`
ftp_cmd_file="${BATCH_TMP}/${batch_prg}.${datetimestamp}"

Usage="USAGE: ${batch_prg} ftp-program source-directory source-filname destination-directory(or DEFAULT) destination-filename transfer-mode. ${*} "
if [ ${#} -ne 6 ]
then
  msg="ERROR -- Invalid arguments ${Usage}"
  batcherror_notify "${msg}"
fi

ftp_program=${1}
source_filename="${2}/${3}"
if [ "${4}" = "DEFAULT" ]; then
  dest_filename="${5}"
else
  dest_filename="${4}/${5}"
fi
mode=${6}

FPA_nohup.ksh ${ftp_program} ${source_filename} ${dest_filename} ${mode}
if [ ${?} -ne 0 ]; then  #### be sure that FPA_nohup.ksh successfully started the program.
  msg="ERROR -- The menu-request for an FTP transfer of, ${ftp_program} ${source_filename} ${dest_filename} ${mode} , failed to start properly. "  
  batcherror_notify "${msg}"
fi

batchend
