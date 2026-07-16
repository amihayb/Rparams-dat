function MaxMemByts = StructMaxMemberByts(str)
% MaxMemByts = StructMaxMemberByts(str)
% Find the most largest byts member in struct
%
% EladM 30.8.18

fi = fieldnames(str);

for i = 1:length(fi)
    if isstruct( str.(fi{i}) )  % 25.12.24 change for array of struct
        c(i) = StructMaxMemberByts(str.(fi{i})(1)  ); % 25.12.24 change for array of struct
    else
        if (strcmp(class(str.(fi{i})),'double')||strcmp(class(str.(fi{i})),'int64')||strcmp(class(str.(fi{i})),'uint64'))
            c(i) = 8;
        elseif (strcmp(class(str.(fi{i})),'single')||strcmp(class(str.(fi{i})),'int32')||strcmp(class(str.(fi{i})),'uint32'))
            c(i) = 4;
        elseif (strcmp(class(str.(fi{i})),'int16')||strcmp(class(str.(fi{i})),'uint16'))
            c(i) = 2;
        elseif (strcmp(class(str.(fi{i})),'int8')||strcmp(class(str.(fi{i})),'uint8')||strcmp(class(str.(fi{i})),'logical'))
            c(i) = 1;
        elseif strcmp(class( str.(fi{i}) ),'embedded.fi')
            c(i) = str.(fi{i}).WordLength/8;
        else %%% add condition to enum
            c(i) = 4;
        end
    end
end

MaxMemByts = max(c);

end

