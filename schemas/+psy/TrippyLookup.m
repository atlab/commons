%{
psy.TrippyLookup (lookup)    # cached noise maps to save computation time
version           : smallint                      # algorithm version; increment when code changes
paramhash         : char(10)                      # hash of the lookup parameters
---
params              : blob       # cell array of params
movie               : longblob   # [y,x,frames]
ts=CURRENT_TIMESTAMP: timestamp  # automatic
%}

classdef TrippyLookup < dj.Relvar
    properties(Constant)
        table = dj.Table('psy.TrippyLookup')
    end
    
    methods(Static)
        function img = upsample(img)
            assert(all(mod(size(img),2)==0))
            k = [0 3 8 10 8 3]'/32;
            img = conv2(2*cat(1, zeros(1,size(img,1)), upsample(fold(img'),2)),k,'valid');
            img = conv2(2*cat(1, zeros(1,size(img,1)), upsample(fold(img'),2)),k,'valid');
            function im = fold(im)
                im = cat(1, (im(1,:)+im(2,:))/2, im, (im(end,:)+im(end-1,:))/2);
            end
        end
        
    end
        
    
    methods
        function [m, key] = lookup(self, cond, degxy, fps)
            % make noise stimulus movie  and update condition
            % INPUTS:
            %   cond  - condition parameters
            %   degxy - visual degrees across x and y
            %   fps   - frames per second
            
            key.version = 1;  % increment if you make any changes to the code below
            
            params = {cond degxy fps};
            hash = dj.DataHash(params);
            key.paramhash = hash(1:10);
            
            if count(psy.TrippyLookup & key)
                m = fetch1(self & key, 'movie');
            else
                % create gaussian movie
                r = RandStream.create('mt19937ar','NormalTransform', ...
                    'Ziggurat', 'Seed', cond.rng_seed);
                nFrames = round(cond.duration*fps/2)*2;
                sz = [cond.control_points, cond.control_points, nFrames];
                m = r.randn(sz);  % movie                
                upsamples = ceil(log2(max(cond.tex_xdim, cond.tex_ydim))-log(cond.control_points));
                
                % apply temporal filter in time domain
                % Use hamming filter for most compact kernel
                semi = round(fps/cond.temp_bandwidth);
                k = hamming(semi*2+1);
                k = k/sum(k);
                m = convn(m, permute(k, [3 2 1]), 'same');
                
                % apply spatial filter in frequency space
                [y, x] = ndgrid(...
                    (-sz(1)/2:sz(1)/2-1)/sz(1)*degxy(2), ...
                    (-sz(2)/2:sz(2)/2-1)/sz(2)*degxy(1));
                radius = 2*sqrt(y.*y + x.*x)*cond.spatial_freq_stop;
                kernel = (0.46*cos(pi*radius) + 0.54).*(radius<1);  % hamming kernel
                kernel = fftn(kernel);
                m = fftn(m);
                m = bsxfun(@times, m, kernel);
                
                % normalize to [-1 1]
                result = real(ifftn(m));                % back to spacetime
                scale = quantile(abs(result(:)), 1-1e-5);
                m = m/scale;
                result = result/scale;
                sigma = std(result(:));
                
                % modulate orientation
                [fy,fx] = ndgrid(...
                    (-sz(1)/2:sz(1)/2-1)/degxy(2), ...
                    (-sz(2)/2:sz(2)/2-1)/degxy(1));   % in units of cy/degree
                directions = (r.randperm(cond.n_dirs)-1)/cond.n_dirs*2*pi;
                onsets = nan(size(directions));
                offsets =  nan(size(directions));
                frametimes = (0:nFrames-1)'/fps;
                theta = ifftshift(atan2(fx,fy));
                speed = zeros(size(frametimes));
                for i=1:cond.n_dirs
                    q = theta + directions(i);
                    space_bias = hann(q, cond.ori_bands*2*pi/cond.n_dirs);
                    biased = real(ifftn(bsxfun(@times, space_bias, m)));
                    biased = result + cond.ori_modulation*(biased*sigma/std(biased(:)) - result);
                    biased = sigma/std(biased(:))*biased;
                    onsets(i) = (i-0.5)*period - cond.ori_on_secs/2;
                    offsets(i) = (i-0.5)*period + cond.ori_on_secs/2;
                    mix = abs(frametimes - (i-0.5)*(period)) < cond.ori_on_secs/2;  % apply motion in the middle
                    speed = speed - mix*exp(-1i*directions(i));
                    mix = abs(frametimes - (i-0.5)*(period)) < (period-semi/fps)/2;   % apply orientation bias always
                    mix = conv(double(mix),k,'same');
                    result = result + bsxfun(@times, biased-result, permute(mix,[3 2 1]));
                end
                m = result;
                clear result
                
                % apply motion
                offset = cumsum(speed*cond.speed/fps);
                for i=1:sz(3)
                    shift = ifftshift(exp(...
                        -2i*pi*fx*imag(offset(i)) ...
                        -2i*pi*fy*real(offset(i))));
                    f = fft2(m(:,:,i)).*shift;
                    m(:,:,i) = real(ifft2(f));
                end
                
                % save results
                m = max(-1, min(1, m)).*(abs(m)>0.001);
                m = uint8((m+1)/2*253)+1;
                
                tuple = key;
                stim.frametimes = frametimes;
                stim.direction = directions;
                stim.onsets = onsets;
                stim.offsets = offsets;
                
                tuple.params = [params {stim}];
                tuple.cached_movie = m;
                
                self.insert(tuple)
            end
        end
    end
    
end


function y = hann(q, width)
% circuar hanning mask with symmetric opposite lobes
q = (mod(q + pi/2,pi)-pi/2)/width;
y = (0.5 + 0.5*cos(q*pi)).*(abs(q)<1);
end