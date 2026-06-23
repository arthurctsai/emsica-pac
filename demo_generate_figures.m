function files = demo_generate_figures(result_tag)
% demo_generate_figures() Generate source-recovery and broadband-PAC figures.
%
% demo_generate_figures() uses the most recent standard demo result.
%
% Author: Arthur C. Tsai
% Copyright (c) Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

if nargin < 1 || isempty(result_tag), result_tag = 'demo'; end
result_tag = char(string(result_tag));
cfg = setup_emsica_pac();

source_output = fullfile(cfg.output_dir, 'source_recovery_zm09.png');
truth_dir = fullfile(cfg.subject_dir, '2epochs', 'EPs-synth');
infomax_dir = fullfile(cfg.subject_dir, '3ica', 'ICs-synth-infomax');
geometry_file = fullfile(cfg.subject_dir, '5lfm', ...
  'source_plot_geometry.mat');
result_name = sprintf('ICs-synth-infomax-extended-%s-full', result_tag);
result_dir = fullfile(cfg.result_root, result_name);
truth_mmi = fullfile(truth_dir, 'mmitmp.mat');
infomax_mmi = fullfile(infomax_dir, 'mmitmp.mat');
result_mmi = fullfile(result_dir, 'mmitmp.mat');

fprintf('\nInput:\n');
fprintf('  Ground truth:\n');
print_dataset_materials_local(truth_dir);
fprintf('  Infomax:\n');
print_dataset_materials_local(infomax_dir);
fprintf('  Extended EMSICA:\n');
print_dataset_materials_local(result_dir);
fprintf('  Source geometry:\n');
fprintf('    - %s\n', geometry_file);

plot_source_recovery_local(truth_dir, infomax_dir, result_dir, ...
  geometry_file, source_output);
pac = struct();
pac.groundtruth = load_pac_tensor_local(truth_mmi);
pac.infomax = load_pac_tensor_local(infomax_mmi);
if isfile(result_mmi)
  pac.emsica = load_pac_tensor_local(result_mmi);
else
  setfile = fullfile(result_dir, 'zm09.set');
  if ~isfile(setfile)
    error('demo_generate_figures:MissingResult', ...
      'Missing %s. Run demo_run_emsica() first.', setfile);
  end
  EEG = pop_loadset(setfile);
  EEG = eeg_checkset(EEG, 'ica');
  sources = double(reshape(EEG.icaact, size(EEG.icaact,1), []));
  EEGmmi = fixed_four_source_pac_local(sources, EEG.srate); %#ok<NASGU>
  save(result_mmi, 'EEGmmi');
  pac.emsica = EEGmmi;
end

pac_output = fullfile(cfg.output_dir, 'pac_recovery_zm09.png');
plot_pac_maps_local(pac, pac_output);
files = {source_output, pac_output};
for k = 1:numel(files)
  assert(isfile(files{k}), 'demo_generate_figures:MissingOutput', ...
    'Expected figure was not created: %s', files{k});
end
fprintf('\nOutput:\n');
for k = 1:numel(files)
  fprintf('  - %s\n', files{k});
end
end

function print_dataset_materials_local(folder)
materials = {'zm09.set', 'zm09.fdt', 'B.mat'};
for k = 1:numel(materials)
  filename = fullfile(folder, materials{k});
  if isfile(filename)
    fprintf('    - %s\n', filename);
  end
end
end

function tensor = load_pac_tensor_local(filename)
if ~isfile(filename)
  error('demo_generate_figures:MissingPAC', 'Missing PAC cache: %s', filename);
end
tmp = load(filename, 'EEGmmi');
tensor = tmp.EEGmmi;
end

function plot_source_recovery_local(truth_dir, infomax_dir, result_dir, ...
    geometry_file, pngfile)
geometry = load(geometry_file, 'cortex', 'deep');
truth_B = load_B_local(fullfile(truth_dir, 'B.mat'));
infomax_B = load_B_local(fullfile(infomax_dir, 'B.mat'));
emsica_B = load_B_local(fullfile(result_dir, 'B.mat'));
assert(size(truth_B,1) == size(geometry.cortex.vertices,1) + ...
  size(geometry.deep.vertices,1), ...
  'Source geometry does not match the rows of B.mat.');

truth_U = load_sources_local(fullfile(truth_dir, 'zm09.set'), true);
infomax_U = load_sources_local(fullfile(infomax_dir, 'zm09.set'), false);
emsica_U = load_sources_local(fullfile(result_dir, 'zm09.set'), false);
K = min(4, size(truth_B,2));
[infomax_B, infomax_U, infomax_rmap, infomax_rtime] = ...
  align_source_result_local(truth_B(:,1:K), truth_U(1:K,:), ...
  infomax_B, infomax_U);
[emsica_B, emsica_U, emsica_rmap, emsica_rtime] = ...
  align_source_result_local(truth_B(:,1:K), truth_U(1:K,:), ...
  emsica_B, emsica_U);

maps = {truth_B(:,1:K), infomax_B, emsica_B};
traces = {truth_U(1:K,:), infomax_U, emsica_U};
map_corr = {nan(1,K), infomax_rmap, emsica_rmap};
time_corr = {nan(1,K), infomax_rtime, emsica_rtime};
titles = {'Ground truth', 'Infomax ICA + sLORETA', 'Extended EMSICA'};
colors = {[0.42 0.42 0.42], [217 182 0]/255, [19 0 130]/255};

fig = figure('Visible', 'off', 'Color', 'w', ...
  'Position', [30 30 1900 610], 'InvertHardCopy', 'off');
cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
lefts = [0.038 0.371 0.704];
column_width = 0.292;
row_height = 0.190;
row_gap = 0.025;
top = 0.900;
for method = 1:3
  annotation(fig, 'textbox', [lefts(method) 0.952 column_width 0.035], ...
    'String', titles{method}, 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', 'EdgeColor', 'none', ...
    'FontWeight', 'bold', 'FontSize', 13, 'Color', colors{method});
  if method > 1
    xline = lefts(method) - 0.012;
    annotation(fig, 'line', [xline xline], [0.055 0.945], ...
      'Color', [0.75 0.75 0.75]);
  end
  for k = 1:K
    y0 = top - k*row_height - (k-1)*row_gap;
    map_pos = [lefts(method), y0 + 0.059, column_width, 0.113];
    trace_pos = [lefts(method), y0 + 0.004, column_width, 0.053];
    plot_brain_strip_local(fig, map_pos, geometry, maps{method}(:,k));
    if method > 1
      annotation(fig, 'textbox', ...
        [map_pos(1)+map_pos(3)-0.070, map_pos(2)+map_pos(4)-0.003, ...
         0.068, 0.015], ...
        'String', sprintf('r_{map} = %.2f', map_corr{method}(k)), ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
        'EdgeColor', 'none', 'FontSize', 7, 'Interpreter', 'tex');
    end
    ax = axes('Parent', fig, 'Position', trace_pos, 'Color', 'w');
    npoint = min(100, size(traces{method},2));
    truth_trace = standardize_trace_local(traces{1}(k,1:npoint));
    plot(ax, 1:npoint, truth_trace, 'Color', [0.48 0.48 0.48], ...
      'LineWidth', 1.0);
    hold(ax, 'on');
    if method > 1
      estimate_trace = standardize_trace_local(traces{method}(k,1:npoint));
      plot(ax, 1:npoint, estimate_trace, 'Color', colors{method}, ...
        'LineWidth', 1.15);
      text(ax, 0.99, 0.86, sprintf('r_{time} = %.2f', time_corr{method}(k)), ...
        'Units', 'normalized', 'HorizontalAlignment', 'right', ...
        'FontSize', 7, 'BackgroundColor', 'w', 'Margin', 0.1);
    end
    xlim(ax, [1 npoint]); ylim(ax, [-2.8 2.8]);
    set(ax, 'YTick', [-2 0 2], 'FontSize', 7, 'Box', 'off', ...
      'TickDir', 'out');
    if k < K
      set(ax, 'XTickLabel', {});
    else
      xlabel(ax, 'Time (ms)', 'FontSize', 8);
    end
    if method == 1
      ylabel(ax, sprintf('k%d', k), 'Rotation', 0, ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
        'FontWeight', 'bold', 'FontSize', 10);
    end
  end
end
print(fig, '-dpng', '-r150', pngfile);
end

function B = load_B_local(filename)
tmp = load(filename, 'B');
if ~isfield(tmp, 'B') || ~isnumeric(tmp.B)
  error('demo_generate_figures:MissingB', 'Missing numeric B in %s.', filename);
end
B = double(tmp.B);
end

function U = load_sources_local(setfile, prefer_clean_truth)
EEG = pop_loadset(setfile);
if prefer_clean_truth && isfield(EEG, 'synthSourceClean') && ...
    ~isempty(EEG.synthSourceClean)
  U = double(reshape(EEG.synthSourceClean, ...
    size(EEG.synthSourceClean,1), []));
else
  EEG = eeg_checkset(EEG, 'ica');
  U = double(reshape(EEG.icaact, size(EEG.icaact,1), []));
end
end

function [B, U, rmap, rtime] = align_source_result_local( ...
    truth_B, truth_U, estimate_B, estimate_U)
K = size(truth_B,2);
map_similarity = abs(corr(abs(truth_B), abs(estimate_B), ...
  'Rows', 'pairwise'));
map_order = best_assignment_local(map_similarity);
B = estimate_B(:,map_order);
T = min(size(truth_U,2), size(estimate_U,2));
time_similarity = abs(corr(truth_U(:,1:T)', estimate_U(:,1:T)', ...
  'Rows', 'pairwise'));
time_order = best_assignment_local(time_similarity);
U = estimate_U(time_order,:);
rmap = zeros(1,K);
rtime = zeros(1,K);
for k = 1:K
  rmap(k) = abs(corr(abs(truth_B(:,k)), abs(B(:,k)), ...
    'Rows', 'pairwise'));
  temporal_r = corr(truth_U(k,1:T)', U(k,1:T)', 'Rows', 'pairwise');
  if temporal_r < 0, U(k,:) = -U(k,:); temporal_r = -temporal_r; end
  rtime(k) = temporal_r;
end
end

function order = best_assignment_local(similarity)
K = size(similarity,1);
candidates = perms(1:size(similarity,2));
candidates = candidates(:,1:K);
scores = zeros(size(candidates,1),1);
for row = 1:size(candidates,1)
  scores(row) = sum(similarity(sub2ind(size(similarity), ...
    1:K, candidates(row,:))));
end
[~, best] = max(scores);
order = candidates(best,:);
end

function trace = standardize_trace_local(trace)
trace = double(trace(:)');
trace = trace - mean(trace, 'omitnan');
scale = std(trace, 0, 'omitnan');
if isfinite(scale) && scale > 0, trace = trace/scale; end
end

function plot_brain_strip_local(fig, position, geometry, values)
n_cortex = size(geometry.cortex.vertices,1);
cortex_values = values(1:n_cortex);
deep_values = values(n_cortex+1:end);
panel = uipanel('Parent', fig, 'Units', 'normalized', ...
  'Position', position, 'BackgroundColor', 'k', 'BorderType', 'none');
fractions = [0.215 0.215 0.215 0.215 0.140];
gap = 0;
x = 0;
for view_index = 1:5
  width = fractions(view_index);
  ax = axes('Parent', panel, 'Position', [x 0 width 1], 'Color', 'k');
  if view_index == 5
    plot_mesh_values_local(ax, geometry.deep.vertices, ...
      geometry.deep.faces, deep_values, zeros(size(deep_values)), [90 0], 0.62);
  else
    if any(view_index == [2 3])
      segment = 1;
    else
      segment = 2;
    end
    first_vertex = double(geometry.cortex.verticesIdx(segment,1));
    last_vertex = double(geometry.cortex.verticesIdx(segment,2));
    vertex_index = first_vertex:last_vertex;
    face_count = size(geometry.cortex.faces,1)/2;
    if segment == 1
      faces = double(geometry.cortex.faces(1:face_count,:));
    else
      faces = double(geometry.cortex.faces(face_count+1:end,:)) - ...
        first_vertex + 1;
    end
    if view_index == 1 || view_index == 3
      camera_view = [90 0];
    else
      camera_view = [-90 0];
    end
    plot_mesh_values_local(ax, geometry.cortex.vertices(vertex_index,:), ...
      faces, cortex_values(vertex_index), ...
      geometry.cortex.curv(vertex_index), camera_view, 0.86);
  end
  x = x + width + gap;
end
end

function plot_mesh_values_local(ax, vertices, faces, values, curv, ...
    camera_view, object_scale)
values = double(values(:));
curv = double(curv(:));
z = abs(values - mean(values, 'omitnan')) / max(std(values,0,'omitnan'), eps);
activation = min(max((z-2.5)/3.5, 0), 1);
base = 0.39 + 0.09*tanh(2*curv);
rgb = repmat(base, 1, 3);
hot = [ones(size(activation)), 0.78*(1-activation), zeros(size(activation))];
rgb = rgb.*(1-activation) + hot.*activation;
patch(ax, 'Vertices', double(vertices), 'Faces', double(faces), ...
  'FaceVertexCData', rgb, 'FaceColor', 'interp', 'EdgeColor', 'none', ...
  'FaceLighting', 'gouraud', 'AmbientStrength', 0.68, ...
  'DiffuseStrength', 0.38, 'SpecularStrength', 0.04);
axis(ax, 'equal'); axis(ax, 'tight');
set(ax, 'Color', 'k', 'XTick', [], 'YTick', [], 'ZTick', [], ...
  'Box', 'off', 'XColor', 'k', 'YColor', 'k', 'ZColor', 'k');
view(ax, camera_view); camlight(ax, 'headlight');
if object_scale < 1
  x_limits = xlim(ax); y_limits = ylim(ax);
  x_center = mean(x_limits); y_center = mean(y_limits);
  x_half = diff(x_limits)/(2*object_scale);
  y_half = diff(y_limits)/(2*object_scale);
  xlim(ax, x_center + [-x_half x_half]);
  ylim(ax, y_center + [-y_half y_half]);
end
end

function plot_pac_maps_local(pac, pngfile)
tensors = {pac.groundtruth, pac.infomax, pac.emsica};
titles = {'Ground truth', 'Infomax ICA + sLORETA', 'Extended EMSICA'};
colors = {[0.3 0.3 0.3], [217 182 0]/255, [19 0 130]/255};
all_values = [];
for g = 1:3
  for n = 1:numel(tensors{g})
    value = tensors{g}{n};
    all_values = [all_values; value(isfinite(value))]; %#ok<AGROW>
  end
end
all_values = sort(all_values);
cmax = all_values(max(1, round(0.995*numel(all_values))));
if ~isfinite(cmax) || cmax <= 0, cmax = max(all_values); end
phasefreq = logspace(log10(2), log10(15), 48);
ampfreq = logspace(log10(25), log10(150), 24);

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [50 50 1680 620]);
cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
left0 = [0.035 0.355 0.675]; groupw = 0.285;
top = 0.84; bottom = 0.10; gap = 0.004;
tilew = (groupw - 3*gap)/4; tileh = (top-bottom-3*gap)/4;
for g = 1:3
  annotation(fig, 'textbox', [left0(g) 0.91 groupw 0.05], ...
    'String', titles{g}, 'HorizontalAlignment', 'center', ...
    'EdgeColor', 'none', 'FontWeight', 'bold', 'FontSize', 13, ...
    'Color', colors{g}, 'Interpreter', 'none');
  annotation(fig, 'textbox', [left0(g) 0.865 groupw 0.035], ...
    'String', 'Phase source', 'HorizontalAlignment', 'center', ...
    'EdgeColor', 'none', 'FontWeight', 'bold', 'FontSize', 9);
  for row = 1:4
    for col = 1:4
      xpos = left0(g) + (col-1)*(tilew+gap);
      ypos = top - row*tileh - (row-1)*gap;
      ax = axes('Parent', fig, 'Position', [xpos ypos tilew tileh]);
      map = tensors{g}{col,row};
      if isequal(size(map), [48 24]), map = map'; end
      imagesc(ax, phasefreq, ampfreq, map);
      axis(ax, 'xy'); caxis(ax, [0 cmax]);
      set(ax, 'XScale', 'log', 'YScale', 'log', 'FontSize', 6, ...
        'TickLength', [0.02 0.02], 'Box', 'on');
      if row == 4
        set(ax, 'XTick', [2 5 10], 'XTickLabel', {'2','5','10'});
      else
        set(ax, 'XTickLabel', {});
      end
      if col == 1
        set(ax, 'YTick', [25 50 100 150], ...
          'YTickLabel', {'25','50','100','150'});
      else
        set(ax, 'YTickLabel', {});
      end
      if row == 1, title(ax, sprintf('k%d', col), 'FontSize', 8); end
      if col == 1
        ylabel(ax, sprintf('k%d', row), 'FontWeight', 'bold', ...
          'Rotation', 0, 'HorizontalAlignment', 'right', ...
          'VerticalAlignment', 'middle');
      end
      if (row == 3 && col == 1) || (row == 4 && col == 2)
        set(ax, 'LineWidth', 1.5, 'XColor', [0.9 0.15 0.1], ...
          'YColor', [0.9 0.15 0.1]);
      end
    end
  end
end
colormap(fig, parula(256));
annotation(fig, 'textbox', [0.004 0.34 0.02 0.30], ...
  'String', 'Amplitude source', 'Rotation', 90, ...
  'HorizontalAlignment', 'center', 'EdgeColor', 'none', ...
  'FontWeight', 'bold', 'FontSize', 9);
cbax = axes('Parent', fig, 'Position', [0.975 bottom 0.008 top-bottom], ...
  'Visible', 'off');
caxis(cbax, [0 cmax]);
cb = colorbar(cbax, 'Position', [0.978 bottom 0.008 top-bottom]);
cb.Label.String = 'Modulation index'; cb.FontSize = 7;
print(fig, '-dpng', '-r180', pngfile);
end

function EEGmmi = fixed_four_source_pac_local(sources, srate)
% Fixed manuscript PAC calculation for exactly four source time courses.
assert(size(sources,1) == 4, 'PAC input must contain four sources.');
sources = double(sources(:, floor(size(sources,2)/2)+1:end));
T = size(sources,2);
phasefreq = logspace(log10(2), log10(15), 48);
ampfreq = logspace(log10(25), log10(150), 24);
phases = zeros(4, 48, T, 'single');
amps = zeros(4, 24, T, 'single');
for k = 1:4
  for f = 1:48
    band = phasefreq(f)*[1/sqrt(2) sqrt(2)];
    taps = fir1(600, 2*band/srate);
    phases(k,f,:) = single(angle(hilbert(conv(sources(k,:), taps, 'same'))));
  end
  for f = 1:24
    band = ampfreq(f)*[1/sqrt(2) sqrt(2)];
    taps = fir1(200, 2*band/srate);
    amps(k,f,:) = single(abs(hilbert(conv(sources(k,:), taps, 'same'))));
  end
end
EEGmmi = cell(4,4);
edges = linspace(-pi, pi, 19);
for phase_source = 1:4
  for amp_source = 1:4
    map = zeros(48,24);
    for i = 1:48
      [~,~,bins] = histcounts(squeeze(phases(phase_source,i,:)), edges);
      for j = 1:24
        amplitude = double(squeeze(amps(amp_source,j,:)));
        means = accumarray(max(bins,1), amplitude, [18 1], @mean, 0);
        distribution = means/sum(means);
        entropy = -sum(distribution.*log(distribution + eps));
        map(i,j) = (log(18)-entropy)/log(18);
      end
    end
    EEGmmi{phase_source,amp_source} = map;
  end
end
end
