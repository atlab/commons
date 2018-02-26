%{
reso.TrialTraceSet (computed) # group of traces in each trial
-> reso.Segment
-> reso.TrialSet
-----
trial_times  :  longblob  # time points relative to trial onset at which to sample traces
%}

classdef TrialTraceSet < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('reso.TrialTraceSet')
        popRel = reso.Segment * reso.TrialSet
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            % compute sample points for trial traces
            tuple = key;
            secondsBefore = 1.0;
            secondsAfter  = 1.0;
            
            dt = 1/fetch1(reso.ScanInfo & key, 'fps');
            dt = dt/2; % upsample
            [durations] = fetchn(reso.Trial & key, 'offset-onset->duration');
            tuple.trial_times = dt*((-ceil(secondsBefore/dt)):ceil((max(durations)+secondsAfter)/dt));
            self.insert(tuple)
           
            % populate trial traces
            for key = fetch(reso.Trace & key)'
                fprintf .
                makeTuples(reso.TrialTrace, key)
            end
            fprintf \n
        end
    end
end
