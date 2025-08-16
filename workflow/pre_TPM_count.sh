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

mkdir -p "${filtering}/expr_gtf" "${filtering}expr_tabs"

cd "${results}/sorted_bam"
for bam in *.bam; do
    sample=${bam%.bam}
    stringtie -e -B -p "$threads_stringtie" \
              -G "${results}/merged/${merged_gtf_pre_filtering}" \
              -o "${filtering}/expr_gtf/${sample}.gtf" \
              -A "${filtering}/expr_tabs/${sample}.tsv" \
              $bam
done
