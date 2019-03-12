classdef YamlTools < handle
    
    methods(Static)
        function yamlStruct = yamlText2Structure(yaml_text)           
            lines = strsplit(yaml_text, '\n');
            names = regexp(lines, '^(?<preSpace>\s*)(?<name>\w+):(?:\s?)(?<value>.*)', 'names');
            isMainField = cellfun(@(x) ~isempty(x) && isempty(x.preSpace), names);
            yamlStruct = cell2mat(names(isMainField));
            numLines = length(lines);
            indMainField = [find(isMainField), numLines + 1];
            indMoreLines = find(diff(indMainField) > 1);
            for i = indMoreLines
                yamlStruct(i).value = strjoin([{yamlStruct(i).value}, lines(indMainField(i)+1:indMainField(i+1)-1)], '\n');
            end
        end
        
        function yamlText = struct2yamlText(struct)
            num_structs = length(struct);
            entries = strings(num_structs, 1);
            for s = 1:num_structs
                value = struct(s).value;
                if isnumeric(value)
                    value = num2str(value);
                end
                entries(s) = strjoin([struct(s).name, ": ", value], ''); 
            end
            yamlText = strjoin(["%YAML:1.0"; entries], newline);
        end
        
        function [T, status] = yamlDictionaryArrayToTable(yaml_dictionary_array_text, field_names, field_types)
            % Assume the set of actual field names of every dictionary array are
            % the same, there are no repetitions among a given dictionary,
            % and appear in the same order. If not, the function will probable not throw any
            % error, but the performance will be wrong.
            dictionary_struct = regexp(yaml_dictionary_array_text, '- { (?<pointOfData>.*?) }', 'names');
            num_dictionaries = length(dictionary_struct);
            if num_dictionaries == 0
                T = [];
                status = 'Not a dictionary';
                return;
            end
            
            dictionary_cell_array = {dictionary_struct.pointOfData};
            dictionary_array_fields_as_struct = regexp(dictionary_cell_array,'(?<name>\w+):(?<value>(\[.*\])|([^,]*))(,\s|)', 'names');
            
            actual_field_names = string({dictionary_array_fields_as_struct{1}.name});
            field_names_provided = nargin > 1;
            if ~field_names_provided
                field_names = actual_field_names;
            end
            
            [present, ind] = ismember(actual_field_names, field_names);
            if ~any(present)
                status = 'No fields';
                T = [];
                return;
            end
            
            num_fields = length(field_names);
            
            T = table('Size', [num_dictionaries, num_fields], 'VariableTypes', repmat({'string'}, [1, num_fields]), 'VariableNames', cellstr(field_names));
            for r = 1:num_dictionaries
                values = {dictionary_array_fields_as_struct{r}.value};
                T{r, ind(present)} = string(values(present));
            end
            
            field_types_provided = nargin > 2;
            if field_types_provided
                T = GazePointManager.castTableTypes(T, field_types);
            end 
            
            status = 'OK';
        end
        
        function dictArrayString = table2yamlDictionaryArray(T)
            num_elem = size(T, 1);
            dicts = strings(num_elem, 1);
            var_names = T.Properties.VariableNames;
            num_var = length(var_names);
            for e = 1:num_elem
                dict_elems = strings(num_var, 1);
                for v = 1:num_var
                    value = T{e, v};
                    if islogical(value) || isnumeric(value)
                        value_str = string(double(value));
                    else
                        value_str = string(value);
                    end
                    dict_elems(v) = string(sprintf('%s:%s', var_names{v}, value_str));
                end
                dict = strjoin(dict_elems, ', ');
                dicts(e) = strjoin(["- { ", dict, " }"], '');
            end
            dictArrayString = strjoin([""; dicts], newline);
        end
        
        function T = castTableTypes(T, field_types)
            num_fields = length(field_types);
            for t = 1:num_fields
                var_type = field_types(t);
                is_number_or_boolean = ismember(var_type, ["int32", "int64", "single", "double", "logical"]);
                if is_number_or_boolean
                    T.(t) = cast(double(T{:, t}), char(var_type));
                end
            end
        end
    end
end

