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

function simulate(self)

	assert(~isempty(self.sim_func),'No sim function configured, refusing to start')
    

    stagger_time = 1;


	% make sure there exists a linked binary
	if isempty(self.x.linked_binary)
		self.x.skip_hash_check = false;
		self.x.transpile;
		self.x.compile;
		self.x.skip_hash_check = true;
	end

	for i = 1:length(self.clusters)
		if strcmp(self.clusters(i).Name,'local')

			% check that every job has the correct hash
			% disp('Checking that every job has the same hash...')
			% do_folder = [self.psychopomp_folder filesep 'do' filesep ];
			% allfiles = dir([do_folder '*.ppp']);
			% for j = 1:length(allfiles)
			% 	textbar(j,length(allfiles))
			% 	m = matfile(joinPath(allfiles(j).folder,allfiles(j).name));
			% 	assert(strcmp(self.xolotl_hash,m.xhash),'At least one job didnt match the hash of the currently configured Xolotl object')
			% end

			self.sim_start_time = now;

			if self.verbosity
				disp('Starting workers...')
			end

			for j = self.num_workers:-1:1
				F(j) = parfeval(@self.simulate_core,0,i,Inf);
				textbar(self.num_workers - j + 1,self.num_workers)
				pause(stagger_time)
			end
			self.workers = F;

		else
			% it's a remote cluster. ask the remote (nicely)
			% to start the simulations

			command = ['simulate();'];
			self.tellRemote(self.clusters(i).Name,command);


		end
	end



end % end simulate 
