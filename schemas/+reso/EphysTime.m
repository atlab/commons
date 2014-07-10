%{
reso.EphysTime (imported) # frame times on ephys clock
-> reso.Align
-> patch.Ephys
---
frame_ephys_time                 : longblob            # times of frames on patch.Ephys clock
ephys_time_ts = CURRENT_TIMESTAMP  : timestamp         # automatic
%}

classdef EphysTime < dj.Relvar & dj.AutoPopulate
    
    properties
        popRel = reso.Align * pro(patch.Ephys,'(file_num)->scan_idx')
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            
            % Get file
            f = fetch1(patch.Recording & key,'filename');
            p = fetch1(patch.Session & key,'path');
            [~,hostname] = system('hostname'); hostname = hostname(1:end-1);
            
            F = getLocalPath(fullfile(p,f));             
            if ~exist(F,'file')
                error(['Can''t find ' F])
            end
            
            % Read data and fetch ephys_time
            [dat,~,ver] = patch.utils.readPatchStimHD5(F);
            vt = fetch1(patch.Ephys & key,'ephys_time');
            
            % For HD5 file versions before ver 6, scanimage sync is saved on stim photodiode channel
            if ver < 6
                frameEdges = diff(conv(dat.stimPd,ones(1,10),'same'));
            elseif ver >= 6
                frameEdges = diff(conv(dat.scanImage,ones(1,10),'same'));
            end
            
            % Find rising edge
            frameInd = find(frameEdges>std(frameEdges));
            frameInd(find(diff(frameInd)==1)+1)=[];
            
            % Limit to length(frameInd) in case patch recording stopped before scan
            % Limit to recordedFrames in case a second scan or stack was started without stopping the patch recording
            [requestedFrames, recordedFrames] = ...
               fetch1(reso.ScanInfo * reso.Align & key, 'nframes_requested*nslices->n1', 'nframes*nslices->n2');
            frameInd = frameInd(1:min(length(frameInd),recordedFrames));
            
            % Plot detection
%             figure
%             jplot(frameEdges)
%             hold on
%             plot(frameInd,ones(size(frameInd))*std(frameEdges),'gx')
%             title([num2str(length(frameInd)) ' frames detected.  ' num2str(recordedFrames) ' frames recorded'])
%             drawnow
%             pause(1)

            % Insert tuple
            key.frame_ephys_time = vt(frameInd);
            self.insert(key);
        end
    end
end