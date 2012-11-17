%{
tp.Extract (imported) # refines segmentation and extract traces
-> tp.Segment

-----

%}

classdef Extract < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('tp.Extract')
		popRel = tp.Segment  % !!! update the populate relation
	end

	methods(Access=protected)

		function makeTuples(self, key)
			self.insert(key)
            makeTuples(tp.Trace, key)
		end
	end
end
