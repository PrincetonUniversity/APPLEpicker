function [ bwMask_p, bwMask_n ] = bestBoxes( microImg, score2, boxSize, ...
    tp, tn )
% bestBoxes returns an initial classification of pixels.
% This function receives the micrograph, and a characterization of each query
% image. tp and tn determines what is considered to be a particle or noise
% window.
%
% Syntax
% [ bwMask_p, bwMask_n ] = bestBoxes( microImg, score2, boxSize, tp, tn);
%
% Description
% Input Arguments
% ---------------------------------------------------------------------
% | microImg       |  Micrograph                                      |
% | score2         |  Characterization of each query image.           |
% | boxSize        |  Size of each edge of the query image.           |
% | tp             |  number of query images we are reasonably sure   |
% |                |  belong to the particle class                    |
% | tn             |  number of query images that we are reasonably   |
% |                |  sure belong to the noise class                  |
% ---------------------------------------------------------------------
%
% Output Arguments
% ---------------------------------------------------------------------
% | bwMask_p      |  Binary image. Contains 1's in the tp query       |
% |               |  images we are reasonably sure belong to the      |
% |               |  particle.                                        |
% | bwMask_n      |  Binary image. Contains 1's in the tn query       |
% |               |  images we are reasonably sure are not noise.     |
% ---------------------------------------------------------------------
%
% Written by Ayelet Heimowitz

% find query images that most likely contain a particle
[order, idx] = sort(score2(:), 'descend');
[y, x] = ind2sub(size(score2), idx(1:tp));

bwMask_p = zeros(size(microImg));
for j=1:numel(y)
    bwMask_p((y(j)-1)*(boxSize/2)+1:(y(j)-1)*(boxSize/2)+boxSize, (x(j)-1)*(boxSize/2)+1:(x(j)-1)*(boxSize/2)+boxSize) = 1;
end

% % remove suspected artifacts - optional
% stat = regionprops(logical(bwMask_p), 'BoundingBox', 'PixelIdxList');
% statBox = cat(1, stat.BoundingBox);
% blob2Remove = find(max(statBox(:, 3:4), [], 2)>3*boxSize);
% for j=1:numel(blob2Remove)
%     bwMask_p(getfield(stat, {blob2Remove(j)}, 'PixelIdxList', {})) = 0;
% end

[y, x] = ind2sub(size(score2), idx(tp+1:size(order)-tn));
bwMask_n = bwMask_p;

for j=1:numel(y)
    bwMask_n((y(j)-1)*(boxSize/2)+1:(y(j)-1)*(boxSize/2)+boxSize, (x(j)-1)*(boxSize/2)+1:(x(j)-1)*(boxSize/2)+boxSize) = 1;
end
end
