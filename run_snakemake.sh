#! /bin/bash
#SBATCH -A b1042
#SBATCH --job-name="scheduler"
#SBATCH -t 20:00:00
#SBATCH -N 1
#SBATCH -n 2
#SBATCH -p genomics
#SBATCH --mem=8gb
#SBATCH --mail-type=ALL
#SBATCH --mail-user=jacksumner2026@u.northwestern.edu
#SBATCH --output="slurm_mlm.out"
# module load anaconda3
# source activate snakemake

cd $SLURM_SUBMIT_DIR

# Annotating the output file
START_TIME=$(date)
cat workflow/examples/ascii_art_flowers.txt
echo "
NEW SNAKEMAKE EXECUTION :)
Job Details
Job ID: ${SLURM_JOB_ID}
Start Time: ${START_TIME}

Loading conda...
"

# Load Conda Environment with Snakemake
module purge all
module load mamba
which mamba
which conda
source activate snakemake
#source activate snakemamba

# Execute snakemake
echo "Starting snakemake on cluster..."
snakemake --profile simple

snakemake --forceall --rulegraph | dot -Tpdf > results/dag.pdf
# Annotating the output file
END_TIME=$(date)
echo "
ENDING SNAKEMAKE EXECUTION
Job Details
Job ID: ${SLURM_JOB_ID}
Start Time: ${END_TIME}

Bye-bye :)
"
## "#SBTCH -A b1042"
## "#SBTCH -p genomics"
