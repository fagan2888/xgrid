% psychopomp
% a MATLAB class to run parameter scans of neuron models
% runs using xolotl (https://github.com/sg-s/xolotl)
% needs the parallel computing toolbox 

classdef psychopomp 

	properties
		current_pool@parallel.Pool
		parameters
		parameters2 % for some reason parameters is invisible to par workers
		x@xolotl
		post_sim_func@function_handle
		n_func_outputs
	end % end props

	properties (SetAccess = protected)
		data 
		allowed_param_names
		nparams
		num_workers
	end


	methods

		function self = psychopomp()
			% get the current pool, and start one if needed
			self.current_pool = gcp;
			self.num_workers = self.current_pool.NumWorkers;

		end

		function self = set.n_func_outputs(self,value)
			assert(length(value) == 1, 'n_func_outputs should be a integer')
			assert(length(value) > 0, 'n_func_outputs should be > 0')
			self.n_func_outputs = value;
		end % end set n_func_outputs 

		function self = set.parameters(self,value)
			if isempty(self.x)
				error('Assign Xolotl object first')
			end
			assert(isstruct(value),'parameters should be a structure')
			assert(length(value) == 1,'parameters should be a structure of unit size')

			% check that every field of parameters exists in allowed_param_names
			f = fieldnames(value);
			for i = 1:length(f)
				assert(any(strcmp(f{i},self.allowed_param_names)),'Parameters contain a field that does not match anything in the xololt object')
			end

			% the length of every field should be the same 
			nparams = NaN(length(f),1);
			for i = 1:length(f)
				nparams(i) = length(value.(f{i}));
			end
			assert(min(nparams) == max(nparams),'All parameter fields should have the same length')
			self.nparams = nparams(1);
			self.parameters = value;
			self.parameters2 = self.parameters;
		end

		function self = set.x(self,value)
			assert(length(value)==1,'Only one xololt object can be linked')
			self.x = value;
			% determine the parameter names we expect 
			n = getCompartmentNames(self.x);
			for i = 1:length(n)
				eval([n{i} ' = self.x.(n{i});']);
				eval( ['[~,these_names] = struct2vec(' n{i} ');']);
				self.allowed_param_names = [self.allowed_param_names; these_names];
			end
		end % end set xolotl object

		function simulate(self)
			for i = 1:self.num_workers
				F(i) = parfeval(@self.simulate_core,1,i);
			end
			ok = wait(F);

		end % end simulate 

		function o = simulate_core(self,idx)


			params = self.parameters2;
			njobs_per_worker = ceil(self.nparams/self.num_workers);
			a = (idx-1)*njobs_per_worker + 1;
			z = idx*njobs_per_worker;
			if z > self.nparams
				z = self.nparams;
			end
			
			f = fieldnames(params);
			this_param = struct;
			
			for j = a:z
				for i = 1:length(f)
					this_param.(f{i}(4:end)) = params.(f{i})(j);
				end

				self.x.updateLocalParameters(this_param);
				[V,Ca] = self.x.integrate;
			end
			o = V;
			

			
		end

	end % end methods 

	methods (Static)
		function spiketimes = findSpikes(V)
			[ons, offs] = computeOnsOffs(V>0);
			spiketimes = NaN*ons;
			for i = 1:length(ons)
				[~,idx] = max(V(ons(i):offs(i)));
				spiketimes(i) = ons(i) + idx;
			end
		end

		 
	end % end static methods

end % end classdef 



