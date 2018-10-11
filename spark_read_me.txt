To run a pipeline,

1. Go to the directory /home/SPARKv1.0.1_N_estimation/template/

2. Open the template file spark_template_fmri_kmap_MNI_Controls.m

3. Put your inputs: 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                  SET PATH                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath(genpath('/home/SPARKv1.0.1_N_estimation')); 
>> This is the path for the SPARK package. 

addpath(genpath('/sb/project/ixx-903-aa/kangjoo/Matlab_code/niak-2012-04-PB')); 
>> This is the path for the NIAK package that is required for SPARK. If you work on Guillmin clusters from Calcul Quebec, simply use the abovementioned path.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                  LOAD DATA                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pathname: set your directory that have input files: preprocessed fmri runs (4D .mnc format).
path_out: set your output directory
maskpath: a gray matter mask with equal dimensions with your fmri runs should be identified. (3D .mnc format).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 SET PARAMETERS              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Set your parameters for SPARK analysis


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                PIPELINE OPTIONS             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
This part is exactly same as in NIAK, you need to set up your options for PSOM processing which allows you parallel computing.



4. Now you are good to run this file.


