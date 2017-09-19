function [bestFreq, minNmult, DP, NtotIt] = uberzwuis(Nprim, Norder, Fbase, CF, DF, tolDF, Nit, Nrand);
% uberzwuis - array of freqs with (almost) unique odd-order distortions
%   [bestFreq, Nmult, DP, NtotIt] = uberzwuis(Ncomp, Norder, Fbase, CF, DF, tolDF, Nit, Nrand)
%   determines a set of primary frequencies whose odd-order,
%   unity-sumweight DPs are optimally dissimilar. 
%
%   Inputs
%     Nprim: number of stimulus components ("primaries").
%    Norder: maximum distortion order considered
%     Fbase: smallest quantum of primary frequency determined by the sample 
%            rate and the circular buffer size. All primary frequency are
%            an exact multiple of Fbase.
%        CF: center frequency of primary complex in same units as Fbase.
%        DF: mean spacing between primaries in same units as Fbase.
%     tolDF: tolerance in spacing as a fraction of DF. For instance, when
%            tolDF=0.1, the spacing between adjacent primaries deviates
%            from DF by at most 10% (either negative or positive). Default
%            value is tolDF = 0.15, which is used when tolDF is either
%            omitted or set to [].
%       Nit: maximum # of iterations. Omitting Nit or specifiying [] 
%            results in the default value 1e3.
%     Nrand: void input parameter for "random caching". Nrand is added to 
%            the cache parameters (see putcache). If not specified, Nrand
%            assumes a random integer value between 1 and 3.  This 
%            construction results in a random choice of three possible
%            realizations of the requested uberzwuis set. In order to 
%            complete the set of cached values, explicitly specifiy each of
%            the 3 values at least one time.
%
%    Outputs
%     bestFreq: the optimized set of priary frequencies in the same units
%               as the input frequencies.
%        Nmult: the number of DPs that are not unique.
%           DP: Struct array containing the odd-order distortion products 
%               generated by the bestFreq. See DPfreqs for the format; the
%               frequencies are again in the same units as the input
%               frequencies. The set of DPs is restricted to those having
%               unity sumweight.
%       NtotIt: actual number of iterations used.
%      
%    Uberzwuis uses caching unless a negative Nprim is used (which is then
%    inerpreted as -Nprim).
%
%    See also DPfreqs, baseFrequency.

% defaults
if nargin<6, tolDF = []; end 
if nargin<7, Nit=[]; end; 
if nargin<8, Nrand= RandomInt(10); end % see help text
%
if isempty(tolDF), tolDF = 0.15; end % default: 15% variation around mean spacing DF
if isempty(Nit), Nit=1e3; end; % default # iterations

DoUseCache = (Nprim>0); % see help text
Nprim = abs(Nprim);

CFN = mfilename;
CPM = CollectInStruct(Nprim, Norder, Fbase, CF, DF, tolDF, Nit, Nrand);
if DoUseCache,
    S = getcache(CFN, CPM);
    if ~isempty(S), % get cached value and out of here
        [bestFreq, minNmult, DP, NtotIt] = deal(S.bestFreq, S.minNmult, S.DP, S.NtotIt);
        return;
    end
end

% convert CF and DF to dimensionless params
nCF = CF/Fbase;
nDF = DF/Fbase;
% absolute DF tolerance
nvarDF = (tolDF*DF)/Fbase;

minNmult = inf;
bestFreq = nan;
bestDP = nan;
NtotIt = 0;
for iit=1:Nit,
    freq = cumsum(round(nDF-nvarDF)+RandomInt(round(2*nvarDF),[1 Nprim]));
    freq = freq+round(nCF-mean(freq));
    DP = DPfreqs(freq,Norder,1);   %last 1 arg means: restrict to sum-of-weights =1
    DP = DP([DP.sumweight]==1); 
    Nmult = numel(DP([DP.mult]>1));
    NtotIt = iit;
    if Nmult<minNmult,
        bestFreq = freq;
        bestDP = DP;
        minNmult = Nmult;
    end
    if minNmult==0, break; end
end
Ndp = numel(DP);

% convert the results to physical frequencies
bestFreq = Fbase*bestFreq;
[DP.freq] = DealElements(Fbase*[DP.freq]);

% cache the result
S = CollectInStruct(bestFreq, minNmult, DP, NtotIt); 
putcache(CFN, 1e4, CPM, S);




