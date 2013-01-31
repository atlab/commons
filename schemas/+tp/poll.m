% tp.poll - check if there is something to populate periodically and
% populate it.

function poll(cycle, varargin)
while true
    tic
    disp(['checking for stuff to populate  '  datestr(clock)])
    switch cycle
        case 1
            parpopulate(tp.Align,     varargin{:})
            
        case 2
            parpopulate(tp.Sync,    varargin{:})
            parpopulate(tp.OriDesign, varargin{:}, tp.CaOpt)
            parpopulate(tp.OriMap,  varargin{:})
            parpopulate(tp.VonMap,  varargin{:})
            parpopulate(tp.Cos2Map, varargin{:})
            
        case 3
            parpopulate(tp.Ministack, varargin{:})
            parpopulate(tp.VonMap,  varargin{:})
            parpopulate(tp.Cos2Map, varargin{:})
            
        case 4
            parpopulate(tp.FineAlign, varargin{:})
            parpopulate(tp.Motion3D,  varargin{:})
            
        case 5
            parpopulate(tp.FreqMap, varargin{:})
            
        case 6
            parpopulate(tp.FineOriMap, varargin{:})
            parpopulate(tp.FineVonMap, varargin{:})
            
        case 7
            parpopulate(tp.Extract)
            
            
    end
    waitTime = 600-2*toc;
    if waitTime > 0
        fprintf('Paused for %d:%d...\n', floor(waitTime/60), floor(mod(waitTime,60)))
        pause(waitTime)
    end
end