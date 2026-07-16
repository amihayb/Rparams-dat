function ExportParamsJson(filename_char, object, Bus_name_char, pragma)
% ExportParamsJson  Export binary parameter layout + default values as JSON.
%
%   ExportParamsJson(FILENAME, OBJECT, BUS_NAME, PRAGMA) generates a JSON
%   file FILENAME.json that describes the exact binary layout produced by
%   CreateBinaryParamsFile, together with the default parameter values.
%
%   Inputs mirror Create_Params:
%     FILENAME    - output base name (no extension)
%     OBJECT      - struct, or Simulink.Parameter whose .Value is a struct
%     BUS_NAME    - Simulink bus type name (e.g. 'BusAimingAlgExtParams')
%     PRAGMA      - packing alignment size in bytes (4 or 8)
%
%   The generated JSON is loaded by the companion HTML/JS app to create,
%   read, and edit .dat files without MATLAB.
%
%   Example:
%     ExtParamsNg;           % run the params script to populate ExtParams
%     ExportParamsJson('NG_Test_Params', ExtParams, 'BusAimingAlgExtParams', 8);

% Unwrap Simulink.Parameter if needed
if isstruct(object)
    object_Struct = object;
else
    object_Struct = object.Value;
end

% Build the same format table used by Create_Params / CreateBinaryParamsFile
BusFormat = CreateBusFormat(object_Struct, Bus_name_char, pragma);
n = size(BusFormat, 1);

% Walk BusFormat and build one JSON entry per row
entries = cell(n, 1);
for ii = 1:n
    ftype  = BusFormat{ii, 1};   % char  – type string (e.g. 'single', 'uint8')
    fsize  = BusFormat{ii, 2};   % array – [rows, cols]  (or scalar for 1-D)
    fpath  = BusFormat{ii, 3};   % char  – '.Field.Sub' or 'JunkN'
    funits = BusFormat{ii, 4};   % char  – unit string (may be empty)

    e = struct();
    e.type = ftype;
    e.path = fpath;

    if strncmp(fpath, 'Junk', 4)
        % Padding entry – only the byte count matters
        e.isJunk    = true;
        e.elemCount = double(prod(double(fsize)));
    else
        % Data entry – capture shape and actual value
        e.isJunk = false;
        e.dims   = normalizeDims(double(fsize));          % always [rows, cols]
        e.units  = char(funits);
        raw      = eval(['object_Struct' fpath]);         % extract from struct
        e.value  = double(raw(:)');  % column-major, serialised as a row vector
    end

    entries{ii} = e;
end

% Assemble the top-level document
out        = struct();
out.meta   = struct('busName', Bus_name_char, 'pragma', pragma);
out.format = entries;   % cell array  →  JSON array

% Serialise  (PrettyPrint requires R2020b; fall back silently for older releases)
try
    json_str = jsonencode(out, 'PrettyPrint', true);
catch
    json_str = jsonencode(out);
end

% Write file
file_name = [filename_char '.json'];
fid = fopen(file_name, 'w');
if fid == -1
    error('ExportParamsJson: cannot open "%s" for writing.', file_name);
end
fwrite(fid, json_str, 'char');
fclose(fid);

dataCount = sum(cellfun(@(e) ~e.isJunk, entries));
fprintf('ExportParamsJson: wrote %s  (%d data fields, %d padding entries)\n', ...
    file_name, dataCount, n - dataCount);
end

% -------------------------------------------------------------------------
% Local helper
% -------------------------------------------------------------------------
function dims = normalizeDims(d)
% Return dimensions always as a 1-by-2 [rows, cols] array.
d = d(:)';
switch numel(d)
    case 0,  dims = [1, 1];
    case 1,  dims = [d, 1];
    otherwise, dims = d(1:2);
end
end
