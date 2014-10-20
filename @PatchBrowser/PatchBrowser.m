classdef PatchBrowser < handle
    
    properties
        browserFig
        sweepFig
        sketchFig
        animalList
        sliceList
        sessList
        
        tabPanel
        infoPanel
        seriesPanel
        sketchPanel
        idh %input dialog handles
        key % current animal, slice and session key
        
        patchCol=[0 0 0 ; 1 0 0; 0 .4 1; 0 1 0; 1 .4 0; .4 .6 0; 0 0 .6; .478 .063 .894];
        
        sketchObj
        sketchConnection = cell(8);
    end
    
    
    methods
        function obj = PatchBrowser
            obj.pbInit;
        end
        
        % fetch animals
        
        % fetch slices
        
        % fetch sessions
        
    end
end