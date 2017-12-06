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
% This is the daemon version of psychopomp
function psychopompd(self,~,~)

	% delete old log files if any 
	if exist(joinPath(self.psychopomp_folder,'log.mat'),'file')
		delete(joinPath(self.psychopomp_folder,'log.mat'))
	end

	% start logging
	plog.host_name = strtrim(getComputerName);
	plog.nthreads = 2*feature('numcores');
	plog.xolotl_hash = self.xolotl_hash;

	[plog.n_do, plog.n_doing, plog.n_done] = self.getJobStatus;
	for i = 1:length(self.workers)
		plog.worker_diary{i} = self.workers(i).Diary;
	end
	plog.last_updated = now;

	save(joinPath(self.psychopomp_folder,'log.mat'),'plog')

	% run any commands specified by master
	try
		if exist('~/.psychopomp/com.mat')
			load('~/.psychopomp/com.mat')
			delete('~/.psychopomp/com.mat')

			disp(['Running command ' command])
			eval(['self.' command])
			disp('Command completely successfully!')
		end
	catch err
		disp(err)
	end


	disp(['psychopompd :: Updating log on ' datestr(now)])
end
