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

function printLog(self)

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
	plog.worker_state{i} = self.workers(i).State;
end
plog.last_updated = now;

save(joinPath(self.psychopomp_folder,'log.mat'),'plog')
