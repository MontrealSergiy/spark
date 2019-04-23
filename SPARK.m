addpath(genpath(fileparts(mfilename('fullpath'))))

%% Parsing scheme
p.fmriData = argv(){1};
p.greyMatterMask = argv(){2};
p.numberOfResamplings = argv(){3};
p.networkScales = argv(){4};
p.numberOfIterations = argv(){5};
p.pValue = argv(){6};
for k = 7:2:nargin
    p.(argv(){k}) = argv(){k+1};
end

%% Private parameters below (for now...), i.e. not visible from Boutiques
p.rerunStep1 = 0;
p.rerunStep2 = 0;
p.rerunStep3 = 0;
p.rerunStep4 = 0;
p.sparsityLevel = '';
p.networkScale = '';
p.errorFlag = '0';
p.displayProgress = '0';
p.session = '1';
p.outDir = ['.',filesep,'spark-results-',datestr(clock(),'yy.mm.dd-HH.MM'),filesep];
p.outSize = 'quality_control';
p.test = '0';

disp(p)


%% Creates the options structure to run SPARK
opt = struct();


f = strsplit(p.fmriData,',');
for k = 1:length(f)
    files_in.subject1.fmri.(['session',int2str(k)]) = f(k);
end


% Step 1: Bootstrap resampling 
opt.folder_tseries_boot.mask = p.greyMatterMask;
opt.folder_tseries_boot.nb_samps = str2double(p.numberOfResamplings);
opt.folder_tseries_boot.bootstrap.dgp = p.resamplingMethod;
opt.folder_tseries_boot.bootstrap.block_length = str2RegSpacedVector(p.blockWindowLength);
opt.folder_tseries_boot.flag = str2double(p.rerunStep1);


% Step 2: Sparse dictionary learning
opt.folder_kmdl = opt.folder_tseries_boot;
opt.folder_kmdl.flag = str2double(p.rerunStep2);
opt.folder_kmdl.ksvd.param = struct(...
    'test_scale',str2RegSpacedVector(p.networkScales),...
    'numIteration',str2double(p.numberOfIterations),...
    'errorFlag',str2double(p.errorFlag),...
    'preserveDCAtom',str2double(p.preserveAtomsDict),...
    'InitializationMethod',p.dictionaryInitMethod,...
    'SparsecodingMethod',p.sparseCodingMethod,...
    'displayProgress',str2double(p.displayProgress)...
    );
if isempty(p.sparsityLevel)
    opt.folder_kmdl.ksvd.param.L = [];
end
if isempty(p.networkScale)
    opt.folder_kmdl.ksvd.param.K = [];
end


% Step 3: spatial clustering
opt.folder_global_dictionary = opt.folder_kmdl;
opt.folder_global_dictionary.flag = str2double(p.rerunStep3);


% Step 4: k-hubness map generation
opt.folder_kmap.nb_samps = opt.folder_tseries_boot.nb_samps;
opt.folder_kmap.ksvd = opt.folder_kmdl.ksvd;
opt.folder_kmap.pvalue = str2double(p.pValue);
opt.folder_kmap.flag = str2double(p.rerunStep4);


% Miscellaneous
opt.flag_session = str2double(p.session);
opt.folder_in = ''; % useless?
opt.folder_out = p.outDir;
opt.size_output = p.outSize;
opt.flag_test = str2double(p.test);


% PSOM options, don't use qsub when using CBRAIN (add 
opt.psom = struct(...
    'mode_pipeline_manager','session',...
    'mode','batch',...
    'max_queued',Inf,...
    'nb_resub',5 ...
    );


%% Runs SPARK
if ~exist(p.outDir,'dir')
	mkdir(p.outDir);
end
[pipeline,opt] = spark_pipeline_fmri_kmap(files_in,opt);%#ok
save([p.outDir,filesep,'pipeline',datestr(clock(),'yy.mm.dd-HH.MM'),'.mat'],'-struct','pipeline','-v7.3')
save([p.outDir,filesep,'opt',datestr(clock(),'yy.mm.dd-HH.MM'),'.mat'],'-struct','opt','-v7.3')