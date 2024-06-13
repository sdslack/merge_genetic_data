#!/bin/bash

if [ "$#" -eq 0 ]
then
   echo "Usage: ${0##*/} <plink_path> <from_build (hg19 or hg38)>"
   echo "      <to_build (hg19 or hg38)> <out_dir>"
   echo "Cleans PLINK1.9 data using PLINK2 in preparation of merge:"
   echo "removes non-autosomal SNPs and SNPs with duplicate positions,"
   echo "lifts over from current build to desired build, updates varIDs"
   echo "to chr:pos:ref:alt, and removes SNPs with duplicate IDs. If no"
   echo "liftover is needed, set from_build and to_build inputs to the"
   echo "the same value."
   exit
fi

plink_path=$1
plink_prefix=$(basename "$plink_path")
from_build=$2  # either hg19 or hg38
to_build=$3  # either hg19 or hg38
out_dir=$4
code_dir=$5

# Remove all non-autosomal SNPs
plink2 --bfile $plink_path \
   --autosome \
   --keep-allele-order \
   --make-bed --out ${out_dir}/tmp_autosome

# Update SNP IDs and remove ID dups to deduplicate positions, keeping
# first entry
plink2 --bfile ${out_dir}/tmp_autosome \
   --set-all-var-ids @:#:\$r:\$a \
   --keep-allele-order \
   --make-bed --out ${out_dir}/tmp_chrpos

plink2 --bfile ${out_dir}/tmp_chrpos \
   --rm-dup force-first \
   --keep-allele-order \
   --make-bed --out ${out_dir}/tmp_no_dupl

# Create bed file to crossover from hg19 to hg38 
cat ${out_dir}/tmp_no_dupl.bim | cut -f1 | sed 's/^/chr/' > ${out_dir}/tmp_c1.txt
cat ${out_dir}/tmp_no_dupl.bim | cut -f4 > ${out_dir}/tmp_c2.txt
cat ${out_dir}/tmp_no_dupl.bim | cut -f4 > ${out_dir}/tmp_c3.txt
cat ${out_dir}/tmp_no_dupl.bim | cut -f2 > ${out_dir}/tmp_c4.txt
paste  ${out_dir}/tmp_c1.txt \
       ${out_dir}/tmp_c2.txt \
       ${out_dir}/tmp_c3.txt \
       ${out_dir}/tmp_c4.txt \
       >  ${out_dir}/tmp_in.bed

# Check if liftover requested and do liftover
if [ "$from_build" == "$to_build" ]; then
   echo "Not lifting over, input is already desired ${to_build}"

elif [[ "$to_build" =~ .*38.* ]]; then
   CrossMap.py bed ${code_dir}/hg19ToHg38.over.chain \
      ${out_dir}/tmp_in.bed  \
      ${out_dir}/tmp_out.bed

elif [[ "$to_build" =~ .*19.* ]]; then
   CrossMap.py bed ${code_dir}/hg38ToHg19.over.chain \
      ${out_dir}/tmp_in.bed  \
      ${out_dir}/tmp_out.bed
fi

# Follow up liftover
if [ "$from_build" == "$to_build" ]; then
   plink2 --bfile ${out_dir}/tmp_no_dupl \
      --keep-allele-order \
      --make-bed --out ${out_dir}/tmp_gwas

else
   # Extract only those SNPs that were successfully cross-overed
   cut -f4 ${out_dir}/tmp_out.bed > ${out_dir}/tmp_snp_keep.txt
   plink2 --bfile ${out_dir}/tmp_no_dupl \
      --extract ${out_dir}/tmp_snp_keep.txt \
      --keep-allele-order \
      --make-bed --out ${out_dir}/tmp_gwas

   # Update bim file positions
   Rscript --vanilla ${code_dir}/update_pos.R \
   ${out_dir}/tmp_out.bed ${out_dir}/tmp_gwas.bim
fi

# Update SNP IDs, remove ID dups, sort output (need to make .pgen)
plink2 --bfile ${out_dir}/tmp_gwas \
   --set-all-var-ids @:#:\$r:\$a --rm-dup --sort-vars \
   --make-pgen --out ${out_dir}/tmp_output

# Make final file
plink2 --pfile ${out_dir}/tmp_output \
   --keep-allele-order \
   --make-bed --out ${out_dir}/${plink_prefix}_${to_build}_clean_for_merge

# Clean up
rm ${out_dir}/tmp_*