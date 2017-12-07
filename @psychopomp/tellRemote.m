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
% tells the remote to do something, and waits till it gets an OK
% or times out

function [status] = tellRemote(self,cluster_name,command,value)

if nargin < 4
	value = 0;
end

if exist('~/.psychopomp/com_response.mat') == 2
	delete('~/.psychopomp/com_response.mat')
end

save('~/.psychopomp/com.mat','command','value');
[e,o] = system(['scp ~/.psychopomp/com.mat ' cluster_name ':~/.psychopomp/']);
assert(e == 0,'Error copying command onto remote')
pause(1)
tic 
goon = true;
t = toc;
while goon
	[e,o] = system(['scp ' cluster_name ':~/.psychopomp/com_response.mat ~/.psychopomp/']);
	pause(1)
	
	if e == 0
		load('~/.psychopomp/com_response.mat')
		if response == 0
			goon = false;
			return
		else
			error('Remote responded with an error.')
		end

	end

	if t > 10
		goon = false;
		error('Command timed out.')
	end

end