function [BusSize,BusFormat] = SizeOf_Matlab(BusName,pragma_size)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    Struct_from_bus=Simulink.Bus.createMATLABStruct(BusName);
    BusFormat = CreateBusFormat(Struct_from_bus, BusName,pragma_size );
    BusSize = CheckBytsSize(BusFormat);
end

