%{
reso.IndicatorSet (computed) # groups all indicators for a single site
-> reso.Align
-> reso.EphysTime
%}

classdef IndicatorSet < dj.Relvar & dj.AutoPopulate

	properties
		popRel  = reso.Align * reso.EphysTime
    end

    
	methods(Access=protected)

		function makeTuples(self, key)            
			self.insert(key)
		end
	end

end