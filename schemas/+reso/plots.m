classdef plots  < handle
    
    properties(Abstract)
        neverInstantiateThisClass
    end
    
    methods(Static)
        function OriMap(varargin)
            for caKey = fetch(reso.CaOpt & (reso.Cos2Map & varargin))'
                for siteKey = fetch(reso.Align & (reso.Cos2Map & varargin))'
                    key = dj.struct.join(caKey, siteKey);
                    g = fetch1(reso.Align & key, 'green_img');
                    [amp, r2, ori, p] = fetchn(reso.Cos2Map & key, ...
                        'cos2_amp', 'cos2_r2', 'pref_ori', 'cos2_fp');
                    
                    % add a black line at the bottom of each figure
                    p = cellfun(@(x) cat(1,x,nan(3,size(x,2))), p, 'uni',false);
                    amp = cellfun(@(x) cat(1,x,nan(3,size(x,2))), amp, 'uni',false);
                    ori = cellfun(@(x) cat(1,x,nan(3,size(x,2))), ori, 'uni',false);
                    r2 = cellfun(@(x) cat(1,x,nan(3,size(x,2))), r2, 'uni',false);
                    
                    % make composite image
                    p = cat(1,p{:});
                    amp = cat(1,amp{:});
                    r2 = cat(1,r2{:});
                    ori = cat(1,ori{:});
                    
                    h = mod(ori,pi)/pi;   % orientation is represented as hue
                    s = p<0.01;   % only significantly tuned pixels are shown in color
                    v = ones(size(p));  % brightness is proportional to variance explained, scaled between 0 and 10 %
                    img = hsv2rgb(cat(3, h, s, v));
                    image(img)
                    axis image
                    
                    title(sprintf('Mouse %d scan %d caOpt=%u', key.animal_id, key.scan_idx, key.ca_opt))
                    
                    f = sprintf('~/dev/figures/reso/cos2map_%05d_%03d_%02d', ...
                        key.animal_id, key.scan_idx, key.ca_opt);
                    set(gcf, 'PaperSize', [8 8], 'PaperPosition', [0 0 8 8])
                    print('-dpng', f, '-r150')
                end
            end
        end
        
        
        
        function TraceVonMises(varargin)
            
        end
        
    end
    
    
end