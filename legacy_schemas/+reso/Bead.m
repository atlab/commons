%{
reso.Bead (imported) # beads extracted from bead scan
-> reso.BeadStack
bead_idx  : smallint  #  bead number in the stack
-----
dx   : float   # (um) pixel pitch
dy   : float   # (um) pixel pitch
dz   : float   # (um) slice pitch
psf_stack  : longblob # stack embedding the bead
center_x  : float   # pixel coordinate
center_y  : float   # pixel coordinate
center_z  : float   # pixel coordinate
base_x    : float   # base intensity in x projection
base_y    : float   # base intensity in y projection
base_z    : float   # base intensity in z projection
amplitude_x    : float   # bead iintensity in x projection
amplitude_y    : float   # bead iintensity in y projection
amplitude_z    : float   # bead iintensity in z projection
sigma_x : float  # full width at half magnitude
sigma_y : float  # full width at half magnitude
sigma_z : float  # full width at half magnitude
xi      : longblob # (um) x-projection coordinates
yi      : longblob # (um) y-projection coordinates
zi      : longblob # (um) z-projection coordinates
proj_x  : longblob # x projection
proj_y  : longblob # x projection
proj_z  : longblob # x projection
%}

classdef Bead < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('reso.Bead')
        popRel = reso.BeadStack
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            [p,f] = fetch1(reso.BeadStack & key,'path','full_filename');
            reader = reso.reader(getLocalPath(fullfile(p,f)));
            assert(~reader.hdr.fastZActive, 'fast Z must be inactivated')
            stack = 0;
            while ~reader.done
                fprintf .
                stack = stack + getfield(reader.read(1,1:reader.nSlices,1),'channel1'); %#ok<GFLD>
            end
            fprintf \n
            sz = size(stack);
            tuple = key;
            tuple.dx = fetch1(reso.BeadStack & key, 'fov_x')/sz(2);
            tuple.dy = fetch1(reso.BeadStack & key, 'fov_y')/sz(1);
            tuple.dz = abs(reader.hdr.stackZStepSize);
            
            params.wavelength = fetch1(reso.BeadStack & key, 'wavelength');
            params.NA = fetch1(reso.BeadStack & key, 'na');
            params.spacing =  [1.0 1.0 4.0];
            params.showFigures = false;
            params.numpsfs = 50;
            params.thresh = 0.2;
            
            img = mean(stack,3);
            img = max(0,img - quantile(img(:),0.001));
            img = min(1,img / quantile(img(:),0.999));
            imshow(1-img), drawnow
            figure(gcf)
            
            [psf,~,sigma,center,base,amplitude,proj] = ...
                ne7.micro.PSF.compute(stack, [tuple.dx tuple.dy tuple.dz], params);
            
            for i=1:length(psf)
                if ~isempty(psf{i})
                    tuple.bead_idx = i;
                    tuple.psf_stack = int16(psf{i});
                    tuple.sigma_x = sigma(1,i);
                    tuple.sigma_y = sigma(2,i);
                    tuple.sigma_z = sigma(3,i);
                    tuple.center_x = center(1,i);
                    tuple.center_y = center(2,i);
                    tuple.center_z = center(3,i);
                    tuple.base_x = base(1,i);
                    tuple.base_y = base(2,i);
                    tuple.base_z = base(3,i);
                    tuple.amplitude_x = amplitude(1,i);
                    tuple.amplitude_y = amplitude(2,i);
                    tuple.amplitude_z = amplitude(3,i);
                    tuple.xi = proj{1,i}(:,1);
                    tuple.yi = proj{2,i}(:,1);
                    tuple.zi = proj{3,i}(:,1);
                    tuple.proj_x = proj{1,i}(:,2);
                    tuple.proj_y = proj{2,i}(:,2);
                    tuple.proj_z = proj{3,i}(:,2);
                    self.insert(tuple)
                end
            end
        end
    end
    
    
    methods
        function plot(self, savePath)
            % plot PSFs and save PNGs if savePath is provided
            
            doPrint = nargin>=2;
            cmap = 1-gray;
            gauss = @(x,base,amp,center,sigma) base+amp*exp(-(x-center).^2/sigma^2/2)/sqrt(2*pi)/sigma;
            for key=fetch(self)'
                
                [na, wavelength] = fetch1(reso.BeadStack & key, 'na', 'wavelength');
                optSigmaX = ne7.micro.PSF.sigmaX(na, wavelength);
                optSigmaZ = ne7.micro.PSF.sigmaZ(na, wavelength);
                
                
                clf
                [stack, xi, yi, zi] = fetch1(reso.Bead & key, ...
                    'psf_stack', 'xi', 'yi', 'zi');
                
                % Z projection
                subplot 231
                zmarg = mean(stack,3);
                zmarg = zmarg - min(zmarg(:));
                zmarg = zmarg / max(zmarg(:));
                image(xi,  yi, size(cmap,1)*zmarg)
                colormap(cmap)
                xlabel 'x (um)'
                ylabel 'y (um)'
                title 'Z projection'
                axis image
                
                
                % x and z projections
                subplot 234
                [px,py,bx,by,cx,cy,ax,ay,sx,sy] = fetch1(reso.Bead & key, ...
                    'proj_x','proj_y','base_x','base_y','center_x','center_y',...
                    'amplitude_x','amplitude_y','sigma_x','sigma_y');
                plot(xi, px, 'rx')
                hold on
                plot(yi, py, 'gv')
                plot(xi,  exp(-xi.^2/2/optSigmaX.^2), '--', 'Color',[0.3 0.3 0.3])
                plot(xi,gauss(xi,bx,ax,cx,sx),'r')
                plot(yi,gauss(yi,by,ay,cy,sy),'g')
                axis tight
                legend('x-axis', 'y-axis','ideal','location','South')
                legend boxoff
                hold off
                box off
                title(sprintf( '\\omega_x=%1.2f, \\omega_y=%1.2f, \\omega_{ideal}=%1.2f', ...
                    sqrt(2)*sx, sqrt(2)*sy, sqrt(2)*optSigmaX))
                xlabel 'x (um)'
                ylabel 'magnitude'
                
                % X projection
                subplot 232
                xmarg = squeeze(mean(stack,2));
                xmarg = xmarg - min(xmarg(:));
                xmarg = xmarg / max(xmarg(:));
                image(yi, zi, size(cmap,1)*xmarg')
                colormap(cmap)
                xlabel 'y (um)'
                ylabel 'z (um)'
                title 'X projection'
                axis image
                
                % Y projection
                subplot(233);
                ymarg = squeeze(mean(stack,1));
                ymarg = ymarg - min(ymarg(:));
                ymarg = ymarg / max(ymarg(:));
                image(xi, zi, size(cmap,1)*ymarg')
                colormap(cmap)
                xlabel 'x (um)'
                ylabel 'z (um)'
                title 'Y projection'
                axis image
                
                subplot(2,3,5:6)
                [pz,bz,cz,az,sz] = fetch1(reso.Bead & key, ...
                    'proj_z','base_z','center_z','amplitude_z','sigma_z');
                
                plot(zi, pz, 'o')
                hold on
                plot(zi,  exp(-(zi-cz).^2/2/optSigmaZ.^2), '--', 'Color',[0.3 0.3 0.3])
                plot(zi, gauss(zi,bz,az,cz,sz))
                xlabel 'z (um)'
                ylabel 'magnitude'
                hold off
                box off
                title(sprintf('\\omega_z=%1.2f, \\omega_{ideal}=%1.2f', sqrt(2)*sz, sqrt(2)*optSigmaZ))
                
                [setup,ddate,lens] = fetch1(reso.BeadStack & key, 'setup','date','lens');
                suptitle({sprintf('Setup %d, %s lens %dx NA=%1.2g, %d nm. -bead #%d',...
                    setup,ddate,lens,na,wavelength,key.bead_idx),...
                    strrep(fetch1(reso.BeadStack & key, 'full_filename'),'_','\_')});
                if doPrint
                    set(gcf, 'PaperUnits', 'inches', 'PaperSize', [8,6], 'PaperPosition',[0,0,8,6])
                    file= fullfile(savePath,...
                        sprintf('PSF_%dx_%s_%d_%d.png', lens, ddate, key.stack_num, key.bead_idx));
                    fprintf('Saving %s\n', file)
                    print('-dpng', file)
                end
            end
        end
    end
end
