#!/bin/bash

# A simple script to compile and run the testbench on your server
# Assuming you have VCS or Xcelium installed.

echo "=============================================="
echo "    Compiling and Running MM_GM Testbench     "
echo "=============================================="

# If using VCS:
# vcs -full64 -sverilog -debug_access+all -f filelist.f -timescale=1ns/1ps -l compile.log
# ./simv -l run.log

# If using Xcelium (xrun):
xrun -64bit -sv -access +rwc -f filelist.f -timescale 1ns/1ps -l xrun.log

echo "Done. Please check the logs (compile.log / run.log or xrun.log)."
