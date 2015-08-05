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
#  NAME:               FPA_audit_extract.ksh
#
#  DESCRIPTION:        Extract files and various FPA information to be used for
#                      audit purposes.
#  
#  EXT DATA FILES:     
#
#  ENV VARIABLES:   
#   
#  INPUT:              List of directories in ${BATCH_ETC}/FPA_audit_extract.dat
#
#  OUTPUT:             Files sent to asp audit directories
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
# 12/21/2005   R. Crawford      New code. 
#
#*******************************************************************************
#
# Remove Directories for monitoring
#
remove_dir() {
cat ${excude_file} |
while read modify
do
  grep -v "^`eval echo "${modify}"`" Mod_Dir_List.dat > tmp.list
  #grep -v "^${modify}" Mod_Dir_List.dat > tmp.list
  ret_stat=${?}
  if [ ${ret_stat} -ne 0 ]; then 
    error_message="ERROR: failed to remove directories from file. Record: ${modify}"
    messagelog "${error_message}"
    err_count=`expr ${err_count} + 1`
  fi
  mv tmp.list Mod_Dir_List.dat
done
} ####END FUNCTION remove_dir

#
# Copy directories
#
copy_directories() {

outputfile=${batch_working_directory}/FPA_audit_extract.PREdisk_space
df -k > ${outputfile}

cat Mod_Dir_List.dat | 
while read copy
do
  dir=`eval echo "${copy}"`     ######## ${dirs[${counter}]}
  messagelog "PROCESSING dir ${copy}"
  cd ${dir}
  if [ ! -d ${dir} ]; then   #  is it a valid directory?
    error_message="ERROR: invalid directory ${dir} "
    messagelog "${error_message}"
    err_count=`expr ${err_count} + 1`
  else
    dest_dir="/asp/aspftp/FPA_client_config/"`pwd | cut -c6-`
    cd ${dest_dir}
    if [ ! -d ${dest_dir} ]; then
      mkdir -p ${dest_dir}
      error_message="ERROR: invalid directory ${dest_dir}. Check for creation. "
      messagelog "${error_message}"
      err_count=`expr ${err_count} + 1`
    else
      cd ${dir}
      ls -la >${dest_dir}/dirList.lst
      find . \( -type d ! -name . -prune \) -o \( -type f -print \) -exec cp {} ${dest_dir} \;
      ret_stat=${?}
      if [ ${ret_stat} -ne 0 ]; then 
        error_message="ERROR: ${ret_stat} from audit_extract in ${dir} "
        messagelog "${error_message}"
        err_count=`expr ${err_count} + 1`
      fi
    fi
  fi
done

} ####  END FUNCTION copy_directories 

#
# Copy cron and base config files
#
cron_config_copy() {

cd ${BATCH_HOME}
dest_dir="/asp/aspftp/FPA_client_config/"`pwd | cut -c6-`"/config"
crontab -l > ${dest_dir}/crontab.COPY
cd ..
cp .*profile* ${dest_dir}/.
env > ${dest_dir}/ENV.dat

} ### END FUNCTION cron_config_copy
###############################################################################
# main script
###############################################################################
. ~/.FPAprofile
. batchlog.ksh
batchsync_filename="SYNC.${batch_prg}"
NO_SUMMARY_MSGS=TRUE      
setlog ${batch_prg}.`date +'%Y%m%d'`
batchstartsync

excude_file=${1}
err_count=0
error_message=""

#if [ ${#} -lt 1 ]
#then
#  msg="${batch_prg} ERROR -- USAGE: requires a directory as arguments:-->${*}<--"
#  batcherror_notify "${msg}"
#fi
outputfile=${batch_working_directory}/FPA_audit_extract.POSTdisk_space

find ${BATCH_ROOT} -type d > ${BATCH_ROOT}/Full_Dir_List.dat
cp ${BATCH_ROOT}/Full_Dir_List.dat Mod_Dir_List.dat

remove_dir

cp Mod_Dir_List.dat ${BATCH_ROOT}/Mod_Dir_List.dat
cd ${BATCH_ROOT}
cp Mod_Dir_List.dat "/asp/aspftp/FPA_client_config/"`pwd | cut -c6-`"/Mod_Dir_List.dat"

cron_config_copy

copy_directories

df -k > ${outputfile}
if [ ${err_count} -ne 0 ]; then
  batcherror_notify "ERROR -- there were ${err_count} errors in ${0} "
fi

batchend
