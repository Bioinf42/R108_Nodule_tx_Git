#!/usr/bin/env bash
#filtering_transcriptome.sh – end-to-end RNA-seq pipeline
set -euo pipefail               # stop on first error, no unset vars
shopt -s nullglob

###################################################################################
CONFIG_FILE="$(dirname "$0")/../configs/paths.yaml"

# quick-and-dirty YAML → shell vars
eval "$(
  sed -E 's/#.*//' "$CONFIG_FILE" |               # strip comments
  grep . |                                        # drop empty lines
  awk -F': *' '                                   # split on “:  ”
    NF==2 {
      gsub(/[[:space:]]+$/, "", $2)               # trim trailing blanks
      print $1 "=\"" $2 "\""
    }'
)"

###################################################################################
mkdir -p "${filtering}/filtered_gtf"
gffread "${results}/merged/R108_merged_nodule.gtf" \
        --ids "${filtering}/pass_tx.txt" \
        -T \
        -o "${filtering}/filtered_gtf/R108_merged_nodule_filtered.gtf"

###################################################################################
gffcompare -r "${reference}/${annotation}" -o "${filtering}/filtered_gtf/gff_compare_out" \
           "${filtering}/filtered_gtf/R108_merged_nodule_filtered.gtf"
