% Copyright 2018 Mark Debord <mjay.debord@gmail.com> GPLv3 (License.txt)
function [biCnts,mapIters] = map_counts(mapFun,initState,multRange,stateRange,multRes,stateRes,nIter,cntThresh,useParallel,dtype)
%map_counts iterates the state of a given map function (such as a logistic
% map x_n+1 = r*x_n(1-x_n) ) over a given multiplier range (r in logistic
% map) and returns the number of state visitations (up to a given
% resolution) for every value of r (also up to a given resolution)
arguments
    mapFun {mustBe2Fun} % iterating map function; takes (multiplier,stateVal) as input
    initState {mustBeNumeric}  % starting state value for map iteration
    multRange {mustBeNumeric, mustBeRangeVec(multRange,'multRange')} % scalar multiplier constant range
    stateRange {mustBeNumeric, mustBeRangeVec(stateRange,'stateRange')} % iterated value range
    multRes {mustBeInteger, mustBePositive}  % bifurcation x-axis (multiplier r) resolution
    stateRes {mustBeInteger, mustBePositive} % bifurcation y-axis (state x) resolution
    nIter {mustBeInteger} = 1024 %number of iterations to generate value data
    %count visited states that are apear more than cntThresh*max(stateCounts)
    %  set to 0 to count all visited states
    cntThresh {mustBeGreaterThanOrEqual(cntThresh,0), mustBeLessThanOrEqual(cntThresh,1)} = 0;
    useParallel logical = false;
    dtype function_handle = @uint64;
end

r = linspace(multRange(1),multRange(2),multRes);

mapIters = zeros(nIter,multRes);
biCnts = dtype(zeros(stateRes,multRes));

if useParallel
    parfor n = 1:multRes
        mapIters(:,n) = iterate_map(@(x)mapFun(r(n),x), initState, nIter);
        biCnts(:,n) = dtype(count_states(mapIters(:,n),stateRes,stateRange,cntThresh));
    end
else
    for n = 1:multRes
        mapIters(:,n) = iterate_map(@(x)mapFun(r(n),x), initState, nIter);
        biCnts(:,n) = dtype(count_states(mapIters(:,n),stateRes,stateRange,cntThresh));
    end
end

biCnts = flipud(biCnts); % so min state is at the bottom, max state at top


end

%% Helper funcs

function xfc = count_states(mapIters,stateRes,stateRange,cntThresh)

binEdges = linspace(stateRange(1),stateRange(2),stateRes+1);

[xfc,~] = histcounts(mapIters,binEdges);

maxc = max(xfc);
mask = xfc < (cntThresh*maxc);
xfc(mask) = 0;

end

function map = iterate_map(mapFun,initState,nIter)

map = zeros(nIter,1);
map(1) = initState;

for n = 2:nIter
    map(n) = mapFun(map(n-1));
end

end

function mustBeRangeVec(vec,name)
    if (numel(vec) ~= 2) || (vec(1) > vec(2)) 
        error('%s must be a 2 element vector with %s(1) < %s(2)',name);
    end
end

function mustBe2Fun(mapFun)
    if nargin(mapFun) ~= 2 || nargout(mapFun) == 0
        error('Map function should take 2 arguments: (multiplier, stateValue) and first return value: nextStateValue');
    end
end