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
#  NAME:               ftp_jim.ksh
#
#  DESCRIPTION:        This script uses ftp to send the specified file $1, 
#                      placing it in the specified directory $2.  This code
#                      defaults to ASCII transfers, but will accept the mode
#                      of A[SCII]" or B[INARY] as $3 to force a specific mode.
#                      
#  EXT DATA FILES:     
#                      
#  ENV VARIABLES:      
#                      
#  INPUT:              $1 is the name of the file to be sent (with full path)
#                      $2 specifies the destination, full path with filename
#                      $3 optionally specifies the transfer mode, ascii or binary
#
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
#  TO DO:              add error checking for "Connection timed out"
#
#*******************************************************************************
# Date         Programmmer      Description
# ----------   --------------   ------------------------------------------
# 11/05/2001   J. Thiessen      New code.
# 02/04/2002   J. Thiessen      confined transfers to user's directories
#
#*******************************************************************************
#-------------------------------------------------------------------------------
####
####  This function creates a temporary, ftp command file.
####

Make_FTP_File ()
{

echo "ftp -n ${dest_system} >> ${batch_log} 2>&1 <<-End_Send 
	user ${USER} ${PW}
	${mode}
	prompt
	cd ${dest_dir} 
	lcd ${local_dir}
	put ${local_file} ${dest_file}
        bye
End_Send" > ${ftp_cmd_file}

}  ####  END FUNCTION Make_FTP_File

##########################################################################
#   main script                                                          #
##########################################################################

## REMOVED  . ${BATCH_BIN}/batchlog.ksh
## REMOVED  batchstart

####  
####  Define runtime variables
####  
datetimestamp=`date +\%Y\%m\%d\%H\%M\%S`
ftp_cmd_file="${BATCH_TMP}/${batch_prg}.${datetimestamp}"

Usage="USAGE: ${batch_prg} filname destination_directory "
if [ ${#} -lt 2 ]
then
  msg="ERROR -- Insufficient arguments ${Usage}"
  ## REMOVED  batcherror_notify "${msg}"
fi
if [ ${#} -gt 4 ]
then
  msg="ERROR -- Too many arguments ${Usage}"
  ## REMOVED  batcherror_notify "${msg}"
fi

filename=$1
destination=$2
mode=ascii
if [ "${3:-X}" != "X" ]; then
  mode=${3}
fi

####  
####  Confirm that data to be sent is located in a permitted directory.
####
root_dir=${BATCH_LOGS%/*}
echo ":${filename}:" | grep  ^:${root_dir} > /dev/null 2>&1
if [ ${?} -ne 0 ]; then  #### successful grep returns zero, found the string
  msg="ERROR -- Cannot Access file ${filename} . . . not in path "
  ## REMOVED  batcherror_notify "${msg}"
fi

local_dir=`dirname ${filename}`
local_file=`basename ${filename}`
dest_dir=`dirname ${destination}`
dest_file=`basename ${destination}`
USER=your-loginname
PW=your-password
dest_system='192.216.170.208'

if [ ! -r ${filename} ]
then
  msg="ERROR -- ${batch_prg} cannot read  ${filename}"
  ## REMOVED  batcherror_notify "${msg}"
fi
   
Make_FTP_File
ReturnCode=$?
if [ "${ReturnCode}" != "0" ]
then
  msg="ERROR -- ${batch_prg} is unable to build the FTP instruction file ${ftp_cmd_file}"
  ## REMOVED  batcherror_notify "${msg}"
fi

chmod 744 ${ftp_cmd_file}
if [ ! -x ${ftp_cmd_file} ]
then
  msg="ERROR -- ${batch_prg} is unable to execute the FTP instruction file `ls -lt ${ftp_cmd_file}`"
  ## REMOVED  batcherror_notify "${msg}"
fi

####
####  Perform the file transfer
####
. ${ftp_cmd_file} >> ${batch_log} 2>&1
ReturnCode=$?
if [ "${ReturnCode}" != "0" ]
then
  msg="ERROR -- ${batch_prg}.  Error executing the FTP instruction file ${ftp_cmd_file}"
  ## REMOVED  batcherror_notify "${msg}"
fi

####  
####  Check the logfile for errors.
####  
line=`grep -i " Connection timed out" ${batch_log} `
if [ ${#line} -gt 6 ]; then
  msg="ERROR --  ${batch_prg}.  Error during FTP: --->${line}<--- "
  ## REMOVED  batcherror_notify "${msg}"
fi
line=`grep " cannot " ${batch_log} `
if [ ${#line} -gt 6 ]; then
  msg="ERROR --  ${batch_prg}.  Error during FTP: --->${line}<--- "
  ## REMOVED  batcherror_notify "${msg}"
fi
line=`grep " aborted" ${batch_log} `
if [ ${#line} -gt 6 ]; then
  msg="ERROR --  ${batch_prg}.  Error during FTP: --->${line}<--- "
  ## REMOVED  batcherror_notify "${msg}"
fi

## REMOVED  batchend
