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
#  NAME:               ksh_functions_custom.ksh
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
# 2009-11-20   J. Thiessen      First custom function is file_info - will be core
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
file_info ()
{
  infile=${1:-file_info_requires_a_parameter}
  outdir=${2:-${BATCH_OUTPUT}}
  if [ -d ${outdir} ];then
    
    if [ -r ${infile} ];then
      outfile="${outdir}/FileInfo.${infile##*/}"
      a="The following describes the file  ${infile##*/}"
      b="File Name:     ${infile##*/}"
      line=$(ls -F --full-time ${infile})
      c=$( echo $line  | awk '{print "Created on "$6" at " $7 " in Time Zone " $8 " from GMT"}' )
      d=$( echo $line  | awk '{print "Created by: " $3 }' )
      e="On system: ${HOSTNAME}"
      line=$(cksum  ${infile} )
      f=$( echo $line | awk '{print "Checksum: " $1 }' )
      line=$(wc  ${infile} )
      g=$( echo $line | awk '{print "Bytes: " $1 }' )
      h=$( echo $line | awk '{print "Words: " $2 }' )
      i=$( echo $line | awk '{print "Lines: " $3 }' )
      echo $a  >> ${outfile}
      echo $b  >> ${outfile}
      echo $c  >> ${outfile}
      echo $d  >> ${outfile}
      echo $e  >> ${outfile}
      echo $f  >> ${outfile}
      echo $g  >> ${outfile}
      echo $h  >> ${outfile}
      echo $i  >> ${outfile}
    fi
  fi
  if [ -r  ${outfile} ];then
    cat ${outfile} >> ${BATCH_LOGS}/FileInfo.log.$(date +'%Y%m%d')
  else
    return 1
  fi

}  ####  END FUNCTION file_info


