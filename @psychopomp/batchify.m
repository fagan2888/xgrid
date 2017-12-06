%                          _                                       
%                         | |                                      
%     _ __  ___ _   _  ___| |__   ___  _ __   ___  _ __ ___  _ __  
%    | '_ \/ __| | | |/ __| '_ \ / _ \| '_ \ / _ \| '_ ` _ \| '_ \ 
%    | |_) \__ \ |_| | (__| | | | (_) | |_) | (_) | | | | | | |_) |
%    | .__/|___/\__, |\___|_| |_|\___/| .__/ \___/|_| |_| |_| .__/ 
%    | |         __/ |                | |                   | |    
%    |_|        |___/                 |_|                   |_|
% 
function batchify(self,params,param_names)
	assert(~isempty(self.x),'First configure the xolotl object')
	assert(~isempty(self.clusters),'At least one cluster has to be connected')
	n_sims = size(params,2);
	self.n_sims = n_sims;
	assert(size(params,1) == length(param_names),'Param names does not match parameter dimensions')
	xhash = self.xolotl_hash;
	total_workers = sum([self.clusters.nthreads]);
	n_jobs = total_workers*self.n_batches;
	job_size = ceil(n_sims/n_jobs);
	idx = 1; c = 1;


	while idx <= n_sims
		z = idx+job_size-1;
		if z > n_sims
			z = n_sims;
		end
		param_idx = 1:n_sims;
		param_idx = param_idx(idx:z);
		this_params = params(:,idx:z);
		save([self.psychopomp_folder oss 'do' oss 'job_' oval(c) '.ppp'],'this_params','param_names','xhash','param_idx');
		idx = z + 1; c = c + 1;
	end

	% now copy some of these files onto the remotes, if they exist
	do_folder = [self.psychopomp_folder oss 'do' oss ];
	allfiles = dir([do_folder '*.ppp']);
	n_total_jobs = length(allfiles);

	job_distribution = ceil(([self.clusters.nthreads]./total_workers)*n_total_jobs);

	% move jobs onto clusters
	for i = 1:length(self.clusters)
		if strcmp(self.clusters(i).Name,'local')
			continue
		end
		disp(['Copying job files onto ' self.clusters(i).Name])
		for j = 1:job_distribution(i)
			textbar(j,job_distribution(i))
			allfiles = dir([do_folder '*.ppp']);
			if length(allfiles) == 0 
				continue
			end
			% copy a job file over

			[e,o] = system(['scp ' do_folder allfiles(1).name ' ' self.clusters(i).Name ':~/.psychopomp/do/']);

			assert(e == 0,'Error copying job file to remote cluster')
			% delete it from the local
			delete([do_folder allfiles(1).name])
		end
	end

end % end batchify