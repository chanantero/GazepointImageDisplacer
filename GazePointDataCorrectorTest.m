classdef GazePointDataCorrectorTest < matlab.unittest.TestCase
    
    properties
        correctorObject
    end
    
    methods(TestMethodSetup)
        function createObject(testCase)
            testCase.correctorObject = GazePointDataCorrector();
        end
    end
    
    methods(TestMethodTeardown)
        function destroyObject(testCase)
            delete(testCase.correctorObject)
        end
    end
    
    methods(Test)
        function should_return_video_based_on_image_and_frame_width_and_velocity_parameters(testCase)
            % Given
            image_file_name = 'imageTest.jpg';
            output_video_file_name = 'test_video.avi';
            frame_width_pixels = 500;
            velocity_pixels_per_second = 500;
            
            % When
            testCase.correctorObject.displaceImage(image_file_name, frame_width_pixels, velocity_pixels_per_second, output_video_file_name);
                     
            
            % Then            
            testCase.verifyTrue(isfile(output_video_file_name), 'Output video does not exist')         
        end
        
        function should_correct_x_coordinates_depending_on_velocity(testCase)
            % Given
            velocity_pixels_per_second = 100;
            frame_width_pixels = 500;
            
            x_coord_measured = [0, 0.1, 0.5, 1, 0.4];
            time_stamps = [0, 0.5, 1, 1.5, 2];
            velocity_normalized = velocity_pixels_per_second/frame_width_pixels;
            x_coord_corrected_test = x_coord_measured + time_stamps*velocity_normalized;
            
            % When
            x_coord_corrected = testCase.correctorObject.correctCoordinates(time_stamps, x_coord_measured, velocity_pixels_per_second, frame_width_pixels);
            
            % Then
            testCase.verifyEqual(x_coord_corrected_test, x_coord_corrected)
        end
        
        function should_get_coordinates_and_time_stamp_from_gaze_point_user_yaml_format(testCase)
            % Given
            gaze_point_yaml_text = sprintf('SomeField: somevalue\nData: \n  - { firstField: someValue, Otherfield: other value } \n - { firstField: asdfasf, Otherfield: kljafslkjñdf}');
            test_table = table(["someValue"; "asdfasf"], ["other value"; "kljafslkjñdf"], 'VariableNames', {'firstField', 'Otherfield'});
            [mock, behavior] = testCase.createMock('GazePointDataCorrector', 'AddedMethods',"deposit");
            testCaseMock =  matlab.mock.TestCase.createMock;
            tes
            % When
            [coordinates, time_stamps] = testCase.correctorObject.gazePointFormat2Table(gaze_point_yaml_text);
            
            % Then
            testCase.verifyThat(testCase.correctorObject.yamlText2Structure(gaze_point_yaml_text), WasCalled);
%             assert(all(coordinates == test_coordinates), 'Failure in "should_get_coordinates_and_time_stamp_from_gaze_point_user_yaml_format": coordinates are not the same')
%             assert(all(time_stamps == test_time_stamps), 'Failure in "should_get_coordinates_and_time_stamp_from_gaze_point_user_yaml_format": time stamps are not the same')
%             
%             disp('Success in "should_get_coordinates_and_time_stamp_from_gaze_point_user_yaml_format".')
        end
        
        function should_open_user_data(testCase)
            testCase.verifyTrue(testCase.gzpMan.is_user_open, 'Output video does not exist');
        end
%         
%         function should_transform_coordinates_to_gaze_point_user_yaml_format()
%             % Given
%             test_coordinates = [];
%             test_time_stamps = [];
%             test_gaze_point_format_text = '';
%             
%             % When
%             gaze_point_format_text = obj.coordinatesAndTimeStampsToGazePointFormat(test_coordinates, test_time_stamps);
%             
%             % Then
%             assert(strcmp(gaze_point_format_text, test_gaze_point_format_text), ...
%                 'Failure in "should_transform_coordinates_to_gaze_point_user_yaml_format"');
%             
%             disp('Failure in "should_transform_coordinates_to_gaze_point_user_yaml_format"')
%         end
%         
%         function should_correct_gaze_point_format_text()
%             % Given
%             test_gaze_point_text = "";
%             test_gaze_point_text_corrected = "";
%             velocity_pixels_per_second = 100;
%             frame_width_pixels = 500;
%             
%             % When
%             gaze_point_text_corrected = obj.correctGazePointCoordinates(test_gaze_point_text, velocity_pixels_per_second, frame_width_pixels);
%             
%             % Then
%             assert(test_gaze_point_text_corrected == gaze_point_text_corrected, ...
%                 'Failure in "should_correct_gaze_point_format_text"')
%             
%             disp('Success in "should_correct_gaze_point_format_text"')
%         end
%         
%         function should_generate_new_gaze_point_yaml_file_with_corrected_coordinates()
%             % Given
%             gaze_point_yaml_file = '';
%             gaze_point_yaml_file_corrected = '';
%             
%             % When
%             obj.generateCorrectedGazePointYamlFile(gaze_point_yaml_file, gaze_point_yaml_file_corrected);
%             
%             % Then
%             assert(isfile(gaze_point_yaml_file_corrected), ...
%                 'Failure in "should_generate_new_gaze_point_yaml_file_with_corrected_coordinates"');
%             
%             disp('Success in "should_generate_new_gaze_point_yaml_file_with_corrected_coordinates"');
%         end
    end
    
end