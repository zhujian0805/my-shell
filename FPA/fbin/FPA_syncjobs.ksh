#!/bin/ksh
#--------------------------- COPYRIGHT NOTICE ----------------------------------
#*******************************************************************************
#
# Copyright (c) 2000 Perot Systems Corporation 
# All Rights Reserved
# Copyright Notice Does Not Imply Publication
#
#*******************************************************************************
# SCCS_ID: @(#) FPA_syncjobs.ksh 1.5 02/25/00
#*******************************************************************************
#
#  NAME:               FPA_syncjobs.ksh
#
#  DESCRIPTION:        This script is designed to be used within the FPA in
#                      order to monitor for successful completion of multiple
#                      batch jobs or conditions before creating a flag-file 
#                      that will cause the FPA to initiate another batch job.
#                      This script requires 2 positional arguments.  
#
#                      The first argument is the name of the control file,
#                      stored in BATCH_ETC, that contains both the list of 
#                      prerequisite flag-files that must exist before creating 
#                      a new flag-file AND the name of the flag-file to be 
#                      created in $BATCH_FLAGS when each of the prerequisites 
#                      have been fulfilled.  
#
#                      The second argument is the name of the flag-file that 
#                      needs to be added to the list of completed requirements
#                      for the specified control file.  
#
#                      It is an error to call this script without proper 
#                      arguments.
#
#  
#  EXT DATA FILES:     *.FPAsync_ctl is the control file located in BATCH_ETC that 
#                      contains two data elements along with comments as
#                      desired.  The first element is the name of a flag-file 
#                      that needs to be created when multiple conditions are
#                      satisfied.  The second element is the list of 
#                      flag-files that will be created to indicate that all
#                      is time to create the flag file (element number one).
#                      The name of this file must be provided as the first
#                      argument when calling this script.  
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
# 01/07/2000   J. Thiessen      New code. 
#
#
# SCCS_COMMENT: Original code checkin.
#
#***    ALWAYS UPDATE THE SCCS_COMMENT BEFORE CHECKING THE CODE INTO SCCS     **
#*******************************************************************************

HERE    HERE HERE HERE HERE HERE HERE


####---------------------------------------------------------------------------
####
####  The function My_Batcherror_Notify cleans up the lockfile before 
####  calling the standard batcherror_notify function.
####
My_Batcherror_Notify()
{
if [ -a ${lockfile} ]
then
  rm -f ${lockfile}
fi
 
batcherror_notify "${msg}"

}  ####  END FUNCTION My_Batcherror_Notify

####---------------------------------------------------------------------------
####
####  The function My_Batcherror cleans up the lockfile before calling the
####  standard batcherror function.
####
My_Batcherror()
{
if [ -a ${lockfile} ]
then
  rm -f ${lockfile}
fi
 
batcherror "${msg}"

}  ####  END FUNCTION My_Batcherror

####---------------------------------------------------------------------------
####
####  The function If_Last_Flagfile logs the activity and creates the next 
####  flagfile.  It is called if $syncfile is now completed.  
#### 
####  Extract the name of the new flagfile to be created.  Note that the
####  must be only one line in the control file containing the string:
####  "MAKE FLAGFILE:" and that the only non-space characters following 
####  the only colon in the line must be the name of the flag-file to 
####  be created when all of the flagfiles listed in the this control
####  file are ready.  
####

If_Last_Flagfile()
{

####  
####  Obtain the name of the next flagfile.
####
next_flag=`grep "MAKE FLAGFILE:" ${my_cntrl} |cut -d: -f2 |sed "s/  *//g"`
  if [ $? -ne 0 -o ${#next_flag} -eq 0 ]                       
  then                                                         
    msg="No MAKE FLAGFILE: in ${my_cntrl} or READ ERROR"       
    My_Batcherror_Notify "${msg}"                                 
  fi                                                           

####
####  Create the next flagfile.
#### 

cp ${syncfile} ${BATCH_FLAGS}/${next_flag}
  if [ $? -ne 0 ]                                              
  then                                                         
    msg="Unable to create flagfile ${next_flag}."              
    My_Batcherror_Notify "${msg}"                                 
  fi                                                           

####
####  Write status and $syncfile out to logfile.
####
msg="Completed synchronizing ${my_cntrl}, created ${next_flag}"
messagelog "${msg}"
messagelog "START OF SYNCFILE LISTING"
cat ${syncfile} >> ${batch_log}
messagelog "END OF SYNCFILE LISTING"

####
####  Now remove the syncfile.
####
FPA_datetimestamp=`date +\%Y\%m\%d\%H\%M\%S`

mv ${syncfile} ${syncfile}.${FPA_datetimestamp}
    if [ $? -ne 0 ]
    then
      msg="Unable to move syncfile ${syncfile}"
      My_Batcherror_Notify "${msg}"
    fi


}  ####  END FUNCTION If_Last_Flagfile

##########################################################################
#   main script                                                          #
##########################################################################

. /export/home/fpabatch/.profile     
. batchlog.ksh
batchstart


my_cntrl="${BATCH_ETC}/${1}"
my_flag="${2}"
lockfile="${BATCH_TMP}/${1}.lock"
syncfile="${BATCH_TMP}/${1}.syncing"

num_args=${#}

if [ ${num_args} -lt 2 ]
then
  msg="${batch_prg} ERROR -- Improper arguments:-->${*}<--"
  My_Batcherror_Notify "${msg}"
fi

if [ ${num_args} -gt 2 ]
then
  sync_file_message="####${3}"
fi
if [ ${num_args} -gt 3 ]
then
  sync_file_message="${sync_file_message}\n####${4}"
fi
if [ ${num_args} -gt 4 ]
then
  sync_file_message="${sync_file_message}\n####${5}"
fi

####
####  Confirm that the configuration file exists.
####

if [ ! -a ${my_cntrl} ]
then
  msg="FPA failure in ${batch_prg} : control file ${my_cntrl} does not exist" 
  My_Batcherror_Notify "${msg}"
fi

####  
####  Check to be sure that $my_flag is listed in the control file.  Exit
####  with an error if $my_flag is NOT listed in the control file.
####  Note that $my_flag must be the only item on the line in the control
####  file--any extra spaces or characters will cause the line to be ignored.
####  But Comment lines beginning with the pound sign, #, are allowed in 
####  the control files and are automatically written in the syncing file.
####
num_matches=`grep '^'"${my_flag}"'$' "${my_cntrl}" |wc -l`
if [ ${num_matches} -ne 1 ]
then
  msg="${batch_prg}: Called to insert flag, ${my_flag}, but"
  msg="${msg} it is not defined in ${my_cntrl}."
  My_Batcherror_Notify "${msg}"
fi

####
####  Be sure that no other process is updating the syncfile.
####
my_lock=0
wait_count=0
max_wait_count=4
while [ ${wait_count} -lt ${max_wait_count} ]
do
  if [ -a ${lockfile} ]
  then
    wait_count=`expr ${wait_count} + 1`
    sleep 4
  else
    echo "PID $$ locking ${syncfile} at `date`" >> ${lockfile}
    wait_count=`expr ${max_wait_count} + 1`
    my_lock=1
  fi
done

####
####  Exit if the control file is locked too long.
####  
if [ ${my_lock} -eq 0 ]
then
  msg="${batch_prg} excessive delay, ${max_wait_count}, for ${lockfile}"
  My_Batcherror_Notify "${msg}"
fi

####
####  If $syncfile does not exist, then this is the first flagfile to be 
####  completed so create the $syncfile. 
####
if [ ! -a ${syncfile} ]
then
  echo "####  First flagfile, ${my_flag}, available at `date`" > ${syncfile}
  if [ ! -a ${syncfile} ] 
  then
    msg="Unable to create syncfile, ${syncfile}. FLAG: ${my_flag}. "
    My_Batcherror_Notify "${msg}"
  fi
fi

####  
####  Check to see if $my_flag already exists in $syncfile.  If so, 
####  write an error message in the syncfile and exit with and error.
####  
num_matches=`grep '^'"${my_flag}"'$' "${syncfile}" |wc -l`
if [ ${num_matches} -ne 0 ]
then
  msg="${batch_prg} Called to insert flag, ${my_flag}, but"
  msg="${msg} it already exists in ${syncfile}."
  echo "####  ERROR -- ${msg}" >> ${syncfile}
  My_Batcherror_Notify "${msg}"
fi

####  
####  Add the current flagfile to the syncfile along with a comment
####  indicating the time that this flagfile was added.
####  
echo "${my_flag}" >> ${syncfile}
if [ $? -ne 0 ]
then
  msg="Unable to add flag ${my_flag} to ${syncfile}."
  My_Batcherror_Notify "${msg}" 
fi
if [ ${num_args} -gt 2 ]
then
  echo "${sync_file_message}" >> ${syncfile}
  if [ $? -ne 0 ]
  then
    msg="Unable to add sync_file_message ${sync_file_message} to ${syncfile}."
    My_Batcherror_Notify "${msg}" 
  fi
fi
msg="####  Flag-file ${my_flag} was inserted in ${syncfile} at `date`" 
echo "${msg}" >> ${syncfile}
if [ $? -ne 0 ]
then
  msg="Unable to add flag ${my_flag} to ${syncfile}."
  My_Batcherror "${msg}"
fi
messagelog "${msg}"

####
####  Check to see if all of the required flag-files have been added
####  to $syncfile.  
####
num_needed=`cat ${my_cntrl} |grep -v '^#' |wc -l`   
    if [ ! -r ${my_cntrl} ]                                      
    then                                                        
      msg="Unable to determine num_needed in ${my_cntrl}."       
      My_Batcherror_Notify "${msg}"                                
    fi                                                           

num_ready=`cat ${syncfile} |grep -v '^#' |wc -l`  
    if [ ! -r ${syncfile} ]                                      
    then                                                        
      msg="Unable to determine num_ready in ${syncfile}."       
      My_Batcherror_Notify "${msg}"                              
    fi                                                       

if [ ${num_ready} -gt ${num_needed} ]
then                                                             
  msg="Too many flagfiles, ${num_ready}, in ${syncfile}."        
  My_Batcherror_Notify "${msg}"                                     
fi                                                               

if [ ${num_ready} -eq ${num_needed} ]
then
  If_Last_Flagfile
fi

####
####  Now the flagfile has been added to $syncfile and if $syncfile
####  is complete, the next flagfile has been created.  So remove
####  the lockfile.
####
rm -f ${lockfile}
    if [ $? -ne 0 ]                                              
    then                                                         
      msg="Unable to remove lockfile ${lockfile}"
      My_Batcherror_Notify "${msg}"                                 
    fi                                                           


batchend


