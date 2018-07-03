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
% it's a very simple loop that is meant to be run
% on a timer. every time it runs, it looks to see if 
% there is a command that tells it to do something
% and if so, tries to do it. that's it. 
% it should never ever throw an error, so 
% count on this running at all times

function psychopompd(self,~,~)




% run any commands specified by master
response = 0;

if exist('~/.psych/com.mat','file') == 2

	% wipe any old responses if they exist
	if exist('~/.psych/com_response.mat','file') == 2
		delete('~/.psych/com_response.mat')
	end


	try

		load('~/.psych/com.mat')
		delete('~/.psych/com.mat')

		disp(['Running command ' command])


	catch err
		disp(err)
		response = 1;
		save('~/.psych/com_response.mat','response')
	end

	try

		eval(['self.' command])
		disp('Command completely successfully!')

		save('~/.psych/com_response.mat','response')

	catch err
		keyboard
		disp(err)
		response = 1;
		save('~/.psych/com_response.mat','response')
	end

end