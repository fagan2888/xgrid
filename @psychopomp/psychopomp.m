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

		clusters
	end % end props

	properties (SetAccess = protected)
		allowed_param_names
		num_workers
		workers
		n_sims
		xolotl_hash
		current_pool@parallel.Pool
		daemon_handle
	end

	properties (Access = protected)
		psychopomp_folder 
		sim_start_time
	end


	methods (Access = protected)
        function displayScalarObject(self)
            url = 'https://github.com/sg-s/psychopomp/';
            fprintf(['\b\b\b\b\b\b<a href="' url '">psychopomp</a> '])
            if length(self.clusters) == 0
            	 fprintf('is not connected to any cluster!')
            else
            	for i = 1:length(self.clusters)
            		fprintf(['\nis using ' oval(self.clusters(i).nthreads) ' threads on ' self.clusters(i).Name]);
            	end
            end
            
            if isempty(self.x)
            	fprintf(['\n\nXolotl has not been configured \n \n'])
            else
            	fprintf(['\n\nXolotl has been configured, with hash: ' self.xolotl_hash '\n \n'])
            end
			
			fprintf('Cluster                   Queued     Running   Done\n')
			fprintf('--------------------------------------------------\n')
			for i = 1:length(self.clusters)
				if strcmp(self.clusters(i).Name,'local')
					[n_do, n_doing, n_done] = getJobStatus(self);
					cluster_name_disp = ['local' repmat(' ',1,20)];
				else
					plog = self.getRemoteState(i);
					cluster_name_disp = self.clusters(i).Name;
					if length(cluster_name_disp) < 25
						cluster_name_disp = [cluster_name_disp repmat(' ',1,25-length(cluster_name_disp))];
					elseif length(cluster_name_disp) > 25
						cluster_name_disp = cluster_name_disp(1:25);
					end
					n_do = plog.n_do; n_doing = plog.n_doing; n_done = plog.n_done;
				end
				fprintf([cluster_name_disp  ' ' oval(n_do) '            ' oval(n_doing) '         ' oval(n_done) '\n'])

			end




            % if isempty(self.sim_start_time)
            % 	fprintf('Simulations have not been started. \n')
            % else
            % 	fprintf(['Simulations started on      : ' datestr(self.sim_start_time) '\n'])
            % 	if length(running_jobs) > 0
            % 		elapsed_time = now - self.sim_start_time;
            % 		if length(done_jobs) > 0
            % 			ldj = length(done_jobs);
            % 			rem_jobs = total_jobs - ldj;
            % 			time_per_job = elapsed_time/ldj;
            % 			time_rem = time_per_job*rem_jobs;
            % 			when_done = time_rem + now;
            % 			fprintf(['Estimated time of completion: ' datestr(when_done) '\n'])

            % 			n_sims_per_job = self.n_sims/(self.n_batches*self.num_workers);
            % 			T = (n_sims_per_job*self.x.t_end)/1000; % s
            % 			dv = datevec(time_per_job);
            % 			elapsed_sec = dv(end) + dv(end-1)*60 + dv(end-2)*60*60 + dv(end-3)*60*60*24;
            % 		end
            % 	end
            % end

            % display the state of all the workers
            if isempty(self.workers)
            	fprintf('\nNo parallel workers connected.\n')
            else
            	fprintf('\nThread ID    State        Error         Output\n')
            	fprintf('----------------------------------------------\n')
            	for i = 1:length(self.workers)
            		s = [];
            		s = [s mat2str(self.workers(i).ID) '           ' ];
            		if strcmp(self.workers(i).State,'running')
            			s = [s 'running...    '];
            		else
            			s = [s 'DONE          '];
            		end
            		if length(self.workers(i).Error) == 0
            			s = [s '          '];
            		else
            			s = [s 'ERROR!    '];
            		end

            		d = self.workers(i).Diary;
            		try
	            		d = splitlines(d);
	            		if isempty(d{end})
	            			d(end) = [];
	            		end
            			s = [s d{end}];
            		catch
            		end
            		s = [s '\n'];
            		fprintf(s)
            	end
            end
        end % end displayScalarObject
   end % end protected methods

	methods



		function self = psychopomp(varargin)
			% get the current pool, and start one if needed
			self.current_pool = gcp;
			self.num_workers = self.current_pool.NumWorkers;
			if ispc
				self.psychopomp_folder = fileparts(which(mfilename));
			else
				self.psychopomp_folder = '~/.psychopomp';
				if exist(self.psychopomp_folder,'file') == 7
				else
					mkdir(self.psychopomp_folder)
				end
			end

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

			if nargin == 0
				self.addCluster('local')
			end

			for i = 1:length(varargin)
				self.addCluster(varargin{i});
			end

		end

		function self = set.sim_func(self,value)
			self.sim_func = value;

			% if there are remotes, copy this function onto the remotes, and ask them to configure it 
			for i = 1:length(self.clusters)
				if strcmp(self.clusters(i).Name,'local')
					continue
				end

				% copy the sim function onto the remote
				[e,o] = system(['scp "' which(func2str(value)) '" ' self.clusters(i).Name ':~/.psychopomp/']);
				assert(e == 0, 'Error copying sim function onto remote')

				command = ['sim_func = @' func2str(value) ';'];
				save('~/.psychopomp/com.mat','command')
				disp('Copying command object onto remote...')
				[e,o] = system(['scp ~/.psychopomp/com.mat ' self.clusters(i).Name ':~/.psychopomp/']);
				assert(e == 0,'Error copying command onto remote')
			end
		end


		function daemonize(self)
			% to do -- check if daemon is already running
			%self.daemon_handle = parfeval(@self.psychopompd,0);

			% add the ~/.psychopompd folder to the path so that sim functions can be resolved 
			addpath('~/.psychopomp')

			self.daemon_handle = timer('TimerFcn',@self.psychopompd,'ExecutionMode','fixedDelay','TasksToExecute',Inf,'Period',5);
			start(self.daemon_handle);
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

			% also configure xolotl objects of all remotes
			for i = 1:length(self.clusters)
				if strcmp(self.clusters(i).Name,'local')
					continue
				end
				command = 'x = value;';
				save('~/.psychopomp/com.mat','command','value')
				disp('Copying xolotl object onto remote...')
				[e,o] = system(['scp ~/.psychopomp/com.mat ' self.clusters(i).Name ':~/.psychopomp/']);
				assert(e == 0,'Error copying command onto remote')
			end
			
		end % end set xolotl object

		% function self = set.sim_func(self,value)
		% 	% make sure it exists 
		% 	% TO DO
		% end % end set sim_func


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



