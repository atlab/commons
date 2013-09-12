%{
reso.Sync (imported) # my newest table
-> reso.Align

-----

%}

classdef Sync < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('reso.Sync')
		popRel = reso.Align  % !!! update the populate relation
	end

	methods(Access=protected)

		function makeTuples(self, key)
		%!!! compute missing fields for key here
			self.insert(key)
		end
	end
end
