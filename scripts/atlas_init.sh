#!/bin/bash

## Bash strict settings
set -ueo pipefail

## Help function
Help() {
  echo
  echo "## $0: Initialize the Atlas pipeline."
  echo
  echo "## Syntax: $0 -i <input-dir> -o <output-dir> [-d <atlas-db-dir>] [-c] [-h]"
  echo
  echo "## Required options:"
  echo "## -i STR     Input dir with FASTQ files"
  echo "## -o STR     Output directory for Atlas"
  echo
  echo "## Other options:"
  echo "## -d STR     Atlas database dir (default: <output-dir>/atlas_db"
  echo "## -h         Print this help message"
  echo
  echo "## Example command:"
  echo "## $0 -i data/fastq -o results/atlas"
  echo "## To submit the OSC queue, preface with 'sbatch': sbatch $0 ..."
  echo
}

## Option defaults
db_dir=""

## Parse command-line options
while getopts ':i:o:d:h' flag; do
  case "${flag}" in
  i) data_dir="$OPTARG" ;;
  o) atlas_dir="$OPTARG" ;;
  d) db_dir="$OPTARG" ;;
  h) Help && exit 0 ;;
  \?) echo "## $0: ERROR: Invalid option" >&2 && exit 1 ;;
  :) echo "## $0: ERROR: Option -$OPTARG requires an argument." >&2 && exit 1 ;;
  esac
done

## Process option defaults
[[ "$db_dir" = "" ]] && db_dir="$atlas_dir"/db_dir

## Load software
module load python
source activate /users/PAS0471/jelmer/miniconda3/envs/atlas-env

## Make output dir
mkdir -p "$atlas_dir"

## Report
echo "## Starting script atlas_init.sh"
date
echo "## Input FASTQ dir:               $data_dir"
echo "## Output dir:                    $atlas_dir"
echo "## Atlas DB dir:                  $db_dir"


# RUN ATLAS INIT ---------------------------------------------------------------
echo -e "\n## Initializing Atlas with 'atlas init'..."
atlas init \
    --db-dir "$db_dir" \
    --working-dir "$atlas_dir" \
    "$data_dir"


## Report
echo -e "\n## Done with script atlas_init.sh"
date