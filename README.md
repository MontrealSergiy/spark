# SPARK
SParsity-based Analysis of Reliable K-hubness for Brain Functional Connectivity fMRI 
(http://www.sciencedirect.com/science/article/pii/S1053811916002548)

SPARK is a MATLAB-based toolbox for functional MRI analysis dedicated to the reliable estimation of overlapping functional network structure from individual fMRI. It is a voxel-wise multivariate analysis of a set of 3D+t BOLD contrast images, based on sparse dictionary learning for the data driven sparse GLM (http://ieeexplore.ieee.org/document/5659483/). It further achieves statistical reproducibility of the estimation of individual network structure by a bootstrap resampling based strategy. This method is fully data-driven, and provides an automatic estimation of the number (K) and combination of overlapping networks based on L0-norm sparisty and minimum description criterion.

SPARK has been built upon Neuroimaging Analysis Kit (NIAK) (http://www.nitrc.org/plugins/mwiki/index.php/niak:MainPage), which is a public library of modules and pipelines for fMRI processing with Octave or Matlab(r) that can run in parallel either locally or in a supercomputing environment. Linux OS and MINC format is currently supported in both NIAK and SPARK.

SPARK is currently in preparation for release.


=Contributors=

The original code for the implementation of SPARK was developed by Kangjoo Lee (http://www.bic.mni.mcgill.ca/PersonalLeekangjoo/HomePage) at McGill University and Montreal Neurological Institute, where she is doing her PhD with Christophe Grova (McGill University and PERFORM Centre, Concordia University http://www.bic.mni.mcgill.ca/ResearchLabsMFIL/PeopleChristophe) and Jean Gotman (Montreal Neurological Institute http://www.bic.mni.mcgill.ca/ResearchLabsMFIL/PeopleJeanGotman). The work was done by a collaboration with Jean-Marc Lina (École de Technologie Supérieure and Centre de Recherches Mathématiques, Université de Montréal http://www.bic.mni.mcgill.ca/ResearchLabsMFIL/PeopleJeanMarc).


