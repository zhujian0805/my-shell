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
#  NAME:               get_custom_code.ksh
#
#  DESCRIPTION:        This script will extract all of the client-owned custom code 
#                      
#  
#  EXT DATA FILES:     
#
#  ENV VARIABLES:      
#   
#  INPUT:              
#
#  OUTPUT:             
#                      
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
# 09/09/2004   J. Thiessen      New code. 
# 02/16/2005   R. Crawford      Removed sed formating for 6 blank spaces
#
# Version 1.0
#*******************************************************************************

####----------------------------------------------------------------------------
####
####  The function format_prc
format_prc()
{
####
if [ ${#} -ne 1 ];then
  messagelog "ERROR in format_prc function: Requires exactly 1 parameter. ${@}"
else
  f_prc=${1}.PRC
  sed -e 's/\^M//g' -e 's/      / /g' -e 's/ \{2,\}$/ /' -e 's/^Procedure/CREATE OR REPLACE Procedure/'  ${f_prc} > ${f_prc}.formatted 2>>${batch_log}
  mv ${f_prc}.formatted ${f_prc} 
fi
}  ####  END FUNCTION format_prc

####----------------------------------------------------------------------------
####
####  The function format_pkg
format_pkg()
{
####
if [ ${#} -ne 1 ];then
  messagelog "ERROR in format_pkg function: Requires exactly 1 parameter. ${@}"
else
  my_pks=${1}.PKS
  my_pkb=${1}.PKB
  sed -e 's/\^M//g' -e 's/      / /g' -e 's/ \{2,\}$/ /' -e 's/^PACKAGE/CREATE OR REPLACE PACKAGE/'  ${my_pks} > ${my_pks}.formatted 2>>${batch_log}
  sed -e 's/\^M//g' -e 's/      / /g' -e 's/ \{2,\}$/ /' -e 's/^PACKAGE/CREATE OR REPLACE PACKAGE/'  ${my_pkb} > ${my_pkb}.formatted 2>>${batch_log}
  mv ${my_pks}.formatted ${my_pks} 
  mv ${my_pkb}.formatted ${my_pkb} 
fi
}  ####  END FUNCTION format_pkg


####----------------------------------------------------------------------------
####
####  The function get_packages
get_packages()
{
####
####  Extract the custom code from the specified database.
####  Requires 3 parameters - the database; the name of the file containing the list of packages to retrieve; and the destination directory for the extracted code. 
####
if [ ${#} -ne 3 ]; then
  messagelog "ERROR in get_packages function: Requires exactly 3 parameters: database, list-file, destination-dir. " 
elif [ ! -r ${2-NoParameterProvided} ]; then 
  messagelog "Cannot read the configuration file ${2-NoParameterProvided} "
else     # start extracting packages...
  my_db=${1}
  my_list=${2}
  my_dest=${3}
  set -A package_list `grep "^#Package " ${my_list} |cut -d" " -f2 |sort -u`
  number_of_packages=${#package_list[*]}
  if [ ${number_of_packages} -eq 0 ]; then
    messagelog "${my_list##*/} is not configured for custom packages. "
  else
    now=`date +'%Y%m%d%H%M%S'`
    if [ ! -d ${my_dest} ];then make_dir ${my_dest} 774 IGNORE ; fi
    if [ ! -d ${my_dest}/archive ];then make_dir ${my_dest}/archive 774 IGNORE ; fi
    export ORACLE_SID=${my_db} 
    get_user_pass   
    . oraenv
    messagelog "Beginning package extracts in ${my_db} package list is ${package_list[*]} "
    package_counter=0
    while [ ${package_counter} -lt ${number_of_packages} ]
    do
      my_pkg=${package_list[${package_counter}]}
      package_counter=`expr ${package_counter} + 1`
      messagelog "Extracting package ${my_pkg} from ${my_db}" 
      if [ -a ${my_pkg}.PKB ]; then mv ${my_pkg}.PKB ${my_pkg}.PKB.prev${now}; fi
      if [ -a ${my_pkg}.PKS ]; then mv ${my_pkg}.PKS ${my_pkg}.PKS.prev${now}; fi
      sqlplus /nolog <<ENDSQL 1>>${batch_log} 2>&1
       connect ${USER_PASS}@${ORACLE_SID};       
       whenever sqlerror exit failure
       set echo off
       @${BATCH_SQLBIN}/get_pkg.sql ${my_pkg}
       exit;
ENDSQL
      ret_stat=${?}
      pwd >> ${batch_log}
      ls -l ${my_pkg}.PKB >> ${batch_log}
      ls -l ${my_pkg}.PKS >> ${batch_log}
      if [ ${ret_stat} -ne 0 ];then
       messagelog "WARNING--problems extracting package ${my_pkg} from ${ORACLE_SID}: ret_stat=${ret_stat} "
      elif [ -a ${my_pkg}.PKS -a ! -s ${my_pkg}.PKS ];then 
        messagelog "WARNING -- ${my_pkg}.PKS does not exist in ${my_db} "
      elif [ -a ${my_pkg}.PKB -a ! -s ${my_pkg}.PKB ];then 
        messagelog "WARNING -- ${my_pkg}.PKB does not exist in ${my_db} "
      else 
       format_pkg ${my_pkg} 
       ###### Add only if Source needs to be ftp'd to client 
       ## better yet, if they want the source, just ftp each ${my_dest} dir  when completed...
       ##  cp ${my_pkg}.PKB SOURCE_${my_db}_${my_pkg}.PKB
       ##  cp ${my_pkg}.PKS SOURCE_${my_db}_${my_pkg}.PKS    
       cp ${my_pkg}.PKB ${my_dest}/archive/${my_pkg}.PKB.${now}
       cp ${my_pkg}.PKS ${my_dest}/archive/${my_pkg}.PKS.${now}
       mv ${my_pkg}.PKB ${my_dest}
       mv ${my_pkg}.PKS ${my_dest}
      fi
    done

  #    get_packages ${db} ${dat_file} ${BATCH_SYSTEM}/custom_code/${my_db}
  fi 
fi
messagelog "Extracting custom packages from database ${my_db} using list in ${my_list} "
}  ####  END FUNCTION get_packages

##########################################################################

####----------------------------------------------------------------------------
####
####  The function get_procedures
get_procedures()
{
####
####  Extract the custom code from the specified database.
####  Requires 3 parameters - the database; the name of the file containing the list of procedures to retrieve; and the destination directory for the extracted code. 
####
if [ ${#} -ne 3 ]; then
  messagelog "ERROR in get_procedures function: Requires exactly 3 parameters: database, list-file, destination-dir. " 
elif [ ! -r ${2-NoParameterProvided} ]; then 
  messagelog "Cannot read the configuration file ${2-NoParameterProvided} "
else     # start extracting procedures...
  my_db=${1}
  my_list=${2}
  my_dest=${3}
  set -A procedure_list `grep "^#Procedure " ${my_list} |cut -d" " -f2 |sort -u`
  number_of_procedures=${#procedure_list[*]}
  if [ ${number_of_procedures} -eq 0 ]; then
    messagelog "${my_list##*/} is not configured for custom procedures. "
  else
    now=`date +'%Y%m%d%H%M%S'`
    if [ ! -d ${my_dest} ];then make_dir ${my_dest} 774 IGNORE ; fi
    if [ ! -d ${my_dest}/archive ];then make_dir ${my_dest}/archive 774 IGNORE ; fi
    export ORACLE_SID=${my_db} 
    get_user_pass   
    . oraenv
    messagelog "Beginning procedure extracts in ${my_db} procedure list is ${procedure_list[*]} "
    procedure_counter=0
    while [ ${procedure_counter} -lt ${number_of_procedures} ]
    do
      my_prc=${procedure_list[${procedure_counter}]}
      procedure_counter=`expr ${procedure_counter} + 1`
      messagelog "Extracting procedure ${my_prc} from ${my_db}" 
      if [ -a ${my_prc}.PRC ]; then mv ${my_prc}.PRC ${my_prc}.PRC.prev${now}; fi
      sqlplus /nolog <<ENDSQL 1>>${batch_log} 2>&1
       connect ${USER_PASS}@${ORACLE_SID};    
       whenever sqlerror exit failure
       set echo off
       @${BATCH_SQLBIN}/get_prc.sql ${my_prc}
       exit;
ENDSQL
      ret_stat=${?}
      pwd >> ${batch_log}
      ls -l ${my_prc}.PRC >> ${batch_log}
      if [ ${ret_stat} -ne 0 ];then
       messagelog "WARNING--problems extracting procedure ${my_prc} from ${ORACLE_SID}: ret_stat=${ret_stat} "
      elif [ -a ${my_prc}.PRC -a ! -s ${my_prc}.PRC ];then 
        messagelog "WARNING -- ${my_prc}.PRC does not exist in ${my_db} "
      else 
       format_prc ${my_prc} 
       cp ${my_prc}.PRC ${my_dest}/archive/${my_prc}.PRC.${now}
       mv ${my_prc}.PRC ${my_dest}
      fi
    done

  fi 
fi
}  ####  END FUNCTION get_procedures

####----------------------------------------------------------------------------
####
####  The function get_scripts
get_scripts()
{
####
####  Extract the custom code from the specified database.
####  Requires 2 parameters - the name of the file containing the list of 
####  scripts to retrieve; and the destination directory for the extracted 
####  code. 
####
if [ ${#} -ne 2 ]; then
  messagelog "ERROR in get_scripts function: Requires exactly 2 parameters: list-file, destination-dir. " 
elif [ ! -r ${1-NoParameterProvided} ]; then 
  messagelog "Cannot read the configuration file ${1-NoParameterProvided} "
else     # start extracting scripts...
  my_list=${1}
  my_dest=${2}
  set -A script_list `grep "^#Script " ${my_list} |cut -d" " -f2 |sort -u`
  number_of_scripts=${#script_list[*]}
  if [ ${number_of_scripts} -eq 0 ]; then
    messagelog "${my_list##*/} is not configured for custom scripts. "
  else
    now=`date +'%Y%m%d%H%M%S'`
    if [ ! -d ${my_dest} ];then make_dir ${my_dest} 774 IGNORE ; fi
    if [ ! -d ${my_dest}/archive ];then make_dir ${my_dest}/archive 774 IGNORE ; fi
    messagelog "Beginning custom script extracts in FPA environment ${BATCH_ENVIRONMENT:-UNDEFINED}, custom script list is: ${script_list[*]} "
    script_counter=0
    while [ ${script_counter} -lt ${number_of_scripts} ]
    do
      my_scr=${script_list[${script_counter}]}
      script_counter=`expr ${script_counter} + 1`
      messagelog "Extracting script ${my_scr} from ${BATCH_ENVIRONMENT}" 
      if [ -a ${BATCH_BIN}/${my_scr} ]; then 
        cp -f ${BATCH_BIN}/${my_scr} ${my_dest} >> ${batch_log} 2>&1
        ret_stat=${?}
        ls -l ${my_dest}/${my_scr} >> ${batch_log} 2>&1
        if [ ${ret_stat} -ne 0 ];then messagelog "WARNING--problem extracting script ${my_scr} : ret_stat=${ret_stat} "; fi
        cp -f ${BATCH_BIN}/${my_scr} ${my_dest}/archive/${my_scr}.${now} >> ${batch_log} 2>&1
        ret_stat=${?}
        ls -l ${my_dest}/archive/${my_scr}.${now} >> ${batch_log} 2>&1
        if [ ${ret_stat} -ne 0 ];then messagelog "WARNING--problem archiving script ${my_scr} : ret_stat=${ret_stat} "; fi
      else
        messagelog "Custom script ${my_script} does not exist in FPA environment ${BATCH_ENVIRONMENT:-UNDEFINED}"
      fi
       ###### Add only if Source needs to be ftp'd to client 
       ## better yet, if they want the source, just ftp each ${my_dest} dir  when completed...
       ##  cp ${my_scr}.PKB SOURCE_${my_db}_${my_scr}.PKB
       ##  cp ${my_pkg}.PKS SOURCE_${my_db}_${my_pkg}.PKS    
    done

  fi 
fi
}  ####  END FUNCTION get_scripts

##########################################################################
#   main script                                                          #
##########################################################################
. ~/.FPAprofile     
. batchlog.ksh
######## NO_SUMMARY_MSGS=TRUE      ## Do not create entries in the batch summary log
######## APPEND_LOG_FILE=TRUE    ## Do not create flags -- .START and .SUCCESS etc.
######## setlog ${batch_prg}.${1-UNDEFINED}.`date +'%Y%m%d'`
batchstart

if [ ! -r  ${BATCH_ETC}/.oracle.batch.profile ]; then 
  messagelog "Cannot read the database configuration file in ${BATCH_ETC} "
  batchend
fi

set -A database_list `grep "^#allowed_db " ${BATCH_ETC}/.oracle.batch.profile |cut -d" " -f2 |sort -u |tr '[A-Z]' '[a-z]'`
if [ ${#database_list[*]} -eq 0 ]; then
  messagelog "${batch_prg} -- no allowed databases. "
  batchend
fi 

####  
####  Check for parameter 
####  OPTIONAL parameter for running with only a specific database/package  -- this will be added later if needed. 
####  
if [ ${#} -gt 0 ]
then
  db_pkg=${1}
fi
prefix=${2-}  # Accept, but do not require, a prefix.  -- this will be added later if needed.

####  
####  Begin extracting the custom scripts for this FPA environment. 
####  
dat_file=${BATCH_ETC}/customcode.scripts
if [ ! -r  ${dat_file} ]; then 
  messagelog "Cannot read the configuration file ${dat_file##*/} "
else     # start extracting scripts...
  get_scripts ${dat_file} ${BATCH_SYSTEM}/custom_code/scripts
fi

####  
####  Begin LOOP -- for each allowed database, extract the custom PL/SQL code. 
####  
number_of_dbs=${#database_list[*]}
db_counter=0
while [ ${db_counter} -lt ${number_of_dbs} ] 
do 
  sleep 2
  this_db=${database_list[${db_counter}]} 
  db_counter=`expr ${db_counter} + 1`
  dat_file=${BATCH_ETC}/customcode.${this_db}
  if [ ! -r  ${dat_file} ]; then 
    messagelog "Cannot read the configuration file ${dat_file##*/} "
  else     # start extracting packages...
    get_packages ${this_db} ${dat_file} ${BATCH_SYSTEM}/custom_code/${this_db}
    get_procedures ${this_db} ${dat_file} ${BATCH_SYSTEM}/custom_code/${this_db}
  fi

done   ## End LOOP -- for each allowed database, extract the custom pl/sql.

batchend

