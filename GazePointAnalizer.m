classdef GazePointAnalizer < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fig
        gzm
    end
    
    methods
        function obj = GazePointAnalizer()
            obj.fig = figure;
            obj.ax = axes(obj.fig);
            obj.ax.DataAspectRatio = [1 1 1];
            obj.gzm = GazePointManager;
        end
        
        function animate(obj, user_name, media_name)
            obj.gzm.openUser(user_name);
            media_file_entry = obj.getUserMediaEntry(media_name);
            
            screen_pos = [0 0; screen_height screen_width];
            image_norm_pos = [media_file_entry.Y, media_file_entry.X; media_file_entry.Y + media_file_entry.HEIGHT, media_file_entry.X + media_file_entry.WIDTH];
            
            obj.loadImageFrame(screen_pos, image_norm_pos);
            
            obj.gzm.getUserDataForMediaFile(media_name, ["TIME", "FPOGX", "FPOGY"]);
        end
        
        function loadImageFrame(obj, media_name)
            media_file_entry = obj.getUserMediaEntry(media_name);
            
            screen_pos = [0 0; screen_height screen_width];
            image_norm_pos = [media_file_entry.Y, media_file_entry.X; media_file_entry.Y + media_file_entry.HEIGHT, media_file_entry.X + media_file_entry.WIDTH];
                        
            obj.ax.XLim = [screen_pos(1, 2), screen_pos(2, 2)];
            obj.ax.YLim = [screen_pos(1, 1), screen_pos(1, 2)];
            
            
        end
        
        function outputArg = animate(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

