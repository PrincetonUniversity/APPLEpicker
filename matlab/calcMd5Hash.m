function md5_str = calcMd5Hash( input, is_string )
% calcMd5Hash calculates MD5 hash for array or file.
%
% Syntax
% md5_str = calcMd5Hash( filename );
% md5_str = calcMd5Hash( input, true );
%
% Description
% Input Arguments
% ---------------------------------------------------------------------------
% | filename  |  The filename of the file whose MD5 hash is to be computed. |
% | input     |  An array whose MD5 hash is to be computed.                 |
% ---------------------------------------------------------------------------
%
% Output Argument
% ---------------------------------------------------------------------------
% | md5_str   |  The MD5 hash of the data in the form of a hexadecimal      |
% |           |  string.                                                    |
% ---------------------------------------------------------------------------
%
% The default behavior is to calclate the MD5 hash of a file, but if the
% second argument is set to true, the MD5 hash of the first argument is
% computed instead.
%
% Written by Joakim Anden

if nargin < 2
    is_string = false;
end

if isOctave()
    if exist('hash', 'builtin') ~= 0
        if ~is_string
            md5_str = hash('md5', fileread(input));
        else
            md5_str = hash('md5', typecast(input, 'char'));
        end
    else
        if ~is_string
            md5_str = md5sum(input);
        else
            md5_str = md5sum(typecast(input, 'char'), true);
        end
    end
else
    digest = java.security.MessageDigest.getInstance('md5');

    if is_string
        digest.update(uint8(input(:)), 0, numel(input));
    else
        f = fopen(input, 'r');

        buffer_len = 65536;

        while ~feof(f)
            [data, data_len] = fread(f, buffer_len, 'uint8');

            if ~isempty(data)
                digest.update(data, 0, data_len);
            end
        end

        fclose(f);
    end

    md5_uint8 = typecast(digest.digest(), 'uint8');

    md5_str = dec2hex(md5_uint8);
    md5_str = reshape(md5_str', 1, 2*numel(md5_uint8));
end

md5_str = lower(md5_str);
end
