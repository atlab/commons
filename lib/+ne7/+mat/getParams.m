function params = getParams(params,vararginput)

% function params = getParams(params,vararginput)
%
% Gives the ability to pass the param as a structure to a function
%
% 2009-02-24 MF


if ~isempty(vararginput)

    characters = zeros(1,length(vararginput));
    structures = zeros(1,length(vararginput));
    
    % find single and multiple params
    for i = 1:length(vararginput)
        characters(i) = ischar(vararginput{i});
        structures(i) = isstruct(vararginput{i});
    end

    % assign params in structure
    if ~sum(structures)==0
        a = fields(vararginput{structures});
        for i = 1:size(a,1)
            params.(cell2mat(a(i)))= vararginput{structures}.(cell2mat(a(i)));
        end
    end

    % assign single params
    for i = 1:length(characters)-1
        if characters(i)==1
            characters(i+1)=0;
            params.(vararginput{i}) = vararginput{i+1};
        end
    end

end
