%{
reso.Indicator (computed) # indicator functions for different reso.Conditions
-> reso.Align
-> reso.EphysTime
-> reso.Conditions
-----
indicator       : longblob      # nframes logical vector
%}

classdef Indicator < dj.Relvar & dj.AutoPopulate
    
    properties
        popRel = reso.Align * reso.Conditions * reso.EphysTime
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            if isempty(fetch(reso.Align & key & eval(fetch1(reso.Conditions & key,'condition_pop_str'))))
                return
            end
            
            ft = fetch1(reso.EphysTime & key,'frame_ephys_time');
            
            switch fetch1(reso.Conditions & key, 'condition_name')
                case 'quiet dilating'
                    [vt,fs]=fetch1(patch.Ephys & key,'ephys_time','ephys_fs');
                    isActive = self.getActive(key,vt,fs);
                    pupilR = self.getPupil(key,vt,fs);
                    indicator = gradient(pupilR) > quantile(abs(gradient(pupilR)),.33) & ~isActive;
                    tuple = key;
                    tuple.indicator = logical(interp1(vt,single(indicator),ft,'nearest'));
                    self.insert(tuple);
                    
                case 'quiet constricting'
                    [vt,fs]=fetch1(patch.Ephys & key,'ephys_time','ephys_fs');
                    isActive = self.getActive(key,vt,fs);
                    pupilR = self.getPupil(key,vt,fs);
                    indicator = gradient(pupilR) < -1 * quantile(abs(gradient(pupilR)),.33) & ~isActive;
                    tuple = key;
                    tuple.indicator = logical(interp1(vt,single(indicator),ft,'nearest'));
                    self.insert(tuple);
                    
                case 'quiet'
                    [vt,fs]=fetch1(patch.Ephys & key,'ephys_time','ephys_fs');
                    isActive = self.getActive(key,vt,fs);
                    indicator = ~isActive;
                    tuple = key;
                    tuple.indicator = logical(interp1(vt,single(indicator),ft,'nearest'));
                    self.insert(tuple);
                    
                case 'active'
                    [vt,fs]=fetch1(patch.Ephys & key,'ephys_time','ephys_fs');
                    isActive = self.getActive(key,vt,fs);
                    indicator = isActive;
                    tuple = key;
                    tuple.indicator = logical(interp1(vt,single(indicator),ft,'nearest'));
                    self.insert(tuple);
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

