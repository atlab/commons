function run(menu, key)

% blank the screen and set default luminance
stims.core.Visual.screen.open;
stims.core.Visual.screen.setContrast(3, 0.5);

% get user input
ch = ' ';
protocol = [];
while ch~='q'
    FlushEvents
    ch = GetChar;
    fprintf('Pressed %c\n', ch)
    if ch=='q'
        break
    elseif ismember(ch, '1':char('0'+length(menu)))
        protocol = menu(str2double(ch));
        fprintf('Selected stimulus %c\n', ch);
        initProtocol(protocol, key)
        disp 'ready to run'        
    elseif ch=='r' && ~isempty(protocol)
        runProtocol(protocol)
    end
end
stims.core.Visual.screen.close
end


function initProtocol(protocol, key)
init(protocol.logger, key, protocol.constants);
rect = stims.core.Visual.screen.rect;
if ~stims.core.Visual.DEBUG && any([protocol.constants.resolution_x protocol.constants.resolution_y] ~= rect(3:4))
    disp 'Mismatching screen size'
    fprintf('Stimulus specifies [%d,%d]\n', protocol.constants.resolution_x, protocol.constants.resolution_y)
    fprintf('Screen resolution is [%d,%d]\n', rect(3), rect(4))
    stims.core.Visual.screen.close
    error 'incorrect screen resolution'
else
    assert(iscell(protocol.stim), 'protocol.stim must be a cell array of structures')
    for stim = protocol.stim(:)'
        stim{1}.init(protocol.logger, protocol.constants)
    end
end
end


function runProtocol(protocol)
screen = stims.core.Visual.screen;

% open parallel pool for trial inserts
if isempty(gcp('nocreate'))
    parpool('local',1);
end

if ~stims.core.Visual.DEBUG
    HideCursor;
    Priority(MaxPriority(screen.win)); % Use realtime priority for better temporal precision:
end

% merge conditions from all display classes into one array and
% append field obj_ to conditions to point back to the displaying class
allConditions = cellfun(@(stim) arrayfun(@(r) r, ...
    dj.struct.join(stim.conditions, struct('obj_', stim)), ...
    'uni', false), protocol.stim, 'uni', false);
allConditions = cat(1, allConditions{:});

% configure photodiode flips
screen.clearFlipTimes;   % just in case
screen.setFlipCount(protocol.logger.getLastFlip)

screen.escape;   % clear the escape
for iBlock = 1:protocol.blocks
    for iCond = randperm(length(allConditions))
        cond = dj.struct.join(allConditions{iCond}, protocol.constants);
        screen.flip(true, false, true)  % clear screen        
        screen.frameStep = 1;  % reset to full frame rate
        if screen.escape, break, end
        cond.obj_.showTrial(cond)     %%%%%% SHOW STIMULUS
        if screen.escape, break, end
        fprintf .        
        protocol.logger.logTrial(struct(...
            'cond_idx', cond.cond_idx, ...
            'flip_times', screen.clearFlipTimes, ...
            'last_flip_count', screen.flipCount))
    end
    screen.flip(true, false, true)  % clear screen at the end of each block
    screen.clearFlipTimes;   % clean up in case of interrupted trial
    if screen.escape, break, end
end

% restore normal function
Priority(0);
ShowCursor;
end