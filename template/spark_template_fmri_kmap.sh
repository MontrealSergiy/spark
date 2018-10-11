#!/bin/bash
#PBS -I nodes=1:ppn:4
#PBS -V
#PBS -N pipeline_manager
#PBS -l walltime=30:00:00
#PBS -A ixx-903-aa
export TMPDIR=/localscratch/kangjoo
mkdir $TMPDIR
matlab -nodisplay /mydirectory/SPARKv1.0.1_N_estimation/template/spark_template_fmri_kmap.m
rm -rf $TMPDIR