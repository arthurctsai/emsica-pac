% get_info() Portable subject configuration for the EMSICA-PAC demonstration.
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function s = get_info(subject)
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

if isstruct(subject)
  s = subject;
  return
end

subject = char(string(subject));
study_root = getenv('EMSICA_PAC_STUDY_ROOT');
if isempty(study_root)
  error('get_info:NotConfigured', 'Run setup_emsica_pac.m first.');
end

subject_dir = fullfile(study_root, subject);
s = struct();
s.subject = subject;
s.dataset = [subject '.set'];
s.study = 'emsica-pac-demodata';
s.studydir = [study_root filesep];
s.subjectDir = [subject_dir filesep];
s.subjectdir = s.subjectDir;
s.datasetDir = s.subjectDir;
s.channelsDir = [fullfile(subject_dir, '1channels') filesep];
s.channelsCHsDir = [fullfile(subject_dir, '1channels', 'CHs') filesep];
s.epochsDir = [fullfile(subject_dir, '2epochs', 'EPs') filesep];
s.cleanDir = [fullfile(subject_dir, '4clean', 'ICs') filesep];
s.sphinvDir = [fullfile(subject_dir, '3ica', 'sphinv') filesep];
s.icaDir = [fullfile(subject_dir, '3ica', 'ICs') filesep];
s.icaDir_a = [fullfile(subject_dir, '3ica', 'ICs-a') filesep];
s.mriDir = [fullfile(subject_dir, 'mri') filesep];
s.mridir = s.mriDir;
s.T1dir = [fullfile(subject_dir, 'mri', 'T1') filesep];
s.labelDir = [fullfile(subject_dir, 'label') filesep];
s.surfDir = [fullfile(subject_dir, 'surf') filesep];
s.lfmDir = [fullfile(subject_dir, '5lfm') filesep];
s.dipmat = fullfile(s.lfmDir, 'dipoles_cortical.mat');
s.warpeddipmat = fullfile(s.lfmDir, 'lfm_warpeddip.mat');
s.emsicaDir = [fullfile(subject_dir, '6emsica', 'ICs') filesep];
s.atlasDir = [fullfile(subject_dir, 'label', 'atlas_jubrain') filesep];
s.annot = 'jubrain';
s.datatype = 'eeg';
s.ongoingeeg = true;
s.subcortical = 'on';
s.reducemesh = 1;
s.simulation = {'zm09'};
s.hasmri = {'zm09'};
s.hasnomri = {};

s.ica = struct('icatype', 'infomax', 'maxsteps', 512, ...
  'activationThreshold', 1.8);
s.mmi = struct('phasefreq', [2 15], 'ampfreq', [25 150], ...
  'nPhaseFreqs', 48, 'nAmpFreqs', 24);
s.emsica = struct('sort', 'on', 'icatype', 'gradient', ...
  'activationThreshold', 1.8, 'zThreshold', 2.2, ...
  'lrate', 1e-3, 'stop', 1e-9, 'maxsteps', 100, ...
  'annealstep', 0.9, 'annealdeg', 70, ...
  'myalpha', 0.0125, 'mybeta', 27.7, 'run_likelihood', 0, ...
  'randmode', 1);

s.subcorticalmeshes = { ...
  10, 'lh.Thalamus-Proper', [0 118 14 0]; ...
  11, 'lh.Caudate', [122 186 220 0]; ...
  12, 'lh.Putamen', [236 13 176 0]; ...
  13, 'lh.Pallidum', [12 48 255 0]; ...
  17, 'lh.Hippocampus', [220 216 20 0]; ...
  18, 'lh.Amygdala', [103 255 255 0]; ...
  49, 'rh.Thalamus-Proper', [0 118 14 0]; ...
  50, 'rh.Caudate', [122 186 220 0]; ...
  51, 'rh.Putamen', [236 13 176 0]; ...
  52, 'rh.Pallidum', [13 48 255 0]; ...
  53, 'rh.Hippocampus', [220 216 20 0]; ...
  54, 'rh.Amygdala', [103 255 255 0]};
end
