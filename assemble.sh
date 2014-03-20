#!/bin/bash 
# Assemble contigs using velvet and generate summary statistics using
# process conitgs

HASH_LENGTH=$1
EXT_FILE=$2
FORWARD_FILE=$3
REVERSE_FILE=$4
ASSEMBLY_NAME=$5
EXP_COV=$6
COV_CUT=$7
WORK_DIR=$TMPDIR

echo "Hash length is $HASH_LENGTH"
echo "Forward file is $FORWARD_FILE"
echo "Reverse file is $REVERSE_FILE"
echo "Assembly name is $ASSEMBLY_NAME"

#######  Step 1  ########
#       Assemble        #
#########################

velveth $WORK_DIR $HASH_LENGTH -fastq -short $EXT_FILE -shortPaired2 -separate $FORWARD_FILE $REVERSE_FILE
velvetg $WORK_DIR -exp_cov $EXP_COV -cov_cutoff $COV_CUT -ins_length2 700 -min_contig_lgth 500
process_contigs.pl -i $WORK_DIR/contigs.fa -o $ASSEMBLY_NAME.$HASH_LENGTH

#######  Step 2  ########
#   Assembly details    #
#########################

N50=$( head -n1 $ASSEMBLY_NAME.$HASH_LENGTH/stats.txt | cut -f2 -d' ' )
echo "storing the N50 value: $N50"

MAX_CONTIG=$( grep 'Max_contig' $ASSEMBLY_NAME.$HASH_LENGTH/stats.txt | cut -f2 -d' ' )
echo "storing the maximum conitg size: $MAX_CONTIG"

NO_CONTIG=$( grep 'Number of contigs' $ASSEMBLY_NAME.$HASH_LENGTH/stats.txt | head -n1 | cut -f4 -d' ' )
echo "storing the number of conitgs: $NO_CONTIG"

NO_BP=$( grep 'Number of bases' $ASSEMBLY_NAME.$HASH_LENGTH/stats.txt | head -n1 | cut -f6 -d' ' )
echo "storing the size of the assembled genome: $NO_BP"

echo "$ASSEMBLY_NAME	$EXP_COV	$HASH_LENGTH	$N50	$MAX_CONTIG	$NO_CONTIG	$NO_BP" >> "$ASSEMBLY_NAME"_stats.txt

#######  Step 3  ########
#       Cleanup         #
#########################

rm -r $WORK_DIR
