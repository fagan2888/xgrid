%                          _                                       
%                         | |                                      
%     _ __  ___ _   _  ___| |__   ___  _ __   ___  _ __ ___  _ __  
%    | '_ \/ __| | | |/ __| '_ \ / _ \| '_ \ / _ \| '_ ` _ \| '_ \ 
%    | |_) \__ \ |_| | (__| | | | (_) | |_) | (_) | | | | | | |_) |
%    | .__/|___/\__, |\___|_| |_|\___/| .__/ \___/|_| |_| |_| .__/ 
%    | |         __/ |                | |                   | |    
%    |_|        |___/                 |_|                   |_|
% 
%

function addCluster(self,cluster_name)
	if strcmp(cluster_name,'local')
		if isempty(self.clusters)
			self.clusters(1).Name = cluster_name;
			self.clusters(1).nthreads = self.num_workers;
		else
			idx = length(self.clusters) + 1;
			self.clusters(idx).Name = cluster_name;
			self.clusters(idx).nthreads = self.num_workers;
		end
	else

		% check if we can ping the cluster
		[e,o]=system(['ping ' cluster_name ' -c 1']);
		assert(e == 0, 'Could not contact server -- check that you have the right name and that it is reachable')

		% check we can SSH into the server, and that psychopomp is running on that server
		[e,o] = system(['scp ' cluster_name ':~/.psychopomp/log.mat ' self.psychopomp_folder '/' cluster_name '.log.mat']);
		assert(e == 0,'SERVER ERROR: Either your server isnt available, or is unresponsive to SSH, or psychopomp isnt running on it')

		% check that the log is fresh ( last 30 seconds)
		load([self.psychopomp_folder '/' cluster_name '.log.mat'])

		v = datevec(now - plog.last_updated);
		assert(etime(datevec(now), datevec(plog.last_updated)) < 30, 'Log file on remote is stale -- maybe the psychopompd is down?')

		if isempty(self.clusters)
			self.clusters(1).Name = cluster_name;
			self.clusters(1).nthreads = plog.nthreads;

		else
			idx = length(self.clusters) + 1;
			self.clusters(idx).Name = cluster_name;
			self.clusters(idx).nthreads = plog.nthreads;
		end
	end
end