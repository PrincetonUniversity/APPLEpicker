function [ convMap ] = myInnerLoop( microImg, referenceBoxAll, containerSize )
% myInnerLoop returns an indication for the classification of each reference
% window.
%
% Syntax
% [ convMap ] = myInnerLoop( microImg, referenceBoxAll, containerSize );
%
% Description
% Input Arguments
% -------------------------------------------------------------------------
% | microImg          |  Micrograph                                       |
% | referenceBoxAll   |  Cell arrray containing all NxN query images      |
% | containerSize     |  size of each edge of a container                 |
% -------------------------------------------------------------------------
%
% Output Arguments
% -------------------------------------------------------------------------
% | convMap           |  Cell array containing normalized cross-          |
% |                   |  correlation coefficientss.                       |
% -------------------------------------------------------------------------
%
% Written by Ayelet Heimowitz.

gpuExist = isGpu();

N = size(referenceBoxAll, 1);

numContainersRow = floor(size(microImg, 1)/containerSize);
numContainersCol = floor(size(microImg, 2)/containerSize);

% create 3D array of windows
if gpuExist
    windows = zeros(N, N, numContainersRow*numContainersCol*4, 'gpuArray');
    microImg = gpuArray(microImg);
else
    windows = zeros(N, N, numContainersRow*numContainersCol*4);
end
winIdx = 1;

% use FT to compute the mean of all possible NxN windows in the micrograph
filt = ones(N, N) / (N*N);
meanFreq = fft2(microImg, size(microImg, 1) + size(windows, 1) - 1, ...
    size(microImg, 2) + size(windows, 2) - 1) .* ...
    fft2(filt, size(microImg, 1) + size(windows, 1) - 1, ...
    size(microImg, 2) + size(windows, 2) - 1);
meanAll = real(ifft2(meanFreq));

% use FT to compute the standard deviation of all possible NxN windows in the
% micrograph
varFreq = fft2(microImg.^2, size(microImg, 1) + size(windows, 1) - 1, ...
    size(microImg, 2) + size(windows, 2) - 1) ...
    .* fft2(filt, size(microImg, 1) + size(windows, 1) - 1, ...
    size(microImg, 2) + size(windows, 2) - 1);
varAll = real(ifft2(varFreq)) - meanAll.^2;
stdAll = sqrt(varAll);

% divide the micrograph into containers and find interesting windows in
% each container

for yContain = 1:numContainersRow
    for xContain = 1:numContainersCol
        % temp contains the micrograph in the current container
        temp = microImg((yContain-1)*containerSize+1:min(size(microImg, 1), yContain*containerSize), ...
            (xContain-1)*containerSize+1:min(size(microImg, 2), xContain*containerSize));


        % meanContain and stdContain contain mean and standard deviation of
        % all possible windows in current container
        meanContain = meanAll((yContain-1)*containerSize+N:min(size(meanAll, 1)-(N-1),...
            (yContain-1)*containerSize+containerSize), (xContain-1)*containerSize+N:min(size(microImg, 2),...
            (xContain-1)*containerSize+containerSize));
        stdContain = stdAll((yContain-1)*containerSize+N:min(size(meanAll, 1)-(N-1),...
            (yContain-1)*containerSize+containerSize), (xContain-1)*containerSize+N:min(size(microImg, 2),...
            (xContain-1)*containerSize+containerSize));

        % Find interesting windows (i.e. windows with largest and smallest
        % mean)
        [~, I] = max(meanContain(:));
        [y, x] = ind2sub(size(meanContain), I);
        windows(:, :, winIdx) = temp(y:y+(N-1), x:x+(N-1));
        winIdx = winIdx + 1;
        [~, I] = min(meanContain(:));
        [y, x] = ind2sub(size(meanContain), I);
        windows(:, :, winIdx) = temp(y:y+(N-1), x:x+(N-1));
        winIdx = winIdx + 1;

        % Find interesting windows (i.e. windows with largest and smallest standard deviation)
        [~, I] = max(stdContain(:));
        [y, x] = ind2sub(size(stdContain), I);
        windows(:, :, winIdx) = temp(y:y+(N-1), x:x+(N-1));
        winIdx = winIdx + 1;
        [~, I] = min(stdContain(:));
        [y, x] = ind2sub(size(stdContain), I);
        windows(:, :, winIdx) = temp(y:y+(N-1), x:x+(N-1));
        winIdx = winIdx+1;
    end
end

windows(:,:,winIdx:end) = []; % ensuring no windows containing all zeros remain
% DFT of all windows
windows = fft2(windows);

if gpuExist
    convMap = zeros(size(windows, 3), size(referenceBoxAll, 3), size(referenceBoxAll, 4), 'gpuArray');
else
    convMap = zeros(size(windows, 3), size(referenceBoxAll, 3), size(referenceBoxAll, 4));
end
cx = size(referenceBoxAll, 1);
cy = size(referenceBoxAll, 2);
cz = size(referenceBoxAll, 3);
cn = size(referenceBoxAll, 4);

for index = 1:size(windows, 3)
    window_t = bsxfun(@times, referenceBoxAll, windows(:,:,index));
    cc = real(ifft2(window_t));
    cc = reshape(cc, [cx*cy, cz, cn, 1]);
    convMap(index, :, :) = max(cc, [], 1) - mean(cc, 1);
end

convMap = permute(convMap, [2, 3, 1]);

if gpuExist
    convMap = gather(convMap);
end
end
