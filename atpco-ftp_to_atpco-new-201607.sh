#!/bin/bash

###**************************************************************************
### File name: ftp_to_atpco.sh   
###
### Description: Use curl to FTPS Fare Files created by Airprice to ATPCO
###
### Purpose: Transmit Alaska Fare Changes to ATPCO for publication
###
### Date     By       Description
### ------------------------------------------------
### 05/06/2005 dkim    initial                     
### 05/02/2008 jgrant  Renamed from sftp_to_atpco.sh                
###                    Renamed subroutines to 'ftp' from 'sftp'.
###                    Modify for new FTP with SSL transmit method to ATPCO.
###                    Remove 'rename' step (associated to put as .tmp)
###                    Adjust to new ATPCO filenaming requirements:
###                       XAS.PROD.XMTASRCZ.nnnnnnn where nnnn is type of file
###                         use .TEST. for test files.
###                    Increase Max Retries for FTP loop. 
###                    Revise main FTP Retry loop to simplify logic.
###                    Added ftp_check routine to verify ATPCO FTP site up.
###                    Improved FTP error checking.
###                    Modify log file contents, and Subject Line of success   
###                     and failure emails to make it easier for customers
###                     to understand.  Per Ben Crandall request.  Goal is
###                     to be clear when customers should call ATPCO to 
###                     resolve a send problem vs. calling PSMC.
###                    Add server name to email message and logfile.
### 06/18/2008 jgrant  Restructure with new 'build_fare_file' logic that will append
###                      any new fare files delivered by the RMAPDIST schedule
###                      into the file we are trying to send.  We'll check for 
###                      new files every time through our send retry loop. 
###                    This will protect us from loss of outbound fare files due
###                      to overwrites by RMAPDIST schedule in-between re-runs of
###                      RMAPSEND@ (due to transmit failure max-outs).
###                    It will also protect us from overwrites caused by
###                      a failure of the RMAPDIST job-level TWS Resources that 
###                      are shared with RMAPSEND@.  
### 11/04/2010 jgrant Modify f_ftp() to use curl to ftps to ATPCo.
###                   Modify mainline to use curl's return code to judge success.
###                   Eliminate mainline's call to ftp_check() because failures
###                     with ATPCo FTP site have caused program to hang here.
###**************************************************************************
#####################
#####################
#####################  CONFIGURED FOR PROD
#####################
#####################
. $HOME/bin/atpco_environment_test
#####################
#####################
#####################
############################################################
# Error Notification - Automated Emails
# 1. 'URGENT: Airprice Error - Fare Send.. Failing' email:  We will retry a failing
#    FTP Connection to ATPCO until max retries, at which point the program 
#    will send an email upon exiting, notifying us of the failure situation 
#    and that we will continue to retry. Given MaxRetry=15, 1 minute apart, 
#    then a continued outage of ATPCO's FTP site will produce this email
#    every :15 minutes.
# 2. 'URGENT: Airprice ... Disk Full?' email: File operations - moves, copies, 
#    concatenates, pkzip compression - will generate this email on failure, 
#    which includes instructions to Production Support to check for disk full.
#    If this problem is not corrected, this error email and the above
#    'Retrying' email will be sent as quickly as the schedule is resubmitted.
#    This will probably be about every two minutes.
############################################################

############################################################
#  Function Definitions 
############################################################

############################################################
# initialize_log_file sets up log file name, location, writes first message
############################################################
initialize_log_file()
{
# Construct Log file Names (ftp_log for entire process)
ftp_log=$LOG/$fare_file.$ARCHDATE
echo "Log file is: $ftp_log"
# f_ftp_log for f_ftp function's connection dialog with ATPCO remote system (cat'd into main log file)
f_ftp_log=$LOG/$fare_file.$ARCHDATE.ftpatpco
echo "FTP session Log file is: $f_ftp_log"
# error_log for specific file operation errors (ie disk io)
error_log=$LOG/$fare_file.$ARCHDATE.diskio

# Determine which RMAPSEND schedule has called us (RMAPSENDDOM, ..INT, ..ARB) based on incoming filename
if [[ $fare_file = *"PLFTRAN" ]]
then
  tws_schedule="RMAPSENDDOM@"
  tws_job="RMAPSENDDOM_FTP"
  fare_type="Domestic"
else
  if [[ $fare_file = *"INTPUB" ]]
  then
    tws_schedule="RMAPSENDINT@"
    tws_job="RMAPSENDINT_FTP"
    fare_type="International"
else
    if [[ $fare_file = *" INTARB " ]]
    then
    tws_schedule="RMAPSENDARB@"
    tws_job="RMAPSENDARB_FTP"
    fare_type="Arbs"
   else  ## *"FARES"
       if [[ $fare_file = *" FARES " ]]
       then
    tws_schedule="RMAPSENDFARET@"
    tws_job="RMAPSENDFARE_FTP_TEST"
    fare_type="Fares"
      fi
    fi
  fi
fi

# Start ftp_log logfile, identify this server
echo "This message is being sent by userid $USER from machine $HOSTNAME in the Alaska Airlines Production environment"  > $ftp_log
echo -e "under control of AGAPPS TWS Schedule $tws_schedule, job $tws_job -- see stdlist for more info." >> $ftp_log
echo -e "\nWorking with $fare_type Fare Distribution from Airprice: $fare_file" >> $ftp_log
echo -e "\nStarting Process to transmit file to ATPCO at `date`" >> $ftp_log

# Start File Operation Error Logfile, identify this server
echo "This message is being sent by userid $USER from machine $HOSTNAME in the Alaska Airlines Production environment"  > $error_log
echo -e "under control of AGAPPS TWS Schedule $tws_schedule, job $tws_job -- see stdlist for more info." >> $error_log
echo -e "\nWorking with $fare_type Fare Distribution from Airprice: $fare_file" >> $error_log
echo -e "\nStarting Process to transmit file to ATPCO at `date`" >> $error_log
}

############################################################
# Build_Fare_File Process: Construct Fares File to Transmit to ATPCO
# Execute this routine every time through our send-retry loop.
# Final result is a $fare_file in $OUTBOUND_WORK ready for further processing.
#
# Psuedocode:
# if $fare_file exists in $OUTBOUND
#   //New file delivered, or one there from previous error_exit.  
#   //Create file name for 
#   //Move it to work directory.
#   move $fare_file to $OUTBOUND_WORK as $fare_file.$ARCHDATE [two steps: 1-copy, 2-if OK, remove]
#
#   //Determine how to incorporate into active send file, if we have one.
#   If $fare_file exists in $OUTBOUND_WORK                   [if there is an active send file]
#     if $fare_file is not identical to $fare_file.$ARCHDATE [if new and active files are different]
#       concatenate $fare_file and $fare_file.$ARCHDATE      [append new onto bottom of active]
#       //write concatenated file into archive directory, archiving combined file
#     endif
#     remove $fare_file.$ARCHDATE                     [remove new file; either appended or identical]
#   else                                                     [else there is not an active send file]
#     //Archive file: copy $OUTBOUND_WORK/$fare_file.$ARCHDATE to $OUTBOUND_ARCHIVE/$fare_file.$ARCHDATE
#     move $fare_file.$ARCHDATE to $fare_file                [then new file becomes active send file]
#   endif
#
#   //Now the active send file ($OUTBOUND_WORK/$fare_file) incorporates the new file if appropriate.
#   //The new file ($fare_file.$ARCHDATE) has been archived (in $OUTBOUND_ARCHIVE), 
#   //  and no longer exists in either $OUTBOUND or $OUTBOUND_WORK directories.
#
# else [no $fare_file in $OUTBOUND]
#   //No new files delivered by RMAPDIST or positioned by this script on error_exit.  
#   //Continue with $fare_file we have in $OUTBOUND_WORK.
#   if no $fare_file in $OUTBOUND_WORK then exit (with error??)
# endif
#
############################################################
build_fare_file()
{
# Does $fare_file exist in $OUTBOUND with a size greater than 0?
# (If it does, either RMAPDIST has delivered a new $fare_file, or we've previously exited with error.)
if [[ -s $OUTBOUND/$fare_file ]]
then
  # copy $fare_file to Working directory, with timestamp appended to name.
  timestamp=$ARCHDATE
  echo -e "\nbuild_fare_file: Moving new fare file to working directory as: $OUTBOUND_WORK/$fare_file.$timestamp"
  echo -e "\nbuild_fare_file: Moving new fare file to working directory as: $OUTBOUND_WORK/$fare_file.$timestamp" >> $ftp_log
  cp $OUTBOUND/$fare_file $OUTBOUND_WORK/$fare_file.$timestamp

  # Test if copy was successful
  cp_rc=$?
  if [[ $cp_rc -eq 0 ]]
  then
    # If successful, remove new fare file from $OUTBOUND
    rm -f $OUTBOUND/$fare_file
  else
    # Not Successful...  Don't remove file from $OUTBOUND (we don't have it anywhere else).
    # Log messages to stdlist with explanation
    echo -e "\nERROR: build_fare_file: Move of newly arrived fare file to Working directory returned $cp_rc: "
    echo -e "   $OUTBOUND/$fare_file could not be copied to $OUTBOUND_WORK/$fare_file.$timestamp"
    echo -e "Data loss is possible if RMAPDIST writes more than one file while we are in fail state here."
 
    # Log messages to error logfile (for email) 
    echo "ERROR: build_fare_file: Copy New Fare File to Working directory returned $cp_rc - Send Aborted" >> $error_log
    echo -e "\n\nPRODUCTION SUPPORT:  " >> $error_log
    echo "  URGENT: Data loss is possible." >> $error_log
    echo "  Check for disk full.  If so, Delete files in /ftphome/atpco/outbound_archive more than 3 months old!!!" >> $error_log
    echo "  Consult PSMC Operations Guides for AGAPPS RMAPSEND* for further information." >> $error_log

    # Send email advising of failure
    /bin/mail -s "URGENT: Airprice $HOSTNAME Disk Full? Action Required" $errlist < $error_log

    # Save new fare file (should still be there in any case), Send email saying we'll retry to send, exit
    error_exit $OUTBOUND/$fare_file
  fi

  # Determine if the newly found $fare_file is new (from RMAPDIST) or a copy (put by error_exit routine here)

  # Do we have a saved fare file: Does an active $fare_file exist in $OUTBOUND_WORK with a size greater than 0?
  if [[ -s $OUTBOUND_WORK/$fare_file ]]
  then
    # Yes we have one. Means we've previously exited with errors, unable to complete the send.
    echo -e "Saved fare file found in Working directory: $OUTBOUND_WORK/$fare_file"                                  
    echo -e "Saved fare file found in Working directory: $OUTBOUND_WORK/$fare_file" >> $ftp_log

    # Is it different from the newly arrived $fare_file?
    # Name the file that will hold any differences between new and saved file - use same timestamp as on new file
    diff_file=$fare_file.$timestamp.diffs

    # Do the file comparison, redirect results (differences) into $diff_file (in archive directory)
    diff $OUTBOUND_WORK/$fare_file $OUTBOUND_WORK/$fare_file.$timestamp > $OUTBOUND_ARCHIVE/$diff_file

    # Check the output - Any differences?  (Does $diff_file exist with a size greater than 0?)
    if [[ -s $OUTBOUND_ARCHIVE/$diff_file ]]
    then 
 
      # Yes, there are differences.  This means that RMAPDIST has delivered a new file.
      # Concatenate files by adding newer file onto end of older one.
      echo -e "New and Saved fare files are different.  Combining the files into one file to send." >> $ftp_log
      echo -e "Saved $fare_file found in $OUTBOUND_WORK; different than new file (see $OUTBOUND_WORK/$diff_file)"
      echo -e "Concatenating saved file and $OUTBOUND_WORK/$fare_file.$timestamp for sending."

      # Name the file that will hold the concatenated fare files -- cat the files into the archive directory!
      combined_file=$fare_file.$timestamp.combined
      cat $OUTBOUND_WORK/$fare_file $OUTBOUND_WORK/$fare_file.$timestamp >$OUTBOUND_ARCHIVE/$combined_file

      # Test if concatenation was successful
      cat_rc=$?
      if [[ $cat_rc -ne 0 ]]
      then
        # Not Successful...  
        # Log messages to stdlist with explanation
        echo -e "\nERROR: build_fare_file: Concatenation of New Fare File with existing Fare File in Working directory returned $cat_rc. "
        echo -e "   cat $OUTBOUND_WORK/$fare_file $OUTBOUND_WORK/$fare_file.$timestamp into $OUTBOUND_ARCHIVE/$combined_file failed."
        echo -e "Data loss is possible if RMAPDIST writes more than one file while we are in fail state here."
 
        # Log messages to logfile (for email) 
        echo "ERROR: build_fare_file: Concatenating New and In-work Fare Files returned $cat_rc - Send Aborted" >> $error_log
        echo -e "\n\nPRODUCTION SUPPORT:  " >> $error_log
        echo "  URGENT: Data loss is possible." >> $error_log
        echo "  Check for disk full.  If so, Delete files in /ftphome/atpco/outbound_archive more than 3 months old!!!" >> $error_log
        echo "  Consult PSMC Operations Guides for AGAPPS RMAPSEND* for further information." >> $error_log
        echo -e "\nSchedule will continue to re-submit itself automatically." >> $error_log

        # Send email advising of failure
        /bin/mail -s "URGENT: Airprice $HOSTNAME Disk Full? Action Required" $errlist < $error_log

        # Save newly retrieved $fare_file back to $OUTBOUND, Send email saying we'll retry to send, exit
        error_exit $OUTBOUND_WORK/$fare_file.$timestamp
        # Note: file $fare_file.$timestamp will remain in $OUTBOUND_WORK in this case (removed by atpco_clean.sh when >180 days old)

      else
        # Successful cat - log that the file was archived
        echo -e "\nArchiving concatenated file at $OUTBOUND_ARCHIVE/$combined_file" >> $ftp_log

        # remove the two original files
        rm -f $OUTBOUND_WORK/$fare_file
        rm -f $OUTBOUND_WORK/$fare_file.$timestamp

        # copy the new file into the active send file
        cp $OUTBOUND_ARCHIVE/$combined_file $OUTBOUND_WORK/$fare_file
        
        # Test if copy was successful
        cp_rc=$?
        if [[ $cp_rc -ne 0 ]]
        then
          # Not Successful...  
          # Log messages to stdlist with explanation
          echo -e "\nERROR: build_fare_file: Copy of concatenated/combined fare file returned $cp_rc. "
          echo -e "   Copy $OUTBOUND_ARCHIVE/$combined_file to $OUTBOUND_WORK/$fare_file failed."
          echo -e "Data loss is possible if RMAPDIST writes more than one file while we are in fail state here."
          echo -e "\n\nCheck for Disk Full - provide disk space - schedule will automatically rerun."
 
          # Log messages to logfile (for email) 
          echo "ERROR: build_fare_file: Copying Combined Fare File to in-work Fare File returned $cp_rc - Send Aborted" >> $error_log
          echo -e "\n\nPRODUCTION SUPPORT:  " >> $error_log
          echo "  URGENT:  Data loss is possible." >> $error_log
          echo "  Check for disk full.  If so, Delete files in /ftphome/atpco/outbound_archive more than 3 months old!!!" >> $error_log
          echo "  Consult PSMC Operations Guides for AGAPPS RMAPSEND* for more information." >> $error_log
          echo -e "\nSchedule will continue to re-submit itself automatically." >> $error_log

          # Send email advising of failure
          /bin/mail -s "URGENT: Airprice $HOSTNAME Disk Full? Action Required" $errlist < $error_log

          # Save combined file back to $OUTBOUND, Send email saying we'll retry to send, exit
          error_exit $OUTBOUND_ARCHIVE/$combined_file
        fi ## cp 0
      fi ## cat 0
    else
      # no differences found between New and Saved fare files.  
      echo -e "No differences found between New and Saved fare files.  Removing new file, sending saved file."
      echo -e "No differences found between New and Saved fare files.  Removing new file, sending saved file." >> $ftp_log
      
      # Remove the new file (send the saved one)                    
      rm -f $OUTBOUND_WORK/$fare_file.$timestamp 

    fi ## any differences between new and saved?
  else ## No, there's no $fare_file saved in $OUTBOUND_WORK

    echo -e "No Saved fare file found in Working directory, sending new distribution file"
    echo -e "No Saved fare file found in Working directory, sending new distribution file" >> $ftp_log

    # Archive the new fare file (note: failure in archive will prompt email but not program exit)
    archive_fare_file

    # Make the newly found fare_file be the active send file
    mv $OUTBOUND_WORK/$fare_file.$timestamp $OUTBOUND_WORK/$fare_file

  fi ## $fare_file present in $OUTBOUND_WORK?
else
  # Script should not have been called - because TWS jobstep should not have run - without file present..
  # Implies a manual removal of the jobstep's OPENS dependency - assume this is to prompt send of saved farefile.
  # Therefore, continue as long as there is a file in $OUTBOUND_WORK...  else throw error
  if [[ ! -s $OUTBOUND/$fare_file ]]
  then

    # Log message for stdlist and email
    echo -e "\nNo file found in $OUTBOUND"
    echo -e "\nNo file found in $OUTBOUND" >> $ftp_log
exit 0
  fi
}

############################################################
# Compress the fare_file per ATPCO requirements (secure PKZip)
############################################################
compress_fare_file()
{
# Compress the fare file (using what atpco calls 'secure zip')
echo -e "\nCompressing file $OUTBOUND_WORK/$fare_file into zip archive $OUTBOUND_WORK/$zip_file.zip" >> $ftp_log
pkzipc -add $cryptalg -passphrase=$password $OUTBOUND_WORK/$zip_file $OUTBOUND_WORK/$fare_file

# Check return code from pkzipc - if non-zero, log error and exit.
pkzipc_rc=$?
if [[ $pkzipc_rc -ne 0 ]]
then
  echo -e "\nERROR: compress_fare_file: PKZipc returned $pkzipc_rc:"
  echo -e "   pkzipc create of archive $OUTBOUND_WORK/$zip_file.zip containing $OUTBOUND_WORK/$fare_file Failed."
  echo -e "Data loss is possible if RMAPDIST writes more than one file while we are in fail state here."
  echo -e "\n\nCheck for Disk Full - provide disk space - schedule will automatically rerun."

  # Log messages to logfile (for email)
  echo -e "\nERROR: compress_fare_file: PKZipc returned $pkzipc_rc:" >> $error_log
  echo -e "\n\nPRODUCTION SUPPORT:  " >> $error_log
  echo "  URGENT: Data loss is possible." >> $error_log
  echo "  Check for disk full.  If so, Delete files in /ftphome/atpco/outbound_archive more than 3 months old!!!" >> $error_log
  echo "  Consult PSMC Operations Guides for AGAPPS RMAPSEND* for further information." >> $error_log

  # Send email advising of failure
  /bin/mail -s "URGENT: Airprice $HOSTNAME Disk Full? Action Required" $errlist < $error_log

  # Return unsuccessful                                                 
  return 4

else
  # Return success
  return 0
fi
}

############################################################
# archive_fare_file copies newly arrived fare file to archive directory
#
# Failure in this process will not cause an exit; an email
#  will be sent but the send process will continue.
############################################################
archive_fare_file()
{
echo -e "\nArchiving file at $OUTBOUND_ARCHIVE/$fare_file.$timestamp"   >> $ftp_log
cp $OUTBOUND_WORK/$fare_file.$timestamp $OUTBOUND_ARCHIVE/$fare_file.$timestamp >>  $ftp_log
cp_rc=$?

# If copy returns non-zero, log failure, send email, but continue processing.
if [[ $cp_rc -ne 0 ]]
then   
  # Log messages to logfile (for email)
  echo "ERROR: archive_fare_file (copy) returned $cp_rc - Send Continuing" >> $error_log
  echo -e "\n\nPRODUCTION SUPPORT:  " >> $error_log
  echo "  URGENT: Data loss is possible." >> $error_log
  echo "  Check for disk full.  If so, Delete files in /ftphome/atpco/outbound_archive more than 3 months old!!!" >> $error_log  
  echo "  Consult PSMC Operations Guides for AGAPPS RMAPSEND* for more information." >> $error_log
  echo -e "\nSchedule will continue to re-submit itself automatically." >> $error_log
  
  # Send email advising of failure -- need disk space!
  /bin/mail -s "URGENT: Airprice $HOSTNAME Disk Full? Action Required" $errlist < $error_log
fi 
}

############################################################
# ftp_check function checks for connectivity to an ftp host 
############################################################
ftp_check()
{
  function_host=$1

  if [ -z $function_host ]
  then
    echo -e "\nMissing FTP Host argument, this function 
               needs to be called with the name of the ftp host as the
               first argument.  e.g. ftp_check mvs\n"
    exit 8
  fi

  echo -e "\nCheck for ftp connectivity to $function_host"
  ftp -v $function_host <<TEST >ftp_results.$$
        quit
TEST

  ftptest1=`grep -i -c -e "$function_host" ftp_results.$$`
  ftptest2=`grep -i -c -e "log" ftp_results.$$`

  if [ $ftptest1 -lt 1 -a $ftptest2 -lt 1 ]
  then
    echo -e "\nUNABLE TO OPEN FTP SESSION TO $function_host
      CHECK THE NETWORK OR FTP HOST ($function_host) FOR PROBLEMS\n"
    cat ftp_results.$$
    cp ftp_results.$$ $ftp_log.ftp_debug.$$
    rm -f ftp_results.$$
    return 4
  else
    echo -e "connection to $function_host confirmed, processing continues...\n"
    rm -f ftp_results.$$
  fi
}

############################################################
# f_ftp function FTP Puts a file to an ftp host
############################################################
f_ftp()
{
echo "f_ftp_log value is " $f_ftp_log
curl -vk --stderr - --ftp-ssl -u xas0ft1:xas0ft1 -T $1 --quote "site LRECL=0 RECFM=U BLKSIZE=27990" ftp://ftpin.atpco.net/"$2" >$f_ftp_log 
ftp_result=$?
echo "ftp_result value is" $ftp_result
}

############################################################
# error_exit function does final processing for exit with error 
#
# Called when we cannot successfully transmit $fare_file.
#
# If there isn't already a new $fare_file in $OUTBOUND,
#   copy our active $fare_file to $OUTBOUND.
#
# (This is necessary to satisfy the OPENS dependency of the
#   next RMAPSEND@ schedule that will be submitted. We need
#   this schedule to immediately start up and begin to retry 
#   to send this file to ATPCO.)
#
# (It is OK if RMAPDIST overwrites our $fare_file in $OUTBOUND.
#   The build_fare_file routine will combine the new RMAPDIST file
#   with our remaining copy of $fare_file in $OUTBOUND_WORK.)
#
# Send Email notifying Production Support etc. that we failed
#   and will retry.
############################################################
error_exit()
{
# Inbound parameter is name of fare file to copy out to $OUTBOUND
#   if there isn't already a $fare_file there.  Most appropriate
#   file to use depends on where we failed, so let caller decide.
restore_file=$1

# If $OUTBOUND/$fare_file does not exist with a size greater than 0
if [[ ! -s $OUTBOUND/$fare_file && $restore_file != "NULL" ]]
then
  # Copy specified $fare_file to $OUTBOUND directory
  cp $restore_file $OUTBOUND/$fare_file
  cp_rc=$?

  # If copy returns non-zero, log failure, send email, continue processing.
  if [[ $cp_rc -ne 0 ]]
  then   
    # Log messages to stdlist with explanation
    echo -e "\nERROR: error_exit: attempt to copy active fare file to Outbound directory returned $cp_rc:"
    echo "  copy $restore_file to $OUTBOUND/$fare_file failed."
    
    # Log messages to error logfile (for email)
    echo -e "\nERROR: error_exit: Attempt to copy active fare file to Outbound directory for rerun returned $cp_rc:" >> $error_log
    echo "  copy $restore_file to $OUTBOUND/$fare_file failed." >> $error_log
    echo -e "\n\nPRODUCTION SUPPORT:  " >> $error_log
    echo "  URGENT: Data loss is possible." >> $error_log
    echo "  Check for disk full.  If so, Delete files in /ftphome/atpco/outbound_archive more than 3 months old!!!" >> $error_log
    echo "  Then, manually remove OPENS dependency on the new version of this RMAPSEND@ schedule" >> $error_log
    echo "  Consult PSMC Operations Guides for AGAPPS RMAPSEND* for further information." >> $error_log

    # Send email advising of failure -- need disk space!
    /bin/mail -s "URGENT: Airprice $HOSTNAME Disk Full? Action Required" $errlist < $error_log
  else
    echo -e "\n\nError_exit: Copy $restore_file to $OUTBOUND successful" >> $ftp_log
  fi 
fi

# Remove diskio error log file (entire contents is in body of error email).
rm -f $error_log

# Remove f_ftp_log (f_ftp function's connection dialog with ATPCO remote system) (cat'd into main log file)
rm -f $f_ftp_log

echo -e '\nTerminating with Errors at: ' `date` >> $ftp_log

# Echo logfile into stdlist
echo -e "\n*****************Logfile Follows (included in Email)******************\n"
cat $ftp_log
echo -e "\n**************************End of Logfile******************************\n"

# Send email advising of problem; retries will continue under re-submitted RMAPSEND schedule
/bin/mail -s "URGENT: Airprice Error - Fare Send to ATPCO Failing" $errlist < $ftp_log

echo -e '\nTerminated with Errors at: ' `date`

# Do not trigger TWS ABEND.  Do not trigger TWS RECOVERY job.  Rely on above email(s).
exit 0
}

############################################################
#  Main module
############################################################

# Incoming parameter is uncompressed fare file name (from RMAPSEND* schedule DOCOMMAND)
fare_file=$1
echo "Received Fare Distribution from Airprice (TWS RMAPDIST): $fare_file"

# initialize_log_file sets up log file name, location, writes first message
initialize_log_file

# Create email address lists for success and failure
errlist=`awk '{print $1}' $ELIST/RMAPsend_error.list` 
successlist=`awk '{print $1}' $ELIST/RMAPsend_success.list` 

# For File Compress: Create .zip file name  (like fare_file name but change XMTASRCN to SMTASRCZ)
zip_file=`echo $fare_file | sed -e s/XMTASRCN/XMTASRCZ/`

# For FTP session: Create ATPCO's required MVS data set name by adding quotes to zip file name     
ATPCO_MVS_DSN=\'$zip_file\'

# Setup for FTP Retry Loop:  Set max number of retries, and pauses in-between retries
let MaxRetry=5         ##15   ===>>> Will Send Emails every :15 minutes saying we're retrying
let sleep_seconds=60   ##60   ===>>>    in the face of continued connection failures to ATPCO.
echo -e "\nEntering Send Loop:  Will make up to $MaxRetry attempts to send file."

##### FTP Retry Loop -- Attempt to FTP PUT file to ATPCO; retry until success or $MaxRetry exceeded
let file_sent=0
let retry_cnt=1
while [[ $retry_cnt -le $MaxRetry && $file_sent -eq 0 ]]
do

  # If not first time thru, sleep before retry          
  if [[ $retry_cnt -gt 1 ]]
  then
    echo -e "\nRetry $retry_cnt of $MaxRetry: Sleeping for $sleep_seconds seconds first, starting at `date`" 
    echo -e "\nRetry $retry_cnt of $MaxRetry: Sleeping for $sleep_seconds seconds first, starting at `date`" >> $ftp_log
    sleep $sleep_seconds
  fi

  # Construct $OUTBOUND_WORK/$fare_file for further processing (note: build_fare_file failures can cause program exit)
  build_fare_file

  # Compress $OUTBOUND_WORK/$fare_file per ATPCO requirements (secure PKZip)
  compress_fare_file

  # If Compress fails, exit
  compress_rc=$?
  if [[ $compress_rc -ne 0 ]]
  then
    # Save active send file, send email saying we'll retry to send, exit
    error_exit $OUTBOUND_WORK/$fare_file
  fi
 
  # Connect to ATPCO FTP server to verify it is available.
  #echo -e "\nTry $retry_cnt: Verifying ATPCO FTP site is available." >> $ftp_log
  #ftp_check $ftphost_outbound

  # Check if connection was successful
  #ftp_check_rc=$?
  #if [[ $ftp_check_rc -ne 0 ]]
  #then
    # Log failure to connect to ATPCO....  (will retry if not maxed out retries)
    #echo "Try $retry_cnt: ERROR: ATPCO FTP site is NOT available (ftp_check returned $ftp_check_rc)"  >> $ftp_log

  #else
    # FTP connection established; their site is up.  Log progress messages
    echo -e "\nTry $retry_cnt: Attempting to transmit $OUTBOUND_WORK/$zip_file.zip to ATPCO as Dataset $ATPCO_MVS_DSN." 
    echo -e "\nTry $retry_cnt: Send $OUTBOUND_WORK/$zip_file.zip to ATPCO as Dataset $ATPCO_MVS_DSN." >> $ftp_log

    # Initiate new FTP session to put fare file; re-direct session log to f_ftp_log file (write anew; don't append)
    #f_ftp $OUTBOUND_WORK/$zip_file.zip $ATPCO_MVS_DSN 2> $f_ftp_log
    f_ftp $OUTBOUND_WORK/$zip_file.zip $ATPCO_MVS_DSN 
 #####FOR TESTING ONLY -- copy saved successful ftp session into f_ftp_logfile 
 ##cp XAS.TEST.XMTASRCN.PLFTRAN.successftp $f_ftp_log
 #####END of Test-only mod

    # Write ftp session dialog into general process log
    echo -e "\n*****FTP Session with ATPCO site follows******" >> $ftp_log
    cat $f_ftp_log >> $ftp_log
    echo "*****End of FTP Session with ATPCO site ******" >> $ftp_log

    # Check curl return code for transfer status; if zero, success
    echo "ftp_result is: $ftp_result (curl return code)"
    if [[ $ftp_result -eq 0 ]]
    then
      # Success: drop out of loop and wrap it up.
      file_sent=1
    else
      # Failure: curl returned non-zero. Log an error.
      echo "ERROR: Send to ATPCO Failed - Retrying."  >> $ftp_log
    fi # eq 0
  #fi # ftp_check rc

  # Increment retry counter
  let retry_cnt=retry_cnt+1

done  ###### End of FTP Retry Loop

# Test if we had a successful send
if [[ $file_sent -eq 1 ]]
then
  # Update log for send complete
  echo -e "\nTRANSMISSION TO ATPCO SUCCESSFUL at " `date` >> $ftp_log
  echo -e "Transmission to ATPCO Successful at " `date` 

  # Cleanup -- remove file Transmitted to ATPCO (recover from archive directory if need be)
  echo -e "\nCleanup:  Removing $fare_file and $zip_file.zip from $OUTBOUND_WORK " 
  rm -f $OUTBOUND_WORK/$fare_file
  rm -f $OUTBOUND_WORK/$zip_file.zip

  # Remove diskio error log file (entire contents is in body of email, if any errors).  File will always exist.
  rm -f $error_log 

  # Remove f_ftp_log (f_ftp function's connection dialog with ATPCO remote system) (cat'd into main log file)
  rm -f $f_ftp_log

  # Update log for Customers, send email    
  echo -e "\n\nPRICING DEPARTMENT:  Contact ATPCO if you do not see this transmission in their systems promptly." >> $ftp_log
  /bin/mail -s "Distribution Sent to ATPCO: $fare_file" $successlist < $ftp_log

  # Display log file in stdlist  (it's already put into email above)
  echo -e "\n\n\nSuccessful Send.  Program ending."
  echo -e "\n*****************Logfile Follows (included in Email)******************\n"
  cat $ftp_log

else
  # Only way to get here is by exceeding max number of retries.
  # Log error         
  echo -e "\n\nERROR: DISTRIBUTION NOT SENT - $MaxRetry tries to send this file to ATPCO all failed." >> $ftp_log
  echo -e "Program will start trying again under a re-submitted TWS schedule." >> $ftp_log
  echo -e "\n\nPRODUCTION SUPPORT:  " >> $ftp_log
  echo "URGENT: If this email indicates a problem connecting or sending this file to ATPCO's FTP site," >> $ftp_log
  echo "  contact ATPCO Network Operations at (703) 471-7510 extension 1230 or 1789." >> $ftp_log

  echo -e "\n\nMaximum number of Retries ( $MaxRetry ) attempted. ERROR: Send to ATPCO Failed.  Will Auto-Retry under new schedule." 

  # Save active send file, send email saying we'll retry to send, exit
  error_exit $OUTBOUND_WORK/$fare_file
fi

# End of program
echo -e '\nSuccessful Completion at: ' `date`

# Exit with success  (note:  error_exit function is only other way of exiting this program)
exit 0

