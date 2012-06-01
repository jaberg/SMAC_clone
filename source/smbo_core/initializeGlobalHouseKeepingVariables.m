function initializeGlobalHouseKeepingVariables
global ThetaUniqSoFar;
ThetaUniqSoFar = [];

global allParamStrings;
allParamStrings = {}; % will keep a string for every unique configuration

global initial_flag; % for optimizing functions in benchmark_func.m
initial_flag = 0; 

global incumbent_matrix; % for keeping track of historic incumbents for offline eval
incumbent_matrix = [];

global TestTheta;
TestTheta = [];