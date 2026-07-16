function [ Format ] = CreateBusFormat(Struct_from_bus, ReadBus,pragma_size )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% init
emptyFormat = [{' '},{0},{' '},{''},{0}];
Out = emptyFormat;
Address = 0;
k=1;
FieldName = '';
busObj = evalin('base',ReadBus);
% run
MaxMemByts = StructMaxMemberByts(Struct_from_bus);
[Out,k,Address] = PaddingBeginStruct(MaxMemByts,Address,Out,k,pragma_size);
[Out,k,Address] = ReadBinaryPragma(Struct_from_bus, k, MaxMemByts, FieldName,busObj,Out,Address,pragma_size);
[Out,k,Address] = PaddingEndStruct(MaxMemByts,Address,Out,k,pragma_size);


% [Out_,~,~]      = ReadBinaryPragma(Struct_from_bus, 1, 0, '',ReadBus,emptyFormat,0,pragma_size);
% Format(:,1:4) = Out_(:,1:4);

Format(:,1:4) = Out(:,1:4);

end

