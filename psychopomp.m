% psychopomp
% a MATLAB class to run parameter scans of neuron models
% runs using xolotl (https://github.com/sg-s/xolotl)
% needs the parallel computing toolbox 

classdef psychopomp < handle & matlab.mixin.CustomDisplay

	properties
		current_pool@parallel.Pool
		x@xolotl
		post_sim_func
		n_func_outputs
		n_batches = 10; % per worker
		data_size
	end % end props

	properties (SetAccess = protected)
		allowed_param_names
		num_workers
		workers
		n_sims
	end

	properties (Access = protected)
		psychopomp_folder 
		sim_start_time
	end


	methods (Access = protected)
        function displayScalarObject(self)
            url = 'https://gitlab.com/psychopomp/';
            nc = feature('numcores');
            fprintf(['<a href="' url '">psychopomp</a> is using ' oval(self.num_workers) '/' oval(2*nc) ' threads on ' getComputerName '\n']);
            if isempty(self.x)
            	fprintf(['Xolotl has not been configured \n \n'])
            else
            	fprintf(['Xolotl has been configured, with hash: ' self.x.hash '\n \n'])
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
            	fprintf(['Simulations started on      :' datestr(self.sim_start_time) '\n'])
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

			% remove all .ppp files
			allfiles = dir([doing_folder '*.ppp']);
			for i = 1:length(allfiles)
				this_job = allfiles(i).name;
				movefile([doing_folder this_job],[do_folder this_job])
			end


		end

		function self = set.n_func_outputs(self,value)
			assert(length(value) == 1, 'n_func_outputs should be a integer')
			assert(length(value) > 0, 'n_func_outputs should be > 0')
			self.n_func_outputs = value;
		end % end set n_func_outputs 

		function batchify(self,params,param_names)
			assert(~isempty(self.x),'First configure the xolotl object')
			n_sims = size(params,2);
			self.n_sims = n_sims;
			assert(size(params,1) == length(param_names),'Param names does not match parameter dimensions')
			xhash = self.x.hash;
			n_jobs = self.num_workers*self.n_batches;
			job_size = ceil(n_sims/n_jobs);
			idx = 1; c = 1;
			while idx < n_sims
				z = idx+job_size;
				if z > n_sims
					z = n_sims;
				end
				this_params = params(:,idx:z);
				save([self.psychopomp_folder oss 'do' oss 'job_' oval(c) '.ppp'],'this_params','param_names','xhash');
				idx = z + 1; c = c + 1;
			end
		end

		function self = set.x(self,value)
			assert(length(value)==1,'Only one xololt object can be linked')
			self.x = value;
			% determine the parameter names we expect 
			n = getCompartmentNames(self.x);
			for i = 1:length(n)
				eval([n{i} ' = self.x.(n{i});']);
				eval( ['[~,these_names] = struct2vec(' n{i} ');']);
				self.allowed_param_names = [self.allowed_param_names; these_names];
			end
		end % end set xolotl object

		function simulate(self)

			% check that every job has the correct hash
			do_folder = [self.psychopomp_folder oss 'do' oss ];
			allfiles = dir([do_folder '*.ppp']);
			for i = 1:length(allfiles)
				m = matfile(joinPath(allfiles(i).folder,allfiles(i).name));
				assert(strcmp(self.x.hash,m.xhash),'At least one job didnt match the hash of the currently configured Xolotl object')
			end


			% first run one sim, and time it 
			tic; self.x.integrate; self.x.integrate; t = toc;
			t = t/2;
			job_time = ceil(self.n_sims/(self.num_workers*self.n_batches))*t;
			stagger_time = job_time/(self.num_workers+1);


			% report estimated completion time
			t_end = oval((length(allfiles)*job_time)/self.num_workers);
			disp(['Estimated running time is ' t_end 's.'])

			self.sim_start_time = now;

			disp('Starting workers...')

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

		end

		function simulate_core(self,idx,n_runs)

			while n_runs > 0

				% grab a job file and move it to doing 
				do_folder = [self.psychopomp_folder oss 'do' oss ];
				doing_folder = [self.psychopomp_folder oss 'doing' oss ];
				done_folder = [self.psychopomp_folder oss 'done' oss ];
				free_jobs = dir([ do_folder '*.ppp']);

				if length(free_jobs) == 0
					self.sim_stop_time = now;
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

				% make data placeholders
				for i = 1:length(self.data_size)
					data{i} = NaN(self.data_size(i),size(this_params,2));
				end
				
				for i = 1:size(this_params,2)
					% update params
					for j = 1:length(param_names)
						eval(['self.x.' strrep(param_names{j},'_','.') ' = this_params(' mat2str(j),',' mat2str(i) ');'])
					end

					% run the model
					try
						[V,Ca] = self.x.integrate;

						% call the post-stim functions
						for j = 1:length(self.post_sim_func)
							data{j}(:,i) = self.post_sim_func{j}(V,Ca);
						end 
					catch
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
		function spiketimes = findSpikes(V)
			[ons, offs] = computeOnsOffs(V>0);
			spiketimes = NaN*ons;
			for i = 1:length(ons)
				[~,idx] = max(V(ons(i):offs(i)));
				spiketimes(i) = ons(i) + idx;
			end
		end

		 
	end % end static methods

end % end classdef 



