function [t, accel, timpact, duration, dV] = loadDat(dataNum)
datapath = 'D:\FSU\Sr Design\Sensors\testData\'; % OSX defaults slash the other way, but both work
% LOADDAT loads the data of the given impact number [1,11], outputs
% ENSURE TO SET datapath
%   - t, time in ms
%   - accel, acceleration in g's
%   - timpact, approimate time of impact in us

%% The following section designed to be modified to fit given dataset values and naming
%% --- Begin ''designed for edit'' section ---
%% load data from somewhere, change dataNum to select which
% stuff about all the data
%   the first is suffixes to filenames
%   the second is approximate time of collision
allTimeStr = [1202  1216  1226  1318  1326  1334  1349  1358  1412  1433  1515 ];
alltimpact = [41.02 41.28 30.69 37.63 29.68 35.59 34.90 33.78 63.11 30.58 37.36]; % time in s
alldt      = [110   110   100   105   101   105   165   150   140   105   075  ]; % in ms
alldeltaV  = [3.635 1.626 3.922 3.590 3.637 3.801 3.500 3.015 3.488 2.023 3.140]; % in mph

% set parameters for files
timeStr  = allTimeStr(dataNum);
timpact  = alltimpact(dataNum)*1e3; % time in ms
duration = alldt(dataNum);
dV       = alldeltaV(dataNum);

% load the data
inFName = [datapath '\DATA20180325' num2str(timeStr) '.TXT'];
dat = importdata(inFName, ',');

%% --- End ''designed for edit'' section ---

%% sort (accounting for polling faster than writing -> unsorted near occasional gaps)
%  and only get data around impact
% dt = 1.5; % duration of impact
t = dat(:,1);
[~, sortInds] = sort(t);
% sortInds = sortInds( (t>timpact*1e6) & (t<(timpact+dt)*1e6));
% [t, sortInds, ~] = unique(t,'sorted');
% % sortInds = sortInds( (t>timpact*1e6) & (t<(timpact+dt)*1e6));
% t   =   t/1e3; % conv to ms
t   =   t(sortInds)/1e3; % conv to ms
accel = dat(sortInds, 2:end); % all accel data

accel = remOffsetConv2G(accel);



function accel = remOffsetConv2G(accel)
% REMOFFSETCONV2G removes offset in whatever way is implemented, which is
% currently zeroing first fourier coefficient. Then it converts to G's
% using the 10-bit ADC conversion

% subtract offset in ADC space
% by removing first fourier coefficient
%
% consider taking a mean of the first few seconds and removing it

for i = 1:4 % for each sensor
    for j = 1:3 % for each axis
        ind = 3*(i-1)+j;
        
        ftdat = fft(accel(:,ind));
        ftdat(1) = 0;
        accel(:,ind) = ifft(ftdat);
    end
end

%% scale from adc values to g's
% accel outputs 3V3/2 for 0g, 3V3 for 200g and 0 for -200g
ADC = 10;
scale = @(x) x*200/2^(ADC-1); % scales after offset removal
accel = scale(accel);
