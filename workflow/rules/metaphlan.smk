
############################
### PART 1A: METAPHLAN3  ###
############################

### Setup Metaphlan. Run Metaphlan on samples to make abundance tables ###

def metaphlan_merge_inputs(wildcards):
    files = expand("results/metaphlan_out/{sample}/{sample}.metaphlan_profile.txt",
        sample=samples["sample"])
    return files


rule metaphlan_setup:
    output:
        metaphlan_db=directory("resources/metaphlan_db"),
        metaphlan_db_file="resources/metaphlan_db/{}.rev.1.bt2".format(config["metaphlan_idx"])
    conda: 
        "../envs/metaphlan.yml"
    params:
        metaphlan_idx = config["metaphlan_idx"] # Index for metaphlan
    threads: 10
    resources:
        mem="10g",
        time="04:00:00"
    shell:
        """
        metaphlan --install --index {params.metaphlan_idx} --bowtie2db {output.metaphlan_db} --nproc {threads}
        """


rule metaphlan:
    input:
        metaphlan_db = rules.metaphlan_setup.output.metaphlan_db,
        r1_clean = "results/bwa_out/{sample}/{sample}.fastp_bwa.r1.fastq",
        r2_clean = "results/bwa_out/{sample}/{sample}.fastp_bwa.r2.fastq"
    output:
        profile = "results/metaphlan_out/{sample}/{sample}.metaphlan_profile.txt",
        bowtie_out = "results/metaphlan_out/{sample}/{sample}.bowtie2.bz2"
    conda: 
        "../envs/metaphlan.yml"
    params:
        metaphlan_idx = config["metaphlan_idx"] # Index for metaphlan
    threads: 20
    resources:
        mem="10g",
        time="04:00:00"
    shell:
        """
        metaphlan {input.r1_clean},{input.r2_clean} \
        --bowtie2out {output.bowtie_out} \
        --index {params.metaphlan_idx} \
        --bowtie2db {input.metaphlan_db} \
        --nproc {threads} \
        --input_type fastq \
        --unknown_estimation \
        -o {output.profile}
        """

rule metaphlan_merge:
    input:
        metaphlan_merge_inputs
    output:
        "results/metaphlan_merged/merged_metaphlan_profile.tsv"
    conda:
        "../envs/metaphlan.yml"
    shell:
        """
        merge_metaphlan_tables.py {input} > {output}
        """


rule metaphlan_species_abundance:
    input:
        "results/metaphlan_merged/merged_metaphlan_profile.tsv"
    output:
        "results/metaphlan_merged/merged_metaphlan_profile_species.tsv"
    conda:
        "../envs/metaphlan.yml"
    shell:
        """
        grep -E "s__|clade|UNKNOWN" {input} | sed 's/^.*s__//g' \
        | cut -f1,3- | sed -e 's/clade_name/sample/g' > {output}
        """


rule metaphlan_genus_abundance:
    input:
        "results/metaphlan_merged/merged_metaphlan_profile.tsv"
    output:
        "results/metaphlan_merged/merged_metaphlan_profile_genus.tsv"
    conda:
        "../envs/metaphlan.yml"
    shell:
        """
        grep -E "g__|clade|UNKNOWN" {input} | sed 's/^.*g__//g' \
        | grep -v s__ |cut -f1,3- | sed -e 's/clade_name/sample/g' > {output}
        """

rule metaphlan_unifrac:
    input:
        "results/metaphlan_merged/merged_metaphlan_profile.tsv"
    output:
        "results/metaphlan_merged/merged_metaphlan_unifrac_matrix.txt"
    params:
        "/home/jsj3921/.conda/envs/snakemake/pkgs/metaphlan-3.0.13-pyhb7b1952_0/site-packages/metaphlan/utils/"
    conda:
        "../envs/metaphlan.yml"
    shell:
        """
        module load R/4.1.1
        Rscript {params}calculate_unifrac.R {input} {params}mpa_v30_CHOCOPhlAn_201901_species_tree.nwk {output}
        """

rule hclust:
    input:
        "results/metaphlan_merged/merged_metaphlan_profile_species.tsv"
    output:
        report("results/metaphlan_merged/merged_metaphlan_hclust_species.png", caption="report/hclust.rst", category="METAPHLAN")
    conda:
        "../envs/hclust.yml"
    shell:
        """
        hclust2.py -i {input} -o {output} --f_dist_f braycurtis --s_dist_f braycurtis --cell_aspect_ratio 0.5 -l --flabel_size 10 --slabel_size 10 --max_flabel_len 100 --max_slabel_len 100 --minv 0.1 --dpi 300
        """

rule hclust_genus:
    input:
        "results/metaphlan_merged/merged_metaphlan_profile_genus.tsv"
    output:
        report("results/metaphlan_merged/merged_metaphlan_hclust_genus.png", caption="report/hclust_genus.rst", category="METAPHLAN")
    conda:
        "../envs/hclust.yml"
    shell:
        """
        hclust2.py -i {input} -o {output} --f_dist_f braycurtis --s_dist_f braycurtis --cell_aspect_ratio 0.5 -l --flabel_size 10 --slabel_size 10 --max_flabel_len 100 --max_slabel_len 100 --minv 0.1 --dpi 300
        """



use rule metaphlan as metaphlan_bowtie with:
    input:
        metaphlan_db = rules.metaphlan_setup.output.metaphlan_db,
        r1_clean = "results/bowtie_out/{sample}/{sample}.fastp_bowtie.r1.fastq.gz",
        r2_clean = "results/bowtie_out/{sample}/{sample}.fastp_bowtie.r2.fastq.gz"
    output:
        profile = "results/metaphlan_bowtie_out/{sample}/{sample}.metaphlan_profile.txt",
        bowtie_out = "results/metaphlan_bowtie_out/{sample}/{sample}.bowtie2.bz2"

use rule metaphlan_merge as metaphlan_merge_bowtie with:
    input:
        expand("results/metaphlan_bowtie_out/{sample}/{sample}.metaphlan_profile.txt", zip, sample=samples["sample"], dataset=samples["dataset"])
    output:
        "results/metaphlan_bowtie_out/merged_metaphlan_profile.tsv"

use rule metaphlan_genus_abundance as metaphlan_bowtie_genus_abundance with:
    input:
        "results/metaphlan_bowtie_out/merged_metaphlan_profile.tsv"
    output:
        "results/metaphlan_bowtie_out/merged_metaphlan_profile_genus.tsv"

use rule metaphlan_species_abundance as metaphlan_bowtie_species_abundance with:
    input:
        "results/metaphlan_bowtie_out/merged_metaphlan_profile.tsv"
    output:
        "results/metaphlan_bowtie_out/merged_metaphlan_profile_species.tsv"


############################
###  PART 1A: KRACKEN2   ###
############################

# Because such high memory DB, consider finding a way to call all input files in one rule

rule kraken2:
    input: 
        r1_clean = "results/bowtie_out/{sample}/{sample}.fastp_bowtie.r1.fastq.gz",
        r2_clean = "results/bowtie_out/{sample}/{sample}.fastp_bowtie.r2.fastq.gz"
    output:
        table = "results/kraken/{sample}/{sample}_kraken2table.tsv",
        reads_class = "results/kraken/{sample}/{sample}_kraken2out.txt"        
    threads: 20
    resources:
        mem="180G",
        time="0:10:00"
    shell:
        """
        module load kraken/2
        kraken2 --threads {threads} \
            --use-names \
            --output {output.reads_class} \
            --report {output.table} \
            --use-mpa-style \
            --report-zero-counts \
            --confidence 0.5 \
            --gzip-compressed \
            --paired {input.r1_clean} {input.r2_clean}
        """


rule metaxa2:
    input:
        r1_clean = "results/bowtie_out/{sample}/{sample}.fastp_bowtie.r1.fastq.gz",
        r2_clean = "results/bowtie_out/{sample}/{sample}.fastp_bowtie.r2.fastq.gz"
    output:
        out = "results/metaxa2/{sample}/{sample}_metaxa2.summary.txt"
    params:
        base_out = "results/metaxa2/{sample}/{sample}_metaxa2"
    threads: 25
    resources:
        mem="30G",
    shell:
        """
        module load hmmer/3.1b2 blast/2.7.1 mafft/7.407 python/anaconda3 metaxa2/2.2

        metaxa2 -1 {input.r1_clean} \
            -2 {input.r1_clean} \
            --mode metagenome \
            -f fastq \
            -g ssu \
            -p /software/metaxa2/2.2/metaxa2_db/SSU/HMMs/ \
            -o {params.base_out} \
            --cpu 24 \
            --multi_thread T \
            --plus T
        """