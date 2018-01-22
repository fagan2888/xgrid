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
            if isempty(self.clusters) 
            	 fprintf('is not connected to any cluster!')
            else
            	for i = 1:length(self.clusters)
            		fprintf(['\nis using ' oval(self.clusters(i).nthreads) ' threads on ' self.clusters(i).Name]);
            	end
            end

			fprintf('\n\nCluster      Status  Queued  Running  Done  xolotl#\n')
			fprintf('---------------------------------------------------------------\n')
			for i = length(self.clusters):-1:1
				if strcmp(self.clusters(i).Name,'local')
					[n_do, n_doing, n_done] = getJobStatus(self);
					cluster_name_disp = flstring('local',12);
					xhash = self.xolotl_hash;
					status = '';
				else
					plog(i) = self.getRemoteState(i);

					cluster_name_disp = self.clusters(i).Name;
					cluster_name_disp = flstring(cluster_name_disp,12);
					n_do = plog(i).n_do; n_doing = plog(i).n_doing; n_done = plog(i).n_done;
					xhash = plog(i).xolotl_hash;
					% check that the log isn't stale
					if etime(datevec(now),datevec(plog.last_updated)) < 10
						status = 'OK';
					else
						status = 'DEAD';
					end

					% copy worker info onto local structure
					self.clusters(i).workers = [];
					if isfield(plog(i),'worker_diary')
						for j = 1:length(plog(i).worker_diary)
							self.clusters(i).workers(j).Diary = plog(i).worker_diary{j};
							self.clusters(i).workers(j).State = plog(i).worker_state{j};
						end
					end
				end
				if isempty(xhash) 
					xhash = 'n/a         ';
				end
				fprintf([cluster_name_disp  ' ' flstring(status,7) ' ' flstring(oval(n_do),7) ' ' flstring(oval(n_doing),8) ' ' flstring(oval(n_done),5) ' ' xhash(1:7) '\n'])

			end

            % display the state of all the workers, on all nodes

            fprintf('\n\nCluster      Worker  State      Output\n')
			fprintf('---------------------------------------------------------------\n')

            for i = 1:length(self.clusters)
            	if strcmp(self.clusters(i).Name,'local')
            		for j = 1:length(self.workers)
            			cluster_name = flstring('local',12);
            			wid = flstring(oval(j),7);
            			ws = flstring(self.workers(j).State,10);
            			wd = self.workers(j).Diary;
            			if ~isempty(wd)
	            			try
		            			wd = splitlines(wd);
			            		if isempty(wd{end})
			            			wd(end) = [];
			            		end

	            				wd = flstring(wd{end},20);
	            			catch
	            				wd = flstring('error parsing diary',20);
	            			end
	            		else
	            			wd = flstring('',20);
	            		end
            			fprintf([cluster_name  ' ' wid ' ' ws ' ' wd  '\n'])
            		end
            	else
            		if isfield(plog,'worker_diary')
	            		for j = 1:length(plog(i).worker_diary)
	            			cluster_name = flstring(self.clusters(i).Name,12);
	            			wid = flstring(oval(j),7);
	            			ws = flstring(plog(i).worker_state{j},10);
	            			wd = plog(i).worker_diary{j};
	            			if ~isempty(wd)
		            			try
			            			wd = splitlines(wd);
				            		if isempty(wd{end})
				            			wd(end) = [];
				            		end

		            				wd = flstring(wd{end},20);
		            			catch

		            				wd = flstring('error parsing diary',20);
		            			end
		            		else
		            			wd = flstring('',20);
		            		end
	            			fprintf([cluster_name  ' ' wid ' ' ws ' ' wd  '\n'])
	            		end
	            	end
            	end
            end

        end % end displayScalarObject
   end % end protected methods

	methods



		function self = psychopomp(varargin)
			% get the current pool, and start one if needed

			if ispc
				self.psychopomp_folder = fileparts(which(mfilename));
			else
				self.psychopomp_folder = '~/.psych';
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
				[e,~] = system(['scp "' which(func2str(value)) '" ' self.clusters(i).Name ':~/.psych/']);
				assert(e == 0, 'Error copying sim function onto remote')

				command = ['sim_func = @' func2str(value) ';'];
				self.tellRemote(self.clusters(i).Name,command);
			end
		end


		function daemonize(self)
			if exist('~/.psych/daemon_running','file')
				error('Daemon is already running. Refusing to start. To force start, delete "~/.psych/daemon_running"')
			end

			% add the ~/.psych folder to the path so that sim functions can be resolved
			addpath('~/.psych')

			system('touch ~/.psych/daemon_running')
			pause(3)

			self.daemon_handle = timer('TimerFcn',@self.psychopompd,'ExecutionMode','fixedDelay','TasksToExecute',Inf,'Period',.5);
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


			self.x.skip_hash_check = false;
			self.xolotl_hash = self.x.hash;
			self.x.skip_hash_check = true;

			% also configure xolotl objects of all remotes
			for i = 1:length(self.clusters)
				if strcmp(self.clusters(i).Name,'local')
					continue
				end
				command = 'x = value; self.x.rebase; self.x.transpile; self.x.compile;';
				self.tellRemote(self.clusters(i).Name,command,value);
			end

		end % end set xolotl object



	end % end methods

	methods (Static)

		% this static method is to go from a voltage and calcium trace to burst metrics
		% assuming you have the calcium trace (true in simulations)
		[burst_metrics, spike_times, Ca_peaks, Ca_mins] = findBurstMetrics(V,Ca,varargin)
		spiketimes = findNSpikes(V,n_spikes,on_off_thresh)

		[neuron_metrics, phase_differences] = spiketimes2stats(varargin);




	end % end static methods

end % end classdef
