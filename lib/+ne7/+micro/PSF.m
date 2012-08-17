classdef PSF
    
    properties(Constant)
        % override any of these in the params structure
        defaultParams = struct( ...
            'NA',       0.8,  ...        % numerical aperture for ideal considerations
            'wavelength', 890, ...       % laser wavelength
            'numpsfs',  50,   ...        % maximum number of psfs fo extract
            'thresh',   0.25,  ...        % the amplitude threshold of beads as a fraction of max max peak
            'spacing',  [0.75 0.75 2.0], ... % (um) xyz distance in each direction to include in the space around the PSFs
            'colormap', 1-gray(256), ... % colormap to use for plots
            'showFigures', true, ...     % if false, return the results without plotting figures
            'printPNG', false, ...       %
            'title',    '', ...   % string to add to the titles of the figures
            'baseName', 'untitled_PSF_stack' ...
            )
        
        % Theoretical PSF widths adapted from
        % W. R. Zipfel, R. M. Williams, and W. W. Webb. Nonlinear magic: multiphoton microscopy in the biosciences. Nat Biotechnol, 21(11):1369?77, Nov 2003.
        Nwater  = 1.333   % index of refraction for water
        sigmaX = @(na,lambda) 0.325/2*lambda/1000/na^0.91
        sigmaZ = @(na,lambda) 0.532/2*lambda/1000/(neu.PSF.Nwater - sqrt(neu.PSF.Nwater^2 - na^2))
    end
    
    
    
    methods(Static)
        
        function scim(scimFile, FOV, params)
            % process beads from the scanimage tiff file
            % FOV is the field of view for the given objective at zoom=1.0
            % -- the scan magnification is extracted from the tiff file.
            %
            % EXAMPLE:
            %  neu.PSF.scim('psf-16x-800nm003.tif', 864, struct('NA',0.8, 'wavelength', 800, 'printPNG', true, 'title', '16x objective'))
            
            if nargin<3
                params = neu.PSF.defaultParams;
            end
            
            if ~isfield(params, 'baseName')
                params.baseName = scimFile;
            end
            
            disp 'reading tiff...'
            scim = neu.Scim(scimFile);
            assert(scim.hdr.acq.fastScanningX==1 && scim.hdr.acq.fastScanningY==0, ...
                'the fast scan must be along X')
            
            zoom =  scim.hdr.acq.baseZoomFactor*scim.hdr.acq.zoomFactor;
            dx = FOV/zoom/scim.hdr.acq.pixelsPerLine*scim.hdr.acq.scanAngleMultiplierFast;
            dy = FOV/zoom/scim.hdr.acq.linesPerFrame*scim.hdr.acq.scanAngleMultiplierSlow;
            dz = abs(scim.hdr.acq.zStepSize);
            neu.PSF.compute(scim.read(1), [dx,dy,dz], params);
        end
        
        
        function [psfs,fwhm,sigmas] = compute(stack, pitch, params)
            % PSF.extract - extract point spread functions and their
            % properties from a stack containing beads.
            %
            % INPUTS:
            %   stack - a 3d stack with dimensions y,x,z
            %   pitch - um per pixel in x, y, z dimensions
            %   params - additional parameters overwriting PSF.defaultParams
            %
            % OUTPUTS:
            %   psfs - 3d mini-stacks centered on beads
            %   fwhm - full width at half magnitude along [x, y, z]
            %   sigmas - PSF sigma along [x, y, z]
            
            % process input parameters
            stack = double(stack);
            assert(all(ismember(fieldnames(params), fieldnames(neu.PSF.defaultParams'))), ...
                'Unknown parameter. See PSF.defaultParams')
            for f = setdiff(fieldnames(neu.PSF.defaultParams),fieldnames(params))'
                params.(f{1}) = neu.PSF.defaultParams.(f{1});
            end
            assert(isnumeric(pitch) && length(pitch)==3, ...
                'The second argument must contain the pixel pitch as [x,y,z]')
            
            % re-order xyz->yxz to make matlab happy
            sz = size(stack);
            pitch  = pitch([2 1 3]);   % xyz -> yzx to make matlab happy
            params.spacing = params.spacing([2 1 3]);  % xyz -> yzx to make matlab happy
            
            if params.showFigures
                % plot the z projection of entire stack
                figure
                temp = sqrt(max(0,max(stack,[],3)));  % equalize variance, expand dynamic range
                image((1:sz(2))*pitch(2),(1:sz(1))*pitch(1), size(params.colormap,1)*temp/max(temp(:)));
                colormap(params.colormap);
                title(sprintf('%s max z-projection', params.title));
                xlabel 'x (um)'
                ylabel 'y (um)'
                
                if params.printPNG
                    subplot 111
                    set(gcf, 'PaperUnits', 'inches', 'PaperSize', [8 8], 'PaperPosition', [0 0 8 8])
                    pdfFile=sprintf('%s_zmax.png', params.baseName);
                    fprintf('Saving %s\n', pdfFile)
                    print('-dpng', pdfFile)
                end
            end
            
            
            % extract spaces around peaks
            s = smoothStack(stack);
            s = s/max(s(:));  %normalize the image
            
            psfs   = cell(1,params.numpsfs);
            fwhm   = zeros(1,params.numpsfs);
            sigmas = zeros(1,params.numpsfs);
            for iPSF=1:params.numpsfs
                [amp,idx] = max(s(:));
                if amp<params.thresh
                    disp 'no more peaks'
                    break
                end
                % extract PSF
                a = round(params.spacing./pitch);
                [ys,xs,zs] = ind2sub(sz, idx);  % the coordinates of the peak in the smoothed stack
                
                % blot out the neighborhood of the extracted blob
                s(max(1,ys-2*a(1)):min(end,ys+2*a(1)),...
                    max(1,xs-2*a(2)):min(end,xs+2*a(2)),...
                    max(1,zs-2*a(3)):min(end,zs+2*a(3)))=0;
                
                if ys-a(1)<1 || ys+a(1)>size(stack,1) || ...
                        xs-a(2)<1 || xs+a(2)>size(stack,2) || ...
                        zs-a(3)<1 || zs+a(3)>size(stack,3)
                    continue
                end
                
                psfs{iPSF} = stack(...
                    ys-a(1):ys+a(1),...
                    xs-a(2):xs+a(2),...
                    zs-a(3):zs+a(3));
                
                % compute marginals, FWHMs, and resolutions
                xmarg = squeeze(mean(psfs{iPSF},2))';
                xmarg = xmarg/max(xmarg(:));
                ymarg = squeeze(mean(psfs{iPSF},1))';
                ymarg = ymarg/max(ymarg(:));
                zmarg = squeeze(mean( psfs{iPSF},3));
                zmarg = zmarg/max(zmarg(:));
                
                xymarg = mean(ymarg,2);  xymarg=xymarg-quantile(xymarg,0.10); xymarg = xymarg/max(xymarg);
                yzmarg = mean(zmarg,1);  yzmarg=yzmarg-quantile(yzmarg,0.10); yzmarg = yzmarg/max(yzmarg);
                xzmarg = mean(xmarg,1);  xzmarg=xzmarg-quantile(xzmarg,0.10); xzmarg = xzmarg/max(xzmarg);
                
                xi = (-(length(yzmarg)-1)/2:(length(yzmarg)-1)/2)*pitch(2);
                yi = (-(length(xzmarg)-1)/2:(length(xzmarg)-1)/2)*pitch(1);
                zi = (-(length(xymarg)-1)/2:(length(xymarg)-1)/2)*pitch(3);
                
                % robust fit to gaussian curve
                gauss = @(a, x) a(4)+a(3)*exp(-(x-a(1)).^2/a(2)^2/2)/sqrt(2*pi)/a(2);
                beta0 = [0 1 1 0];
                bx = nlinfit(xi, yzmarg, gauss, beta0, struct('Robust','on'));
                by = nlinfit(yi, xzmarg, gauss, beta0, struct('Robust','on'));
                bz = nlinfit(zi, xymarg',gauss, beta0, struct('Robust','on'));
                
                fwhm(1,iPSF) = 2*bx(2)*sqrt(2*log(2));
                fwhm(2,iPSF) = 2*by(2)*sqrt(2*log(2));
                fwhm(3,iPSF) = 2*bz(2)*sqrt(2*log(2));
                
                sigmas(1,iPSF) = bx(2);
                sigmas(2,iPSF) = by(2);
                sigmas(3,iPSF) = bz(2);
                
                % visualize PSFs
                if params.showFigures
                    clf
                    
                    % Z projection
                    subplot 231
                    image(xi,  yi, size(params.colormap,1)*zmarg)
                    colormap(params.colormap)
                    xlabel 'x (um)'
                    ylabel 'y (um)'
                    title 'Z projection'
                    axis image
                    
                    optSigmaX = neu.PSF.sigmaX(params.NA, params.wavelength);
                    optSigmaZ = neu.PSF.sigmaZ(params.NA, params.wavelength);
                    
                    % xz and yz marginals
                    subplot 234
                    plot(xi, yzmarg, 'rx')
                    hold on
                    plot(yi, xzmarg, 'gv')
                    plot(xi,  exp(-xi.^2/2/optSigmaX.^2), '--', 'Color',[0.3 0.3 0.3])
                    plot(xi,gauss(bx,xi),'r')
                    plot(yi,gauss(by,yi),'g')
                    legend('x-axis', 'y-axis','ideal','location','South')
                    legend boxoff
                    hold off
                    box off
                    title(sprintf( '\\omega_x=%1.2f, \\omega_y=%1.2f, \\omega_{ideal}=%1.2f', ...
                        sqrt(2)*sigmas(1,iPSF), sqrt(2)*sigmas(2,iPSF), sqrt(2)*optSigmaX))
                    xlabel 'x (um)'
                    ylabel 'magnitude'
                    
                    % X projection
                    subplot 232
                    image(xi, zi, size(params.colormap,1)*xmarg)
                    colormap(params.colormap)
                    xlabel 'y (um)'
                    ylabel 'z (um)'
                    title 'X projection'
                    axis image
                    
                    % Y projection
                    subplot(233);
                    image(yi, zi, size(params.colormap,1)*ymarg)
                    colormap(params.colormap)
                    xlabel 'x (um)'
                    ylabel 'z (um)'
                    title 'Y projection'
                    axis image
                    
                    subplot(2,3,5:6)
                    plot(zi, xymarg, 'o')
                    hold on
                    plot(zi,  exp(-zi.^2/2/optSigmaZ.^2), '--', 'Color',[0.3 0.3 0.3])
                    plot(zi, gauss(bz,zi))
                    xlabel 'z (um)'
                    ylabel 'magnitude'
                    hold off
                    box off
                    title(sprintf('\\omega_z=%1.2f, \\omega_{ideal}=%1.2f', sqrt(2)*sigmas(3,iPSF), sqrt(2)*optSigmaZ))
                    
                    suptitle(sprintf('NA=%1.2g, %d nm. "%s" -bead #%d',params.NA, params.wavelength, params.title, iPSF));
                    if params.printPNG
                        set(gcf, 'PaperUnits', 'inches', 'PaperSize', [8,6], 'PaperPosition',[0,0,8,6])
                        pdfFile= sprintf('%s_PSF%02d.png', params.baseName, iPSF );
                        fprintf('Saving %s\n', pdfFile)
                        print('-dpng', pdfFile)
                    end
                end
            end
        end
    end
end





function m = smoothStack( m )
k = hamming(7); k = k/sum(k);
m = imfilter(imfilter(m, k, 'symmetric'), k', 'symmetric');
end