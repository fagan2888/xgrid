%
% __   ____ _ _ __(_) __| |
% \ \/ / _` | '__| |/ _` |
%  >  < (_| | |  | | (_| |
% /_/\_\__, |_|  |_|\__,_|
%      |___/
%
% ### simulate
%
%
% **Syntax**
%
% ```matlab
% 	p.simulate()
% ```
%
% **Description**
%
% Starts the simulation on all clusters, both local and remote.
% This function should be called by the user once a simulation function is configured
% and the jobs have been batched.
%
% See Also:
% xgrid.batchify
% xgrid.cleanup


function simulate(self)

	assert(~isempty(self.sim_func),'No sim function configured, refusing to start')


	% make sure there exists a linked binary
	if isempty(self.x.linked_binary)
		self.x.skip_hash_check = false;
		self.x.transpile;
		self.x.compile;
		self.x.skip_hash_check = true;
	end

	for i = 1:length(self.clusters)
		if strcmp(self.clusters(i).Name,'local')

			self.sim_start_time = now;

			corelib.verb(self.verbosity, 'INFO', 'Starting workers...')

			for j = 1:self.num_workers
				self.startWorker();
				corelib.textbar(j, self.num_workers)
			end


		else
			% it's a remote cluster. ask the remote (nicely)
			% to start the simulations

			command = ['simulate();'];
			self.tellRemote(self.clusters(i).Name,command);


		end
	end



end % end simulate
