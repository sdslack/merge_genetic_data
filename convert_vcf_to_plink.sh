#!/bin/bash

in_vcf=$1
out_plink_prefix=$2

plink --vcf $in_vcf --make-bed --out $out_plink_prefix
