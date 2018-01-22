%                          _                                       
%                         | |                                      
%     _ __  ___ _   _  ___| |__   ___  _ __   ___  _ __ ___  _ __  
%    | '_ \/ __| | | |/ __| '_ \ / _ \| '_ \ / _ \| '_ ` _ \| '_ \ 
%    | |_) \__ \ |_| | (__| | | | (_) | |_) | (_) | | | | | | |_) |
%    | .__/|___/\__, |\___|_| |_|\___/| .__/ \___/|_| |_| |_| .__/ 
%    | |         __/ |                | |                   | |    
%    |_|        |___/                 |_|                   |_|
%  

function plog = getRemoteState(self,idx)

	self.tellRemote(self.clusters(idx).Name,'printLog;');

	[e,o] = system(['scp ' self.clusters(idx).Name ':~/.psych/log.mat ' self.psychopomp_folder '/' self.clusters(idx).Name '.log.mat']);

	% load the log 
	load([self.psychopomp_folder '/' self.clusters(idx).Name '.log.mat']);
end
