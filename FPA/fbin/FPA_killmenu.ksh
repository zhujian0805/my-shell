#!/bin/ksh 
#--------------------------- COPYRIGHT NOTICE ----------------------------------
#*******************************************************************************
#
# Copyright (c) 2005 Perot Systems Corporation 
# All Rights Reserved
# Copyright Notice Does Not Imply Publication
#
#*******************************************************************************
#
#  NAME:               FPA_killmenu.ksh
#
#  DESCRIPTION:        This script is started by the menu.ksh program to kill runaaway menu processes.  The runaway process happen when a pc window (MSWindows) running menu.ksh is exited improperly.  Improperly includes clicking the upper right X to close the window before disconnecting from teh menu program, a PC crashing, and the network losing connectivity. 
#  
#  EXT DATA FILES:     The 
#
#  ENV VARIABLES:   
#   
#  INPUT:            
#
#  OUTPUT:            For each 
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
# 02/25/2005   J. Thiessen      New code. 
#
#
#*******************************************************************************
####----------------------------------------------------------------------------
####
####  The function purge_dir is the function that generates the before and 
####  after file listings of the current directory and deletes the files older 
####  than the number of days specified in $old between the listings.
####

purge_dir() {

output_prefix=${batch_working_directory}/FPA_purge.`echo ${PWD} |sed 's/\//_/g'`
echo "BEFORE PURGING DATA older than ${old} days in ${PWD} " >> ${output_prefix}.BeforeDelete.lst
ls -Altr  ${PWD} >> ${output_prefix}.BeforeDelete.lst
echo "THE BEFORE LIST ENDS HERE.\n\n\n" >> ${output_prefix}.BeforeDelete.lst

find ${PWD} \( -type d ! -name ${PWD##*/} -prune \) -o \( -type f -mtime +${old} -exec ls -l {} \; \)  > ${output_prefix}.DeletedFiles.lst 2>&1
find ${PWD} \( -type d ! -name ${PWD##*/} -prune \) -o \( -type f -mtime +${old} -exec rm -f {} \; \)  >> ${output_prefix}.DeletedFiles 2>&1  

echo "AFTER PURGING DATA older than ${old} days in ${PWD} " >> ${output_prefix}.PostDelete.lst
ls -Altr  ${PWD} >> ${output_prefix}.PostDelete.lst
echo "THE AFTER LIST ENDS HERE.\n\n\n" >> ${output_prefix}.PostDelete.lst

}  ####  END FUNCTION purge_dir

####----------------------------------------------------------------------------
####
####  The function touch_changecontrol_logs updates the timestamp on the
####  ${BATCH_ARCHIVE}/.saving_files${year}${month} files for the current
####  month and the previous month so that the purge process will not
####  remove these logs for at least two months.
####

touch_changecontrol_logs() {

year=`date +\%Y`
month=`date +\%m`
touch ${BATCH_ARCHIVE}/.saving_files${year}${month}
touch ${BATCH_ARCHIVE}/.moving-files-to-production${year}${month}
if [ "${month}" = "1" ];then
  month=12
  year=`expr ${year} - 1`
else
  month=`expr ${month} - 1`
fi
touch ${BATCH_ARCHIVE}/.saving_files${year}${month}
touch ${BATCH_ARCHIVE}/.moving-files-to-production${year}${month}

return 0

}  ####  END FUNCTION touch_changecontrol_logs


##########################################################################
#   main script                                                          #
##########################################################################

. ~/.FPAprofile     
. batchlog.ksh
. ksh_functions.ksh
NO_SUMMARY_MSGS=TRUE      
setlog ${batch_prg}.`date +'%Y%m%d'`
batchstart



my_uid=`whoami`
the_pid=${1:-ERROR}

sleep_interval=654
sleep_interval=6
all_done=no
loop_count=0

while [ ${all_done} ne 'yes' ]
do
  loop_count=`expr $loop_count + 1`
  sleep ${sleep_interval}
  psline=`ps -ef | sed 's/^  *//' | grep "^${my_uid}" |grep ${the_pid}bb`
  psline=`ps -ef | sed 's/^  *//' | grep "^${my_uid}" |cut -c1-29,38- |sort 


done

if [ ${#} -lt 2 ]
then
  msg="${batch_prg} ERROR -- USAGE: requires 'old' in days and a directory as arguments:-->${*}<--"
  batcherror_notify "${msg}"
fi
####
####  touch the change control log file for the current and previous month
####
touch_changecontrol_logs

####  
####  Definitions
####  
old=${1}
if [ ${old} -lt 0 ]; then
  msg="${batch_prg} ERROR: negative thresholds are not allowed ${old} "
  batcherror_notify "${msg}"
elif [ ${old} -gt 999 ]; then
  msg="${batch_prg} ERROR: threshold larger than 999 are not allowed ${old} "
  batcherror_notify "${msg}"
fi

shift               #  shift away the first argument, leaving only the list of directories.
set -A tdirs $@
counter=0
num_dirs=$#
err_count=0
error_message=""

messagelog "The ${num_dirs} dirs are: ${tdirs[*]}"

####  
####  JPT 20030818 allow expansion to accomodate variables in config files like FPA_purge40.dat
####  
## ## ## dirs=`eval echo "${tdirs[*]}"`
## ## ## num_dirs=${#tdirs[*]}
## ## ## messagelog "JUNK...The ${num_dirs} dirs are: ${dirs[*]}"

outputfile=${batch_working_directory}/FPA_purge.PREdisk_space
df -k > ${outputfile}

while [ ${counter} -lt ${num_dirs} ]
do
  dir=`eval echo "${tdirs[${counter}]}"`     ######## ${dirs[${counter}]}
  messagelog "PROCESSING dir ${counter}: ${dir}"
  cd ${dir}
  if [ ! -d ${dir} ]; then   #  is it a valid directory?
    error_message="ERROR: invalid directory ${dir} "
    messagelog "${error_message}"
    err_count=`expr ${err_count} + 1`
##  removed this elif section to allow "../" syntax in specifying the directories...
##  elif [ "${PWD}" != "${dir}" ]; then  #  did we successfully cd to the intended dir?
##    error_message="ERROR: unable to cd to ${dir}, skipping this directory. "
##    messagelog "${error_message}"
##    err_count=`expr ${err_count} + 1`
  else
    purge_dir 
    ret_stat=${?}
    if [ ${ret_stat} -ne 0 ]; then 
      error_message="ERROR: ${ret_stat} from purge_dir in ${dir} "
      messagelog "${error_message}"
      err_count=`expr ${err_count} + 1`
    fi
  fi
  counter=`expr ${counter} + 1`
done

outputfile=${batch_working_directory}/FPA_purge.POSTdisk_space
df -k > ${outputfile}

cd ${batch_working_directory}
tarname=FPA_purge.${LOGNAME}.`date +"%Y%m%d"`.${old}.tar
tar cvf ${tarname} *
tar tvf ${tarname} >> ${tarname}.lst
for x in `tar tf ${tarname}`
do
  rm ${x}
done

if [ ${err_count} -ne 0 ]; then
  batcherror_notify "ERROR -- there were ${err_count} errors in ${0} "
fi

batchend

