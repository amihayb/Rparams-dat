function [Out,k,Address] = ReadBinaryPragma(Struct_from_bus, k, MaxMemByts, Name0,busObj,Out,Address,pragma_size)

% EladM 30.8.18
% Nati: 17.10.18


fi = fieldnames(Struct_from_bus);

for i = 1:length(fi)
    
    
    
    if isstruct(Struct_from_bus.(fi{i}))
        if length(Struct_from_bus.(fi{i}))>1
            disp(1);
        end
        
        StructDim = busObj.Elements(i).Dimensions; % 25.12.24 Support Array of struct , assum 1 dim array
        
        for jj = 1:StructDim(1) % 25.12.24 Support Array of struct , assum 1 dim array
            if StructDim(1)==1
                FieldName = [Name0,'.',char(fi{i})];
            else
                FieldName = [Name0,'.',char(fi{i}),'(',num2str(jj),')'];
            end
             disp(FieldName)
            SubBusDataType = busObj.Elements(i).DataType;
            if strcmp(SubBusDataType(1:5),'Bus: ')
                SubBusObj = evalin('base',SubBusDataType(6:end));
            elseif strcmp(SubBusDataType(1:4),'Bus:')  %rida
                SubBusObj = evalin('base',SubBusDataType(5:end));
            else
                SubBusObj = evalin('base',SubBusDataType);
            end
            
            MaxMemByts = StructMaxMemberByts(Struct_from_bus.(fi{i})(1));
            [Out,k,Address] = PaddingBeginStruct(MaxMemByts,Address,Out,k,pragma_size);
            [Out,k,Address] = ReadBinaryPragma(Struct_from_bus.(fi{i})(1), k, MaxMemByts, FieldName,SubBusObj,Out,Address,pragma_size); % Recursive
            [Out,k,Address] = PaddingEndStruct(MaxMemByts,Address,Out,k,pragma_size);
        end
    else
        FieldName = [Name0,'.',char(fi{i})];
         disp(FieldName)
        FieldType = class(Struct_from_bus.(fi{i}));
        Value  = Struct_from_bus.(fi{i});
        
        if strcmp(FieldType,'embedded.fi')
            if strcmp(Value.Signedness,'Unsigned')
                FieldType = ['uint' num2str(Value.WordLength) ] ;
            else
                FieldType = ['int' num2str(Value.WordLength) ] ;
            end
        end
        
        %         Size=size(str.(fi{i}));
        %         Units = '';
        
        Size=busObj.Elements(i).Dimensions;
        Units = busObj.Elements(i).Unit;
        
        
        [Out,k,Address] = Padding({FieldType},Address,Out,k,pragma_size);
        Out(k,:)=[{FieldType},{Size}, {FieldName},{Units}, MaxMemByts];
        Address = Address + max(Size)*TypeSize(FieldType);
        k = k+1;
    end
    
end

end