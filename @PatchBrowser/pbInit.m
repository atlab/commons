 function pbInit(pb)
            
            pb.browserFig = figure('position',[200 150 1500 850]);
            hBox = uiextras.HBoxFlex('Parent',pb.browserFig,'Spacing',3);
            animalPanel = uiextras.BoxPanel('Parent',hBox,'Title','Animals');
            vBox = uiextras.VBoxFlex('Parent',hBox,'Spacing',3);
            pb.tabPanel = uiextras.TabPanel('Parent',hBox,'Padding', 5 ,'Callback',@pb.updateTabs);
            pb.infoPanel = uipanel('Parent', pb.tabPanel);
            pb.seriesPanel = uipanel('Parent', pb.tabPanel);
            pb.sketchPanel = uipanel('Parent', pb.tabPanel);
            uicontrol('parent',pb.infoPanel,'String','New Session','units','normalized','position',[.4 .475 .2 .05],'callback',@pb.insertDialog);
            uicontrol('Parent', pb.seriesPanel, 'String','Import Series','units','normalized','position',[.4 .475 .2 .05],'callback',@pb.importSeries);
            uicontrol('Parent', pb.sketchPanel, 'String','New Sketch','units','normalized','position',[.4 .475 .2 .05],'callback',@pb.newSketch);
            pb.tabPanel.TabNames = {'Info', 'Series', 'Sketch'};
            pb.tabPanel.SelectedChild = 1;
            set(pb.tabPanel,'TabEnable',{'on','off','off'});
            set(hBox,'Sizes',[140 70 -1]);
            
            slicePanel = uiextras.BoxPanel('Parent',vBox,'Title','Slices');
            sessPanel = uiextras.BoxPanel('Parent',vBox,'Title','Sessions');
            
            % populate listboxes:
            
            key=fetch(common.Animal,'*');
            
            for i=1:length(key)
                if key(i).animal_id == str2num(key(i).real_id)
                    s{i}=num2str(key(i).animal_id);
                else
                    s{i}=[num2str(key(i).animal_id) ' (' key(i).real_id ')'];
                end
            end
            pb.animalList = uicontrol('parent',animalPanel,'style','listbox','string',s,'callback',@pb.selectAnimal);
            pb.sliceList = uicontrol('parent',slicePanel,'style','listbox','string','','callback',@pb.selectSlice);
            pb.sessList = uicontrol('parent',sessPanel,'style','listbox','string','','callback',@pb.selectSession);
        end