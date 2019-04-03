function [xbest, dv] = testAnyModel(dataNum, modeltype)
%% TESTANYMODEL(dataNum, modeltype) is a routine that takes a datanumber and model string
% and outputs the best fit parameters associated to the data and model
%   ex:
%       % fits dataset 2 to the haversine model
%       x2best = testAnyModel(2, 'haversine')
%       % fits dataset 5 to the halfsine model
%       x5best = testAnyModel(5, 'halfsine')
%
% dataNum goes from 1:11
% modeltypes: haversine, halfsine, triangle, symmtriangle, square

global INPUT DATAF DATA
%% choose dataset and figure
INPUT.dataNum = dataNum;
INPUT.figNum  = 1;
INPUT.titleStr = 'Title';
INPUT.windowSz = 5; % averaging filter width
INPUT.model = modeltype;
% model types: haversine, halfsine, triangle, symmtriangle, square

% format a little
% INPUT.f1 = figure(INPUT.figNum);
% INPUT.f1.Position = [700 300 800 450];

%% load chosen dataset through moving average filter
loadDataAndFilter(); % loads filtered data into DATAF

%% plot data
plot(DATAF.t, DATAF.cg) % for filtered
% plot( DATA.t,  DATA.cg) % for raw
tstr = sprintf('Data Num: %02d', INPUT.dataNum);
xlim([-25 25+DATAF.duration]) 
title(tstr)
xlabel('$t$ (ms)', 'Interpreter', 'latex')
ylabel('$a$ ($g$)', 'Interpreter', 'latex')
set(gca,'FontSize', 16)


%% fit to model and plot

[f,xbest] = findFit();

hold on
plot(DATAF.t, f);
hold off
if strcmp(INPUT.model, 'haversine')
    legend('Filtered', 'Model')
end


% %% output fit form onto plot
% summarizeOntoPlot(xbest, f)
dv = DATAF.dv;
end


function loadDataAndFilter
global DATAF INPUT CONV DATA
[t, accel, timpact, duration, dv] = loadDat(INPUT.dataNum);
CONV.gms2mph = @(x) x*32.2*3600/5280/1000;

DATA.t = t;
DATA.cg =  -accel(:,11) + mean(accel(1:2e3,11)); % remove 0 offset w avg
clear t accel


% filter with moving average
DATAF.cg = movAvgFilt(DATA.cg,INPUT.windowSz);
dt = DATA.t(2)-DATA.t(1);
DATAF.t = DATA.t - dt*INPUT.windowSz;
DATA.dv = dv;


%% Reduce data to be near pulse
DATA.t = DATA.t-timpact; DATAF.t = DATAF.t-timpact;
impactInds = (DATA.t>-50) & (DATA.t<duration+50);
DATAF.cg   = DATAF.cg(impactInds);
DATAF.t = DATAF.t(impactInds);
DATAF.dv = dv;
DATAF.duration = duration;

clear DATA % only need filtered data

end

function f = myModelFunction(x,t)
global INPUT
% used to handle any type of fit function
% functional shape defined by user
% with variable fit parameters, x


switch lower(INPUT.model)
%% haversine
    case 'haversine'
        A = x(1); t0 = x(2); tf = x(3); T = tf-t0;
        f = A / 2 * (1 - cos(2*pi*(t-t0)/T) );
        f(t0 > t | t > tf) = 0;
        
%% halfsine
    case 'halfsine'
        A = x(1); t0 = x(2); tf = x(3); T = tf-t0;
        f = A * sin( pi*(t-t0)/T );
        f(t0 > t | t > tf) = 0;
        
%% triangle
    case 'triangle'
        apeak = x(1); t0 = x(2); tf = x(3); tpeak = x(4);
        pp = mkpp([-50 t0 tpeak tf 300], [0 0; apeak/(tpeak-t0) 0; apeak/(tpeak-tf) apeak; 0 0]);
        f = ppval(pp, t);
        
%% symmetric triangle
    case 'symmtriangle'
        apeak = x(1); t0 = x(2); tf = x(3); tpeak = (t0+tf)/2;
        % piecewise polynomial
        pcwsdivs = [-50 t0 tpeak tf 300];
        coefs = [0 0; apeak/(tpeak-t0) 0; apeak/(tpeak-tf) apeak; 0 0];
        pp = mkpp(pcwsdivs, coefs);
        f = ppval(pp, t);
        
%% square
    case 'square'
        a = x(1); t0 = x(2); tf = x(3);
        pcwsdivs = [-50 t0 tf 300];
        coefs = [0; a; 0]; 
        pp = mkpp(pcwsdivs, coefs);
        f = ppval(pp, t);

%% whoops
    otherwise
        error('Model unknown, add it on here and in objective function')
end


end

function obj = myObjectiveFunc(x)
% inputs model parameters and produces objective function based on
% how far start end times are from init guess (bad fitting theory, but 
% we assume by eye is good within some window
global DATAF
f = myModelFunction(x,DATAF.t);

% contribution weights
SSEwt   = 1/length(f);
TERRwt  = 1;
DVERRwt = 1;

% max acceptable error terms
TWID = 10; % error window (+/-) in ms for how good init guess for t0 tf are
DVWID = 5e-2; % max relative error acceptable for fitting dv term

% parse input parameters
t0 = x(2); tf = x(3);

% term for t0 and tf
terrobj = sinh((t0-0)/TWID)^2 + sinh((tf-DATAF.duration)/TWID)^2;

% term for delta-V
dvfit = computeDV(x, f);
dverr = dvfit/DATAF.dv - 1;
dverrobj = sinh(dverr/DVWID)^2;

% term for LLS
RSSE = sqrt( sum((f-DATAF.cg).^2) );

% overall assessment of fit
obj = RSSE*SSEwt + terrobj*TERRwt + dverrobj*DVERRwt;

end

function [f, xbest] = findFit()
% finds fit
global INPUT DATAF

% choose ICs based on model type
switch lower(INPUT.model)
%% haversine
    case 'haversine'
        A = max(DATAF.cg); t0 = 0; tf = DATAF.duration;
        x0 = [A; t0; tf];
        
%% halfsine
    case 'halfsine'
        A = max(DATAF.cg); t0 = 0; tf = DATAF.duration;
        x0 = [A; t0; tf];
        
%% triangle
    case 'triangle'
        apeak = max(DATAF.cg); t0 = 0; tf = DATAF.duration; tpeak = DATAF.t(find(DATAF.cg==apeak,1));
        x0 = [apeak; t0; tf; tpeak];
        
%% symmetric triangle
    case 'symmtriangle'
        apeak = max(DATAF.cg); t0 = 0; tf = DATAF.duration;
        x0 = [apeak; t0; tf];
        
%% square
    case 'square'
        a = max(DATAF.cg)/2; t0 = 0; tf = DATAF.duration;
        x0 = [a; t0; tf];

%% whoops
    otherwise
        error('Model IC''s not specifed in findFit function')
end

xbest = fminunc(@myObjectiveFunc, x0);
f = myModelFunction(xbest,DATAF.t);

end

function dv = computeDV(x,f)
% finds deltaV from data
global DATAF CONV INPUT
% old way, not the best really
% dv = CONV.gms2mph(trapz(DATAF.t, f)); 

dv = 0;
% there is analytic form for each model depending on x
switch lower(INPUT.model)
%% haversine
    case 'haversine'
        A = x(1); t0 = x(2); tf = x(3); T = tf-t0;
        dv = A*T/2;
%% halfsine
    case 'halfsine'
        A = x(1); t0 = x(2); tf = x(3); T = tf-t0;
        dv = 2*A*T/pi;
%% triangle
    case 'triangle'
        apeak = x(1); t0 = x(2); tf = x(3); tpeak = x(4);
        dv = apeak*(tf-t0)/2;
%% symmetric triangle
    case 'symmtriangle'
        apeak = x(1); t0 = x(2); tf = x(3); tpeak = (t0+tf)/2;
        dv = apeak*(tf-t0)/2;
%% square
    case 'square'
        a = x(1); t0 = x(2); tf = x(3);
        dv = a*(tf-t0);
%% whoops
    otherwise
        error('Model unknown, add it on here and in objective function')
end

dv = CONV.gms2mph(dv);

end

function summarizeOntoPlot(xbest, f)
% add numeric text to plot
global DATAF
%% summarize delta V comparison
tstr =       sprintf('%sV_{fit}   \t= %.2f[mph] ', '\Delta', computeDV(xbest, f));
tstr = {tstr sprintf('%sV_{data}\t= %.2f[mph]', '\Delta', DATAF.dv)};
text(-20, max(DATAF.cg), tstr, 'FontSize', 14)

%% summarize fit parameters to plot
fitparams = {'A' 't_0' 't_f' 't_{peak}'};
fitunits  = {'g' 'ms'  'ms'  'ms'};


tstr = cell(size(xbest));
for i=1:length(xbest)
    tstr{i} = sprintf('%s=%.2f [%s]', fitparams{i}, xbest(i), fitunits{i});
end
tstr{end+1} = sprintf('SSE/N=%.2f [g^2]', sum((f-DATAF.cg).^2)/length(f) );
text((xbest(2)+xbest(3))/2-15, .25, tstr, 'FontSize', 14)
end