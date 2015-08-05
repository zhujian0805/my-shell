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
#  NAME:               ftp_mainframe.ksh
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
#  INPUT:              $1 is the directory containing the file to be sent relative to $BATCH_FTP
#                      $2 is the name of the file to be sent 
#                      $2 specifies the destination filename
#                      $3 specifies the transfer mode, ascii or binary
#                      $4 specifies the UNIT
#                      $5 specifies the RECFM
#                      $6 specifies the LRECL
#                      $7 specifies the BLKSIZE
#                      $8 specifies the additional parameter grouping 
#                         eg PHARM
#                      
#  INPUT:  USED-TO-BE...  $1 is the name of the file to be sent (with full path)
#                      $2 specifies the destination filename
#                      $3 specifies the transfer mode, ascii or binary
#                      $4 specifies the UNIT
#                      $5 specifies the RECFM
#                      $6 specifies the LRECL
#                      $7 specifies the BLKSIZE
#                      $8 specifies the additional parameter grouping 
#                         eg PHARM
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
# 11/20/2002   K. Thomas        PHARM mod - PRIMARY=90 SECONDARY=50
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

echo "ftp -nv ${dest_system} >> ${batch_log} <<-End_Send 
       user ${USER} ${PW}
       ${mymode}
       prompt
       ${additional_commands}
       site UNIT=${myunit}
       site RECFM=${myrecfm}
       site LRECL=${mylrecl}
       site BLKSIZE=${myblksize}
       lcd ${local_dir}
       put "${local_file} \'${mydest_file}\(+1\)\'"
     bye
End_Send" > ${ftp_cmd_file}

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

Usage="USAGE: ${batch_prg} filname destination_file mode unit recfm lrecl blksize "
if [[ ${#} -ne 7 && ${#} -ne 8 ]]
then
  msg="ERROR -- Invalid arguments ${Usage}"
  batcherror_notify "${msg}"
fi

myfilename=${1}
mydest_file=${2}
mymode=`echo ${3} | tr '[A-Z]' '[a-z]'`
myunit=${4}
myrecfm=${5}
mylrecl=${6}
myblksize=${7}
mycmdgroup=${8:-NONE}

case ${mycmdgroup} in
  PHARM)  additional_commands="site CYLINDERS\n\tsite PRIMARY=90\n\tsite SECONDARY=50" ;;
  *)      additional_commands="" ;;
esac

####  
####  Confirm that data to be sent is located in a permitted directory.
####  
root_dir=${BATCH_LOGS%/*}
echo ":${myfilename}:" | grep  ^:${root_dir} > /dev/null 2>&1  
if [ ${?} -ne 0 ]; then  #### successful grep returns zero, found the string
  msg="ERROR -- Cannot Access file ${myfilename} . . . not in path "
  batcherror_notify "${msg}"
fi


local_dir=`dirname ${myfilename}`
local_file=`basename ${myfilename}`
USER=ftpssp
PW=sspftp
dest_system='192.216.170.199'

if [ ! -r ${myfilename} ]
then
  msg="ERROR -- ${batch_prg} cannot read  ${myfilename}"
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
