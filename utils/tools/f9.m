function varargout = f9% f9 -- h = figure(9); % Go to/make figure(9) and return handle when requested% See also aa, figure  h = figure(9);if nargout, varargout(1) = {h}; end