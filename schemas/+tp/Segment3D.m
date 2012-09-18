%{
tp.Segment3D (imported) # extraction of calcium traces
-> tp.Motion3D
-> tp.FineAlign
-> tp.SegOpt
-----
validity_trace   : longblob                      # boolean trace indicates periods of signal validity
%}

classdef Segment3D < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('tp.Segment3D')
        popRel = tp.Motion3D*tp.SegOpt & 'activated=1' ...
            & 'zdrift<2.5' & 'seg_algo in ("DoG 3D","convex 3D")'
    end
    
    methods
        function self = Segment3D(varargin)
            self.restrict(varargin)
        end
    end
    
    methods(Access=protected)
        function makeTuples(self, key)
            tuple = key;
            tuple.validity_trace = true;
            drift = fetch1(tp.Motion3D(key), 'xyz_trajectory');
            zcenter = mean(quantile(drift(:,3), [0.1 0.9]));
            tuple.validity_trace = abs(drift(:,3)-zcenter) < 1;
            fprintf('%2.2f%% of the movie was within z-range\n', mean(tuple.validity_trace)*100);
            self.insert(tuple)
            makeTuples(tp.Trace3D, key)
        end
    end
end