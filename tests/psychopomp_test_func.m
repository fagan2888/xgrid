% this function is used in the example (test.m)
% to show how custom functions can be written to
% run xolotl simulations using pyschopomp
% 
% functions that can be run by pyschopomp take in only
% argument, which is the xolotl object
% they are responsible for running the simulation, analyzing
% outputs, and returning data that matches the dimensions 
% specified in the data_sizes property 

function [burst_period, n_spikes_per_burst, spike_times, sim_time] = psychopomp_test_func(x,~,~)

try

	x.closed_loop = false;
	x.reset;

	tic
	[V,Ca] = x.integrate; 
	sim_time = toc;

	transient_cutoff = floor(length(V)/2);
	Ca = Ca(transient_cutoff:end,1);
	V = V(transient_cutoff:end,1);

	burst_metrics = psychopomp.findBurstMetrics(V,Ca);

	burst_period = burst_metrics(1);
	n_spikes_per_burst = burst_metrics(2);

	spike_times = xolotl.findNSpikes(V,100);

	disp('Sim successfully completed!')

catch err
	disp('error running function!')
end