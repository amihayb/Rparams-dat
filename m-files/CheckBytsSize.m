function sizeY = CheckBytsSize(y)
m = 0;
for k = 1:size(y,1)
%     tt = max(y{k,2});
    tt = prod(y{k,2});
    if strcmp('logical',y{k,1});
        m = m + 1*tt;
    elseif strcmp('int8',y{k,1});
        m = m + 1*tt;
    elseif strcmp('int16',y{k,1});
        m = m + 2*tt;
    elseif strcmp('int32',y{k,1});
        m = m + 4*tt;
    elseif strcmp('int64',y{k,1});
        m = m + 8*tt;
    elseif strcmp('uint8',y{k,1});
        m = m + 1*tt;
    elseif strcmp('uint16',y{k,1});
        m = m + 2*tt;
    elseif strcmp('uint32',y{k,1});
        m = m + 4*tt;
    elseif strcmp('uint64',y{k,1});
        m = m + 8*tt;
    elseif strcmp('single',y{k,1});
        m = m + 4*tt;
    elseif strcmp('double',y{k,1});
        m = m + 8*tt;
    else % enum
        m = m + 4*tt;
    end
end
sizeY = m;
end