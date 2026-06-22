% plot_S_spect_and_mmi() (s, S, emsicafolder)
%
% called by get_synthX()
% Standalone Usage:
% plot_S_spect_and_mmi('zm02',[],[],'2epochs/EPs-synth/',1,'EEG.synthSourceClean');
% Output:
% ~/1_zen/zm01/2epochs/EPs-synth/S_spect.png is printed for checking synthetic signals.
% ~/1_zen/zm01/2epochs/EPs-synth/S_mmi.png is printed for checking synthetic mmi matrix.
%
% 1) Plot power spectrum of synthetic sources S (K signals) and save S_spect.png
% 2) Compute and plot MMI comodulograms using get_mmi() and save S_mmi.png
%
% Inputs:
%   s            : subject struct (will call get_info(s))
%   EEG          : can be [] or EEG structure
%   S            : S, [K x T]
%   emsicafolder : e.g., '6emsica/ICs-synth/'
%   plotmmi      : 1 = also compute/save S_mmi.png; 0 = skip MMI and only save S_spect.png
%   source_mode  : "EEG.icaact" | "EEG.synthSourceClean"
%                  "EEG.icaact" uses the saved component activations in the
%                  set file. For synth truth data in 2epochs/EPs-synth/,
%                  this is the observed/noisy temporal truth, approximately
%                  S + pinv(A)*noise.
%                  "EEG.synthSourceClean" uses the clean latent source
%                  matrix saved by get_synthX(), i.e. synthS reshaped back
%                  to K x T. Use this when you want the clean synthetic
%                  truth rather than the noisy observed source time courses.
%
% Examples:
%   s='zm02'; emsicafolder = '6emsica/ICs-synth/';
%   plot_S_spect_and_mmi(s,[],[], emsicafolder, 1, 'EEG.icaact');
%   % For estimated ICA/EMSICA result folders, use "EEG.icaact".
%
%   s='zm02'; emsicafolder = '2epochs/EPs-synth/';
%   plot_S_spect_and_mmi(s,[],[], emsicafolder, 1, 'EEG.synthSourceClean');
%   % For synthetic truth folders, use "EEG.synthSourceClean".
% You can compare
% s='zm01'; emsicafolder = '6emsica/ICs-synth';
% plot_S_spect_and_mmi(s,[],[], emsicafolder, 1, 'EEG.icaact');
% with
% mmi_(s,'recompute','on','emsicafolder',emsicafolder, 'clusterstxt','~/1_zen/7raicar-synth/6emsica/ICs-synth/clusters.txt', 'cclusters',[1 4 3 2], 'cclusters_mytext',{'lfronto-striatal', 'precuneus', 'VIS', 'orbitofrontal-thalamic'}, 'interval','breathing', 'getconnonly','off');
%
% 2026-02-5 arthur
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function [EEGmmitmp] = plot_S_spect_and_mmi(s, EEG, S, emsicafolder, plotmmi, source_mode)
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

close all;
if nargin < 5 || isempty(plotmmi)
  plotmmi = 1;
end
if nargin < 6 || isempty(source_mode)
  source_mode = "EEG.icaact";
end
plotmmi = logical(plotmmi);
source_mode = lower(string(source_mode));
% ------------------------
% Basic setup
% ------------------------
s = get_info(s);
workingdir = [s.subjectdir emsicafolder];

% Load EEG (for fs and get_mmi().)
if ~isstruct(EEG)
  setfile = [workingdir s.subject '.set'];
  if ~isfile(setfile)
    error('Cannot find setfile: %s', setfile);
  end
  EEG = pop_loadset(setfile);
end

if isempty(S)
  [S, EEG] = select_source_matrix_local(EEG, emsicafolder, source_mode);
end

K = size(S,1);
fs  = EEG.srate;

% ------------------------
% Fixed parameters (edit here if needed)
% ------------------------
freqrange = [1 150];     % for spectopo and plots
use_half  = 1;           % 1: use last half of S for MMI (as you did)
PhaseFreq_winsize = 0.5;
AmpFreq_winsize   = 8;
recompute = 'on';
mmimat    = 'mmitmp.mat';
visible   = 'on';
pct_cmax  = 99.5;

% Choose segment for MMI
if use_half
  T = size(S,2);
  S_mmi = S(:, floor(T/2)+1:end);
else
  S_mmi = S;
end

% =========================================================================
% (1) Plot S power spectrum
% =========================================================================
figure('Visible', visible);
tlo = tiledlayout(K, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
str = [s.subject ' | ' emsicafolder ' | S power spectrum'];
sgtitle(tlo, str, 'Interpreter','none');


for k = 1:K
    ax = nexttile(tlo);
    [spec, freqs] = spectopo(S(k,:), 0, fs, 'freqrange', freqrange, 'plot', 'off');
    plot(ax, freqs, spec, 'LineWidth', 1.2);
    xlim(ax, [freqrange(1) freqrange(2)]);
    grid(ax, 'on');
    title(ax, ['Signal ' num2str(k)]);
    if k == K, xlabel(ax, 'Frequency (Hz)'); end
    ylabel(ax, 'Log Power (dB)');
end

png_spect = [workingdir 'S_spect.png'];
print('-dpng', png_spect);
mdisp('yellow', [png_spect ' is printed for checking synthetic signals.']);

if ~plotmmi
  EEGmmitmp = [];
  mdisp('yellow', 'plot_S_spect_and_mmi(): skip S_mmi.png because plotmmi == 0.');
  return
end

% =========================================================================
% (2) Compute MMI conn using get_mmi
% =========================================================================
args = {'emsicafolder', emsicafolder, 'comps', 1:K, ...
  'setfile', [s.subject '-ongoingeeg.set'], ...
  'ampfreq', s.mmi.ampfreq, 'phasefreq', s.mmi.phasefreq, ...
  'nAmpFreqs', s.mmi.nAmpFreqs, 'nPhaseFreqs', s.mmi.nPhaseFreqs, ...
  'PhaseFreq_winsize', PhaseFreq_winsize, ...
  'AmpFreq_winsize', AmpFreq_winsize, ...
  'recompute', recompute, 'mmimat', mmimat};

EEGsyn = EEG;
EEGsyn.icaact = S_mmi;

if ~isfile([workingdir 'idx.txt'])
  gen_dummy_idx(s, K, workingdir);
end

[EEGmmitmp, ~] = get_mmi(s, EEGsyn, args{:});

% =========================================================================
% (3) Plot KxK MMI with shared color scale + log axes
% =========================================================================
phasefreq  = s.mmi.phasefreq;  nPhaseFreqs = s.mmi.nPhaseFreqs;
ampfreq    = s.mmi.ampfreq;    nAmpFreqs   = s.mmi.nAmpFreqs;

xvals = logspace(log10(phasefreq(1)), log10(phasefreq(2)), nPhaseFreqs);
yvals = logspace(log10(ampfreq(1)),   log10(ampfreq(2)),   nAmpFreqs);
empty_tile = zeros(numel(yvals), numel(xvals));

allv = [];
for ii = 1:K
  for jj = 1:K
    v = EEGmmitmp{jj,ii};
    if ~isempty(v)
      allv = [allv; v(:)];
    end
  end
end
if isempty(allv)
  cmax = 1;
else
  cmax = prctile(allv, pct_cmax);
  if ~isfinite(cmax) || cmax <= 0, cmax = max(allv); end
end

fig = figure('Visible', visible);
tlo = tiledlayout(K, K, 'TileSpacing', 'none', 'Padding', 'none');
tlo.Units = 'normalized';
tlo.Position = [0.06 0.08 0.76 0.82];
str = [s.subject ' | ' emsicafolder ...
       ' | S->MMI (cmax p' num2str(pct_cmax,'%.1f') '=' num2str(cmax,'%.3g') ')'];
sgtitle(tlo, str, 'Interpreter','none');
phase_ticks = local_keep_ticks(phasefreq, [5 10 15]);
amp_ticks   = local_keep_ticks(ampfreq,   [50 100 150]);
ax_grid = gobjects(K, K);

for ii = 1:K
  for jj = 1:K
    ax = nexttile(tlo);
    ax_grid(ii, jj) = ax;
    tmp = EEGmmitmp{jj,ii};
    if isempty(tmp)
      tmp = empty_tile;
    end
    contourf(ax, xvals, yvals, tmp', 30, 'lines', 'none');
    set(ax, 'XScale', 'log', 'YScale', 'log');
    caxis(ax, [0 cmax]);
    title(ax, '');

    if ~isempty(phase_ticks)
      xticks(ax, phase_ticks);
    end
    if ~isempty(amp_ticks)
      yticks(ax, amp_ticks);
    end

    if ii == K
    else
      set(ax, 'XTick', []);
    end

    if jj == K
      set(ax, 'YAxisLocation', 'right');
    else
      set(ax, 'YTick', []);
    end
  end
end

grid_left = 0.07;
grid_bottom = 0.09;
grid_right = 0.790;
grid_top = 0.885;
fig.Units = 'pixels';
fig_pos = fig.Position;
hgap = 2 / fig_pos(3);
vgap = 2 / fig_pos(4);
tile_w = (grid_right - grid_left - (K-1)*hgap) / K;
tile_h = (grid_top - grid_bottom - (K-1)*vgap) / K;

for ii = 1:K
  for jj = 1:K
    xpos = grid_left + (jj-1) * (tile_w + hgap);
    ypos = grid_bottom + (K-ii) * (tile_h + vgap);
    ax_grid(ii, jj).Position = [xpos ypos tile_w tile_h];
  end
end

for jj = 1:K
  title(ax_grid(1, jj), sprintf('k%d', jj), 'FontWeight', 'bold');
end

for ii = 1:K
  ylabel(ax_grid(ii, 1), sprintf('k%d', ii), 'FontWeight', 'bold');
end

annotation(fig, 'textbox', [0.31 0.014 0.38 0.018], ...
  'String', 'phase frequency (Hz)', ...
  'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
  'EdgeColor', 'none', 'Interpreter', 'none', 'FontWeight', 'bold');
annotation(fig, 'textbox', [0.875 0.32 0.055 0.32], ...
  'String', 'amplitude frequency (Hz)', ...
  'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
  'EdgeColor', 'none', 'Interpreter', 'none', 'FontWeight', 'bold', ...
  'Rotation', 90);

cb = colorbar(ax_grid(K, K), 'eastoutside');
cb.Units = 'normalized';
cb.Position = [0.920, grid_bottom + 0.010, 0.012, 0.055];

png_mmi = [workingdir 'S_mmi.png'];
print('-dpng', png_mmi);
mdisp('yellow', [png_mmi ' is printed for checking synthetic mmi matrix.']);

end

function ticks = local_keep_ticks(freqrange, candidates)
ticks = candidates(candidates >= freqrange(1) & candidates <= freqrange(2));
end

function [S, EEG] = select_source_matrix_local(EEG, emsicafolder, source_mode)
switch source_mode
  case "eeg.synthsourceclean"
    if isfield(EEG, 'synthSourceClean') && ~isempty(EEG.synthSourceClean)
      S = double(reshape(EEG.synthSourceClean, size(EEG.synthSourceClean,1), []));
      mdisp('yellow', ['Here we should not read saved EEG.icaact, because it is the observed/noisy temporal truth, approximately S + pinv(A)*noise, not the clean synthS. Instead, we read EEG.synthSourceClean, which stores the clean latent source matrix S.']);
      return
    end
    mdisp('yellow', ['plot_S_spect_and_mmi(): EEG.synthSourceClean is missing, fallback to EEG.icaact.']);
    source_mode = "eeg.icaact";
  case "eeg.icaact"
  otherwise
    error('plot_S_spect_and_mmi(): source_mode must be ''EEG.icaact'' or ''EEG.synthSourceClean''.');
end

EEG = eeg_checkset(EEG);
S = double(reshape(EEG.icaact, size(EEG.icaact,1), []));
end

function tf = is_named_pac_pair_local(jj, ii)
tf = (jj == 1 && ii == 3) || (jj == 2 && ii == 4);
end
