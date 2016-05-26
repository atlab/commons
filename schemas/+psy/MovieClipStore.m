%{
psy.MovieClipStore (imported) # clips from movies
-> psy.MovieInfo
clip_number : int           # clip index
-----
file_name  : varchar(255)   # full file name
clip : longblob  #  
%}


classdef MovieClipStore < dj.Relvar & dj.AutoPopulate
     properties
        popRel = psy.MovieInfo
     end
    
    methods (Access=protected)
        function makeTuples(self,key)
            [path,file_temp] = fetch1(psy.MovieInfo & key,'path','file_template');
            clips = dir(fullfile(getLocalPath(path),['*.' file_temp(end-2:end)]));
            for iclip = 1:length(clips);
                clip_number = sscanf(clips(iclip).name,file_temp);
                if isempty(clip_number);continue;end
                tuple = key;
                tuple.clip_number = clip_number;    
                tuple.file_name = clips(iclip).name;
                fid = fopen(getLocalPath(fullfile(path,tuple.file_name)));
                tuple.clip = fread(fid,'*int8');
                fclose(fid);
                self.insert(tuple)
            end
        end
    end
    
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