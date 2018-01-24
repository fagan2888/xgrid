%                          _                                       
%                         | |                                      
%     _ __  ___ _   _  ___| |__   ___  _ __   ___  _ __ ___  _ __  
%    | '_ \/ __| | | |/ __| '_ \ / _ \| '_ \ / _ \| '_ ` _ \| '_ \ 
%    | |_) \__ \ |_| | (__| | | | (_) | |_) | (_) | | | | | | |_) |
%    | .__/|___/\__, |\___|_| |_|\___/| .__/ \___/|_| |_| |_| .__/ 
%    | |         __/ |                | |                   | |    
%    |_|        |___/                 |_|                   |_|
%  


function simulate_core(self,idx,n_runs)

	while n_runs > 0

		% grab a job file and move it to doing 
		do_folder = [self.psychopomp_folder oss 'do' oss ];
		doing_folder = [self.psychopomp_folder oss 'doing' oss ];
		done_folder = [self.psychopomp_folder oss 'done' oss ];
		free_jobs = dir([ do_folder '*.ppp']);

		if length(free_jobs) == 0
			return
		end

		try
			this_job = free_jobs(idx).name;
		catch
			this_job = free_jobs(1).name;
		end

		try
			movefile([do_folder this_job],[doing_folder this_job])
		catch
			pause(1)
		end

		% load the file 
		load([doing_folder this_job],'-mat')


		
		for i = 1:size(this_params,2)
			% update params

			for j = 1:length(param_names)
				eval(['self.x.' param_names{j} ' = this_params(' mat2str(j),',' mat2str(i) ');'])
			end


			% run the model
			ok = false;
			try

				[outputs{1:length(argOutNames(self.sim_func))}] = self.sim_func(self.x);
				ok = true;
			catch err
				disp(err)
				for j = 1:length(err.stack)
					disp(['file: ' err.stack(j).file '  line:' err.stack(j).line])
				end
				warning('Error while running simulation function.')
			end

			% map the outputs to the data structures
			if ok

				if ~exist('data','var')
					% create placeholders
					for j = 1:length(outputs)
						data{j} = NaN(size(vectorise(outputs{j}),1),size(this_params,2));
					end
				end

				for j = 1:length(data)
					data{j}(:,i) = vectorise(outputs{j});
				end
			end

		end


		% save the data 
		save([done_folder this_job '.data'],'data')

		% move the job into the done folder
		try
			movefile([doing_folder this_job],[done_folder this_job])
		catch
		end

		n_runs = n_runs - 1;
	end
	
end