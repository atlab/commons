%{
reso.ScanInfo (imported) # header information
-> common.TpScan

-----
nframes_requested           : smallint                       # number of valumes (from header)
px_width                    : smallint                      # pixels per line
px_height                   : smallint                      # lines per frame
um_width                    : float                         # width in microns
um_height                   : float                         # height in microns
bidirectional               : tinyint                       # 1=bidirectional scanning
fps                         : float                         # (Hz) frames per second
zoom                        : decimal(4,1)                  # zoom factor
dwell_time                  : float                         # (us) microseconds per pixel per frame
nchannels                   : tinyint                       # number of recorded channels
nslices                     : tinyint                       # number of slices
slice_pitch                 : float                         # (um) distance between slices
%}

classdef ScanInfo < dj.Relvar & dj.AutoPopulate
    
    properties
        popRel = common.TpScan * common.TpSession & 'tp_session_date > "2013-09"'
    end
    
    methods
        function copySource(self, destFolder)
            for key = self.fetch'
                reader = reso.getReader(key);
                src = fullfile(getLocalPath(reader.path),[reader.base '*']);
                % create directory
                [~,dname] =  fileparts(reader.path);
                dname = fullfile(destFolder,dname);
                if ~exist(dname,'dir')
                    mkdir(dname)
                end
                copyfile(src,dname)
            end
        end
    end
    
    
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            reader = reso.getReader(key);
            
            assert(reader.hdr.acqNumAveragedFrames == 1, 'averaging should be off')
            assert(strcmp(reader.hdr.fastZImageType,'XY-Z'),'we assume XY-Z scanning')
            
            key.nframes_requested = ...
                reader.hdr.fastZActive*reader.hdr.fastZNumVolumes + ...
                (1-reader.hdr.fastZActive)*reader.hdr.acqNumFrames;
            key.px_height = reader.hdr.scanLinesPerFrame;
            key.px_width  = reader.hdr.scanPixelsPerLine;
            fov = fetch1(common.TpSession & key, 'fov');
            zoom = reader.hdr.scanZoomFactor;
            key.um_height = fov/zoom*reader.hdr.scanAngleMultiplierSlow;
            key.um_width  = fov/zoom*reader.hdr.scanAngleMultiplierFast;
            if reader.hdr.fastZActive
                key.fps =  1/reader.hdr.fastZPeriod;
                key.slice_pitch = reader.hdr.stackZStepSize;
            else
                key.fps = reader.hdr.scanFrameRate;
                key.slice_pitch = 0;
            end
            
            key.bidirectional = ~strncmpi(reader.hdr.scanMode, 'uni', 3);
            key.zoom = zoom;
            key.dwell_time = reader.hdr.scanPixelTimeMean*1e6;
            key.nchannels = length(reader.hdr.channelsSave);
            key.nslices = reader.hdr.stackNumSlices;
            if key.nslices == 1
                key.fps = reader.hdr.scanFrameRate;
            end
            
            self.insert(key)
        end
    end
end
