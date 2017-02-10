#!/bin/sh

export checkcnt=0

function mainproc {

# set unzipped file name variable
export data_file=`echo $FILE1 | sed -e s/.zip/.txt/`

# unzip
unzip $FILE1

# ftp to asprodftp
ftp asprodftp $data_file

# archive
mv $FILE1 $inbound_archive/$data_file.$datestamp.zip

# remove old files
archive_clean

}

set -x
#cd inbound

	ls -1 | while read FILE1
	do
	startsize=`ls -l $FILE1 | awk '{print $5}'`
	sleep 15
	endsize=`ls -l $FILE1 | awk '{print $5}'`
	
	if [ $startsize -eq $endsize ]; then
	mainproc
	fi

	done
