# psychopomp

[![GitHub last commit](https://img.shields.io/github/last-commit/sg-s/psychopomp.svg)]()

## What it is


`psychopomp` is a MATLAB toolbox to run [xolotl](https://github.com/sg-s/xolotl) simulations in parallel, using MATLAB's [parallel computing toolbox](https://www.mathworks.com/products/parallel-computing.html). 

## How to use it


Set up a `psychopomp` object:

```
p = psychopomp;
```

Set up a `xolotl` object (see instructions [here](https://github.com/sg-s/xolotl)), and link it to `psychopomp`

```
p.x = x; % x is a xolotl object
```

Configure some functions to run on the output of the simulation. There's no point running all these simulations if you aren't also simultaneously analyzing the data and reducing it -- storing the raw output of the simulations is going to be indefeasibly large. 

```
p.post_sim_func = {@findBurstMetrics, @storeSpikes};
```

Tell `psychopomp` about the size of the data storage matrices that these functions produce, so that `psychopomp` can allocate in advance.

```
p.data_size = [4, 1e3];
```

Feed a giant matrix of parameters, with labels to `psychopomp`. `psychopomp` will split these into a number of job files that live on the filesystem, and can be transparently manipulated. 

```
p.batchify(all_params,param_labels);
```

Start the simulation on all threads on your CPU:

```
p.simulate;
```

Inspect the `psychopomp` object at any time:

``` 
p = 
psychopomp is using 8/8 threads on yggdrasil

Xolotl has been configured, with hash: 545e69a92e3d2pe5e2b4ef48a8d2e601
 
Simulation progress:    
--------------------
Queued :  0
Running:  1
Done   :  71
Simulations started on      :04-Oct-2017 23:21:18
Estimated time of completion: 04-Oct-2017 23:22:04
Running @ 199X

```

## How to get it

The best way to get `psychopomp` is to use my package manager:

```matlab

% copy and paste this code in your MATLAB prompt
urlwrite('http://srinivas.gs/install.m','install.m'); 
install sg-s/srinivas.gs_mtools % you'll need this
install sg-s/xolotl % the actual simulation code
install sg-s/psychopomp
```



## License 

`psychopomp` is free software (GPL v3). 