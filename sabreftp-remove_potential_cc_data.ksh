#!/bin/ksh

###########################################################################
###########################################################################
##									 ##
##									 ##
##  This script converts any 16-digit numbers, with no spaces, into      ##
##    "XXXAAG_MASKEDXXX".  Any occurrence of 16 digits, with spaces      ##
##    between groupings of 4, are converted to "XXXA AG_M ASKE DXXX".    ##
##									 ##
##									 ##
##		Original Version:  September 2014  Dwight K. Guy	 ##
##									 ##
##									 ##
##									 ##
###########################################################################
###########################################################################

###########################################################################
###########################################################################
##									 ##
##									 ##
##  On 9/11/14, it was decided to not track which files were modified    ##
##    and e-mail the list.  Therefore, all code which contributed to     ##
##    this were commented out with 5 hash marks (#####).                 ##
##									 ##
##                                - Dwight K . Guy                       ##
##									 ##
##									 ##
###########################################################################
###########################################################################

###########################################################################
###########################################################################
##									 ##
##									 ##
##  On 12/1/14, it was decided to track which files were modified        ##
##    and e-mail the list.  Therefore, all code which contributed to     ##
##    this were uncommented out. And all code that contradicted this     ##
##    was commented out with 6 hash marks (######).                      ##    
##									 ##
##                                - Dwight K . Guy                       ##
##									 ##
##									 ##
###########################################################################
###########################################################################

exec_date=`date +%y%m%d_%H%M%S`
outfile=modfied_files_${exec_date}.lst
mail_list="sopheak.chea@alaskaair.com"
###mail_list="big.problem.tickets@alaskaair.com,sopheak.chea@alaskaair.com"
###mail_list="vipul.saxena@alaskaair.com,debbie.mcglenn@alaskaair.com,sopheak.chea@alaskaair.com"
###mail_list="dwight.guy@alaskaair.com,debbie.mcglenn@alaskaair.com,vince.caputo@alaskaair.com,sopheak.chea@alaskaair.com"
###mail_list="dwight.guy@alaskaair.com"

###echo "Mail recipients are:  $mail_list"
###exit

if [ -a ${outfile} ];then
  rm ${outfile}
fi

for a in `ls *.dat`
do
  fname=`echo ${a}| awk -F ".dat" '{ print $1 }'`
###  echo "File Name = ${fname}"
  infname=${fname}.dat
  scrubbed_fname1=${fname}.scrubbed1
  scrubbed_fname=${fname}.scrubbed
  
###  sed 's/[0-9]\{4\}[0-9]\{4\}[0-9]\{4\}[0-9]\{4\}/8888888888888888/g' ${infname} > ${scrubbed_fname1}

  sed 's/[0-9]\{4\}[0-9]\{4\}[0-9]\{4\}[0-9]\{4\}/XXXAAG_MASKEDXXX/g' ${infname} > ${scrubbed_fname1}


###  sed 's/[0-9]\{4\} [0-9]\{4\} [0-9]\{4\} [0-9]\{4\}/8888 8888 8888 8888/g' ${scrubbed_fname1} > ${scrubbed_fname}
  sed 's/[0-9]\{4\} [0-9]\{4\} [0-9]\{4\} [0-9]\{4\}/XXXA AG_M ASKE DXXX/g' ${scrubbed_fname1} > ${scrubbed_fname}

  
######  sed 's/[0-9]\{4\} [0-9]\{4\} [0-9]\{4\} [0-9]\{4\}/XXXA AG_M ASKE DXXX/g' ${scrubbed_fname1} > ${infname}


###echo "infname = ${infname}."
###echo "scrubbed_fname = ${scrubbed_fname}."

###echo "  if diff ${infname} ${scrubbed_fname};then "

  if ! /usr/bin/diff ${infname} ${scrubbed_fname} >/dev/null
  then
    echo "${infname} was modified." >> ${outfile}
    mv ${scrubbed_fname} ${infname}
  else
    rm ${scrubbed_fname}
  fi
  
######if [ -a ${infname} ];then
######  rm ${infname}
######fi

if [ -a ${scrubbed_fname1} ];then
  rm ${scrubbed_fname1}
###       echo "Empty if loop."
fi

done

if [ -a ${outfile} ];then
###  /bin/mailx -s "TDB Files Modified." dwight.guy@alaskaair.com < ${outfile}
  /bin/mailx -s "TDB Files Modified ${exec_date}" $mail_list < ${outfile}
  rm ${outfile}
fi
