classdef GazePointAnalyzer < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fig
        ax
        im
        point
        gzm
        loaded_media_name
    end
    
    % Getters and setters
    methods
        function set.ax(obj, value)
            obj.ax = value;
            obj.setupAxes();
        end
    end
    
    methods
        function obj = GazePointAnalyzer(intialize_default_axes)
            if nargin == 0
                intialize_default_axes = false;
            end
            
            obj.gzm = GazePointManager;
            
            if intialize_default_axes
                obj.fig = figure;
                obj.ax = axes(obj.fig);
            end
            
            obj.setupAxes();
            obj.loaded_media_name = [];
        end
        
        function setupAxes(obj)
            obj.ax.DataAspectRatio = [1 1 1];
            default_img = zeros(2, 2, 3);
            obj.ax.NextPlot = 'Add';
            obj.im = image(obj.ax, 0.5 + [0 1] - [0, 1], 0.5 + [0 1] - [0 1], default_img);
            obj.point = scatter(obj.ax, 0, 0, 50, [1 0 1], 'filled');
            obj.ax.NextPlot = 'Replace';
        end
        
        function loadProject(obj, project_name)
            obj.gzm.openProject(project_name);
        end
        
        function loadUser(obj, user_name)
            obj.gzm.openUser(user_name);
        end
        
        function animate(obj, media_name)    
            obj.loadMedia(media_name);
            quoted_media_name = ImageDisplacer.quote(media_name);
            data = obj.gzm.getUserDataForMediaFile(quoted_media_name, ["TIME", "FPOGX", "FPOGY"]);
            screen_width = str2double(obj.gzm.getUserField("Width"));
            screen_height = str2double(obj.gzm.getUserField("Height"));
            
            time_vec = data(:, 1);
            fpogx = data(:, 2);
            fpogy = data(:, 3);
            
            pos_x = fpogx*screen_width;
            pos_y = (1 - fpogy)*screen_height;
            
            num_data_points = length(time_vec);            
            time_vec(end+1) = 0;
            
            t0 = tic;
            for d = 1:num_data_points
                obj.point.XData = pos_x(d);
                obj.point.YData = pos_y(d);
                drawnow;
                pause_time = time_vec(d+1) - toc(t0);
                pause(pause_time);
            end  
        end
        
        function loadMedia(obj, media_name)
            if strcmp(obj.loaded_media_name, media_name)
                return
            end
            
            media_type = 'image';
            
            switch media_type
                case 'image'
                    obj.loadImageFrame(media_name);
                case 'video'
            end
            
            obj.loaded_media_name = media_name;
        end
        
        function loadImageFrame(obj, media_name)
            screen_height = str2double(obj.gzm.getUserField('Height'));
            screen_width = str2double(obj.gzm.getUserField('Width'));
            screen_pos = [0 0; screen_height screen_width];
            
            quoted_media_name = ImageDisplacer.quote(media_name);
            media_file_entry = obj.gzm.getUserMediaEntry(quoted_media_name);
            x0 = media_file_entry.XPIX;
            y0 = media_file_entry.YPIX;
            width = media_file_entry.WIDTHPIX;
            height = media_file_entry.HEIGHTPIX;
            image_pos = [y0, x0; y0 + height, x0 + width];
            
            corner_pixels_center = double(image_pos) + [0.5 0.5; -0.5, -0.5];
            corner_pixels_center(:, 1) = flip(corner_pixels_center(:, 1));
                        
            obj.ax.XLim = [screen_pos(1, 2), screen_pos(2, 2)];
            obj.ax.YLim = [screen_pos(1, 1), screen_pos(2, 1)];
                        
            project_path = fileparts(obj.gzm.open_project);
            full_media_path = strcat(project_path, filesep, "src", filesep, media_name);
            img = imread(char(full_media_path));
            obj.im.CData = img;
            obj.im.XData = 0.5 + corner_pixels_center(:, 2) - [0; 1];
            obj.im.YData = 0.5 + corner_pixels_center(:, 1) - [0; 1];
            
            obj.point.XData = 0;
            obj.point.YData = 0;
        end
    end
    
end

