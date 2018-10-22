
% tempdir 
% clear all
% setenv('TMP','/gs/scratch/kangjoo/tmp2/') % TEMP for Windows
% tempdir



pbs_jobid = getenv('PBS_JOBID');
if isempty(pbs_jobid)
    gb_psom_tmp = '/localscratch/';
else
    gb_psom_tmp = ['/localscratch/' pbs_jobid filesep]; 
end
setenv('TMP',gb_psom_tmp)


clc; clear; close all; fclose all;

addpath(genpath('/sb/project/ixx-903-aa/kangjoo/Matlab_code/2_Kangjoo_matlab/SPARK/SPARKv1.0.1_N_estimation'));
addpath(genpath('/sb/project/ixx-903-aa/kangjoo/Matlab_code/niak-boss-0.13.0')); 



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                  LOAD DATA                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pathname='/sb/project/ixx-903-aa/kangjoo/controls_newprotocol_2/01_prep_MNI_Controls_res4_fwhm8_scrub0.5/fmri/';

files_in.subject1.fmri.session1 = {[pathname 'fmri_subject1_session1_run1.mnc']};
files_in.subject2.fmri.session1 = {[pathname 'fmri_subject2_session1_run1.mnc']};
files_in.subject2.fmri.session2 = {[pathname 'fmri_subject2_session1_run2.mnc']};


path_out='/sb/project/ixx-903-aa/kangjoo/controls_newprotocol_2/02_sparkv1.0.1_Controls_res4_fwhm8_scrub0.5/'; % output directory
if ~exist(path_out,'dir')
    mkdir(path_out);
end
maskpath='/sb/project/ixx-903-aa/kangjoo/GM_mask_AAL_4mm/roi_func_total_bin_mask.mnc'; % Gray matter mask to select voxels for SPARK analysis


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 SET PARAMETERS              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%- Default: K-SVD paramaters
param.L                           = [];%Leave it empty. Sparsity level will be determined automatically.
param.K                           = []; %Leave it empty. The network scale will be determined automatically.
param.test_scale                  = [10:2:30]; 
param.numIteration                = 20;
param.errorFlag                   = 0;
param.preserveDCAtom              = 0;
param.InitializationMethod        = 'GivenMatrix';
param.SparsecodingMethod          = 'Thresholding';
param.displayProgress             =1;

%- Step 1: Bootstrap Resampling
opt.folder_tseries_boot.mask = maskpath; % That's a mask for the analysis. It can be a mask of the brain common to all subjects, or a mask of a specific brain area, e.g. the thalami.
opt.folder_tseries_boot.nb_samps                = 100; % Number of bootstrap samples at the individual level. 100: the CI on indidividual stability is +/-0.1
opt.folder_tseries_boot.bootstrap.dgp           = 'CBB'; %(string, default 'CBB') the method used to resample the data under the null hypothesis. Available options :'CBB' (recommended),'AR1B', 'AR1G'
opt.folder_tseries_boot.bootstrap.block_length  = [10:30];%(integer, default 1) window width used in the circular block bootstrap.
opt.folder_tseries_boot.flag                    = 0; % If you want to re-run this step, change this value to 1. If the flag will catch any change of this value, it will re-run this step and the following steps associated to this step.

%- Step 2: Sparse Dictionary Learning
opt.folder_kmdl.mask                            = opt.folder_tseries_boot.mask;
opt.folder_kmdl.ksvd.param                      = param;
opt.folder_kmdl.nb_samps                        = opt.folder_tseries_boot.nb_samps; 
opt.folder_kmdl.bootstrap.dgp                   = opt.folder_tseries_boot.bootstrap.dgp;
opt.folder_kmdl.bootstrap.block_length          = opt.folder_tseries_boot.bootstrap.block_length;
opt.folder_kmdl.flag                            = 0; % If you want to re-run this step, change this value to 1. If the flag will catch any change of this value, it will re-run this step and the following steps associated to this step.


%- Step 3: Clustering for spatial maps
opt.folder_global_dictionary                    = opt.folder_kmdl;
opt.folder_global_dictionary.flag               = 0; % If you want to re-run this step, change this value to 1. If the flag will catch any change of this value, it will re-run this step and the following steps associated to this step.

% Step 4: k-map Generation
opt.folder_kmap.pvalue                          = 0.01;
opt.folder_kmap.nb_samps                        = opt.folder_tseries_boot.nb_samps;
opt.folder_kmap.ksvd                            = opt.folder_kmdl.ksvd;     
opt.folder_kmap.flag                            = 0;

% Folder Options: 
% This is a default option for NIAK fmri processing, but not necessary for SPARK. Just keep it like that, do not change. 
% The amount of outputs that are generated by the pipeline. 'all' will keep intermediate outputs, 'quality_control' will only keep the quality control outputs. 
opt.flag_session = 1;
opt.folder_in=pathname;
opt.folder_out = path_out;
opt.size_output = 'quality_control'; 
opt.flag_test = 0;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                PIPELINE OPTIONS             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Pipeline Options: This is where you need to change to set up in your parallel computing system.
opt.psom.mode                  = 'session'; % Process jobs in the background, 'session' or 'qsub' or 'msub' depending on your parallel computing system
opt.psom.mode_pipeline_manager = 'session'; % Run the pipeline manager in the background : if I unlog, keep working
opt.psom.max_queued            = 200;       % Number of jobs that can run in parallel. In batch mode, this is usually the number of cores.
opt.psom.qsub_options          = '-q sw -l walltime=4:00:00 -A ixx-903-aa -l nodes=1:ppn=2';
opt.psom.nb_resub = 5;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 RUN PIPELINE                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
opt.flag_test = false; % Put this flag to true to just generate the pipeline without running it. I haven't tested this option but just keep it 'false' which has been working.

[pipeline,opt] = spark_pipeline_fmri_kmap(files_in,opt);

