function [sp] = storeSpikes(V,Ca)

% stores spiketimes in a 1000-element vector
sp = zeros(1e3,1);
s = psychopomp.findSpikes(V);
if length(s) < 1e3
	sp(1:length(s)) = s;
end
