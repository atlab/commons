%{
reso.Sync (computed) # one-to-one mapping to patch recordings
-> reso.Align
-----
-> psy.Session
first_trial :   int         # first trial in recording
last_trial :    int         # last trial in recording
frame_times : longblob    # times of frames and slices
%}

classdef Sync < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('reso.Sync')
        popRel = common.TpScan & pro(patch.Recording * patch.Sync)
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            % borrow synchronization from matching patch.Session
            patchKey = key;
            patchKey.file_num = key.scan_idx;
            if exists(patch.Recording & patchKey)
                key = fetch(reso.Align*psy.Session & key & (patch.Sync & patchKey));
                assert(length(key) == 1)
                
                % find frame pulses
                [p,f] = fetch1(patch.Session*patch.Recording & patchKey,'path','filename');
                filename = getLocalPath(fullfile(p,f));
                dat = patch.utils.readPatchStimHD5(filename);
                datT = patch.utils.ts2sec(dat.ts);
                dt = median(diff(datT));
                n = ceil(0.0002/dt);
                k = hamming(2*n);
                k = k/sum(k);
                k(1:n) = -k(1:n);
                
                pulses = conv(dat.stimPd,k,'same');
                peaks = ne7.dsp.spaced_max(pulses, 0.005/dt);
                peaks = peaks(pulses(peaks) > 0.1*quantile(pulses(peaks),0.9));
                
                [requestedFrames, recordedFrames] = ...
                    fetch1(reso.ScanInfo * reso.Align & key, 'nframes_requested*nslices->n1', 'nframes*nslices->n2');
                
                assert(ismember(length(peaks), [requestedFrames, recordedFrames]),...
                    'Could not detect frame pulses')
                
                [stimTimes, firstTrial, lastTrial] = fetch1(patch.Sync & patchKey, ...
                    'vis_time','first_trial','last_trial');
                key.frame_times = stimTimes(peaks);
                key.first_trial = firstTrial;
                key.last_trial = lastTrial;
                
                self.insert(key)
            end
        end
    end
end
