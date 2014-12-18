classdef NaturalMovie < stims.core.Visual
    
    properties
        nBlocks = 1
        
        params = struct(...
            'type',    'nat',        ... natural or phase scrambled
            'luminance',   5,           ... cd/m^2
            'contrast',    0.95,        ... Michelson's 0-1
            'movie_path', '~/Desktop/', ...file path for the movies
            'movie_number',   7,           ... (int) the number of movie
            'aperture_radius', 0.63, ...  % in units of half-diagonal, 0=no aperture
            'aperture_x', 0, ... % 0=center, in units of half-diagonal
            'aperture_y', 0, ... % 0=center, in units of half-diagonal
            'frame_downsample', 2,      ... 1=60 fps, 2=30 fps, 3=20 fps, 4=15 fps, etc
            'duration', 10,          ... (s) trial duration
            'pre_blank', 1 ... (s) pre trial blank duration 
            )
    end
    
    
    methods
        function d = degPerPix(self)
            % assume isometric pixels
            d = 180/pi*self.constants.monitor_size*2.54/norm(self.rect(3:4))/self.constants.monitor_distance;
        end
        
        
        function init(self, varargin)
            init@stims.core.Visual(self, varargin{:});
            if ~isfield(self.conditions, 'movie')
                % pre-compute movies
                disp 'making movies'
                
                movies = cell(size(self.conditions));
                for iCond=1:length(self.conditions)
                    fprintf .
                    cond = self.conditions(iCond);
                    movies{iCond} = ...
                        stims.NaturalMovie.makeMovie(cond, self.screen.fps/cond.frame_downsample);
                end
                fprintf \n
                [self.conditions(:).movie] = deal(movies{:});
            end
        end
    end
    
    methods(Access=protected)
        
        function showTrial(self, cond)
            % execute a single trial with a single cond
            % See PsychToolbox DriftDemo4.m for API calls
            assert(~isnan(self.constants.monitor_distance), 'monitor distance is not set')
            
            assert(all(ismember({
                'type'
                'luminance'
                'contrast'
                'movie_path'
                'movie_number'
                'aperture_radius'
                'aperture_x'
                'aperture_y'
                'frame_downsample'
                'duration'
                'pre_blank'
                'movie'
                }, fieldnames(cond))))
            
            % display black syn photodiode rectange during the pre blank
            if cond.pre_blank>0
                % display black photodiode rectangle during the pre-blank
                self.flip(false, false, true)
                WaitSecs(cond.pre_blank);
            end
%             self.screen.setContrast(cond.luminance, cond.contrast)
            self.frameStep = cond.frame_downsample;
            self.saveAfterEachTrial = true;
            for i=1:size(cond.movie,3)
                if self.escape, break, end
                tex = Screen('MakeTexture', self.win, cond.movie(:,:,i));
                Screen('DrawTexture',self.win, tex, [], self.rect)
                self.flip(false, false, i==1)
            end
        end
    end
    
    
    
    methods(Static)
        function m = makeMovie(cond, fps)
            % load movie 
            % INPUTS:
            %   cond  - condition parameters
            %   fps   - frames per second
            
            % create gaussian movie
            nFrames = round(cond.duration*fps/2)*2;
            % load movie
            movie_name = [cond.movie_path 'mov' num2str(cond.movie_number) '_' cond.type '.avi'];
            movieObj = VideoReader(movie_name);
            sz = get(0,'screensize'); sz = sz(3:4);
            for ii = 1:nFrames
                temp_img = read(movieObj,ii);
                temp_img = temp_img(:,:,1);
                m(:,:,ii) = imresize(temp_img,[sz(2),sz(1)]);
            end
            
        end
        
    end
end