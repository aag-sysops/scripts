#!/bin/bash

export pgppass=seavvdmzftp
export pgp_rem_sig="30DA6CFA"
export outbound_dir=$HOME/outbound
export outfile_prefix=WYWYNDHAMPITexport
outdate=`date +%y%m%d`
export sftp_host=chanthni@198.246.150.12

. /opt/local/ops_scripts/function_lib

sftp -v $sftp_host <<TEST >ftp_results.$$ 
	cd incoming
	dir
	bye
TEST

