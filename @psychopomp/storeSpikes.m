% psychopomp
%                          _                                       
%                         | |                                      
%     _ __  ___ _   _  ___| |__   ___  _ __   ___  _ __ ___  _ __  
%    | '_ \/ __| | | |/ __| '_ \ / _ \| '_ \ / _ \| '_ ` _ \| '_ \ 
%    | |_) \__ \ |_| | (__| | | | (_) | |_) | (_) | | | | | | |_) |
%    | .__/|___/\__, |\___|_| |_|\___/| .__/ \___/|_| |_| |_| .__/ 
%    | |         __/ |                | |                   | |    
%    |_|        |___/                 |_|                   |_|
% 
function [sp] = storeSpikes(self,V,Ca,~,~,~,~,~,~)

% stores spiketimes in a 1000-element vector

% throw away the transient 
if ~isempty(self.transient_length)
	a = self.transient_length/self.x.dt;
else
	a = 1;
end

V = V(a:end,:);

% to do -- make this work for multiple compartments

% to do -- don't hard wire the number of spikes to store, but read it from the data dimensions stored in the pyschopomp object

sp = zeros(1e3,1);
s = psychopomp.findSpikes(V);
if length(s) < 1e3
	sp(1:length(s)) = s;
end
