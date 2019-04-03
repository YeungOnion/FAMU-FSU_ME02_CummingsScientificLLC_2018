% for all combinations of models and datatypes
numTests = 11;
fitStuff = nan(4, 5, numTests); % 4 params, 5 models, numTests(=11) datasets
mtype = {'haversine', 'halfsine', 'triangle', 'symmtriangle', 'square'};

for dataNum = 1:numTests
    figure(1), clf
    for m = 1:length(mtype)
        if m == 1
            subplot(2,4, [3 8])
        elseif m >= 4
            subplot(2,4, m+1)
        else % 2 <= m <= 3
            subplot(2,4, m-1)
        end
        [xbest, dv] = testAnyModel(dataNum, mtype{m});
        fitStuff(1,m, dataNum) = xbest(1);
        fitStuff(2,m, dataNum) = abs(xbest(3)-xbest(2));
        
        if strcmp('triangle', mtype{m})
            fitStuff(3,m, dataNum) = xbest(4);
        end
        fitStuff(4, m, dataNum) = dv;
        
        drawnow
        pause(1)
    end
    figName = sprintf('MultiModelPlots/FitResults_N%02d', dataNum);
    export_fig([figName '.jpg'], '-m3')
end

save('allFitSummary.mat', 'fitStuff', 'mtype')