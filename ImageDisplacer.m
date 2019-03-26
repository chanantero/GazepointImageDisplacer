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
            ImageDisplacer.duplicateProject(project_file_name);
            
            [meta_info, status] = ImageDisplacer.getMetaInfo(meta_file);
            
            assert(~strcmp(status, 'ERROR'), 'ImageDisplacer:adaptProject', 'Could not extract information from meta information file')
           
            x_displacement_time = str2num(meta_info.displacement_time);
            x_displacement_value = str2num(meta_info.displacement_value);
            full_image_size = str2num(meta_info.image_size);
            image_position_in_screen = ImageDisplacer.fitRectangleIntoAnother([0 0; 1 1], [0 0; full_image_size]);
            
            obj.gzm.openProject(project_file_name);
            user_list = obj.gzm.getUserList();
            num_users = length(user_list);
            x_coord_field_names = ["FPOGX", "BPOGX", "CX", "SCLX", "LPCX", "RPCX"];
            y_coord_field_names = ["FPOGY", "BPOGY", "CY", "SCLY", "LPCY", "RPCY"];
            for u = 1:num_users
                obj.gzm.openUser(user_list(u));
                               
                media_info = obj.gzm.getUserMediaEntry(meta_info.output_video_file_name);
                frame_position_in_screen = [media_info.X, media_info.Y; media_info.X + media_info.WIDTH, media_info.Y + media_info.HEIGHT];
                frame_width_in_image = str2double(meta_info.frame_width_pixels);
                               
                normalized_x_coord_in_screen = obj.gzm.getUserDataForMediaFile(meta_info.output_video_file_name, x_coord_field_names);
                normalized_y_coord_in_screen = obj.gzm.getUserDataForMediaFile(meta_info.output_video_file_name, y_coord_field_names);
                time_vector = obj.gzm.getUserDataForMediaFile(meta_info.output_video_file_name, "TIME");
                                 
                [final_normalized_x_coord_in_screen, final_normalized_y_coord_in_screen] = ImageDisplacer.correctCoordinates(time_vector,...
                    x_displacement_time, x_displacement_value,...
                    normalized_x_coord_in_screen, normalized_y_coord_in_screen,...
                    frame_position_in_screen, frame_width_in_image,...
                    full_image_size, image_position_in_screen);
                
                obj.gzm.setUserDataForMediaFile(meta_info.output_video_file_name, x_coord_field_names, final_normalized_x_coord_in_screen);
                obj.gzm.setUserDataForMediaFile(meta_info.output_video_file_name, y_coord_field_names, final_normalized_y_coord_in_screen);
                obj.gzm.setUserMediaEntryPosition(meta_info.output_video_file_name, image_position_in_screen);
                
                obj.gzm.closeUser();
            end
            project_media_entry = obj.gzm.getProjectMediaEntry(meta_info.output_video_file_name);
            project_media_entry.Path = meta_info.image_file_name;
            obj.gzm.setProjectMediaEntry(meta_info.output_video_file_name, project_media_entry);
            
            obj.gzm.closeProject();
        end
    end
    
    methods(Static)
        function duplicateProject(project_name)
            [project_path, ~, ~] = fileparts(project_name);
            separate_path = regexp(char(project_path), '\\|/', 'split');
            folder_name = separate_path{end};
            parent_folder = strjoin(separate_path(1:end-1));
            copy_project_path = [parent_folder, '\', folder_name, '_old'];
            copyfile(project_path, copy_project_path);
        end
        
        function fitted_position = fitRectangleIntoAnother(reference_rectangle_position, rectangle_to_fit_position)
            reference_x0 = reference_rectangle_position(1, 1);
            reference_x1 = reference_rectangle_position(2, 1);
            reference_y0 = reference_rectangle_position(1, 2);
            reference_y1 = reference_rectangle_position(2, 2);
            
            to_fit_x0 = rectangle_to_fit_position(1, 1);
            to_fit_x1 = rectangle_to_fit_position(2, 1);
            to_fit_y0 = rectangle_to_fit_position(1, 2);
            to_fit_y1 = rectangle_to_fit_position(2, 2);
                        
            reference_rectangle_width = reference_x1 - reference_x0;
            reference_rectangle_height = reference_y1 - reference_y0;
            
            to_fit_rectangle_width = to_fit_x1 - to_fit_x0;
            to_fit_rectangle_height = to_fit_y1 - to_fit_y0;
                        
            reference_aspect_ratio = reference_rectangle_width/reference_rectangle_height;
            to_fit_aspect_ratio = to_fit_rectangle_width/to_fit_rectangle_height;
            
            to_fit_width = to_fit_x1 - to_fit_x0;
            to_fit_height = to_fit_y1 - to_fit_y0;
            
            if to_fit_aspect_ratio > reference_aspect_ratio
                reference_width = reference_x1 - reference_x0;
                scale_factor = reference_width/to_fit_width;
                x0 = reference_x0;
                x1 = reference_x1;
                reference_y_center = (reference_y0 + reference_y1)/2;
                y0 = reference_y_center - to_fit_height*scale_factor/2;
                y1 = reference_y_center + to_fit_height*scale_factor/2;
            else
                reference_height = reference_y1 - reference_y0;
                scale_factor = reference_height/to_fit_height;
                y0 = reference_y0;
                y1 = reference_y1;
                reference_x_center = (reference_x0 + reference_x1)/2;
                x0 = reference_x_center - to_fit_width*scale_factor/2;
                x1 = reference_x_center + to_fit_width*scale_factor/2;
            end
            fitted_position = [x0, y0; x1, y1];
        end
        
        function [final_normalized_x_coord_in_screen, final_normalized_y_coord_in_screen] = correctCoordinates(time_vector, x_displacement_time, x_displacement_value, normalized_x_coord_in_screen, normalized_y_coord_in_screen, frame_position_in_screen, frame_width_in_image, full_image_size, image_position_in_screen)
            [normalized_x_coord_in_frame, normalized_y_coord_in_frame] = ImageDisplacer.map2DcoordinatesToAnotherReference([0, 0], [1, 1], frame_position_in_screen(1, :), frame_position_in_screen(2, :), normalized_x_coord_in_screen, normalized_y_coord_in_screen);
            x_displacement = interp1(x_displacement_time, x_displacement_value, time_vector, 'linear', 'extrap');
            [normalized_x_coord_in_image, normalized_y_coord_in_image] = ImageDisplacer.map2DcoordinatesToAnotherReference([x_displacement, zeros(length(x_displacement), 1)], [frame_width_in_image + x_displacement, full_image_size(2)*ones(length(x_displacement), 1)], [0, 0], full_image_size, normalized_x_coord_in_frame, normalized_y_coord_in_frame);
            [final_normalized_x_coord_in_screen, final_normalized_y_coord_in_screen] = ImageDisplacer.map2DcoordinatesToAnotherReference(image_position_in_screen(1,:), image_position_in_screen(2,:), [0, 0], [1, 1], normalized_x_coord_in_image, normalized_y_coord_in_image);
        end
        
        function displaceImage(image_file_name, output_video_file_name, meta_file, frame_width_pixels, velocity_pixels_per_second)
            img = imread(image_file_name);
            [height, width, ~] = size(img);
            
            displacement_information = ImageDisplacer.imageToDisplacedVideo(img, output_video_file_name, frame_width_pixels, 'displacement_velocity', velocity_pixels_per_second);

            ImageDisplacer.createMetaFile(meta_file, image_file_name, frame_width_pixels, displacement_information, output_video_file_name, [height, width]);
        end
        
        function createMetaFile(meta_file, image_file_name, frame_width_pixels, displacement_information, output_video_file_name, image_size)
            meta_info = struct();
            meta_info.image_file_name = ["""", image_file_name, """"];
            meta_info.frame_width_pixels = frame_width_pixels;
            meta_info.displacement_time = displacement_information.displacement_time;
            meta_info.displacement_value = displacement_information.displacement_value;
            meta_info.output_video_file_name = ["""", output_video_file_name, """"];
            meta_info.image_size = image_size;
            
            meta_text = YamlTools.structToYamlText(meta_info);
            file_id = fopen(meta_file, 'w');
            fwrite(file_id, meta_text);
            fclose(file_id);
        end
        
        function result = imageToDisplacedVideo(img, output_video_file_name, frame_width_pixels, varargin)
            [~, width, ~] = size(img);
                      
            [displacement_time, displacement_value] = ImageDisplacer.createDisplacementProfile(width, varargin{:});
            result.displacement_time = displacement_time;
            result.displacement_value = displacement_value;
                        
            if frame_width_pixels < 100
                error('ImageDisplacer:FrameTooThin', 'The minimum frame width is 100 pixels');
            end
            
            if frame_width_pixels > width
                error('ImageDisplacer:FrameTooThick', 'The maximum frame width is the width of the image');
            end
            
            if max(displacement_time) < 1
                error('ImageDisplacer:tooFastDisplacement', 'The minimum duration of the video is 1 second')
            end
            
            if max(displacement_time) > 100
                error('ImageDisplacer:tooSlowDisplacement', 'The maximum duration of the video is 100 seconds')
            end
                           
            ImageDisplacer.displaceImageAsVideo(img, output_video_file_name, frame_width_pixels, displacement_time, displacement_value);    
        end
        
        function displaceImageAsVideo(img, output_video_file_name, frame_width_pixels, displacement_time, displacement_value)
            [~, width, ~] = size(img);
            displacement_time = displacement_time - displacement_time(1);
            duration = displacement_time(end);         
            numFrames = floor(duration*ImageDisplacer.FRAME_RATE);
            time_vector = (0:numFrames-1)/ImageDisplacer.FRAME_RATE;
            displacement = interp1(displacement_time, displacement_value, time_vector, 'linear', 'extrap');
            v = VideoWriter(output_video_file_name, 'Motion JPEG AVI');
            v.FrameRate = ImageDisplacer.FRAME_RATE;
            open(v);
            for f = 1:numFrames
                first_pixel = floor(displacement(f));
                last_pixel = first_pixel + frame_width_pixels - 1;
                pixel_indices = mod((first_pixel:last_pixel) - 1, width) + 1;
                frame = img(:, pixel_indices, :);
                writeVideo(v, frame);
            end
            close(v)
        end
        
        function [displacement_time, displacement_value] = createDisplacementProfile(image_width, varargin)
            p = inputParser;
            addParameter(p, 'displacement_time_vector', [0 10]); % Seconds
            addParameter(p, 'displacement_ratio_value_vector', [0 1]); % A value of 1 corresponds to the width image
            addParameter(p, 'displacement_velocity', 100); % Pixels per second
            parse(p, varargin{:})
            
            if ~ismember('displacement_velocity', p.UsingDefaults)
                displacement_velocity = p.Results.displacement_velocity;
                duration = image_width/abs(displacement_velocity);
                displacement_time = [0, duration];
                displacement_ratio_value = [0, 1];
            else
                displacement_time = p.Results.displacement_time_vector;
                displacement_ratio_value = p.Results.displacement_ratio_value_vector;             
            end
            
            displacement_value = displacement_ratio_value*image_width;
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
        
        function [x_coord_new, y_coord_new] = map2DcoordinatesToAnotherReference(ref_origin_coords, ref_one_one_coords, new_origin_coords, new_one_one_coords, ref_norm_x_coord, ref_norm_y_coord)
            ref_origin_x_coord = ref_origin_coords(:, 1);
            ref_one_x_coord = ref_one_one_coords(:, 1);
            ref_x_dir = ref_one_x_coord - ref_origin_x_coord;
            
            ref_origin_y_coord = ref_origin_coords(:, 2);
            ref_one_y_coord = ref_one_one_coords(:, 2);
            ref_y_dir = ref_one_y_coord - ref_origin_y_coord;
            
            new_origin_x_coord = new_origin_coords(:, 1);
            new_one_x_coord = new_one_one_coords(:, 1);
            new_x_dir = new_one_x_coord - new_origin_x_coord;
            
            new_origin_y_coord = new_origin_coords(:, 2);
            new_one_y_coord = new_one_one_coords(:, 2);
            new_y_dir = new_one_y_coord - new_origin_y_coord;
            
            absolute_x_coord = ref_norm_x_coord.*ref_x_dir + ref_origin_x_coord;
            x_coord_new = (absolute_x_coord - new_origin_x_coord)./new_x_dir;
            
            absolute_y_coord = ref_norm_y_coord.*ref_y_dir + ref_origin_y_coord;
            y_coord_new = (absolute_y_coord - new_origin_y_coord)./new_y_dir;
        end
    end
end

