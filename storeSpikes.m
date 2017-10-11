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
function [sp] = storeSpikes(V,Ca,~,~,~,~,~,~)

% stores spiketimes in a 1000-element vector
sp = zeros(1e3,1);
s = psychopomp.findSpikes(V);
if length(s) < 1e3
	sp(1:length(s)) = s;
end
