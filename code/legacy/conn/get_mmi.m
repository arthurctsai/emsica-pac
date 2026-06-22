% get_mmi() setting
%
% Calculating PAC for components
% called by mmi_
% Output: 
% EEGmmi{row, col} = (phase-source = row) → (amplitude-source = col)
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function [EEGmmi, EEG] = get_mmi(s, EEG, varargin)
  defaultsetting = {...
    %  name             type        range   default
    'emsicafolder',     'string',    '',    'ica';...
    'comps',            'real',      [],    [];... % 1:4;...
    'mmimat',          'string',    '',    '';...
    'setfile',          'string',    '',    '';... % full path & setname
    'mmitimerange',     'real',      [],    [];...
    'phasefreq',          'real',      [],    s.mmi.phasefreq; % [1 15];...
    'ampfreq',            'real',      [],    s.mmi.ampfreq; % [25 100]
    'nPhaseFreqs',       'real',      [],    s.mmi.nPhaseFreqs;...
    'nAmpFreqs',         'real',      [],    s.mmi.nAmpFreqs;...
    'PhaseFreq_winsize','real',      [],    2;... 
    'AmpFreq_winsize',  'real',      [],    2;...
    'recompute',        'string',    '',    'on';...
    'ontesting',        'real',      '',    0;... % it will add testing singal on comp 1, 2, and, 3
    };

[g, s] = gparser(s, varargin, defaultsetting); ff = fieldnames(g);
for i = 1:length(ff), eval([ff{i} '=getfield(g,''' ff{i}  ''');']); end % flatten parameters

cd(workingdir);

if nargin<2, EEG=[]; end


%% check idx.txt or idx_manually.txt
if isfile([workingdir 'idx_manually.txt'])
  txtfilename = [s.workingdir 'idx_manually.txt'];
elseif isfile([workingdir 'idx.txt'])
  txtfilename = [workingdir 'idx.txt'];   
else
  disp(['Cannot find idx.txt or idx_manually.txt in ' workingdir]);
  keyboard % that's strange there is no idx.txt!! check it!!
  mdisp('artifact comps are not removed!');
  rmartifact = 'off';
end

%% load EEG
if isempty(setfile)
  setfile = [s.workingdir s.subject '-ongoingeeg.set'];
end


%% delete in case the mmimat is older than studyinfo.m
% studyinfom=[s.studydir 'studyinfo.m'];

%% mmimat
if isempty(mmimat)
  % mmimat = [workingdir s.subject '-EEGmmi_' num2str(mmitimerange(1)/60,'%.1f') '~' num2str(mmitimerange(2)/60,'%.1f') 'min.mat']; 
  mdisp('mmimat must be asigned in mmi_()>get_mmi()');
  keyboard
end

if ontesting
  mmimat = strrep(mmimat, '.mat', '-ontesting.mat');
end

current_cache_settings = struct( ...
  'mmitimerange', mmitimerange, ...
  'phasefreq', phasefreq, ...
  'ampfreq', ampfreq, ...
  'nPhaseFreqs', nPhaseFreqs, ...
  'nAmpFreqs', nAmpFreqs, ...
  'PhaseFreq_winsize', PhaseFreq_winsize, ...
  'AmpFreq_winsize', AmpFreq_winsize, ...
  'ontesting', logical(ontesting), ...
  'algorithm', 'ModIndex_v3-logfreq-v1');
cache_metadata = struct();
cache_settings_verified = true;

recompute = checkrecompute(recompute, mmimat, setfile);
recompute = checkrecompute(recompute, mmimat, txtfilename);

% A cache with verified but incompatible numerical settings is stale for this request.
% Rebuild only that cache, even when the caller asked to reuse valid caches.
if ~recompute
  cached_metadata = load(mmimat, 'cache_metadata');
  if isfield(cached_metadata, 'cache_metadata')
    metadata = cached_metadata.cache_metadata;
    has_verified_settings = ...
      isfield(metadata, 'settings_verified') && ...
      metadata.settings_verified && ...
      isfield(metadata, 'settings');
    if has_verified_settings && ...
        ~isequaln(metadata.settings, current_cache_settings)
      mdisp('yellow', [ ...
        'MMI cache settings do not match the current request. Rebuilding ' ...
        mmimat]);
      recompute = true;
    end
  end
end

%% check logicmatrix
if ~recompute
  mdisp(['OK! ' mmimat ' is newer than ' txtfilename '. Keep it...']);
  cache = load(mmimat);
  EEGmmi = cache.EEGmmi;
  logicmatrix = cache.logicmatrix;
  if isfield(cache, 'cache_metadata')
    cache_metadata = cache.cache_metadata;
    has_verified_settings = ...
      isfield(cache_metadata, 'settings_verified') && ...
      cache_metadata.settings_verified && ...
      isfield(cache_metadata, 'settings');
    cache_settings_verified = has_verified_settings;
  else
    cache_settings_verified = false;
    mdisp('yellow', [ ...
      'Legacy MMI cache has no provenance metadata; numerical settings ' ...
      'cannot be verified.']);
  end
  % % keyboard
  % if length(EEGmmi)<length(logicmatrix)
  %   EEGmmitemp = cell(length(logicmatrix));
  %   [mm,nn]=find(logicmatrix);
  %   EEGmmitemp(mm,nn) = EEGmmi(mm,nn);
  %   EEGmmi = EEGmmitemp; clear EEGmmitemp;
  % end
  logicmat = logicmatrix(comps,comps);

  if all(all(logicmat))
    mdisp(['OK! logicmat is complete. Skip recalculation...']);
    return
  end
  mdisp('yellow', sprintf( ...
    ['The cache file is current but incomplete for the selected components: ' ...
    '%d complete, %d missing connections. Computing only the missing entries...'], ...
    nnz(logicmat), nnz(~logicmat)));
else
if isempty(EEG)
  mdisp('nonewline','');
  EEG=pop_loadset(setfile); 
end
  % initialize
  K = size(EEG.icawinv,2);
  logicmatrix = false(K,K);
  logicmat = logicmatrix(comps,comps);
  EEGmmi = cell(length(logicmatrix));
end
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

if isempty(EEG)
  mdisp('nonewline','');
  EEG=pop_loadset(setfile); 
end

%% setting
for i = 1:length(EEG.event)
  EEG.event(i).type = num2str(EEG.event(i).type);
end
EEG = eeg_checkicaact(EEG);
icaact = EEG.icaact;
if ndims(icaact) > 2
  % Flatten epoched ICA activations to continuous samples so downstream PAC
  % code sees the same shape as datasets that already store 2-D icaact.
  icaact = reshape(icaact, size(icaact,1), []);
end
srate = EEG.srate;

if ~isempty(mmitimerange)
  starttime = max(1, round(mmitimerange(1) * EEG.srate));
  endtime = min(round(mmitimerange(2) * EEG.srate), size(icaact, 2));
  icaact = icaact(:, starttime:endtime); % note. in studyinfo.m s.mmi.timerange in second
end

data_length = size(icaact,2);
EEG.data_length = data_length;

g.mmitimerange = mmitimerange;

% mdisp('Show parameters!');
% g

% PhaseFreqVector= linspace(phasefreq(1),phasefreq(2), nPhaseFreqs);
% AmpFreqVector= linspace(ampfreq(1),ampfreq(2), nAmpFreqs);
% switch from a linear frequency scale to a 10‐based logarithmic scale for the low‐frequency phase (phasefreq) and high‐frequency amplitude (ampfreq). 2025-02-15 arthur@UCSD
PhaseFreqVector = logspace(log10(phasefreq(1)), log10(phasefreq(2)), nPhaseFreqs); % <---------
AmpFreqVector   = logspace(log10(ampfreq(1)),   log10(ampfreq(2)),   nAmpFreqs);   % <---------

Phase_all = zeros(length(comps),nPhaseFreqs,data_length);
Amp_all   = zeros(length(comps),nAmpFreqs,data_length);

if ontesting
  showfigures = 1;
  [signal1, signal2, signal] = mmi_ontesting(EEG, showfigures);
end % if ontesting

% Note, ref. plotmmiconnmat() 2025-02-15 arthur 
%     for cc = 1:C
%       c=cclusters(cc);
%       if contains(s.subject, '7raicar')
%         strtitle_left = ['C' num2str(c ,'%.2d')];
%         strtitle_top = strtitle_left;
%       end
% c is the cluster number, eg. C01, C02, ....
% cc is from 1:C the cc'th column of the conn matrix figure
C = length(comps); % comps 是 mmi_() 伸手跟我要的 comps eg. 2 25 18 ... typically from clusters.txt
for cc = 1:C
  data = icaact(comps(cc),:);
  if ontesting && cc<=11
    kkk = std(data);
    switch cc
      case 3
        data = 0.3*data + 0.7*kkk*signal1/std(signal1);
      case 4
        data = 0.3*data + 0.7*kkk*signal2/std(signal2);
      case 9
        data = 0.3*data + 0.7*kkk*signal/std(signal);
    end
  end % if ontesting

  % ========================ModIndex_v1=========================
  % the eegfilt routine employed below is obtained from the EEGLAB toolbox
  % (Delorme and Makeig J Neurosci Methods 2004)
  for i = 1:nPhaseFreqs % <----- resolution, todo needs to be changed for nPhaseFreqs and nAmpFreqs 

    % OLD (linear offset): 
    % freqrange = [PhaseFreqVector(i), PhaseFreqVector(i) + PhaseFreq_winsize]; % <----

    % NEW (pure log: ±1/2 octave around center):
    freqrange = [PhaseFreqVector(i)/sqrt(2), PhaseFreqVector(i)*sqrt(2)];  % <----
    filtSpec.order=600;
    filtSpec.range=freqrange;
    filtPts = fir1(filtSpec.order, 2/srate*filtSpec.range);  %1x101
    PhaseFreq = conv(data,filtPts,'same');
    Phase_all(cc,i,:)=angle(hilbert(PhaseFreq)); % this is getting the phase time series
  end

  for i = 1:nAmpFreqs % <----- resolution, todo needs to be changed for nPhaseFreqs and nAmpFreqs 
    % OLD (linear offset): 
    % freqrange = [AmpFreqVector(i), AmpFreqVector(i) + AmpFreq_winsize]; % <----

    % NEW (pure log: ±1/2 octave around center):
    freqrange = [AmpFreqVector(i)/sqrt(2), AmpFreqVector(i)*sqrt(2)]; % <----
    filtSpec.order=200; %filter order=500;
    filtSpec.range=freqrange;
    filtPts = fir1(filtSpec.order, 2/srate*filtSpec.range);  %1x101
    AmpFreq = conv(data,filtPts,'same');
    Amp_all(cc,i,:)=abs(hilbert(AmpFreq)); % getting the amplitude envelope
  end
  % ========================ModIndex_v1=========================

end % for cc, the column in the conn matrix figure

% To get the indices m and n of the elements that are 0 in a logical matrix logicmat
[m, n] = find(logicmat == 0);

%% calculate MI
nBins=18;

myparpool(8);
%  myparpool(12); % 28 will be killed in expanse 2025-01-22
mtic = tic;
% Preallocate EEGmmi with empty cells of appropriate size
EEGmmi_temp = cell(length(m), 1); 
nPhaseFreqs = g.nPhaseFreqs;
nAmpFreqs = g.nAmpFreqs;
comps = g.comps;
parfor cc = 1:length(m)
  % Calculate Comodulogram for each k
  Comodulogram = zeros(nPhaseFreqs, nAmpFreqs);
  mdisp([s.subject ' calculating ' num2str(cc) '/' num2str(length(m)) ' k' num2str(comps(m(cc))) '(lfp)->k' num2str(comps(n(cc))) '(hfa)...']);
  for i = 1:nPhaseFreqs
      p = Phase_all(m(cc), i, :);
      for j = 1:nAmpFreqs
          %%%
          a = Amp_all(n(cc), j, :);
          if 0
              % Simple KL-Divergence MI Calculation % <--
              [~, ~, bins] = histcounts(p, linspace(-pi, pi, nBins+1));
              mean_amp = zeros(1, nBins);
              for b = 1:nBins
                  mean_amp(b) = mean(a(bins==b));
              end
              p_dist = mean_amp / sum(mean_amp);
              H = -sum(p_dist .* log(p_dist + eps));
              Comodulogram(i, j) = (log(nBins) - H) / log(nBins); % <--
          else
              [MI, ~] = ModIndex_v3(squeeze(Phase_all(m(cc), i, :)), squeeze(Amp_all(n(cc), j, :)));
              Comodulogram(i, j) = MI';
          end

      %%% Comodulogram(i, j) = MI;
    end
  end
  % Store the result in the temporary variable
  EEGmmi_temp{cc} = Comodulogram;
end

% After the parfor loop, assign values to EEGmmi using comps indices
for cc = 1:length(m)
  EEGmmi{comps(m(cc)), comps(n(cc))} = EEGmmi_temp{cc};
end
logicmatrix(comps,comps)=true;

% % 2025-05-20 arhur add this segment
%   if length(EEGmmi)<length(logicmatrix)
%     EEGmmitemp = cell(length(logicmatrix));
%     [mm,nn]=find(logicmatrix);
%     EEGmmitemp(mm,nn) = EEGmmi(mm,nn);
%     EEGmmi = EEGmmitemp; clear EEGmmitemp;
%   end





mdisp([mmimat ' saved!!']);
cache_metadata.settings = current_cache_settings;
cache_metadata.settings_verified = cache_settings_verified;
cache_metadata.last_requested_comps = comps(:)';
cache_metadata.last_updated = datestr(now, 30);
save(mmimat, 'EEGmmi', 'logicmatrix', 'cache_metadata');
mytoc(toc(mtic));

end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ModIndex_v3(Phase,Amp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% original m-file ModIndex_v1.m
% [MI,MeanAmp] = ModIndex_v1(data,srate,Pf1,Pf2,Af1,Af2)
% changed by rkffabcd 20150130 
function [MI,MeanAmp] = ModIndex_v3(Phase,Amp)
  % Now we search for a Phase-Amp relation between these frequencies by
  % caclulating the mean amplitude of the AmpFreq in each phase bin of the
  % PhaseFreq

  % First we define the bin intervals:

  nbin=18; % % we are breaking 0-360^o in 18 bins, ie, each bin has 20^o
  position=zeros(1,nbin); % this variable will get the beginning (not the center) of each bin (in rads)
  winsize = 2*pi/nbin;
  for j=1:nbin 
    position(j) = -pi+(j-1)*winsize; 
  end


  % now we compute the mean amplitude in each phase:

  MeanAmp=zeros(1,nbin); 
  for j=1:nbin   
    I = and((Phase <  position(j)+winsize) , (Phase >=  position(j)));
    MeanAmp(j)=mean(Amp(I)); 
  end

  % so note that the center of each bin (for plotting purposes) is
  % position+winsize/2

  % at this point you might want to plot the result to see if there's any
  % amplitude modulation

  % % %PLOT Amplitude vs. Phase   
  % % bar(10:20:720,[MeanAmp,MeanAmp]/sum(MeanAmp),'k')
  % % xlim([0 720])
  % % set(gca,'xtick',0:360:720)
  % % xlabel('Phase (Deg)')
  % % ylabel('Amplitude')

  % and next you quantify the amount of amp modulation by means of a
  % normalized entropy index (Tort et al PNAS 2008):

  MI=(log(nbin)-(-sum((MeanAmp/sum(MeanAmp)).*log((MeanAmp/sum(MeanAmp))))))/log(nbin);
  
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% generate phase amplitude coupling signals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [signal1, signal2, signal] = mmi_ontesting(EEG, showfigures)
  % mmi_ontesting() - generate synthetic signals to demonstrate phase-amplitude coupling (pac).
  %
  %   [signal, signal1, signal2] = mmi_ontesting(eeg, showfigures) returns three
  %   synthetic signals designed for testing or illustrating pac analysis.
  %
  %   Inputs:
  %     eeg         - an eeglab eeg structure. only eeg.srate is used here
  %                   to define the sampling rate of the synthetic signals.
  %     showfigures - a logical flag (true or false) that controls whether
  %                   to display plots of the generated signals.
  %
  %   Outputs:
  %     signal1     - a broadband theta signal (4–8 hz).
  %     signal2     - a broadband gamma signal (40–60 hz) whose amplitude is
  %                   modulated by the phase of signal1’s theta.
  %
  %     signal      - a single-channel broadband beta signal (20–30 hz) whose
  %                   amplitude is modulated by a broadband delta phase (1–4 hz).
  %
  %
  %   Description:
  %     1) The function creates a theta signal (4–8 hz) and a gamma
  %        signal (40–60 hz). the gamma amplitude is then modulated by the
  %        theta phase, producing signal2, while signal1 is simply the
  %        theta signal itself.
  %     2) Next, the function first creates a delta signal (1–4 hz) and extracts
  %        its instantaneous phase. it also creates a beta signal (20–30 hz)
  %        and modulates its amplitude by the delta phase. this modulated
  %        beta signal is returned as signal.
  %     3) If showfigures is enabled, the function plots these signals to
  %        visualize their frequency content and amplitude modulation.
  %
  %   Example:
  %     % suppose you have an eeg structure named eeg:
  %     [sigbeta, sigtheta, siggamma] = mmi_ontesting(eeg, true);
  % 
  % History:
  %     2025-02-13 arthur with Chatgpt assistance


  %% Parameters
  fs = EEG.srate;          % Sampling frequency in Hz
  data_length = EEG.data_length;
  t  = [0:(data_length-1)]/fs; % Time vector

  %% Generate a Broadband Delta Signal (1-4 Hz)
  % Start with white noise and bandpass filter to obtain delta band activity.
  deltaNoise = randn(size(t));
  [b_delta, a_delta] = butter(4, [1 4]/(fs/2), 'bandpass');
  deltaSignal = filtfilt(b_delta, a_delta, deltaNoise);

  % Compute the instantaneous phase of the delta signal.
  deltaPhase = angle(hilbert(deltaSignal));

  %% Generate a Broadband Beta Signal (20-30 Hz)
  % Generate white noise and bandpass filter it to obtain beta band activity.
  betaNoise = randn(size(t));
  [b_beta, a_beta] = butter(4, [20 30]/(fs/2), 'bandpass');
  betaSignal = filtfilt(b_beta, a_beta, betaNoise);

  %% Modulate Beta Amplitude Based on Delta Phase
  % Create a modulation envelope using the delta phase.
  % The envelope is highest when delta phase is near 0 (its peak).
  modulationStrength = 1;  % Adjust to control coupling strength
  betaEnvelope = 1 + modulationStrength * cos(deltaPhase);

  % Multiply the beta signal by the envelope.
  betaSignalMod = betaEnvelope .* betaSignal;

  %% Optionally, Combine the Signals
  % You can choose to work only with the modulated beta signal or
  % combine it with the delta signal.
  signal = betaSignalMod;        % Use only modulated beta
  % signal = deltaSignal + betaSignalMod;  % Alternatively, combine both

  %% Plotting the Results

  if showfigures
    figure;

    subplot(4,1,1);
    plot(t, deltaSignal, 'b');
    title('Broadband Delta Signal (1-4 Hz)');
    xlabel('Time (s)');
    ylabel('Amplitude');

    subplot(4,1,2);
    plot(t, deltaPhase, 'r');
    title('Delta Phase');
    xlabel('Time (s)');
    ylabel('Phase (radians)');

    subplot(4,1,3);
    plot(t, betaSignal, 'k');
    title('Broadband Beta Signal (20-30 Hz)');
    xlabel('Time (s)');
    ylabel('Amplitude');

    subplot(4,1,4);
    plot(t, betaSignalMod, 'm');
    title('Beta Signal with Delta-Modulated Amplitude');
    xlabel('Time (s)');
    ylabel('Amplitude');
  end % if showfigures



  %% signal1, signal2
  %% two signals that the theta phase of signal1 modulates the gamma amplitude of signal2.

  %% Parameters
  %         fs = 1000;          % Sampling frequency (Hz)
  %         T  = 10;            % Total time in seconds
  %         t  = 0:1/fs:T-1/fs; % Time vector

  %% Generate a Broadband Theta Signal (4-8 Hz)
  thetaNoise = randn(size(t));            % Generate white noise
  [b_theta, a_theta] = butter(4, [4 8]/(fs/2), 'bandpass');  % 4th-order Butterworth filter for theta band
  thetaSignal = filtfilt(b_theta, a_theta, thetaNoise);       % Filter noise to obtain theta signal
  thetaPhase  = angle(hilbert(thetaSignal));                 % Extract instantaneous phase

  %% Generate a Broadband Gamma Signal (40-60 Hz)
  gammaNoise = randn(size(t));            % Generate white noise
  [b_gamma, a_gamma] = butter(4, [80 100]/(fs/2), 'bandpass');  % 4th-order Butterworth filter for gamma band
  gammaSignal = filtfilt(b_gamma, a_gamma, gammaNoise);       % Filter noise to obtain gamma signal

  %% Modulate Gamma Amplitude Using Theta Phase
  % Create an envelope that peaks when the theta phase is near 0 radians
  modulationStrength = 1;                  % Adjust to control coupling strength
  gammaEnvelope = 1 + modulationStrength * cos(thetaPhase);
  gammaSignalMod = gammaEnvelope .* gammaSignal;  % Apply modulation

  %% Define the Two Signals
  signal1 = thetaSignal;       % Broadband theta signal (4-8 Hz)
  signal2 = gammaSignalMod;    % Gamma signal with amplitude modulated by theta phase (40-60 Hz)

  %% Plot the Results
  if showfigures
    figure;

    subplot(3,1,1);
    plot(t, signal1);
    title('Signal 1: Broadband Theta (4-8 Hz)');
    xlabel('Time (s)'); ylabel('Amplitude');

    subplot(3,1,2);
    plot(t, gammaSignal);
    title('Signal 2: Raw Broadband Gamma (80-100 Hz)');
    xlabel('Time (s)'); ylabel('Amplitude');

    subplot(3,1,3);
    plot(t, signal2);
    title('Signal 2: Gamma with Theta-Modulated Amplitude');
    xlabel('Time (s)'); ylabel('Amplitude');
  end % if showfigures

end
