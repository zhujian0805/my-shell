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
#  NAME:               ftp_corp2.ksh
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

ftp -n 208.242.100.180 <<-ENDFTP
user diamondasp/chauser chauser
binary
dir
put /diamond/extdata/CLM0530.001 clmo530.xxx
dir
bye

ENDFTP


