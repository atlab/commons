% stims.core.Logger -- log stimulus data into specified DataJoint tables 

% -- Dimitri Yatsenko, 2012

classdef Logger < handle
    
    properties(SetAccess=private)
        % DataJoint tables for session information. Structure with fields
        % 'session', 'trial', 'condition', 'paramaters'
        sessionTable
        condTable
        trialTable
        paramTable        
        parentKey       % primary key of session's parent
        sessionKey
        
        trialIdName = 'trial_idx'
        trialIdx
        unsavedTrials
    end
    
    methods
        function self = Logger(sessionTable, condTable, trialTable, paramTable)
            self.sessionTable = sessionTable;
            self.trialTable = trialTable;
            self.condTable = condTable;
            self.paramTable = paramTable;
                        
        end
        
        function init(self, key)
            % autoincrement session id
            self.parentKey = key;

            idname = setdiff(self.sessionTable.primaryKey, fieldnames(key));
            assert(length(idname)==1, 'invalid key')
            idname = idname{1};
            nextId = max(fetchn(self.sessionTable & self.parentKey, idname))+1;
            if isempty(nextId)
                nextId = 1;
            end
            self.sessionKey = self.parentKey;
            self.sessionKey.(idname) = nextId;
            
            % start counting trials
            self.trialIdName = setdiff(self.trialTable.primaryKey, fieldnames(self.sessionKey));
            assert(length(self.trialIdName)==1, 'invalid trial table')
            self.trialIdName = self.trialIdName{1};
            self.trialIdx = 0;
        end
        
            
        function nextFlip = getLastFlip(self)
            nextFlip = max(fetchn(self.trialTable & self.parentKey, 'last_flip_count'));  % flip counts are unique per animal
            if isempty(nextFlip)
                nextFlip = 0;
            end
        end
        
        
        function logSession(self, tuple)
            assert(~isempty(self.sessionKey), 'Logger must be initalized')
            self.sessionTable.insert(dj.struct.join(self.sessionKey, tuple));
            disp **logged**
            disp(self.sessionKey)
        end
        
        
        function logConditions(self, conditions)
            for condIdx = 1:length(conditions)
                tuple = self.sessionKey;
                tuple.cond_idx = condIdx;
                self.condTable.insert(tuple);
                self.paramTable.insert(dj.struct.join(tuple, conditions(condIdx)))
            end
        end
        
        
        function logTrial(self, tuple)
            self.trialIdx = self.trialIdx + 1;
            key = self.sessionKey;
            key.(self.trialIdName)=self.trialIdx;
            tuple = dj.struct.join(key, tuple);
            self.unsavedTrials = [self.unsavedTrials tuple];
        end
        
        function flushTrials(self)
            if ~isempty(self.unsavedTrials)
                self.trialTable.insert(self.unsavedTrials);
                self.unsavedTrials = [];
            end
        end
    end
end