function LAUNCH_ME_SPARK(varargin)

path_out = '';
files_in = struct();
opt = struct();

pbs_jobid = getenv('PBS_JOBID');
if isempty(pbs_jobid)
    gb_psom_tmp = varargin{2};
else
    gb_psom_tmp = [varargin{2},pbs_jobid,filesep];
end
setenv('TMP',gb_psom_tmp);

eval(varargin{1});

if ~exist(path_out,'dir')
	mkdir(path_out);
end

[pipeline,opt] = spark_pipeline_fmri_kmap(files_in,opt);%#ok
save([path_out,filesep,'pipeline',datestr(datetime('now'),'yy.mm.dd_HH.MM'),'.mat'],'-struct','pipeline','-v7.3')
save([path_out,filesep,'opt',datestr(datetime('now'),'yy.mm.dd_HH.MM'),'.mat'],'-struct','opt','-v7.3')

end


