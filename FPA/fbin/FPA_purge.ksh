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
#  NAME:               FPA_purge.ksh
#
#  DESCRIPTION:        This script will delete old files from specified 
#                      directories where the definition of old is specified 
#                      as the first parameter and the directories are specified 
#                      as subsequent directories.  
#  
#  EXT DATA FILES:     The JobCard file which contains the instructions for
#                          running a job.
#                      JobList.processing in $BATCH_TMP contains the list 
#                          of JobCards being processed. (only exists while 
#                          this job is running.)
#                      JobList.previous in $BATCH_TMP contains the previous 
#                          list of JobCards.  This list updated only when 
#                          the list JobList changes, not every run.  
#                      JobList.most_recent in $BATCH_TMP contains the list 
#                          of JobCards from the most recent prior run.  This 
#                          list updated at the end of every run.
#                      JobList.diff in $BATCH_TMP contains the differences 
#                          between JobList.processing and JobList.previous 
#                          and is overwritten during each run.
#
#  ENV VARIABLES:   
#   
#  INPUT:            
#
#  OUTPUT:            For each directory specified on the command line this 
#                     program will create the three files listed below:
#                     1.  A file listing (ls -Altr) the directory BEFORE the purge 
#                     2.  A file listing All files that were deleted
#                     3.  A file listing (ls -Altr) the directory AFTER the purge 
#                     The filename syntax is FPA_purge.<dir>.<type>.lst where
#                     <dir> is the directory being purged with slashes 
#                     replaced by underscores and <type> is "BeforeDelete", 
#                     "DeletedFiles", or "PostDelete".
#                     All of these files are placed in one tar file, so the only
#                     actual output files are the tar file and a file listing 
#                     the contents of the tarfile 
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
# 05/16/2002   J. Thiessen      New code. 
# 12/16/2002   J. Thiessen      Added line recording the free disk space.
# 06/18/2003   J. Thiessen      Now using tar to reduce the number of output
#                               files.  
# 12/27/2005   J. Thiessen      Improved the directory validation.  
# 02/21/2006   J. Thiessen      Uses env var instead of full dir in name of list file. 
# 03/27/2006   J. Thiessen      Fixed problem with env var in name of list file. 
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

####
####  Need to shorten the length of output_prefix, use parameter if supplied...
####  
if [ ${#*} -gt 0 ];then
  output_prefix=${batch_working_directory}/FPA_purge.`echo ${1} |sed 's/\//_/g' |sed 's/_//'`
else
  output_prefix=${batch_working_directory}/FPA_purge.`echo ${PWD} |sed 's/\//_/g' |sed 's/_//'`
fi
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
batchsync_filename="SYNC.${batch_prg}"
NO_SUMMARY_MSGS=TRUE      
setlog ${batch_prg}.`date +'%Y%m%d'`
batchstartsync

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

outputfile=${batch_working_directory}/FPA_purge.PREdisk_space
df -k > ${outputfile}

while [ ${counter} -lt ${num_dirs} ]
do
  dir=`eval echo "${tdirs[${counter}]}"`     ######## ${dirs[${counter}]}
  messagelog "PROCESSING dir ${counter}: ${dir}"
  if [ ! -d ${dir} ]; then   #  is it a valid directory?
    error_message="ERROR: invalid directory ${dir} "
    messagelog "${error_message}"
    err_count=`expr ${err_count} + 1`
  else
    ## JPT 20060221  use env var without $ and {} as to shorten dir name.  
    short_dirname=`echo ${tdirs[${counter}]} |sed 's/\.\.\///g' |sed 's/\${//g' |sed 's/:-UNDEFINED}//g' |sed 's/\$//g' |sed 's/{//g' |sed 's/}//g' |sed 's/://g' |sed 's/\#//g' |sed 's/\*//g' |sed 's/\%//g' `
    cd ${dir}
    purge_dir ${short_dirname:-}
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

