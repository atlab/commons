%{
psy.VanGoghLookup (lookup) # cached noise maps to save computation time
vangogh_version           : smallint                      # algorithm version; increment when code changes
vangogh_paramhash         : char(10)                      # hash of the lookup parameters
---
params     :blob   # cell array of params
movie      :longblob     # [y,x,frames]
ori        :longblob     # ori movie
kappa      :longblob     # 
contrast   :longblob     # contrast movie
timestamp=CURRENT_TIMESTAMP: timestamp            # automatic
%}

classdef VanGoghLookup < dj.Relvar
    properties(Constant)
        table = dj.Table('psy.VanGoghLookup')
    end
    
    methods
        function [m, key] = lookup(self, cond, degxy, fps)
            % make noise stimulus movie  and update condition
            % INPUTS:
            %   cond  - condition parameters
            %   degxy - visual degrees across x and y
            %   fps   - frames per second
            
            key.vangogh_version = 1;  % increment if you make any changes to the code below
            
            params = {cond degxy fps};
            hash = dj.DataHash(params);
            key.vangogh_paramhash = hash(1:10);
            
            if count(psy.VanGoghLookup & key)
                m = fetch1(self & key, 'movie');
            else
                % create gaussian movie
                [movie, ori, kappa, contrast] = vangoghnoise(cond, degxy, fps);
                
                tuple.params = [params {stim}];
                tuple.movie = movie;
                tuple.kappa = kappa;
                tuple.ori = ori;
                tuple.contrast = contrast;
                
                self.insert(tuple)
            end
        end
    end
    
end