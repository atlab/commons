classdef plots  < handle
    
    properties(Abstract)
        neverInstantiateThisClass
    end
    
    methods(Static)
        
        function astroPupil
            for key = fetch(reso.SegmentGlia*reso.Sync*patch.Eye & patch.EyeFrame & reso.TraceGlia)'
                % compute constriction fluorescences
                times = fetch1(reso.Sync & key, 'frame_times');
                traces = fetchn(reso.TraceGlia & key, 'ca_trace');
                
                [pupilRadius, pupilX, pupilY, pupilTimes] = fetchn(patch.EyeFrame & key, ...
                    'pupil_r','pupil_x','pupil_y','frame_time','ORDER BY frame_time');
                pupilFPS = 1/median(diff(pupilTimes));

                % interpolate over nans
                notnans = ~isnan(pupilRadius);
                pupilRadius = interp1(pupilTimes(notnans),pupilRadius(notnans), pupilTimes, 'linear', 'extrap');
                
                % establish running epochs
                [runOn,runDur]=fetchn(patch.Running & key, 'run_on', 'run_dur');
                [faceOn,faceDur]=fetchn(patch.Facing & key, 'face_on', 'face_dur');
                [runOn, runDur] = mergeIntervals([runOn; faceOn], [runDur; faceDur]);
                
                % a trial is considered dilating if the pupil is bigger
                % at the end than at the beginning
                onRad = interp1(pupilTimes, pupilRadius, trialOnsets, 'nearest', 'extrap');
                offRad = interp1(pupilTimes, pupilRadius, trialOffsets, 'nearest', 'extrap');
                select = offRad > onRad;
                select = xor(select, strcmp(opt.condition,'constricting'));
                
                % exclude running periods
                runFrac = arrayfun(@(on,dur) fracOverlap(on, dur, runOn, runDur),...
                    trialOnsets, trialOffsets-trialOnsets);
                select = select & runFrac == 0;

                % convert to vis stim time
                [eTime,vTime] = fetch1(patch.Ephys*patch.Sync & key, 'ephys_time','vis_time');
                conOn = interp1(eTime,vTime,conOn,'linear','extrap');
                dilOn = interp1(eTime,vTime,dilOn,'linear','extrap');
                
                % compute averages
                dil = cellfun(@(trace) ...
                    arrayfun(@(on,dur) mean(trace(times>on & times<on+dur+5)), dilOn, dilDur), ...
                    traces, 'uni', false);
               
                % compute averages
                con = cellfun(@(trace) ...
                    arrayfun(@(on,dur) mean(trace(times>on & times<on+dur+5)), conOn, conDur), ...
                    traces, 'uni', false);
                
                scatter(cellfun(@nanmean, con),cellfun(@nanmean, dil))
                refline(1)
                
            end
        end
        
        
        function OriMap(varargin)
            for key = fetch(reso.Cos2Map & varargin)'
                g = fetch1(reso.Align & key, 'green_img');
                g = double(g);
                g = g - 0.8*imfilter(g,fspecial('gaussian',201,70));
                g = max(0,g-quantile(g(:),0.005));
                g = min(1,g/quantile(g(:),0.99));
                [amp, r2, ori, p] = fetchn(reso.Cos2Map & key, ...
                    'cos2_amp', 'cos2_r2', 'pref_ori', 'cos2_fp');
                
                % add a black line at the bottom of each figure
                if false
                    p = cellfun(@(x) cat(1,x,nan(3,size(x,2))), p, 'uni',false);
                    amp = cellfun(@(x) cat(1,x,nan(3,size(x,2))), amp, 'uni',false);
                    ori = cellfun(@(x) cat(1,x,nan(3,size(x,2))), ori, 'uni',false);
                    r2 = cellfun(@(x) cat(1,x,nan(3,size(x,2))), r2, 'uni',false);
                end
                
                % make composite image
                p = cat(1,p{:});
                amp = cat(1,amp{:});
                r2 = cat(1,r2{:});
                ori = cat(1,ori{:});
                
                h = mod(ori,pi)/pi;   % orientation is represented as hue
                s = max(0, min(1, amp/0.1));   % only significantly tuned pixels are shown in color
                v = g;  % brightness is proportional to variance explained, scaled between 0 and 10 %
                img = hsv2rgb(cat(3, h, s, v));
                image(img)
                axis image
                axis off
                
                title(sprintf('Mouse %d scan %d caOpt=%u', key.animal_id, key.scan_idx, key.ca_opt))
                
                f = sprintf('~/dev/figures/pupil/cos2map-%05d-%03d-%02d.png', ...
                    key.animal_id, key.scan_idx, key.ca_opt);
                imwrite(img,f,'png')
            end
        end
    end
end