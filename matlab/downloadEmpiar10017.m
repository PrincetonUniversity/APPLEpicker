function downloadEmpiar10017( url, location )
% downloadEmpiar10017 downloads the EMPIAR-10017 dataset.
%
% Syntax
% downloadEmpiar10017( url, location );
%
% Input Arguments
% ---------------------------------------------------------------------------
% | url       |  The base URL from which the dataset should be downloaded.  |
% |           |  By default, this is:                                       |
% |           |    ftp://ftp.ebi.ac.uk/pub/databases/empiar/archive/10017/  |
% | location  |  The location in which the dataset should be stored. By     |
% |           |  default this is in the subfolder 'data/empiar10017'.       |
% ---------------------------------------------------------------------------
%
% This function downloads the EMPIAR-10017 dataset, which is of size 5.3 GB.
%
% Written by Joakim Anden

if nargin < 1 || isempty(url)
    url = 'ftp://ftp.ebi.ac.uk/pub/databases/empiar/archive/10017/';
end

dataset = 'empiar10017';

if nargin < 2 || isempty(location)
    location = fullfile(pkgRoot(), 'data', dataset);
end

hash_file = fullfile(pkgRoot(), 'data', 'hashes', dataset);

if ~exist(location, 'dir')
    mkdirp(location);
else
    files = readMd5Hashes(hash_file);

    filenames = {files.name};

    filenames = cellfun(@(x)(fullfile(location, x)), filenames, ...
        'uniformoutput', false);

    if all(cellfun(@(x)(exist(x, 'file')), filenames))
        return;
    end
end

root_dir = 'data/';

files = readMd5Hashes(hash_file);

fprintf('Downloading...');
for k = 1:numel(files)
    filename = fullfile(location, files(k).name);

    subfolder_path = fileparts(filename);

    if ~exist(subfolder_path, 'dir')
        mkdir(subfolder_path);
    end

    file_url = [url root_dir files(k).name];

    urlwrite(file_url, filename);
end
fprintf('OK\n');

fprintf('Verifying MD5 hashes...');
verified = verifyMd5Hashes(location, hash_file);
fprintf('OK\n');

if ~verified
    warning(['Downloaded ' dataset ' dataset does not verify MD5 hashes.']);
end
end
