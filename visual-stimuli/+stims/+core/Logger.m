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
        
        
        function init(self, parentKey, constants)
            if ~isempty(self.parentKey)
                disp 'logger alread initialized'
            else
                self.parentKey = parentKey;
                
                % log session
                idname = setdiff(self.sessionTable.primaryKey, fieldnames(parentKey));
                assert(length(idname)==1, 'invalid key')
                idname = idname{1};
                nextId = fetch1(self.sessionTable & parentKey, sprintf('max(%s)->m', idname))+1;  %autoincrement
                if isempty(nextId)
                    nextId = 1;
                end
                self.sessionKey = parentKey;
                self.sessionKey.(idname) = nextId;
                self.sessionTable.insert(dj.struct.join(self.sessionKey, constants))
                
                self.trialIdName = setdiff(self.trialTable.primaryKey, fieldnames(self.sessionKey));
                assert(length(self.trialIdName)==1, 'invalid trial table')
                self.trialIdName = self.trialIdName{1};
                self.trialIdx = 0;
                
                disp **logged**
                disp(self.sessionKey)
            end
        end
        
        
        function lastFlip = getLastFlip(self)
            lastFlip = fetch1(self.trialTable & self.parentKey, 'max(last_flip_count)->m');  % flip counts are unique per animal
            if isempty(lastFlip)
                lastFlip = 0;
            end
        end
        
        
        function conditions = logConditions(self, conditions)
            lastCond = fetch1(self.condTable & self.sessionKey, 'max(cond_idx)->m');
            if isempty(lastCond)
                lastCond = 0;
            end
            [conditions(:).cond_idx] = deal(nan);
            for iCond = 1:length(conditions)
                condIdx = iCond + lastCond;
                conditions(iCond).cond_idx = condIdx;
                tuple = self.sessionKey;
                tuple.cond_idx = condIdx;
                self.condTable.insert(tuple);
                self.paramTable.insert(dj.struct.join(tuple, conditions(iCond)))
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