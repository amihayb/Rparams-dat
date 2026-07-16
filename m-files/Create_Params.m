% Make sure you ran init before.
% this script will generate a binary parameters file to switch between
% parameters settings without building the entire model again.

function [size,format] = Create_Params(filename_char , object, Bus_name_char, pragma)
%% Load Params
% FireLosControl_Params_Temp

%% Binary params file name
file_name = [filename_char '.dat'];
% file_name = 'Ammo_MK44_PABMTmod1_ATK.dat';
if isstruct(object)
    object_Struct = object;
else
    object_Struct = object.Value;
end
%% Binary file build 
% Third input can be 8/4 - Pragma. 
object_Bus_Format = CreateBusFormat(object_Struct , Bus_name_char , pragma);
CreateBinaryParamsFile(file_name , object_Bus_Format, object_Struct);

%% Make sure that Size matches the actual file size you wanted
[size,format] = SizeOf_Matlab(Bus_name_char,pragma);
end