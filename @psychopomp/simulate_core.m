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
		do_folder = [self.psychopomp_folder filesep 'do' filesep ];
		doing_folder = [self.psychopomp_folder filesep 'doing' filesep ];
		done_folder = [self.psychopomp_folder filesep 'done' filesep ];
		free_jobs = dir([ do_folder '*.ppp']);

		if isempty(free_jobs)
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
			continue
		end

		% load the file 
		load([doing_folder this_job],'-mat')


		% check that the hash matches
		assert(strcmp(xhash,self.x_hash),'Hashes dont match')

		
		for i = 1:size(this_params,2)
			% update params

			self.x.set(param_names,this_params(:,i))

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
					for j = length(outputs):-1:1
						data{j} = NaN(size(vectorise(outputs{j}),1),size(this_params,2));
					end
				end

				for j = 1:length(data)
					data{j}(:,i) = vectorise(outputs{j});
				end
			end

		end

		% some defensive measures to make sure that data
		% and params are aligned 
		ok = true;
		for j = 1:length(data)
			if size(data{j},2) ~= size(this_params,2)
				ok = false;
			end
		end

		if ok
			% all OK, can save the data, move on
			save([done_folder this_job '.data'],'data')

			% move the job into the done folder
			movefile([doing_folder this_job],[done_folder this_job])

		else
			% not OK. give up. 
			disp('Something went wrong with this job:')
			disp(this_job)
			disp('This job will remain stuck in the doing queue')
		end



		clear data this_params param_idx param_names xhash
		n_runs = n_runs - 1;
	end
	
end