%{
psy.MovieStill (imported) # cached still frames from the movie
-> psy.MovieStillStore
still_id        : int                    # ids of still images from the movie
---
still_frame                 : longblob                      # uint8 grayscale movie
%}

classdef MovieStill < dj.Relvar 

	methods

		function makeTuples(self, key)            
            [template, fps] = fetch1(psy.MovieInfo & key, ...
                'path_template', 'frame_rate');
            id = 0;
            decimateFactor = fps/2;  % 2 frames per second
            for i = 1:1e9
                filename = sprintf(template, i);
                if ~exist(filename, 'file')
                    break;
                end
                v = VideoReader(filename); %#ok<TNMLP>
                while(v.hasFrame)
                    for j = 1:decimateFactor
                        frame = v.readFrame();
                        if ~v.hasFrame
                            break
                        end
                    end
                    [~, ~, frame] = rgb2hsv(frame);
                    if id && ~mod(id,10)
                        fprintf('%d ', id);
                        if ~mod(id,200)
                            fprintf \n
                        end
                    end
                    id = id+1;
                    key.still_id = id;
                    key.still_frame = uint8(frame*255);
                    self.insert(key);
                end
            end
		end
	end

end
