#!/bin/bash

rm -rf xvlog*
rm -rf xelab*
rm -rf xsim*
rm snap1.*

xvlog -sv ${1}.sv
if [ -f "${1}_tb.sv" ];
then
  xvlog -sv ${1}_tb.sv
fi
xelab ${2} --snap snap1
xsim snap1 -t run.tcl ${3}
