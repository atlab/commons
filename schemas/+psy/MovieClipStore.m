%{
psy.MovieClipStore (imported) # clips from movies
-> psy.MovieInfo
clip_number : int           # clip index
-----
file_name  : varchar(255)   # full file name
clip : longblob  #
%}

classdef MovieClipStore < dj.Relvar 
    
    methods
        function filenames = export(obj)
            
            [file_names,clips] = fetchn(obj,'file_name','clip');
            path = getLocalPath(fetch1(psy.MovieInfo & obj,'path'));
            if ~exist(path,'dir');mkdir(path);end
            
            filenames = cell(length(file_names),1);
            for ifile = 1:length(file_names)
                filenames{ifile} = fullfile(path,file_names{ifile});
                if exist(filenames{ifile}, 'file');delete(filenames{ifile});end
                fid = fopen(filenames{ifile},'w');
                fwrite(fid,clips{ifile},'int8');
                fclose(fid);
            end
            
            if length(filenames)==1; filenames = filenames{1};end
            
        end
    end
end