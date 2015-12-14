#!/bin/ksh 
#--------------------------- COPYRIGHT NOTICE ----------------------------------
#*******************************************************************************
#
# Copyright (c) 2004 Perot Systems Corporation 
# All Rights Reserved
# Copyright Notice Does Not Imply Publication
#
#*******************************************************************************
#
#  NAME:               FPA_zipdir.ksh
#
#  DESCRIPTION:        This script will gzip all non-zipped files in the 
#                      directories specified as parameters.  
#  
#  EXT DATA FILES:     
#
#  ENV VARIABLES:      
#   
#  INPUT:              Parameters are directories whose files are to be zipped
#
#  OUTPUT:             ${batch_working_directory}/FPA_zipdir.out contains 
#                      detailed listings of disk space and files compressed.
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
# 03/15/2004   J. Thiessen      New code. 
#
#
#*******************************************************************************

##########################################################################
#   main script                                                          #
##########################################################################

. ~/.FPAprofile     
. batchlog.ksh
batchsync_filename="SYNC.${batch_prg}"
NO_SUMMARY_MSGS=TRUE      
batchstartsync

if [ ${#} -lt 1 ]
then
  msg="${batch_prg} ERROR -- USAGE: requires at least one directory as an argument:-->${*}<--"
  batcherror_notify "${msg}"
fi

set -A tdirs $@
counter=0
num_dirs=$#
err_count=0
outputfile=${batch_working_directory}/FPA_zipdir.out

msg="The ${num_dirs} dirs are: ${tdirs[*]}\n\n"
messagelog "${msg}"
echo -e "`date` ${msg}" >> ${outputfile}

while [ ${counter} -lt ${num_dirs} ]
do
  dir=`eval echo "${tdirs[${counter}]}"`     #  translate variables...
  if [ ! -d ${dir} ]; then   #  is directory invalid?
    error_message="ERROR: invalid directory ${dir} "
    messagelog "${error_message}"
    err_count=`expr ${err_count} + 1`
  else
    msg="ZIPPING dir ${counter}: ${dir}"
    messagelog "${msg}"
    echo "`date` ${msg}" >> ${outputfile}
    df -k ${dir} >> ${outputfile}
    for x in `find ${dir} \( -type d ! -name ${dir##*/} -prune \) -o \( -type f -size +10 ! -name '*.gz' -print \) 2>>${outputfile}`
    do
	tstamp=$(date +'%Y%m%d%H%M%S')
	if [ -e ${x}.gz ]
	then
	gzip -N -S .gzipped_at_${tstamp}.gz ${x}
	ret_stat=${?}
	echo "-- gzip ${x}.gz already exists, suffixed ${x} during gzip to ${x}.gzipped_at_${tstamp}.gz" >> ${outputfile}
	echo "-- rc=${ret_stat} command=gzip -N -S .gzipped_at_${tstamp}.gz ${x} " >> ${outputfile}
		if [ ${ret_stat} -ne 0 ]; then
		error_message="ERROR: ${ret_stat} from gzip on file ${x} "
		messagelog "${error_message}"
		err_count=`expr ${err_count} + 1`
		fi
	else
      gzip ${x}
      ret_stat=${?}
      echo "-- gzip ${ret_stat} ${x} " >> ${outputfile}
      if [ ${ret_stat} -ne 0 ]; then 
        error_message="ERROR: ${ret_stat} from gzip on file ${x} "
        messagelog "${error_message}"
        err_count=`expr ${err_count} + 1`
      fi
	fi
    done
    df -k ${dir} >> ${outputfile}
    echo -e "`date` DONE ${msg}\n" >> ${outputfile}
  fi
  counter=`expr ${counter} + 1`
done

if [ ${err_count} -ne 0 ]; then
  batcherror_notify "ERROR -- there were ${err_count} errors in ${0} "
fi

batchend
