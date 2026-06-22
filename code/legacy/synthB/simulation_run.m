% simulation_run() run the synthB simulation pipeline for selected subjects.
%
% Usage:
%   simulation_run()
%   simulation_run(stype=2)
%   simulation_run(subjects={'zm02' 'zm06'})
%
% Inputs:
%   recompute_synthX - recompute the synthetic truth data when needed
%   recompute_B0     - recompute the EMSICA B0 initializer; when 0, reuse
%                      the cached B0 result if it exists. This is forced
%                      on when recompute_synthX=1.
%   stype            - synthetic signal setting
%   subjects         - cell array of subject ids; use {} for all subjects
%   EMSICA synth outputs are named by initializer and B-update mode, e.g.
%   6emsica/ICs-synth-infomax-extended/.
%   myalpha          - EMSICA sparse-prior strength; [] keeps runemsica default
%   mybeta           - EMSICA smooth-prior strength; [] keeps runemsica default
%   b_update_lrate_scale - extra multiplicative scale on lrate used only
%                      inside the chosen B-space update geometry
%   spatiotemporal_mix_ramp_steps - optional step count for r(step) ramp
%   spatiotemporal_mix_exp_k - exponential sharpness for r(step); larger means later/faster rise
%   spatiotemporal_mix_r_begin - starting value of r(step); default 0
%   spatiotemporal_mix_r_end - ending value of r(step); default 1
%   runemsica_log_suffix - optional suffix for per-run runemsica diary file
%   B0method         - EMSICA initializer source; default 'infomax'
%                      Options: 'fastica' | 'infomax' | 'random' |
%                      'sLORETA' | 'minimum-norm' | 'psudo-inv' |
%                      'lcmv' | 'synthBS'
%   maxsteps         - EMSICA maximum gradient steps; use 0 to keep the initializer only
%   sl_upweightsubcortical - pass-through to sl_()/get_lfm(); 'on' keeps the
%                      historical deep-source upweighting, 'off' estimates
%                      with unweighted cortical/subcortical leadfields
%
% This public demo always runs the full Extended EMSICA method from the
% requested cached initializer.
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function simulation_run(g)
arguments
  g.recompute_synthX (1,1) {mustBeNumeric} = 1
  g.recompute_B0 (1,1) {mustBeNumeric} = 1
  g.stype (1,1) {mustBeNumeric} = 2
  g.subjects cell = {} % {'zm02'} % {}
  g.myalpha = 0.0125 % 4.5e-6 / 0.000360674 % legacy default rescaled after folding sparse_anneal into lrate
  % larger myalpha pushes harder toward spatial structure/sparsity, which can improve spatialCorrAcc(B)
  % smaller myalpha leaves the temporal fit freer, which can preserve or improve temporalCorrAcc(U)
  g.mybeta = 27.7 % 1 / 0.000360674
  g.b_update_lrate_scale = 1
  g.spatiotemporal_mix_ramp_steps = 100 % []
  g.spatiotemporal_mix_exp_k = 1 % 5 % [] k=1: mild curvature, almost linear• k=3: moderate delay• k=5: strong delay
  g.spatiotemporal_mix_r_begin = 0
  g.spatiotemporal_mix_r_end = 1
  g.runemsica_log_suffix char = ''
  g.B0method char = 'infomax' % 'infomax' | 'fastica' | 'random' | 'sLORETA' | 'minimum-norm' | 'psudo-inv' | 'lcmv' | 'synthBS'
  g.maxsteps = 100
  g.enable_diagnostics (1,1) {mustBeNumeric} = 0
  g.diagnostics_stride (1,1) {mustBeNumeric} = 1
  g.synth_snr_db = []
  g.synth_truth_folder char = '2epochs/EPs-synth/'
  g.ica_output_tag char = ''
  g.emsica_output_tag char = ''
  g.overwrite_guard (1,1) {mustBeNumeric} = 1
  g.require_cached_B0 (1,1) {mustBeNumeric} = 0
  g.b0_perturb_mode char = 'none'
  g.b0_perturb_strength (1,1) {mustBeNumeric} = 0
  g.b0_perturb_seed (1,1) {mustBeNumeric} = 1
  g.skip_accuracy_plot (1,1) {mustBeNumeric} = 0
  g.areas cell = {}
  g.areapercentagesettings cell = {}
  g.sl_upweightsubcortical char = 'on'
end
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

K = 4;

areas = {
    {'lMOF','rMOF','lHippocampus'};
    {'lPCUN','rPCUN'};
    {'lFP','lRMF'};
    {'lLOCC','rLOCC'};
};

areapercentagesettings = {
  0.5
  0.5
  0.5
  [1.0 1.0 0.9 0.9]
  };


recompute_synthX = g.recompute_synthX;
recompute_B0 = g.recompute_B0;
stype = g.stype;
subjects = g.subjects;
myalpha = g.myalpha;
mybeta = g.mybeta;
b_update_lrate_scale = g.b_update_lrate_scale;
spatiotemporal_mix_ramp_steps = g.spatiotemporal_mix_ramp_steps;
spatiotemporal_mix_exp_k = g.spatiotemporal_mix_exp_k;
spatiotemporal_mix_r_begin = g.spatiotemporal_mix_r_begin;
spatiotemporal_mix_r_end = g.spatiotemporal_mix_r_end;
runemsica_log_suffix = g.runemsica_log_suffix;
B0method = g.B0method;
maxsteps = g.maxsteps;
enable_diagnostics = logical(g.enable_diagnostics);
diagnostics_stride = max(1, round(g.diagnostics_stride));
synth_snr_db = g.synth_snr_db;
synth_truth_folder = normalize_folder_local(g.synth_truth_folder);
ica_output_tag = strtrim(char(g.ica_output_tag));
emsica_output_tag = strtrim(char(g.emsica_output_tag));
overwrite_guard = logical(g.overwrite_guard);
require_cached_B0 = logical(g.require_cached_B0);
b0_perturb_mode = g.b0_perturb_mode;
b0_perturb_strength = g.b0_perturb_strength;
b0_perturb_seed = g.b0_perturb_seed;
skip_accuracy_plot = logical(g.skip_accuracy_plot);
areas_override = g.areas;
areapercentagesettings_override = g.areapercentagesettings;
sl_upweightsubcortical = g.sl_upweightsubcortical;
baseB0method = resolve_base_B0method(B0method);
emsica_plots = 'off';

run_fastica = false;
run_infomax = false;
emsica_variants = struct('token', 'extended_emsica', ...
  'folder_suffix', '', 'log_suffix', runemsica_log_suffix);

% Keep the synthetic truth and downstream decompositions synchronized.
if logical(recompute_synthX)
  if ~run_infomax
    fprintf(['simulation_run(): forcing infomax rerun because recompute_synthX=1 ' ...
      'and the comparison plot includes an infomax baseline.\n']);
    run_infomax = true;
  end
  if strcmpi(baseB0method, 'fastica') && ~run_fastica
    fprintf(['simulation_run(): forcing fastica rerun because recompute_synthX=1 ' ...
      'and B0method=%s depends on 3ica/ICs-synth-fastica/.\n'], baseB0method);
    run_fastica = true;
  end
end

force_recompute_B0 = logical(recompute_synthX);
if force_recompute_B0 && ~logical(recompute_B0)
  fprintf('simulation_run(): forcing recompute_B0=1 because recompute_synthX=1.\n');
end
recompute_B0 = logical(recompute_B0) || force_recompute_B0;

effective_args = struct( ...
  'recompute_synthX', recompute_synthX, ...
  'recompute_B0', recompute_B0, ...
  'stype', stype, ...
  'subjects', {subjects}, ...
  'myalpha', myalpha, ...
  'mybeta', mybeta, ...
  'b_update_lrate_scale', b_update_lrate_scale, ...
  'spatiotemporal_mix_ramp_steps', spatiotemporal_mix_ramp_steps, ...
  'spatiotemporal_mix_exp_k', spatiotemporal_mix_exp_k, ...
  'spatiotemporal_mix_r_begin', spatiotemporal_mix_r_begin, ...
  'spatiotemporal_mix_r_end', spatiotemporal_mix_r_end, ...
  'runemsica_log_suffix', runemsica_log_suffix, ...
  'B0method', B0method, ...
  'maxsteps', maxsteps, ...
  'synth_snr_db', synth_snr_db, ...
  'synth_truth_folder', synth_truth_folder, ...
  'ica_output_tag', ica_output_tag, ...
  'emsica_output_tag', emsica_output_tag, ...
  'require_cached_B0', require_cached_B0, ...
  'b0_perturb_mode', b0_perturb_mode, ...
  'b0_perturb_strength', b0_perturb_strength, ...
  'b0_perturb_seed', b0_perturb_seed, ...
  'skip_accuracy_plot', skip_accuracy_plot, ...
  'sl_upweightsubcortical', sl_upweightsubcortical);


close all;
study_root = getenv('EMSICA_PAC_STUDY_ROOT');
if isempty(study_root) || ~isfolder(study_root)
  error('simulation_run:MissingStudyRoot', ...
    'Run setup_emsica_pac.m before simulation_run().');
end
cd(study_root);

% 123456789000012345678901234567890123456789012345678901234567890123456789012345
if stype == 0
  nPCA = 4;
else
  nPCA = 6;
end

s0 = get_info('zm02');
subjects_filter = subjects;
subjects = s0.simulation;
% subjects = subjects(1:2);
if ~isempty(subjects_filter)
  subjects = subjects_filter;
end

%% ====== (1) Run the whole simulation pipeline and plot summary results =======
if ~isempty(areas_override)
  areas = areas_override;
end
if ~isempty(areapercentagesettings_override)
  areapercentagesettings = areapercentagesettings_override;
end

  for ss = 1:numel(subjects)
    sb = subjects{ss};
    s = get_info(sb);

    if recompute_synthX
      enforce_synth_truth_readonly_guard(s, synth_truth_folder);
      synth_args = {'stype', stype, 'K', K, ...
        'emsicafolder', synth_truth_folder, ...
        'areas', areas, ...
        'areapercentagesettings', areapercentagesettings, ...
        'plots', 'off'};
      if ~isempty(synth_snr_db)
        synth_args = [synth_args, {'snr_db', synth_snr_db}]; %#ok<AGROW>
      end
      get_synthX(s, synth_args{:});
        plot_S_spect_and_mmi(s,[],[],synth_truth_folder, 0);
    end

    if run_fastica
      icatype = 'fastica';
      emsicafolder = tagged_ica_folder(icatype, ica_output_tag);
      enforce_synth_truth_readonly_guard(s, emsicafolder);
      ica_(s, 'icatype',icatype, 'emsicafolder',emsicafolder, 'nPCA',nPCA, 'plots','off', 'skip_get_iclabel',1, 'synth_truth_folder',synth_truth_folder);
      sl_(s, 'emsicafolder',emsicafolder, 'sourceorient','fixed', 'upweightsubcortical',sl_upweightsubcortical, 'plots',emsica_plots);
        plot_S_spect_and_mmi(s,[],[],emsicafolder, 0);
    end

    if run_infomax
      icatype = 'infomax';
      emsicafolder = tagged_ica_folder(icatype, ica_output_tag);
      enforce_synth_truth_readonly_guard(s, emsicafolder);
      ica_(s, 'icatype',icatype, 'emsicafolder',emsicafolder, 'nPCA',nPCA, 'plots','off', 'skip_get_iclabel',1, 'synth_truth_folder',synth_truth_folder);
      sl_(s, 'emsicafolder',emsicafolder, 'sourceorient','fixed', 'upweightsubcortical',sl_upweightsubcortical, 'plots',emsica_plots);
        plot_S_spect_and_mmi(s,[],[],emsicafolder, 0);
    end

    b0folder = tagged_b0_folder(B0method, ica_output_tag);
    subject_myalpha = resolve_subject_myalpha(sb, myalpha);

    fprintf('\n============================================================\n');
    fprintf('EMSICA subject = %s\n', sb);
    fprintf('  b0folder = %s\n', b0folder);
    fprintf('  synth truth input = %s\n', synth_truth_folder);
    fprintf('  EMSICA output tag = %s\n', num2str_or_default(emsica_output_tag));
    fprintf('  myalpha = %s\n', num2str_or_default(subject_myalpha));
    fprintf('  mybeta = %s\n', num2str_or_default(mybeta));
    fprintf('  B0method = %s\n', B0method);
    fprintf('  variants = %s\n', strjoin({emsica_variants.token}, ', '));
    fprintf('============================================================\n\n');
    % Meaningful B0method options for synth runs:
    %   fastica
    %     Uses get_LB0A0_by_ica.m and loads 3ica/ICs-synth-fastica/.
    %   infomax
    %     Uses get_LB0A0_by_ica.m and loads 3ica/ICs-synth-infomax/.
    %   random
    %     Uses the infomax initializer as the cached base B0, then
    %     simulation_run() perturbs EEG.SigmainvB0 with gaussian_blend
    %     before the gradient run and restores the cached B0 afterward.
    %   sLORETA | minimum-norm | psudo-inv | lcmv 
    %     Uses get_LB0A0_by_sphx_source_space.m.
    %   synthBS
    %     Special test path using ground-truth synth data in
    %     get_LB0A0_by_sphx_source_space.m.

    if ~any(strcmpi(baseB0method, {'fastica' 'infomax'})) % for B0method== fastica | infomax we just use ica result as initial condition, so we donot need clean results
      clean_(s, 'emsicafolder','4clean/ICs-synth-infomax/', ...
        'as2plot','off','eeginterp','off','erp2plot','off', ...
        'ersp2mat','off','ersp2plot','off','icatype','bypass');
    end

    b0set = fullfile(s.subjectdir, b0folder, [sb '.set']);
    enforce_synth_truth_readonly_guard(s, b0folder);
    effective_recompute_B0 = logical(recompute_B0);
    if ~effective_recompute_B0 && ~exist(b0set, 'file')
      if require_cached_B0
        error('simulation_run:RequiredCachedB0Missing', ...
          'Required cached B0 is missing at %s. Refusing to regenerate it.', b0set);
      end
      fprintf(['simulation_run(): forcing recompute_B0=1 because cached B0 for ' ...
        'B0method=%s is missing at %s\n'], B0method, b0set);
      effective_recompute_B0 = true;
    end
    if effective_recompute_B0
      if ~isfield(s, 'emsica') || ~isstruct(s.emsica)
        s.emsica = struct();
      end
      s.emsica.ica_input_folder = tagged_ica_folder(baseB0method, ica_output_tag);
      emsica_(s, 'emsicatype','B0', 'K',K, ...
        'emsicafolder', b0folder, 'B0method',baseB0method, ...
        'recompute','on', 'ith',20, 'plots',emsica_plots, ...
        'synth_truth_folder',synth_truth_folder);
    else
      fprintf('simulation_run(): reusing cached B0 at %s\n', b0set);
    end
    cleanup_random_b0 = []; %#ok<NASGU>
    active_b0folder = b0folder;
    if strcmpi(B0method, 'random')
      cleanup_random_b0 = perturb_b0set_for_random_run(b0set); %#ok<NASGU>
    elseif b0_perturb_strength > 0 && ~strcmpi(strtrim(b0_perturb_mode), 'none')
      [active_b0folder, active_b0set] = prepare_perturbed_b0_copy( ...
        s, b0folder, b0set, emsica_output_tag, b0_perturb_seed);
      cleanup_random_b0 = perturb_b0set_for_run(active_b0set, b0_perturb_mode, ...
        b0_perturb_strength, b0_perturb_seed, false); %#ok<NASGU>
    end

    for variant_idx = 1:numel(emsica_variants)
      variant = emsica_variants(variant_idx);
      emsica_method_name = build_emsica_method_name_from_variant(B0method, variant);
      emsica_method_name = apply_emsica_output_tag(emsica_method_name, variant, emsica_output_tag);
      emsicafolder = ['6emsica/ICs-synth-' emsica_method_name '/'];
      enforce_output_overwrite_guard(s, emsicafolder, B0method, variant, emsica_output_tag, ...
        b0_perturb_strength, b0_perturb_mode, overwrite_guard);
      variant_log_suffix = variant.log_suffix;

      [variant_ramp_steps, variant_exp_k, variant_r_begin, variant_r_end] = ...
        resolve_variant_spatiotemporal_mix_settings(spatiotemporal_mix_ramp_steps, spatiotemporal_mix_exp_k, spatiotemporal_mix_r_begin, spatiotemporal_mix_r_end);
      fprintf('EMSICA variant\n');
      fprintf('  token = %s\n', variant.token);
      fprintf('  emsicafolder = %s\n', emsicafolder);
      fprintf('  b_update_lrate_scale = %s\n', num2str_or_default(b_update_lrate_scale));
      fprintf('  spatiotemporal_mix_ramp_steps = %s\n', num2str_or_default(variant_ramp_steps));
      fprintf('  spatiotemporal_mix_exp_k = %s\n', num2str_or_default(variant_exp_k));
      fprintf('  spatiotemporal_mix_r_begin = %s\n', num2str_or_default(variant_r_begin));
      fprintf('  spatiotemporal_mix_r_end = %s\n', num2str_or_default(variant_r_end));
      fprintf('  runemsica_log_suffix = %s\n\n', num2str_or_default(variant_log_suffix));

      s_variant = configure_emsica(s, subject_myalpha, mybeta, b_update_lrate_scale, ...
        variant_ramp_steps, variant_exp_k, variant_r_begin, variant_r_end, ...
        variant_log_suffix);
      s_variant.emsica.enable_diagnostics = enable_diagnostics;
      s_variant.emsica.diagnostics_stride = diagnostics_stride;
      s_variant.emsica.maxsteps = maxsteps; % intend to make EMSICA equal its initializer
      s_variant.emsica.b0folder = active_b0folder;
      s_variant.emsica.ica_input_folder = tagged_ica_folder(baseB0method, ica_output_tag);
      effective_args.subjects = {sb};
      effective_args.myalpha = subject_myalpha;
      effective_args.mybeta = mybeta;
      effective_args.b_update_lrate_scale = b_update_lrate_scale;
      effective_args.spatiotemporal_mix_ramp_steps = variant_ramp_steps;
      effective_args.spatiotemporal_mix_exp_k = variant_exp_k;
      effective_args.spatiotemporal_mix_r_begin = variant_r_begin;
      effective_args.spatiotemporal_mix_r_end = variant_r_end;
      effective_args.runemsica_log_suffix = variant_log_suffix;
      effective_args.enable_diagnostics = enable_diagnostics;
      effective_args.diagnostics_stride = diagnostics_stride;
      effective_args.recompute_B0 = effective_recompute_B0;
      effective_args.b0folder = active_b0folder;
      effective_args.emsicafolder = emsicafolder;
      effective_args.ica_input_folder = s_variant.emsica.ica_input_folder;
      s_variant.emsica.simulation_run_args = effective_args;
      enforce_synth_truth_readonly_guard(s, emsicafolder);
      emsica_(s_variant, 'emsicatype', 'gradient', 'K', K, ...
        'emsicafolder', emsicafolder, ...
        'lapmethod', 'synth', 'recompute', 'on', 'plots', emsica_plots, ...
        'synth_truth_folder',synth_truth_folder);
      report_pilot_calibration_from_log(s_variant, effective_args);

      if maxsteps < 4
        return
      end
    end

    tidy(sb, 1);
  end % for ss

if ~skip_accuracy_plot
  fig2_args = { ...
    'subjects', subjects, ...
    'B0method', B0method, ...
    'similarity_metric', "corr", ... % "nmi"
    'compare_methods', get_comparison_methods(B0method), ...
    'plot_summary', 0};
  if isscalar(subjects)
    fig2_args = [fig2_args, {'example_subject', subjects{1}}];
  end
  fig2_source_acc(fig2_args{:});
end
end

function folder = tagged_ica_folder(icatype, output_tag)
output_tag = sanitize_output_tag_local(output_tag);
icatype = lower(strtrim(char(icatype)));
if isempty(output_tag)
  folder = ['3ica/ICs-synth-' icatype '/'];
else
  folder = ['3ica/ICs-synth-' icatype '-' output_tag '/'];
end
end

function folder = tagged_b0_folder(B0method, output_tag)
output_tag = sanitize_output_tag_local(output_tag);
method_name = canonicalize_B0method_name(B0method);
if isempty(output_tag)
  folder = ['6emsica/B0-synth-' method_name '/'];
else
  folder = ['6emsica/B0-synth-' method_name '-' output_tag '/'];
end
end

function enforce_synth_truth_readonly_guard(s, folderrel)
protected = normalize_absolute_path_local(fullfile(s.subjectdir, '2epochs/EPs-synth'));
target = normalize_absolute_path_local(fullfile(s.subjectdir, folderrel));
if strcmp(target, protected)
  error('simulation_run:ProtectedSynthTruthOutput', ...
    'Refusing to write output into protected standard truth folder: %s', target);
end
end

function path_out = normalize_absolute_path_local(path_in)
path_out = char(java.io.File(path_in).getCanonicalPath());
path_out = strrep(path_out, '\', '/');
while numel(path_out) > 1 && path_out(end) == '/'
  path_out(end) = [];
end
end

function methods = get_comparison_methods(B0method)
methods = {'infomax', ...
  ['B0-synth-' canonicalize_B0method_name(B0method)], ...
  'extended_emsica'};
end

function method_name = canonicalize_B0method_name(B0method)
token = lower(strtrim(char(B0method)));
switch token
  case 'sloreta'
    method_name = 'sLORETA';
  case 'synthbs'
    method_name = 'synthBS';
  otherwise
    method_name = char(B0method);
end
end

function method_name = build_emsica_method_name_from_variant(B0method, variant)
assert(strcmpi(variant.token, 'extended_emsica'));
method_name = [canonicalize_B0method_name(B0method) '-extended'];
end

function method_name = apply_emsica_output_tag(method_name, variant, output_tag)
output_tag = sanitize_output_tag_local(output_tag);
if isempty(output_tag)
  return
end
assert(strcmpi(variant.token, 'extended_emsica'));
method_name = [method_name '-' output_tag '-full'];
end

function tag = sanitize_output_tag_local(tag)
tag = regexprep(strtrim(char(tag)), '[^A-Za-z0-9_-]', '-');
tag = regexprep(tag, '-+', '-');
tag = regexprep(tag, '^-|-$', '');
end

function enforce_output_overwrite_guard(s, emsicafolder, B0method, variant, output_tag, perturb_strength, perturb_mode, overwrite_guard)
if ~overwrite_guard
  return
end
protected_method = build_emsica_method_name_from_variant(B0method, variant);
protected_folder = ['6emsica/ICs-synth-' protected_method '/'];
is_perturbed_run = perturb_strength > 0 && ~strcmpi(strtrim(char(perturb_mode)), 'none');
if is_perturbed_run && isempty(sanitize_output_tag_local(output_tag))
  error('simulation_run:OverwriteGuard', ...
    ['Refusing perturbed-B0 run without emsica_output_tag because it would write ' ...
    'to the main result folder %s.'], fullfile(s.subjectdir, protected_folder));
end
if is_perturbed_run && strcmp(normalize_folder_local(emsicafolder), normalize_folder_local(protected_folder))
  error('simulation_run:OverwriteGuard', ...
    'Refusing to write perturbed-B0 output into protected main folder %s.', ...
    fullfile(s.subjectdir, protected_folder));
end
end

function [ramp_steps, exp_k, r_begin, r_end] = resolve_variant_spatiotemporal_mix_settings(default_ramp_steps, default_exp_k, default_r_begin, default_r_end)
ramp_steps = default_ramp_steps;
exp_k = default_exp_k;
r_begin = default_r_begin;
r_end = default_r_end;
end

function baseB0method = resolve_base_B0method(B0method)
if strcmpi(B0method, 'random')
  baseB0method = 'infomax';
else
  baseB0method = B0method;
end
end

function cleanup_obj = perturb_b0set_for_random_run(b0set)
cleanup_obj = perturb_b0set_for_run(b0set, 'gaussian_blend', 1, 1);
end

function [stress_b0folder, stress_b0set] = prepare_perturbed_b0_copy(s, b0folder, b0set, output_tag, perturb_seed)
tag = sanitize_output_tag_local(output_tag);
if isempty(tag)
  tag = 'perturbedB0';
end
seed_tag = sprintf('seed%03d', round(perturb_seed));
if isempty(regexp(tag, ['(^|-)' seed_tag '$'], 'once'))
  tag = [tag '-' seed_tag];
end
base_b0folder = strip_trailing_slash_local(b0folder);
b0_parent = fileparts(base_b0folder);
b0_name = get_last_folder_name_local(base_b0folder);
stress_b0folder = normalize_folder_local(fullfile(b0_parent, ...
  [b0_name '-' tag]));
stress_b0dir = fullfile(s.subjectdir, stress_b0folder);
stress_b0set = fullfile(stress_b0dir, [s.subject '.set']);
if ~exist(b0set, 'file')
  error('simulation_run:B0CopyMissingSource', 'Cannot copy missing B0 set: %s', b0set);
end
if ~exist(stress_b0dir, 'dir')
  mkdir(stress_b0dir);
end
copyfile(b0set, stress_b0set);
source_fdt = replace_set_ext_local(b0set, '.fdt');
if exist(source_fdt, 'file')
  copyfile(source_fdt, replace_set_ext_local(stress_b0set, '.fdt'));
end
fprintf('simulation_run(): copied B0 input %s -> %s\n', b0set, stress_b0set);
end

function cleanup_obj = perturb_b0set_for_run(b0set, perturb_mode, perturb_strength, perturb_seed, restore_on_cleanup)
if nargin < 5
  restore_on_cleanup = true;
end
if ~exist(b0set, 'file')
  error('simulation_run:RandomB0Missing', 'Cannot randomize missing B0 set: %s', b0set);
end

EEG = pop_loadset(b0set);
if ~isfield(EEG, 'SigmainvB0') || isempty(EEG.SigmainvB0)
  error('simulation_run:RandomB0MissingField', 'EEG.SigmainvB0 is missing in %s', b0set);
end
[b0_dir, b0_base, b0_ext] = fileparts(b0set);
EEG.filepath = b0_dir;
EEG.filename = [b0_base b0_ext];
original_sigmainvB0 = EEG.SigmainvB0;
EEG.SigmainvB0 = perturb_initializer_matrix(original_sigmainvB0, ...
  perturb_mode, perturb_strength, perturb_seed);
pop_saveset(EEG, 'filename', EEG.filename, 'filepath', EEG.filepath);
fprintf(['simulation_run(): B0 perturbation active, perturbed EEG.SigmainvB0 in %s ' ...
  '(mode=%s, strength=%g, seed=%d)\n'], b0set, perturb_mode, perturb_strength, round(perturb_seed));

if restore_on_cleanup
  cleanup_obj = onCleanup(@() restore_b0set_sigmainvB0(b0set, original_sigmainvB0));
else
  cleanup_obj = [];
end
end

function name = get_last_folder_name_local(folder)
folder = strip_trailing_slash_local(folder);
[~, name] = fileparts(folder);
end

function folder = strip_trailing_slash_local(folder)
folder = strrep(char(folder), '\', '/');
while ~isempty(folder) && folder(end) == '/'
  folder(end) = [];
end
end

function path_out = replace_set_ext_local(path_in, new_ext)
[parent_dir, base_name] = fileparts(path_in);
path_out = fullfile(parent_dir, [base_name new_ext]);
end

function restore_b0set_sigmainvB0(b0set, original_sigmainvB0)
if ~exist(b0set, 'file')
  return
end
EEG = pop_loadset(b0set);
[b0_dir, b0_base, b0_ext] = fileparts(b0set);
EEG.filepath = b0_dir;
EEG.filename = [b0_base b0_ext];
EEG.SigmainvB0 = original_sigmainvB0;
pop_saveset(EEG, 'filename', EEG.filename, 'filepath', EEG.filepath);
fprintf('simulation_run(): restored original EEG.SigmainvB0 in %s\n', b0set);
end

function B_out = perturb_initializer_matrix(B_in, perturb_mode, perturb_strength, perturb_seed)
Bd = double(B_in);
if perturb_strength <= 0 || strcmpi(strtrim(perturb_mode), 'none')
  B_out = B_in;
  return
end

old_rng = rng;
cleanup_rng = onCleanup(@() rng(old_rng));
rng(round(perturb_seed), 'twister');

switch lower(strtrim(perturb_mode))
  case 'mixing'
    Klocal = size(Bd, 2);
    [Q, ~] = qr(randn(Klocal));
    mix = (1 - perturb_strength) * eye(Klocal) + perturb_strength * Q;
    Bp = Bd * mix;
  case 'gaussian_blend'
    noise = randn(size(Bd));
    noise = noise / max(norm(noise, 'fro'), eps);
    ref = Bd / max(norm(Bd, 'fro'), eps);
    Bp = (1 - perturb_strength) * ref + perturb_strength * noise;
  otherwise
    error('simulation_run:UnknownInitPerturbMode', ...
      'Unknown perturb mode: %s', perturb_mode);
end

ref_norm = norm(Bd, 'fro');
new_norm = norm(Bp, 'fro');
if ref_norm > 0 && new_norm > 0
  Bp = Bp * (ref_norm / new_norm);
end
B_out = cast(Bp, 'like', B_in);
end

%% ===================== Helper: (1) Configure EMSICA ========================
function s = configure_emsica(s, myalpha, mybeta, b_update_lrate_scale, spatiotemporal_mix_ramp_steps, spatiotemporal_mix_exp_k, spatiotemporal_mix_r_begin, spatiotemporal_mix_r_end, runemsica_log_suffix)
if ~isfield(s, 'emsica') || isempty(s.emsica)
  s.emsica = struct();
end

if isfield(s.emsica, 'lambda_reg0')
  s.emsica = rmfield(s.emsica, 'lambda_reg0');
end
if isfield(s.emsica, 'lambda_reg_final')
  s.emsica = rmfield(s.emsica, 'lambda_reg_final');
end
if isfield(s.emsica, 'lambda_schedule_mode')
  s.emsica = rmfield(s.emsica, 'lambda_schedule_mode');
end
if nargin >= 2 && ~isempty(myalpha)
  s.emsica.myalpha = myalpha;
elseif isfield(s.emsica, 'myalpha')
  s.emsica = rmfield(s.emsica, 'myalpha');
end
if nargin >= 3 && ~isempty(mybeta)
  s.emsica.mybeta = mybeta;
elseif isfield(s.emsica, 'mybeta')
  s.emsica = rmfield(s.emsica, 'mybeta');
end
if nargin >= 4 && ~isempty(b_update_lrate_scale)
  s.emsica.b_update_lrate_scale = b_update_lrate_scale;
elseif isfield(s.emsica, 'b_update_lrate_scale')
  s.emsica = rmfield(s.emsica, 'b_update_lrate_scale');
end
if nargin >= 5 && ~isempty(spatiotemporal_mix_ramp_steps)
  s.emsica.spatiotemporal_mix_ramp_steps = spatiotemporal_mix_ramp_steps;
elseif isfield(s.emsica, 'spatiotemporal_mix_ramp_steps')
  s.emsica = rmfield(s.emsica, 'spatiotemporal_mix_ramp_steps');
end
if nargin >= 6 && ~isempty(spatiotemporal_mix_exp_k)
  s.emsica.spatiotemporal_mix_exp_k = spatiotemporal_mix_exp_k;
elseif isfield(s.emsica, 'spatiotemporal_mix_exp_k')
  s.emsica = rmfield(s.emsica, 'spatiotemporal_mix_exp_k');
end
if nargin >= 7 && ~isempty(spatiotemporal_mix_r_begin)
  s.emsica.spatiotemporal_mix_r_begin = spatiotemporal_mix_r_begin;
elseif isfield(s.emsica, 'spatiotemporal_mix_r_begin')
  s.emsica = rmfield(s.emsica, 'spatiotemporal_mix_r_begin');
end
if nargin >= 8 && ~isempty(spatiotemporal_mix_r_end)
  s.emsica.spatiotemporal_mix_r_end = spatiotemporal_mix_r_end;
elseif isfield(s.emsica, 'spatiotemporal_mix_r_end')
  s.emsica = rmfield(s.emsica, 'spatiotemporal_mix_r_end');
end
if nargin >= 9 && ~isempty(runemsica_log_suffix)
  s.emsica.runemsica_log_suffix = runemsica_log_suffix;
elseif isfield(s.emsica, 'runemsica_log_suffix')
  s.emsica = rmfield(s.emsica, 'runemsica_log_suffix');
end
if isfield(s.emsica, 'temporal_grad_mode')
  s.emsica = rmfield(s.emsica, 'temporal_grad_mode');
end
if isfield(s.emsica, 'eta_smooth')
  s.emsica = rmfield(s.emsica, 'eta_smooth');
end
if isfield(s.emsica, 'eta_sparse')
  s.emsica = rmfield(s.emsica, 'eta_sparse');
end
if isfield(s.emsica, 'eta_sparse_final')
  s.emsica = rmfield(s.emsica, 'eta_sparse_final');
end
if isfield(s.emsica, 'inner_accept_metric')
  s.emsica = rmfield(s.emsica, 'inner_accept_metric');
end
if isfield(s.emsica, 'warm_steps')
  s.emsica = rmfield(s.emsica, 'warm_steps');
end
if isfield(s.emsica, 'ramp_steps')
  s.emsica = rmfield(s.emsica, 'ramp_steps');
end
end


function should_return = report_pilot_calibration_from_log(s, current_args)
should_return = false;
log_suffix = '';
if nargin >= 2 && isstruct(current_args) && isfield(current_args, 'runemsica_log_suffix') && ~isempty(current_args.runemsica_log_suffix)
  log_suffix = char(current_args.runemsica_log_suffix);
end
if isempty(log_suffix)
  logfile = fullfile(emsica_pac_log_dir_local(), [s.subject '_runemsica_log.txt']);
else
  logfile = fullfile(emsica_pac_log_dir_local(), [s.subject '_runemsica_log_' log_suffix '.txt']);
end
if ~exist(logfile, 'file')
  return
end
try
  txt = fileread(logfile);
catch
  return
end
pat_objective = ['pilot-objective-balance\(step=(?<step>\d+)\):.*?' ...
  'myalpha=(?<myalpha>[-+0-9.eE]+) mybeta=(?<mybeta>[-+0-9.eE]+)'];
objective_match = regexp(txt, pat_objective, 'names');
if isempty(objective_match)
  return
end
objective_match = objective_match(end);
current_call = format_simulation_run_call(current_args);
next_args = current_args;
next_args.myalpha = str2double(objective_match.myalpha);
next_args.mybeta = str2double(objective_match.mybeta);
next_call = format_simulation_run_call(next_args);
mdisp('yellow', ['Currently you run: ' current_call]);
mdisp('yellow', sprintf('Suggested next run: %s', next_call));
should_return = true;
end

function myalpha_out = resolve_subject_myalpha(subject, default_myalpha)
myalpha_out = default_myalpha;
[has_best, best_myalpha, myalpha_source] = lookup_best_myalpha_for_subject(subject);
if ~has_best
  return
end

myalpha_out = best_myalpha;
mdisp('yellow', sprintf([ ...
  'simulation_run(): replace myalpha from the default value %.6g to %.6g ' ...
  'for subject %s using %s'], ...
  default_myalpha, myalpha_out, subject, myalpha_source.label));
end

function [tf, myalpha, source_info] = lookup_best_myalpha_for_subject(subject)
subject = lower(strtrim(char(subject)));

tf = true;
  switch subject
    case 'zm23'
    myalpha = 0.025;
  % case 'zc15'
  %  myalpha = 0.025;
    otherwise
      tf = false;
      myalpha = NaN;
  end
if tf
  source_info = struct('kind', 'hardcoded_fallback', 'label', 'hardcoded fallback table', 'path', '');
else
  source_info = struct('kind', 'none', 'label', 'no subject-specific myalpha found', 'path', '');
end

end

function txt = format_simulation_run_call(args)
names = { ...
  'recompute_synthX'
  'recompute_B0'
  'stype'
  'subjects'
  'myalpha'
  'mybeta'
  'b_update_lrate_scale'
  'spatiotemporal_mix_ramp_steps'
  'spatiotemporal_mix_exp_k'
  'spatiotemporal_mix_r_begin'
  'spatiotemporal_mix_r_end'
  'B0method'
  'maxsteps'
  'synth_truth_folder'
  'ica_output_tag'
  'emsica_output_tag'
  'require_cached_B0'};
parts = cell(1, numel(names));
for ii = 1:numel(names)
  name = names{ii};
  if isfield(args, name)
    value = args.(name);
  else
    value = [];
  end
  parts{ii} = [name '=' format_simulation_arg_value(value)];
end
txt = ['simulation_run(' strjoin(parts, ', ') ')'];
end

function txt = format_simulation_arg_value(value)
if isstring(value) && isscalar(value)
  txt = ['"' char(value) '"'];
elseif ischar(value)
  txt = ['''' value ''''];
elseif isnumeric(value) || islogical(value)
  if isempty(value)
    txt = '[]';
  elseif isscalar(value)
    txt = num2str(value, '%.15g');
  else
    txt = mat2str(value);
  end
elseif iscell(value)
  if isempty(value)
    txt = '{}';
  else
    items = cell(1, numel(value));
    for ii = 1:numel(value)
      items{ii} = format_simulation_arg_value(value{ii});
    end
    txt = ['{' strjoin(items, ', ') '}'];
  end
else
  txt = mat2str(value);
end
end

function txt = num2str_or_default(x)
if isempty(x)
  txt = '(default)';
else
  txt = num2str(x);
end
end

function folder = normalize_folder_local(folder)
folder = strrep(strtrim(char(folder)), '\', '/');
if isempty(folder)
  folder = '2epochs/EPs-synth/';
end
if ~endsWith(folder, '/')
  folder = [folder '/'];
end
end

function logdir = emsica_pac_log_dir_local()
rootdir = getenv('EMSICA_PAC_ROOT');
if isempty(rootdir)
  rootdir = pwd;
end
logdir = fullfile(rootdir, 'outputs', 'logs');
if ~isfolder(logdir)
  mkdir(logdir);
end
end
