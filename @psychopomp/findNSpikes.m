%                          _                                       
%                         | |                                      
%     _ __  ___ _   _  ___| |__   ___  _ __   ___  _ __ ___  _ __  
%    | '_ \/ __| | | |/ __| '_ \ / _ \| '_ \ / _ \| '_ ` _ \| '_ \ 
%    | |_) \__ \ |_| | (__| | | | (_) | |_) | (_) | | | | | | |_) |
%    | .__/|___/\__, |\___|_| |_|\___/| .__/ \___/|_| |_| |_| .__/ 
%    | |         __/ |                | |                   | |    
%    |_|        |___/                 |_|                   |_|
% 
% this helper static method figures out spike times 
% (in units of simulation time step) and returns them
% only works with one compartment
% 
function spiketimes = findNSpikes(V,n_spikes)

spiketimes = NaN(n_spikes,1);
[ons, offs] = computeOnsOffs(V > 0);
stop_here = min([length(ons) n_spikes]);
if stop_here == 0
	return
end
for j = 1:stop_here
	[~,idx] = max(V(ons(j):offs(j)));
	spiketimes(j) = ons(j) + idx;
end

