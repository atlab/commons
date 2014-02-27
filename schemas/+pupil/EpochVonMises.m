%{
pupil.EpochVonMises (computed) # directional tuning conditioned on pupil phase
-> pupil.EpochVonMisesSet
-> reso.Trace
-----
responses : longblob  # table with 2 columns: directions and responses
von_r2    : float     # r-squared of response
von_pref  : float     # (radians) preferred direciton
von_base  : float     # response in anti-preferred orientation
von_amp1  : float     # response in preferred direction
von_amp2  : float     # response in anti-preferred direction
von_sharp : float     # tuning sharpness
von_p : float     # p-value computed by shuffling
%}

classdef EpochVonMises < dj.Relvar
    
    methods
        
        function makeTuples(self, key)
            
            disp 'fetching trials...'
            trialTimes = fetch1(reso.TrialTraceSet & key, 'trial_times');
            s = fetch(pupil.EpochTrial*reso.TrialTrace*psy.Trial*psy.Grating & key, ...
                'direction', 'trial_trace');
            
            disp 'integrating responses...'
            interval = trialTimes > 0 & trialTimes < trialTimes(end)-0.8;
            s = arrayfun(@(s) setfield(s, 'response', sum(s.trial_trace(interval))), s); %#ok<SFLD>
            [responses, traceIds, directions] = dj.struct.tabulate(s, ...
                'response','trace_id','direction');
            assert(all(directions == 0:360/length(directions):359))
            
            disp 'computing von Mises tuning ...'
            nShuffles = fetch1(pupil.EpochVonMisesSet & key, 'nshuffles');
            [von, r2, p] = ne7.rf.VonMises2.computeSignificance(responses, nShuffles);
            
            % report results
            for i=1:length(traceIds)
                tuple = key;
                tuple.trace_id = traceIds(i);
                tuple.von_r2  = r2(i);
                tuple.responses = single(responses(i,:,:));
                tuple.von_base = von.w(i,1);
                tuple.von_amp1 = von.w(i,2);
                tuple.von_amp2 = von.w(i,3);
                tuple.von_sharp = von.w(i,4);
                tuple.von_pref = von.w(i,5);
                tuple.von_p = p(i);
                
                self.insert(tuple)
            end
        end
    end
end
