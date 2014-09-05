function  updateSketch(varargin)
%% callback from draggable
if nargin == 2
    pb = varargin{1};
    src = varargin{2};
    
    % if we've dragged any marker, de-select all lines (return to correct
    % linewidth)
    for i=1:8
        for j=1:8
            if i>j
                set([pb.sketchConnection{i,j}],'linewidth',6);
            else
                set([pb.sketchConnection{i,j}],'linewidth',3);
            end
        end
    end
    
    % the dragged marker...
    objInd = find([pb.sketchObj.handle] == src);
    h = pb.sketchObj(objInd);
    
    % ... is a cell prototype (from the upper left corner)
    if h.chan == -1
        h.chan = 0;
        h.textStr = '.';
        h.x = get(h.handle,'XData');
        h.y = get(h.handle,'YData');
        h.textHandle = text(h.x+.02, h.y+.02,h.textStr,'fontsize',14);
        pb.sketchObj(objInd) = h;
        
        % Create a new draggable unlabeled cell
        objInd = length(pb.sketchObj)+1;
        if isPyramidal(h)
            pb.sketchObj(objInd).handle = plot(-1,.5,'marker','^','markerfacecolor',[.4 .4 .4],'color',[.4 .4 .4],'markersize',10);
            pb.sketchObj(objInd).cell_type = 'Pyramidal';
        else
            pb.sketchObj(objInd).handle = plot(-.9,.5,'marker','o','markerfacecolor',[.4 .4 .4],'color',[.4 .4 .4],'markersize',10);
            pb.sketchObj(objInd).cell_type = 'Not Specified';
        end
        pb.sketchObj(objInd).cell_label = 'None';
        pb.sketchObj(objInd).chan = -1;
        
        draggable(pb.sketchObj(objInd).handle,'endfcn',@pb.updateSketch);
        
        % ...is an unlabeled cell
    elseif h.chan == 0 % just update position and move text label
        
        h.x = get(src,'xdata');
        h.y = get(src,'ydata');
        set(h.textHandle,'position',[h.x+.02 h.y+.02 0]);
        pb.sketchObj(objInd) = h;
        
        % ...is a labeled cell
    elseif h.chan > 0
        x = get(src,'xdata');
        y = get(src,'ydata');
        
        % check all the other objects to see if we've dragged this one
        % close enough to draw a line
        w = pb.sketchObj;
        w(objInd)=[];       % exclude the cell we're dragging
        w([w.chan]==-1)=[]; % exclude the protype cells
        w([w.chan]==0)=[]; % exclude the unlabeled cells
        
        [closestXDist closestXInd] = min(abs(x - [w.x]));
        [closestYDist closestYInd] = min(abs(y - [w.y]));
        
        if closestXInd == closestYInd && closestXDist < .02 && closestYDist < .1
            % We're drawing a line
            
            % Check to see if there's already a connecting line so we don't
            % draw another
            if ~isempty(pb.sketchConnection{pb.sketchObj(objInd).chan,w(closestXInd).chan})
                % return the dragged marker back to where it started
                set(src,'xdata',h.x);
                set(src,'ydata',h.y);
                return
            end
            
            % Draw each direction with a different width to see overlaps
            if w(closestXInd).chan > pb.sketchObj(objInd).chan
                hLine=line([h.x w(closestXInd).x],[h.y w(closestXInd).y],'color',pb.patchCol(pb.sketchObj(objInd).chan,:),'linestyle','-','linewidth',3);
            else
                hLine=line([h.x w(closestXInd).x],[h.y w(closestXInd).y],'color',pb.patchCol(pb.sketchObj(objInd).chan,:),'linestyle','--','linewidth',6);
            end
            set(hLine,'buttondownfcn',@pb.updateSketch);
            
            % get it out of the way of the clickable cell markers
            sendToBack(hLine);
            
            pb.sketchConnection{pb.sketchObj(objInd).chan,w(closestXInd).chan}=hLine;
            
            % return the dragged marker back to where it started
            set(src,'xdata',h.x);
            set(src,'ydata',h.y);
        elseif ~h.id
            % We're just moving the marker (but don't move a cell if it has
            % a cell ID)
            h.x = get(src,'xdata');
            h.y = get(src,'ydata');
            pb.sketchObj(objInd) = h;
            
            % Move the text too
            set(h.textHandle,'position',[h.x+.02 h.y+.02 0]);
            
            % Move the endpoints of any connections from this cell to others
            ind = find(~cellfun('isempty',pb.sketchConnection(pb.sketchObj(objInd).chan,:)));
            for i=1:length(ind)
                lineX = get(pb.sketchConnection{pb.sketchObj(objInd).chan,ind(i)},'xdata');
                lineY = get(pb.sketchConnection{pb.sketchObj(objInd).chan,ind(i)},'ydata');
                set(pb.sketchConnection{pb.sketchObj(objInd).chan,ind(i)},'xdata',[h.x,lineX(2)]);
                set(pb.sketchConnection{pb.sketchObj(objInd).chan,ind(i)},'ydata',[h.y,lineY(2)]);
            end
            
            % Move the connections coming from other cells
            ind = find(~cellfun('isempty',pb.sketchConnection(:,pb.sketchObj(objInd).chan)));
            for i=1:length(ind)
                lineX = get(pb.sketchConnection{ind(i),pb.sketchObj(objInd).chan},'xdata');
                lineY = get(pb.sketchConnection{ind(i),pb.sketchObj(objInd).chan},'ydata');
                set(pb.sketchConnection{ind(i),pb.sketchObj(objInd).chan},'xdata',[lineX(1) h.x]);
                set(pb.sketchConnection{ind(i),pb.sketchObj(objInd).chan},'ydata',[lineY(1) h.y]);
            end
        else
            % return the dragged marker back to where it started
            set(src,'xdata',h.x);
            set(src,'ydata',h.y);
        end
    end
    
    % Whatever else we've done, leave the dragged marker as the current
    % object for keypresses, etc.
    set(pb.browserFig,'CurrentObject',src);
    
    %% Callbacks from the figure, from connecting lines, or from cell assignment popupmenus
elseif nargin == 3
    pb = varargin{1};
    src = varargin{2};
    event = varargin{3};
    
    %% It's from the figure, meaning it has to be a keypress
    if src == pb.sketchFig;
        c = event.Character;
        
        % If the current object is a cell marker, than we need to label it
        objInd = find([pb.sketchObj.handle] == gco);
        if ~isempty(objInd)
            
            % Wait, is it a cell prototype?  Don't label that!
            if pb.sketchObj(objInd).chan==-1
                return
            end
            
            % Make sure that the key is a numeric label between 1 and 8
            if ismember(c,'12345678')
                
                % Check to see if any other markers are labeled with this
                % channel - if so, make them unlabeled, and delete their
                % connections
                if any([pb.sketchObj.chan] == str2num(c))
                    for i=1:length(pb.sketchObj)
                        if pb.sketchObj(i).chan == str2num(c)
                            
                            % delete connections
                            delete(pb.sketchConnection{pb.sketchObj(i).chan,:}); pb.sketchConnection(pb.sketchObj(i).chan,:)=cell(1,8);
                            delete(pb.sketchConnection{:,pb.sketchObj(i).chan}); pb.sketchConnection(:,pb.sketchObj(i).chan)=cell(8,1);
                            
                            % make unlabeled
                            pb.sketchObj(i).id = 0;
                            pb.sketchObj(i).chan = 0;
                            pb.sketchObj(i).textStr='.';
                            set(pb.sketchObj(i).textHandle,'string','.');
                            set(pb.sketchObj(i).handle,'color',[.4 .4 .4],'markerfacecolor',[.4 .4 .4]);
                        end
                    end
                end
                
                % If the cell we're about to label is currently labeled, delete connections and disable the old channel assignment
                if pb.sketchObj(objInd).chan >= 1
                    delete(pb.sketchConnection{pb.sketchObj(objInd).chan,:}); pb.sketchConnection(pb.sketchObj(objInd).chan,:)=cell(1,8);
                    delete(pb.sketchConnection{:,pb.sketchObj(objInd).chan}); pb.sketchConnection(:,pb.sketchObj(objInd).chan)=cell(8,1);
                    
                    set(findobj(pb.sketchFig,'tag',['assignment' num2str(pb.sketchObj(objInd).chan)]),'value',1,'enable','off');
                    h=findobj(pb.sketchFig,'tag',['celltype' num2str(pb.sketchObj(objInd).chan)]);
                    val = find(strcmp('Not Specified',get(h,'string')));
                    set(h,'value',val,'enable','off');
                    h=findobj(pb.sketchFig,'tag',['celllabel' num2str(pb.sketchObj(objInd).chan)]);
                    val = find(strcmp('None',get(h,'string')));
                    set(h,'value',val,'enable','off');
                    set(findobj(pb.sketchFig,'tag',['cellnote' num2str(pb.sketchObj(objInd).chan)]),'string','','enable','off');
                end
                
                
                % Label that cell
                pb.sketchObj(objInd).id = 0;
                pb.sketchObj(objInd).chan = str2num(c);
                pb.sketchObj(objInd).textStr = c;
                set(pb.sketchObj(objInd).textHandle,'string',c);
                set(pb.sketchObj(objInd).handle,'color',pb.patchCol(str2num(c),:),'markerfacecolor',pb.patchCol(str2num(c),:));
                
                % Update the cell assignment - we now have a new cell on this channel
                set(findobj(pb.sketchFig,'tag',['assignment' num2str(pb.sketchObj(objInd).chan)]),'value',1,'enable','on');
                h=findobj(pb.sketchFig,'tag',['celltype' num2str(pb.sketchObj(objInd).chan)]);
                if isPyramidal(pb.sketchObj(objInd))
                    val = find(strcmp('Pyramidal',get(h,'string')));
                    set(h,'value',val,'enable','on');
                else
                    val = find(strcmp('Not Specified',get(h,'string')));
                    set(h,'value',val,'enable','on');
                end
                set(findobj(pb.sketchFig,'tag',['celllabel' num2str(pb.sketchObj(objInd).chan)]),'enable','on');
                set(findobj(pb.sketchFig,'tag',['cellnote' num2str(pb.sketchObj(objInd).chan)]),'enable','on');
                
                % Wait, we're not labeling the cell marker, we're deleting it!
            elseif c == char(127)
                % if it's a labeled cell, than delete any of its connections
                if pb.sketchObj(objInd).chan > 0
                    delete(pb.sketchConnection{pb.sketchObj(objInd).chan,:}); pb.sketchConnection(pb.sketchObj(objInd).chan,:)=cell(1,8);
                    delete(pb.sketchConnection{:,pb.sketchObj(objInd).chan}); pb.sketchConnection(:,pb.sketchObj(objInd).chan)=cell(8,1);
                end
                
                % Disable the cell assignment
                set(findobj(pb.sketchFig,'tag',['assignment' num2str(pb.sketchObj(objInd).chan)]),'value',1,'enable','off');
                h=findobj(pb.sketchFig,'tag',['celltype' num2str(pb.sketchObj(objInd).chan)]);
                val = find(strcmp('Not Specified',get(h,'string')));
                set(h,'value',val,'enable','off');
                h=findobj(pb.sketchFig,'tag',['celllabel' num2str(pb.sketchObj(objInd).chan)]);
                val = find(strcmp('None',get(h,'string')));
                set(h,'value',val,'enable','off');
                set(findobj(pb.sketchFig,'tag',['cellnote' num2str(pb.sketchObj(objInd).chan)]),'string','','enable','off');
                
                % delete the cell from the sketch and remove it from the sketchObj structure
                delete(pb.sketchObj(objInd).textHandle);
                delete(pb.sketchObj(objInd).handle);
                pb.sketchObj(objInd)=[];
            end
            
        end
        
        %% Someone pressed a key, and gco is a line
        if ~isempty(gco) && any([pb.sketchConnection{:}] == gco)
            % Delete it and remove from remove it from pb.sketchConnection?
            if c == char(127)
                for i=1:8
                    for j=1:8
                        %Yes, but only if it's selected
                        if pb.sketchConnection{i,j}==gco
                            if strncmp(get(gco,'type'),'line',4) && get(gco,'linewidth')==8
                                pb.sketchConnection{i,j}=[];
                                delete(gco)
                            end
                        end
                    end
                end
            end
        end
        
        %% Callbacks from cell assignment popupmenu
    elseif strncmp('assignment',get(src,'tag'),10)
        tag = get(src,'tag');
        chan = str2num(tag(end));
        val = get(src,'value');
        objInd = find([pb.sketchObj.chan] == chan);
        
        if val == 1 % Assign channel to new cell
            % Set id to 0
            pb.sketchObj(objInd).id = 0;
            
            % Delete any connections
            delete(pb.sketchConnection{pb.sketchObj(objInd).chan,:}); pb.sketchConnection(pb.sketchObj(objInd).chan,:)=cell(1,8);
            delete(pb.sketchConnection{:,pb.sketchObj(objInd).chan}); pb.sketchConnection(:,pb.sketchObj(objInd).chan)=cell(8,1);
            
            draggable(pb.sketchObj(objInd).handle,'endfcn',@pb.updateSketch);
            
        else % Assign channel to an existing cell
            
            % Delete any connections
            delete(pb.sketchConnection{pb.sketchObj(objInd).chan,:}); pb.sketchConnection(pb.sketchObj(objInd).chan,:)=cell(1,8);
            delete(pb.sketchConnection{:,pb.sketchObj(objInd).chan}); pb.sketchConnection(:,pb.sketchObj(objInd).chan)=cell(8,1);
            key=pb.key;
            key=rmfield(key,'mp_sess'); % get all previous cells on this channel in this slice
            key.channel=chan;
            
            % update pb.sketchObj
            c = fetch(mp.CellAssignment(key),'*');
            [~,ind] = sort([c.mp_sess],'descend');
            c = c(ind);
            c=c(val-1);
            
            pb.sketchObj(objInd).id=c.cell_id;
            pb.sketchObj(objInd).cell_type=fetch1(mp.Cell(['cell_id=' num2str(c.cell_id)]),'cell_type');
            pb.sketchObj(objInd).cell_label=fetch1(mp.Cell(['cell_id=' num2str(c.cell_id)]),'cell_label');
            pb.sketchObj(objInd).x = c.sketch_x;
            pb.sketchObj(objInd).y = c.sketch_y;
            
            % set marker position
            set(pb.sketchObj(objInd).handle,'xdata',pb.sketchObj(objInd).x);
            set(pb.sketchObj(objInd).handle,'ydata',pb.sketchObj(objInd).y);
            
            % update text position
            set(pb.sketchObj(objInd).textHandle,'position',[pb.sketchObj(objInd).x+.02 pb.sketchObj(objInd).y+.02]);
            
            % set marker type
            if isPyramidal(pb.sketchObj(objInd))
                set(pb.sketchObj(objInd).handle,'marker','^')
            else
                set(pb.sketchObj(objInd).handle,'marker','o')
            end
            
            % update cell type and cell assignment popups
            h = findobj(pb.sketchFig,'tag',['celltype' num2str(chan)]);
            val = find(strcmp(pb.sketchObj(objInd).cell_type,get(h,'string')));
            set(h,'value',val);
            
            h = findobj(pb.sketchFig,'tag',['celllabel' num2str(chan)]);
            val = find(strcmp(pb.sketchObj(objInd).cell_label,get(h,'string')));
            set(h,'value',val);
            
            % Draw connections
            for i=1:length(pb.sketchObj)
                if i==objInd
                    continue
                end
                
                pair = fetch(pro(mp.CellPair(['cell_id=' num2str(pb.sketchObj(i).id)],'presynaptic=1','connected=1'),'cell_id->cell1')...
                    * pro(mp.CellPair(['cell_id=' num2str(pb.sketchObj(objInd).id)],'presynaptic=0','connected=1'),'cell_id->cell2'),'cell_pair');
                if ~isempty(pair)
                    
                    % Draw each direction with a different width to see overlaps
                    if pb.sketchObj(i).chan > pb.sketchObj(objInd).chan
                        hLine=line([pb.sketchObj(i).x pb.sketchObj(objInd).x],[pb.sketchObj(i).y pb.sketchObj(objInd).y],'color',pb.patchCol(pb.sketchObj(i).chan,:),'linestyle','-','linewidth',6);
                    else
                        hLine=line([pb.sketchObj(i).x pb.sketchObj(objInd).x],[pb.sketchObj(i).y pb.sketchObj(objInd).y],'color',pb.patchCol(pb.sketchObj(i).chan,:),'linestyle','--','linewidth',3);
                    end
                    
                    % get it out of the way of the clickable cell markers
                    sendToBack(hLine);
                    
                    pb.sketchConnection{pb.sketchObj(i).chan,pb.sketchObj(objInd).chan}=hLine;
                end
                
                pair = fetch(pro(mp.CellPair(['cell_id=' num2str(pb.sketchObj(objInd).id)],'presynaptic=1','connected=1'),'cell_id->cell1')...
                    * pro(mp.CellPair(['cell_id=' num2str(pb.sketchObj(i).id)],'presynaptic=0','connected=1'),'cell_id->cell2'),'cell_pair');
                if ~isempty(pair)
                    
                    % Draw each direction with a different width to see overlaps
                    if pb.sketchObj(objInd).chan > pb.sketchObj(i).chan
                        hLine=line([pb.sketchObj(objInd).x pb.sketchObj(i).x],[pb.sketchObj(objInd).y pb.sketchObj(i).y],'color',pb.patchCol(pb.sketchObj(objInd).chan,:),'linestyle','-','linewidth',6);
                    else
                        hLine=line([pb.sketchObj(objInd).x pb.sketchObj(i).x],[pb.sketchObj(objInd).y pb.sketchObj(i).y],'color',pb.patchCol(pb.sketchObj(objInd).chan,:),'linestyle','--','linewidth',3);
                    end
                    
                    % get it out of the way of the clickable cell markers
                    sendToBack(hLine);
                    
                    pb.sketchConnection{pb.sketchObj(objInd).chan,pb.sketchObj(i).chan}=hLine;
                end
            end
        end
        %% just adjust type if there's a callback from the celltype popup
    elseif strncmp('celltype',get(src,'tag'),8)
        tag = get(src,'tag');
        chan = str2num(tag(end));
        val = get(src,'value');
        str = get(src,'string');
        objInd = find([pb.sketchObj.chan] == chan);
        
        pb.sketchObj(objInd).cell_type = str{val};
        
        if isPyramidal(pb.sketchObj(objInd))
            set(pb.sketchObj(objInd).handle,'marker','^');
        else
            set(pb.sketchObj(objInd).handle,'marker','o');
        end
        %% just adjust label if there's a callback from the celllabel popup
    elseif strncmp('celllabel',get(src,'tag'),9)
        tag = get(src,'tag');
        chan = str2num(tag(end));
        val = get(src,'value');
        str = get(src,'string');
        objInd = find([pb.sketchObj.chan] == chan);
        
        pb.sketchObj(objInd).cell_label = str{val};
        
        %% This isn't a keypress from the figure, it's a buttondownfcn from a connecting line or the axes
        % All we need to do is change the linewidth of the line to toggle it "selected"
    elseif any([pb.sketchConnection{:}] == src) || src==gca
        selectIt=1;
        if src==gca
            selectIt=0;
        elseif get(src,'linewidth')==8
            sendToBack(src);
            selectIt=0;
        end
        
        for i=1:8
            for j=1:8
                if i>j
                    set([pb.sketchConnection{i,j}],'linewidth',6);
                else
                    set([pb.sketchConnection{i,j}],'linewidth',3);
                end
            end
        end
        if selectIt
            set(src,'linewidth',8);
        end
        
    end
end