#!/bin/sh

### this script contains the full pipeline

data_dir="/scratch1/battle-fs1/ashis/progdata/brain_process/v6"
gtex_abbrev_fn="$data_dir/gtex_abbrevs.csv"
cov_data_dir="$data_dir/covariates"
log_dir="$data_dir/logs"
var_exp_dir="$data_dir/variance_explained"
plt_dir="$data_dir/plots"

if [ ! -f $gtex_abbrev_fn ]; then
  echo "GTEx tissue abbreviation file does not exist.";
  exit 1
fi

if [ -d $cov_data_dir ]; then
  echo "covariates directory already exists."
  exit 1
else
  mkdir $cov_data_dir
fi

if [ -d $log_dir ]; then
  echo "log directory already exists."
  exit 1
else
  mkdir $log_dir
fi

if [ -d $var_exp_dir ]; then
  echo "variance explained directory already exists."
  exit 1
else
  mkdir $var_exp_dir
fi

if [ -d $plt_dir ]; then
  echo "plot directory already exists."
  exit 1
else
  mkdir $plt_dir
fi


### step-1
python 01_merge_covariates.py 2>&1 | tee $log_dir/01_merge_covariates.log


### step-2
all_cov_fn="$cov_data_dir/20170901.all_covariates.txt"
all_cov_pc_fn="$cov_data_dir/20170901.all_covariates.PCs.txt"
std_cov_pc_fn="$cov_data_dir/20170901.std_covars.PCs.txt"
python 02_extract_covariates.py -all_cov_fn $all_cov_fn -all_cov_pc_fn $all_cov_pc_fn -std_cov_pc_fn $std_cov_pc_fn  2>&1 | tee $log_dir/02_extract_covariates_alltissue.log

all_cov_fn="$cov_data_dir/20170901.all_covariates.brain.txt"
all_cov_pc_fn="$cov_data_dir/20170901.all_covariates.PCs.brain.txt"
std_cov_pc_fn="$cov_data_dir/20170901.std_covars.PCs.brain.txt"
python 02_extract_covariates.py -all_cov_fn $all_cov_fn -all_cov_pc_fn $all_cov_pc_fn -std_cov_pc_fn $std_cov_pc_fn 2>&1 | tee $log_dir/02_extract_covariates_brain.log

### step-3a : filter data based on TPM and COUNT
Rscript 03a_filter_expression.R 2>&1 | tee $log_dir/03a_filter_expression.log

### step-3b: merge expr files
python 03b_merge_expression.py 2>&1 | tee $log_dir/03b_merge_expression.log

### step-4 - round1
outlier=""
brain_cov_fn="$cov_data_dir/20170901.all_covariates.PCs.brain.txt"
brain_gene_expr_fn="$data_dir/20170901.gtex_expression.gene.brain.txt"
gene_median_count_fn="$data_dir/20170901.gtex_expression.gene.median_cvg.txt"
brain_gene_outlier_pc_fn="$data_dir/20170901.gene.sample.outlier.pc.values.r1.txt"
brain_gene_expr_filtered_fn="$data_dir/20170901.gtex_expression.brain.good_genes.outlier_rm.txt"
brain_gene_outlier_plot_dir="$data_dir/outlier_plots/brain_genes_r1"
fast_svd="TRUE"
Rscript 04a_pc_plots_by_tissue.R -outlier "$outlier" -cov $brain_cov_fn -expr $brain_gene_expr_fn -med $gene_median_count_fn -outlier_pc $brain_gene_outlier_pc_fn -expr_filtered $brain_gene_expr_filtered_fn -pltdir $brain_gene_outlier_plot_dir  -fast.svd $fast_svd 2>&1 | tee $log_dir/04a_pc_plots_by_tissue_brain_gene_r1.log 

outlier=""
brain_cov_fn="$cov_data_dir/20170901.all_covariates.PCs.brain.txt"
brain_iso_expr_fn="$data_dir/20170901.gtex_expression.isoform.brain.txt"
iso_median_count_fn="$data_dir/20170901.gtex_expression.isoform.median_cvg.txt"
brain_iso_outlier_pc_fn="$data_dir/20170901.isoform.sample.outlier.pc.values.r1.txt"
brain_iso_expr_filtered_fn="$data_dir/20170901.gtex_expression.isoform.brain.good_genes.outlier_rm.txt"
brain_iso_outlier_plot_dir="$data_dir/outlier_plots/brain_isoforms_r1"
fast_svd="TRUE"
Rscript 04a_pc_plots_by_tissue.R -outlier "$outlier" -cov $brain_cov_fn -expr $brain_iso_expr_fn -med $iso_median_count_fn -outlier_pc $brain_iso_outlier_pc_fn -expr_filtered $brain_iso_expr_filtered_fn -pltdir $brain_iso_outlier_plot_dir  -fast.svd $fast_svd 2>&1 | tee $log_dir/04a_pc_plots_by_tissue_brain_iso_r1.log 

outlier=""
brain_cov_fn="$cov_data_dir/20170901.all_covariates.PCs.brain.txt"
brain_isopct_expr_fn="$data_dir/20170901.gtex_expression.isoform.percentage.brain.txt"
iso_median_count_fn="$data_dir/20170901.gtex_expression.isoform.median_cvg.txt"
brain_isopct_outlier_pc_fn="$data_dir/20170901.isoform.percentage.sample.outlier.pc.values.r1.txt"
brain_isopct_expr_filtered_fn="$data_dir/20170901.gtex_expression.isoform.percentage.brain.good_genes.outlier_rm.txt"
brain_isopct_outlier_plot_dir="$data_dir/outlier_plots/brain_isoforms_percentage_r1"
fast_svd="TRUE"
Rscript 04a_pc_plots_by_tissue.R -outlier "$outlier" -cov $brain_cov_fn -expr $brain_isopct_expr_fn -med $iso_median_count_fn -outlier_pc $brain_isopct_outlier_pc_fn -expr_filtered $brain_isopct_expr_filtered_fn -pltdir $brain_isopct_outlier_plot_dir  -fast.svd $fast_svd 2>&1 | tee $log_dir/04a_pc_plots_by_tissue_brain_isopct_r1.log

# select outlier brain samples
Rscript 04b_list_outliers_brain_r1.R

### step-4 - round2

outlier="$data_dir/20170901.outlier_samples_r1.txt"
brain_cov_fn="$cov_data_dir/20170901.all_covariates.PCs.brain.txt"
brain_gene_expr_fn="$data_dir/20170901.gtex_expression.gene.brain.txt"
gene_median_count_fn="$data_dir/20170901.gtex_expression.gene.median_cvg.txt"
brain_gene_outlier_pc_fn="$data_dir/20170901.gene.sample.outlier.pc.values.r2.txt"
brain_gene_expr_filtered_fn="$data_dir/20170901.gtex_expression.brain.good_genes.outlier_rm.txt"
brain_gene_outlier_plot_dir="$data_dir/outlier_plots/brain_genes_r2"
fast_svd="TRUE"
Rscript 04a_pc_plots_by_tissue.R -outlier "$outlier" -cov $brain_cov_fn -expr $brain_gene_expr_fn -med $gene_median_count_fn -outlier_pc $brain_gene_outlier_pc_fn -expr_filtered $brain_gene_expr_filtered_fn -pltdir $brain_gene_outlier_plot_dir  -fast.svd $fast_svd 2>&1 | tee $log_dir/04a_pc_plots_by_tissue_brain_gene_r2.log 

outlier="$data_dir/20170901.outlier_samples_r1.txt"
brain_cov_fn="$cov_data_dir/20170901.all_covariates.PCs.brain.txt"
brain_iso_expr_fn="$data_dir/20170901.gtex_expression.isoform.brain.txt"
iso_median_count_fn="$data_dir/20170901.gtex_expression.isoform.median_cvg.txt"
brain_iso_outlier_pc_fn="$data_dir/20170901.isoform.sample.outlier.pc.values.r2.txt"
brain_iso_expr_filtered_fn="$data_dir/20170901.gtex_expression.isoform.brain.good_genes.outlier_rm.txt"
brain_iso_outlier_plot_dir="$data_dir/outlier_plots/brain_isoforms_r2"
fast_svd="TRUE"
Rscript 04a_pc_plots_by_tissue.R -outlier "$outlier" -cov $brain_cov_fn -expr $brain_iso_expr_fn -med $iso_median_count_fn -outlier_pc $brain_iso_outlier_pc_fn -expr_filtered $brain_iso_expr_filtered_fn -pltdir $brain_iso_outlier_plot_dir  -fast.svd $fast_svd 2>&1 | tee $log_dir/04a_pc_plots_by_tissue_brain_iso_r2.log 


outlier="$data_dir/20170901.outlier_samples_r1.txt"
brain_cov_fn="$cov_data_dir/20170901.all_covariates.PCs.brain.txt"
brain_isopct_expr_fn="$data_dir/20170901.gtex_expression.isoform.percentage.brain.txt"
iso_median_count_fn="$data_dir/20170901.gtex_expression.isoform.median_cvg.txt"
brain_isopct_outlier_pc_fn="$data_dir/20170901.isoform.percentage.sample.outlier.pc.values.r2.txt"
brain_isopct_expr_filtered_fn="$data_dir/20170901.gtex_expression.isoform.percentage.brain.good_genes.outlier_rm.txt"
brain_isopct_outlier_plot_dir="$data_dir/outlier_plots/brain_isoforms_percentage_r2"
fast_svd="TRUE"
Rscript 04a_pc_plots_by_tissue.R -outlier "$outlier" -cov $brain_cov_fn -expr $brain_isopct_expr_fn -med $iso_median_count_fn -outlier_pc $brain_isopct_outlier_pc_fn -expr_filtered $brain_isopct_expr_filtered_fn -pltdir $brain_isopct_outlier_plot_dir  -fast.svd $fast_svd 2>&1 | tee $log_dir/04a_pc_plots_by_tissue_brain_isopct_r2.log

# select outlier brain samples
Rscript 04b_list_outliers_brain_r2.R


### step-4 - round3

outlier="$data_dir/20170901.outlier_samples_r2.txt"
brain_cov_fn="$cov_data_dir/20170901.all_covariates.PCs.brain.txt"
brain_gene_expr_fn="$data_dir/20170901.gtex_expression.gene.brain.txt"
gene_median_count_fn="$data_dir/20170901.gtex_expression.gene.median_cvg.txt"
brain_gene_outlier_pc_fn="$data_dir/20170901.gene.sample.outlier.pc.values.r3.txt"
brain_gene_expr_filtered_fn="$data_dir/20170901.gtex_expression.brain.good_genes.outlier_rm.txt"
brain_gene_outlier_plot_dir="$data_dir/outlier_plots/brain_genes_r3"
fast_svd="TRUE"
Rscript 04a_pc_plots_by_tissue.R -outlier "$outlier" -cov $brain_cov_fn -expr $brain_gene_expr_fn -med $gene_median_count_fn -outlier_pc $brain_gene_outlier_pc_fn -expr_filtered $brain_gene_expr_filtered_fn -pltdir $brain_gene_outlier_plot_dir  -fast.svd $fast_svd 2>&1 | tee $log_dir/04a_pc_plots_by_tissue_brain_gene_r3.log 

outlier="$data_dir/20170901.outlier_samples_r2.txt"
brain_cov_fn="$cov_data_dir/20170901.all_covariates.PCs.brain.txt"
brain_iso_expr_fn="$data_dir/20170901.gtex_expression.isoform.brain.txt"
iso_median_count_fn="$data_dir/20170901.gtex_expression.isoform.median_cvg.txt"
brain_iso_outlier_pc_fn="$data_dir/20170901.isoform.sample.outlier.pc.values.r3.txt"
brain_iso_expr_filtered_fn="$data_dir/20170901.gtex_expression.isoform.brain.good_genes.outlier_rm.txt"
brain_iso_outlier_plot_dir="$data_dir/outlier_plots/brain_isoforms_r3"
fast_svd="TRUE"
Rscript 04a_pc_plots_by_tissue.R -outlier "$outlier" -cov $brain_cov_fn -expr $brain_iso_expr_fn -med $iso_median_count_fn -outlier_pc $brain_iso_outlier_pc_fn -expr_filtered $brain_iso_expr_filtered_fn -pltdir $brain_iso_outlier_plot_dir  -fast.svd $fast_svd 2>&1 | tee $log_dir/04a_pc_plots_by_tissue_brain_iso_r3.log 


outlier="$data_dir/20170901.outlier_samples_r2.txt"
brain_cov_fn="$cov_data_dir/20170901.all_covariates.PCs.brain.txt"
brain_isopct_expr_fn="$data_dir/20170901.gtex_expression.isoform.percentage.brain.txt"
iso_median_count_fn="$data_dir/20170901.gtex_expression.isoform.median_cvg.txt"
brain_isopct_outlier_pc_fn="$data_dir/20170901.isoform.percentage.sample.outlier.pc.values.r3.txt"
brain_isopct_expr_filtered_fn="$data_dir/20170901.gtex_expression.isoform.percentage.brain.good_genes.outlier_rm.txt"
brain_isopct_outlier_plot_dir="$data_dir/outlier_plots/brain_isoforms_percentage_r3"
fast_svd="TRUE"
Rscript 04a_pc_plots_by_tissue.R -outlier "$outlier" -cov $brain_cov_fn -expr $brain_isopct_expr_fn -med $iso_median_count_fn -outlier_pc $brain_isopct_outlier_pc_fn -expr_filtered $brain_isopct_expr_filtered_fn -pltdir $brain_isopct_outlier_plot_dir  -fast.svd $fast_svd 2>&1 | tee $log_dir/04a_pc_plots_by_tissue_brain_isopct_r3.log

# note: after round 3, no outliers called.
# a few samples could be called outliers from 5th or 6th PC of isoform percentage,
# but that could be too strict.


### step-4 - round1 (all tissues)
outlier=""
alltissue_cov_fn="$cov_data_dir/20170901.all_covariates.PCs.txt"
alltissue_gene_expr_fn="$data_dir/20170901.gtex.expression.gene.alltissue.txt"
gene_median_count_fn="$data_dir/20170901.gtex_expression.gene.median_cvg.txt"
alltissue_gene_outlier_pc_fn="$data_dir/20170901.gene.sample.outlier.pc.values.r1.alltissue.txt"
alltissue_gene_expr_filtered_fn="$data_dir/20170901.gtex_expression.gene.alltissue.good_genes.outlier_rm.txt"
alltissue_gene_outlier_plot_dir="$data_dir/outlier_plots/alltissue_genes_r1"
fast_svd="TRUE"

Rscript 04a_pc_plots_by_tissue_v2_alltissue.R -outlier "$outlier" -cov $alltissue_cov_fn -expr $alltissue_gene_expr_fn -med $gene_median_count_fn -outlier_pc $alltissue_gene_outlier_pc_fn -expr_filtered $alltissue_gene_expr_filtered_fn -pltdir $alltissue_gene_outlier_plot_dir -fast.svd $fast_svd 2>&1 | tee $log_dir/04a_pc_plots_by_tissue_alltissue_gene_r1.log 

outlier=""
alltissue_cov_fn="$cov_data_dir/20170901.all_covariates.PCs.txt"
alltissue_iso_expr_fn="$data_dir/20170901.gtex.expression.isoform.alltissue.txt"
iso_median_count_fn="$data_dir/20170901.gtex_expression.isoform.median_cvg.txt"
alltissue_iso_outlier_pc_fn="$data_dir/20170901.isoform.sample.outlier.pc.values.r1.alltissue.txt"
alltissue_iso_expr_filtered_fn="$data_dir/20170901.gtex_expression.isoform.alltissue.good_genes.outlier_rm.txt"
alltissue_iso_outlier_plot_dir="$data_dir/outlier_plots/alltissue_isoforms_r1"
fast_svd="TRUE"

Rscript 04a_pc_plots_by_tissue_v2_alltissue.R -outlier "$outlier" -cov $alltissue_cov_fn -expr $alltissue_iso_expr_fn -med $iso_median_count_fn -outlier_pc $alltissue_iso_outlier_pc_fn -expr_filtered $alltissue_iso_expr_filtered_fn -pltdir $alltissue_iso_outlier_plot_dir -fast.svd $fast_svd 2>&1 | tee $log_dir/04a_pc_plots_by_tissue_alltissue_iso_r1.log 

outlier=""
alltissue_cov_fn="$cov_data_dir/20170901.all_covariates.PCs.txt"
alltissue_isopct_expr_fn="$data_dir/20170901.gtex.expression.isoform.percentage.alltissue.txt"
iso_median_count_fn="$data_dir/20170901.gtex_expression.isoform.median_cvg.txt"
alltissue_isopct_outlier_pc_fn="$data_dir/20170901.isoform.percentage.sample.outlier.pc.values.r1.alltissue.txt"
alltissue_isopct_expr_filtered_fn="$data_dir/20170901.gtex_expression.isoform.percentage.alltissue.good_genes.outlier_rm.txt"
alltissue_isopct_outlier_plot_dir="$data_dir/outlier_plots/alltissue_isoforms_percentage_r1"
fast_svd="TRUE"

Rscript 04a_pc_plots_by_tissue_v2_alltissue.R -outlier "$outlier" -cov $alltissue_cov_fn -expr $alltissue_isopct_expr_fn -med $iso_median_count_fn -outlier_pc $alltissue_isopct_outlier_pc_fn -expr_filtered $alltissue_isopct_expr_filtered_fn -pltdir $alltissue_isopct_outlier_plot_dir -fast.svd $fast_svd 2>&1 | tee $log_dir/04a_pc_plots_by_tissue_alltissue_isopct_r1.log

# select outlier alltissue samples
Rscript 04b_list_outliers_alltissue_r1.R

### step-4 - round2 (all tissues)

outlier="$data_dir/20170901.outlier_samples_alltissue_r1.txt"
alltissue_cov_fn="$cov_data_dir/20170901.all_covariates.PCs.txt"
alltissue_gene_expr_fn="$data_dir/20170901.gtex.expression.gene.alltissue.txt"
gene_median_count_fn="$data_dir/20170901.gtex_expression.gene.median_cvg.txt"
alltissue_gene_outlier_pc_fn="$data_dir/20170901.gene.sample.outlier.pc.values.r2.alltissue.txt"
alltissue_gene_expr_filtered_fn="$data_dir/20170901.gtex_expression.gene.alltissue.good_genes.outlier_rm.txt"
alltissue_gene_outlier_plot_dir="$data_dir/outlier_plots/alltissue_genes_r2"
fast_svd="TRUE"

Rscript 04a_pc_plots_by_tissue_v2_alltissue.R -outlier "$outlier" -cov $alltissue_cov_fn -expr $alltissue_gene_expr_fn -med $gene_median_count_fn -outlier_pc $alltissue_gene_outlier_pc_fn -expr_filtered $alltissue_gene_expr_filtered_fn -pltdir $alltissue_gene_outlier_plot_dir -fast.svd $fast_svd 2>&1 | tee $log_dir/04a_pc_plots_by_tissue_alltissue_gene_r2.log 

outlier="$data_dir/20170901.outlier_samples_alltissue_r1.txt"
alltissue_cov_fn="$cov_data_dir/20170901.all_covariates.PCs.txt"
alltissue_iso_expr_fn="$data_dir/20170901.gtex.expression.isoform.alltissue.txt"
iso_median_count_fn="$data_dir/20170901.gtex_expression.isoform.median_cvg.txt"
alltissue_iso_outlier_pc_fn="$data_dir/20170901.isoform.sample.outlier.pc.values.r2.alltissue.txt"
alltissue_iso_expr_filtered_fn="$data_dir/20170901.gtex_expression.isoform.alltissue.good_genes.outlier_rm.txt"
alltissue_iso_outlier_plot_dir="$data_dir/outlier_plots/alltissue_isoforms_r2"
fast_svd="TRUE"

Rscript 04a_pc_plots_by_tissue_v2_alltissue.R -outlier "$outlier" -cov $alltissue_cov_fn -expr $alltissue_iso_expr_fn -med $iso_median_count_fn -outlier_pc $alltissue_iso_outlier_pc_fn -expr_filtered $alltissue_iso_expr_filtered_fn -pltdir $alltissue_iso_outlier_plot_dir -fast.svd $fast_svd 2>&1 | tee $log_dir/04a_pc_plots_by_tissue_alltissue_iso_r2.log 

outlier="$data_dir/20170901.outlier_samples_alltissue_r1.txt"
alltissue_cov_fn="$cov_data_dir/20170901.all_covariates.PCs.txt"
alltissue_isopct_expr_fn="$data_dir/20170901.gtex.expression.isoform.percentage.alltissue.txt"
iso_median_count_fn="$data_dir/20170901.gtex_expression.isoform.median_cvg.txt"
alltissue_isopct_outlier_pc_fn="$data_dir/20170901.isoform.percentage.sample.outlier.pc.values.r2.alltissue.txt"
alltissue_isopct_expr_filtered_fn="$data_dir/20170901.gtex_expression.isoform.percentage.alltissue.good_genes.outlier_rm.txt"
alltissue_isopct_outlier_plot_dir="$data_dir/outlier_plots/alltissue_isoforms_percentage_r2"
fast_svd="TRUE"

Rscript 04a_pc_plots_by_tissue_v2_alltissue.R -outlier "$outlier" -cov $alltissue_cov_fn -expr $alltissue_isopct_expr_fn -med $iso_median_count_fn -outlier_pc $alltissue_isopct_outlier_pc_fn -expr_filtered $alltissue_isopct_expr_filtered_fn -pltdir $alltissue_isopct_outlier_plot_dir -fast.svd $fast_svd 2>&1 | tee $log_dir/04a_pc_plots_by_tissue_alltissue_isopct_r2.log

# select outlier alltissue samples
Rscript 04b_list_outliers_alltissue_r2.R


### step-4 - round3 (all tissues)

outlier="$data_dir/20170901.outlier_samples_alltissue_r2.txt"
alltissue_cov_fn="$cov_data_dir/20170901.all_covariates.PCs.txt"
alltissue_gene_expr_fn="$data_dir/20170901.gtex.expression.gene.alltissue.txt"
gene_median_count_fn="$data_dir/20170901.gtex_expression.gene.median_cvg.txt"
alltissue_gene_outlier_pc_fn="$data_dir/20170901.gene.sample.outlier.pc.values.r3.alltissue.txt"
alltissue_gene_expr_filtered_fn="$data_dir/20170901.gtex_expression.gene.alltissue.good_genes.outlier_rm.txt"
alltissue_gene_outlier_plot_dir="$data_dir/outlier_plots/alltissue_genes_r3"
fast_svd="TRUE"

Rscript 04a_pc_plots_by_tissue_v2_alltissue.R -outlier "$outlier" -cov $alltissue_cov_fn -expr $alltissue_gene_expr_fn -med $gene_median_count_fn -outlier_pc $alltissue_gene_outlier_pc_fn -expr_filtered $alltissue_gene_expr_filtered_fn -pltdir $alltissue_gene_outlier_plot_dir -fast.svd $fast_svd 2>&1 | tee $log_dir/04a_pc_plots_by_tissue_alltissue_gene_r3.log 

outlier="$data_dir/20170901.outlier_samples_alltissue_r2.txt"
alltissue_cov_fn="$cov_data_dir/20170901.all_covariates.PCs.txt"
alltissue_iso_expr_fn="$data_dir/20170901.gtex.expression.isoform.alltissue.txt"
iso_median_count_fn="$data_dir/20170901.gtex_expression.isoform.median_cvg.txt"
alltissue_iso_outlier_pc_fn="$data_dir/20170901.isoform.sample.outlier.pc.values.r3.alltissue.txt"
alltissue_iso_expr_filtered_fn="$data_dir/20170901.gtex_expression.isoform.alltissue.good_genes.outlier_rm.txt"
alltissue_iso_outlier_plot_dir="$data_dir/outlier_plots/alltissue_isoforms_r3"
fast_svd="TRUE"

Rscript 04a_pc_plots_by_tissue_v2_alltissue.R -outlier "$outlier" -cov $alltissue_cov_fn -expr $alltissue_iso_expr_fn -med $iso_median_count_fn -outlier_pc $alltissue_iso_outlier_pc_fn -expr_filtered $alltissue_iso_expr_filtered_fn -pltdir $alltissue_iso_outlier_plot_dir -fast.svd $fast_svd 2>&1 | tee $log_dir/04a_pc_plots_by_tissue_alltissue_iso_r3.log 

outlier="$data_dir/20170901.outlier_samples_alltissue_r2.txt"
alltissue_cov_fn="$cov_data_dir/20170901.all_covariates.PCs.txt"
alltissue_isopct_expr_fn="$data_dir/20170901.gtex.expression.isoform.percentage.alltissue.txt"
iso_median_count_fn="$data_dir/20170901.gtex_expression.isoform.median_cvg.txt"
alltissue_isopct_outlier_pc_fn="$data_dir/20170901.isoform.percentage.sample.outlier.pc.values.r3.alltissue.txt"
alltissue_isopct_expr_filtered_fn="$data_dir/20170901.gtex_expression.isoform.percentage.alltissue.good_genes.outlier_rm.txt"
alltissue_isopct_outlier_plot_dir="$data_dir/outlier_plots/alltissue_isoforms_percentage_r3"
fast_svd="TRUE"

Rscript 04a_pc_plots_by_tissue_v2_alltissue.R -outlier "$outlier" -cov $alltissue_cov_fn -expr $alltissue_isopct_expr_fn -med $iso_median_count_fn -outlier_pc $alltissue_isopct_outlier_pc_fn -expr_filtered $alltissue_isopct_expr_filtered_fn -pltdir $alltissue_isopct_outlier_plot_dir -fast.svd $fast_svd 2>&1 | tee $log_dir/04a_pc_plots_by_tissue_alltissue_isopct_r3.log

# select outlier alltissue samples
#Rscript 04b_list_outliers_alltissue_r3.R





#### step-5 variance explained -- totallm model
##### variance partition -- brain genes ###############
expr_fn="$data_dir/20170901.gtex_expression.brain.good_genes.outlier_rm.txt"
cov_fn="$data_dir/covariates/20170901.all_covariates.PCs.brain.txt"
min_sample=15
out_pref="$var_exp_dir/brain_gene"
tissue=""
do_log=TRUE
min_sample=15
interaction=""
model="totallm"
na_str=""
max_pc=20
Rscript 05a_variance_partition.R -expr $expr_fn -cov $cov_fn -tissue "$tissue" -log $do_log -min_sample $min_sample -o $out_pref  -interaction "$interaction" -model "$model" -na "$na_str" -max_pc $max_pc 2>&1 | tee $log_dir/05a_variance_partition_brain_gene_together.log


mkdir "$var_exp_dir/per_tissue"
for tissue in BRNCTXBA9 BRNCDT BRNACC BRNPUT BRNHYP BRNHIP BRNCTXB24 BRNSNA BRNAMY
do
  echo $tissue
  expr_fn="$data_dir/20170901.gtex_expression.brain.good_genes.outlier_rm.txt"
  cov_fn="$cov_data_dir/20170901.all_covariates.PCs.brain.txt"
  do_log=TRUE
  min_sample=15
  interaction=""
  model="totallm"
  na_str=""
  max_pc=20
  out_pref="$var_exp_dir/per_tissue/brain_gene_${tissue}"
  Rscript 05a_variance_partition.R -expr $expr_fn -cov $cov_fn -tissue $tissue -log $do_log -min_sample $min_sample -o $out_pref  -interaction "$interaction" -model "$model" -na "$na_str" -max_pc $max_pc 2>&1 | tee "$log_dir/05a_variance_partition_brain_gene_within_${tissue}.log"
done


### variance parition per tissue in alltissue-processed data
expr_fn="$data_dir/20170901.gtex_expression.gene.alltissue.good_genes.outlier_rm.txt"
cov_fn="$data_dir/covariates/20170901.all_covariates.PCs.txt"
min_sample=15
out_pref="$var_exp_dir/alltissue_gene"
tissue=""
do_log=TRUE
min_sample=15
interaction=""
model="totallm"
na_str=""
max_pc=20
Rscript 05a_variance_partition.R -expr $expr_fn -cov $cov_fn -tissue "$tissue" -log $do_log -min_sample $min_sample -o $out_pref  -interaction "$interaction" -model "$model" -na "$na_str" -max_pc $max_pc 2>&1 | tee $log_dir/05a_variance_partition_alltissue_gene_together.log


for tissue in ADPSBQ ADPVSC ADRNLG ARTAORT ARTCRN ARTTBL BREAST BRNACC BRNAMY BRNCDT BRNCTXB24 BRNCTXBA9 BRNHIP BRNHYP BRNPUT BRNSNA CLNSIG CLNTRN ESPGEJ ESPMCS ESPMSL FIBRCUL HRTAA HRTLV LCL LIVER LUNG MSCLSK NERVET OVARY PNCREAS PRSTTE PTTARY SALVMNR SKINNS SKINS SMNTILM SPLN STMACH TESTIS THYROID UTERUS VAGINA WHLBLD
do
  echo $tissue
  expr_fn="$data_dir/20170901.gtex_expression.gene.alltissue.good_genes.outlier_rm.txt"
  cov_fn="$cov_data_dir/20170901.all_covariates.PCs.txt"
  do_log=TRUE
  min_sample=15
  interaction=""
  model="totallm"
  na_str=""
  max_pc=20
  out_pref="$var_exp_dir/per_tissue/alltisue_gene_${tissue}"
  Rscript 05a_variance_partition.R -expr $expr_fn -cov $cov_fn -tissue $tissue -log $do_log -min_sample $min_sample -o $out_pref  -interaction "$interaction" -model "$model" -na "$na_str" -max_pc $max_pc  2>&1 | tee "$log_dir/05a_variance_partition_alltissue_gene_within_${tissue}.log"
done



mkdir "$var_exp_dir/per_tissue/combined"

dir="$var_exp_dir/per_tissue"
pattern='brain_gene_.*_variance_explained_by_cov.txt$'
out_prefix="$dir/combined/brain_gene_combined_variance_explained_by_cov"
Rscript 05b_combine_totallm_results.R -dir $dir -pattern $pattern -o $out_prefix 2>&1 | tee $log_dir/05b_combine_totallm_results_brain_gene.log


dir="$var_exp_dir/per_tissue"
pattern='alltisue_gene_.*_variance_explained_by_cov.txt$'
out_prefix="$dir/combined/alltisue_gene_combined_variance_explained_by_cov"
Rscript 05b_combine_totallm_results.R -dir $dir -pattern $pattern -o $out_prefix 2>&1 | tee $log_dir/05b_combine_totallm_results_alltissue_gene.log



### step-6 linear regression (brain tissues)
# gene
expr_fn="$data_dir/20170901.gtex_expression.brain.good_genes.outlier_rm.txt"
cov_fn="$cov_data_dir/20170901.all_covariates.PCs.brain.txt"
do_log=TRUE
min_sample=15
na_str="UNKNOWN"
out_all="$data_dir/20170901.gtex_expression.brain.good_genes.outlier_rm.lm_regressed.txt"
out_within="$data_dir/20170901.gtex_expression.brain.good_genes.outlier_rm.lm_regressed.within_tissue.txt"
Rscript 06a_regress_lm.R -expr $expr_fn -cov $cov_fn -log $do_log -out_all "$out_all" -out_within "$out_within" -min_sample $min_sample -na "$na_str"   2>&1 | tee $log_dir/06a_regress_lm_brain_gene.log

# isoform
expr_fn="$data_dir/20170901.gtex_expression.isoform.brain.good_genes.outlier_rm.txt"
cov_fn="$cov_data_dir/20170901.all_covariates.PCs.brain.txt"
do_log=TRUE
min_sample=15
na_str="UNKNOWN"
out_all="$data_dir/20170901.gtex_expression.isoform.brain.good_genes.outlier_rm.lm_regressed.txt"
out_within="$data_dir/20170901.gtex_expression.isoform.brain.good_genes.outlier_rm.lm_regressed.within_tissue.txt"
Rscript 06a_regress_lm.R -expr $expr_fn -cov $cov_fn -log $do_log -out_all "$out_all" -out_within "$out_within" -min_sample $min_sample -na "$na_str"   2>&1 | tee $log_dir/06a_regress_lm_brain_iso.log

# isoform ratio
expr_fn="$data_dir/20170901.gtex_expression.isoform.percentage.brain.good_genes.outlier_rm.txt"
cov_fn="$cov_data_dir/20170901.all_covariates.PCs.brain.txt"
do_log=TRUE
min_sample=15
na_str="UNKNOWN"
out_all="$data_dir/20170901.gtex_expression.isoform.percentage.brain.good_genes.outlier_rm.lm_regressed.txt"
out_within="$data_dir/20170901.gtex_expression.isoform.percentage.brain.good_genes.outlier_rm.lm_regressed.within_tissue.txt"
Rscript 06a_regress_lm.R -expr $expr_fn -cov $cov_fn -log $do_log -out_all "$out_all" -out_within "$out_within" -min_sample $min_sample -na "$na_str"    2>&1 | tee $log_dir/06a_regress_lm_brain_isopct.log


### step-6 linear regression (all tissues)
# gene
expr_fn="$data_dir/20170901.gtex_expression.gene.alltissue.good_genes.outlier_rm.txt"
cov_fn="$cov_data_dir/20170901.all_covariates.PCs.txt"
do_log=TRUE
min_sample=15
na_str="UNKNOWN"
out_all="$data_dir/20170901.gtex_expression.gene.alltissue.good_genes.outlier_rm.lm_regressed.txt"
out_within="$data_dir/20170901.gtex_expression.gene.alltissue.good_genes.outlier_rm.lm_regressed.within_tissue.txt"
Rscript 06a_regress_lm.R -expr $expr_fn -cov $cov_fn -log $do_log -out_all "$out_all" -out_within "$out_within" -min_sample $min_sample -na "$na_str"   2>&1 | tee $log_dir/06a_regress_lm_alltissue_gene.log

# isoform
expr_fn="$data_dir/20170901.gtex_expression.isoform.alltissue.good_genes.outlier_rm.txt"
cov_fn="$cov_data_dir/20170901.all_covariates.PCs.txt"
do_log=TRUE
min_sample=15
na_str="UNKNOWN"
out_all="$data_dir/20170901.gtex_expression.isoform.alltissue.good_genes.outlier_rm.lm_regressed.txt"
out_within="$data_dir/20170901.gtex_expression.isoform.alltissue.good_genes.outlier_rm.lm_regressed.within_tissue.txt"
Rscript 06a_regress_lm.R -expr $expr_fn -cov $cov_fn -log $do_log -out_all "$out_all" -out_within "$out_within" -min_sample $min_sample -na "$na_str"   2>&1 | tee $log_dir/06a_regress_lm_alltissue_iso.log

# isoform ratio
expr_fn="$data_dir/20170901.gtex_expression.isoform.percentage.alltissue.good_genes.outlier_rm.txt"
cov_fn="$cov_data_dir/20170901.all_covariates.PCs.txt"
do_log=TRUE
min_sample=15
na_str="UNKNOWN"
out_all="$data_dir/20170901.gtex_expression.isoform.percentage.alltissue.good_genes.outlier_rm.lm_regressed.txt"
out_within="$data_dir/20170901.gtex_expression.isoform.percentage.alltissue.good_genes.outlier_rm.lm_regressed.within_tissue.txt"
Rscript 06a_regress_lm.R -expr $expr_fn -cov $cov_fn -log $do_log -out_all "$out_all" -out_within "$out_within" -min_sample $min_sample -na "$na_str"    2>&1 | tee $log_dir/06a_regress_lm_alltissue_isopct.log


### check PVE after linear model correction -- brain tissues
mkdir "$var_exp_dir/per_tissue_after_correction"
for tissue in BRNCTXBA9 BRNCDT BRNACC BRNPUT BRNHYP BRNHIP BRNCTXB24 BRNSNA BRNAMY
do
  echo $tissue
  expr_fn="$data_dir/20170901.gtex_expression.brain.good_genes.outlier_rm.lm_regressed.within_tissue.txt"
  cov_fn="$cov_data_dir/20170901.all_covariates.PCs.brain.txt"
  do_log=FALSE
  min_sample=15
  interaction=""
  model="totallm"
  na_str=""
  max_pc=20
  out_pref="$var_exp_dir/per_tissue_after_correction/brain_gene_${tissue}"
  Rscript 05a_variance_partition.R -expr $expr_fn -cov $cov_fn -tissue $tissue -log $do_log -min_sample $min_sample -o $out_pref  -interaction "$interaction" -model "$model" -na "$na_str" -max_pc $max_pc 2>&1 | tee "$log_dir/05a_variance_partition_brain_gene_within_${tissue}_after_correction.log"
done


### check PVE after linear model correction -- all tissues
for tissue in ADPSBQ ADPVSC ADRNLG ARTAORT ARTCRN ARTTBL BREAST BRNACC BRNAMY BRNCDT BRNCTXB24 BRNCTXBA9 BRNHIP BRNHYP BRNPUT BRNSNA CLNSIG CLNTRN ESPGEJ ESPMCS ESPMSL FIBRCUL HRTAA HRTLV LCL LIVER LUNG MSCLSK NERVET OVARY PNCREAS PRSTTE PTTARY SALVMNR SKINNS SKINS SMNTILM SPLN STMACH TESTIS THYROID UTERUS VAGINA WHLBLD
do
  echo $tissue
  expr_fn="$data_dir/20170901.gtex_expression.gene.alltissue.good_genes.outlier_rm.lm_regressed.within_tissue.txt"
  cov_fn="$cov_data_dir/20170901.all_covariates.PCs.txt"
  do_log=FALSE
  min_sample=15
  interaction=""
  model="totallm"
  na_str=""
  max_pc=20
  out_pref="$var_exp_dir/per_tissue_after_correction/alltisue_gene_${tissue}"
  Rscript 05a_variance_partition.R -expr $expr_fn -cov $cov_fn -tissue $tissue -log $do_log -min_sample $min_sample -o $out_pref  -interaction "$interaction" -model "$model" -na "$na_str" -max_pc $max_pc 2>&1 | tee "$log_dir/05a_variance_partition_alltissue_gene_within_${tissue}_after_correction.log"
done



mkdir "$var_exp_dir/per_tissue_after_correction/combined"

dir="$var_exp_dir/per_tissue_after_correction"
pattern='brain_gene_.*_variance_explained_by_cov.txt$'
out_prefix="$dir/combined/brain_gene_combined_variance_explained_by_cov"
Rscript 05b_combine_totallm_results.R -dir $dir -pattern $pattern -o $out_prefix 2>&1 | tee $log_dir/05b_combine_totallm_results_brain_gene_after_correction.log


dir="$var_exp_dir/per_tissue_after_correction"
pattern='alltisue_gene_.*_variance_explained_by_cov.txt$'
out_prefix="$dir/combined/alltisue_gene_combined_variance_explained_by_cov"
Rscript 05b_combine_totallm_results.R -dir $dir -pattern $pattern -o $out_prefix 2>&1 | tee $log_dir/05b_combine_totallm_results_alltissue_gene_after_correction.log

