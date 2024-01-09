#!/bin/bash

if [ "$#" -eq 0 ]
then
   echo "Usage: ${0##*/} <input_vcf> <output_prefix>"
   echo "Converts VCF to PLINK1.9 file."
   exit
fi

input_vcf=$1
output_prefix=$2

plink --vcf "$input_vcf" \
        --keep-allele-order \
        --make-bed --double-id \
        --out "$output_prefix"

