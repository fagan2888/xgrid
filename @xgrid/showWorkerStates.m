function showWorkerStates(self)

fprintf('\n\nCluster      Worker  State      Output\n')
fprintf('---------------------------------------------------------------\n')

for i = 1:length(self.clusters)
	if strcmp(self.clusters(i).Name,'local')
		for j = 1:length(self.workers)
			cluster_name = flstring('local',12);
			wid = flstring(oval(j),7);
			ws = flstring(self.workers(j).State,10);
			wd = self.workers(j).Diary;
			if ~isempty(wd)
    			try
        			wd = splitlines(wd);
            		if isempty(wd{end})
            			wd(end) = [];
            		end

    				wd = flstring(wd{end},20);
    			catch
    				wd = flstring('error parsing diary',20);
    			end
    		else
    			wd = flstring('',20);
    		end
			fprintf([cluster_name  ' ' wid ' ' ws ' ' wd  '\n'])
		end
	else
		if isfield(self.clusters(i).plog,'worker_diary')
    		for j = 1:length(self.clusters(i).plog.worker_diary)
    			cluster_name = flstring(self.clusters(i).Name,12);
    			wid = flstring(oval(j),7);
    			ws = flstring(self.clusters(i).plog.worker_state{j},10);
    			wd = self.clusters(i).plog.worker_diary{j};
    			if ~isempty(wd)
        			try
            			wd = splitlines(wd);
	            		if isempty(wd{end})
	            			wd(end) = [];
	            		end

        				wd = flstring(wd{end},20);
        			catch

        				wd = flstring('error parsing diary',20);
        			end
        		else
        			wd = flstring('',20);
        		end
    			fprintf([cluster_name  ' ' wid ' ' ws ' ' wd  '\n'])
    		end
    	end
	end
end


