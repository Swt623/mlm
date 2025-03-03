# The main entry point of your workflow.
# After configuring, running snakemake -n in a clone of this repository should successfully execute a dry-run of the workflow.
import itertools
import os 
import glob
import sys
import pandas as pd

configfile: "config/config.yaml"
include: "workflow/rules/common.smk"
include: "workflow/rules/00_TrimReads.smk"
#include: "workflow/rules/read_qc.smk"
include: "workflow/rules/01_DecontaminateReads.smk"
include: "workflow/rules/02_TaxonomicAnalysis.smk"
include: "workflow/rules/assemble.smk"
include: "workflow/rules/assembly_qc.smk"
include: "workflow/rules/bin_metabat2.smk"

rule all:
    input:
        expand("results/AMP_trimmed/{sample}_fastp-merged.fq.gz", sample=samples["sample"])        #get_rules,

# Make report for snakemake. 
report: "workflow/report/workflow.rst"

