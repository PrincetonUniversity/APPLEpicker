function [ ] = parameterCheck(microImg, particleSize, nonOverlap, tp, tn, ...
    boxSize, containerSize, minParticle, maxParticle)
% parameterCheck verifies that the parameters are consistent.
%
% Syntax
% parameterCheck(microImg, particleSize, nonOverlap, tp, tn, boxSize, ...
%    containerSize, minParticle, maxParticle)

assert(isnumeric(particleSize), 'Input particleSize is not of numeric type.');
assert(isnumeric(nonOverlap), 'Input nOverlap is not of numeric type.');
assert(isnumeric(tp), 'Input classifierProps is not of numeric type.');
assert(isnumeric(tn), 'Input classifierProps is not of numeric type.');
assert(isnumeric(boxSize), 'Input qSize is not of numeric type.');
assert(isnumeric(containerSize), 'Input containerSize is not of numeric type.');

assert(numel(particleSize) == 1, 'Input particleSize must be scalar.');
assert(numel(nonOverlap) == 1, 'Input nOverlap must be scalar.');
assert(numel(tp) == 1, 'Input classifierProps must be scalar.');
assert(numel(tn) == 1, 'Input classifierProps must be scalar.');
assert(numel(boxSize) == 1, 'Input qSize must be scalar.');
assert(boxSize>5, 'Input qSize is too small.');

assert(containerSize > boxSize, 'Input containerSize must exceed the value of qSize.');
assert(numel(containerSize) == 1, 'Input containerSize must be scalar.');

assert(isnumeric(minParticle), 'Input minParticle is not of numeric type.');
assert(minParticle >= 0, 'Input minParticle cannot be negative.');
assert(numel(minParticle) == 1, 'Input minParticle must be scalar.');

assert(isnumeric(maxParticle), 'Input maxParticle is not of numeric type.');
assert(maxParticle > 0, 'Input maxParticle cannot be negative.');
assert(numel(maxParticle) == 1, 'Input maxParticle must be scalar.');

assert(particleSize == abs(round(particleSize)), 'Input particleSize must be a positive integer.');
assert(nonOverlap == abs(round(nonOverlap)), 'Input nOverlap must be a positive integer.');
assert(tp == abs(round(tp)), 'Input classifierProps must be an array of positive integers.');
assert(tn == abs(round(tn)), 'Input classifierProps must be an array of positive integers.');
assert(boxSize == abs(round(boxSize)), 'Input qSize must be a positive integer.');
assert(containerSize == abs(round(containerSize)), 'Input containerSize must be a positive integer.');
assert(minParticle == abs(round(minParticle)), 'Input minParticle must be a positive integer.');
assert(maxParticle == abs(round(maxParticle)), 'Input maxParticle must be a positive integer.');

assert(min(size(microImg))>200+2*containerSize, 'Micrograph is too small for chosen containerSize.');
assert(particleSize > boxSize, 'Input particleSize is too small.');

assert(containerSize < min(size(microImg, 1), size(microImg, 2))/2, 'Input containerSize is too large');
assert(boxSize < min(size(microImg, 1), size(microImg, 2))/2, 'Input qSize is too large');
assert(particleSize < min(size(microImg, 1), size(microImg, 2))/2, 'Input particleSize is too large');
assert(nonOverlap < min(size(microImg, 1), size(microImg, 2))/2, 'Input nOverlap is too large');
assert(minParticle < min(size(microImg, 1), size(microImg, 2))/2, 'Input minParticle is too large');
assert(maxParticle < min(size(microImg, 1), size(microImg, 2))/2, 'Input maxParticle is too large');


end
