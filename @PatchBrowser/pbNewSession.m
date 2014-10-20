
% animal
% slice
% import path
% experimenter
% notes

% check / insert animal
% check / insert slice
% insert new session
% import data

% go directly to new sketch

function NewSession(pb,src,event)
            sexes = {'M','F','Unknown'};
            strains = {'C57/BLK6','Other'};
            
            figH = figure('position',[600 600 550 250]);
            
            hTop = uiextras.HBox('Parent',figH,'Spacing',3);
            vLeft = uiextras.VBox('Parent',hTop,'Spacing',3);
            vRight = uiextras.VBox('Parent',hTop,'Spacing',3);
            set(hTop,'Sizes',[-1 -5]);
            
            % Animal, Slice, and Session number
            uicontrol('style','text','parent',vLeft,'string','Animal ID');
            eAnimal = uicontrol('style','edit','parent',vLeft,'string','');
            uiextras.Empty('Parent',vLeft);
            uicontrol('style','text','parent',vLeft,'string','Slice');
            eSlice = uicontrol('style','edit','parent',vLeft,'string','');
            uiextras.Empty('Parent',vLeft);
            uicontrol('style','text','parent',vLeft,'string','Session');
            eSession = uicontrol('style','edit','parent',vLeft,'string','');
            uiextras.Empty('Parent',vLeft);
            set(vLeft,'Sizes',[20 20 -1 20 20 -1 20 20 -1]);
                        
            % ************Animal info
            v = uiextras.VBox('Parent',vRight);
            ht = uiextras.HBox('Parent',v);
            he = uiextras.HBox('Parent',v);
            
            uicontrol('style','text','parent',ht,'string','Real ID:');
            realID=uicontrol('style','edit','parent',he,'string','');
            
            uicontrol('style','text','parent',ht,'string','Sex:');
            sex=uicontrol('style','popupmenu','parent',he,'string',{'M','F','Unknown'});
            
            uicontrol('style','text','parent',ht,'string','Strain:');
            strain=uicontrol('style','popupmenu','parent',he,'string',{'C57/BLK6','Rat','Other'});
            
            uicontrol('style','text','parent',ht,'string','Date of Birth:');
            dob=uicontrol('style','edit','parent',he,'string','');

            set(he,'Sizes',[-2 -1 -2 -2])
            set(ht,'Sizes',[-2 -1 -2 -2])
            
            h = uiextras.HBox('Parent',v);
            uicontrol('style','text','parent',h,'string','Notes:')
            animalNotes=uicontrol('style','edit','parent',h,'string','');
            set(h,'Sizes',[50,-1]);
            
            h = uiextras.HBox('Parent',v);
            uiextras.Empty('Parent',h);
            insertAnimal=uicontrol('parent',h,'string','Insert Animal');
            set(h,'Sizes',[-3 -1]);
            set(v,'Sizes',[20 20 -1 -1]);
            
            % ***********Slice info
            v = uiextras.VBox('Parent',vRight);
            ht = uiextras.HBox('Parent',v);
            he = uiextras.HBox('Parent',v);
            
            uicontrol('style','text','parent',ht,'string','Thickness');
            thickness=uicontrol('style','edit','parent',he,'string','350');
            
            uicontrol('style','text','parent',ht,'string','Brain Region');
            region=uicontrol('style','edit','parent',he,'string','S1');
            
            uiextras.Empty('Parent',he);
            uiextras.Empty('Parent',ht);
            set(he,'Sizes',[-1 -1 -3])
            set(ht,'Sizes',[-1 -1 -3])
            
            h = uiextras.HBox('Parent',v);
            uicontrol('style','text','parent',h,'string','Notes:');
            sliceNotes=uicontrol('style','edit','parent',h,'string','');
            set(h,'Sizes',[50,-1]);
            
            h = uiextras.HBox('Parent',v);
            uiextras.Empty('Parent',h);
            insertSlice=uicontrol('parent',h,'string','Insert Slice');
            set(h,'Sizes',[-3 -1]);
            set(v,'Sizes',[20 20 -1 -1]);
            
            % **************Session info
            v = uiextras.VBox('Parent',vRight);
            ht = uiextras.HBox('Parent',v);
            he = uiextras.HBox('Parent',v);
            uicontrol('style','text','parent',ht,'string','Experimenter:');
            experimenter=uicontrol('style','edit','parent',he,'string','Xiaolong');
            
            uiextras.Empty('Parent',he);
            uiextras.Empty('Parent',ht);
            set(he,'Sizes',[-1 -3])
            set(ht,'Sizes',[-1 -3])
            
            h = uiextras.HBox('Parent',v);
            uicontrol('style','text','parent',h,'string','Notes:');
            sessionNotes=uicontrol('style','edit','parent',h,'string','');
            set(h,'Sizes',[50,-1]);
            
            h = uiextras.HBox('Parent',v);
            uiextras.Empty('Parent',h);
            insertSession=uicontrol('parent',h,'string','Insert Session');
            set(h,'Sizes',[-3 -1]);
            set(v,'Sizes',[20 20 -1 -1]);
            
            set(vRight,'Sizes',[-1 -1 -1]);
            
            
            
          %%  
            
            uicontrol('style','text','parent',animalPanel,'string','Date of Birth:')
            eDOB=uicontrol('style','edit','parent',animalPanel,'string','')
            
            
            
            
            prompts = {'Animal ID:'         , 'animal_id'       ;...
                       'Sex:'               , 'sex'             ;...
                       'Real Animal ID:'    , 'real_id'         ;...
                       'Strain:'            , 'strain'          ;...
                       'DOB (YYYY-MM-DD):'  , 'date_of_birth'   ;...
                       'Animal Notes:'      , 'animal_notes'    ;...
                       'Slice Date: '       , 'slice_date'      ;...
                       'Experimenter:'      , 'experimenter'    ;...
                       'Slice Number:'      , 'mp_slice'        ;...
                       'Slice Thickness:'   , 'thickness'       ;...
                       'Brain Region:'      , 'brain_region'    ;...
                       'Slice Notes:'       , 'slice_notes'     ;...
                       'Session Number:  '  , 'mp_sess'         ;...
                       'Session Notes:'     , 'mp_session_notes'};
            formats=[];
            formats(1,1).type = 'edit'; formats(1,1).format = 'text';
            formats(1,2).type = 'list'; formats(1,2).style = 'radiobutton'; formats(1,2).items = sexes;
            formats(2,1).type = 'edit'; formats(2,1).format = 'text';
            formats(2,2).type = 'list'; formats(2,2).style = 'popupmenu'; formats(2,2).items = strains;
            formats(3,1).type = 'edit'; formats(3,1).format = 'date'; formats(3,1).limits = 29;
            formats(3,2).type = 'none';
            formats(4,1).type = 'edit'; formats(4,1).format = 'text'; formats(4,1).limits = [0 1]; formats(4,1).size = [-1 0];
            formats(4,2).type = 'none'; formats(4,2).limits = [0 1];
            formats(5,1).type = 'none'; 
            formats(5,2).type = 'none'; 
            formats(6,1).type = 'edit'; formats(6,1).format = 'date'; formats(6,1).limits = 29;
            formats(6,2).type = 'edit'; formats(6,2).format = 'text';
            formats(7,1).type = 'edit'; formats(7,1).format = 'text';
            formats(7,2).type = 'edit'; formats(7,2).format = 'text';
            formats(8,1).type = 'edit'; formats(8,1).format = 'text';
            formats(8,2).type = 'none'; 
            formats(9,1).type = 'edit'; formats(9,1).format = 'text'; formats(9,1).limits = [0 1]; formats(9,1).size = [-1 0];
            formats(9,2).type = 'none'; formats(9,2).limits = [0 1];
            formats(10,1).type = 'none'; 
            formats(10,2).type = 'none'; 
            formats(11,1).type = 'edit'; formats(11,1).format = 'text';
            formats(11,2).type = 'none'; 
            formats(12,1).type = 'edit'; formats(12,1).format = 'text'; formats(12,1).limits = [0 1]; formats(12,1).size = [-1 0];
            formats(12,2).type = 'none'; formats(12,2).limits = [0 1];
            
            
            defaults.animal_id = '';
            defaults.sex = 1;
            defaults.real_id = 'same';
            defaults.strain = 1;
            defaults.date_of_birth = '';
            defaults.animal_notes = '';
            defaults.slice_date = datestr(now,29);
            defaults.experimenter = 'Xiaolong';
            defaults.mp_slice='';
            defaults.thickness = '350';
            defaults.brain_region = 'S1';
            defaults.slice_notes='';
            defaults.mp_sess='';
            defaults.mp_session_notes='';
            
            options.AlignControls='on';
            
            [s, cancelled] = inputsdlg(prompts,'title',formats,defaults,options);

            if cancelled
                return
            end

            w = fetchn(common.Animal,'animal_id');
            if ~any(w == str2num(s.animal_id))
                disp(['Inserting new animal ' s.animal_id ' in common.Animal']);
            else
                error('animal exists!');
            end
            
            w = fetchn(common.MpSlice(['animal_id=' s.animal_id]),'mp_slice');
            if ~any(w == str2num(s.mp_slice))
                disp(['Inserting new slice ' s.mp_slice ' for animal ' s.animal_id ' in common.MpSlice']);
            end
            
            w = fetchn(common.MpSession(['animal_id=' s.animal_id], ['mp_slice=' s.mp_slice]),'mp_sess');
            if ~any(w == str2num(s.mp_sess))
                disp(['Inserting new session ' s.mp_sess ' for animal ' s.animal_id ' in common.MpSlice']);
            else
                error('session exists!');
            end

            
        end