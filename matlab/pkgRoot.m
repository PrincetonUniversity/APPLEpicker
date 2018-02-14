% pkgRoot determines the root directory of the package.
%
% Syntax
% [ root ] = pkgRoot();
%
% Description
% Output Argment
% ---------------------------------------------------------------------------
% | root      |  The root directory of the package.                         |
% ---------------------------------------------------------------------------
%
% Written by Joakim Anden

function root = pkgRoot()
full_path = mfilename('fullpath');

[root, ~, ~] = fileparts(full_path);

ind = find(root == filesep, 1, 'last');

root = root(1:ind-1);
end
