function waitForMemory(GiB, seconds)
% wait until requested amount of memory becomes available.

if nargin < 2
    seconds = 10;
end

persistent mem

while true
    free = ne7.sys.getFreeMemory;
    if isempty(mem)
        mem = min(free, free/2+exprnd(free/4));
    else
        mem = min(free, (mem*3+free)/4);  % increase available memory gradually
    end
    if mem > GiB
        break
    end
    sec = min(180,round(exprnd(seconds*(GiB-mem))));
    fprintf(':: Requested memory %3.1f GiB :: Available %3.1f GiB :: Pausing for%4d seconds ::\n', GiB, mem, sec)
    pause(sec)
end