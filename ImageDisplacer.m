classdef ImageDisplacer < handle
    
    properties(Constant)
        FRAME_RATE = 30
    end
    
    properties
        gzm
    end
    
    methods
        function obj = ImageDisplacer()
            gzm = GazePointManager();
            
        end
        
        function adaptProject(obj, meta_file, project_file_name)
            meta_info = ImageDisplacer.getMetaFile(meta_file);
            
            obj.gzm.openProject(project_file_name);
            user_list = obj.gzm.getUserList();
            num_users = length(user_list);
            x_coord_field_names = [""];
            for u = 1:numUsers
                obj.gzm.openUser(user_list(u));
                media_table = obj.gzm.user_media_table;
                frame_position_in_screen = 
                new_data = ImageDisplacer.correctCoordinates(time_vector, x_displacement_time, x_displacement_value, normalized_x_coord_in_screen, normalized_y_coord_in_screen, frame_position_in_screen, frame_width_in_image, full_image_size, image_position_in_screen);
                gzm.closeUser();
            end
            
        end
        
        function [final_normalized_x_coord_in_screen, final_normalized_y_coord_in_screen] = correctCoordinates(time_vector, x_displacement_time, x_displacement_value, normalized_x_coord_in_screen, normalized_y_coord_in_screen, frame_position_in_screen, frame_width_in_image, full_image_size, image_position_in_screen)
            [normalized_x_coord_in_frame, normalized_y_coord_in_frame] = ImageDisplacer.map2DcoordinatesToAnotherReference([0, 0], [1, 1], frame_position_in_screen(1, :), frame_position_in_screen(2, :), normalized_x_coord_in_screen, normalized_y_coord_in_screen);
            x_displacement = interp1(x_displacement_time, x_displacement_value, time_vector);
            [normalized_x_coord_in_image, normalized_y_coord_in_image] = ImageDisplacer.map2DcoordinatesToAnotherReference([x_displacement, zeros(length(x_displacement), 1)], [frame_width_in_image + x_displacement, full_image_size(2)*ones(length(x_displacement), 1)], [0, 0], full_image_size, normalized_x_coord_in_frame, normalized_y_coord_in_frame);
            [final_normalized_x_coord_in_screen, final_normalized_y_coord_in_screen] = ImageDisplacer.map2DcoordinatesToAnotherReference(image_position_in_screen(1,:), image_position_in_screen(2,:), [0, 0], [1, 1], normalized_x_coord_in_image, normalized_y_coord_in_image);
        end
    end
    
    methods(Static)
        function displaceImage(image_file_name, frame_width_pixels, velocity_pixels_per_second, output_video_file_name, meta_file)
            duration = width/abs(velocity_pixels_per_second);
            displacement_time = [0, duration];
            displacement_ratio_value = [0, 1];
            
            ImageDisplacer.createDisplacedVideo(image_file_name, frame_width_pixels, displacement_time, displacement_ratio_value, output_video_file_name);

            meta_info = struct();
            meta_info.image_file_name = image_file_name;
            meta_info.frame_width_pixels = frame_width_pixels;
            meta_info.displacement_time = displacement_time;
            meta_info.displacement_value = displacement_value;
            meta_info.output_video_file_name = output_video_file_name;
            
            meta_text = YamlTools.struct2yamlText(meta_info);
            file_id = fopen(meta_file, 'w');
            fwrite(file_id, meta_text);
            fclose(file_id);
        end
        
        function createDisplacedVideoCULO(image_file_name, frame_width_pixels, velocity_pixels_per_second, output_video_file_name)
            img = imread(image_file_name);
            [~, width, ~] = size(img);
            duration = width/abs(velocity_pixels_per_second);
            numFrames = ceil(duration*obj.FRAME_RATE) - 1;
            v = VideoWriter(output_video_file_name, 'Motion JPEG AVI');
            v.FrameRate = obj.FRAME_RATE;
            open(v);
            for f = 0:numFrames - 1
                first_pixel = floor(width*f/numFrames);
                last_pixel = first_pixel + frame_width_pixels - 1;
                pixel_indices = mod((first_pixel:last_pixel) - 1, width) + 1;
                frame = img(:, pixel_indices, :);
                writeVideo(v, frame);
            end
            close(v)
        end
        
        function createDisplacedVideo(image_file_name, frame_width_pixels, displacement_time, displacement_ratio_value, output_video_file_name)
            img = imread(image_file_name);
            [~, width, ~] = size(img);
                      
            displacement_time = displacement_time - displacement_time(1);
            duration = displacement_time(end);
            displacement_value = displacement_ratio_value*width;
            
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

