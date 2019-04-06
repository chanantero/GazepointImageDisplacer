
project_file_name = '../gen esponrane ejemplo 2/Ejemplo 2.prj';
meta_file = 'meta_info.txt';

imDisp = ImageDisplacer();
imDisp.adaptProject(meta_file, project_file_name);

% ImageDisplacer.displaceImage('imageTest.jpg', 'asdf.avi', meta_file, 100, 100);
ImageDisplacer.duplicateProject(project_file_name);

%% 
project_path = "C:\Users\chana\Google Drive\Telecomunicación\Extra\Generación Espontánea UPV\Example GazePoint Project_old\";
project_name = strcat(project_path, "Ejemplo 2.prj");
user_name = "User 0";
image_name = "S8_banner_2100x750.jpg";

obj = GazePointAnalyzer;
obj.loadProject(project_name);
obj.loadUser(user_name);
obj.animate("S8_banner_2100x750.jpg");
