#!/bin/bash

#######  Step 1	 ########
# 	Initialise values	#
#########################

F_READ='P.cact_411_1M_F.fastq.gz'
R_READ='P.cact_411_1M_R.fastq.gz'

$F_TRIM=(echo $F_READ | tr -d '.gz')
$R_TRIM=(echo $F_READ | tr -d '.gz')

echo "your forward read is: $F_READ"
echo "your reverse read is: $R_READ"

echo "your trimmed forward read will be named: $F_TRIM"
echo "your trimmed reverse read will be named: $R_TRIM"
