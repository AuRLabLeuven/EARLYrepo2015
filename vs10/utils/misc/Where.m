function loc = Where(loc);
% WHERE - location
%   WHERE returns a character string identifying the location of this
%   computer. If not set, the string '**' is returned and a warning is
%   given.
%
%   WHERE('Foo') sets the location to Foo. Foo must be valid Matlab
%   identifier.
%
%   See also SETCOMPUNAME, ISVARNAME.

if nargin<1, % get
    loc = MyFlag('where___'); % try to retrieve from persistent flag (no file I/O)
    if isempty(loc),
        loc = FromSetupFile('ComputerProps', 'Location', '-default', '**');
        if isequal('**', loc),
            warning('Location of this computer is unknown. Use WHERE to fix location.');
        end
        MyFlag('where___', loc); % store as persistent flag
    end
else, % set
    if ~isvarname(loc),
        error('Computer location must be valid Matlab identifier. See ISVARNAME.')
    end
    ToSetupFile('ComputerProps', '-propval', 'Location', loc);
    MyFlag('where___', loc); % store also as persistent flag
end



