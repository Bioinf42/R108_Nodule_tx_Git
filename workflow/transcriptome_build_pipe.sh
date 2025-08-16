#!/usr/bin/env bash
#Transcriptome_build_pipe.sh – end-to-end RNA-seq pipeline
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
#Run FASTQC to check sequence quality and adaptor content. 

mkdir -p "${results}/fastqc_out_1"

cd "${fastq_dir}"

for fq1 in *fastq.gz; do
fastqc -t "$threads_fastqc" \
       -o "${results}/fastqc_out_1" \
       "$fq1"
done

cd "${proj_root}"

###################################################################################
#Trim .fastq.gz files to remove low quality sequences and adaptors.

mkdir -p "${results}/trimmed_data"

cd "${fastq_dir}"

for fq1 in *_R1_001.fastq.gz; do
    sample=${fq1%%_*}                    # e.g. “A10” from “A10_R1_001.fastq.gz” selects the shorter side of _
    java -jar "${trimmomatic}" PE -threads "$threads_trimmomatic" -phred33 \
        "${sample}_R1_001.fastq.gz" "${sample}_R2_001.fastq.gz" \
        "${results}/trimmed_data/${sample}_R1_paired_001.fastq.gz" \
        "${results}/trimmed_data/${sample}_R1_unpaired_001.fastq.gz" \
        "${results}/trimmed_data/${sample}_R2_paired_001.fastq.gz" \
        "${results}/trimmed_data/${sample}_R2_unpaired_001.fastq.gz" \
        ILLUMINACLIP:"$adaptors"/adapters/TruSeq3-PE-2.fa:2:30:10:2:True \
        SLIDINGWINDOW:4:20 MINLEN:50
done

cd "${proj_root}"

###################################################################################
#Re-run FASTQC on Trimmed fastq.gz files to check adaptor and low quality sequence removal

mkdir -p "${results}/fastqc_out_2"

cd "${results}/trimmed_data"

for fq1 in *fastq.gz; do
fastqc -t "$threads_fastqc" \
       -o "${results}/fastqc_out_2" \
       "$fq1"
done

cd "${proj_root}"

###################################################################################
#Using the hisat software make a exon and splice site txt file.
cd "${reference}"
hisat2_extract_exons.py "${annotation}" > "${exons}"
hisat2_extract_splice_sites.py "${annotation}" > "${splice_sites}"

###################################################################################
#Make the hisat index using the exon and splice site files. 
cd "${reference}"
mkdir -p hisat_index
hisat2-build -p "$threads_hisat_index" \
    --ss "${splice_sites}" \
    --exon "${exons}" \
    "${genome}" \
    "${hisat_index}"

###################################################################################
#Run hisat alignment using the hisat index and paired trimmed files.
mkdir -p "${results}/aligned_sam"
cd "${results}/trimmed_data"

for fq1 in *_R1_paired_001.fastq.gz; do
    sample=${fq1%%_*}
    hisat2 -p "$threads_hisat_quant" --dta \
        -x "${reference}/${hisat_index}" \
        -1 "${sample}_R1_paired_001.fastq.gz" \
        -2 "${sample}_R2_paired_001.fastq.gz" \
        -S "${results}/aligned_sam/${sample}_001_aligned.sam"
done

cd "${proj_root}"

###################################################################################
#Run samtools to make Sorted Bam files used downstream. 
mkdir -p "${results}/aligned_bam" 
mkdir -p "${results}/sorted_bam"
cd "${results}/aligned_sam"

for sam in *_aligned.sam; do
    sample=${sam%%_*}
    bam="${results}/aligned_bam/${sample}_001_aligned.bam"
    samtools view -@ "$threads_samtools" -Sb -o "$bam" "$sam"

    sorted="${results}/sorted_bam/${sample}_001_sorted.bam"
    samtools sort -@ "$threads_samtools" -o "$sorted" "$bam"
    samtools index "$sorted"
done

cd "${proj_root}"

###################################################################################
#Run stringtie with strict filters to remove false positives
mkdir -p "${results}/stringtie_transcript" "${results}/stringtie_counts"
cd "${results}/sorted_bam"

for bam in *_001_sorted.bam; do
    sample=${bam%%_*}
    stringtie "$bam" -p "$threads_stringtie" \
        -G "${reference}/${annotation}" \
        -o "${results}/stringtie_transcript/${sample}_transcripts.gtf" \
        -A "${results}/stringtie_counts/${sample}_counts.tab" \
        -c 3 -j 5 -f 0.20 -m 300               # stricter filters
done

cd "${proj_root}"

###################################################################################
#Merge created gtf files to create a single transcriptome gtf file. 
mkdir -p "${results}/merged"
stringtie --merge -p "$threads_stringtie" -l R108nod \
    -G "${reference}/${annotation}" \
    -o "${results}/merged/R108_merged_nodule.gtf" \
    "${results}"/stringtie_transcript/*.gtf

###################################################################################
#Compare the gtf file to the original 
mkdir -p "${results}/merged/compare/"
gffcompare -r "${reference}/${annotation}" -o "${results}/merged/compare/cmp" \
           "${results}/merged/R108_merged_nodule.gtf"

###################################################################################

gffread "${results}/merged/R108_merged_nodule.gtf" \
        -g "${reference}/${genome}" \
        -w "${results}/merged/R108_merged_nodule.fa"


