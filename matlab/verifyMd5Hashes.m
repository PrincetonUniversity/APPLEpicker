function [ verified, files_ver ] = verifyMd5Hashes( directory, ...
    hash_file, idx )
% verifyMd5Hashes verifies the MD5 hashes in a directory using a hash file.
%
% Syntax
% [ verified, files_v ] = verifyMd5Hashes( directory, hash_file, idx );
%
% Input Arguments
% ---------------------------------------------------------------------------
% | directory |  The root directory containing the files whose MD5 hashes   |
% |           |  are to be verified.                                        |
% | hash_file |  The hash file containing the hashes to compare against.    |
% | idx       |  A subset of files to check. If empty, all files are        |
% |           |  checked (default empty).                                   |
% ---------------------------------------------------------------------------
%
% Output Arguments
% ---------------------------------------------------------------------------
% | verified  |  The root directory containing the files whose MD5 hashes   |
% |           |  are to be verified.                                        |
% | files_ver |  A boolean array corresponding to all hashes in hash_file.  |
% |           |  If the file is missing, the entry is set to false.         |
% ---------------------------------------------------------------------------
%
% Written by Joakim Anden

if nargin < 3
    idx = [];
end

files = readMd5Hashes(hash_file);

if isempty(idx)
    idx = 1:numel(files);
end

for k = 1:numel(idx)
    filename = fullfile(directory, files(idx(k)).name);
    if exist(filename, 'file')
        hash = calcMd5Hash(filename);

        files_ver(k) = strcmp(hash, files(idx(k)).hash);
    else
        files_ver(k) = false;
    end
end

verified = all(files_ver);
end
