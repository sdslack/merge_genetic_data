#!/bin/bash

if [ "$#" -eq 0 ]
then
   echo "Usage: ${0##*/} <input_vcf>"
   echo "Converts VCF to PLINK1.9 file."
   exit
fi

input_vcf=$1
input_vcf_name=$(basename $input_vcf | sed 's/\.vcf.*//')

plink --vcf "$input_vcf" \
        --keep-allele-order \
        --make-bed --double-id \
        --out "$input_vcf_name"

