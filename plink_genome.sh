#!/bin/bash

plink_bed_file=$1
window_size=$2  # window size in kb, e.g. 10000
step_size=$3  # e.g. 5
r2=$4  # e.g. 0.1

plink_in_file=`echo $plink_bed_file | sed 's/.bed//'`

plink --bfile $plink_in_file \
   --keep-allele-order \
   --indep-pairwise ${window_size}['kb'] $step_size $r2 \
   --out ${plink_in_file}_to_prune

plink --bfile $plink_in_file \
   --extract ${plink_in_file}_to_prune.prune.in \
   --keep-allele-order \
   --make-bed --out ${plink_in_file}_pruned

plink --bfile ${plink_in_file}_pruned \
   --keep-allele-order \
   --genome \
   --out ${plink_in_file}_pruned_ibd
