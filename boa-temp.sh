#!/bin/bash

# Set up the BOA solar enrollment data transfer environment
# This script is used by other scripts to preset values from a common source.
# Usage: (in another script) ". $HOME/bin/solarenroll_new_environment"

#IR056179 - 11/8/2013 - added dateparm2 & updated the info_to variable. Tsonnen.

export PGPPASS=seavvdmzftp
export remote_sig=BOAPUBKY
export ftp_host=elink-ftp4.bankofamerica.com
#export ftp_local_host=testftp
export ftp_local_host=asprodftp
export outbound_dir=$HOME/outbound
export outbound_archive=${outbound_dir}.archive
export inbound_dir=$HOME/inbound
export inbound_archive=${inbound_dir}.archive
export DT=`date '+%c'`
export info_to="alaskarewardsfileconf@bankofamerica.com,tyler.sonnen@alaskaair.com"
export datestamp=`/bin/date '+%b%d%Y.%H%M'`
export datestamp2=`/bin/date '+%b.%d.%Y'`
export outdate=`/bin/date '+%Y%m%d'`
export errors_to="production.services@alaskaair.com"
export logfile=$HOME/transfer_log
export FileAge=99

. /opt/local/ops_scripts/function_lib

function inproc {

cd $inbound_dir

echo -e "\ndecrypt $local_pgp_file" 
echo $PGPPASS | gpg --passphrase-f 0 --batch --output $local_file --decrypt $local_pgp_file

set -x
	result=$?
set +x

	if [ $result -ne 0 -o ! -s $local_file ]; then
	echo -e "\n`whoami` $local_pgp_file decrypt problem.\n"
	exit 8
	fi

echo -e "\nmake record length 450 for all records"
$HOME/bin/450.pl $local_file > $crl_file

	result=$?

	if [ $result -ne 0 ]; then
	echo -e  "\nchange record length failed, contact EPS"
	exit 4
	fi

record_count=`wc -l $crl_file | awk '{print $1}'`
MSG="$crl_file record count is $record_count on `date`"
echo -e "\n$MSG"


ftp_vendor $ftp_local_host $crl_file $crl_file "cd MPPROD/BofAEnrollment/Input"

echo -e "\nmove $local_pgp_file to archive directory and timestamp"
mv $local_pgp_file $inbound_archive/$local_pgp_file.$datestamp

echo "remove temp files"
rm -f $local_file $crl_file $local_pgp_file

archive_clean $inbound_archive $local_pgp_file $FileAge

}
