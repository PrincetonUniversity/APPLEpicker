function [] = ApplePicker(path, particleSize, varargin)
% ApplePicker gathers necessary parameters for picking routines. In
% addition, this function displays result images when requested by user.
% This function can run in batch mode, in which case many micrographs are
% processed sequentially or in single mode, in which case a single
% micrograph is processed.
%
% Syntax
% ApplePicker( path, particleSize, varargin );
%
% Description
% Input Arguments
% -------------------------------------------------------------------------
% | path        |  When running in batch mode contains a path to a folder |
% |             |  containing all micrographs to be processed. When       |
% |             |  running in single mode contains the path to and name of|
% |             |  of a .mrc file.                                        |
% | particleSize|  Size of each edge of a square containing a particle    |
% |             |  projection.                                            |
% | varargin    |  See below.                                             |
% -------------------------------------------------------------------------
%
% Possible additional arguments are:
%
% 'nOverlap' - The pair 'nOverlap' and integer value specify the necessary
% distance between the centers of two nearby projections.
% Example usage: ApplePicker('/Micrographs', 78, 'nOverlap', 60, ...);
%
% 'qSize' - The pair 'qSize' and integer value specify the size of a query
% image.
% Example usage: ApplePicker('/Micrographs', 78, 'qSize', 52, ...);
%
% 'classifierProps' - The pair 'classifierProps' and a 2x1 vector specify
% the number of query image we are reasonably certain contain a particle and
% the number of query images we are reasonably cenrtain contain noise
% Example usage: ApplePicker('/Micrographs', 78, 'classifierProps', [800; 8000], ...);
%
% 'containerSize'- The pair 'containerSize' and integer value specify the
% size of each edge of a container.
% Example usage: ApplePicker('/Micrographs', 78, 'containerSize', 450, ...);
%
% 'minParticle' - The pair 'minParticle' and integer value specify the
% Minimum size of particle diameter.
% Example usage: ApplePicker('/Micrographs', 78, 'minParticle', 20, ...);
%
% 'maxParticle' - The pair 'maxParticle' and integer value specify the
% Maximum size of particle diameter.
% Example usage: ApplePicker('/Micrographs', 78, 'maxParticle', 110, ...);
%
% 'showImages' - True if user would like to display result images, Default:
% false.
% Example usage: ApplePicker('/Micrographs', 78, 'showImages', true, ...);
%
% Written by Ayelet Heimowitz

warning('off', 'all');

assert(nargin>1, 'Not enough input arguments.');
if isempty(strfind(path, '.mrc'))
    mNames = dir([path '/*.mrc']);
    mNames = {mNames.name};
    addpath(path);
else
    mNames = {path};
    path = '';
end

v = find(cellfun(@(x) isequal(x, 'nOverlap'), varargin));
% if no maximal overlap defined, use approsimately 10% of particle size
if isempty(v)
    nonOverlap = round(particleSize/10);
else
    nonOverlap = varargin{v+1};
end

% if the box size is unspecified use box of size
% (2*particleSize/3)x(2*particleSize/3) pixels
v = find(cellfun(@(x) isequal(x, 'qSize'), varargin));
if isempty(v)
    boxSize = round(2*particleSize/3);
else
    boxSize = varargin{v+1};
end

if mod(boxSize, 2)==1
    boxSize = floor(boxSize/2)*2;
    if ~isempty(v)
        fprintf('Parameter boxSize expected to be even. Reducing to %d\n', boxSize);
    end
end

% if number of examples for classifier training is
% unspecified, use approximately 5% of query images for
% particle examples and approximately 30% for noise examples
v = find(cellfun(@(x) isequal(x, 'classifierProps'), varargin));
if isempty(v)
    [r, c] = size(loadMrc(fullfile(path, mNames{1})));
    boxPerRow = floor(r/boxSize) + floor((r-boxSize/2)/boxSize);
    boxPerCol = floor(c/boxSize) + floor((c-boxSize/2)/boxSize);
    tp = floor(5*boxPerRow*boxPerCol/100);
    tn = floor(30*boxPerRow*boxPerCol/100);
else
    tp = varargin{v+1}(1);
    tn = varargin{v+1}(2);
end

% if container size unspecified aim for approximately 300 reference
% windows
v = find(cellfun(@(x) isequal(x, 'containerSize'), varargin));
if isempty(v)
    [r, c] = size(loadMrc(fullfile(path, mNames{1})));
    containerSize = floor(min(r, c) / 18);
else
    containerSize = varargin{v+1};
end

% if minimum of particle size unspecified use boxSize
v = find(cellfun(@(x) isequal(x, 'minParticle'), varargin));
if isempty(v)
    minParticle = boxSize;
else
    minParticle = varargin{v+1};
end

% if maximum of particle size unspecified use 2*particleSize
v = find(cellfun(@(x) isequal(x, 'maxParticle'), varargin));
if isempty(v)
    maxParticle = 5*particleSize/3;
else
    maxParticle = varargin{v+1};
end

v = find(cellfun(@(x) isequal(x, 'showImages'), varargin));
if isempty(v)
    showImages = false;
else
    showImages = varargin{v+1};
end

for i=1:numel(mNames)
    fprintf('processing image %d....\n', i);
    [classifiedImg, pickedParticleImg, microImg_ds, centers_idx] = ...
        particlePicking(fullfile(path, mNames{i}), round(particleSize/2), round(nonOverlap/2), tp, tn,...
        round(boxSize/2), round(containerSize/2),...
        round(minParticle/4), round(maxParticle/4));
    if showImages
        figure; imagesc(microImg_ds); colormap gray
        axis equal
        set(gca,'xtick',[])
        set(gca,'YTick',[])
        axis([1, size(microImg_ds, 1), 1, size(microImg_ds, 2)])
        figure; imagesc(classifiedImg); colormap gray
        axis equal
        set(gca,'xtick',[])
        set(gca,'YTick',[])
        axis([1, size(microImg_ds, 1), 1, size(microImg_ds, 2)])
        figure; imagesc(pickedParticleImg); colormap gray
        axis equal
        set(gca,'xtick',[])
        set(gca,'YTick',[])
        axis([1, size(microImg_ds, 1), 1, size(microImg_ds, 2)])
    end
end

end
