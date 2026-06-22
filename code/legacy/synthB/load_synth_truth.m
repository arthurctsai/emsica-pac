% load_synth_truth() Load temporal/spatial truth objects for synthB runs.
%
% The clean synthetic source matrix saved by get_synthX() remains available
% for optional analyses via temporal_target="EEG.synthSourceClean".
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function truth = load_synth_truth(s, g)
arguments
  s
  g.truth_folder char = '2epochs/EPs-synth/'
  g.K = []
  g.temporal_target string = "EEG.icaact" % "EEG.icaact" | "EEG.synthSourceClean"
end

s = get_info(s);
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

temporal_target = lower(strtrim(char(string(g.temporal_target))));
if strcmp(temporal_target, 'eegicaact')
  temporal_target = 'eeg.icaact';
elseif strcmp(temporal_target, 'eegsynthsourceclean')
  temporal_target = 'eeg.synthsourceclean';
end
if ~ismember(temporal_target, {'eeg.icaact', 'eeg.synthsourceclean'})
  error('load_synth_truth:BadTemporalTarget', ...
    'temporal_target must be ''EEG.icaact'' or ''EEG.synthSourceClean''.');
end

truth_folder = strrep(strtrim(char(g.truth_folder)), '\', '/');

truth = struct( ...
  'setfile', fullfile(s.subjectdir, g.truth_folder, [s.subject '.set']), ...
  'bfile', fullfile(s.subjectdir, g.truth_folder, 'B.mat'), ...
  'Upreferred', [], ...
  'Uclean', [], ...
  'Uobserved', [], ...
  'B', [], ...
  'hasCleanTemporalSources', false, ...
  'temporalSourceMode', 'missing');

if exist(truth.setfile, 'file')
  EEGt = pop_loadset(truth.setfile);
  if isfield(EEGt, 'icaact') && ~isempty(EEGt.icaact)
    truth.Uobserved = double(reshape(EEGt.icaact, size(EEGt.icaact,1), []));
  end
  if isfield(EEGt, 'synthSourceClean') && ~isempty(EEGt.synthSourceClean)
    truth.Uclean = double(reshape(EEGt.synthSourceClean, size(EEGt.synthSourceClean,1), []));
    truth.hasCleanTemporalSources = true;
  end

  switch temporal_target
    case 'eeg.synthsourceclean'
      if ~isempty(truth.Uclean)
        truth.Upreferred = truth.Uclean;
        truth.temporalSourceMode = 'clean_synthSourceClean';
        if strcmp(truth_folder, '2epochs/EPs-synth/')
          mdisp('yellow', ['Here we should not read saved EEG.icaact, because it is the observed/noisy temporal truth, approximately S + pinv(A)*noise, not the clean synthS. Instead, we read EEG.synthSourceClean, which stores the clean latent source matrix S.']);
        end
      elseif ~isempty(truth.Uobserved)
        truth.Upreferred = truth.Uobserved;
        truth.temporalSourceMode = 'fallback_observed_icaact_noisy';
      end
    otherwise % EEG.icaact
      if ~isempty(truth.Uobserved)
        truth.Upreferred = truth.Uobserved;
        truth.temporalSourceMode = 'observed_icaact_noisy';
      elseif ~isempty(truth.Uclean)
        truth.Upreferred = truth.Uclean;
        truth.temporalSourceMode = 'fallback_clean_synthSourceClean';
      end
  end
end

if exist(truth.bfile, 'file')
  tmp = load(truth.bfile, 'B');
  if isfield(tmp, 'B') && ~isempty(tmp.B)
    truth.B = double(tmp.B);
  end
end

if ~isempty(g.K) && g.K > 0
  K = double(g.K);
  if ~isempty(truth.Upreferred)
    truth.Upreferred = truth.Upreferred(1:min(K, size(truth.Upreferred,1)), :);
  end
  if ~isempty(truth.Uclean)
    truth.Uclean = truth.Uclean(1:min(K, size(truth.Uclean,1)), :);
  end
  if ~isempty(truth.Uobserved)
    truth.Uobserved = truth.Uobserved(1:min(K, size(truth.Uobserved,1)), :);
  end
  if ~isempty(truth.B)
    truth.B = truth.B(:, 1:min(K, size(truth.B,2)));
  end
end
end
