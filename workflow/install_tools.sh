#!/usr/bin/env bash
###############################################################################
# install_tools.sh
#   Download and unpack all third-party binaries used in the R108 pipeline.
#
#   Usage:  bash install_tools.sh  /absolute/path/to/toolbin
#           (If no path is given, ./tools is used.)
###############################################################################
##Tools to dowload:
#fastqc_v0.12.1
#Trimmomatic-0.39
#hisat2-2.2.1
#samtools-1.18
#stringtie-3.0.0
#gffread-0.12.7
#gffcompare-0.11.2   #Not included, download by conda 

###############################################################################
set -euo pipefail

#Make and move into tools directory
cd ../
TOOLS_DIR=${1:-"$PWD/tools"}
mkdir -p "$TOOLS_DIR" && cd "$TOOLS_DIR"

echo "Installing tools into: $TOOLS_DIR"
echo "(add the relevant sub-folders to your PATH after this script finishes)"
echo

###############################################################################
#Install FASTQC

echo "→ FASTQC 0.12.1"
if [[ ! -d FastQC ]]; then
  wget -qO fastqc_v0.12.1.zip \
    https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.12.1.zip
  unzip -q fastqc_v0.12.1.zip && rm fastqc_v0.12.1.zip
  chmod +x FastQC/fastqc
else
  echo "  FastQC already present — skipping"
fi

###############################################################################
#Install Trimmomatic

echo "→ Trimmomatic 0.39"
if [[ ! -d Trimmomatic-0.39 ]]; then
  wget -qO Trimmomatic-0.39.zip \
    https://github.com/usadellab/Trimmomatic/files/5854859/Trimmomatic-0.39.zip
  unzip -q Trimmomatic-0.39.zip && rm Trimmomatic-0.39.zip
else
  echo "  Trimmomatic already present — skipping"
fi

###############################################################################
#Install Hisat2

echo "→ HISAT2 2.2.1"
if [[ ! -d hisat2-2.2.1 ]]; then
  wget -qO hisat2-2.2.1.zip \
    https://cloud.biohpc.swmed.edu/index.php/s/oTtGWbWjaxsQ2Ho/download
  unzip -q hisat2-2.2.1.zip && rm hisat2-2.2.1.zip
else
  echo "  HISAT2 already present — skipping"
fi

###############################################################################
#Install Samtools

echo "→ SAMTOOLS 1.18"
if [[ ! -d samtools-1.18 ]]; then
  wget -qO samtools-1.18.tar.bz2 \
    https://github.com/samtools/samtools/releases/download/1.18/samtools-1.18.tar.bz2
  tar -xjf samtools-1.18.tar.bz2 && rm samtools-1.18.tar.bz2
  cd samtools-1.18
  ./configure --prefix="$PWD"
  make -j"$(nproc)"
  make install
  cd ..
else
  echo "  Samtools already present — skipping"
fi

###############################################################################
#Install Stringtie

echo "→ STRINGTIE 3.0.0"
if [[ ! -d stringtie-3.0.0.Linux_x86_64 ]]; then
  wget -qO stringtie-3.0.0.Linux_x86_64.tar.gz \
    https://github.com/gpertea/stringtie/releases/download/v3.0.0/stringtie-3.0.0.Linux_x86_64.tar.gz
  tar -xzf stringtie-3.0.0.Linux_x86_64.tar.gz && rm stringtie-3.0.0.Linux_x86_64.tar.gz
else
  echo "  StringTie already present — skipping"
fi

###############################################################################
#Install gffread 

echo "→ GFFREAD 0.12.7"
if [[ ! -d gffread-0.12.7.Linux_x86_64 ]]; then
  wget -qO gffread-0.12.7.Linux_x86_64.tar.gz \
    https://github.com/gpertea/gffread/releases/download/v0.12.7/gffread-0.12.7.Linux_x86_64.tar.gz
  tar -xzf gffread-0.12.7.Linux_x86_64.tar.gz && rm gffread-0.12.7.Linux_x86_64.tar.gz
else
  echo "  Gffread already present — skipping"
fi

###############################################################################
#Reminder

cat <<'MSG'

--------------------------------------------------------------------
Make sure the following are on your PATH, for example in ~/.bashrc:

    export PATH=$TOOLS_DIR/FastQC:$PATH
    export PATH=$TOOLS_DIR/hisat2:$PATH
    export PATH=$TOOLS_DIR/samtools-1.18:$PATH
    export PATH=$TOOLS_DIR/stringtie-3.0.0.Linux_x86_64:$PATH
    export PATH=$TOOLS_DIR/gffread-0.12.7.Linux_x86_64:$PATH

Trimmomatic is a Java-based tool that requires java -jar. You can add 
as an alias to the end of your ~/.bashrc file. 

    alias trimmomatic='java -jar /home/bioinformatics/lfrpkj/Software/Trimmomatic-0.39/trimmomatic-0.39.jar'

Done!
--------------------------------------------------------------------
MSG