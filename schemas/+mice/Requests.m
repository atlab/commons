%{
mice.Requests (manual) # requests for transgenic mice$
request_idx     : int                    # request number
---
requestor="none"            : enum('Jake','Manolis','Dimitri','Shan','Keith','Cathryn','Fabian','Deumani','Matt','Megan','Paul','Shuang','Federico','Jiakun','Other','Available','none') # person who requested the mice
dor=null                    : date                          # date of request
number_mice                 : int                           # number of mice requested
age=null                    : enum('any','P18-P21','P21-P28','4-6 Weeks') # age requested
line1=null                  : varchar(100) # Mouse Line 1 Abbreviation
genotype1                   : enum('homozygous','heterozygous','hemizygous','positive','negative','wild type','') # genotype for line 1
line2=null                  : varchar(100) # Mouse Line 2 Abbreviation
genotype2=null              : enum('homozygous','heterozygous','hemizygous','positive','negative','wild type','') # genotype for line 2
line3=null                  : varchar(100) # Mouse Line 3 Abbreviation
genotype3=null              : enum('homozygous','heterozygous','hemizygous','positive','negative','wild type','') # genotype for line 3
request_notes=null          : varchar(4096)                 # other comments
request_ts=CURRENT_TIMESTAMP: timestamp                     # automatic
%}



classdef Requests < dj.Relvar

	properties(Constant)
		table = dj.Table('mice.Requests')
	end

	methods
		function self = Requests(varargin)
			self.restrict(varargin)
        end
        function makeTuples(self,key)
            self.insert(key)
        end
	end
end
