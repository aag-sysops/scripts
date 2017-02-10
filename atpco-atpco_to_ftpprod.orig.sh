#!/bin/sh
###**************************************************************************
### File name: atpco_to_ftpprod.sh   
###
### Description:  Transfer newly received ATPCO files to SEAVVPSMCFS/FTPPROD:
###                 Process all *.ZIP files found in $INBOUND directory: 
###                   Extract file(s) from .ZIP archive(s).
###                   Gzip file(s) for network transfer.
###                   FTP gzipped file(s) to SEAVVPSMCFS FTPPROD Production 
###                     and Test directories (inbound and inbound_test).
###                   FTP tag file to SEAVVPSMCFS FTPPROD inbound_test directory.
###
### Purpose:      Initiate Processing of Fares Files from ATPCO
###               Called by TWS Schedule RMAPFETCH
###
### Date     By       Description
### ------------------------------------------------
### 12/22/2003 dkim    Initial                     
### 05/10/2007 dkim    Added the file name to logfile name.             
### 04/23/2008 jgrant  Modify for New ATPCO transfer method.    
###                    Added ftp_check() method (from Prod Svcs) to verify
###                        FTP host is available.
###                    Modify f_ftp() method to take 3rd parm (dest path).
###                    Modify f_errcheck() method to treat known error-like
###                       messages from FTP server as non-errors; and to
###                       include any FTP dialog with errors in stdlist.
###                    Modify ls command to return filelist in timestamp order.
### 06/18/2008 jgrant  Modify 'ls' command sent to SEAVVFTP so that it only
###                      returns file names that meet our agreed-upon ATPCO
###                      naming convention, not any Revenue Accounting files.
###                    Add file-size checking logic to validate that file 
###                      transmission from ATPCO is complete before 
###                      continuing with uncompressing the file.
###**************************************************************************
###**************************************************************************
### Set values common environment variables for atpco userid
###**************************************************************************
. $HOME/bin/atpco_environment

###**************************************************************************
### Function Definitions                                    
###**************************************************************************

###**************************************************************************
# Function ftp_check checks for connectivity to an ftp host 
###**************************************************************************
function ftp_check 
{
  export function_host=$1

  if [ -z $function_host ]
  then
    echo -e "\nERROR: Missing FTP Host argument, this function 
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
    echo -e "\nERROR: UNABLE TO OPEN FTP SESSION TO $function_host
              CHECK THE NETWORK OR FTP HOST ($function_host) FOR PROBLEMS\n"
    cat ftp_results.$$
    cp ftp_results.$$ ftp_debug.$$
    rm ftp_results.$$
    exit 4
  else
    echo -e "connection to $function_host confirmed, processing continues...\n"
    rm ftp_results.$$
  fi

}

###**************************************************************************
# Function f_errcheck interprets potential errors grepped from FTP Dialog 
#   looking for true error conditions.
###**************************************************************************
f_errcheck()
{
  NULL="NULL"$1
  THISFILE=$2
  LOGFILE=$3
## If error string passed in is NULL, that's success.
  if [[ $NULL = "NULL" ]]
  then
     echo "FTP Transfer Successful for file: '$2'"
     return
  fi 
## Otherwise, parse string to determine if contents are actually errors.
## Display error string
# echo "f_errcheck: Value(s) passed in: '$1'"
## Known 'errors' that aren't really 'errors' are response strings:
#   'AUTH GSSAPI':
#   'AUTH KERBEROS_V4':
## Remove first Known 'Error' message
  rc2=`echo $1  | sed -e s/"'AUTH GSSAPI': "//`
## Remove second Known 'Error' message
  rc3=`echo $rc2  | sed -e s/"'AUTH KERBEROS_V4':"//`
## Remove third Known 'Error' message
  rc4=`echo $rc3  | sed -e s/"bytes sent"//`

## Check for null string -- indicates success!
  NULL="NULL"$rc4
  if [[ $NULL = "NULL" ]]
  then
     echo "FTP Transfer Successful for file: '$2'"
     return
  fi

## If anything left in error string, assume we had a problem...
  echo "ERROR: Error(s) found while sending file '$2': '$rc4'"
  echo -e "\nLogfile Name: $LOGFILE"                     
  echo -e "\nRemaining Files to Retrieve and Logfile Contents (FTP Dialog):\n`more $LOGFILE`"
  echo -e "\nNOTE:  If only the FTP Dialog appears above - with no preceding filelist - then this is the last (or only) file being retrieved."
  exit 4
}

###**************************************************************************
### Function f_ftp does FTP put to remote server 
###**************************************************************************
f_ftp()
{
ftp -v $ftphost_inbound << END_INPUT
cd $3
pwd
bin
put $1 $2
bye
END_INPUT
}

############################################################
#  Main module
############################################################
## Enable following command for debugging -- will show all command steps
##set -x

echo 'start time: ' `date` 

# Determine number of files received from ATPCO by counting .ZIP files present
filecount=`ls -1rt $INBOUND/*.D??????.T????.ZIP | wc -l`
echo -e "\nNumber of ATPCO fare files (*.D??????.T????.ZIP) found in directory $INBOUND: $filecount "

# If no files found, exit with error.
if [[ $filecount -lt 1 ]]
then
  echo -e "\nERROR:  No ATPCO fare files found in directory: $INBOUND"
  echo -e "        Look at most recent run of RMAPWATCH@ schedule;"
  echo -e "        It should not have submitted this schedule if there were no"
  echo -e "           *.D??????.T????.ZIP files in $INBOUND.  "
  echo -e "        If you verify no .ZIP files present, cancel this RMAPFETCH and" 
  echo -e "           resubmit RMAPWATCH under an alias."
  exit 4
fi

# Get List of new files from ATPCO to Process (in timestamp order).  
cd $INBOUND
ls -1rt *.D??????.T????.ZIP > $LOG/$ZIPFILENAME
echo -e "Processing Loop will Extract, gzip and FTP contents of each of these Files:\n`more $LOG/$ZIPFILENAME`"

# Set flag to indicate no files returned by ls command yet verified as truly existing; when verified, set to 1.
fileexists=0

## Read from $INBOUND, write extracted files to $INBOUND_WORK
## cd required because pkzipc extracts to current directory...  
cd $INBOUND_WORK

echo -e "\nExtracting to and Gzipping files in directory:  $INBOUND_WORK "
echo -e "\n--------------------------------------------------------" 
echo -e "Process Each .ZIP File "
echo -e "----------------------------------------------------------" 

# Process each file from List
while read -r thisFile 
do
    # Log Name of File in work
    echo -e "\nWorking on File (Extracting from):  $INBOUND/$thisFile "

    # Verify Transmission from ATPCO has completed by checking file size
    echo -e "\nVerify filesize is stable (that transmission from ATPCO is complete)"
    filesize1=`ls -l $INBOUND/$thisFile | awk '{print $5}'`
    echo "Current filesize is $filesize1  - will sleep for 10 secs and re-sample..."

    # Assume size is changing, sleep and re-check.  If truly changing, loop until stable.
    let changing=1
    while [[ $changing -eq 1 ]]
    do
      sleep 10
      filesize2=`ls -l $INBOUND/$thisFile | awk '{print $5}'`
      echo "Current filesize is $filesize2 "
      if [ $filesize1 -eq $filesize2 ]
      then
         let changing=0
      else
         let filesize1=$filesize2
         echo "File size changing... sleep for 10 secs and re-check..."
      fi
    done
    echo "File size stable at $filesize2.  Continuing"

    # If this file does not exist with a size greater than 0, log WARNING and move onto next file in list.
    if [[ ! -s $INBOUND/$thisFile ]]
    then 
      echo -e "\nWARNING: -s test on $INBOUND/$thisFile indicates this file does not exist with a size greater than 0"
      echo    "         Must be some weird text returned by 'ls -1rt $INBOUND/*.ZIP' command "
      echo -e "         Continuing to Process - moving to next filename in list from ls command."
      # Jump to top of while loop
      continue
    else
      # Set flag to indicate something made it thru this test; if nothing does, don't send tag file at bottom.
      fileexists=1
    fi 

    # Derive filename for extracted file -- will be used to confirm file created by pkzipc
    filename=`echo $thisFile | sed -e s/.ZIP//`
    echo -e "\nExpecting pkzipc to extract filename: $filename "

    # Extract File from .ZIP archive - remove expected extracted file first, in case re-running.
    rm -f $filename
    pkzipc -extract -password=$password $INBOUND/$thisFile

    # Check return code from pkzipc - if non-zero, log error and exit.
    pkzipc_rc=$?
    if [[ $pkzipc_rc -ne 0 ]]
    then
      echo -e "\nERROR:  pkzipc returned $pkzipc_rc"
      echo    "     Check for Disk Full."
      exit 4 
    fi

    # Check expected file exists and has size greater than 0. If not, exit with Error.
    if [[ ! -s $filename ]]
    then
      echo -e "\nERROR: $filename failed -s test (file doesn't exist with non-zero size)."
      echo -e "  Expected it to be Extracted from $INBOUND/$thisFile into directory $INBOUND_WORK."
      echo -e "  Check for Disk Full. "
      echo -e "  Confirm that pkzipc 'Inflating' filename in this log matches filename: $filename.\n"
      exit 4
    fi

    # Derive filename for gzipped file -- will be used to confirm file is gzipped
    gzfilename="$filename.gz"

    # Gzip File for transfer across Network - remove target file first, then gzip.
    echo -e "\ngzipping file: $filename into $gzfilename"
    rm -f $gzfilename
    gzip $filename

    # Check return code from gzip - if non-zero, log error and exit.
    gzip_rc=$?
    if [[ $gzip_rc -ne 0 ]]
    then
      echo -e "\nERROR:  gzip returned $gzip_rc"
      echo    "     Check for Disk Full."
      exit 4 
    fi

    # Log error and exit if file gzip should have created doesn't exist with size greater than 0.
    if [[ ! -s $gzfilename ]]
    then
      echo -e "\nERROR: $gzfilename failed -s test (file doesn't exist with non-zero size)."
      echo -e "    gzip of $filename failed in directory $INBOUND_WORK."
      echo -e "  Check for Disk Full "
      exit 4
    fi

    # Confirm Connectivity to seavvpsmcfs FTP server
    ftp_check $ftphost_inbound

    # FTP .gz file to seavvpsmcfs server Production Directory
    echo -e   "Initiating FTP Put for Prod to: $ftphost_inbound $FTPHOST_ATPCO_IN/$filename" 
    echo -e   ">>> Log of FTP Session available on $HOSTNAME at $LOG/$filename.$FTP_RESULT" 
    echo -e "\n-----------------------------------"                                          >> $LOG/$filename.$FTP_RESULT
    echo -e "\nInitiating FTP Put for Prod to: $ftphost_inbound $FTPHOST_ATPCO_IN/$filename" >> $LOG/$filename.$FTP_RESULT 
    f_ftp $gzfilename $gzfilename $FTPHOST_ATPCO_IN                                          >> $LOG/$filename.$FTP_RESULT
    rc=`awk '$1<599&&$1>400  {print $2,$3}' $LOG/$filename.$FTP_RESULT`
    f_errcheck "$rc" "$filename" "$LOG/$filename.$FTP_RESULT"
 
    # FTP .gz file to seavvpsmcfs server Test Directory
    echo -e "\nInitiating FTP Put for Test to: $ftphost_inbound $FTPHOST_ATPCO_IN_TEST/$filename" 
    echo -e   ">>> Log of FTP Session available on $HOSTNAME at $LOG/$filename.$FTP_RESULT" 
    echo -e "\n-----------------------------------"                                             >> $LOG/$filename.$FTP_RESULT
    echo -e "\nInitiating FTP Put for Test to: $ftphost_inbound $FTPHOST_ATPCO_IN_TEST/$filename" >> $LOG/$filename.$FTP_RESULT 
    echo -e "See Logfile:  $LOG/$filename.test.$FTP_RESULT"                                     >> $LOG/$filename.$FTP_RESULT 
    f_ftp $gzfilename $gzfilename $FTPHOST_ATPCO_IN_TEST                                        >> $LOG/$filename.test.$FTP_RESULT
    rc=`awk '$1<599&&$1>400  {print $2,$3}' $LOG/$filename.test.$FTP_RESULT`
    f_errcheck "$rc" "$filename" "$LOG/$filename.test.$FTP_RESULT"
 
    echo -e "\nProcessing Complete for '$filename' from '$INBOUND/$thisFile' "
    echo -e "---------------------------------------------------------------------" 

done < $LOG/$ZIPFILENAME

# Check flag set when we verified existence of each file returned by ls -1rt *.ZIP command - if none passed, Error out.
if [[ $fileexists -eq 1 ]]
then
  # Send tag file to Test (required by ICSTEST RMAPFETCH)
  echo -e "\nInitiating FTP Put for Test tagfile to: $ftphost_inbound $FTPHOST_ATPCO_IN_TEST/$ZIPFILENAME.tag"
  echo -e   ">>> Log of FTP Session available on $HOSTNAME at $LOG/$ZIPFILENAME.$FTP_RESULT" 
  f_ftp $LOG/$ZIPFILENAME $ZIPFILENAME.tag $FTPHOST_ATPCO_IN_TEST >> $LOG/$ZIPFILENAME.$FTP_RESULT
  rc=`awk '$1<599&&$1>400  {print $2,$3}' $LOG/$ZIPFILENAME.$FTP_RESULT`
  f_errcheck "$rc" "$ZIPFILENAME.tag" "$LOG/$ZIPFILENAME.$FTP_RESULT" 
else
  echo -e "\nERROR: -s test on every file in list returned by ls command indicates file does not exist with a size greater than 0"
  echo    "         Must be some weird text returned by 'ls -1rt $INBOUND/*.ZIP' command "
  echo -e "     Look at most recent run of RMAPWATCH@ schedule;"
  echo -e "     It should not have submitted this schedule if there were no"
  echo -e "         .ZIP files in $INBOUND.  "
  echo -e "     If you verify no .ZIP files present, cancel this RMAPFETCH and" 
  echo -e "         resubmit RMAPWATCH under an alias."
  exit 4
fi

echo -e '\nEnd time: ' `date`
