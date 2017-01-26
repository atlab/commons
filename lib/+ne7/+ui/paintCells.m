function bw = paintCells(bw)
% lets the user outline objects in the image on the current axis

global r % dot radius
r = 3;  

sz = axis;
sz = round([sz(4)-sz(3), sz(2)-sz(1)]);
if nargin<1 || isempty(bw)
    bw = false(sz);
end
assert(size(bw,1)==sz(1) && size(bw,2)==sz(2))


outlines = {};
undoBuffer = {bw};

% Plot
h = figure('NumberTitle','off',...
    'Name','Paint cells',...
    'KeyPressFcn',@dispkeyevent,...
    'WindowScrollWheelFcn', @doScroll);

printInstructions

function dispkeyevent(~, event)

switch event.Key
    case 1
        bw(enumeratePixels) = true;
        redraw
    case 2
        bw(enumeratePixels) = false;
        redraw
    case 'backspace'
        % UNDO
        if length(undoBuffer)>=2
            bw = undoBuffer{end-1};
            undoBuffer(end-1:end) = [];
            redraw
        end
    case 'space'  % SPACE - toggle outlines
        if isempty(outlines)
            redraw
        else
            removeOutlines
        end
    case 'leftbracket'
        h=findobj(gcf,'type','image');
        set(h,'cdata',get(h,'cdata')*.9)
    case 'rightbracket'
        h=findobj(gcf,'type','image');
        set(h,'cdata',get(h,'cdata')*1.1)
    case 'escape'
        yes = questdlg('Do you wish to abort segmenting this image?','Finish segmentation', 'yes','no','no');
        if strcmpi('yes', yes)
            bw = [];  % destroy mask
            return
        end
    case 'return'
        yes = questdlg('Ready to commit?','Finish segmentation', 'yes','no','no');
        if strcmpi('yes', yes)
            return
        end
    otherwise
        disp(['key: "' event.Key '" not assigned!'])
        disp '---'
        printInstructions
end
end

function doScroll(~,e)
    winsz = 32;
    if e.VerticalScrollCount<0
        if r~=1
            r = r-1;
        end
    elseif e.VerticalScrollCount>0
        if winsz/2 ~= r
            r = r+1;
        end
    end
    sz = 32;
    c = nan(winsz,winsz);
    [gy, gx] = meshgrid(1:winsz1:winsz);
    data = (gx(:) - winsz2).^2 + (gy(:) - winsz/2).^2;
    idx =  data < r^2 & data > floor(r*0.8)^2;
    c(idx) = 2;
    set(gcf,'PointerShapeCData',c,'pointer','custom')
end

function idx = enumeratePixels
idx = [];
for xi=round(x+(-r:r))
    for yi=round(y+(-r:r))
        if (xi-x)^2 + (yi-y)^2 < r^2*0.64 && ...
                yi>=1 && yi<=sz(1) && ...
                xi>=1 && xi<=sz(2)
            idx(end+1) = sub2ind(sz,yi,xi); %#ok<AGROW>
        end
    end
end
end


function removeOutlines
% delete old outlines
for i=1:length(outlines)
    if ishandle(outlines{i})
        delete(outlines{i})
    end
end
outlines = {};
end

function redraw
removeOutlines
if isempty(undoBuffer)
    return
end
if ~all(undoBuffer{end}(:)==bw(:))
    % buffer only if modified
    undoBuffer = [undoBuffer(max(1,end-30):end) {bw}];  % append but limit buffer size
end
bounds = bwboundaries(bw,4);
hold on
for i=1:length(bounds)
    bound = bounds{i};
    outlines{i} = plot(bound(:,2), bound(:,1), 'r');
end
hold off
end

function printInstructions
disp INSTRUCTIONS:
disp 'Click to add pixels to mask'
disp 'Shift-click to delete pixels from mask'
disp 'Press BACKSPACE to undo'
disp 'Press 1-9 to set brush size'
disp '[ to reduce brightness'
disp '] to increase brightness'
disp 'Press SPACE to toggle outlines'
disp 'Press ESC to discard all edits'
disp 'Press ENTER to commit'
end

end