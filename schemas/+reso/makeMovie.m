function makeMovie(key)
assert(count(reso.Align & key)==1 && count(reso.OriMap & key & 'ca_opt=1')==1 && count(reso.Segment & key)==1, 'exactly one movie with one slice is required')

frameRate = 30;
speedUp = 5;
filename = sprintf('~/dev/movies/cmovie-%04d-%03d', key.animal_id, key.scan_idx);
writer = VideoWriter(filename, 'MPEG-4');
writer.Quality = 100;
writer.FrameRate = frameRate;
writer.open

reader = getReader(reso.Align & key);
xymotion = fetch1(reso.Align & key, 'motion_xy');

% extract pixels for each trace
origFPS = fetch1(reso.ScanInfo & key, 'fps');
disp 'making the movie'
dfactor = round(origFPS*speedUp/frameRate);
blockSize = round(500/dfactor)*dfactor;
[rasterPhase, fillFraction] = fetch1(reso.Align & key, ...
    'raster_phase', 'fill_fraction');
mx = nan;
[hue,sat] = makeOriMap(setfield(key,'ca_opt',1));

while ~reader.done
    gblock = getfield(reader.read(1, 1:reader.nSlices, blockSize),'channel1'); %#ok<GFLD>
    %    rblock = getfield(reader.read(2, 1:reader.nSlices, blockSize),'channel2'); %#ok<GFLD>
    xy = xymotion(:,:,1:size(gblock,4));
    xymotion(:,:,1:size(gblock,4)) = [];
    gblock = reso.Align.correctRaster(gblock, rasterPhase, fillFraction);
    gblock = reso.Align.correctMotion(gblock, xy);
    %    rblock = reso.Align.correctRaster(rblock, rasterPhase, fillFraction);
    %    rblock = reso.Align.correctMotion(rblock, xy);
    bgScale = 0.5;
    if isnan(mx)
        frame = median(gblock,4);
        med = median(frame(:));
        bg = imfilter(frame,fspecial('gaussian',151,40),'symmetric');
        bg = bgScale*anscombe(bg,med);
        frame = anscombe(frame,med)-bg;
    end
    lims = quantile(frame(:),[0.02 0.999]);
    
    % temporal smoothing
    gblock = bsxfun(@minus, anscombe(gblock, med), bg);
    for i=1:size(gblock,4)
        d = gblock(:,:,:,i)-frame;
        c = abs(imfilter(d,fspecial('gaussian',21,8), 'symmetric'));
        c = c./mean(c(:))/dfactor;
        gblock(:,:,:,i) = frame + d.*max(0.05, min(1-(sign(d)==-1)/dfactor,c/3));
    end
    %downsample 
    gblock = reshape(gblock,size(gblock,1),size(gblock,2),[]);
    gblock = gblock(:,:,ceil(dfactor/2):dfactor:end);
    
    %scale
    gblock = max(0, gblock - lims(1));
    gblock = min(1, gblock/diff(lims));    
    
    for i=1:size(gblock,3)
        img = uint8(hsv2rgb(cat(3,hue,sat,gblock(:,:,i)))*255);
        writer.writeVideo(img)
    end
    fprintf .
end
fprintf \n
writer.close

disp compressing..
system(sprintf('ffmpeg -i %s.mp4 -y %s-compressed.mp4', filename, filename));
%delete([filename '.mp4'])
disp done
end

function x = anscombe(x,d)
x = sqrt(max(0,x + 0.1*d));
end



function [h,s] = makeOriMap(key)
[amp, ori] = fetch1(reso.Cos2Map & key, ...
    'cos2_amp', 'pref_ori');
h = mod(ori,pi)/pi;   % orientation is represented as hue
s = max(0, min(1, amp/0.25));   % only significantly tuned pixels are shown in color
end