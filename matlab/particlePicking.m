function [ classifiedImg, pickedParticleImg, microImg_ds, centers_idx ] = ...
    particlePicking( mName, particleSize, nonOverlap, tp, tn, boxSize, ...
    containerSize, minParticle, maxParticle )
% particlePicking implements template-free particle picking
% from the paper "APPLE Picker: Automatic Particle Picking, a Low-Effort
% Cryo-EM Framework".
%
% Syntax
% [ classifiedImg, pickedParticleImg, microImg_ds, centers_idx ] = ...
%     particlePicking( mName, particleSize, nonOverlap, tp, tn, boxSize, ...
%     containerSize, minParticle, maxParticle )
%
% Description
% Input Arguments
% ----------------------------------------------------------------------------
% | mName          |  Name of mrc file containing the micrograph.            |
% | particleSize   |  Size of each edge of a square containing a             |
% |                |  particle projection.                                   |
% | nonOverlap     |  Constraint on location of picked particles.            |
% |                |  The centers of each 2 particles must be at a           |
% |                |  distance of at least this value.                       |
% | tp             |  number of query images we are reasonably sure          |
% |                |  belong to the particle class                           |
% | tn             |  number of query images that we are reasonably          |
% |                |  sure belong to the noise class                         |
% | boxSize        |  Size of each edge of a query image.                    |
% | containerSize  |  size of each edge of a container.                      |
% | minParticle    |  Minimum size of particle diameter.                     |
% | maxParticle    |  Maximum size of particle diameter.                     |
% ----------------------------------------------------------------------------
%
% Output Arguments
% ----------------------------------------------------------------------------
% | classifiedImg        | Micrograph with classification results            |
% | pickedParticleImg    | Micrograph with boxed particles                   |
% | microImg_ds          | Micrograph with size corresponding to results     |
% | centers_idx          |  coordinates for center of each box               |
% ----------------------------------------------------------------------------
%
% Written by Ayelet Heimowitz

gpuExist = isGpu();

% read micrograph
microImg = loadMrc(mName);

% verify parameters make sense
parameterCheck(microImg, particleSize, nonOverlap, tp, tn,...
    boxSize, containerSize, minParticle, maxParticle);

boxSize = boxSize - mod(boxSize, 2);

microImg = double(microImg);
microImg_full = microImg;

% get rid of the outermost pixels of the micrograph - optional
microImg = microImg(100:size(microImg, 1) - 100, 100:size(microImg, 2) - 100);

% filter micrograph
hf = fspecial('gaussian', [15, 15], 0.5);

% subsample micrograph
microImg = microImg(1:2*floor(end/2), 1:2*floor(end/2));
microImg = imresize(microImg, 1/2);

microImg = imfilter(microImg, hf);
clear hf

Sx = size(microImg, 1); Sy = size(microImg, 2);

microImgLocal = microImg;

% create cell array of query images
if gpuExist
    referenceBox = zeros(boxSize, boxSize, floor(Sy/boxSize) + floor(Sy/boxSize - 0.5), ...
     floor(Sx/boxSize) + floor(Sx/boxSize - 0.5), 'gpuArray');
    microImg = gpuArray(microImg);
else
    referenceBox = zeros(boxSize, boxSize, floor(Sy/boxSize) + floor(Sy/boxSize - 0.5), ...
     floor(Sx/boxSize) + floor(Sx/boxSize - 0.5));
end

a = im2col(microImgLocal(1:floor(2*size(microImg, 1)/boxSize) * boxSize/2,...
    1:floor(2*size(microImg, 2)/boxSize) * boxSize/2), [boxSize/2, boxSize/2], 'distinct');
if gpuExist
    a = gpuArray(a);
end
a = permute(a, [1, 3, 2]);
a = reshape(a, boxSize/2, boxSize/2, []);
b = cat(1, a, a(:,:,[2:end, 1]));
c = cat(2, b, b(:,:,[1+floor(2*size(microImg, 2)/boxSize):end,...
    1:1+floor(2*size(microImg, 2)/boxSize)-1]));

%%% for square micrographs
%referenceBox = reshape(c, [boxSize, boxSize, sqrt(size(c, 3)), sqrt(size(c, 3))]);

% for square or rectangular micrographs
referenceBox = reshape(c, [boxSize, boxSize, floor(2*size(microImg, 1)/boxSize),...
    floor(2*size(microImg, 2)/boxSize)]);

referenceBox(:,:,end, :) = [];
referenceBox(:,:,:,end) = [];

referenceBox = conj(fft2(referenceBox));
clear xCount yCount a b c

% myInnerLoop returns a measure calculated from the cross correlation between referenceBox
% and the query images
[surface] = myInnerLoop(microImg, referenceBox, containerSize);

if gpuExist
    microImg = microImgLocal;
end

minVal = min(surface(:));
maxVal = max(surface(:));
thresh = minVal + (maxVal - minVal)/20;
h = surface>=thresh;
score2 = sum(h, 3);
clear minVal maxVal thresh h

% sanity check for parameters tp, tn
assert(tp<numel(score2), ['for entered micrograph and box size, number of particle examples for training cannot exceed ' num2str(numel(score2)-1)]);
assert(tn<numel(score2), ['for entered micrograph and box size, number of noise examples for training cannot exceed ' num2str(numel(score2)-1)]);

flag_detected = true;
while flag_detected

    % find areas we are reasonably sure contain a particle and areas that may
    % contain a particle
    [ bwMask_p, bwMask_n ] = bestBoxes( microImg, score2, boxSize, tp, tn );

    % Classify micrograph
    [ y_test, classifiedImg] = svmClassifier( microImg, bwMask_n, bwMask_p, boxSize);

    if y_test==ones(size(y_test))
        tn = tn + 1000;
        assert(tn<numel(score2), 'Classifier Error. No particle detected. Using different classifierProps is recommended.');
    elseif y_test==zeros(size(y_test))
        tp = tp + 1000;
        assert(tp<numel(score2), 'Classifier Error. No particle detected. Using different classifierProps is recommended.');
    else
        flag_detected = false;
    end
end

if imfill(y_test, 'holes') == ones(size(y_test))
    y_test(101:end-100, 101:end-100) = 0;
end

y_test_e = imerode(imfill(y_test, 'holes'), strel('disk', minParticle));
y_test_o = imerode(imfill(y_test, 'holes'), strel('disk', maxParticle));
sizeConst = bwlabel(y_test_e);
y_test_e(ismember(sizeConst, unique(nonzeros(sizeConst.*y_test_o)))) = 0;
y_test = y_test_e;

% truncate microImg to be compatible with y_test
microImg_ds = microImg(boxSize/2:end-boxSize/2, boxSize/2:end-boxSize/2);
[  bwMap, centers_idx ] = addWindow( y_test, particleSize, microImg_ds, nonOverlap );

% centers_idx must correspond to centers in original, non-truncated,
% non-downsampled micrograph
centers_idx = centers_idx + boxSize/2 - 1;
centers_idx = 2*centers_idx - 1;
centers_idx = centers_idx + 99;

microImg_ds = microImg_ds - min(microImg_ds(:));
microImg_ds = microImg_ds/max(microImg_ds(:));

bwMap = bwMap - min(bwMap(:));
bwMap = bwMap/max(bwMap(:));
visual1 = ones(size(microImg_ds));
visual1(find(bwperim(bwMap))) = 0;
visual1 = imerode(visual1, ones(3));
pickedParticleImg = visual1.*microImg_ds;

if gpuExist
    classifiedImg = gather(classifiedImg);
end

% Write output star file
[~, name, ~] = fileparts(mName);
myTable = table(centers_idx(:, 2), centers_idx(:, 1));
myTable.Properties.VariableNames = {'rlnCoordinateX', 'rlnCoordinateY'};
myStruct = table2struct(myTable);
myStar = struct('root', myStruct);

mkdirp(fullfile(pkgRoot(), 'results'));
saveStar(fullfile(pkgRoot(), 'results', [name '.star']), myStar);

end
