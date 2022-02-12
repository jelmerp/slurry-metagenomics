## Copy host genomes from Poonam

```bash
genome_dir=refdata/genomes
cp /fs/project/PAS0471/poonam/atlas_workflow/databases/Cattle_genomic.fna "$genome_dir"
cp /fs/project/PAS0471/poonam/atlas_workflow/databases/Human_genomic.fna "$genome_dir"
```

## Atlas setup (see https://metagenome-atlas.readthedocs.io/en/latest/usage/getting_started.html)

```bash
cookiecutter --output-dir ~/.config/snakemake https://github.com/metagenome-atlas/clusterprofile.git
cp ~/.config/snakemake/cluster/queues.tsv.example ~/.config/snakemake/cluster/queues.tsv
```

- Next changed `queues.tsv` to reflect OSC's queue parameters -- see https://www.osc.edu/resources/technical_support/supercomputers/pitzer/batch_limit_rules
- Also changed `~/.config/snakemake/cluster/cluster_config.yaml` to include account PAS0471
- DON'T include `queue: serial` in __default__ in `cluster_config.yaml`, because then it will always use the serial queue!

## AmrPlusPlus modifications...

- Change `kraken_db` value in `software/amrplusplus_v2/nextflow.config`!

- In `singularity_slurm.config`:
  - Change to conda env for rgi: conda='bioconda::rgi'
  - Change to conda env for resistome: conda='hcc::resistomeanalyzer'
  - Move `container = 'shub://meglab-metagenomics/amrplusplus_v2'` to individual rules instead

- In `nextflow.config`:
  - Add `conda { useMamba = true }`
  - Remove `process.container = 'shub://meglab-metagenomics/amrplusplus_v2'` from `singularity_slurm` section

- In workflow (``.nf`) file:
  - Remove `-type` argument to `resistome` (resistomeanalyzer) and resulting files, e.g. `-type_fp ${sample_id}.type.tsv`
    (There is no `-type` argument and `resistome` won't do anything)

#> Modify script `software/amrplusplus_v2/bin/RGI_aro_hits.py` to properly process sample name
