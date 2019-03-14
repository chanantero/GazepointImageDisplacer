classdef ImageDisplacer < handle
    
    properties(Constant)
        FRAME_RATE = 30
    end
    
    properties
        gzm
    end
    
    methods
        function obj = ImageDisplacer()
            obj.gzm = GazePointManager();
            
        end
        
        function adaptProject(obj, meta_file, project_file_name)
            [meta_info, status] = ImageDisplacer.getMetaInfo(meta_file);
            
            if strcmp(status, 'OK')
                x_displacement_time = meta_info.displacement_time;
                x_displacement_value = meta_info.displacement_value;
            else
                return
            end
            
            obj.gzm.openProject(project_file_name);
            user_list = obj.gzm.getUserList();
            num_users = length(user_list);
            x_coord_field_names = [""];
            for u = 1:num_users
                obj.gzm.openUser(user_list(u));
                media_table = obj.gzm.user_media_table;
                
                % Select the right media file information
                project_media_table = obj.gzm.project_media_table;
                ind = strcmp(meta_info.output_video_file_name, project_media_table.Path);
                if ~any(ind)
                    return
                end
                
                media_id = project_media_table.Id(ind);
                media_info = media_table(media_id, :);
                
                frame_position_in_screen = [media_info.X, media_info.Y; media_info.X + media_info.WIDTH, media_info.X + media_info.HEIGHT];
                frame_width_in_image = meta_info.frame_width_pixels;
%                 image_position_in_screen = ?
                
                
                new_data = ImageDisplacer.correctCoordinates(time_vector, x_displacement_time, x_displacement_value, normalized_x_coord_in_screen, normalized_y_coord_in_screen, frame_position_in_screen, frame_width_in_image, full_image_size, image_position_in_screen);
                gzm.closeUser();
            end
            
        end
        
        
    end
    
    methods(Static)
        function [final_normalized_x_coord_in_screen, final_normalized_y_coord_in_screen] = correctCoordinates(time_vector, x_displacement_time, x_displacement_value, normalized_x_coord_in_screen, normalized_y_coord_in_screen, frame_position_in_screen, frame_width_in_image, full_image_size, image_position_in_screen)
            [normalized_x_coord_in_frame, normalized_y_coord_in_frame] = ImageDisplacer.map2DcoordinatesToAnotherReference([0, 0], [1, 1], frame_position_in_screen(1, :), frame_position_in_screen(2, :), normalized_x_coord_in_screen, normalized_y_coord_in_screen);
            x_displacement = interp1(x_displacement_time, x_displacement_value, time_vector);
            [normalized_x_coord_in_image, normalized_y_coord_in_image] = ImageDisplacer.map2DcoordinatesToAnotherReference([x_displacement, zeros(length(x_displacement), 1)], [frame_width_in_image + x_displacement, full_image_size(2)*ones(length(x_displacement), 1)], [0, 0], full_image_size, normalized_x_coord_in_frame, normalized_y_coord_in_frame);
            [final_normalized_x_coord_in_screen, final_normalized_y_coord_in_screen] = ImageDisplacer.map2DcoordinatesToAnotherReference(image_position_in_screen(1,:), image_position_in_screen(2,:), [0, 0], [1, 1], normalized_x_coord_in_image, normalized_y_coord_in_image);
        end
        
        function displaceImage(image_file_name, output_video_file_name, meta_file, frame_width_pixels, velocity_pixels_per_second)
            result = ImageDisplacer.imageFileToDisplacedVideo(image_file_name, output_video_file_name, frame_width_pixels, 'displacement_velocity', velocity_pixels_per_second);

            meta_info = struct();
            meta_info.image_file_name = image_file_name;
            meta_info.frame_width_pixels = frame_width_pixels;
            meta_info.displacement_time = result.displacement_time;
            meta_info.displacement_value = result.displacement_value;
            meta_info.output_video_file_name = output_video_file_name;
            
            meta_text = YamlTools.structToYamlText(meta_info);
            file_id = fopen(meta_file, 'w');
            fwrite(file_id, meta_text);
            fclose(file_id);
        end
        
        function result = imageFileToDisplacedVideo(image_file_name, output_video_file_name, frame_width_pixels, varargin)
            img = imread(image_file_name);
            [~, width, ~] = size(img);
                      
            [displacement_time, displacement_value] = ImageDisplacer.createDisplacementProfile(width, varargin{:});
            result.displacement_time = displacement_time;
            result.displacement_value = displacement_value;
                        
            ImageDisplacer.imageToDisplacedVideo(img, output_video_file_name, frame_width_pixels, displacement_time, displacement_value);    
        end
        
        function imageToDisplacedVideo(img, output_video_file_name, frame_width_pixels, displacement_time, displacement_value)
            displacement_time = displacement_time - displacement_time(1);
            duration = displacement_time(end);         
            numFrames = floor(duration*obj.FRAME_RATE);
            time_vector = (0:numFrames-1)/obj.FRAME_RATE;
            displacement = interp1(displacement_time, displacement_value, time_vector, 'linear', 'extrap');
            v = VideoWriter(output_video_file_name, 'Motion JPEG AVI');
            v.FrameRate = obj.FRAME_RATE;
            open(v);
            for f = 0:numFrames - 1
                first_pixel = floor(displacement(f));
                last_pixel = first_pixel + frame_width_pixels - 1;
                pixel_indices = mod((first_pixel:last_pixel) - 1, width) + 1;
                frame = img(:, pixel_indices, :);
                writeVideo(v, frame);
            end
            close(v)
        end
        
        function [displacement_time, displacement_ratio_value] = createDisplacementProfile(image_width, varargin)
            p = inputParser;
            addParameter(p, 'displacement_time_vector', [0 10]); % Seconds
            addParameter(p, 'displacement_ratio_value_vector', [0 1]); % A value of 1 corresponds to the width image
            addParameter(p, 'displacement_velocity', 100); % Pixels per second
            parse(p, varargin{:})
            
            if ismember('displacement_velocity', p.UsingDefaults)
                displacement_velocity = p.Results.displacement_velocity;
                duration = image_width/abs(displacement_velocity);
                displacement_time = [0, duration];
                displacement_ratio_value = [0, 1];
            else
                displacement_time = p.Results.displacement_time_vector;
                displacement_ratio_value = p.Results.displacement_ratio_value_vector;             
            end
        end
        
        function [structure, status] = getMetaInfo(meta_file)
            try
                meta_file_text = fileread(meta_file);
                structure = YamlTools.yamlTextToStructure(meta_file_text);
                status = 'OK';
            catch m
                structure = [];
                status = 'ERROR';
            end
        end
        
        function [x_coord_new, y_coord_new] = ImageDisplacer.map2DcoordinatesToAnotherReference(ref_origin_coords, ref_one_one_coords, new_origin_coords, new_one_one_coords, ref_norm_x_coord, ref_norm_y_coord)
            ref_origin_x_coord = ref_origin_coords(1);
            ref_one_x_coord = ref_one_one_coords(1);
            ref_x_dir = ref_one_x_coord - ref_origin_x_coord;
            
            ref_origin_y_coord = ref_origin_coords(2);
            ref_one_y_coord = ref_one_one_coords(2);
            ref_y_dir = ref_one_y_coord - ref_origin_y_coord;
            
            new_origin_x_coord = new_origin_coords(1);
            new_one_x_coord = new_one_one_coords(1);
            new_x_dir = new_one_x_coord - new_origin_x_coord;
            
            new_origin_y_coord = new_origin_coords(2);
            new_one_y_coord = new_one_one_coords(2);
            new_y_dir = new_one_y_coord - new_origin_y_coord;
            
            absolute_x_coord = ref_norm_x_coord*ref_x_dir + ref_origin_x_coord;
            x_coord_new = (absolute_x_coord - new_origin_x_coord)/new_x_dir;
            
            absolute_y_coord = ref_norm_y_coord*ref_y_dir + ref_origin_y_coord;
            y_coord_new = (absolute_y_coord - new_origin_y_coord)/new_y_dir;
        end
    end
end

