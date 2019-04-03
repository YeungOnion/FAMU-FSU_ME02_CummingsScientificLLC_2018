function datout = movAvgFilt(dat,n)
%MOVAVGFILT is a moving average filter
N = size(dat,1);
assert(N>n); assert(size(dat,2)==1);
T = toeplitz(1:N, [1 N:-1:N-n+2]);
T(1:ceil(n/2),:) = [];

datout = [dat(1:n-2); mean(dat(T),2)];
end

