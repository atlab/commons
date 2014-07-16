%{
reso.Indicator (computed) # indicator functions for different reso.Conditions
-> reso.IndicatorSet
-> reso.Conditions
---
indicator                   : longblob                      # nframes logical vector for condition
%}

classdef Indicator < dj.Relvar & dj.AutoPopulate
    
    properties
        popRel = reso.IndicatorSet
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            for cond = fetch(reso.Conditions,'*')'
                if exists(reso.Align & key & eval(cond.condition_pop_str))
                    ft = fetch1(reso.EphysTime & key,'frame_ephys_time');
                    tuple = key;
                    switch cond.condition_name
                        case 'quiet dilating'
                            [vt,fs]=fetch1(patch.Ephys & key,'ephys_time','ephys_fs');
                            isActive = self.getActive(key,vt,fs);
                            pupilR = self.getPupil(key,vt,fs);
                            indicator = gradient(pupilR) > quantile(abs(gradient(pupilR)),.33) & ~isActive;
                            tuple.indicator = logical(interp1(vt,single(indicator),ft,'nearest'));
                            
                        case 'quiet constricting'
                            [vt,fs]=fetch1(patch.Ephys & key,'ephys_time','ephys_fs');
                            isActive = self.getActive(key,vt,fs);
                            pupilR = self.getPupil(key,vt,fs);
                            indicator = gradient(pupilR) < -1 * quantile(abs(gradient(pupilR)),.33) & ~isActive;
                            tuple.indicator = logical(interp1(vt,single(indicator),ft,'nearest'));
                            
                        case 'quiet'
                            [vt,fs]=fetch1(patch.Ephys & key,'ephys_time','ephys_fs');
                            isActive = self.getActive(key,vt,fs);
                            indicator = ~isActive;
                            tuple.indicator = logical(interp1(vt,single(indicator),ft,'nearest'));
                            
                        case 'active'
                            [vt,fs]=fetch1(patch.Ephys & key,'ephys_time','ephys_fs');
                            isActive = self.getActive(key,vt,fs);
                            indicator = isActive;
                            tuple.indicator = logical(interp1(vt,single(indicator),ft,'nearest'));
                            
                        otherwise
                            error('unkown condition name ''%s''', cond.condition_name)
                    end
                    self.insert(tuple);
                end
            end
        end
    end
    methods(Static)
        function isActive=getActive(key,vt,fs)
            %Running
            [runOn,runDur,runVel]=fetchn(patch.Running & key ,'run_on','run_dur','run_vel');
            isActive=false(size(vt));
            for q=1:length(runOn)
                isActive(ts2ind(runOn(q),vt,1/fs):ts2ind(runOn(q)+runDur(q),vt,1/fs))=1;
            end
            
            %Whisking/Facing
            if exists(patch.Whisker & key & 'whisker_quality>=2')
                % Whisker
                [whiskOn,whiskDur,whiskAmp]=fetchn(patch.Whisking & key ,'whisk_on','whisk_dur','whisk_amp');
                isWhisking=false(size(vt));
                for q=1:length(whiskOn)
                    isWhisking(ts2ind(whiskOn(q),vt):ts2ind(whiskOn(q)+whiskDur(q),vt))=1;
                end
                isActive = isActive | isWhisking;
            else
                % Face
                [faceOn,faceDur,faceAmp]=fetchn(patch.Facing & key,'face_on','face_dur','face_amp');
                isFacing=false(size(vt));
                for q=1:length(faceOn)
                    isFacing(ts2ind(faceOn(q),vt):ts2ind(faceOn(q)+faceDur(q),vt))=1;
                end
                isActive = isActive | isFacing;
            end
            isActive = isActive(:)';
        end
        
        function ri = getPupil(key,vt,fs)
            [x,y,r,et,blink]=fetchn(patch.EyeFrame & key,'pupil_x','pupil_y','pupil_r','frame_time','isblink');
            ri = interp1(et(~isnan(r)),r(~isnan(r)),vt);
            ri = ezfilt(ri,1,fs,'lowhamming');
            ri=ri(:)';
        end
    end
end

