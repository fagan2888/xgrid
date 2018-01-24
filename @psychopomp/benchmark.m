%                          _                                       
%                         | |                                      
%     _ __  ___ _   _  ___| |__   ___  _ __   ___  _ __ ___  _ __  
%    | '_ \/ __| | | |/ __| '_ \ / _ \| '_ \ / _ \| '_ ` _ \| '_ \ 
%    | |_) \__ \ |_| | (__| | | | (_) | |_) | (_) | | | | | | |_) |
%    | .__/|___/\__, |\___|_| |_|\___/| .__/ \___/|_| |_| |_| .__/ 
%    | |         __/ |                | |                   | |    
%    |_|        |___/                 |_|                   |_|
% 
% benchmarks performance on current hardware, and saves
% results to ~/.psych/benchmark.mat

function benchmark(self)

assert(~isempty(self.x),'First configure xolotl object')

% make sure there exists a linked binary
if isempty(self.x.linked_binary)
	self.x.skip_hash_check = false;
	self.x.transpile;
	self.x.compile;
	self.x.skip_hash_check = true;
end

self.x.closed_loop = false;
tic
for i = 1:5
	V = self.x.integrate;
end
t = toc;

speed = (self.x.t_end*1e-3*5)/t;
save('~/.psych/benchmark.mat','speed');
disp(['average of 5 runs: ' oval(speed) 'X'])