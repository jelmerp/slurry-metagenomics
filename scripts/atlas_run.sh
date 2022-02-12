#!/bin/bash

#SBATCH --account=PAS0471
#SBATCH --time=72:00:00
#SBATCH --output=slurm-atlas-%j.out

## Bash strict settings
set -ueo pipefail

## Help function
Help() {
  echo
  echo "## $0: Run the Atlas pipeline."
  echo
  echo "## Syntax: $0 -o <output-dir> [ -p <snakemake-profile> ] [-h]"
  echo
  echo "## Required options:"
  echo "## -o STR     Output directory for Atlas"
  echo
  echo "## Other options:"
  echo "## -p STR     Snakemake profile name (default: 'profile')"
  echo "## -h         Print this help message"
  echo
  echo "## Example command:"
  echo "## $0 -o results/atlas -p profile"
  echo "## To submit the OSC queue, preface with 'sbatch': sbatch $0 ..."
  echo
}

## Option defaults
snakemake_profile=cluster

## Parse command-line options
while getopts 'o:p:h' flag; do
  case "${flag}" in
  o) atlas_dir="$OPTARG" ;;
  p) snakemake_profile="$OPTARG" ;;
  h) Help && exit 0 ;;
  \?) echo "## $0: ERROR: Invalid option" >&2 && exit 1 ;;
  :) echo "## $0: ERROR: Option -$OPTARG requires an argument." >&2 && exit 1 ;;
  esac
done

## Load software
module load python
source activate /users/PAS0471/jelmer/miniconda3/envs/atlas-env

## Report
echo "## Starting script atlas_run.sh"
date
echo "## Output dir:                    $atlas_dir"
echo "## Snakemake profile name:        $snakemake_profile"


# RUN ATLAS --------------------------------------------------------------------
echo -e "\n## Now running atlas..."
atlas run all \
    --working-dir "$atlas_dir" \
    --config-file "$atlas_dir"/config.yaml \
    --profile "$snakemake_profile"


## Report
echo -e "\n## Done with script atlas_run.sh"
date


#? Snakemake profile:
## ~/.config/snakemake

#? Ad-hoc fixes made
## 1. Changed max memory for larger jobs in config.yaml --
##      250 GB is too large for `serial` but too small for `largemem`!
## 2. Added a line `mkdir -p {params.tmpdir}` in rule `run_checkm_lineage_wf` in file `binning.smk`
##    Did this because checkm was complaining that the --tmpdir should be a valid dir; presumably didn't exist.
## 3. Added same mkdir line in rule `run_all_checkm_lineage_wf` in file `genomes.smk`.

## Snakemake files are in /users/PAS0471/jelmer/miniconda3/envs/atlas-env/lib/python3.8/site-packages/atlas/workflow/rules/binning.smk