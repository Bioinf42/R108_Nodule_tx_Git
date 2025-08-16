#!/usr/bin/env bash
set -euo pipefail

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

#Make directories if not already present
mkdir -p "$proj_root" "$fastq_dir" "$reference" "$results"
mkdir -p "${results}/logs"
