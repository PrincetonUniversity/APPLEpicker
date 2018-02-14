function files = readMd5Hashes( hash_file )
% readMd5Hashes reads MD5 hashes from a file.
%
% Syntax
% [ files ] = readMd5Hashes( hash_file );
%
% Input Argument
% ---------------------------------------------------------------------------
% | hash_file |  The name of the file containing the hashes.                |
% ---------------------------------------------------------------------------
%
% Output Argument
% ---------------------------------------------------------------------------
% | files     |  A struct array with two fields: name and hash. The name    |
% |           |  field contains the filename while hash contains its MD5    |
% |           |  hash.                                                      |
% ---------------------------------------------------------------------------
%
% The hash file should be in the format output by the GNU md5sum utility.
%
% Written by Joakim Anden

f = fopen(hash_file, 'r');

files = struct([]);

while ~feof(f)
    line = fgetl(f);

    nfile.name = line(35:end);
    nfile.hash = line(1:32);

    files = cat(1, files, nfile);
end

fclose(f);
end
