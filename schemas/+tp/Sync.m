%{
tp.Sync (imported) # stimulus synchronization
-> tp.Align
-----
-> psy.Session
first_trial : int   # first trial matching scan
last_trial  : int   # last trial matching scan
frame_times : longblob   # mean frame times on stimulus clock
sync_ts = CURRENT_TIMESTAMP : timestamp    # automatic
%}

classdef Sync < dj.Relvar & dj.Automatic
    
    properties(Constant)
        table = dj.Table('tp.Sync')
        popRel = tp.Align
    end
    
    methods
        function self = Sync(varargin)
            self.restrict(varargin)
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            f = getFilename(common.TpScan(key));
            scim = neurosci.scanimage.Reader(f{1});
            phd = scim.readPhotodiode;
            fps = fetch1(tp.Align(key), 'fps');
            nlines = scim.hdr.acq.linesPerFrame;
            [times, psyId] = neurosci.dsp.FlipCode.synch(phd', fps*nlines, psy.Trial(key));
            
            key.psy_id = psyId;
            [trialIds, flipTimes] = fetchn(psy.Trial(key), 'trial_idx', 'flip_times');
            ix = cellfun(@(x) any(x>=times(1) & x<=times(end)), flipTimes);
            trialIds = trialIds(ix);
            
            
            key.frame_times = times(ceil(nlines/2):nlines:end);  
            assert(length(key.frame_times) == fetch1(tp.Align(key), 'nframes'));
            key.first_trial = min(trialIds);
            key.last_trial = max(trialIds);
            self.insert(key)
        end
    end
end
