# The main entry point of your workflow.
# After configuring, running snakemake -n in a clone of this repository should successfully execute a dry-run of the workflow.
import itertools
import os 
import glob
import sys
import pandas as pd

configfile: "config/config.yaml"
include: "workflow/rules/common.smk"
# include: "workflow/rules/bin_assembly.smk"
#include: "workflow/rules/single_sample_binning.smk"
include: "workflow/rules/00_TrimReads.smk"
include: "workflow/rules/read_qc.smk"
include: "workflow/rules/01_DecontaminateReads.smk"
include: "workflow/rules/02_TaxonomicAnalysis.smk"
include: "workflow/rules/assemble.smk"
include: "workflow/rules/assembly_qc.smk"
#include: "workflow/rules/spades.smk"
include: "workflow/rules/bin_metabat2.smk"

rule all:
    input:
        get_rules,
        "results/kraken/merged_kraken_report_profile.tsv"

# Make report for snakemake. 

report: "workflow/report/workflow.rst"
