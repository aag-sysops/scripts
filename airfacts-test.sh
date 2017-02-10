#!/bin/bash

set -x
export outbound_dir=$HOME/outbound
export namebase=ASoag

cd $outbound_dir

export sim_file=`ls -1 ${namebase}*`
export sim_year=`head -10 $sim_file | grep -v 00000000 | tail -1 | cut -c70-71`
let name_size=`echo $sim_file | wc -c`-1
export suffix=`echo $sim_file | cut -c10-$name_size`
sim_out_file=`echo $sim_file | cut -c1-9`$sim_year`echo $suffix` 
export done_file=${sim_out_file}.done
export arch_name=`echo $sim_file | sed -e 's/.txt//'`
export zip_name=${arch_name}.zip
export reldate=`head -10 $sim_file | grep -v 00000000 | tail -1 | cut -c65-71`

mv -fv $sim_file $sim_out_file
#touch $done_file
