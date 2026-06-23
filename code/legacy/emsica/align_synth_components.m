function [EEG, scores] = align_synth_components(s, EEG, truth_folder)
% align_synth_components() Align the four demo components using spatial B.
%
% Copyright (c) Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

truth = load(fullfile(s.subjectdir, truth_folder, 'B.mat'), 'B');
result_file = fullfile(s.workingdir, 'B.mat');
result = load(result_file, 'B', 'w', 'a');
K = size(truth.B, 2);
assert(K == 4 && size(result.B,2) == K, ...
  'align_synth_components:ExpectedFourSources', ...
  'The packaged alignment helper expects four truth and result sources.');

C = zeros(K);
for truth_idx = 1:K
  for result_idx = 1:K
    pair = corrcoef(double(truth.B(:,truth_idx)), ...
      double(result.B(:,result_idx)));
    C(truth_idx,result_idx) = abs(pair(1,2));
  end
end

candidates = perms(1:K);
totals = zeros(size(candidates,1),1);
for row = 1:size(candidates,1)
  totals(row) = sum(C(sub2ind([K K], 1:K, candidates(row,:))));
end
[~, best] = max(totals);
order = candidates(best,:);
scores = C(sub2ind([K K], 1:K, order));

result.B = result.B(:,order);
result.w = result.w(order,:);
if isfield(result, 'a') && ~isempty(result.a)
  result.a = result.a(:,order);
  save(result_file, '-struct', 'result', 'B', 'w', 'a');
else
  save(result_file, '-struct', 'result', 'B', 'w');
end

EEG.B = result.B;
EEG.icaweights = EEG.icaweights(order,:);
EEG.icawinv = EEG.icawinv(:,order);
if isfield(EEG,'A0') && size(EEG.A0,2) >= K
  EEG.A0 = EEG.A0(:,order);
end
if isfield(EEG,'A0_from_infomax') && size(EEG.A0_from_infomax,2) >= K
  EEG.A0_from_infomax = EEG.A0_from_infomax(:,order);
end
EEG.icaact = [];
pop_saveset(EEG, 'filename', s.dataset, 'filepath', s.workingdir);
fprintf('Aligned four components by B.mat: order=%s, corr=%s\n', ...
  mat2str(order), mat2str(scores,4));
end
