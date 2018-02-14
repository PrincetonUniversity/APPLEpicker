function downloadKlh( url, location )
% downloadKlh downloads the KLH dataset.
%
% Syntax
% downloadKlh( url, location );
%
% Input Arguments
% ---------------------------------------------------------------------------
% | url       |  The base URL from which the dataset should be downloaded.  |
% |           |  By default, this is:                                       |
% |           |    http://emg.nysbc.org/prtl_data/klh/klh_1k/               |
% |           |    exposure2.mrc.tar.gz                                     |
% | location  |  The location in which the dataset should be stored. By     |
% |           |  default this is in the subfolder 'data/klh'.               |
% ---------------------------------------------------------------------------
%
% This function downloads the KLH dataset, which is of size 384 MB.
%
% Written by Joakim Anden

if nargin < 1 || isempty(url)
    url = ...
        'http://emg.nysbc.org/prtl_data/klh/klh_1k/exposure2.mrc.tar.gz';
end

dataset = 'klh';

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

ind = find(url=='/', 1, 'last');
filename = url(ind+1:end);

filepath = fullfile(location, filename);

fprintf('Downloading...');
urlwrite(url, filepath);
fprintf('OK\n');

current_dir = pwd();

[filepath_p, filepath_n, filepath_e] = fileparts(filepath);
filepath_n = [filepath_n filepath_e];

cd(filepath_p);

fprintf('Unzipping...');
unzipped_files = gunzip(filepath_n);
delete(filepath_n);
if numel(unzipped_files) == 1 && strcmp(unzipped_files{1}(end-3:end), '.tar')
    untarred_files = untar(unzipped_files{1});
    delete(unzipped_files{1});
    unzipped_files = untarred_files;
end
fprintf('OK\n');

cd(current_dir);

fprintf('Verifying MD5 hashes...');
verified = verifyMd5Hashes(location, hash_file);
fprintf('OK\n');

if ~verified
    warning(['Downloaded ' dataset ' dataset does not verify MD5 hashes.']);
end
end
