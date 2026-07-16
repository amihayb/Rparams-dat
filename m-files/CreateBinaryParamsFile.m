function [] = CreateBinaryParamsFile(file_name,BusFormat,ParamsStruct)

ByteOrder = 'l' ; % l = Little-endian ordering , a = Little-endian ordering, 64-bit long data type

support_class = {'logical','boolean','single','double',...
    'uint8','uint16','uint32','uint64','int8','int16','int32','int64'};  

% Open *.mpf file
fid=fopen(file_name,'w');
n = size(BusFormat,1);

for ii=1:n
    field_path = BusFormat{ii,3};
    field_size = BusFormat{ii,2};
    field_class = BusFormat{ii,1};
    disp(ii)
 
    if strncmp(field_path,'Junk',4)
        fwrite(fid,zeros(field_size,'uint8') ,'uint8',ByteOrder);
    else
        
        value = eval(['ParamsStruct' field_path]);
        if any(strcmp(field_class, support_class))==0
            value = int32(value);
            field_class = 'int32';
        end
        fwrite(fid,value,field_class,ByteOrder);
    end
 
end


fclose(fid);

end