%% plotting routine made/modified day 1 of testing

%% quick plot of logged data for SR design 02
function quickPlot
global ADC t
inFName = 'D:\FSU\Sr Design\Sensors\testData\DATA201803251515.TXT';
% inFName = 'F:\DATA.TXT';
outFName = sprintf('testData/testData_%s.mat', myDateStr());
dat = importdata(inFName, ',');
ADC = 10;
scale = @(x) (x-2^(ADC-1))/2^(ADC-1)*200; % why 200?
t = dat(:,1);
[t, sortInds] = sort(t);
dat = dat(sortInds, :);

% format long
% % disp(reshape(t, 5,[]))
% format

%% conversion
% % zero all accel data
% for i = 1:4 % for each sensor
%     for j=0:2 % for each axis
%        dat(:, 3*i-1+j) = subtractOffset(dat(:, 3*i-1+j), t>5&t<10); % do this because independent offsets (zeroes)
%     end
% end
% convert to g's from binary
dat = scale(dat);

%% mov avg filter
windowSize=0;
newDat = zeros(size(dat,1)-windowSize, size(dat,2));
for i = 1:4 % for each sensor
    for j=0:2 % for each axis
       newDat(:, 3*i-1+j) = movAvgFilter(dat(:, 3*i-1+j), windowSize);
    end

end
%% split data
a1 = dat(:,2:4);    % label=1, position=IBM passenger side, pins={0,1,2}
a2 = dat(:,5:7);    % label=4, position=occupant,           pins={3,4,5}
a3 = dat(:,8:10);   % label=3, position=IBM driver side,    pins={6,7,8}
a4 = dat(:,11:13);  % label=2, position=COM,                pins={9,10,11}

% save(outFName, 't','a1','a2','a3','a4');

af1 = newDat(:,2:4);    % label=1, position=IBM passenger side, pins={0,1,2}
af2 = newDat(:,5:7);    % label=4, position=occupant,           pins={3,4,5}
af3 = newDat(:,8:10);   % label=3, position=IBM driver side,    pins={6,7,8}
af4 = newDat(:,11:13);  % label=2, position=COM,                pins={9,10,11}

plotDat = a4; % select data

t = t(1:end-windowSize);
%% plotting
figure(2), clf
subplot(221)
plotTheData(t,af1), title('IBM pass side')
subplot(222)
plotTheData(t,af2), title('occupant')
subplot(223)
plotTheData(t,af3), title('IBM driv side')
subplot(224)
plotTheData(t,af4), title('COM')

    function plotTheData(t,plotDat)
        
        plot(t,plotDat(:,1),t,plotDat(:,2),t,plotDat(:,3))
%         title('x dir')
        % axis([min(t) max(t) 2^(ADC)*[0.3 0.8]])
        
%         subplot(312)
%         plot(t,plotDat(:,2))
% %         title('y dir')
%         % axis([min(t) max(t) 2^(ADC)*[0.3 0.8]])
%         
%         subplot(313)
%         plot(t,plotDat(:,3))
%         title('z dir')
        % axis([min(t) max(t) 2^(ADC)*[0.3 0.8]])
        legend('X', 'Y', 'Z')
    end

end

%%

function newDat = subtractOffset(oldDat, window)
global ADC
assert(~any(isnan(oldDat(:))))
offset = -mean(oldDat(window)) + 2^(ADC-1);

newDat = oldDat + offset;

end


function newDat = movAvgFilter(dat, N)
newDat = zeros(1,length(dat)-N);
for i=1:(length(dat)-N)
    newDat(i) = mean(dat(i:i+N));
end

end

function out=myDateStr()
timenow = clock;
out = sprintf('%02.0f', timenow(1:end-1));
end