function [Out,k,Address] = PaddingEndStruct(MaxMemByts,Address,Out,k,pragma_size)

JunkSize = MaxMemByts - mod(Address,MaxMemByts);
JunkSize = mod(JunkSize,pragma_size);

if (JunkSize ~= 0 && JunkSize ~= MaxMemByts)
    FieldName = ['Junk' num2str(k)];
    Out(k,:)=['uint8', [JunkSize, 1],{FieldName} ,{''},0] ;
    k = k + 1;
    Address = Address + JunkSize;
end

end