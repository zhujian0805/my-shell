#!/bin/ksh
#--------------------------- COPYRIGHT NOTICE ----------------------------------
#*******************************************************************************
#
# Copyright (c) 2000 Perot Systems Corporation 
# All Rights Reserved
# Copyright Notice Does Not Imply Publication
#
#*******************************************************************************
# SCCS_ID: @(#) FPA_semaphore.ksh 1.5 02/25/00
#*******************************************************************************
#
#  NAME:               FPA_semaphore.ksh
#
#  DESCRIPTION:        This script is designed to be used within the FPA in
#                      order to monitor for successful completion of multiple
#                      batch jobs or conditions before creating a flag-file 
#                      that will cause the FPA to initiate another batch job.
#                      This script requires at least 2 positional arguments, 
#                      subsequent arguments are included in the semaphore file 
#                      as a means of passing information to subsequent 
#                      processes.  
#
#                      The first argument is the name of the control file,
#                      stored in BATCH_ETC, that contains both the list of 
#                      prerequisite flag-files which must exist before creating 
#                      a new flag-file AND the name of the flag-file to be 
#                      created in $BATCH_FLAGS when each of the prerequisites 
#                      have been fulfilled.  
#
#                      The second argument is the name of the flag-file that 
#                      needs to be added to the list of completed requirements
#                      for the specified control file.  
#
#                      The third and subsequent arguments are included in 
#                      the semaphore file as a means of passing information 
#                      to subsequent processes.  
#
#                      It is an error to call this script without proper 
#                      arguments.
#
#  
#  EXT DATA FILES:     *.FPAsemaphore is the file located in BATCH_ETC that 
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
# 2000/01/07   J. Thiessen      Original code.
# 2003/03/20   J. Thiessen      New version
#
#
# SCCS_COMMENT: Original code checkin.
#
#***    ALWAYS UPDATE THE SCCS_COMMENT BEFORE CHECKING THE CODE INTO SCCS     **
#*******************************************************************************



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
####  flagfile.  It is called if $semaphore is now completed.  
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
next_flag=`grep "MAKE FLAGFILE:" ${my_cntrl} |tail -1 |cut -d: -f2 |sed "s/  *//g"`
  if [ $? -ne 0 -o ${#next_flag} -eq 0 ]                       
  then                                                         
    msg="No MAKE FLAGFILE: in ${my_cntrl} or READ ERROR"       
    My_Batcherror_Notify "${msg}"                                 
  fi                                                           

####
####  Create the flagfile, append without error if it already exists.
#### 
cat ${semaphore} >> ${BATCH_FLAGS}/${next_flag} 
if [ $? -ne 0 ]                                              
then                                                         
  msg="Unable to create flagfile ${next_flag}."              
  My_Batcherror_Notify "${msg}"                                 
fi                                                           

####
####  Write status and $semaphore out to logfile.
####
msg="Completed requirements in ${my_cntrl}, created ${next_flag}"
messagelog "${msg}"
messagelog "START OF SEMAPHORE LISTING"
cat ${semaphore} >> ${batch_log}
messagelog "END OF SEMAPHORE LISTING"

####
####  Now move the semaphore to the archive subdirectories.
####
FPA_datetimestamp=`date +\%Y\%m\%d\%H\%M\%S`

##### JPT 20050131 removed.  I think this was a comment...  ${1%/*}/archive/${1##*/}
cp ${semaphore} ${semaphore%/*}_archive/${semaphore##*/}.${FPA_datetimestamp}
if [ $? -ne 0 ]; then
  msg="Unable to copy semaphore ${semaphore} to archive"
  My_Batcherror_Notify "${msg}"
fi
mv ${semaphore} ${BATCH_ARCHIVE}/${semaphore##*/}.ID`get_run_seq OUTPUT_ID.SEQ`
if [ $? -ne 0 ]; then
  msg="Unable to move semaphore ${semaphore} to ${BATCH_ARCHIVE}"
  My_Batcherror_Notify "${msg}"
fi


}  ####  END FUNCTION If_Last_Flagfile

##########################################################################
#   main script                                                          #
##########################################################################
. ~/.FPAprofile
. batchlog.ksh
. ksh_functions.ksh               #  READS THE DATE AND RUN_SEQUENCE FUNCTIONS
NO_OUTPUT="TRUE"        ## only for FPA itself, do not create a working directory
NO_SUMMARY_MSGS=TRUE    ## set this variable only for the FPA itself
APPEND_LOG_FILE=TRUE    ## set this variable only for the FPA itself
setlog ${batch_prg}.`date +'%Y%m%d'`
batchstart

if [ ${#} -lt 2 ]
then
  msg="${batch_prg} USAGE: ${batch_prg} control_file flag [ comments ] -- Improper arguments:-->${*}<--"
  My_Batcherror_Notify "${msg}"
fi

my_cntrl="${BATCH_ETC}/${1}"
my_flag="${2}"
lockfile="${BATCH_TMP}/${1}.lock"
semaphore="${BATCH_TMP}/${1}.semaphore"

shift 2
while [ ${#} -gt 0 ]
do
  semaphore_message="${semaphore_message:-}${semaphore_message:+\n}##MSG## ${1}"
  shift
done

####
####  Confirm that the configuration file exists.
####
if [ ! -a ${my_cntrl} ]
then
  msg="FPA failure in ${batch_prg} : control file ${my_cntrl} does not exist" 
  My_Batcherror_Notify "${msg}"
fi

####  Check to be sure that $my_flag matches a template in the control file.  Exit
####  with an error if $my_flag does NOT match the control file.
####  Note that $my_flag must be the only item on the line in the control
####  file--any extra spaces or characters will cause the line to be ignored.
####  But Comment lines beginning with the pound sign, #, are allowed in 
####  the control files and are automatically written in the semaphore file.
####  ** WRITE LOGIC TO MATCH ON WILDCARDS IN THE CONTROL FILE, WHILE RECORDING THE SPECIFIC FILE IN THE SEMAPHORE FILE.
####  ** RECORD THE CTL LINE IN THE SEMAPHORE FILE FOR EACH MATCH, THEN QUERY FOR IT TO CHECK FOR DUPLICATE ENTRIES
num_matches=0
unset found
for x in `grep -v "^#" ${my_cntrl}`
do
  found=`echo ${my_flag} | grep ${x}`
  if [ ${#found} -gt 0 ]; then
    num_matches=1
    break
  fi
done
if [ ${num_matches} -eq 0 ]; then
  msg="${batch_prg}: Called to insert flag, ${my_flag}, but"
  msg="${msg} it is not matched in ${my_cntrl}."
  My_Batcherror_Notify "${msg}"
fi
matching_template=${x}   # The control file template that matches this specific flag.
matching_string="# MATCHED ${x}"   # The control file template that matches this specific flag.

####
####  Be sure that no other process is updating the semaphore.
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
    echo "PID $$ locking ${semaphore} at `date`" >> ${lockfile}
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
####  If $semaphore does not exist, then this is the first flagfile to be 
####  completed so create the $semaphore. 
####
if [ ! -a ${semaphore} ]
then
  echo "####  First flagfile, ${my_flag}, available at `date`" >> ${semaphore}
  if [ ! -a ${semaphore} ] 
  then
    msg="Unable to create semaphore, ${semaphore}. FLAG: ${my_flag}. "
    My_Batcherror_Notify "${msg}"
  fi
fi

####  
####  Check to see if $my_flag already exists in $semaphore.  If so, 
####  write an error message in the semaphore and exit with an error.
####  
num_matches=`grep '^'"${my_flag}"'$' "${semaphore}" |wc -l`
num_prev_matches=`grep "^${matching_string}" ${semaphore} | wc -l`
if [ ${num_prev_matches} -ne 0 ]
then
  msg="${batch_prg} Called to insert flag, ${my_flag}, but"
  msg="${msg} template ${matching_template} was previously matched in ${semaphore}."
  echo "####  ERROR -- ${msg}" >> ${semaphore}
  My_Batcherror_Notify "${msg}"
fi

####  
####  Add the current flagfile to the semaphore along with a comment
####  indicating the time that this flagfile was added.
####  
echo "${my_flag}" >> ${semaphore}
if [ $? -ne 0 ]
then
  msg="Unable to add flag ${my_flag} to ${semaphore}."
  My_Batcherror_Notify "${msg}" 
fi
if [ ${#semaphore_message} -gt 0 ]
then
  echo "${semaphore_message}" >> ${semaphore}
  if [ $? -ne 0 ]
  then
    msg="Unable to add semaphore_message ${semaphore_message} to ${semaphore}."
    My_Batcherror_Notify "${msg}" 
  fi
fi
msg="${matching_string} | with flag-file | ${my_flag} | Inserted in | ${semaphore} | at | `date`" 
echo "${msg}" >> ${semaphore}
if [ $? -ne 0 ]
then
  msg="Unable to add flag ${my_flag} to ${semaphore}."
  My_Batcherror "${msg}"
fi
messagelog "${msg}"

####
####  Check to see if all of the required flag-files have been added
####  to $semaphore.  
####
num_needed=`cat ${my_cntrl} |grep -v '^#' |wc -l`
    if [ ! -r ${my_cntrl} ]    # JPT 20050128 Changed error checking...
    then                                                        
      msg="Unable to determine num_needed in ${my_cntrl}."       
      My_Batcherror_Notify "${msg}"                                
    fi                                                           

num_ready=`cat ${semaphore} |grep -v '^#' |wc -l`  
    if [ ! -r ${semaphore} ]   # JPT 20050128 Changed error checking...
    then                                                        
      msg="Unable to determine num_ready in ${semaphore}."       
      My_Batcherror_Notify "${msg}"                              
    fi                                                       

if [ ${num_ready} -gt ${num_needed} ]
then                                                             
  msg="Too many flagfiles, ${num_ready}, in ${semaphore}."        
  My_Batcherror_Notify "${msg}"                                     
fi                                                               

if [ ${num_ready} -eq ${num_needed} ]
then
  If_Last_Flagfile
fi

####
####  Now the flagfile has been added to $semaphore and if $semaphore
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
