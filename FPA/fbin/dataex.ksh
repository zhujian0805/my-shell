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
#  NAME:               dataex.ksh
#
#  DESCRIPTION:        This korn shell script uses Call_Java to run the DataEx 
#                      java code.   DATAEX requires configuration files in a 
#                      specific directory structure which mimics that of DDS 
#                      and ECRTP.  Since DDS does not run on the reporting 
#                      database, the direcdtory structure had to be built out 
#                      as a sister directory to BATCH_ETC.   These configuration 
#                      files are part of the productoin environment so change 
#                      controls must remain in effect.  
#                      
#                      
#
#  EXT DATA FILES:     There are configuration files below the DATAEX_TP and DATAEX_HOME directories. 
#
#  ENV VARIABLES:      DATAEX_TP is the tradingPartnerRoot directory
#                      DATAEX_HOME is the jome directory for dataex    
#
#                  STANDARD BATCH VARIABLES 
#                      USER_PASS
#                      ORACLE_SID   This variable contains the name of the 
#                                   database where the job will bee executed.  
#                                   for each ORACLE_SID value, a configureation 
#                                   file must be created containing the 
#                                   connection informtion for the database.  
#                                   this file must be named 
#                                   $BATCH_ETC/.${ORACLE_SID}.dat 
#                      BATCH_BIN    directory containing local (custom) executable code
#                      BATCH_LOGS   directory containing log files
#                      BATCH_ETC    directory containing configuration files
#                      batch_working_directory  directory containing the
#                                   output files as they are beeing created.
#                                   The standard batchend routine will move all
#                                   output files into $BATCH_OUTPUT upon successful
#                                   completion.
#                      BATCH_OUTPUT directory containing batch output after the
#                                   program has completed successfully -- this
#                                   directory is monitored by FPA which moves
#                                   the output files to $BATCH_OUTPUT_archive
#                                   and processes them according to the configuration
#                                   files.  The batchstart function does a cd 
#                                   (change direcgtory) into $batch_working_directory 
#                                   so the java code can either accept a parameter 
#                                   that specifies the directory where output 
#                                   files are to be written OR it 
#                                   can simply spool output to a filename
#                                   and the file will be created in the proper
#                                   directory.  NOTE: This means that if the
#                                   java code calls other java code, the paths
#                                   must be properly defined.
#                      Note also, that when the job completes successfully, the
#                      batchend function will automatically record a long listing
#                      of the batch_working_directory and will then MOVE each
#                      output file to $BATCH_OUTPUT, and will finally rmdir
#                      batch_working_directory.  If the job exits with a failure
#                      status, the files will NOT be moved, but will need to be
#                      manually cleaned up.
#
#  INPUT:              dataex.ksh requires four parameters: partner, category, xml_file, and output filename. 
#                      $1 = Trading partner name corresponding to name of directory
#                         in the /dds/pphsdev/dds2.2/DDS/test/tradingPartnerRoot/ 
#                         directory.
#                      $2 = Sub-category for trading partner (ie. member, group, etc.)
#                         for this output file. If your trading partner is ARGUS,
#                         for example, your sub-category could be 'member'. In this
#                         case, there would need to be a directory named 'member'
#                         below your trading partner directory. 
#                      $3 = Name of input XML file that will be read to create the output.
#                      $4 = Name of the output file to be created.  
#                      NOTE:  All parameters are case sensitive and must match existing directory and file names. 
#
#
#  OUTPUT:             Standard log file in $BATCH_LOGS
#                      Optional output files depending on the java object
#
#
#*******************************************************************************
# Date         Programmmer      Description
# ----------   --------------   ------------------------------------------
# 16-SEP-2003  Jesse Gonzalez   Initial Version
# 02-MAR-2004  Jesse Gonzalez   Changes for FPA
# 12/03/2003   J. Thiessen      Wrapped for FPA
# 03/27/2006   J. Thiessen      Modified to use Call_Java function to reduce log files. 
#
#
#*******************************************************************************

##########################################################################
#   main script                                                          #
##########################################################################
. ${BATCH_ETC}/.oracle.batch.profile
. ksh_functions.ksh
. batchlog.ksh
tempstring0="`basename ${1:-NoPartner}`.`basename ${2:-NoCategory}`.`basename ${3:-NoXML}`"
tempstring1="`basename ${0}|cut -d\. -f1`.${tempstring0}"
logfilename="${tempstring1}.${batch_start_dtm}.log"
setlog "${logfilename}"
batchstart

batch_log_path=${batch_log%/*}
batch_log_name=`basename ${batch_log}`
flagfile="${BATCH_FLAGS}/${batch_log_name%%.log}.done"

if [ "${#}" != "4" ]
then
  msg="ERROR -- dataex.ksh requires four parameters: partner, category, xml_file, and output filename. ${*} "
  batcherror_notify "${msg}"
fi


TP_SUBDIR=${DATAEX_TP}/${1}/${2}
TP_OUTFILE=${4}

errmsg=""
if [ ! -d ${TP_SUBDIR} ];then
  msg="ERROR - directory ${TP_SUBDIR} does not exist.  Parameters are case sensitive."
  batcherror "${msg}"
fi
if [ ! -r ${TP_SUBDIR}/${3} ];then
  msg="ERROR - xml file ${TP_SUBDIR}/${3} does not exist.  Parameters are case sensitive."
  batcherror "${msg}"
fi

############
############
############  OLD COMMAND  ############  java.ksh DataEx/${tempstring0} ${BATCH_BIN}/classes12.jar ${DATAEX_HOME} END_PATH ${BATCH_ETC}/.${ORACLE_SID}.dat ${TP_SUBDIR}/${3} batch_working_directory/${TP_OUTFILE} ${DATAEX_HOME}

echo "Call_Java DataEx ${BATCH_BIN}/classes12.jar ${DATAEX_HOME} END_PATH ${BATCH_ETC}/.${ORACLE_SID}.dat ${TP_SUBDIR}/${3} batch_working_directory/${TP_OUTFILE} ${DATAEX_HOME} "  >> ${batch_log}

Call_Java DataEx ${BATCH_BIN}/classes12.jar ${DATAEX_HOME} END_PATH ${BATCH_ETC}/.${ORACLE_SID}.dat ${TP_SUBDIR}/${3} batch_working_directory/${TP_OUTFILE} ${DATAEX_HOME}
javareturn_code=$?


####
####  Check to be sure that java.ksh successfully started and completed.
####  Perform all error handling here for java errors.
####
if [ ${javareturn_code} -ne 0 ];then
    msg="Error-- dataex did not complete successfully. Writing logfile ${batch_log_name}"
    batcherror_notify "${msg}"
fi

####
####  Create a flag file to indicate successful completion
####
echo "${batch_prg} created ${flagfile} at ${now}" >> ${flagfile}
if [ ! -a  ${flagfile} ];then
  msg="Error. FAILED to create flagfile ${flagfile}"
  batcherror_notify "${msg}"
fi

batchend

##=-=## #-------------------------------------------------------------
##=-=## # dataex.ksh
##=-=## #
##=-=## # Script for extracting data from Oracle environment and 
##=-=## # creating non-standard delimited or fixed-width output files.
##=-=## #
##=-=## # Arguments:
##=-=## # --------------
##=-=## # EXAMPLE
##=-=## #
##=-=## # $DATAEX_HOME/dataex.ksh ARGUS group group.xml > $DATAEX_TP/ARGUS/group/group1.log
##=-=## #
##=-=## # Revision History
##=-=## # ---------------------
##=-=## # 16-SEP-2003	Jesse Gonzalez	Initial Version
##=-=## # 02-MAR-2004	Jesse Gonzalez	Changes for FPA
##=-=## #
##=-=## #-------------------------------------------------------------
##=-=## #
##=-=## #---------------------
##=-=## # Setup variables
##=-=## #---------------------
##=-=## echo "START:"`date`
##=-=## DATAEX_TP=/dds/pphsdev/dds2.2/DDS/test/tradingPartnerRoot
##=-=## DATAEX_HOME=/dds/pphsdev/dds2.2/ppic/dataex
##=-=## echo "Change to home directory..."
##=-=## cd
##=-=## #echo "Execute profile..."
##=-=## #. ./.profile
##=-=## echo "Change to DATAEX_HOME..."
##=-=## cd $DATAEX_HOME
##=-=## TP_SUBDIR=$DATAEX_TP/$1/$2
##=-=## TP_OUTBOUND=$TP_SUBDIR/outbound
##=-=## TP_OUTFILE=$1_$2_`awk 'BEGIN{print substr(ARGV[1],1,index(ARGV[1],".")-1)}' "$3"`".out"
##=-=## #
##=-=## echo "Execute DataEx..."
##=-=## #java -cp $DATAEX_HOME/classes12.jar:$DATAEX_HOME DataEx "/dds/pphsdev/dds2.2/ppic/dataex/config.txt" $TP_SUBDIR/$3 $TP_OUTBOUND/$TP_OUTFILE $DATAEX_HOME > java.log
##=-=## echo "JPT java -cp $DATAEX_HOME/classes12.jar:$DATAEX_HOME DataEx /dds/pphsdev/dds2.2/ppic/dataex/config.txt $TP_SUBDIR/$3 batch_working_directory/$TP_OUTFILE $DATAEX_HOME > java.log "
##=-=# echo "END:"`date`
