# psychopomp

[![GitHub last commit](https://img.shields.io/github/last-commit/sg-s/psychopomp.svg)]()

## What it is


`psychopomp` is a MATLAB toolbox to run [xolotl](https://github.com/sg-s/xolotl) simulations in parallel, using MATLAB's [parallel computing toolbox](https://www.mathworks.com/products/parallel-computing.html), on as many computers you want. `psychopomp` handles all communication to remote nodes over SSH, and you can use it to run simulations on an arbitrary number of nodes without ever leaving the MATLAB prompt on your local machine. 

## How to use it (one a single machine)


Set up a `psychopomp` object:

```
p = psychopomp;
```

Set up a `xolotl` object (see instructions [here](https://github.com/sg-s/xolotl)), and link it to `psychopomp`

```
p.x = x; % x is a xolotl object
```

Now, you can write an arbitrarily complex function that does **something** with the `xolotl` object, and returns `N` outputs. The only requirements for this function are:

1. it must exist on your path (duh)
2. it must have exactly one input, which is a xolotl object

Typically, you would want to write a function that integrates the `xolotl` object, and reduces the time-series output of the model into some metrics, that will then be returned to `psychopomp`. 

Once you have this function, configure `psychopomp` to use this function:

```
p.sim_func = @test_func;
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
psychopomp 
is using 12 threads on yggdrasil
is using 12 threads on midgard

Xolotl has been configured, with hash: 429e229c3511a8f87e7ed16f12296dd8c354408d
 
Cluster                   Queued     Running   Done
---------------------------------------------------
yggdrasil                 0            12        14
midgard                   0            4         24

```

## How to use it (on multiple machines)

Assuming you have multiple machines called `remote` and `local`, and that

1. `remote` is reachable from `local` via SSH using public-key authentication (You should be able to `ssh server.name` without specifying passwords or usernames)
2. `remote` and `local` run MATLAB with the parallel computing toolbox
3. `remote` and `local` have the latest versions of `psychopomp` and `xolotl` 

Run the `psychopomp` [daemon](https://en.wikipedia.org/wiki/Daemon_(computing)) on the `remote`:

```matlab
% on the remote
p = psychopomp;
p.daemonize;
```

Now, you can add the `remote` as a cluster to `psychopomp` on `local`:

```
% on local
p = psychopomp('address.of.remote');
```

It's that simple. All other operations are transparent, and all commands are the same whether you are using a local cluster or a remote cluster. Psychopomp handles all the communication with other computers, including running jobs, moving files -- everthing. 


## Examples 

See [tests/](tests/test.m)

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