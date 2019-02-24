function SPARK(varargin)

%% Parsing scheme
p = inputParser;

addRequired(p, 'fmriData', checkValFunc('fmriData'))
addRequired(p, 'greyMatterMask', checkValFunc('greyMatterMask'))

addRequired(p, 'numberOfResamplings', checkValFunc('numberOfResamplings'))
addRequired(p, 'networkScales', checkValFunc('networkScales'))
addRequired(p, 'numberOfIterations', checkValFunc('numberOfIterations'))
addRequired(p, 'pValue', checkValFunc('pValue'))

addParameter(p, 'resamplingMethod', defaultVal('resamplingMethod'), checkValFunc('resamplingMethod'))
addParameter(p, 'blockWindowLength', defaultVal('blockWindowLength'), checkValFunc('blockWindowLength'))
addParameter(p, 'dictInitMethod', defaultVal('dictInitMethod'), checkValFunc('dictInitMethod'))
addParameter(p, 'sparseCodingMethod', defaultVal('sparseCodingMethod'), checkValFunc('sparseCodingMethod'))
addParameter(p, 'preserveAtomsDict', defaultVal('preserveAtomsDict'), checkValFunc('preserveAtomsDict'))

% The parameters below are private (for now...), i.e. not visible from
% Boutiques
addParameter(p, 'rerunStep1', defaultVal('rerunStep1'), checkValFunc('rerunStep1'))
addParameter(p, 'rerunStep2', defaultVal('rerunStep2'), checkValFunc('rerunStep2'))
addParameter(p, 'rerunStep3', defaultVal('rerunStep3'), checkValFunc('rerunStep3'))
addParameter(p, 'rerunStep4', defaultVal('rerunStep4'), checkValFunc('rerunStep4'))

addParameter(p, 'sparsityLevel', defaultVal('sparsityLevel'), checkValFunc('sparsityLevel'))
addParameter(p, 'networkScale', defaultVal('networkScale'), checkValFunc('networkScale'))
addParameter(p, 'errorFlag', defaultVal('errorFlag'), checkValFunc('errorFlag'))
addParameter(p, 'displayProgress', defaultVal('displayProgress'), checkValFunc('displayProgress'))

addParameter(p, 'session', defaultVal('session'), checkValFunc('session'))
addParameter(p, 'outDir', defaultVal('outDir'), checkValFunc('outDir'))
addParameter(p, 'outSize', defaultVal('outSize'), checkValFunc('outSize'))
addParameter(p, 'test', defaultVal('test'), checkValFunc('test'))

p.KeepUnmatched = true;
p.PartialMatching = false;

parse(p,varargin{:})

if ~isempty(p.UsingDefaults)
   disp('*** Using defaults values for: ')
   disp(p.UsingDefaults)
end
if ~isempty(fieldnames(p.Unmatched))
   disp('*** Extra inputs:')
   disp(p.Unmatched)
end


%% Creates the options structure to run SPARK
opt = struct();


f = strsplit(p.Results.fmriData,' ');
for k = 1:length(f)
    files_in.subject1.fmri.(['session',int2str(k)]) = f(k);
end


% Step 1: Bootstrap resampling 
opt.folder_tseries_boot.mask = p.Results.greyMatterMask;
opt.folder_tseries_boot.nb_samps = str2double(p.Results.numberOfResamplings);
opt.folder_tseries_boot.bootstrap.dgp = p.Results.resamplingMethod;
opt.folder_tseries_boot.bootstrap.block_length = str2RegSpacedVector(p.Results.blockWindowLength);
opt.folder_tseries_boot.flag = str2double(p.Results.rerunStep1);


% Step 2: Sparse dictionary learning
opt.folder_kmdl = opt.folder_tseries_boot;
opt.folder_kmdl.flag = str2double(p.Results.rerunStep2);
opt.folder_kmdl.ksvd.param = struct(...
    'test_scale',str2RegSpacedVector(p.Results.networkScales),...
    'numIteration',str2double(p.Results.numberOfIterations),...
    'errorFlag',str2double(p.Results.errorFlag),...
    'preserveDCAtom',str2double(p.Results.preserveAtomsDict),...
    'InitializationMethod',p.Results.dictInitMethod,...
    'SparsecodingMethod',p.Results.sparseCodingMethod,...
    'displayProgress',str2double(p.Results.displayProgress)...
    );
if isempty(p.Results.sparsityLevel)
    opt.folder_kmdl.ksvd.param.L = [];
end
if isempty(p.Results.networkScale)
    opt.folder_kmdl.ksvd.param.K = [];
end


% Step 3: spatial clustering
opt.folder_global_dictionary = opt.folder_kmdl;
opt.folder_global_dictionary.flag = str2double(p.Results.rerunStep3);


% Step 4: k-hubness map generation
opt.folder_kmap.nb_samps = opt.folder_tseries_boot.nb_samps;
opt.folder_kmap.ksvd = opt.folder_kmdl.ksvd;
opt.folder_kmap.pvalue = str2double(p.Results.pValue);
opt.folder_kmap.flag = str2double(p.Results.rerunStep4);


% Miscellaneous
opt.flag_session = str2double(p.Results.session);
opt.folder_in = ''; % useless?
opt.folder_out = p.Results.outDir;
opt.size_output = p.Results.outSize;
opt.flag_test = str2double(p.Results.test);


% PSOM options, don't use qsub when using CBRAIN (add 
opt.psom = struct(...
    'mode_pipeline_manager','session',...
    'mode','batch',...
    'max_queued',Inf,...
    'nb_resub',5 ...
    );


%% Runs SPARK
if ~exist(p.Results.outDir,'dir')
	mkdir(p.Results.outDir);
end
[pipeline,opt] = spark_pipeline_fmri_kmap(files_in,opt);%#ok
save([p.Results.outDir,filesep,'pipeline',datestr(clock(),'yy.mm.dd-HH.MM'),'.mat'],'-struct','pipeline','-v7.3')
save([p.Results.outDir,filesep,'opt',datestr(clock(),'yy.mm.dd-HH.MM'),'.mat'],'-struct','opt','-v7.3')

end



%% Local functions

function val = validVal(argName)
switch argName
    case 'resamplingMethod'
        val = {'CBB','AR1B','AR1G'};
    case 'dictInitMethod'
        val = {'GivenMatrix';'DataElements'};
    case 'sparseCodingMethod'
        val = {'OMP';'Thresholding'};
    case 'preserveAtomsDict'
        val = [0;1];
    case 'rerunStep1'
        val = [0;1];
    case 'rerunStep2'
        val = [0;1];
    case 'rerunStep3'
        val = [0;1];
    case 'rerunStep4'
        val = [0;1];
    otherwise
        error('No list of valid arguments for ''%s'', type help ''help %s'' for more info.',argName,mfilename)
end
end


function val = defaultVal(argName)
switch argName
    case 'resamplingMethod'
        val = 'CBB';
    case 'blockWindowLength'
        val = '10 1 30';
    case 'dictInitMethod'
        val = 'GivenMatrix';
    case 'sparseCodingMethod'
        val = 'Thresholding';
    case 'preserveAtomsDict'
        val = '1';
    case 'rerunStep1'
        val = '0';
    case 'rerunStep2'
        val = '0';
    case 'rerunStep3'
        val = '0';
    case 'rerunStep4'
        val = '0';
    case 'sparsityLevel'
        val = '';
    case 'networkScale'
        val = '';
    case 'errorFlag'
        val = '0';
    case 'displayProgress'
        val = '0';
    case 'session'
        val = '1';
    case 'outDir'
        val = ['.',filesep,'spark-results-',datestr(clock(),'yy.mm.dd-HH.MM'),filesep];
    case 'outSize'
        val = 'quality_control';
    case 'test'
        val = '0';
    otherwise
        error('No default argument for ''%s'', type help ''help %s'' for more info.',argName,mfilename)
end
end


function f = checkValFunc(argName)
switch argName
    case 'fmriData'
%         f = @(x) cellfun(@(y) validateattributes(y,{'char'},{'nonempty'}),strsplit(x,' '));
        f = @(x) all(cellfun(@(y) checkNonEmptyString(y),strsplit(x,' ')));
    case 'greyMatterMask'
%         f = @(x) validateattributes(x,{'char'},{'nonempty'});
        f = @(x) checkNonEmptyString(x);
    case 'numberOfResamplings'
        f = @(x) checkIntGreaterThan(x,2);
    case 'networkScales'
        f = @(x) checkRegSpacedVector(x);
    case 'numberOfIterations'
        f = @(x) checkIntGreaterThan(x,2);
    case 'pValue'
%         f = @(x) validateattributes(str2double(x),{'double'},{'>=',0,'<=',1});
        f = @(x) isfloat(str2double(x)) && (str2double(x) >= 0) && (str2double(x) <= 1);
    case 'resamplingMethod'
        f = @(x) checkString(x,validVal(argName));
    case 'blockWindowLength'
        f = @(x) checkRegSpacedVector(x);
    case 'dictInitMethod'
        f = @(x) checkString(x,validVal(argName));
    case 'sparseCodingMethod'
        f = @(x) checkString(x,validVal(argName));
    case 'preserveAtomsDict'
        f = @(x) checkPositiveInteger(x,validVal(argName));
    case 'rerunStep1'
        f = @(x) checkPositiveInteger(x,validVal(argName));
    case 'rerunStep2'
        f = @(x) checkPositiveInteger(x,validVal(argName));
    case 'rerunStep3'
        f = @(x) checkPositiveInteger(x,validVal(argName));
    case 'rerunStep4'
        f = @(x) checkPositiveInteger(x,validVal(argName));
    case 'sparsityLevel'
        f = @(x) true;
    case 'networkScale'
        f = @(x) true;
    case 'errorFlag'
        f = @(x) true;
    case 'displayProgress'
        f = @(x) true;
    case 'session'
        f = @(x) true;
    case 'outDir'
        f = @(x) true;
    case 'outSize'
        f = @(x) true;
    case 'test'
        f = @(x) true;
    otherwise
        error('No validation function for ''%s'', type help ''help %s'' for more info.',argName,mfilename)
end
end


function TF = checkNonEmptyString(str)
if (~ischar(str) || isempty(str))
    error('Expected input to be non-empty string:\n\n%s',str)
else
    TF = true;
end
end


function TF = checkString(str,validStrings)
if ~any(strcmp(str,validStrings))
    tmpStr = [];
    for i = 1:length(validStrings)
        tmpStr = [tmpStr,validStrings{i},', '];%#ok
    end
    tmpStr = tmpStr(1:(end-2));
    error('The input did not match any of these values:\n\n%s',tmpStr)
else
    TF = true;
end
end


function TF = checkIntGreaterThan(str,val)
matchedStr = regexp(str,'^\d+$','match');
if isempty(matchedStr)||~strcmp(str,matchedStr)
    error('The input did not match the expected format: ''positiveIntegerValue''.')
end
% validateattributes(str2double(str),{'double'},{'finite','nonnan'});
if (~isfloat(str2double(str)) || ~isfinite(str2double(str)))
    error('Expected input to be a finite number:\n\n%s',str)
elseif (str2double(str)<val)
    error(['The input did not match the condition: ''>=',int2str(val),''''])
else
    TF = true;
end
end


function TF = checkPositiveInteger(str,varargin)
matchedStr = regexp(str,'^\d+$','match');
if isempty(matchedStr)||~strcmp(str,matchedStr)
    error('The input did not match the expected format: ''positiveIntegerValue''.')
end
% validateattributes(str2double(str),{'double'},{'finite','nonnan'});
if (~isfloat(str2double(str)) || ~isfinite(str2double(str)))
    error('Expected input to be a finite number:\n\n%s',str)
elseif (~isempty(varargin)&&~ismember(str2double(str),varargin{1}(:)))
    tmpStr = [];
    for i = 1:length(varargin{1})
        tmpStr = [tmpStr,int2str(varargin{1}(i)),', '];%#ok
    end
    tmpStr = tmpStr(1:(end-2));
    error('The input did not match any of these values:\n\n%s',tmpStr)
else
    TF = true;
end
end


function TF = checkRegSpacedVector(str)
matchedStr = regexp(str,'^\d+ \d+ \d+$','match');
if isempty(matchedStr)||~strcmp(str,matchedStr)
    error('The inputs did not all match the expected format: ''positiveIntegerValue'':\n\n%s',str)
end
n = str2RegSpacedVector(str);
if isempty(n(1):n(2):n(3))
    error('A regularly-spaced vector cannot be generated with the given values.')
else
    TF = true;
end
end


function x = str2RegSpacedVector(str)
x = cellfun(@(x) str2double(x),strsplit(str,' '));
end