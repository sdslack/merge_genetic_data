#!/bin/bash

if [ "$#" -eq 0 ]
then
   echo "Usage: ${0##*/} <study1_plink_bed_file> <study2_plink_bed_file>"
   echo "       <min_maf> <min_geno>"
   echo "Merges two PLINK1.9 datasets after first cleaning them with"
   echo "clean_data_set.sh. Flips SNPs as needed and excludes any"
   echo "allele mismatches. Cleans final merge."
   exit
fi

study1_plink_bed_file=$1
study2_plink_bed_file=$2
min_maf=$3
min_geno=$4
study1_plink_in_prefix=`echo $study1_plink_bed_file | sed 's/.bed//' | sed 's/.BED//'` 
study2_plink_in_prefix=`echo $study2_plink_bed_file | sed 's/.bed//' | sed 's/.BED//'` 
study1_plink_prefix=`basename $study1_plink_in_prefix` 
study2_plink_prefix=`basename $study2_plink_in_prefix` 

#Clean the data sets
bash /home/sslack@xsede.org/code/immunogenetics_t1d/daisy_complement/ibd_check/clean_data_set.sh \
   $study1_plink_in_prefix $study1_plink_prefix
bash /home/sslack@xsede.org/code/immunogenetics_t1d/daisy_complement/ibd_check/clean_data_set.sh \
   $study2_plink_in_prefix $study2_plink_prefix

#Get a list of common markers
cat ${study1_plink_prefix}_clean.bim ${study2_plink_prefix}_clean.bim | awk '{print $2}' \
   | sort | uniq -d > ${study1_plink_prefix}_${study1_plink_prefix}_common_snps.txt
plink --bfile ${study1_plink_prefix}_clean \
   --extract ${study1_plink_prefix}_${study1_plink_prefix}_common_snps.txt \
   --keep-allele-order \
   --make-bed --out ${study1_plink_prefix}_common
plink --bfile ${study2_plink_prefix}_clean \
   --extract ${study1_plink_prefix}_${study1_plink_prefix}_common_snps.txt \
   --keep-allele-order \
   --make-bed --out ${study2_plink_prefix}_common

#First merge attempt
plink --bfile ${study1_plink_prefix}_common \
   --bmerge ${study2_plink_prefix}_common \
   --keep-allele-order \
   --make-bed --out ${study1_plink_prefix}_${study2_plink_prefix}_merged1

#Flip SNPs where necessary
if [ -e "${study1_plink_prefix}_${study2_plink_prefix}_merged1-merge.missnp" ]
then
   plink --bfile ${study2_plink_prefix}_common \
      --flip ${study1_plink_prefix}_${study2_plink_prefix}_merged1-merge.missnp \
      --keep-allele-order \
      --make-bed --out ${study2_plink_prefix}_common_flipped
   plink --bfile ${study1_plink_prefix}_common \
      --bmerge ${study2_plink_prefix}_common_flipped \
      --keep-allele-order \
      --make-bed --out ${study1_plink_prefix}_${study2_plink_prefix}_merged2
else
   plink --bfile ${study1_plink_prefix}_${study2_plink_prefix}_merged1 \
      --keep-allele-order \
      --make-bed --out ${study1_plink_prefix}_${study2_plink_prefix}_merged2
fi

#Exclude allele mismatch SNPs
if [ -e "${study1_plink_prefix}_${study2_plink_prefix}_merged2-merge.missnp" ]
then
   plink --bfile ${study1_plink_prefix}_common \
      --exclude ${study1_plink_prefix}_${study2_plink_prefix}_merged2-merge.missnp \
      --keep-allele-order \
      --make-bed --out ${study1_plink_prefix}_common_no_mismatches
   plink --bfile ${study2_plink_prefix}_common_flipped \
      --exclude ${study1_plink_prefix}_${study2_plink_prefix}_merged2-merge.missnp \
      --keep-allele-order \
      --make-bed --out ${study2_plink_prefix}_common_no_mismatches
   plink --bfile ${study1_plink_prefix}_common_no_mismatches \
      --bmerge ${study2_plink_prefix}_common_no_mismatches \
      --keep-allele-order \
      --make-bed --out ${study1_plink_prefix}_${study2_plink_prefix}_merged3
else
   plink --bfile ${study1_plink_prefix}_${study2_plink_prefix}_merged2 \
      --keep-allele-order \
      --make-bed --out ${study1_plink_prefix}_${study2_plink_prefix}_merged3
fi

#Remove SNPs with large missingness and apply MAF filter
plink --bfile ${study1_plink_prefix}_${study2_plink_prefix}_merged3 \
   --geno $min_geno --maf $min_maf \
   --keep-allele-order \
   --make-bed --out ${study1_plink_prefix}_${study2_plink_prefix}_merged_clean
