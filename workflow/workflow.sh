## Download sequences
# sftp -P 22 wirat_pipatpongpinyo@3.17.199.203 #tebBkv-92gvwlmT

## Dirs and setting
dir_fq_sep=data/fastq/211119_Meulia_GSL-WP-2486
dir_fq=data/fastq/lane-concat
dir_fq_sub=data/fastq/subset
dir_fastqc=results/fastqc
dir_multiqc=results/multiqc
dir_atlas=results/atlas
dir_amr=results/amrpp

genome_dir=refdata/genomes
host_fa_comb=refdata/genomes_combined/cattle_and_human.fna

## Run FastQC
shopt -s globstar
for fq in "$dir_fq_sep"/**/*fastq.gz; do
    echo "FASTQ file: $fq"
    sbatch mcic-scripts/qc/fastqc.sh -i "$fq" -o "$dir_fastqc"
done

## Run MultiQC
sbatch mcic-scripts/qc/multiqc.sh -i "$dir_fastqc" -o "$dir_multiqc"

## Concatenate reads from different lanes
sbatch mcic-scripts/misc/fqconcat.sh -i "$dir_fq_sep" -o "$dir_fq"

## Subset FASTQ files for test runs
mcic-scripts/misc/fqsub_dir.sh -i $dir_fq -o "$dir_fq_sub"
for old in "$dir_fq_sub"/*q.gz; do
    new=$(echo "$old" | sed -E 's/_S[0-9]+_/_/' | sed 's/_001//')
    mv -v "$old" "$new" # Simplify names - not sure if necessary for AmrPlusPlus
done

## Host genomes
cp /fs/project/PAS0471/poonam/atlas_workflow/databases/Cattle_genomic.fna "$genome_dir"
cp /fs/project/PAS0471/poonam/atlas_workflow/databases/Human_genomic.fna "$genome_dir"
cat "$genome_dir"/Cattle_genomic.fna "$genome_dir"/Human_genomic.fna > "$host_fa_comb"

## Set up Atlas (see https://metagenome-atlas.readthedocs.io/en/latest/usage/getting_started.html)
cookiecutter --output-dir ~/.config/snakemake https://github.com/metagenome-atlas/clusterprofile.git
cp ~/.config/snakemake/cluster/queues.tsv.example ~/.config/snakemake/cluster/queues.tsv
#> Next changed `queues.tsv` to reflect OSC's queue parameters -- see https://www.osc.edu/resources/technical_support/supercomputers/pitzer/batch_limit_rules
#> Also changed `~/.config/snakemake/cluster/cluster_config.yaml` to include account PAS0471
#> DON'T include `queue: serial` in __default__ in cluster_config.yaml, because then it will always use the serial queue!

## Run Atlas
bash scripts/atlas_init.sh -i "$dir_fq" -o "$dir_atlas"
#> Now add host genomes to config!
sbatch scripts/atlas_run.sh -o "$dir_atlas"

## Create Kraken DB for AmrPlusPlus run
krakendb=refdata/kraken-db
sbatch mcic-scripts/metagenomics/kraken-build-custom-db.sh -d "$krakendb" -g "$genome_dir"

## Run AmrPlusPlus
sbatch --time=300 scripts/amrpp.sh -i data/fastq/subset2 -o "$dir_amr" -s "$host_fa_comb"

sbatch --time=600 scripts/amrpp.sh -i data/fastq/subset2 -o "$dir_amr"/subset7samp_fullpipeline -s "$host_fa_comb" -r
