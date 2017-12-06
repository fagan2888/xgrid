% small script that tests psychopomp
% this simulates 100 different neurons 


% tests a neuron that reproduces Fig 3 in Tim's paper

vol = 0.0628; % this can be anything, doesn't matter
f = 1.496; % uM/nA
tau_Ca = 200;
F = 96485; % Faraday constant in SI units
phi = (2*f*F*vol)/tau_Ca;
Ca_target = 0; % used only when we add in homeostatic control 

x = xolotl;
x.addCompartment('AB',-60,0.02,10,0.0628,vol,phi,3000,0.05,tau_Ca,Ca_target);

% set up a relational parameter
x.AB.vol = @() x.AB.A;

x.addConductance('AB','liu/NaV',1831,30);
x.addConductance('AB','liu/CaT',23,30);
x.addConductance('AB','liu/CaS',27,30);
x.addConductance('AB','liu/ACurrent',246,-80);
x.addConductance('AB','liu/KCa',980,-80);
x.addConductance('AB','liu/Kd',610,-80);
x.addConductance('AB','liu/HCurrent',10,-20);
x.addConductance('AB','Leak',.99,-50);

x.dt = 50e-3;
x.t_end = 10e3;


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
p = psychopomp;
p.cleanup;
p.n_batches = 2;
p.x = x;
p.batchify(all_params,parameters_to_vary);


% configure the simulation type, and the analysis functions 
p.sim_func = @psychopomp_test_func;

return

p.simulate(1);
wait(p.workers)

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

