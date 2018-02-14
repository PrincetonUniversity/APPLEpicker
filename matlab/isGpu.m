function gpuExist = isGpu()
% isGpu tests to see whether a GPU is present on the host.
%
% Syntax
% [ gpuExist ] = isGpu();
%
% Description
% Output Argument
% ----------------------------------------------------------------------
% | gpuExist    |  A Boolean variable specifying whether a GPU is      |
% |             |  present
% ----------------------------------------------------------------------
%
% Written by Joakim Anden

if exist('gpuDeviceCount')
    gpuExist = (gpuDeviceCount() > 0);
else
    gpuExist = false;
end
end
