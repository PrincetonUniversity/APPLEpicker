function ret = isOctave()
% isOctave determines whether host is running Octave.
%
% Syntax
% [ ret ] = isOctave();
%
% Output Argument
% ---------------------------------------------------------------------------
% | ret       |  True if system is Octave, false if MATLAB.                 |
% ---------------------------------------------------------------------------
%
% Written by Joakim Anden

persistent p_ret;
if isempty(p_ret)
    p_ret = (exist('OCTAVE_VERSION', 'builtin') ~= 0);
end
ret = p_ret;
end
