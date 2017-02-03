function params = getParams(params,vararginput)

% function params = getParams(params,vararginput)
%
% Gives the ability to pass the param as a structure to a function
%
% 2009-02-24 MF


if ~isempty(vararginput)

    char = zeros(1,length(vararginput));
    struc = zeros(1,length(vararginput));
    
    % find single and multiple params
    for i = 1:length(vararginput)
        char(i) = ischar(vararginput{i});
        struc(i) = isstruct(vararginput{i});
    end

    % assign params in structure
    if ~sum(struc)==0
        a = fields(vararginput{struc});
        for i = 1:size(a,1)
            params.(cell2mat(a(i)))= vararginput{struc}.(cell2mat(a(i)));
        end
    end

    % assign single params
    for i = 1:length(char)-1
        if char(i)==1
            char(i+1)=0;
            params.(vararginput{i}) = vararginput{i+1};
        end
    end

end
