function [ windowedImg, centers ] = addWindow( y_test, boxSize, microImg, ...
    nonOverlap )
% addWindow adds a window of size boxSize x boxSize around the center of
% each cluster of particle pixels in y_test
%
% Syntax
% [ windowedImg, centers ] = addWindow( y_test, boxSize, microImg, ...
%    nonOverlap );
%
% Description
% Input Arguments
% ----------------------------------------------------------------------
% | y_test      |  binary image containing 1 in entries corresponding  |
% |             |  to pixels classified as particle                    |
% | boxSize     |  Size of each edge of a square containing a particle |
% |             |  projection.                                         |
% | microImg    |  Micrograph                                          |
% | nonOverlap  |  Constraint on location of picked particles.         |
% |             |  The centers of each 2 particles must be at a        |
% |             |  distance of at least this value                     |
% ----------------------------------------------------------------------
%
% Output Arguments
% ----------------------------------------------------------------------
% | windowedImg |  binary image containing 1 in entries corresponding  |
% |             |  to a box around each picked particle                |
% | centers     |  coordinates for center of each box                  |
% ----------------------------------------------------------------------
%
% Written by Ayelet Heimowitz

gpuExist = isGpu();

y_test = y_test>0;

% remove suspected artifacts
helper = bwareaopen(y_test, boxSize^2);
if gpuExist
    y_test = gpuArray(y_test);
    helper = gpuArray(helper);
end
y_test = bsxfun(@xor, y_test, helper);

if gpuExist
    y_test = gather(y_test);
end

% find center of each cluster
y_test = bwmorph(y_test, 'majority');
stat = regionprops(y_test, 'Centroid');
locs = struct2cell(stat)';
centers  = cell2mat(locs);
centers = round(centers);

% remove clusters not fully contained in microImg
[extraIdx, ~] = find(centers < floor(boxSize/2) + 1);
centers(extraIdx, :) = [];
assert(~isempty(centers), ...
    ['Classifier Error. No particle detected. Using different ' ...
     'classifierProps is recommended.'])
centers_idx = sub2ind(size(y_test), centers(:, 2), centers(:, 1));

% place box around center
windowedImg = zeros(size(y_test));
windowedImg(centers_idx) = 1;
windowedImg = imdilate(windowedImg, ones(nonOverlap));

stat = regionprops(windowedImg>0, 'pixelList');
locs = struct2cell(stat)';
% If there is any overlap between boxes then the size of a connected region
% will be larger than nonOverlap*nonOverlap
a = cellfun(@(x) size(x, 1)==(nonOverlap*nonOverlap), locs);
locs(find(a)) = [];
locs2  = cellfun(@(x) sub2ind(size(y_test), x(:, 2), x(:, 1)), locs, ...
    'UniformOutput', false);
locs2 = cell2mat(locs2);
windowedImg(locs2) = 0;

% find centers
stat = regionprops(logical(windowedImg), 'Centroid');
centers = struct2cell(stat)';
centers  = cell2mat(centers);

centers = round(centers);
assert(~isempty(centers), 'Classifier Error. No particle detected.')

[extraIdx, ~] = find(centers < floor(boxSize/2) + 1);
centers(extraIdx, :) = [];

if mod(boxSize, 2)==0
    [extraIdx, ~] = ...
        find(centers(:, 2) > size(microImg, 1) - floor(boxSize/2) + 1);
else
    [extraIdx, ~] = ...
        find(centers(:, 2) > size(microImg, 1) - floor(boxSize/2));
end
centers(extraIdx, :) = [];

if mod(boxSize, 2)==0
    [extraIdx, ~] = find(centers(:, 1) > size(microImg, 2) - floor(boxSize/2) + 1);
else
    [extraIdx, ~] = find(centers(:, 1) > size(microImg, 2) - floor(boxSize/2));
end
centers(extraIdx, :) = [];
centers_idx = sub2ind(size(y_test), centers(:, 2), centers(:, 1));

windowedImg = zeros(size(windowedImg));
windowedImg(centers_idx) = 1;

windowedImg = imdilate(windowedImg, ones(boxSize));
centers = [centers(:, 2), centers(:, 1)];
end
