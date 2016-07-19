#!/bin/ksh
#--------------------------- COPYRIGHT NOTICE ----------------------------------
#*******************************************************************************
#
# Copyright (c) 2009 Perot Systems Corporation
# All Rights Reserved
# Copyright Notice Does Not Imply Publication
#
#*******************************************************************************
#
#  NAME:               get_file_info.ksh
#
#  DESCRIPTION:        This script contains additional, client-specific
#                      functions for use in korn shell scripts.  This allows
#                      specific FPA implementations to add ksh functions.
#                      If ksh_functions_custom.ksh exists in BATCH_BIN of
#                      a specific FPA implementation then the
#                      ksh_functions.ksh script will source it to includes
#                      the custom functions.
#
#
#*******************************************************************************
# Date         Programmmer      Description
# ----------   --------------   ------------------------------------------
# 2009-11-20   J. Thiessen      Created
#
#*******************************************************************************

####----------------------------------------------------------------------------
####
####  The file_info function creates a file containing information about 
####  the file specified in parameter 1.  This MetaData file has the same name 
####  as the file in parameter 1 with a prefix of "FileInfo." and is created in 
####  the directory specified in parameter 2 or in $BATCH_OUTPUT if there is 
####  only one parameter.  
####  This information is also appended to the daily log file, 
####  FileInfo.log.YYYYMMDD in $BATCH_LOGS. 
####
f_file_info ()
{

  infile=${1:-file_info_requires_a_parameter}
  outdir=${2:-${BATCH_OUTPUT}}
  if [ -d ${outdir} ];then
    if [ -r ${infile} ];then
      outfile="${outdir}/FileInfo.${infile##*/}"
      a="The following describes the file  ${infile##*/}"
      b="File Name:     ${infile##*/}"
      line=$(ls -F --full-time ${infile})
      c=$( echo $line | awk '{print "Created on "$6" at " $7 " in Time Zone " $8 " from GMT"}' )
      d=$( echo $line | awk '{print "Created by: " $3 }' )
      line=$(uname -a )
      e=$( echo $line | awk '{print "On system: " $2  }' )
      line=$(cksum  ${infile} )
      f=$( echo $line | awk '{print "Checksum: " $1 }' )
      line=$(wc  ${infile} )
      g=$( echo $line | awk '{print "Bytes: " $3 }' )
      h=$( echo $line | awk '{print "Words: " $2 }' )
      i=$( echo $line | awk '{print "Lines: " $1 }' )
      echo $a  >> ${outfile}
      ## echo "\n"  >> ${outfile}
      echo $b  >> ${outfile}
      ## echo "\n"  >> ${outfile}
      echo $c  >> ${outfile}
      ## echo "\n"  >> ${outfile}
      echo $d  >> ${outfile}
      ## echo "\n"  >> ${outfile}
      echo $e  >> ${outfile}
      ## echo "\n"  >> ${outfile}
      echo $f  >> ${outfile}
      ## echo "\n"  >> ${outfile}
      echo $g  >> ${outfile}
      ## echo "\n"  >> ${outfile}
      echo $h  >> ${outfile}
      ## echo "\n"  >> ${outfile}
      echo $i  >> ${outfile}
      ## echo "\n"  >> ${outfile}
    fi
  fi
  if [ -r  ${outfile} ];then
    cat ${outfile} >> ${BATCH_LOGS}/FileInfo.log.$(date +'%Y%m%d')
  else
    return 1
  fi

}  ####  END FUNCTION f_file_info

##########################################################################
#   main script                                                          #
##########################################################################
. ~/.FPAprofile
. batchlog.ksh
APPEND_LOG_FILE=TRUE    ## Do not export
setlog ${batch_prg}.$(date +'%Y%m%d')

batchstart
if [ $# -lt 1 ]; then
  msg="Usage:  'get_file_info.ksh <filename> ' or 'get_file_info.ksh <filename> <output_directory>' "
  batcherror "${msg} "
fi

p2=${2:-${BATCH_OUTPUT}}
f_file_info ${1} ${p2}
ReturnCode=$?

if [ "${ReturnCode}" != "0" ]; then
  msg="ERROR:  ${batch_prg} was unable to analyze file ${1}"
  batcherror "${msg} "
fi

batchend

