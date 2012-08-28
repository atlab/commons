function poll(cycle, varargin)

dj.schedule.clear
dj.schedule.add

parpopulate(tp.Sync,    varargin{:})
parpopulate(tp.OriMap,  varargin{:})
parpopulate(tp.VonMap,  varargin{:})

% run every 10 minutes
dj.schedule.run(180, 90)