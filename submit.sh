#!/bin/bash
# Simple script to automate susbmitting assembly jobs to SGE
# for different hash lengths


FORWARD_FILE=P.cact_411_1M_F_trim.fastq
REVERSE_FILE=P.cact_411_1M_F_trim.fastq
ASSEMBLY_NAME=P.cact.auto

cd $PWD
for HASH_LENGTH in $( seq 21 2 51 ); do
	qsub ~/scripts/align.sh $HASH_LENGTH $FORWARD_FILE $REVERSE_FILE $ASSEMBY_NAME
done
