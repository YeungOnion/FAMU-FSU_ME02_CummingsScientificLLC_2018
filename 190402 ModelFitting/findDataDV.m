% loads data and integrates to find dv values

newDV = zeros(1,11);
for dataNum = 1:11
    [t, accel, timpact, duration, dV] = loadDat(dataNum);
    inds = timpact < t & t < timpact+duration;
    tt = t(inds);
    cg = -accel(inds,11) + mean(accel(1:2e3,11)); % remove 0 offset w avg
    newDV(dataNum) = trapz(tt, cg)*32.2*3600/5280/1000;
end

fprintf('%.3f ', newDV); % put this output into loadDat for alldeltaV