% compare all models
% put them on a deltaV - amax plot

clear variables
load('allFitSummary.mat'); % loads fitStuff and model types
% fit stuff is (4x5x11): 4 fit params, 5 models, 11 datasets
% fit params: A, duration, tpeak (triangle), deltaV

A   = squeeze(fitStuff(1,:,:));
dur = squeeze(fitStuff(2,:,:));
dv  = squeeze(fitStuff(4,:,:));

f1 = figure(1);
f1.Position = [700 300 800 450];


% plot mean haversine 125ms line
dvx = linspace(0, 4, 100);
durMean = 125; % mean duration is 125ms
Ay  = 2*dvx/durMean /(32.2*3600/5280/1000); % accel in g
plot(dvx, Ay)
xlabel('$\Delta{V}$ [mph]', 'Interpreter', 'latex')
ylabel('$a_{max}$ [$g$]', 'Interpreter', 'latex')
title('Compare all models and Tests')
set(gca,'FontSize', 18)

% add all model types
mktypes = {'*' 'o' 'v' '^' 's'};
for m=1:length(mtype)
    hold on
    scatter(dv(m,:), A(m,:), 150, mktypes{m})
end
hold off

legend({'125ms haversine line' mtype{:}}, 'location', 'nw')
