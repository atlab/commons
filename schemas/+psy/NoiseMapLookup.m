%{
psy.NoiseMapLookup (lookup) # cached noise maps to save computation time
noise_map_version           : smallint                      # algorithm version; increment when code changes
rng_seed                    : double                        # random number generate seed
luminance                   : decimal(5,2)                  # (cd/m^2)
contrast                    : decimal(6,3)                  # michelson contrast
tex_ydim                    : smallint                      # (pixels) texture dimension
tex_xdim                    : smallint                      # (pixels) texture dimension
degrees_x                   : decimal(6,3)                  # (degrees) monitor width 
degrees_y                   : decimal(6,3)                  # (degrees) monitor height
spatial_freq_half           : decimal(6,4)                  # (cy/deg) spatial frequency modulated to 50%
spatial_freq_stop           : decimal(6,4)                  # (cy/deg), spatial lowpass cutoff
temp_bandwidth              : decimal(6,4)                  # (Hz) temporal bandwidth of the stimulus
contrast_mod_freq           : decimal(6,5)                  # (Hz) raised cosine contrast modulation (used only in version 2)
frame_downsample            : tinyint                       # 1=60 fps, 2=30 fps, 3=20 fps, 4=15 fps, etc
duration                    : decimal(6,3)                  # (s) trial duration
contrast_slope              : decimal(6,4)                  # onset slope
modulation_shift            : decimal(4,3)                  # shift of the signamoid argument (cosine value)
fps                         : decimal(6,2)                  # full frame rate of display before downsampling 
---
cached_movie                : longblob                      # [y,x,frames]
noise_map_lookup_ts=CURRENT_TIMESTAMP: timestamp            # automatic
%}

classdef NoiseMapLookup < dj.Relvar
    
    methods
        function [m, condition] = lookup(self, condition, degxy, fps)
            % make noise stimulus movie  and update condition
            % INPUTS:
            %   cond  - condition parameters
            %   degxy - visual degrees across x and y
            %   fps   - frames per second
            
            attrs = {'rng_seed','tex_ydim','tex_xdim','spatial_freq_half','spatial_freq_stop', ...
                'temp_bandwidth', 'contrast_mod_freq', 'frame_downsample', ...
                'duration','contrast_slope','modulation_shift'};
            
            assert(all(ismember(fieldnames(cond),attrs)), 'extra attributes')
            assert(all(ismember(attrs,fieldnames(cond))), 'missing attributes')

            % round everything to types 
            cond.version = 1;
            cond.degrees_x = round(degxy(1)*1000)/1000;
            cond.degrees_y = round(degxy(2)*1000)/1000;
            clear degxy
            cond = self.roundFields(cond);
            
            if count(psy.NoiseMapLookup & key)
                m = fetch(psy.NoiseMap & key, 'cached_movie');
            else
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
                z = (-(sz(3)-1)/2:(sz(3)-1)/2)/fps;
                z = cos(2*pi*z*cond.contrast_mod_freq);
                z = 1./(1+exp(-cond.contrast_slope*(z+cond.modulation_shift)));
                z = reshape(z, 1, 1, []);
                m = bsxfun(@times, m, z);
                
                % normalize movie to [-1 1];
                m = m/quantile(abs(m(:)), 1-1e-5);
                m = max(-1, min(1, m)).*(abs(m)>0.001);
                m = uint8((m+1)/2*254);
                key.cached_movie = m;
                insert(psy.NoiseMapLookup, key)
            end
        end
    end
    
end
