#!/bin/sh
###**************************************************************************
### File name: atpco_clean.sh   
###
### Description:   removes all files ftp'd to asprodftp
###
### Purpose:  Called by TWS RMAPFETCH schedule to remove files on seavvftp.
###
### Date     By       Description
### ------------------------------------------------
### 12/22/2003 dkim    initial                     
### 04/26/2008 jgrant  Modify for new ATPCO Connectivity, migration to seavvftp.
###                    - Remove $INBOUND and $INBOUND_WORK files per list.
###                    - Remove $LOG files more than 180 days old.
###                    - Remove $OUTBOUND_ARCHIVE fare files > 180 days old.
###                    - Remove $OUTBOUND_WORK fare files > 180 days old.
###**************************************************************************
###**************************************************************************
###  variables are defined in $HOME/bin/atpco_environment
###**************************************************************************
. $HOME/bin/atpco_environment

###**************************************************************************
# Function Definitions
###**************************************************************************

###**************************************************************************
## Function archive_clean removes old files
###**************************************************************************
function archive_clean {

export directory=$1
export prefix=$2
export fileage=$3

echo -e "\nremove files older than $fileage days from $directory"

        find $directory/*$prefix* -mtime +$fileage -print |
        while read FILE1
        do
        echo "deleting file $FILE1"
        rm -f $FILE1
        done
}

###**************************************************************************
### Function f_errcheck check for errors 
###**************************************************************************
f_errcheck()
{
  if [[ $# -gt 1 ]]
  then
     echo "Error removing file '$1'"
     exit 4
  else
     echo "...successfully removed file '$1'"
     echo
  fi 
}

############################################################
#  Main module
############################################################

echo 'start time: ' `date` 
echo -e "\nNote: Will also remove .gz version of following files from $INBOUND_WORK."
echo -e "\nFiles to remove from directory $INBOUND:\n`more $LOG/$ZIPFILENAME`"

# Process entire list of files sent to Windows, remove each one.
  while read -r thisFile 
    do
      echo "-----------------------------------" 
      echo "...removing "$INBOUND/$thisFile   
      rm -f $INBOUND/$thisFile 
      f_errcheck $rc "$thisFile" 
      gzfilename=`echo $thisFile | sed -e s/.ZIP/.gz/`
      echo "...removing "$INBOUND_WORK/$gzfilename 
      rm -f $INBOUND_WORK/$gzfilename
      f_errcheck $rc "$gzfilename" 
  done < $LOG/$ZIPFILENAME 

# Remove List of Files
rm $LOG/$ZIPFILENAME 

# Remove inbound and outbound ftp log files older than 180 days
export FileAge=180
export filepat=.ftp
archive_clean $LOG $filepat $FileAge

# Remove log files for sends to ATPCO older than 180 days
export FileAge=180
export filepat=XAS.
archive_clean $LOG $filepat $FileAge

# Remove orphaned outbound.work files older than 180 days
export FileAge=180
export filepat=XAS.
archive_clean $OUTBOUND_WORK $filepat $FileAge

# Remove fare files sent to ATPCO more than 180 days ago
export FileAge=180
export filepat=XAS.
archive_clean $OUTBOUND_ARCHIVE $filepat $FileAge

# End program
echo "atpco_clean.sh complete."
echo 'end time: ' `date`

