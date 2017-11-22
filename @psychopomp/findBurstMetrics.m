%                          _                                       
%                         | |                                      
%     _ __  ___ _   _  ___| |__   ___  _ __   ___  _ __ ___  _ __  
%    | '_ \/ __| | | |/ __| '_ \ / _ \| '_ \ / _ \| '_ ` _ \| '_ \ 
%    | |_) \__ \ |_| | (__| | | | (_) | |_) | (_) | | | | | | |_) |
%    | .__/|___/\__, |\___|_| |_|\___/| .__/ \___/|_| |_| |_| .__/ 
%    | |         __/ |                | |                   | |    
%    |_|        |___/                 |_|                   |_|
% 
% finds the following things:
% (1) burst period
% (2) # of spikes / burst
% (3) time of first spike relative to Ca peak
% (4) time of last spike relative to Ca peak 
% (5) height of calcium peak

function burst_metrics = findBurstMetrics(V,Ca,Ca_peak_similarity, burst_duration_variability)

if nargin < 3
	Ca_peak_similarity = .3;
end
if nargin < 4
	burst_duration_variability = .1;
end

burst_metrics = -ones(5,1);


Ca_prom = std(Ca);
[peak_Ca,burst_peak_loc] = findpeaks(Ca,'MinPeakProminence',Ca_prom);


% there should be at least three
if length(peak_Ca)<3
	disp('Less than three peaks')
	return
end

% check for similarity of peak heights 
if std(peak_Ca)/(mean(peak_Ca)) > Ca_peak_similarity
	disp('Calcium peaks not similar enough')
	disp(std(peak_Ca)/(mean(peak_Ca)))
	return
end

burst_durations = diff(burst_peak_loc);

if std(burst_durations)/mean(burst_durations) > burst_duration_variability
	disp('Burst durations too variable')
	disp(std(burst_durations)/mean(burst_durations))
	return
end

burst_dur = mean(burst_durations);

% find spikes
s = psychopomp.findNSpikes(V,1000);

n_spikes = 0*burst_peak_loc;
first_spike_loc = 0*burst_peak_loc;
last_spike_loc = 0*burst_peak_loc;

% for each burst, look around that peak and count spikes
for i = 2:length(burst_peak_loc)
	% find calcium minimum before current burst and previous burst

	[~,idx] = min(Ca(burst_peak_loc(i-1):burst_peak_loc(i)));

	a = idx + burst_peak_loc(i-1);

	% find calcium minimum after current peak
	if i == length(burst_peak_loc)
		[~,idx] = min(Ca(burst_peak_loc(i):end));
	else
		[~,idx] = min(Ca(burst_peak_loc(i):burst_peak_loc(i+1)));
	end
	z = idx + burst_peak_loc(i);
	% find spikes in this interval

	% first position of first spike
	spikes_in_this_burst = s(s<z&s>a);

	n_spikes(i) = length(spikes_in_this_burst);

	if n_spikes(i) > 0

		first_spike_loc(i) = spikes_in_this_burst(1) - burst_peak_loc(i);
		last_spike_loc(i) =  spikes_in_this_burst(end) - burst_peak_loc(i);
	end


end


burst_metrics(1) = burst_dur;
burst_metrics(2) = mean(n_spikes);
burst_metrics(3) = mean(first_spike_loc);
burst_metrics(4) = mean(last_spike_loc);
burst_metrics(5) = mean(peak_Ca);

