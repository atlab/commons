classdef MotionCorrection
    
    methods(Static)
        
        function [offsets, peakCorr]  = fit(movie, templateFrames)
            if nargin<2
                templateFrames = 60;
            end
            sigmas = [1 5];  % these work for a broad range of magnifications
            
            % construct template
            template = median(movie(:,:,1:min(templateFrames,end)),3);
            [x, y, peakCorr] = ne7.ip.xcorrpeak(movie, template, sigmas);
            offsets = [y x];
        end
        
        
        
        function movie = apply(movie, offsets)
            % offset image img by yxOffset integer pixels, preserving image size.
            % Boundary pixels are duplicated.
            
            for i = 1:size(offsets,1)
                movie(:,:,i) = movie(...
                    min(end,max(1,(1:end)+double(offsets(i,1)))),...
                    min(end,max(1,(1:end)+double(offsets(i,2)))),i);
            end
        end
               
    end
end
