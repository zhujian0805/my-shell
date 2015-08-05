#!/bin/ksh
#--------------------------- COPYRIGHT NOTICE ----------------------------------
#*******************************************************************************
#
# Copyright (c) 2006 Perot Systems Corporation
# All Rights Reserved
# Copyright Notice Does Not Imply Publication
#
#*******************************************************************************
# SCCS_ID: %Z% %M% %I% %G%
#*******************************************************************************
#
#  NAME:               FPA_catfile.ksh
#
#  DESCRIPTION:        This script simply displays a specified file.  It is 
#                      designed to be run from the menu to interactively 
#                      display short files to the user. 
#
#  USAGE:              FPA_catfile.ksh fullpath_filename
#
#  EXT DATA FILES:
#
#  ENV VARIABLES:
#
#  INPUT:
#
#  OUTPUT:
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
# 2006/12/15   J Thiessen       New code.
#
# SCCS_COMMENT: Original code checkin.
#
#***    ALWAYS UPDATE THE SCCS_COMMENT BEFORE CHECKING THE CODE INTO SCCS     **
#*******************************************************************************

##########################################################################
#   main script                                                          #
##########################################################################

num_args=${#@}
if [ ${num_args} -ne 1 ]; then
  echo "ERROR -- USAGE:  FPA_catfile.ksh fullpath_filename "
  ret_code=1
else
  my_file=`eval echo ${1}`
  mywc=`echo ${my_file:-NoFile} | grep "^${BATCH_FTP:-DoesNotExist}" | wc -w`
  if [ ${mywc} -gt 0 -a -r ${my_file} ]; then 
    cat ${my_file}
  else
    echo "\n\n${RVON}ERROR:  Specified file is not accessible and may not exist -- ${my_file}${RVOF}"
  fi
fi
return ${ret_code:-1}

