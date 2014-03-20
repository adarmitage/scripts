#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -pe smp 16
#$ -l virtual_free=5G
#$ -M andrew.armitage@emr.ac.uk
#$ -m abe

# Script to prepare data for genome assembly including
#  flash-extending reads, trimming and estimating coverage
# Usage: seq_prep.sh <F_read.fastq.gz> <R_read.fastq.gz>

#######  Step 1	 ########
# Initialise values	#
#########################

F_IN=$1
R_IN=$2

F_READ_ZIP=$(echo $F_IN | sed 's/.fastq.gz/.copy.fastq.gz/')
R_READ_ZIP=$(echo $R_IN | sed 's/.fastq.gz/.copy.fastq.gz/')

F_READ=$(echo $F_READ_ZIP | sed 's/.gz//')
R_READ=$(echo $R_READ_ZIP | sed 's/.gz//')

ASSEMBLY_NAME=$(echo $F_READ | sed 's/_F.copy.fastq//')

EXTENDED_READ=$ASSEMBLY_NAME.extendedFrags.fastq
F_REMAINDER=$ASSEMBLY_NAME.notCombined_1.fastq
R_REMAINDER=$ASSEMBLY_NAME.notCombined_2.fastq

EXTENDED_READ_TRIM="$ASSEMBLY_NAME""_ext_trim.fastq"
F_REMAINDER_TRIM="$ASSEMBLY_NAME""_F_trim.fastq"
R_REMAINDER_TRIM="$ASSEMBLY_NAME""_R_trim.fastq"

ILLUMINA_ADAPTERS=/home/armita/idris/scripts/illumina_full_adapters.fa

echo "your compressed forward read is: $F_IN"
echo "your compressed reverse read is: $R_IN"
	echo ""
echo "your forward read is: $F_READ"
echo "your reverse read is: $R_READ"
	echo ""
echo "your Flash outfiles will be given the prefix: $ASSEMBLY_NAME"
echo "the extended reads will be named: $EXTENDED_READ"
echo "the remaining forwards reads will be named: $F_REMAINDER"
echo "the remaining reverse reads will be named: $R_REMAINDER"
	echo ""
echo "illumina adapters are stored in the file: $ILLUMINA_ADAPTERS"
	echo ""
echo "your trimmed extended reads will be stored in the file $EXTENDED_READ_TRIM"
echo "your trimmed forwards reads will be stored in the file $F_REMAINDER_TRIM"
echo "your trimmed reverse reads will be stored in the file $R_REMAINDER_TRIM"


#######  Step 2	 ########
# 	unzip reads			#
#########################


cp $F_IN $F_READ_ZIP
cp $R_IN $R_READ_ZIP

gunzip $F_READ_ZIP
gunzip $R_READ_ZIP


#######  Step 3	 ########
# 	Flash reads			#
#########################

flash $F_READ $R_READ -o $ASSEMBLY_NAME


#######  Step 4	 ########
# 	Quality trim		#
#########################

fastq-mcf $ILLUMINA_ADAPTERS $EXTENDED_READ -o $EXTENDED_READ_TRIM -C 1000000 -u -k 20 -t 0.01 -q 30 -p 5

fastq-mcf $ILLUMINA_ADAPTERS $F_REMAINDER $R_REMAINDER -o $F_REMAINDER_TRIM -o $R_REMAINDER_TRIM -C 1000000 -u -k 20 -t 0.01 -q 30 -p 5


#######  Step 5	 ########
# 	Estimate coverage	#
#########################

EST_COV_EXT=$(count_nucl.pl -i $EXTENDED_READ_TRIM -g 65 | tail -n1 | cut -d ' ' -f10)

EST_COV_REMAINDER=$(count_nucl.pl -i $F_REMAINDER_TRIM -i $R_REMAINDER_TRIM -g 65 | tail -n1 | cut -d ' ' -f10)

COVERAGE=$(perl -e '$sum=$ARGV[0]+$ARGV[1]; print "$sum\n";exit;' $EST_COV_EXT $EST_COV_REMAINDER)
MIN_COV=$(perl -e '$sum=$ARGV[0]/3; print "$sum\n";exit;' $COVERAGE)
echo ""
echo "the estimated coverage of the extended sequences is: $EST_COV_EXT"
echo "the estimated coverage of the forward and reverse reads is: $EST_COV_REMAINDER"

echo "the estimated combined coverage is: $COVERAGE"


#######  Step 6	 ########
# 	Cleanup		#
#########################

rm $F_READ
rm $R_READ

rm $ASSEMBLY_NAME.*


#######  Step 7	 ########
# 	Assemble	#
#########################

echo "ASSEMBLY_NAME    EXP_COV        HASH_LENGTH	N50	MAX_CONTIG	NO_CONITG	NO_BP" > "$ASSEMBLY_NAME"_stats.txt

cd $PWD
for HASH_LENGTH in $( seq 41 10 101 ); do
        /home/armita/scripts/assemble.sh $HASH_LENGTH $EXTENDED_READ_TRIM $F_REMAINDER_TRIM $R_REMAINDER_TRIM $ASSEMBLY_NAME $COVERAGE $MIN_COV
done


#######  Step 8  ########
#       Cleanup         #
#########################

gzip *.fastq
