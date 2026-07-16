function [Out,k,Address] = Padding(FieldType,Address,Out,k,pragma_size)

if (strcmp(FieldType,'double')||strcmp(FieldType,'int64')||strcmp(FieldType,'uint64'))
    %     TypeSize = 4;
    TypeSize = min(8,pragma_size);
elseif (strcmp(FieldType,'single')||strcmp(FieldType,'int32')||strcmp(FieldType,'uint32'))
    %     TypeSize = 4;
    TypeSize = min(4,pragma_size);
elseif (strcmp(FieldType,'int16')||strcmp(FieldType,'uint16'))
    %     TypeSize = 2;
    TypeSize = min(2,pragma_size);
elseif (strcmp(FieldType,'int8')||strcmp(FieldType,'uint8')||strcmp(FieldType,'logical'))
    %     TypeSize = 1;
    TypeSize = min(1,pragma_size);
else %%% add condition to enum
    %     TypeSize = 4;
    TypeSize = min(4,pragma_size);
end

JunkSize = TypeSize - mod(Address,TypeSize);


if (JunkSize ~= 0 && JunkSize ~= TypeSize)
    FieldName = ['Junk' num2str(k)];
    Out(k,:)=['uint8', [JunkSize, 1],{FieldName},{''},0] ;
    k = k + 1;
    Address = Address + JunkSize;
end

end