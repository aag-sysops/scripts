#!/bin/bash

###**************************************************************************
. $HOME/bin/atpco_environment

let i=1
let maxi=100
fn=$INBOUND/PARG05.D080620.T2222.ZIP

echo "writing to $fn"
while [[ $i -lt $maxi ]] 
do
  echo "more data, round $i" >> $fn
  echo "added more data to $fn, round $i"
  sleep 1
  let i=i+1
done
