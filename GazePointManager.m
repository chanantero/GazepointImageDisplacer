classdef GazePointManager < handle
    
    properties(Constant)
        user_data_field_names = ...
           ["MID"
            "CNT"
            "TIME"
            "TIMETICK"
            "FPOGX"
            "FPOGY"
            "FPOGS"
            "FPOGD"
            "FPOGID"
            "FPOGV"
            "BPOGX"
            "BPOGY"
            "BPOGV"
            "CX"
            "CY"
            "CS"
            "USER"
            "BKID"
            "BKDUR"
            "BKPMIN"
            "SCLX"
            "SCLY"
            "WEB"
            "VID"
            "SCN"
            "CAM"
            "MOB"
            "FACE"
            "LPCX"
            "LPCY"
            "LPD"
            "LPS"
            "LPV"
            "RPCX"
            "RPCY"
            "RPD"
            "RPS"
            "RPV"];                      
        user_data_field_types = [
            "int32";
            "int32";
            "double";
            "int64";
            "single";
            "single";
            "single";
            "single";
            "int32";
            "logical";
            "single";
            "single";
            "logical";
            "single";
            "single";
            "logical";
            "string";
            "int32";
            "int32";
            "int32";
            "single";
            "single";
            "string";
            "string";
            "string";
            "string";
            "string";
            "string";
            "single";
            "single";
            "single";
            "single";
            "logical";
            "single";
            "single";
            "single";
            "single";
            "logical"];
        
        user_data_x_coord_field_names = ["FPOGX", "BPOGX", "CX", "SCLX", "LPCX", "RPCX"];
        user_data_y_coord_field_names = ["FPOGY", "BPOGY", "CY", "SCLY", "LPCY", "RPCY"];
        
        user_media_field_names = ...
            ["ID";
            "X";
            "Y";
            "WIDTH";
            "HEIGHT";
            "XPIX";
            "YPIX";
            "WIDTHPIX";
            "HEIGHTPIX";
            "START_INDEX";
            "END_INDEX";
            "AUDIO_START"];
        user_media_field_types = ...
            ["int32";
            "double";
            "double";
            "double";
            "double";
            "int32";
            "int32";
            "int32";
            "int32";
            "int32";
            "int32";
            "double"];
        
        project_media_field_names = [
            "Id";
            "PlaybackIndex";
            "Name";
            "Type";
            "Path";
            "Duration";
            "Randomize";
            "Scale"];
        project_media_field_types = [
            "int32";
            "int32";
            "string";
            "int32";
            "string";
            "double";
            "logical";
            "double"];
        
        project_user_data_field_names = [
            "Id";
            "Name";
            "Age";
            "Gender";
            "OffsetX";
            "OffsetY";
            "Color";
            "DataRecords"];
        project_user_data_field_types = [...
            "int32";
            "string";
            "int32";
            "string";
            "double";
            "double";
            "string";
            "int32";];
    end
    
    properties
        % Project properties
        open_project
        project_struct 
        project_media_modified
        project_media_table
        project_user_data_modified
        project_user_data_table
        is_project_open
                
        % User properties
        open_user
        is_user_open
        user_struct
        user_data_table
        user_data_modified
        user_media_table
        user_media_modified
    end
    
    % Getters and setters
    methods
        function bool = get.is_project_open(obj)
            bool = ~isempty(obj.open_project);
        end
        
        function set.project_media_table(obj, value)
            obj.project_media_table = value;
            obj.project_media_modified = true;
        end
        
        function set.project_user_data_table(obj, value)
            obj.project_user_data_table = value;
            obj.project_user_data_modified = true;
        end
        
        function bool = get.is_user_open(obj)
            bool = ~isempty(obj.open_user);
        end
        
        function set.user_data_table(obj, value)
            obj.user_data_table = value;
            obj.user_data_modified = true;
        end
        
        function set.user_media_table(obj, value)
            obj.user_media_table = value;
            obj.user_media_modified = true;
        end
    end
    
    methods
        
        function obj = GazePointManager()
            
        end
        
        function openProject(obj, project_file_name)
            obj.open_project = project_file_name;
            project_file_text = fileread(project_file_name);
            structure = YamlTools.yamlTextToStructure(project_file_text);
            obj.project_struct = structure;
            
            media_value = obj.getProjectField('Media', false);
            obj.project_media_table = YamlTools.yamlDictionaryArrayToTable(media_value, GazePointManager.project_media_field_names, GazePointManager.project_media_field_types);
            obj.project_media_modified = false;
            
            user_data_value = obj.getProjectField('UserData', false);
            obj.project_user_data_table = YamlTools.yamlDictionaryArrayToTable(user_data_value, GazePointManager.project_user_data_field_names, GazePointManager.project_user_data_field_types);
            obj.project_user_data_modified = false;
        end
        
        function closeProject(obj)
            if obj.project_media_modified
                obj.setProjectField('Media', obj.project_media_table);
            end
            
            if obj.project_user_data_modified
                obj.setProjectField('UserData', obj.project_user_data_table);
            end
            yamlText = YamlTools.structToYamlText(obj.project_struct);
            
            fileId = fopen(obj.open_project, 'w');
            fwrite(fileId, char(yamlText));
            fclose(fileId);
                       
            obj.project_media_table = [];
            obj.project_user_data_table = [];
            obj.open_project = [];
            
            if obj.is_user_open
                warning('A user was open');
                obj.closeUser();
            end
        end
                        
        function value = getProjectField(obj, field, convert_to_table)
            if nargin < 3
                convert_to_table = true;
            end
            value = GazePointManager.getStructureField(obj.project_struct, field);
            if convert_to_table
                [T, status] = YamlTools.yamlDictionaryArrayToTable(value);
                if strcmp(status, 'OK')
                    value = T;
                end
            end
        end        
        
        function setProjectField(obj, field, value)
            if istable(value)
                value = YamlTools.table2yamlDictionaryArray(value);
            end
            obj.project_struct = GazePointManager.setStructureField(obj.project_struct, field, value);
        end
                
        function project_media_entry = getProjectMediaEntry(obj, media_file_name)
             project_media_entry = obj.project_media_table(obj.project_media_table.Path == media_file_name, :);
        end
        
        function setProjectMediaEntry(obj, media_file_name, project_media_entry)
            obj.project_media_table(obj.project_media_table.Path == media_file_name, :) = project_media_entry;
        end
        
        function user_list = getUserList(obj)
            user_list = obj.project_user_data_table.Name;
        end
        
        function openUser(obj, user_name)
            user_measure_data_file_name_unzipped = obj.getUserFileName(user_name);
            user_measure_data_file_name = [user_measure_data_file_name_unzipped, '.gz'];
            gunzip(user_measure_data_file_name);
            
            user_measure_data_file_text = fileread(user_measure_data_file_name_unzipped);
            obj.user_struct = YamlTools.yamlTextToStructure(user_measure_data_file_text);
            
            data_value = obj.getUserField('Data', false);
            obj.user_data_table = YamlTools.yamlDictionaryArrayToTable(data_value, GazePointManager.user_data_field_names, GazePointManager.user_data_field_types);
            obj.user_data_modified = false;
            
            media_value = obj.getUserField('Media', false);
            obj.user_media_table = YamlTools.yamlDictionaryArrayToTable(media_value, GazePointManager.user_media_field_names, GazePointManager.user_media_field_types);
            obj.user_media_modified = false;
            
            obj.open_user = user_name;
        end
        
        function closeUser(obj)
            if obj.user_data_modified
                obj.setUserField('Data', obj.user_data_table);
            end
            
            if obj.user_media_modified
                obj.setUserField('Media', obj.user_media_table);
            end
            
            yamlText = YamlTools.structToYamlText(obj.user_struct);
            
            user_measure_data_file_name_unzipped = obj.getUserFileName(obj.open_user);
            fileId = fopen(user_measure_data_file_name_unzipped, 'w');
            fwrite(fileId, char(yamlText));
            fclose(fileId);
            gzip(user_measure_data_file_name_unzipped);
            delete(user_measure_data_file_name_unzipped);
            obj.user_struct = [];
            obj.user_data_table = [];
            obj.open_user = [];
        end
                
        function value = getUserField(obj, field, convert_to_table)
            if nargin < 3
                convert_to_table = true;
            end
            value = GazePointManager.getStructureField(obj.user_struct, field);
            if convert_to_table
                [T, status] = YamlTools.yamlDictionaryArrayToTable(value);
                if strcmp(status, 'OK')
                    value = T;
                end
            end
        end
        
        function setUserField(obj, field, value)
            if istable(value)
                value = YamlTools.table2yamlDictionaryArray(value);
            end
            obj.user_struct = GazePointManager.setStructureField(obj.user_struct, field, value);
        end
                       
        function media_id = getMediaFileId(obj, media_file_name)
            ind = strcmp(media_file_name, obj.project_media_table.Path);
            media_id = obj.project_media_table.Id(ind);
        end
        
        function media_file_entry = getUserMediaEntry(obj, media_file_name)
            media_id = obj.getMediaFileId(media_file_name);
            media_file_entry = obj.user_media_table(obj.user_media_table.ID == media_id, :);
        end
        
        function setUserMediaEntry(obj, media_file_name, user_media_entry)
            media_id = obj.getMediaFileId(media_file_name);
            obj.user_media_table(obj.user_media_table.ID == media_id, :) = user_media_entry;
        end
        
        function setUserMediaEntryPosition(obj, media_file_name, normalized_position_in_screen)
            user_media_entry = obj.getUserMediaEntry(media_file_name);
            
            screen_width = str2double(obj.getUserField('Width'));
            screen_height = str2double(obj.getUserField('Height'));
            user_media_entry.X = normalized_position_in_screen(1, 1);
            user_media_entry.Y = normalized_position_in_screen(1, 2);
            user_media_entry.WIDTH = normalized_position_in_screen(2, 1) - user_media_entry.X;
            user_media_entry.HEIGHT = normalized_position_in_screen(2, 2) - user_media_entry.Y;
            user_media_entry.XPIX = int32(user_media_entry.X*screen_width);
            user_media_entry.YPIX = int32(user_media_entry.Y*screen_height);
            user_media_entry.WIDTHPIX = int32(user_media_entry.WIDTH*screen_width);
            user_media_entry.HEIGHTPIX = int32(user_media_entry.HEIGHT*screen_height);
            
            obj.setUserMediaEntry(media_file_name, user_media_entry);
        end
        
        function user_data = getUserDataForMediaFile(obj, media_file_name, field_names)
            media_id = obj.getMediaFileId(media_file_name);
            user_data = obj.user_data_table{obj.user_data_table.MID == media_id, cellstr(field_names)};
        end
        
        function setUserDataForMediaFile(obj, media_file_name, field_names, user_data)
            media_id = obj.getMediaFileId(media_file_name);
            obj.user_data_table{obj.user_data_table.MID == media_id, cellstr(field_names)} = user_data;
        end
        
    end
    
    methods(Access=private)
        function user_measure_data_file_name_unzipped = getUserFileName(obj, user_name)
            
            ind = find(obj.project_user_data_table.Name == user_name);
            if isempty(ind)
                error('User doesn''t exist');
            end
            user_id = obj.project_user_data_table.Id(ind);
            
            [project_directory, name, ext] = fileparts(obj.open_project);
            user_measure_data_file_name_unzipped = ([project_directory, '/user/', num2str(user_id, '%.4u'), '-user.yml']);
        end
    end
    
    methods(Static, Access=private)       
        function value = getStructureField(structure, field)
            value = structure.(field);
        end
        
        function structure = setStructureField(structure, field, value)
            structure.(field) = value;
        end
    end
    
end

