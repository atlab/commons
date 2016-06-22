%{
psy.MovieParams (imported) # clips from movies
-> psy.MovieInfo
-----
frame_rate : float  # frames per second
frame_width : int  # (pixels)
frame_height : int  # (pixels)
params : longblob # movie parameters
%}


classdef MovieParams < dj.Relvar & dj.AutoPopulate
    properties
        popRel = psy.MovieInfo
    end
    
    methods (Access=protected)
        function makeTuples(self,key)
            [path,file,file_temp,dur,codec] = fetch1(psy.MovieInfo & key,'path','original_file','file_template','file_duration','codec');
            
            infile = getLocalPath(fullfile(path,file));
            info = ffmpeginfo(infile);
            clip_number = floor(info.duration/dur);
            tuple = key;
            
            % read data file
            csvname = [infile(1:end-3) 'csv'];
            if exist(csvname,'file')
                data = csvread(csvname,1,0);
                fileID = fopen(csvname,'r');
                names = textscan(fileID, '%s', 1, 'delimiter', '\n', 'headerlines', 0);
                fclose(fileID);
                names = textscan(names{1}{1},'%s','delimiter',',');
                names = names{1};
                tuple.params = [];
                for iname = 1:length(names)
                    eval(['tuple.params.' names{iname} '=data(:,iname);']);
                end
            end
            
            % insert movie info
            tuple.frame_rate = info.streams.codec.fps;
            tuple.frame_width = info.streams.codec.size(1);
            tuple.frame_height = info.streams.codec.size(2);
            self.insert(tuple)
            
            % process & insert clips
            for iclip = 1:clip_number
                tuple = key;
                tuple.clip_number = iclip;
                tuple.file_name = sprintf(file_temp,iclip);
                if exists(psy.MovieClipStore & tuple);continue;end
               
                % create file
                start = (iclip-1)*dur;
                outfile = getLocalPath(fullfile(path,tuple.file_name));
                if ~exist(outfile,'file')
                    argstr = sprintf('-i %s -ss %d -t %d %s %s',infile,start,dur,codec,outfile);
                    ffmpegexec(argstr)
                end
                
                % load file & insert
                fid = fopen(getLocalPath(fullfile(path,tuple.file_name)));
                tuple.clip = fread(fid,'*int8');
                fclose(fid);
                insert(psy.MovieClipStore,tuple)
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
        
        function plotPos(obj)
            params = fetch1(obj,'params');
            figure
            hold on
            px = interpn(params.frames,params.camera_pos_x,1:params.frames(end),'cubic');
            pz = interpn(params.frames,params.camera_pos_z,1:params.frames(end),'cubic');
            
            fps = fetch1(obj,'frame_rate');
            tbin = 500; % in msec
            bin = fps*tbin/1000; % in frames
            
            trials = 200;
            nsz = floor(length(px)/bin)*bin;
            px = px(1:nsz);
            pz = pz(1:nsz);
            nx = reshape(px,bin,nsz/bin);
            nz = reshape(pz,bin,nsz/bin);
            [~,idx] = sort(nx(1,:));
            nz = nz(:,idx);
            nx = nx(:,idx);
         
            
            range =  floor(linspace(1,size(nx,2),trials));
            try
                colors = cbrewer('qual','Set3',length(range));
            catch
                colors = hsv(length(range));
            end
            idx = randperm(size(colors,1));
            colors = colors(idx,:);
            idx = 0;

            for i = range
                px = nx(:,i);
                pz = nz(:,i);
                idx = idx+1;
                  plot(interpn(px,3,'cubic'),interpn(pz,3,'cubic'),'color',colors(idx,:),'linewidth',1)

            end

            xlim([min(nx(:)) max(nx(:))])
            ylim([min(nz(:)) max(nz(:))])
            set(gca,'xtick',[],'ytick',[])
            xlabel('X dimension')
            ylabel('Y dimension')
            title(['Object trajectories (' num2str(tbin) 'msec)'])
            
        end
    end
end