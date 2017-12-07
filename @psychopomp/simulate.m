%                          _                                       
%                         | |                                      
%     _ __  ___ _   _  ___| |__   ___  _ __   ___  _ __ ___  _ __  
%    | '_ \/ __| | | |/ __| '_ \ / _ \| '_ \ / _ \| '_ ` _ \| '_ \ 
%    | |_) \__ \ |_| | (__| | | | (_) | |_) | (_) | | | | | | |_) |
%    | .__/|___/\__, |\___|_| |_|\___/| .__/ \___/|_| |_| |_| .__/ 
%    | |         __/ |                | |                   | |    
%    |_|        |___/                 |_|                   |_|
%  
% start the simulation on all cluster, local and remote

function simulate(self, stagger_time)

	assert(~isempty(self.sim_func),'No sim function configured, refusing to start')


	for i = 1:length(self.clusters)
		if strcmp(self.clusters(i).Name,'local')

			% check that every job has the correct hash
			do_folder = [self.psychopomp_folder oss 'do' oss ];
			allfiles = dir([do_folder '*.ppp']);
			for i = 1:length(allfiles)
				m = matfile(joinPath(allfiles(i).folder,allfiles(i).name));
				assert(strcmp(self.xolotl_hash,m.xhash),'At least one job didnt match the hash of the currently configured Xolotl object')
			end

			% first run one sim, and time it 
			if nargin < 2
				try
					tic
					self.sim_func(self.x);
					t = toc;
					t = t/2;
				catch
					error('Attempted to run simulation function and encountered an error. Check your function and make sure it works.')
				end

				job_time = ceil(self.n_sims/(self.num_workers*self.n_batches))*t;
				stagger_time = job_time/(self.num_workers+1);

			end


			self.sim_start_time = now;

			if self.verbosity
				disp('Starting workers...')
			end

			for i = 1:self.num_workers
				F(i) = parfeval(@self.simulate_core,0,i,Inf);
				textbar(i,self.num_workers)
				pause(stagger_time)
			end
			self.workers = F;

		else
			% it's a remote cluster. ask the remote (nicely)
			% to start the simulations

			if nargin < 2
				command = ['simulate;'];
			else
				command = ['simulate(' mat2str(stagger_time) ');'];
			end

			save('~/.psychopomp/com.mat','command')
			disp('Copying command object onto remote...')
			[e,o] = system(['scp ~/.psychopomp/com.mat ' self.clusters(i).Name ':~/.psychopomp/']);
			assert(e == 0,'Error copying command onto remote')


		end
	end



end % end simulate 