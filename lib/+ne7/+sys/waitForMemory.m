function waitForMemory(GiB, seconds)

while true
    free = ne7.sys.getFreeMemory;
    if free >= GiB
        break
    end
    fprintf('%3.1f GiB memory available. Waiting to get %3.1f\n', free, GiB)
    pause(seconds)
end
