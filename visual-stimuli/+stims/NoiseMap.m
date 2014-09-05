classdef NoiseMap < stims.core.Visual
    
    properties
        nBlocks = 1
        
        params = struct(...
            'rng_seed',    1:80,        ... RNG seed
            'luminance',   5,           ... cd/m^2
            'contrast',    0.95,        ... Michelson's 0-1
            'tex_ydim',    64,          ... (pixels) texture dimension
            'tex_xdim',    80,          ... (pixels) texture dimension
            'spatial_freq_half', 0.05,  ... (cy/deg) spatial frequency modulated to 50
            'spatial_freq_stop',0.2,    ... (cy/deg), spatial lowpass cutoff
            'temp_bandwidth',4,         ... (s) temporal decay
            'contrast_mod_freq', 0.1, ... (Hz) raised cosine contrast modulation
            'frame_downsample', 2,      ... 1=60 fps, 2=30 fps, 3=20 fps, 4=15 fps, etc
            'duration', 10              ... (s) trial duration
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
                    if ~self.DEBUG
                        assert(cond.tex_xdim/self.rect(3)==cond.tex_ydim/self.rect(4), ...
                            'noise texture aspect ratio must match the monitor aspect ratio')
                    end
                    movies{iCond} = ...
                        stims.NoiseMap.makeMovie(cond, self.degPerPix*self.rect(3:4), self.screen.fps/cond.frame_downsample);
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
                'rng_seed'
                'luminance'
                'contrast'
                'tex_ydim'
                'tex_xdim'
                'spatial_freq_half'
                'spatial_freq_stop'
                'temp_bandwidth'
                'contrast_mod_freq'
                'duration'
                'frame_downsample'
                'movie'
                }, fieldnames(cond))))
            
            self.screen.setContrast(cond.luminance, cond.contrast)
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
        function m = makeMovie(cond, degxy, fps)
            % make noise stimulus
            % INPUTS:
            %   cond  - condition parameters
            %   degxy - visual degrees across x and y
            %   fps   - frames per second
            
            % create gaussian movie
            r = RandStream.create('mt19937ar','NormalTransform', 'Ziggurat', 'Seed', cond.rng_seed);
            nFrames = round(cond.duration*fps/2)*2;
            sz = [cond.tex_ydim, cond.tex_xdim, nFrames];
            assert(~any(bitand(sz,1)), 'all movie dimensions must be even')
            m = r.randn(sz);  % movie
            
            % apply spatial filter in frequency space
            m = fftn(m);
            [fy,fx] = ndgrid(...
                (-sz(1)/2:sz(1)/2-1)/degxy(2), ...
                (-sz(2)/2:sz(2)/2-1)/degxy(1));
            fxy = ifftshift(sqrt(fy.^2 + fx.^2));  % radial frequency
            fxy = (fxy<cond.spatial_freq_stop)./(1+fxy/cond.spatial_freq_half);  % 1/f filter
            m = bsxfun(@times, m, fxy);
            
            % apply temporal filter in frequency space
            fz = ifftshift((-sz(3)/2:sz(3)/2-1)/sz(3)*fps);
            fz = reshape(fz, 1, 1, []);
            fz = exp(-fz.^2/2/cond.temp_bandwidth.^2);
            m = bsxfun(@times, m, fz);
            
            % apply temporal modulation
            m = ifftn(m);
            z = (0:sz(3)-1)/fps;
            z = cos(2*pi*z*cond.contrast_mod_freq);
            z = 1./(1+exp(1*z));
            z = reshape(z, 1, 1, []);
            m = bsxfun(@times, m, z);
            
            % normalize movie to [-1 1];
            m = m/quantile(abs(m(:)), 1-1e-5);
            m = max(-1, min(1, m)).*(abs(m)>0.001);
            m = uint8((m+1)/2*254);
        end
    end
end