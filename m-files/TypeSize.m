function y = TypeSize(type)


if (strcmp(type,'double')||strcmp(type,'int64')||strcmp(type,'uint64'))
    y = 8;
elseif (strcmp(type,'single')||strcmp(type,'int32')||strcmp(type,'uint32'))
    y = 4;
elseif (strcmp(type,'int16')||strcmp(type,'uint16'))
    y = 2;
elseif (strcmp(type,'int8')||strcmp(type,'uint8')||strcmp(type,'logical'))
    y = 1;
else %%% add condition to enum
    y = 4;
end

end