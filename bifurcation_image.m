% Copyright 2018 Mark Debord <mjay.debord@gmail.com> GPLv3 (License.txt)
%% parameters
% Edit this section to change output image resolution, visable state
% range, and visable multiplier range

saveim = "bifurcation"; %set to [] to not save

mapFun = @logistic_map; % 1d recurrence relation to build histogram with

initState = 0.5;      % initial state value to start iteration
multRange = [2.85,4]; % const. multiplier range for map (r in logistic map)
stateRange = [0,1];   % state range to count visitations
multRes = 1920*4;     % integer divisions of multiplier range
stateRes = 1080*4;    % integer divisions of state counts
nIter = round(stateRes/4); % numer of iterations at each multiplier value to count in histogram
cntThresh = 0;        % only start to count states that have been visited this many times
useParallel = true;  % use parfor loop to iterate over multiplier range

% set datatype based on number of iterations (to keep memory size low)
if nIter <= 65535
    dtype = @uint16;
elseif nIter <= 4294967295
    dtype = @uint32;
else
    dtype = @uint64;
end

%% state visitation histogram counts

tic;
[biCnts,~] = bifurcation_counts(mapFun,initState,...
                                       multRange,stateRange,...
                                       multRes,stateRes,nIter,...
                                       cntThresh,useParallel,...
                                       dtype);
fprintf('Counts took: %0.2f s\n',toc);
                                   
%% build image data

aspect = multRes/stateRes;

%log scaling
logCnts = log(double(biCnts) + 1); % +1 so that all counts map to number >= 0
%0-1 normalize
im = uint8(255*(mat2gray(logCnts)));

%% Show image

colormap(bone);
imshow(im);
axis on;

% a bunch of nonsense to get good tick marks
nMultTicks = 35;
nStateTicks = round(50/aspect);
multTicks = linspace(1,multRes,nMultTicks);%
multTickVal = linspace(multRange(1),multRange(2),nMultTicks);
stateTicks = linspace(1,stateRes,nStateTicks); %
stateTickVal = fliplr(linspace(stateRange(1),stateRange(2),nStateTicks));

multLabels=cellfun(@(v) sprintf('%0.2f',v),num2cell(multTickVal),...
                    'UniformOutput',false);
stateLabels=cellfun(@(v) sprintf('%0.2f',v),num2cell(stateTickVal),...
                    'UniformOutput',false);

% ticks
xticks(multTicks);
xticklabels(multLabels);
xtickangle(60);
yticks(stateTicks);
yticklabels(stateLabels);

xlabel('r');
ylabel('x');
title('Logistic Map $x_{n+1} = r*x_n(1-x_n)$ Bifurcation','interpreter','latex');
axis image

%% save

% for very large resolutions we save in strips that will need to be
% concatenated outside of MATLAB due to imwrite limitations
if (multRes*stateRes) >= (2^32 - 1) 
    %save as horizontal strips
    divs = 4; % number of strips
    startCol = 1;
    width = floor(multRes / divs);
    endCol = width;
    for n = 1:divs
        tic;
        fname = sprintf("%s_%d.png",saveim,n);
        fprintf("Saving %s...",fname);
        imwrite(im(:,startCol:endCol),fname);
        startCol = endCol + 1;
        endCol = startCol + width;
        if endCol > multRes
            endCol = multRes;
        end
        fprintf("Done in %0.2f s\n",toc);
    end
    
else
    imwrite(im,sprintf("%s.png",saveim));
end
