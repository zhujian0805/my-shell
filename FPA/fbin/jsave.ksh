#!/bin/ksh
#--------------------------- COPYRIGHT NOTICE ----------------------------------
#*******************************************************************************
#
# Copyright (c) 2006 Perot Systems Corporation
# All Rights Reserved
# Copyright Notice Does Not Imply Publication
#
#*******************************************************************************
#
#  NAME:               jsave.ksh
#
#  DESCRIPTION:        Script to archive files into `pwd`_archive directory. 
#                      Files must be specified as parameters.  Echoes status
#                      messages to the screen.  
#   
#*******************************************************************************
# Date         Programmmer      Description
# ----------   --------------   ------------------------------------------
# 07/11/2006   J Thiessen       Now skips archive if parameter is a directory
#
#*******************************************************************************


dtm=`date +\%Y\%m\%d\%H\%M\%S`
yearmo=`date +\%Y\%m`
logfile=${BATCH_ARCHIVE:-.}/.saving_files${yearmo}

if [ ${#} -lt 1 ]; then
  echo "USAGE:  jsave.ksh 'filename(s) to be saved'\n"
  return 3
fi

my_arc_dir="`pwd`_archive"
if [ "`pwd`" = "`echo ~`" ]
then
  my_arc_dir=homedir_archive
fi
if [ ! -d ${my_arc_dir} ]; then
  echo "ERROR:  no '[dir]_archive' sister-directory: ${my_arc_dir}"
  return 4
fi

echo "STARTING at ${dtm}" >> ${logfile}
echo "SAVING files from ${PWD} to ${my_arc_dir}" >> ${logfile}
echo "Enter a comment and press <return> "
read my_comment
echo "processing..."
echo "COMMENT: ${my_comment}" >> ${logfile}

echo ${dtm}
echo ${*}
set -A files ${*}
echo "files ${#files[*]}"
echo "file 0:${files[0]}"
echo "file 1:${files[1]}"
echo "file 2:${files[2]}"
echo "file 3:${files[3]}"
echo "file 4:${files[4]}"

let total=${#files[*]}
let count=0
while [ count -lt ${total} ]
do 
  echo $count
  if [ -d ${files[${count}]} ];then
    echo "    WARNING:  $0 archives files only, not directories.  "
    echo "    WARNING:  ${files[${count}]} is a directory and will be skipped. "
  elif [ -r ${files[${count}]} ];then
    cp -p ${files[${count}]} ${my_arc_dir}/${files[${count}]}.${dtm}
    cp -pf ${files[${count}]} ${my_arc_dir}/${files[${count}]}  ## overwrite the current file in my_arc_dir
    echo "    ARCHIVED: ${files[${count}]} " >> ${logfile}
    echo "    ARCHIVED: ${files[${count}]} " 
  else
    echo "Cannot find ${files[${count}]}"
    echo "    CANNOT ARCHIVE: ${files[${count}]} " >> ${logfile}
    echo "**********>>>> ERROR    CANNOT ARCHIVE: ${files[${count}]} " 
  fi
  let count=${count}+1
done

echo "jsave DONE\n" >> ${logfile}
echo "jsave DONE"
