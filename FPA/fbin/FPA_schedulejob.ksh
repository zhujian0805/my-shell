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
#  NAME:               FPA_schedulejob.ksh
#
#  DESCRIPTION:        This script is designed to be used within the FPA in
#                      order to use cron to schedule jobs to be initiated by 
#                      the automation.  This method is prefered over using 
#                      cron to directly start a batch process for several 
#                      reasons:
#                      1.  The job can be scheduled to run early in the day 
#                          so the users can verify that the job is scheduled 
#                          to run.
#                      2.  The users can cancel the run without PSC interaction 
#                          by removing the jobcard via ftp without PSC 
#                          interaction.
#                      3.  If there is system downtime during the night, the 
#                          job will run when cron is activated again rather 
#                          than just skipping the run. 
#                      4.  Keeps ALL job initiation consolidated in the 
#                          automation, helps to prevent forgetting about jobs 
#                          scheduled in cron. 
#                      
#                      This script requires 1 positional argument.  
#
#                      The first argument is the name (without the path!) of 
#                      the Jobcard template to be scheduled.
#
#                      The optional second argument is the "RunAfter" datetime and may use the following formats:
#                      YYYYMMDDHHMMSS or 
#                      MMDDHHMMSS or 
#                      DDHHMMSS or 
#                      HHMMSS  
#
#                      The subsequent parameters will be substituted for the 
#                      string '__P1__' and '__P2__' in the template file 
#                      respectively.  This allows for up to 10 parameters to 
#                      be used in the template files.  If these parameters are 
#                      used, the second parameter (the RunAfter datetime) MUST 
#                      be specified. 
#
#                      It is an error to call this script without proper 
#                      arguments.
#
#  
#  EXT DATA FILES:     The JobCard template file that contains the 
#                      instructions for running the job must reside 
#                      in the BATCH_ETC directory and use the naming
#                      convention, "JOBNAME.template"  
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
# 2003.12.10   J. Thiessen      New code. 
# 2004         J. Thiessen      Added parameter options to templates
#
#*******************************************************************************

####----------------------------------------------------------------------------
####
####  The function check_status examines the value of P1 and if non-zero will 
####  execute the batchlog function specified in P2 with the message string 
####  specified by the remaining parameters.  
####     be  ---> batcherror
####     ben ---> batcherror_notify
####     bn  ---> batch_notify
####     end ---> batchend
####     ml  ---> messagelog
####     mln ---> messagelog_notify
####  

check_status() {
if [ ${#*} -le 2 ]; then
  batcherror_notify "USAGE: called check_status with improper arguments: ${*}"
fi
if [ "${1:-1}" != "0" ]; then   ## Only process if there is an error to report. 
  err_stat=${1}
  my_action=${2}
  shift 2  ## discard the error status value and requested action
  case ${my_action:-UNDEFINED} in
    be)  batcherror "${*}" ;; 
    ben) batcherror_notify "${*}" ;; 
    bn)  batch_notify "${*}" ;; 
    end) batchend "${*}" ;; 
    ml)  messagelog "${*}" ;; 
    mln) messagelog_notify "${*}" ;; 
    *)   batcherror_notify "${*}" ;; 
  esac
fi
}

##########################################################################
#   main script                                                          #
##########################################################################

. ~/.FPAprofile     
. batchlog.ksh
. ksh_functions.ksh               #  READS THE DATE AND RUN_SEQUENCE FUNCTIONS
NO_OUTPUT="TRUE"
NO_SUMMARY_MSGS=TRUE              # be sure that the job started does NOT have this variable set. (don't export it!!)
APPEND_LOG_FILE=TRUE      # be sure that the job started does NOT have this variable set.
setlog ${batch_prg}.`date +'%Y%m%d'`
batchstart
unset FPA_OUTPUTFILEPREFIX     # be sure that this variable is not still defined
ca=`echo '\001'`  ## define the string "control-A" for use as delimiter in sed substitutions

usage="${batch_prg} JOBCARD.template [ start-after ] "
now_Y=`echo ${batch_start_dtm} | cut -c1-4`
now_m=`echo ${batch_start_dtm} | cut -c5-6`
now_d=`echo ${batch_start_dtm} | cut -c7-8`
now_H=`echo ${batch_start_dtm} | cut -c9-10`
now_M=`echo ${batch_start_dtm} | cut -c11-12`
now_S=`echo ${batch_start_dtm} | cut -c13-14`
num_args=${#}
if [ ${num_args} -lt 1 ]
then
  msg="${batch_prg} ERROR -- Improper arguments:-->${*:-NoArguments}<-- USAGE: ${usage}"
  batcherror_notify "${msg}"
fi
if [ ${num_args} -eq 1 ]
then
  start_after=${batch_start_dtm}
else
  arg2_length=${#2}
  case ${arg2_length} in
      6)    start_after="${now_Y}${now_m}${now_d}${2}"
            if [ ${start_after} -lt ${batch_start_dtm} ]; then
              start_after="`Tomorrow_Date`${2}"
            fi;;
      8)    start_after="${now_Y}${now_m}${2}";;
     10)    start_after="${now_Y}${2}";;
     14)    start_after="${2}";;
      *)    batcherror_notify "${batch_prg} ERROR -- Invalid datetime ${2}  Must be formatted as YYYYMMDDHHMMSS or MMDDHHMMSS or DDHHMMSS or HHMMSS  ";;
  esac
fi
jobname=${1%.*}

if [ ! -r ${BATCH_ETC}/${1} ]; then
  msg="${batch_prg} ERROR -- cannot read JOBCARD template ${1}"
  batcherror_notify "${msg}"
fi
my_jobcard=${BATCH_JOBCARDS}/RunAfter${start_after}.${jobname}.${batch_start_dtm}
cp ${BATCH_ETC}/${1} ${my_jobcard}
ReturnCode=$?

if [ ! -r ${my_jobcard} ]; then
  msg="${batch_prg} ERROR -- Unable to create jobcard. ReturnCode=${ReturnCode}"
  batcherror_notify "${msg}"
fi
if [ "${ReturnCode}" != "0" ]; then
  msg="${batch_prg} ERROR -- Error copying the jobcard template. ReturnCode=${ReturnCode}"
  batcherror_notify "${msg}"
fi

chmod 777 ${my_jobcard}
ReturnCode=$?
if [ "${ReturnCode}" != "0" ]; then
  msg="${batch_prg} ERROR -- Permissions error on the jobcard template. ReturnCode=${ReturnCode}"
  batcherror_notify "${msg}"
fi

####  
####  Handle parameters
####  
shift  #Discard the template name
if [ ${#1} -gt 0 ];then shift; fi   #JPT 20060807  Check to be sure param exists before shifting.   #Discard the RunAfter datetime

if [ ${#1} -gt 0 ];then
  cat ${my_jobcard} | eval sed 's${ca}__P1__${ca}${1}${ca}' > ${my_jobcard}.param
  check_status $? ben "${batch_prg} ERROR -- cannot substitute __P1__ with ${1} in ${my_jobcard}"
  mv ${my_jobcard}.param ${my_jobcard}
  check_status $? ben "${batch_prg} ERROR -- Problem settign parameter __P1__ in ${my_jobcard}"
fi
if [ ${#2} -gt 0 ];then
  cat ${my_jobcard} | eval sed 's${ca}__P2__${ca}${2}${ca}' > ${my_jobcard}.param
  check_status $? ben "${batch_prg} ERROR -- cannot substitute __P2__ with ${2} in ${my_jobcard}"
  mv ${my_jobcard}.param ${my_jobcard}
  check_status $? ben "${batch_prg} ERROR -- Problem settign parameter __P2__ in ${my_jobcard}"
fi
if [ ${#3} -gt 0 ];then
  cat ${my_jobcard} | eval sed 's${ca}__P3__${ca}${3}${ca}' > ${my_jobcard}.param
  check_status $? ben "${batch_prg} ERROR -- cannot substitute __P3__ with ${3} in ${my_jobcard}"
  mv ${my_jobcard}.param ${my_jobcard}
  check_status $? ben "${batch_prg} ERROR -- Problem settign parameter __P3__ in ${my_jobcard}"
fi
if [ ${#4} -gt 0 ];then
  cat ${my_jobcard} | eval sed 's${ca}__P4__${ca}${4}${ca}' > ${my_jobcard}.param
  check_status $? ben "${batch_prg} ERROR -- cannot substitute __P4__ with ${4} in ${my_jobcard}"
  mv ${my_jobcard}.param ${my_jobcard}
  check_status $? ben "${batch_prg} ERROR -- Problem settign parameter __P4__ in ${my_jobcard}"
fi
if [ ${#5} -gt 0 ];then
  cat ${my_jobcard} | eval sed 's${ca}__P5__${ca}${5}${ca}' > ${my_jobcard}.param
  check_status $? ben "${batch_prg} ERROR -- cannot substitute __P5__ with ${5} in ${my_jobcard}"
  mv ${my_jobcard}.param ${my_jobcard}
  check_status $? ben "${batch_prg} ERROR -- Problem settign parameter __P5__ in ${my_jobcard}"
fi
if [ ${#6} -gt 0 ];then
  cat ${my_jobcard} | eval sed 's${ca}__P6__${ca}${6}${ca}' > ${my_jobcard}.param
  check_status $? ben "${batch_prg} ERROR -- cannot substitute __P6__ with ${6} in ${my_jobcard}"
  mv ${my_jobcard}.param ${my_jobcard}
  check_status $? ben "${batch_prg} ERROR -- Problem settign parameter __P6__ in ${my_jobcard}"
fi
if [ ${#7} -gt 0 ];then
  cat ${my_jobcard} | eval sed 's${ca}__P7__${ca}${7}${ca}' > ${my_jobcard}.param
  check_status $? ben "${batch_prg} ERROR -- cannot substitute __P7__ with ${7} in ${my_jobcard}"
  mv ${my_jobcard}.param ${my_jobcard}
  check_status $? ben "${batch_prg} ERROR -- Problem settign parameter __P7__ in ${my_jobcard}"
fi
if [ ${#8} -gt 0 ];then
  cat ${my_jobcard} | eval sed 's${ca}__P8__${ca}${8}${ca}' > ${my_jobcard}.param
  check_status $? ben "${batch_prg} ERROR -- cannot substitute __P8__ with ${8} in ${my_jobcard}"
  mv ${my_jobcard}.param ${my_jobcard}
  check_status $? ben "${batch_prg} ERROR -- Problem settign parameter __P8__ in ${my_jobcard}"
fi
if [ ${#9} -gt 0 ];then
  cat ${my_jobcard} | eval sed 's${ca}__P9__${ca}${9}${ca}' > ${my_jobcard}.param
  check_status $? ben "${batch_prg} ERROR -- cannot substitute __P9__ with ${9} in ${my_jobcard}"
  mv ${my_jobcard}.param ${my_jobcard}
  check_status $? ben "${batch_prg} ERROR -- Problem settign parameter __P9__ in ${my_jobcard}"
fi
if [ ${#10} -gt 0 ];then
  cat ${my_jobcard} | eval sed 's${ca}__P10__${ca}${10}${ca}' > ${my_jobcard}.param
  check_status $? ben "${batch_prg} ERROR -- cannot substitute __P10__ with ${10} in ${my_jobcard}"
  mv ${my_jobcard}.param ${my_jobcard}
  check_status $? ben "${batch_prg} ERROR -- Problem settign parameter __P10__ in ${my_jobcard}"
fi


messagelog "${batch_prg} SUCCESSFULLY created jobcard ${my_jobcard}"

batchend

