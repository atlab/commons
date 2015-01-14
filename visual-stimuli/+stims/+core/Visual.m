classdef Visual < handle
    % stims.core.Visual is an abstract class from which visual stimuli are derived
    % A stims.core.Visual object manages the graphics window, iterates through
    % trial conditions and calls the showTrial method for each trial.
    % The object optionally logs the data into datajoint tables.
    
    % -- Dimitri Yatsenko, 2012-2015
    
    properties(Constant)
        DEBUG = false
        screen = stims.core.Screen   % all stimuli share one static screen object
    end
    
    properties(Dependent)
        win
        rect
    end
    
    properties(Abstract)
        params          % structure of cell arrays from which conditions will be derived
    end
    
    properties(Access=protected)
        frameStep=1 % 1=full fps, 2=half, 3=third, etc
        conditions
        logger          % an instance of stims.core.Logger
        constants       % fields to be inserted into the session table
        saveAfterEachTrial = false
    end
    
    properties(Access=private)
        flipCount       % the index of the last flip
        flipTimes       % the flip times of the recent flips
    end
    
    methods(Abstract, Access=protected)
        showTrial(self, args)  % implement a trial block in the subclass
    end
    
    methods(Access = protected)
        
        function prepare(self) %#ok<MANU>
            % override this function to do extra work before logging conditions. 
            % For example this could compute a lookup table that the
            % condition table will then reference.
            % This callback is called when self.conditions have been
            % generated but not logged yet.
            % Here, populate tables that psy.Condition (or similar) can
            % refer to.
            
            % do nothing by default.
        end
        
    end
    
    methods
        
        function win = get.win(self)
            win = self.screen.win;
        end
        
        
        function rect = get.rect(self)
            rect = self.screen.rect;
        end
        
        
        function self = init(self, logger, constants)
            if isempty(self.conditions)
                % not yet initialized
                assert(~isempty(self.params), 'Use setParams first')
                disp 'generating conditions'
                self.logger = logger;
                self.constants = constants;
                self.conditions = makeFactorialConditions(self.params);
                self.prepare()
                self.conditions = self.logger.logConditions(self.conditions);
            end
        end
        
        
        function self = setParams(self, varargin)
            % update condition parameters
            for i=1:2:length(varargin)
                self.params.(varargin{i}) = varargin{i+1};
            end
        end
        
        
        function run(self)
            self.screen.escape;   % clear the escape
            self.flipCount = self.logger.getLastFlip;
            
            self.flip(true, false, true)  % clear screen
            for condIdx = randperm(length(self.conditions))   % shuffle conditions
                condition = dj.struct.join(self.conditions(condIdx), self.constants);
                
                %%%%%% show stimulus %%%%%%%
                if self.escape, break, end
                self.showTrial(condition)
                if self.escape, break, end
                fprintf .
                
                % log trial (or queue to save at the end of the block)
                self.logger.logTrial(struct(...
                    'cond_idx', condition.cond_idx, ...
                    'flip_times', self.flipTimes, ...
                    'last_flip_count', self.flipCount))
                if self.saveAfterEachTrial
                    self.logger.flushTrials
                end
                self.flipTimes = [];
            end
            self.flip(true, false, true)  % clear screen
            
            % save trials between blocks
            self.logger.flushTrials;
            self.flipTimes = [];
        end
        
        
        function flip(self, dontLog, dontClear, dontCheck)
            % defaults:    self.flip(false, false, false)
            dontLog   = nargin>=2 && dontLog;
            dontClear = nargin>=3 && dontClear;
            dontCheck = nargin>=4 && dontCheck;
            
            self.flipCount = self.flipCount + ~dontLog;
            [t, droppedFrames] = self.screen.flip(self.flipCount, self.frameStep, double(dontClear));
            if ~dontCheck
                % print a '$" for every dropped frame or $(n) for n dropped frames
                if droppedFrames>5
                    fprintf('$(%d)', droppedFrames)
                else
                    fprintf(repmat('$',1,droppedFrames));
                end
            end
            if ~dontLog
                self.flipTimes(end+1) = t;
            end
        end
    end
    
    
    methods(Static)
        function r = escape
            % an alias for convenience
            r = stims.core.Screen.escape;
        end
    end
end





function conditions = makeFactorialConditions(params)
% make a structure array of conditions that is the cartesian
% product of the field values in params.
% params must be a scalar structure whose fields are cell arrays.

fields = fieldnames(params);

% turn all numeric arrays into cell arrays
for iField = 1:length(fields)
    n = fields{iField};
    v = params.(n);
    if ~iscell(v)
        if ischar(v)
            params.(n) = {v};
        else
            params.(n) = num2cell(v);
        end
    end
end

% cartesian product of field values
dims = structfun(@(x) size(x,2), params)';
[subs{1:length(dims)}] = ind2sub(dims, 1:prod(dims));
conditions = repmat(cell2struct(repmat({[]}, size(fields)), fields), dims);
for iField = 1:length(fields)
    field = fields{iField};
    vals = params.(field);
    for idx=1:prod(dims)
        conditions(idx).(field) = vals{subs{iField}(idx)};
    end
end
conditions = conditions(:);
end