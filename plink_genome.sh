#!/bin/bash

if [ "$#" -eq 0 ]
then
   echo "Usage: ${0##*/} <plink_bed> <out_dir> <window_size>"
   echo "         <step_size> <r2>"
   echo "Runs LD pruning with PLINK1.9 --indep-pairwise and then"
   echo "runs PLINK1.9 --genome on pruned data."
   exit
fi

plink_bed=$1
out_dir=$2
window_size=$3  # window size in kb, e.g. 10000
step_size=$4  # e.g. 5
r2=$5  # e.g. 0.1

# Get basename of plink_bed_dir
plink_in_file=`echo $plink_bed | sed 's/.bed//'`  # has path, no .bed
plink_name=`basename $plink_in_file`  # removes path, prefix only

plink --bfile $plink_in_file \
   --keep-allele-order \
   --indep-pairwise ${window_size}['kb'] $step_size $r2 \
   --out ${out_dir}/${plink_name}_to_prune

plink --bfile $plink_in_file \
   --extract ${out_dir}/${plink_name}_to_prune.prune.in \
   --keep-allele-order \
   --make-bed --out ${out_dir}/${plink_name}_pruned

plink --bfile ${out_dir}/${plink_name}_pruned \
   --keep-allele-order \
   --genome \
   --out ${out_dir}/${plink_name}_pruned_ibd
