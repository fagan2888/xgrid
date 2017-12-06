%                          _                                       
%                         | |                                      
%     _ __  ___ _   _  ___| |__   ___  _ __   ___  _ __ ___  _ __  
%    | '_ \/ __| | | |/ __| '_ \ / _ \| '_ \ / _ \| '_ ` _ \| '_ \ 
%    | |_) \__ \ |_| | (__| | | | (_) | |_) | (_) | | | | | | |_) |
%    | .__/|___/\__, |\___|_| |_|\___/| .__/ \___/|_| |_| |_| .__/ 
%    | |         __/ |                | |                   | |    
%    |_|        |___/                 |_|                   |_|
% 

function stop(self)
	if ~isempty(self.workers)
		disp('Stopping all workers...')
		try
			cancel(self.workers)
		catch
		end
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