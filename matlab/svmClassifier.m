function [ y_test, resultImg ] = svmClassifier( microImg, bwMask_n, ...
    bwMask_p, N )
% svmClassifier trains and applies an SVM classifier to find areas containing a
% particle.
%
% Syntax
% [ y_test, resultImg ] = svmClassifier( microImg, bwMask_n, bwMask_p, N );
%
% Description
% Input Arguments
% ----------------------------------------------------------------------
% | microImg   |  Micrograph                                           |
% | bwMask_n   |  Binary image. Contains 0's in entries corresponding  |
% |            |  to pixels we are reasonably sure contain noise.      |
% | bwMask_p   |  Binary image. Contains 1's in entries corresponding  |
% |            |  to pixel we are reasonably sure belong to the        |
% |            |  particle.                                            |
% | N          |  Size of each edge of the query image                 |
% ----------------------------------------------------------------------
%
% Output Arguments
% ----------------------------------------------------------------------
% | y_test     |  binary image containing 1's in entries corresponding |
% |            |  to pixels classified as particle                     |
% | resultImg  |  Micrograph displaying clusters of pixels classified  |
% |            |  as particle                                          |
% ----------------------------------------------------------------------
%
% Written by Ayelet Heimowitz

gpuExist = isGpu();

windowsAll = im2col(microImg, [N, N], 'distinct');

if gpuExist
    windowsAll = gpuArray(windowsAll);
end

% Extract non-overlapping windows that most likely contain noise
windows = windowsAll;
indicate = im2col(bwMask_n, [N, N], 'distinct');
[~, cols] = find(indicate==1); % cols contains the columns in windows that contain particle pixels
windows(:, unique(cols)) = [];
n_mu = mean(windows, 1);
n_std = std(windows, 1);

% Extract non-overlapping windows that most likely contain a particle
 windows = windowsAll;
 indicate = im2col(bwMask_p, [N, N], 'distinct');
 [~, cols] = find(indicate==0); % cols contains the columns in windows that contain noise pixels
 windows(:, unique(cols)) = [];
 p_mu = mean(windows, 1);
 p_std = std(windows, 1);

% x is training examples, y is training labels
x = [p_mu(:), p_std(:)];
x = [x; n_mu(:) n_std(:)];
y = [ones(numel(p_mu), 1); zeros(numel(n_mu), 1)];

assert(numel(p_mu)>0, 'Training Error.\nTraining set contains no instances of particle class.');
assert(numel(n_mu)>0, 'Training Error.\nTraining set contains no instances of noise class.');

if gpuExist
    x = gather(x);
end
% train classifier
svmStruct = svmtrain(x, y, 'kernel_function', 'rbf', 'showplot', false);

% classify all possible windows of the micrograph as either
% particle or noise
if gpuExist
    microImgLocal = microImg;
    microImg = gpuArray(microImg);
end

% find mean and variance for each window of the micrograph
filt = ones(N, N) / (N*N);
fftMic = fft2(microImg, size(microImg, 1) + N - 1, size(microImg, 2)+ N - 1);
fft_filt = fft2(filt, size(microImg, 1) + N - 1, size(microImg, 2)+ N - 1);
data = real(ifft2(fftMic.*fft_filt));

varFreq = fft2(microImg.^2, size(microImg, 1) + N - 1, size(microImg, 2)+ N - 1) ...
.* fft2(filt, size(microImg, 1)+ N - 1, size(microImg, 2)+ N - 1);
varAll = real(ifft2(varFreq)) - data.^2;
data2 = sqrt(varAll);

data = data(N : end - (N-1), N : end - (N-1));
data2 = data2(N : end - (N-1), N : end - (N-1));

Xtest = [data(:) data2(:)];

y_test = [];
for temo=1:10000:size(Xtest, 1)
    y_test = [y_test; svmclassify(svmStruct, Xtest(temo:min(temo+9999, end), :))];
end

% remove possible artifacts
%%%for square micrographs
%y_test = reshape(y_test, sqrt(numel(y_test)), []);

%%% for square or rectangular micrographs
y_test = reshape(y_test, size(fft_filt, 1) - 2*(N-1), size(fft_filt, 2) - 2*(N-1));

img = microImg((N/2):end - (N/2), (N/2):end - (N/2));
img = img - min(img(:));
img = img / max(img(:));
img = img * 255;

resultImg = img.*imcomplement(imdilate(bwperim(y_test), ones(3)));

end
