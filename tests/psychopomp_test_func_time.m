% this function is used to time psychopomp,
% to make sure it isn't slower than it should be

function [burst_period] = psychopomp_test_func(x)

burst_period = 0;

x.integrate; 


