%{
psy.NoiseMapLookup (lookup) # cached noise maps to save computation time
noise_map_version           : smallint                      # algorithm version; increment when code changes
noise_map_paramhash         : char(10)                      # hash of the lookup parameters
---
noise_map_params            : blob   # cell array of params
cached_movie                : longblob                      # [y,x,frames]
noise_map_lookup_ts=CURRENT_TIMESTAMP: timestamp            # automatic
%}

classdef NoiseMapLookup < dj.Relvar
    properties(Constant)
        table = dj.Table('psy.NoiseMapLookup')
    end
    
    methods
        function [m, key] = lookup(self, cond, degxy, fps)
            % make noise stimulus movie  and update condition
            % INPUTS:
            %   cond  - condition parameters
            %   degxy - visual degrees across x and y
            %   fps   - frames per second
            
            key.noise_map_version = 1;  % increment if you make any changes to the code below
            
            params = {cond degxy fps};
            hash = dj.DataHash(params);
            key.noise_map_paramhash = hash(1:10);
            
            if count(psy.NoiseMapLookup & key)
                m = fetch1(self & key, 'cached_movie');
            else
                % create gaussian movie
                r = RandStream.create('mt19937ar','NormalTransform', ...
                    'Ziggurat', 'Seed', cond.rng_seed);
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
                
                tuple = key;
                tuple.noise_map_params = params;
                tuple.cached_movie = m;
                
                self.insert(tuple)
            end
        end
    end
    
end
