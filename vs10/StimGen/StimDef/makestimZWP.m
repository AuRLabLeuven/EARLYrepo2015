function P2=makestimZW(P);
% MakestimRF - stimulus generator for ZW stimGUI (zwuis)
%    P=MakestimZW(P), where P is returned by GUIval, generates the stimulus
%    specified in P. MakestimZW is typically called by StimGuiAction when
%    the user pushes the Check, Play or PlayRec button.
%    MakestimRF does the following:
%        * Complete check of the stimulus parameters and their mutual
%          consistency, while reporting any errors
%        * Compute the stimulus waveforms
%        * Computation and broadcasting info about # conditions, total
%          stimulus duration, Max SPL, etc.
%
%    MakestimZW renders P ready for D/A conversion by adding the following 
%    fields to P
%           Fsam: sample rate [Hz] of all waveforms. This value is
%                 determined by carrier & modulation freqs, but also by
%                 the Experiment definition P.Experiment, which may 
%                 prescribe a minimum sample rate needed for ADC.
%           Fcmp: frequencies [Hz] of all the components in a column array
%          Fprof: profile jump frequencies [Hz] of all the conditions
%       Waveform: Waveform object array containing the samples in SeqPlay
%                 format.
%    Attenuation: scaling factors and analog attuater settings for D/A
%   Presentation: struct containing detailed info on stimulus order,
%                 broadcasting of D/A progress, etc.
% 
%   See also Waveform/maxSPL, Waveform/play, sortConditions, 


P2 = []; % a premature return will result in []
if isempty(P), return; end
figh = P.handle.GUIfig;
EXP = P.Experiment;

% check & convert params. Note that helpers like maxSPL
% report any problems to the GUI and return [] or false in case of problems.

%        i_________Zwuis_______: '_____Zwuis_____'
%                       LowFreq: 5000
%                      HighFreq: 25000
%                         Ncomp: 40
%                      BaseFreq: 0.2000
%                       FreqTol: 20
%                   FreqTolUnit: '%'
%                           Nit: 20
somethingwrong=1;
if P.LowFreq<EXP.minStimFreq,
    GUImessage(figh, {'Low frequency violates min stim frequency'...
        ['of ' num2str(EXP.minStimFreq) ' Hz']},'error', 'LowFreq');
elseif P.HighFreq>EXP.maxStimFreq,
    GUImessage(figh, {'High frequency exceeds max stim frequency'...
        ['of ' num2str(EXP.minStimFreq) ' Hz']},'error', 'HighFreq');
elseif P.LowFreq>P.HighFreq,
    GUImessage(figh, {'Low frequency exceeds High frequency'}, 'error', {'LowFreq' 'HighFreq'});
elseif P.Ncomp<2,
    GUImessage(figh, {'Too few (<2) zwuis components'}, 'error', {'Ncomp'});
elseif P.Ncomp>100,
    GUImessage(figh, {'Too many (>100) zwuis components'}, 'error', {'Ncomp'});
elseif P.BaseFreq<0.1,
    GUImessage(figh, {'Base frequency too low (< 0.1 Hz)'}, 'error', {'BaseFreq'});
elseif P.FreqTol>50,
    GUImessage(figh, {'Frequency tolerance exceeds max of 50%.'}, 'error', {'FreqTol'});
else, % passed the tests..
    somethingwrong=0;
end
if somethingwrong, return; end
% try to realize the zwuis freqs
F_reg = linspace(P.LowFreq, P.HighFreq, P.Ncomp).'; % regular spacing
AvgDF = diff(F_reg(1:2)); % average freq spacing of components
AbsTol = 0.01*P.FreqTol*AvgDF; % absulote value of tolerance (one-sided)
Fbound = [F_reg-AbsTol, F_reg+AbsTol];
Fbound = max(EXP.minStimFreq, Fbound);
Fbound = min(EXP.maxStimFreq, Fbound);
GUImessage(figh, 'Computing zwuis frequencies ...', 'warning');
S = linzwuis(Fbound, P.BaseFreq, P.ZWseed, P.Nit);
GUImessage(figh, 'Computing waveforms ...', 'warning');
if S.Nmult2>0,
    GUImessage(figh, {'Cannot meet zwuis demands. Relax the requirements by either', ...
        'reducing # components, increasing base freq', 'increasing the bandwidth, or increasing maxdev.'}, ...
        'error', {'LowFreq' 'HighFreq' 'Ncomp' 'FreqTol' 'BaseFreq'});
    return;
end
ZwM = find(messenger(), figh, 'ZwuisMess');
report(ZwM, ['Average spacing: ' num2str(round(AvgDF)) ' Hz']);
P.Fsam = sampleRate(S.Freq, EXP); % sample rate in Hz
ReportFsam(figh, P.Fsam/1e3); % in kHz

%  Profile: changing the SPL of either a single or all components
if P.ProfileLowFreq>0 && isequal('all',P.ProfileType),
    GUImessage(figh, {'When ProfileType=all, set Profile frequency to 0 Hz.'}, 'error', {'ProfileLowFreq' 'ProfileType'});
    return;
elseif isequal('all',P.ProfileType) && ~isequal(P.Ncomp, numel(P.ProfileSPLjump)),
    GUImessage(figh, {'When ProfileType=all, SPL change must have as many values as there are freq components.'}, 'error', {'ProfileSPLjump' 'ProfileType'});
    return;
elseif isequal('single cmp',P.ProfileType) && ~isequal(1, numel(P.ProfileSPLjump)),
    GUImessage(figh, {'When ProfileType=single cmp, SPL change must be single value'}, 'error', {'ProfileSPLjump' 'ProfileType'});
    return;
end
switch P.ProfileType,
    case '-',
        SPLjump = zeros(1,P.Ncomp); % no SPL manipulation
        P.ProfileFreq = 0;
    case 'single cmp', % change SPL of single component whose freq is nearest to P.ProfileLowFreq
        i_prof = findnearest(S.Freq, P.ProfileLowFreq);
        P.ProfileFreq = S.Freq(i_prof); 
        SPLjump = zeros(1,P.Ncomp);
        SPLjump(i_prof) = P.ProfileSPLjump;
    case 'all', % change SPL of single component whose freq is nearest to P.ProfileLowFreq
        P.ProfileFreq = 0; 
        SPLjump = P.ProfileSPLjump(:).';
end
P.SPLjump = SPLjump;
Ncond = 1;

%         i_________Pres_______: '_____Pres_____'
%                       TotDur: 10
%                    TotDurUnit: 's'
%                      Baseline: 1000
%                         ISgap: 500
%                       RampDur: 25
%                   RampDurUnit: 'ms'
%                         Order: 'Forward'
%                     PresRseed: 567674973
if 2*P.RampDur>1e3/P.BaseFreq,
    GUImessage(figh, 'Ramp duration exceeds half the base cycle.', ...
        'error', {'RampDur' 'BaseFreq'});
    return;
elseif P.TotDur<1/P.BaseFreq,
    GUImessage(figh, 'Total duration must be at least one base cycle.', ...
        'error', {'TotDur' 'BaseFreq'});
    return;
end
% following is need for sortConditions csall below
[P.Nrep, P.Grouping] = deal(1, 'rep by rep'); 

% Compute the waveforms (P.Waveform) and perform subtle freq corrections
P = local_waveform(P, S);

% report duration
totBaseline = sum(SameSize(P.Baseline,[1 1])); % sum of pre- & post-stim baselines
Ttotal=ReportPlayTime(figh, Ncond, P.Nrep, P.ISI, totBaseline);
% report zwuis details
local_report_zwuisinfo(figh, P);


%       i_________Levels_______: '_____Levels_____'
%                           SPL: 60
%                           DAC: 'Left=Ipsi'
P = sortConditions(P, 'ProfileFreq', 'Profile frequency' , 'Hz', 'Log');

% Levels and active channels (must be called *after* adding the baseline waveforms)
[mxSPL P.Attenuation] = maxSPL(P.Waveform, P.Experiment);
if ~isSingleHandle(figh), % ugly but needed to get stimsam to work
    figh = P.Experiment;
end
okay = CheckSPL(figh, P.SPL, mxSPL, P.ProfileFreq, '', {'SPL'});
if ~okay, return; end

P2=P;

%===================================================
function P = local_waveform(P,S);
% cycle of Fbase must be integer # samples
P.NsamCycle = round(P.Fsam/P.BaseFreq);
P.NsamRamp = round(1e-3*P.Fsam*P.RampDur);
Fbase = P.Fsam/P.NsamCycle;
if ~isfield(P, 'Fzwuis'), P.Fzwuis = Fbase*S.nFreq(:).'; end % allow re-calculation from stored data
Nzwuis = numel(P.Fzwuis);
CycleDur = P.NsamCycle*1e3/P.Fsam; % ms
Ncycle = floor(1e3*P.TotDur/CycleDur); % s->ms
Ncond = numel(P.ProfileFreq);
P.BurstDur = ones(Ncond,1)*(Ncycle*CycleDur + 2*P.RampDur);
P.ISI = P.BurstDur(1) + P.ISgap; % onset-onset interval
SetRandState(P.ZWseed);
P.StartPhase = rand(1,Nzwuis); % starting phases of zwuis components
AllChan = channelSelect(P.DAC, 'LR');
for DAchan=AllChan,
    ichan = 1+double(P.DAC(1)=='B' && DAchan=='R');
    for icond = 1:Ncond,
        SPL = P.SPL + P.SPLjump(icond,:);
        [DL, Dphi] = calibrate(P.Experiment, P.Fsam, DAchan, P.Fzwuis);
        LinAmp = dB2A(SPL+DL)*sqrt(2); % calibrated linear amplitude
        ph0 = P.StartPhase+Dphi; % calibrated starting phase
        w = tonecomplex(LinAmp, P.Fzwuis, ph0, P.Fsam, CycleDur);
        [Rise, Fall] = local_ramps(w, P.NsamRamp);
        Param = CollectInStruct(LinAmp, ph0);
        P.Waveform(icond, ichan) = Waveform(P.Fsam, DAchan, max(abs(w)), P.SPL, ...
            Param, {Rise w Fall}, [1 Ncycle 1]);
        % trailing zeros
        P.Waveform(icond, ichan) = AppendSilence(P.Waveform(icond, ichan), P.ISI);
    end
end
%P,S

function  [Rise, Fall] = local_ramps(w, Nsam);
Wrise = sin(linspace(0,pi/2,Nsam).').^2;
Wfall = flipud(Wrise);
Rise = Wrise.*w(end+1+(-Nsam:-1));
Fall = Wfall.*w(end+1+(-Nsam:-1));
 
function local_report_zwuisinfo(figh, S);
Nfreq = numel(S.Fzwuis);
DZwM = find(messenger(), figh, 'ZwuisInfo');
SPL = S.SPL + S.SPLjump(1,:);
iline = 1; icomp=1;
[Fstr Lstr] = deal('');
StrLen = [];
for ii=1:Nfreq,
    Fstr = [Fstr, sprintf('%2.1f  ', S.Fzwuis(ii)/1e3)];
    Lstr = [Lstr, sprintf('%2.1f', SPL(ii))];
    LD = numel(Fstr)-numel(Lstr);
    Lstr = [Lstr repmat(' ',[1 LD])];
    StrLen(ii) = numel(Fstr);
end
MaxLen = 122;
icut1 = find(StrLen<MaxLen, 1, 'last');
icut2 = find(StrLen<2*MaxLen, 1, 'last');
icut3 = find(StrLen<3*MaxLen, 1, 'last');
Fstr1 = Fstr(1:StrLen(icut1));
Lstr1 = Lstr(1:StrLen(icut1));
Fstr2 = Fstr(StrLen(icut1)+1:StrLen(icut2));
Lstr2 = Lstr(StrLen(icut1)+1:StrLen(icut2));
Fstr3 = Fstr(StrLen(icut2)+1:StrLen(icut3));
Lstr3 = Lstr(StrLen(icut2)+1:StrLen(icut3));
if ~isempty(Fstr1), Fstr1 = [Fstr1 ' kHz']; end
if ~isempty(Fstr2), Fstr2 = [Fstr2 ' kHz']; end
if ~isempty(Fstr3), Fstr3 = [Fstr3 ' kHz']; end
if ~isempty(Lstr1), Lstr1 = [Lstr1 ' dB']; end
if ~isempty(Lstr2), Lstr2 = [Lstr2 ' dB']; end
if ~isempty(Lstr3), Lstr3 = [Lstr3 ' dB']; end

Str = {Fstr1 Lstr1 Fstr2 Lstr2 Fstr3 Lstr3};
report(DZwM, Str);








