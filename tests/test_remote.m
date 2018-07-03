% small script that tests psychopomp
% using parallel workers both on the local
% computer and on a remote cluster 
% this simulates 100 different neurons 


% tests a neuron that reproduces Fig 3 in Tim's paper


% tests a neuron that reproduces Fig 3 in Tim's paper
vol = 0.0628; % this can be anything, doesn't matter
f = 1.496; % uM/nA
tau_Ca = 200;
F = 96485; % Faraday constant in SI units
phi = (2*f*F*vol)/tau_Ca;
Ca_target = 0; % used only when we add in homeostatic control

x = xolotl;
x.add('compartment','AB','Cm',10,'A',0.0628,'vol',vol,'phi',phi,'Ca_out',3000,'Ca_in',0.05,'tau_Ca',tau_Ca,'Ca_target',Ca_target);

x.AB.add('liu/NaV','gbar',1831,'E',30);
x.AB.add('liu/CaT','gbar',23,'E',30);
x.AB.add('liu/CaS','gbar',27,'E',30);
x.AB.add('liu/ACurrent',246,'E',-80);
x.AB.add('liu/KCa','gbar',980,'E',-80);
x.AB.add('liu/Kd','gbar',610,'E',-80);
x.AB.add('liu/HCurrent','gbar',10,'E',-20);
x.AB.add('Leak','gbar',.99,'E',-50);

x.t_end = 50e3;
x.closed_loop = false;
x.transpile;
x.compile;
x.t_end = 20e3;

% in this example, we are going to vary the maximal conductances of the Acurrent and the slow calcium conductance in a grid

parameters_to_vary = {'AB.CaS.gbar','AB.ACurrent.gbar'};

g_CaS_space = linspace(0,100,25);
g_A_space = linspace(100,300,25);

all_params = NaN(2,length(g_CaS_space)*length(g_A_space));
c = 1;
for i = 1:length(g_CaS_space)
	for j = 1:length(g_A_space)
		all_params(1,c) = g_CaS_space(i);
		all_params(2,c) = g_A_space(j);
		c = c + 1;
	end
end

clear p 

% connect to a local cluster (on your machine)
% and on a remote cluster 
% make sure you have a variable called remote_name
% that is the address of the remote
p = psychopomp(remote_name,'local');

return

% wipes all job files on local and on remote
p.cleanup; 
pause(6)


% copies xolotl object to all remote clusters
p.x = x;
pause(6)

% split simulation parameter set into jobs, 
% and distribute them optimally across all
% connected clusters, local and remote 
p.n_batches = 2;
p.batchify(all_params,parameters_to_vary);
pause(6)


% configure the function to run the simulation
% this also copies this function onto all remotes
% and configures all remotes 
p.sim_func = @psychopomp_test_func;
pause(6)

return

p.simulate(.5);
wait(p)

[all_data,all_params,all_param_idx] = p.gather;
burst_periods = all_data{1};
n_spikes_per_burst = all_data{2};
spiketimes = all_data{3};


% assemble the data into a matrix for display
BP_matrix = NaN(length(g_CaS_space),length(g_A_space));
NS_matrix = NaN(length(g_CaS_space),length(g_A_space));
for i = 1:length(all_params)
	x = find(all_params(1,i) == g_CaS_space);
	y = find(all_params(2,i) == g_A_space);
	BP_matrix(x,y) = burst_periods(i);
	NS_matrix(x,y) = n_spikes_per_burst(i);
end
BP_matrix(BP_matrix<0) = NaN;
NS_matrix(NS_matrix<0) = 0;

figure('outerposition',[0 0 1100 500],'PaperUnits','points','PaperSize',[1100 500]); hold on
subplot(1,2,1)
h = heatmap(g_A_space,g_CaS_space,BP_matrix);
h.Colormap = parula;
h.MissingDataColor = [1 1 1];
ylabel('g_CaS')
xlabel('g_A')
title('Burst period (ms)')

subplot(1,2,2)
h = heatmap(g_A_space,g_CaS_space,NS_matrix);
h.Colormap = parula;
h.MissingDataColor = [1 1 1];
ylabel('g_CaS')
xlabel('g_A')
title('#spikes/burst')

prettyFig();

