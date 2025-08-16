markdown

# *Medicago truncatula* R108 Nodule Transcriptome Pipeline

---
## Overview
This pipeline processes unstranded paired-end RNA-seq data to build a transcriptome for *Medicago truncatula* R108 root nodules, also reffered to as *Medicago littoralis*. 
It performs quality control, trimming, alignment to the R108 reference genome, transcript assembly, merging, and comparison to the reference annotation, producing a comprehensive nodule transcriptome for downstream analysis.

---
## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)  
- [Repository Contents](#repository-contents)  
- [Directory structures](#directory-structures)
- [Installation](#installation)  
- [Usage](#usage)  
- [Outputs](#outputs)  
- [Transcript Filtering](#transcript-filtering) 
- [License](#license)  
- [Citation](#citation) 

---
## Prerequisites
- System: Linux (e.g., Ubuntu)

### Software included (`install_tools.sh`)
- 'fastqc_v0.12.1' : For quality control 
- 'Trimmomatic-0.39' : For trimming and adaptor removal 
- 'hisat2-2.2.1' : For alignment
- 'samtools-1.18' : For BAM conversion and sorting
- 'stringtie-3.0.0' : For transcript assembly
- 'gffread-0.12.7' : For extracting transcript sequence

### Software not included (install separately)
- Java (OpenJDK 11 or later) : Required for Trimmomatic
- Miniconda3   : For installing GFFCompare
- gffcompare-0.11.2 (available through Miniconda/conda) : For comparison to original gtf annotation. 

### Input Files:
- Paired-end RNA FASTQ files (e.g., `SAMPLE_R1_001.fastq.gz`, `SAMPLE_R2_001.fastq.gz`)
- Reference genome - from the zip use the "MedtrR108_HiC.genome.fasta" file 
(https://medicago.toulouse.inrae.fr/MtrunR108_HiC/downloads/1.0/MtrunR108_HiC.1.0.fasta_features.zip)
- Reference annotation 
(https://medicago.toulouse.inrae.fr/MtrunR108_HiC/downloads/1.0/MtrunR108_HiC.1.0.gtf)

### Hardware Recommendations 
- Multi-core CPU (16+ threads recommended)
- Sufficient disk space for FASTQ and output files.

---
## Repository Contents
- `install_tools.sh`: Contains a script to download and unpack all of the specific version tools used to make the transcriptome. 
NOTE: gffcompare-0.11.2 is not included and can be installed via Conda.

- `make_directories.sh`: Makes the main base directories required for the transcriptome_build_pipe.sh, run before. 

- `transcriptome_build_pipe.sh`: Main end-to-end pipeline script (trimming, alignment, assembly, merging, comparison). 

- `pre_TPM_count.sh` : generates TPM values for each sample and needed directiories inside the filtering directory. 

- `final_filtering.sh` filters the final gtf and runs gffcompare to output a last .gtf draft. 

- `example.yaml`: A template for `configs/paths.yaml`, specifying paths to input files, reference files, and tool directories.

---
## Directory structures

The R108_Nodule_tx_Git repository has the following structure:

```bash
R108_Nodule_tx_Git/
├── configs/
│   └── example.yaml  # Template for configuration file         
├── workflow/
│   ├── install_tools.sh # Install tools file 
│   ├── make_directories.sh # Makes base directories
│   ├── transcriptome_build_pipe.sh # Main pipeline script
│   ├── pre_TPM_count.sh
│   └── final_filtering.sh
├── README.md               # Documentation
└── LICENSE   
```
- `install_tools.sh` generates the tools directory.
- `make_directories.sh` generates results, reference, raw_data and filtering directories inside of the Pipeline_directory.
- `transcriptome_build_pipeline.sh` further directories are created in results directory. 
- `pre_TPM_count.sh` generates TPM values for each sample and needed directiories inside the filtering directory.
- `final_filtering.sh` filters the final gtf and runs gffcompare to output a last .gtf draft. 

After running the five .sh files thr directory structure will look like the one below: 

```bash
R108_Nodule_tx_Git/
├── configs/
│   ├── example.yaml
│   └── paths.yaml # Template for configuration file         
├── workflow/
│   ├── install_tools.sh # Install tools file 
│   ├── make_directories.sh # Makes base directories
│   ├── transcriptome_build_pipe.sh # Main pipeline script
│   ├── pre_TPM_count.sh
│   └── final_filtering.sh
├── README.md               # Documentation
├── LICENSE   
└── Pipeline_directory/
    ├── raw_data/
    ├── reference/
    ├── filtering/
    └── results/ 
        ├── fastqc_out_1/             # FastQC reports
        ├── trimmed_data/  
        ├── fastqc_out_2/      # Trimmed FASTQ files
        ├── aligned_sam/        # SAM alignment files
        ├── aligned_bam/        # BAM files
        ├── sorted_bam/         # Sorted BAM files
        ├── stringtie_transcript/  # Per-sample GTF files
        ├── stringtie_counts/   # Per-sample count tables
        ├── merged/             # Merged GTF and FASTA files
        └── logs/  
```

---
## Installation
Follow these steps to install all required tools and set up your environment before running the pipeline.

1. **Clone the repository**
    
```bash
git clone https://github.com/yourusername/R108_Nodule_tx_Git.git
```

2. **Navigate to the repository and make the installation script executable**
     
```bash
cd R108_Nodule_tx_Git/workflow
chmod +x install_tools.sh
```
3. **Run the install_tools.sh file**

This creates a tools/ directory containing included software.
    
```bash
./install_tools.sh
```
 
 4. **Add the tools to your PATH**

 You will need to add to your ~/.bashrc file if on linux. Change the `/ABS/PATH/TO/` and add these below. Trimmomatic is left out here
 because the path is added later to the `paths.yaml` file instead. 

```bash
export PATH=$PATH:/ABS/PATH/TO/R108_Nodule_tx_Git/tools/FastQC
export PATH=$PATH:/ABS/PATH/TO/R108_Nodule_tx_Git/tools/hisat2-2.2.1
export PATH=$PATH:/ABS/PATH/TO/R108_Nodule_tx_Git/tools/samtools-1.18/bin
export PATH=$PATH:/ABS/PATH/TO/R108_Nodule_tx_Git/tools/stringtie-3.0.0.Linux_x86_64
export PATH=$PATH:/ABS/PATH/TO/R108_Nodule_tx_Git/tools/gffread-0.12.7.Linux_x86_64
```
Apply the changes immediately with `source ~/.bashrc`
 ```bash
source ~/.bashrc
 ```

5. **Install Miniconda3 and GFFCompare**

Move into the tools directory and download the Miniconda installer:
     
```bash
cd tools
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O Miniconda3.sh
```
Run the installer:
     
```bash
bash Miniconda3.sh
```
- Accept the license agreement.
- Install to your home directory (default).
- When prompted “Do you wish the installer to initialize Miniconda3 by running `conda init`?”, type **yes**. This will automatically add Conda to your shell’s startup scripts (e.g., `~/.bashrc`).
- Then run:
       
```bash
source ~/.bashrc
```

Create and activate an environment for GFFCompare:
```bash
conda create -n gffcompare_env -c bioconda -c conda-forge gffcompare=0.11.2
conda activate gffcompare_env
```
Verify that GFFCompare is installed:
```bash
gffcompare -h
```

After these steps, both Conda (and therefore `conda` commands) and `gffcompare` will be on your `PATH` whenever you open a new terminal.


6. **Verify each tool is available**
   
```bash
fastqc --version
trimmomatic -version
hisat2 --version
samtools --version
stringtie --version
gffread --version
gffcompare -h
java -version
conda --version
``` 

7. **Move to the configs folder and make a copy of example.yaml, call it path.yaml**

Edit all `/ABS/PATH/TO` the directory structure on your system.

```bash 
cd configs
cp example.yaml paths.yaml
```

---

## Usage
You should now have installed all required software and edited your paths.yaml file. Run the commands below 
to first make the base directories then to run the `transcriptome_build_pipe.sh`. This contains all of the commands 
required to build the transcriptome. 

1. **Make the base directory structure by running make_directories.sh** 

```bash
cd workflow
chmod +x make_directories.sh
./make_directories.sh
```

2. **Move `MedtrR108_HiC.genome.fasta` and `MtrunR108_HiC.1.0.gtf` into the reference directory** 

```bash
mv /ABS/PATH/TO/MedtrR108_HiC.genome.fasta /ABS/PATH/TO/R108_Nodule_tx_Git/Pipeline_directory/reference/MedtrR108_HiC.genome.fasta
mv /ABS/PATH/TO/MtrunR108_HiC.1.0.gtf /ABS/PATH/TO/R108_Nodule_tx_Git/Pipeline_directory/reference/MtrunR108_HiC.1.0.gtf
```
3. **Move your paired RNA-seq raw data into the raw_data directory.**

```bash
mv /ABS/PATH/TO/*fastq.gz /ABS/PATH/TO/R108_Nodule_tx_Git/Pipeline_directory/raw_data
```
4. **Finally Run the transcriptome_build_pipe.sh**

```bash
cd R108_Nodule_tx_Git
chmod +x workflow/transcriptome_build_pipe.sh
conda activate gffcompare_env
./workflow/transcriptome_build_pipe.sh
```
**Note**: Ensure `paths.yaml` paths are correct. Check `results/logs/` for errors if the pipeline fails.

If you are running on a HPC server and using slurm, create a SLURM job script to manage resources. 
Use `nano` or `vim` to create a file (e.g., `run_pipeline.sbatch`). Save this as `run_pipeline.sbatch` in `R108_Nodule_tx_Git/`.

```bash
#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=20
#SBATCH --mem-per-cpu=3988
#SBATCH --time=20:00:00
#SBATCH --output=../Pipeline_output/results/logs/pipeline_%j.out
#SBATCH --error=../Pipeline_output/results/logs/pipeline_%j.err


source ~/.bashrc
conda activate gffcompare_env
cd /ABS/PATH/TO/R108_Nodule_tx_Git
chmod +x workflow/transcriptome_build_pipe.sh
bash workflow/transcriptome_build_pipe.sh
```

To submit the job:

```bash
sbatch run_pipeline.sbatch
```

---
## Outputs

There will be 9 output folders in results directory produced for a successful run.

1. **fastqc_out_1**: HTML & `.zip` reports from the raw FASTQ files (one pair of reports per library). Open the HTML file for each sample in a web browser and eyeball: 
per-base quality, over-represented sequences, adapter contamination. A quick primer is on the [FastQC project page](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/).

2. **trimmed_data**: four FASTQ files per sample, all gzip-compressed: 

- `*_R1_paired_001.fastq.gz` forward reads that kept their mate 
- `*_R1_unpaired_001.fastq.gz` forward reads whose mate was discarded
- `*_R2_paired_001.fastq.gz` reverse reads that kept their mate    
- `*_R2_unpaired_001.fastq.gz` reverse reads whose mate was discarded

  Paired vs. unpaired? Trimmomatic processes each read independently; if trimming pushes one mate below the `MINLEN` threshold (36 nt here) that read is dropped while its partner is kept. 
  ‘*Paired*’ files therefore contain read pairs that both survived; ‘*unpaired*’ files hold the few orphan reads that survived alone. Down-stream aligners only consume the *paired* files.


3. **fastqc_out_2**: HTML & `.zip` reports of the trimmed data, sequence quality should be higher and adaptors should now be removed. 

4. **aligned_sam**: One `.sam` per sample: raw, unsorted **HISAT2** output alignments. Large (~10–15 × the BAM size) but human-readable; handy for quick grep-style checks.

5. **aligned_bam**:  One `.bam` per sample, this is a compressed `.sam` file converted into binary. This is an intermediate step before sorting. 
6. **sorted_bam**: Coordinate-sorted & indexed BAMs (`.bam` + `.bam.bai`). These are the files that are used by StringTie; you can view them in IGV.
7. **stringtie_counts**: Per-sample abundance tables (`*_counts.tab`). Expression estimates (FPKM, TPM, read counts) for every transcript feature in the matching GTF
8. **stringtie_transcript**: a GTF is produced per sample. Each file lists all transcript models assembled from that sample alone.
8. **merged**: 

- `R108_merged_nodule.gtf` merged transcriptome 
- `R108_merged_nodule.fa` cDNA FASTA extracted from the merged GTF 
- `cmp.*` gffcompare evaluation files (how the new assembly compares to the reference annotation) 

The merged GTF is the unfiltered annotation for the R108 nodule transcriptome.


---
## Transcript Filtering

Now you have the merged GTF file there is an overprediction of transcript numbers that include very lowly expressed isoforms. Stringtie is run again outputting TPM 
values for each transcript for the new `R108_merged_nodule.gtf`. These will then be combined into one matrix allowing you to filter as desired.

1. Run `pre_TPM_count.sh` as done before like `transcriptome_build_pipe.sh`. This will run stringtie and create two sub-directories in the filtering directory 
producing gtf files for each sample with TPM values. 

2. Next build a matrix of TPM values for each transcript in each sample. You can either do this yourself for example using R and then filtering as desired, or you can use 
the python code supplied. 

There are two python files stored in the workflow directory. Move these into the filtering directory and run from there. 

- `make_tx_tpm_matrix.py` uses the gtf files produced and makes a transcript TPM matrix. 
- `filter_tx_tpm_matrix.py` uses the TPM matrix and removes transcripts with low TPM values (currently set to remove any transcript with a TPM less than or equal to 1 in less than or equal to 3 samples)  

```
mv make_tx_tpm_matrix.py ../Pipeline_directory/filtering
mv filter_tx_tpm_matrix.py ../Pipeline_directory/filtering
```

Move into the filtering directory and run the commands. 

```
conda create -n rna_py python=3.11 pandas -y
conda activate rna_py

python make_tx_tpm_matrix.py
python filter_tx_tpm_matrix.py
```

3. You now have a list called `pass_tx.txt`, these are the transcripts that passed the filtering step. Run `final_filtering.sh` to filter and remake the 
final annotation `.gtf`, the output is called `R108_merged_nodule_filtered.gtf`, the script will also run gffcompare, this evaluates the new gtf file 
compared to the original MtrunR108_HiC.1.0.gtf. 


```bash
cd R108_Nodule_tx_Git
chmod +x workflow/final_filtering.sh
conda activate gffcompare_env
./workflow/final_filtering.sh
```

It also outputs a new `.gtf` annotation which should be taken and used for downstream steps. This `.annoted.gtf`
provides a new naming system as well as identifies transcripts based on if they are new or old. 


## License

- **Code**: MIT License © 2025 <Matthew Jolly>. See `LICENSE`.
- **Text/docs/figures in this repo**: Creative Commons Attribution 4.0 International (**CC BY 4.0**).
- **Third-party tools and external genomes/annotations/data** remain under their own licenses/terms; follow the providers’ terms.


## Citation

**This repository**
- Matthew Jolly (Gifford Lab, Univesity of Warwick). *Medicago truncatula R108 nodule transcriptome: tutorial & pipeline*. GitHub, `v0.1.0` (2025)

**Software**

- 'fastqc_v0.12.1' : Andrews S. (2010) FastQC: A Quality Control Tool for High Throughput Sequence Data
- 'Trimmomatic-0.39' : Bolger AM, Lohse M, Usadel B. Trimmomatic: a flexible trimmer for Illumina sequence data. Bioinformatics. 2014;30(15):2114-2120. doi:10.1093/bioinformatics/btu170
- 'hisat2-2.2.1' : Kim D, Paggi JM, Park C, Bennett C, Salzberg SL. Graph-based genome alignment and genotyping with HISAT2 and HISAT-genotype. Nat Biotechnol. 2019;37(8):907-915. doi:10.1038/s41587-019-0201-4
- 'samtools-1.18' : Li H, Handsaker B, Wysoker A, et al. The Sequence Alignment/Map format and SAMtools. Bioinformatics. 2009;25(16):2078-2079. doi:10.1093/bioinformatics/btp352
- 'stringtie-3.0.0' : Pertea M, Pertea GM, Antonescu CM, Chang TC, Mendell JT, Salzberg SL. StringTie enables improved reconstruction of a transcriptome from RNA-seq reads. Nat Biotechnol. 2015;33(3):290-295. doi:10.1038/nbt.3122
- 'gffread-0.12.7' : Pertea G, Pertea M. GFF Utilities: GffRead and GffCompare. F1000Res. 2020;9:ISCB Comm J-304. Published 2020 Apr 28. doi:10.12688/f1000research.23297.2

**Genome and Annotation**

- Kaur P, Lui C, Dudchenko O, et al. Delineating the Tnt1 Insertion Landscape of the Model Legume Medicago truncatula cv. R108 at the Hi-C Resolution Using a Chromosome-Length Genome Assembly. Int J Mol Sci. 2021;22(9):4326. Published 2021 Apr 21. doi:10.3390/ijms22094326

