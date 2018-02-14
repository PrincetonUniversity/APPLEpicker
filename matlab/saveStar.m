function saveStar(filename, data)
% saveStar write a STAR file.
%
% Syntax
% saveStar(filename, data);
%
% Input Arguments
% ----------------------------------------------------------------------
% | filename   |  The filename of the STAR file to write.              |
% | data       |  A struct containing the data to write.               |
% ----------------------------------------------------------------------
%
% Each field of the data struct consists of a loop to be written to the
% STAR file. Note that even if this is a scalar field, it will be written
% to the file as a loop with one row, not as a list. As a result, reading
% a STAR file using read_star and writing it back is not guaranteed to give
% the same STAR file back. However, writing a STAR file using saveStar
% and then reading it back using read_star should always give the same
% result.
%
% Written by Joakim Anden

fid = fopen(filename, 'w');

fields = fieldnames(data);

for k = 1:numel(fields)
    saveStarLoop(fid, fields{k}, getfield(data, fields{k}));
end

fclose(fid);
end

function saveStarLoop(fid, name, star_loop)
fprintf(fid, 'data_%s\n\n', name);

fprintf(fid, 'loop_\n');

labels = fieldnames(star_loop);

for k = 1:numel(labels)
    fprintf(fid, '_%s #%d\n', labels{k}, k);
end

for s = 1:numel(star_loop)
    for k = 1:numel(labels)
        value = getfield(star_loop(s), labels{k});

        if isempty(value)
            fprintf(fid, 'None');
        elseif ischar(value)
            fprintf(fid, '%s', value);
        elseif isinteger(value)
            fprintf(fid, '%d', value);
        elseif isnumeric(value)
            fprintf(fid, '%.16g', value);
        else
            error('values must be strings or numeric variables');
        end

        if k < numel(labels)
            fprintf(fid, '\t');
        end
    end
    fprintf(fid, '\n');
end

fprintf(fid, '\n');
end
