function poll(cycle, varargin)
while true   
    tic
    disp(['checking for stuff to populate  '  datestr(clock)])
    if cycle == 1
        parpopulate(tp.Align,     varargin{:})
    end
    if cycle == 2
        parpopulate(tp.Sync,    varargin{:})
        parpopulate(tp.OriMap,  varargin{:})
        parpopulate(tp.VonMap,  varargin{:})
    end
    if cycle == 3
        parpopulate(tp.Ministack, varargin{:})
        parpopulate(tp.Motion3D,  varargin{:})
    end
    waitTime = 600-2*toc;
    if waitTime > 0 
        fprintf('Paused for %d:%d...\n', floor(waitTime/60), floor(mod(waitTime,60)))
        pause(waitTime)
    end
end 