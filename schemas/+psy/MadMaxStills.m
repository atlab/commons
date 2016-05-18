%{
psy.MadMaxStills (lookup) # cache of static frame from Mad Max
madmax_still_id  : int   # index of the selected still image
-----
still_image :  longblob  
%}

classdef MadMaxStills < dj.Relvar
    
    methods
        function fill(self, template, decimate)
            s = dir(template);
            id = 0;
            for s=s'
                v = VideoReader(fullfile(fileparts(template), s.name)); %#ok<TNMLP>
                decimator = 0;
                while(v.hasFrame)
                    frame = v.readFrame();
                    decimator = decimator + 1;
                    if decimator < decimate
                        continue;
                    end
                    decimator =0;
                    [~, ~, frame] = rgb2hsv(frame);
                    if ~mod(id,10)
                        fprintf('%d ', id);
                        if ~mod(id,200)
                            fprintf \n
                        end
                    end
                    id = id+1;
                    self.insert({id  uint8(255*frame)});
                end
            end
        end
    end
end