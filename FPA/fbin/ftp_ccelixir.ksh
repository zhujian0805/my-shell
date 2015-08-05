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
#  NAME:               ftp_ccelixir.ksh
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
#                      Additional arguments must be in pairs: 
#                        filename to be sent (without path)
#                        destination filename (without path)
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
# 04/01/2002   J. Thiessen      added error trap for " No such file or directory" msg
# 05/02/2002   J. Thiessen      added error trap for " Connection reset by peer." msg
# 06/26/2002   J. Thiessen      moved error traps into ksh_functions.ksh 
# 03/10/2003   J. Thiessen      removed explicit path references to allow the 
#                               PATH to select the proper version or custom
#                               executables. 
#
#*******************************************************************************
#-------------------------------------------------------------------------------
####
####  This function creates a temporary, ftp command file.
####

Make_FTP_File ()
{

echo "ftp -nv ${dest_system} >> ${batch_log} 2>&1 <<-End_Send 
	user ${USER} ${PW}
	${mode}
	prompt
	cd ${dest_dir} 
	lcd ${local_dir}" > ${ftp_cmd_file}

let num_loops=${#dest_file[*]}
let loop_count=0
while [ ${loop_count} -lt ${num_loops} ]
do
  echo "        put ${local_file[${loop_count}]} ${dest_file[${loop_count}]}" >> ${ftp_cmd_file}
  loop_count=`expr ${loop_count}+1`
done

echo "       bye
End_Send" >> ${ftp_cmd_file}

}  ####  END FUNCTION Make_FTP_File

##########################################################################
#   main script                                                          #
##########################################################################

. batchlog.ksh
. ksh_functions.ksh
NO_OUTPUT="TRUE"
batchstart

####  
####  Define variables
####  
datetimestamp=`date +\%Y\%m\%d\%H\%M\%S`
ftp_cmd_file="${BATCH_TMP}/${batch_prg}.${datetimestamp}"

Usage="USAGE: ${batch_prg} filname destination_directory "
if [ ${#} -lt 2 ]
then
  msg="ERROR -- Invalid arguments ${Usage}"
  batcherror_notify "${msg}"
fi

filename=$1
destination=$2
set -A arg_array $@
set -A local_file
set -A dest_file
local_dir=`dirname ${filename}`
local_file[0]=`basename ${filename}`
dest_dir=`dirname ${destination}`
dest_file[0]=`basename ${destination}`

mode=ascii
if [ "${3:-X}" != "X" ]; then
  mode=${3}
fi

num_files=0
counter=3
while [ ${counter} -lt ${#} ]
do
  num_files=`expr ${num_files} + 1`
  local_file[${num_files}]=${arg_array[${counter}]}
  counter=`expr ${counter} + 1`
  if [  ${counter} -ge ${#} ]; then
    msg="ERROR -- Unmatched arguments ${Usage} "
    batcherror_notify "${msg}"
  fi
  dest_file[${num_files}]=${arg_array[${counter}]}
  counter=`expr ${counter} + 1`
done

####  
####  Confirm that data to be sent is located in a permitted directory.
####
root_dir=${BATCH_LOGS%/*}
echo ":${filename}:" | grep  ^:${root_dir} > /dev/null 2>&1
if [ ${?} -ne 0 ]; then  #### successful grep returns zero, found the string
  msg="ERROR -- Cannot Access file ${filename} . . . not in path "
  batcherror_notify "${msg}"
fi


USER=ftpssp
PW=sspftp
dest_system='192.216.170.206'


if [ ! -r ${filename} ]
then
  msg="ERROR -- ${batch_prg} cannot read  ${filename}"
  batcherror_notify "${msg}"
fi

Make_FTP_File
ReturnCode=$?
if [ "${ReturnCode}" != "0" ]
then
  msg="ERROR -- ${batch_prg} is unable to build the FTP instruction file ${ftp_cmd_file}"
  batcherror_notify "${msg}"
fi

chmod 744 ${ftp_cmd_file}
if [ ! -x ${ftp_cmd_file} ]
then
  msg="ERROR -- ${batch_prg} is unable to execute the FTP instruction file `ls -lt ${ftp_cmd_file}`"
  batcherror_notify "${msg}"
fi


####
####  Perform the file transfer
####
. ${ftp_cmd_file} >> ${batch_log} 2>&1

ReturnCode=$?
if [ "${ReturnCode}" != "0" ]
then
  msg="ERROR -- ${batch_prg}.  Error executing the FTP instruction file ${ftp_cmd_file}"
  batcherror_notify "${msg}"
fi

####  
####  Check the logfile for errors.
####  
line=`check_for_ftp_errors`
if [ ${#line} -gt 6 ]; then
  msg="ERROR --  ${batch_prg}.  Error during FTP: --->${line}<--- "
  batcherror_notify "${msg}"
fi

batchend
