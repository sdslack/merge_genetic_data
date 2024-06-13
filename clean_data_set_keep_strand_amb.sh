#!/bin/bash

if [ "$#" -eq 0 ]
then
   echo "Usage: ${0##*/} <plink_in_file> <plink_prefix>"
   echo "Cleans PLINK1.9 data in preparation of merge: removes"
   echo "non-autosomal SNPs, duplicate varIDs, updates varIDs"
   echo "to chr:pos, and removes SNPs with duplicate positions."
   echo "Keeps strand ambiguous SNPs."
   exit
fi

plink_in_file=$1
plink_prefix=$2

#Remove all non-autosomal SNPs
plink --bfile $plink_in_file \
   --autosome \
   --keep-allele-order \
   --make-bed --out ${plink_in_file}_autosome

#Remove all variants with duplicate IDs
cat ${plink_in_file}_autosome.bim | awk '{print $2}' | sort \
   | uniq -d > ${plink_in_file}_dupl_snp_ids.txt
plink --bfile ${plink_in_file}_autosome \
   --exclude ${plink_in_file}_dupl_snp_ids.txt \
   --keep-allele-order \
   --make-bed --out ${plink_in_file}_autosome_no_dupl_snp_ids

#Update PLINK SNP names as chr:position
cat ${plink_in_file}_autosome_no_dupl_snp_ids.bim \
   | awk '{print $2"\t"$1":"$4}' > ${plink_in_file}_new_snp_ids.txt
plink --bfile ${plink_in_file}_autosome_no_dupl_snp_ids \
   --update-map ${plink_in_file}_new_snp_ids.txt --update-name \
   --keep-allele-order \
   --make-bed --out ${plink_in_file}_autosome_no_dupl_snp_ids_chr_pos_snp_ids

#Remove all variants with duplicate positions
cat ${plink_in_file}_autosome_no_dupl_snp_ids_chr_pos_snp_ids.bim \
   | awk '{print $2}' | sort | uniq -d > ${plink_in_file}_dupl_pos_snps.txt
plink --bfile ${plink_in_file}_autosome_no_dupl_snp_ids_chr_pos_snp_ids \
   --exclude ${plink_in_file}_dupl_pos_snps.txt \
   --keep-allele-order \
   --make-bed --out ${plink_in_file}_clean
