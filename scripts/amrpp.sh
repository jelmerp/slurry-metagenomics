#!/bin/bash

#SBATCH --account=PAS0471
#SBATCH --time=96:00:00
#SBATCH --output=slurm-amrpp-%j.out

## Help function
Help() {
  echo
  echo "## $0: Run the AmrPlusPlus pipeline."
  echo
  echo "## Syntax: $0 -o <output-dir> [ -p <snakemake-profile> ] [-h]"
  echo
  echo "## Required options:"
  echo "## -i STR     Input directory with FASTQ files"
  echo "## -o STR     Output directory for AmrPlusPlus"
  echo "## -s STR     Host FASTA file"
  echo
  echo "## Other options:"
  echo "## -r         Resume incomplete run (default: start from scratch)"
  echo "## -a STR     Directory with AmrPlusPlus software (GitHub repo) (default: 'software/amrplusplus_v2')"
  echo "## -p STR     Profile (default: 'singularity_slurm')"
  echo "## -l STR     Pipeline (default: 'main_AmrPlusPlus_v2_withRGI_Kraken.nf')"
  echo "## -h         Print this help message"
  echo
  echo "## Example command:"
  echo "## $0 -o results/atlas -p profile"
  echo "## To submit the OSC queue, preface with 'sbatch': sbatch $0 ..."
  echo
}

# SETUP ------------------------------------------------------------------------
## Load software
module load python
source activate /fs/project/PAS0471/jelmer/conda/nextflow-21.10.6

## Option defaults
amr_dir=software/amrplusplus_v2/
profile="singularity_slurm"
pipeline="main_AmrPlusPlus_v2_withRGI_Kraken.nf"
resume=false
resume_arg=""

fq_dir=""
host_fa=""
out_dir=""

## Parse command-line options
while getopts 'a:i:o:s:pl::rh' flag; do
  case "${flag}" in
  i) fq_dir="$OPTARG" ;;
  o) out_dir="$OPTARG" ;;
  s) host_fa="$OPTARG" ;;
  a) amr_dir="$OPTARG" ;;
  l) pipeline="$OPTARG" ;;
  p) profile="$OPTARG" ;;
  r) resume=true ;;
  h) Help && exit 0 ;;
  \?) echo "## $0: ERROR: Invalid option" >&2 && exit 1 ;;
  :) echo "## $0: ERROR: Option -$OPTARG requires an argument." >&2 && exit 1 ;;
  esac
done

## Check params
[[ "$fq_dir" = "" ]] && echo "## ERROR: Please specify an input FASTQ dir with -i" && exit 1
[[ "$out_dir" = "" ]] && echo "## ERROR: Please specify an output dir with -o" && exit 1
[[ "$host_fa" = "" ]] && echo "## ERROR: Please specify a host FASTA dir with -s" && exit 1

[[ ! -d "$fq_dir" ]] && echo "## ERROR: Input FASTQ dir $fq_dir does not exist" && exit 1
[[ ! -f "$host_fa" ]] && echo "## ERROR: Input host FASTA file $host_fa does not exist" && exit 1

## Process params
mkdir -p "$out_dir"
[[ $resume = true ]] && resume_arg="-resume"

## If dir and file paths are not absolute, make them absolute, because we have 
## to `cd` into the software dir later on, which would invalidate relative paths:
echo "$fq_dir" | grep -qv "^/" && fq_dir="$PWD"/"$fq_dir"
echo "$host_fa" | grep -qv "^/" && host_fa="$PWD"/"$host_fa"
echo "$out_dir" | grep -qv "^/" && out_dir="$PWD"/"$out_dir"

## Bash strict settings
set -ueo pipefail

## Report
echo
echo "## Starting script amprpp.sh"
date
echo
echo "## AmrPlusPlus software dir:        $amr_dir"
echo "## FASTQ dir:                       $fq_dir"
echo "## Host FASTA file:                 $host_fa"
echo "## Output dir:                      $out_dir"
echo "## Pipeline nextflow file:          $pipeline"
echo "## Profile:                         $profile"
echo "## Resume run:                      $resume"
echo -e "-------------------------\n"


# CARD DATABASE ----------------------------------------------------------------
## If running `RGI`` is included in the pipeline, then download the CARD db if needed,
## and create an argument to point the pipeline to the CARD db
## See https://github.com/meglab-metagenomics/amrplusplus_v2 main README
if echo "$pipeline" | grep -q "RGI"; then
    card_db_dir=$out_dir/refdata/CARD
    mkdir -p "$card_db_dir"

    card_db_json="$card_db_dir"/card.json
    card_db_arg="--card_db $card_db_json"

    if [ ! -f "$card_db_json" ]; then
        echo -e "## Downloading CARD db..."
        wget -q -O "$card_db_dir"/card-data.tar.bz2 https://card.mcmaster.ca/latest/data
        tar xfvj "$card_db_dir"/card-data.tar.bz2 -C "$card_db_dir"
        echo -e "\nq"
    else
        echo -e "## Using CARD db; files already present in $card_db_dir \n"
    fi
fi


# RUN AMRplusplus --------------------------------------------------------------
## Move into the AMRplusplus dir
cd "$amr_dir" || exit 1

## Run the pipeline
nextflow run "$pipeline" \
    -profile "$profile" $resume_arg $card_db_arg \
    --reads "$fq_dir/*_R{1,2}.fastq.gz" \
    --host "$host_fa" \
    --output "$out_dir"

## Report
echo -e "\n## Done with script amprpp.sh"
date
