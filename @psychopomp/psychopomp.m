% psychopomp
%                          _                                       
%                         | |                                      
%     _ __  ___ _   _  ___| |__   ___  _ __   ___  _ __ ___  _ __  
%    | '_ \/ __| | | |/ __| '_ \ / _ \| '_ \ / _ \| '_ ` _ \| '_ \ 
%    | |_) \__ \ |_| | (__| | | | (_) | |_) | (_) | | | | | | |_) |
%    | .__/|___/\__, |\___|_| |_|\___/| .__/ \___/|_| |_| |_| .__/ 
%    | |         __/ |                | |                   | |    
%    |_|        |___/                 |_|                   |_|
%     
% a MATLAB class to run parameter scans of neuron models
% runs using xolotl (https://github.com/sg-s/xolotl)
% needs the parallel computing toolbox 

classdef psychopomp < handle & matlab.mixin.CustomDisplay

	properties
		x@xolotl
		sim_func@function_handle
		n_func_outputs % how many outputs will the simulation function generate? 
		use_parallel = true
		n_batches = 10 % per worker
		verbosity = 1;
	end % end props

	properties (SetAccess = protected)
		allowed_param_names
		num_workers
		workers
		n_sims
		xolotl_hash
		current_pool@parallel.Pool
	end

	properties (Access = protected)
		psychopomp_folder 
		sim_start_time
	end


	methods (Access = protected)
        function displayScalarObject(self)
            url = 'https://github.com/sg-s/psychopomp/';
            nc = feature('numcores');
            fprintf(['<a href="' url '">psychopomp</a> is using ' oval(self.num_workers) '/' oval(2*nc) ' threads on ' getComputerName '\n']);
            if isempty(self.x)
            	fprintf(['Xolotl has not been configured \n \n'])
            else
            	fprintf(['Xolotl has been configured, with hash: ' self.xolotl_hash '\n \n'])
            end
			do_folder = [self.psychopomp_folder oss 'do' oss ];
			doing_folder = [self.psychopomp_folder oss 'doing' oss ];
			done_folder = [self.psychopomp_folder oss 'done' oss ];
			free_jobs = dir([ do_folder '*.ppp']);
			running_jobs = dir([ doing_folder '*.ppp']);
			done_jobs = dir([ done_folder '*.ppp']);

			total_jobs = length(done_jobs) + length(running_jobs) + length(free_jobs);

			if  total_jobs == 0
            	fprintf('No simulations queued')
            else
            	fprintf('Simulation progress:    ') 
            	fprintf('\n--------------------\n')
            	fprintf(['Queued :  ' oval(length(free_jobs)) '\n'])
            	fprintf(['Running:  ' oval(length(running_jobs)) '\n'])
            	fprintf(['Done   :  ' oval(length(done_jobs)) '\n'])

            end

            if isempty(self.sim_start_time)
            	fprintf('Simulations have not been started. \n')
            else
            	fprintf(['Simulations started on      : ' datestr(self.sim_start_time) '\n'])
            	if length(running_jobs) > 0
            		elapsed_time = now - self.sim_start_time;
            		if length(done_jobs) > 0
            			ldj = length(done_jobs);
            			rem_jobs = total_jobs - ldj;
            			time_per_job = elapsed_time/ldj;
            			time_rem = time_per_job*rem_jobs;
            			when_done = time_rem + now;
            			fprintf(['Estimated time of completion: ' datestr(when_done) '\n'])

            			n_sims_per_job = self.n_sims/(self.n_batches*self.num_workers);
            			T = (n_sims_per_job*self.x.t_end)/1000; % s
            			dv = datevec(time_per_job);
            			elapsed_sec = dv(end) + dv(end-1)*60 + dv(end-2)*60*60 + dv(end-3)*60*60*24;
            			speed = T/elapsed_sec;
            			fprintf(['Running @ ' oval(speed) 'X\n \n'])
            		end
            	end
            end
        end % end displayScalarObject
   end % end protected methods

	methods

		function self = psychopomp()
			% get the current pool, and start one if needed
			self.current_pool = gcp;
			self.num_workers = self.current_pool.NumWorkers;
			self.psychopomp_folder = fileparts(which(mfilename));

			% create do, doing, done folders if they don't exist
			if exist(joinPath(self.psychopomp_folder,'do'),'file') == 7
			else
				mkdir(joinPath(self.psychopomp_folder,'do'))
			end
			if exist(joinPath(self.psychopomp_folder,'doing'),'file') == 7
			else
				mkdir(joinPath(self.psychopomp_folder,'doing'))
			end
			if exist(joinPath(self.psychopomp_folder,'done'),'file') == 7
			else
				mkdir(joinPath(self.psychopomp_folder,'done'))
			end

		end

		function stop(self)
			if ~isempty(self.workers)
				disp('Stopping all workers...')
				cancel(self.workers)
			end

			% move doing jobs back to queue
			do_folder = [self.psychopomp_folder oss 'do' oss ];
			doing_folder = [self.psychopomp_folder oss 'doing' oss ];

			allfiles = dir([doing_folder '*.ppp']);
			for i = 1:length(allfiles)
				this_job = allfiles(i).name;
				movefile([doing_folder this_job],[do_folder this_job])
			end


		end

		function batchify(self,params,param_names)
			assert(~isempty(self.x),'First configure the xolotl object')
			n_sims = size(params,2);
			self.n_sims = n_sims;
			assert(size(params,1) == length(param_names),'Param names does not match parameter dimensions')
			xhash = self.xolotl_hash;
			n_jobs = self.num_workers*self.n_batches;
			job_size = ceil(n_sims/n_jobs);
			idx = 1; c = 1;

			while idx < n_sims
				z = idx+job_size;
				if z > n_sims
					z = n_sims;
				end
				param_idx = 1:n_sims;
				param_idx = param_idx(idx:z);
				this_params = params(:,idx:z);
				save([self.psychopomp_folder oss 'do' oss 'job_' oval(c) '.ppp'],'this_params','param_names','xhash','param_idx');
				idx = z + 1; c = c + 1;
			end
		end

		function self = set.x(self,value)
			assert(length(value)==1,'Only one xololt object can be linked')
			self.x = value;
			% determine the parameter names we expect 
			n = self.x.compartment_names;
			for i = 1:length(n)
				eval([n{i} ' = self.x.(n{i});']);
				eval( ['[~,these_names] = struct2vec(' n{i} ');']);
				self.allowed_param_names = [self.allowed_param_names; these_names];
			end
			self.x.closed_loop = false; 
			self.x.skip_hash_check = false;
			self.xolotl_hash = self.x.hash;
			self.x.skip_hash_check = true;
		end % end set xolotl object

		% function self = set.sim_func(self,value)
		% 	% make sure it exists 
		% 	% TO DO
		% end % end set sim_func


		function [all_data, all_params, all_param_idx] = gather(self)
			% make sure nothing is running
			% read all files from done/
			do_folder = [self.psychopomp_folder oss 'do' oss ];
			allfiles = dir([do_folder '*.ppp']);
			assert(length(allfiles) == 0,'At least one job is still queued')
			doing_folder = [self.psychopomp_folder oss 'doing' oss ];
			allfiles = dir([doing_folder '*.ppp']);
			assert(length(allfiles) == 0,'At least one job is still running')

			done_folder = [self.psychopomp_folder oss 'done' oss ];
			job_files =  dir([done_folder '*.ppp']);
			data_files =  dir([done_folder '*.ppp.data']);
			assert(length(job_files) == length(data_files),'# of data files does not match # of job files')

			load([done_folder data_files(1).name],'-mat');
			all_data = data;
			load([done_folder job_files(1).name],'-mat');
			all_params = this_params;
			all_param_idx = param_idx;

			for i = 2:length(data_files) % because we've already loaded the first one (see above)
				load([done_folder data_files(i).name],'-mat');
				load([done_folder job_files(i).name],'-mat');

				for j = 1:length(all_data)
					all_data{j} = [all_data{j} data{j}];
				end

				all_params = [all_params this_params];
				all_param_idx = [all_param_idx param_idx];
			end
		end

		function simulate(self, stagger_time)

			% check that every job has the correct hash
			do_folder = [self.psychopomp_folder oss 'do' oss ];
			allfiles = dir([do_folder '*.ppp']);
			for i = 1:length(allfiles)
				m = matfile(joinPath(allfiles(i).folder,allfiles(i).name));
				assert(strcmp(self.xolotl_hash,m.xhash),'At least one job didnt match the hash of the currently configured Xolotl object')
			end

			% make sure that the number of data_sizes matches the number of outputs in sim_func
			% to do


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
		
		end % end simulate 


		function cleanup(self)
			do_folder = [self.psychopomp_folder oss 'do' oss ];
			doing_folder = [self.psychopomp_folder oss 'doing' oss ];
			done_folder = [self.psychopomp_folder oss 'done' oss ];

			% remove all .ppp files
			allfiles = dir([do_folder '*.ppp']);
			for i = 1:length(allfiles)
				delete(joinPath(allfiles(i).folder,allfiles(i).name))
			end
			allfiles = dir([doing_folder '*.ppp']);
			for i = 1:length(allfiles)
				delete(joinPath(allfiles(i).folder,allfiles(i).name))
			end
			allfiles = dir([done_folder '*.ppp']);
			for i = 1:length(allfiles)
				delete(joinPath(allfiles(i).folder,allfiles(i).name))
			end

			allfiles = dir([done_folder '*.ppp.data']);
			for i = 1:length(allfiles)
				delete(joinPath(allfiles(i).folder,allfiles(i).name))
			end

		end

		function simulate_core(self,idx,n_runs)

			while n_runs > 0

				% grab a job file and move it to doing 
				do_folder = [self.psychopomp_folder oss 'do' oss ];
				doing_folder = [self.psychopomp_folder oss 'doing' oss ];
				done_folder = [self.psychopomp_folder oss 'done' oss ];
				free_jobs = dir([ do_folder '*.ppp']);

				if length(free_jobs) == 0
					return
				end

				try
					this_job = free_jobs(idx).name;
				catch
					this_job = free_jobs(1).name;
				end

				try
					movefile([do_folder this_job],[doing_folder this_job])
				catch
					pause(1)
				end

				% load the file 
				load([doing_folder this_job],'-mat')


				
				for i = 1:size(this_params,2)
					% update params

					for j = 1:length(param_names)
						eval(['self.x.' param_names{j} ' = this_params(' mat2str(j),',' mat2str(i) ');'])
					end

					% run the model
					ok = false;
					try
						[outputs{1:length(argOutNames(self.sim_func))}] = self.sim_func(self.x);
						ok = true;
					catch
						warning('Error while running simulation function.')
					end

					% map the outputs to the data structures
					if ok

						if ~exist('data','var')
							% create placeholders
							for j = 1:length(outputs)
								data{j} = NaN(size(outputs{j},1),size(this_params,2));
							end
						end

						for j = 1:length(data)
							data{j}(:,i) = outputs{j};
						end
					end

				end

				% save the data 
				save([done_folder this_job '.data'],'data')

				% move the job into the done folder
				try
					movefile([doing_folder this_job],[done_folder this_job])
				catch
				end

				n_runs = n_runs - 1;
			end
			
		end

	end % end methods 

	methods (Static)

		function syn_state = getSynapseState(V,Ca,I_clamp,cond_states,syn_states,cont_states)
			syn_state = syn_states(end,:);
		end


		function cond_state = getConductanceState(V,Ca,I_clamp,cond_states,syn_states,cont_states)
			cond_state = cond_states(end,:);
		end

		function cont_state = getControllerState(V,Ca,I_clamp,cond_states,syn_states,cont_states)
			cont_state = cont_states(end,:);
		end

		[burst_metrics, spike_times, Ca_peaks, Ca_mins] = findBurstMetrics(V,Ca,varargin)
		spiketimes = findNSpikes(V,n_spikes)


	end % end static methods

end % end classdef 



