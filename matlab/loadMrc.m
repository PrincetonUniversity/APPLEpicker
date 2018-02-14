function [x, header] = loadMrc( filename, start, num )
% loadMrc extracts slices from an MRC file.
%
% Syntax
% [ x, header ] = loadMrc( filename, start, num );
%
% Description
% Input Arguments
% ---------------------------------------------------------------------
% | filename  |  The filename of the MRC file.                        |
% | start     |  The starting number of the slices to be extracted    |
% |           |  (default 1).                                         |
% | num       |  The number of slices to extract. If set to Inf, all  |
% |           |  slices after start will be returned (default Inf).   |
% ---------------------------------------------------------------------
%
% Output Arguments
% ---------------------------------------------------------------------
% | x         |  The slices, arranged in an array of size N(1)-by-    |
% |           |  N(2)-by-n, where N are the slice dimensions from     |
% |           |  header.N and n are the number of slices extracted.   |
% | header    |  The header structure obtained from the MRC file.     |
% ---------------------------------------------------------------------
%
% Written by Joakim Anden

if nargin < 2 || isempty(start)
    start = 1;
end

if nargin < 3 || isempty(num)
    num = Inf;
end

mrc = mrcOpen(filename);

mrcSkip(mrc, start-1);

x = mrcRead(mrc, num);

mrcClose(mrc);

header = mrc.header;
end

function mrc = mrcOpen(filename)
fd = fopen(filename, 'r', 'ieee-le');

h = mrcHeader(fd);

check_header(h);

mrc.fd = fd;
mrc.header = h;

datatypes = {'int8', 'int16', 'single'};

mrc.data_type = datatypes{mrc.header.mode+1};

data_widths = [1 2 4];

mrc.data_width = data_widths(mrc.header.mode+1);
end

function h = mrcHeader(f)
h.N = fread(f, 3, 'uint32');

h.mode = fread(f, 1, 'uint32');

h.nstart = fread(f, 3, 'int32');

h.m = fread(f, 3, 'uint32');

h.cella = fread(f, 3, 'float32');

h.cellb = fread(f, 3, 'float32');

h.mapcrs = fread(f, 3, 'uint32');

h.dmin = fread(f, 1, 'float32');
h.dmax = fread(f, 1, 'float32');
h.dmean = fread(f, 1, 'float32');

h.ispg = fread(f, 1, 'uint32');

h.nsymbt = fread(f, 1, 'uint32');

h.extra = fread(f, 25, 'uint32');

h.origin = fread(f, 3, 'float32');

h.map = char(fread(f, 4, 'uchar'))';

h.machst = fread(f, 1, 'uint32');

h.rms = fread(f, 1, 'float32');

h.nlabl = fread(f, 1, 'uint32');

h.label = char(fread(f, 10*80, 'uchar'));
h.label = reshape(h.label, [80 10])';
end

function check_header(h)
% Check against specification.
if ~ismember(h.mode, 0:4)
    error('MODE must be in the range 0 through 4');
end

if (~all(ismember(h.mapcrs, 1:3)) || numel(unique(h.mapcrs)) ~= 3) && ...
    ~all(h.mapcrs == 0)

    error(['MAPC, MAPR and MAPS must form a permutation of {1, 2, 3} ' ...
        'or all equal 0.']);
end

% Check against current capabilities.
if ismember(h.mode, 3:4)
    error('Transform data (MODE 3 and 4) currently not supported');
end

if h.nsymbt > 0
    error('Files with symmetry data currently not supported');
end
end

function x = mrcRead(mrc, n)
if nargin < 2 || isempty(n)
    n = Inf;
end
N = mrc.header.N(1:2);

[x, count] = fread(mrc.fd, prod(N)*n, ['*' mrc.data_type]);

x = reshape(x, [N' count/prod(N)]);
end

function mrcSkip(mrc, s)
N = mrc.header.N(1:2);

fseek(mrc.fd, prod(N)*s*mrc.data_width, 0);
end

function mrcClose(mrc)
fclose(mrc.fd);
end
