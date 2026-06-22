% runemsica_cpu_tidy() Extended EMSICA training with constrained B updates.
%
  %  Model:
  %    x(t) = L B s(t), with A = L B and u(t) = A^{-1} x(t).
  %
  %  This public implementation is the Extended EMSICA workflow: sign
  %  adaptation, progressive temporal/spatial weighting, and the direct
  %  Euclidean B-space update are always enabled.
  %
  %  Learning-rule variables:
  %    A = L B
  %    u = A^{-1} x + bias 1^T
  %    varphi = -(signs * tanh(u) + u)
  %    G = (1/block) varphi u^T
  %
  %  Current learning rule:
  %    1) Temporal-gradient term:
  %         grad_temporal = -L^T (A^{-1})^T * block * (I + G)
  %    2) Spatial regularizers:
  %         grad_sparse = -2 myalpha tanh(B)
  %         grad_smooth = -mybeta invC B
  %    3) B-space update:
  %         Delta_B = r(step) grad_temporal + (1-r(step)) (grad_sparse + grad_smooth)
  %         B_try = B + eta_B lrate Delta_B
  %         where eta_B is the retry-loop damping factor for the whole B-space update,
  %         and, when enabled,
  %         r(step) = r_begin + (r_end - r_begin) * (exp(k * progress) - 1) / (exp(k) - 1),
  %         with progress = min(step / ramp_steps, 1) and k = 5.
  %         So it starts near r_begin, rises slowly at first, and reaches
  %         r_end by the end of the ramp.
  %    4) Accept/reject:
  %         accept B_try only if normalized_repulsion_energy(B_try)
  %         <= normalized_repulsion_energy(B) + 0.0005.
  %         If rejected, halve eta_B and retry the same Delta_B pattern.
  %         If all retries fail, keep the old B and continue to the next
  %         block iteration.
  %    5) Bias update:
  %         bias <- bias + lrate * mean(varphi, 2) * block
  %         This bias step is self-consistent with the chosen score varphi,
  %         not identical to runica or runica_a.
  %
  %  Temporal tracking note for synth runs:
  %    EMSICA is intentionally evaluated on the same synthetic Xtilde used
  %    by the current method/run, where Xtilde = sph*x_clean in the synth
  %    wrapper path. In synth mode the tracked temporal target is
  %    (L*target_B)\Xtilde, so the temporal score reflects recovery on that
  %    run's own Infomax-initialized data rather than on an external shared
  %    X_ref.
  % 
  % 2026-01-18 arthur
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function [w, a, B, U, bias, signs, meanvar] = runemsica_cpu_tidy(s, X, L, B0, invC, Imat, groundtruth)
  if nargin < 7
    groundtruth = [];
  end
  s = get_info(s);
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

config_myalpha = [];
config_mybeta = [];
config_b_update_lrate_scale = [];
config_spatiotemporal_mix_ramp_steps = [];
config_spatiotemporal_mix_exp_k = [];
config_spatiotemporal_mix_r_begin = [];
config_spatiotemporal_mix_r_end = [];
config_enable_diagnostics = false;
config_diagnostics_stride = 1;
config_runemsica_log_suffix = '';
if isfield(s, 'emsica') && isstruct(s.emsica)
  if isfield(s.emsica, 'myalpha') && ~isempty(s.emsica.myalpha)
    config_myalpha = double(s.emsica.myalpha);
  end
  if isfield(s.emsica, 'mybeta') && ~isempty(s.emsica.mybeta)
    config_mybeta = double(s.emsica.mybeta);
  end
  if isfield(s.emsica, 'b_update_lrate_scale') && ~isempty(s.emsica.b_update_lrate_scale)
    config_b_update_lrate_scale = double(s.emsica.b_update_lrate_scale);
  end
  if isfield(s.emsica, 'spatiotemporal_mix_ramp_steps') && ~isempty(s.emsica.spatiotemporal_mix_ramp_steps)
    config_spatiotemporal_mix_ramp_steps = double(s.emsica.spatiotemporal_mix_ramp_steps);
  end
  if isfield(s.emsica, 'spatiotemporal_mix_exp_k') && ~isempty(s.emsica.spatiotemporal_mix_exp_k)
    config_spatiotemporal_mix_exp_k = double(s.emsica.spatiotemporal_mix_exp_k);
  end
  if isfield(s.emsica, 'spatiotemporal_mix_r_begin') && ~isempty(s.emsica.spatiotemporal_mix_r_begin)
    config_spatiotemporal_mix_r_begin = double(s.emsica.spatiotemporal_mix_r_begin);
  end
  if isfield(s.emsica, 'spatiotemporal_mix_r_end') && ~isempty(s.emsica.spatiotemporal_mix_r_end)
    config_spatiotemporal_mix_r_end = double(s.emsica.spatiotemporal_mix_r_end);
  end
  if isfield(s.emsica, 'enable_diagnostics') && ~isempty(s.emsica.enable_diagnostics)
    config_enable_diagnostics = logical(s.emsica.enable_diagnostics);
  end
  if isfield(s.emsica, 'diagnostics_stride') && ~isempty(s.emsica.diagnostics_stride)
    config_diagnostics_stride = max(1, round(double(s.emsica.diagnostics_stride)));
  end
  if isfield(s.emsica, 'runemsica_log_suffix') && ~isempty(s.emsica.runemsica_log_suffix)
    config_runemsica_log_suffix = char(s.emsica.runemsica_log_suffix);
  end
end
% Start the diary early so epoch-0 / initializer diagnostics are captured.
% tStamp = datestr(now, 'yyyy-mm-dd_HH-MM');
% fileName = ['~/emsicalab/emsica/' s.subject '_runemsica_log_', tStamp, '.txt'];
log_suffix = strtrim(char(config_runemsica_log_suffix));
if isempty(log_suffix)
  fileName = fullfile(emsica_pac_log_dir_local(), [s.subject '_runemsica_log.txt']);
else
  fileName = fullfile(emsica_pac_log_dir_local(), [s.subject '_runemsica_log_' log_suffix '.txt']);
end
if exist(fileName, 'file'), backupfile(fileName); end
myrm(fileName);
mdisp('yellow', ['diary log on ' fileName]);
diary(fileName)

sim_run_args = struct();
if isfield(s, 'emsica') && isstruct(s.emsica) && ...
    isfield(s.emsica, 'simulation_run_args') && isstruct(s.emsica.simulation_run_args)
  sim_run_args = s.emsica.simulation_run_args;
end
if ~isfield(sim_run_args, 'myalpha'), sim_run_args.myalpha = config_myalpha; end
if ~isfield(sim_run_args, 'mybeta'), sim_run_args.mybeta = config_mybeta; end
if ~isfield(sim_run_args, 'b_update_lrate_scale'), sim_run_args.b_update_lrate_scale = config_b_update_lrate_scale; end
if ~isfield(sim_run_args, 'spatiotemporal_mix_ramp_steps'), sim_run_args.spatiotemporal_mix_ramp_steps = config_spatiotemporal_mix_ramp_steps; end
if ~isfield(sim_run_args, 'spatiotemporal_mix_exp_k'), sim_run_args.spatiotemporal_mix_exp_k = config_spatiotemporal_mix_exp_k; end
if ~isfield(sim_run_args, 'spatiotemporal_mix_r_begin'), sim_run_args.spatiotemporal_mix_r_begin = config_spatiotemporal_mix_r_begin; end
if ~isfield(sim_run_args, 'spatiotemporal_mix_r_end'), sim_run_args.spatiotemporal_mix_r_end = config_spatiotemporal_mix_r_end; end
if ~isfield(sim_run_args, 'enable_diagnostics'), sim_run_args.enable_diagnostics = config_enable_diagnostics; end
if ~isfield(sim_run_args, 'diagnostics_stride'), sim_run_args.diagnostics_stride = config_diagnostics_stride; end
if ~isfield(sim_run_args, 'runemsica_log_suffix'), sim_run_args.runemsica_log_suffix = config_runemsica_log_suffix; end

  %% =========================== Dimensions ============================
  [I, T] = size(X); [~, K] = size(B0);

% ---- rescale L 2026-02-17 ----
% ICA Convention: For sphered data where E[XX^T] = I, the mixing matrix A typically has a Frobenius norm related to the number of components. 
% If $A$ is too small, the algorithm may struggle with numerical precision, 
% and the log-determinant term (L_jacobian) will start at a very large positive value, 
% potentially biasing the initial steps of the gradient descent.

% Rescaling L by std(U0(:)) is a clever and effective way to ensure your model adheres to the ICA convention. 
% By using the standard deviation of the initial source estimates (U0), 
% you are essentially forcing the initial mixing matrix A to be at a scale that produces unit-variance sources.

% 1. Initial estimate of A with raw L
A = L * B0;

% 2. Calculate initial sources to find the required scale
U0 = A \ double(X);

% 3. Apply the scale to L (the Leadfield)
L = L * std(U0(:));

if isempty(Imat)
  Imat = eye(K, 'like', B0);
end
% ----- match stable gradientemsica_gpu defaults -----              % <--
% Typical “working ranges” after normalization of invC as shown above:
% • myalpha: 0.5–5
% • mybeta: 0.01–0.3
myalpha    = 2; % sparseness
mybeta     = 1; % smoothness
b_update_lrate_scale = 1;
spatiotemporal_mix_ramp_steps = [];
spatiotemporal_mix_exp_k = [];
spatiotemporal_mix_r_begin = 0;
spatiotemporal_mix_r_end = 1;
if ~isempty(config_myalpha)
  myalpha = config_myalpha;
end
if ~isempty(config_mybeta)
  mybeta = config_mybeta;
end
if ~isempty(config_b_update_lrate_scale)
  b_update_lrate_scale = config_b_update_lrate_scale;
end
if ~isempty(config_spatiotemporal_mix_ramp_steps)
  spatiotemporal_mix_ramp_steps = config_spatiotemporal_mix_ramp_steps;
end
if ~isempty(config_spatiotemporal_mix_exp_k)
  spatiotemporal_mix_exp_k = config_spatiotemporal_mix_exp_k;
end
if ~isempty(config_spatiotemporal_mix_r_begin)
  spatiotemporal_mix_r_begin = config_spatiotemporal_mix_r_begin;
end
if ~isempty(config_spatiotemporal_mix_r_end)
  spatiotemporal_mix_r_end = config_spatiotemporal_mix_r_end;
end
suggest_spatial_weight_step = 2;
%% ============================ (1) Defaults =============================
invC = 0.5*(invC + invC');                  % symmetrize the spatial precision matrix
invC = invC / norm(invC,'fro');     % make invC scale = 1
target_B = [];
if ~isempty(groundtruth) && isstruct(groundtruth)
  if isfield(groundtruth, 'A') && ~isempty(groundtruth.A)
    target_B = pinv(double(L)) * double(groundtruth.A);
  elseif isfield(groundtruth, 'B') && ~isempty(groundtruth.B)
    target_B = double(groundtruth.B);
  end
end


%% ============== (2) Stopping Rule (Simple + Robust) ============== %<--
patience   = 5;        %<-- consecutive steps required to be "small"
rel_tol    = 1e-4;     %<-- relative B-change tolerance

MAX_WEIGHT           = 1e8;
DEFAULT_MAXSTEPS     = 512;
DEFAULT_LRATE        = 0.05/log(I)*0.01; % *0.01 for zm01, or zm02,  *0.001 for 
DEFAULT_BLOCK        = ceil(min(10*log(T), 0.3*T));

DEFAULT_EXTBLOCKS    = 1;
DEFAULT_EXTMOMENTUM  = 0.5;
SIGNCOUNT_THRESHOLD  = 25;
SIGNCOUNT_STEP       = 2;

% --- annealstep ---
DEFAULT_ANNEALDEG  = 60;
DEFAULT_EXTANNEAL  = 0.98;
annealdeg  = DEFAULT_ANNEALDEG;
annealstep = DEFAULT_EXTANNEAL;


degconst  = 180/pi;
olddelta  = [];
oldchange = NaN;
% --- annealstep (end) ---

MIN_LRATE            = 1e-6;
DEFAULT_RESTART_FAC  = 0.9;

signsbias            = 0.02;
kurtsize             = min(6000, T);

maxsteps   = DEFAULT_MAXSTEPS;
lrate      = DEFAULT_LRATE;
block      = DEFAULT_BLOCK;
extblocks  = DEFAULT_EXTBLOCKS;
extmomentum= DEFAULT_EXTMOMENTUM;

if isfield(s, 'emsica') && isstruct(s.emsica) && ...
    isfield(s.emsica, 'maxsteps') && ~isempty(s.emsica.maxsteps)
  maxsteps = max(0, round(double(s.emsica.maxsteps)));
end
if isempty(config_spatiotemporal_mix_ramp_steps) || ...
    ~isfinite(config_spatiotemporal_mix_ramp_steps) || ...
    config_spatiotemporal_mix_ramp_steps <= 0
  spatiotemporal_mix_ramp_steps = maxsteps;
end
if isempty(config_spatiotemporal_mix_exp_k) || ...
    ~isfinite(config_spatiotemporal_mix_exp_k) || ...
    config_spatiotemporal_mix_exp_k <= 0
  spatiotemporal_mix_exp_k = 1;
end
if isempty(config_spatiotemporal_mix_r_begin) || ~isfinite(config_spatiotemporal_mix_r_begin)
  spatiotemporal_mix_r_begin = 0;
end
if isempty(config_spatiotemporal_mix_r_end) || ~isfinite(config_spatiotemporal_mix_r_end)
  spatiotemporal_mix_r_end = 1;
end
pilot_skip_inner_B = (maxsteps > 0) && (maxsteps <= suggest_spatial_weight_step);
pilot_skip_inner_B_notified = false;

%% =================== (3) Runica-Like Header Logs ====================
fprintf('\nInput data size [%d,%d] = %d channels, %d frames\n', I, T, I, T);
fprintf('Finding %d components for Extended EMSICA model, x(t) = LBs(t).\n', K);
fprintf('Kurtosis will be calculated initially every %d blocks using %d data points.\n', extblocks, kurtsize);
fprintf('Decomposing %d frames per weight ((%d)^2 = %d weights, %d frames)\n', floor(T/(K.^2)), K, K.^2, T);
fprintf('Initial learning rate will be %g, block size %d.\n', lrate, block);
fprintf('Learning rate will be multiplied by %g whenever angledelta >= %g deg.\n', annealstep, annealdeg);
fprintf('Training will end when relchg (and energies, if enabled) plateau or after %d steps.\n', maxsteps); %<--
fprintf('Online bias adjustment will be used.\n');

%% =========================== (4) Preprocess ============================
X = X - mean(X, 2);
fprintf('Removing mean of each channel ...\n');
fprintf('Final training data range: %g to %g\n', min(X(:)), max(X(:)));

% signs init (1 sub-Gaussian)
nsub = 1;
sgn = ones(1,K);
sgn(1:nsub) = -1;
signs = diag(sgn);

%% ============================== (5) Init ===============================
B    = B0;                     % <-- B-space parameter
if ~isempty(target_B)
  target_B = cast(target_B, 'like', B0);
  targetBStdRef = std(double(B0(:)));
  targetBStdCur = std(double(target_B(:)));
  if isfinite(targetBStdRef) && isfinite(targetBStdCur) && targetBStdCur > 0
    target_B = cast(double(target_B) * (targetBStdRef / targetBStdCur), 'like', B0);
  end
end
bias = zeros(K,1, 'like', B0); % <-- bias in source space
wts_blowup = 0;

Utarget_track = [];
if ~isempty(target_B)
  spatialCorrAccB0 = compute_spatial_corr_accuracy(B0, target_B);
  Utarget_track = (double(L) * double(target_B)) \ double(X);
end

if maxsteps <= 0
  mdisp('yellow', ['runemsica_cpu_tidy(): maxsteps=' num2str(maxsteps) ', skip gradient updates after preprocessing/normalization.']);
  fprintf('Skipping EMSICA gradient training because maxsteps=%d after preprocessing/normalization.\n', maxsteps);
  a = L * B;
  w = a \ eye(size(a,1));
  U = w * double(X);
  meanvar = sum(a.^2) .* sum((U').^2) / ((I*T)-1);
  diary off;
  return;
end

fprintf('Beginning EMSICA training ... first training step may be slow ...\n');

oldsigns  = zeros(size(signs));
signcount = 0;
old_kk    = zeros(1,K);

onesrow = ones(1,block, 'like', X);

lastt   = fix((T/block-1)*block+1);
step    = 0;
blockno = 1;

relchg_hist   = nan(1,maxsteps);             %<-- (NEW) relative ||dB|| / ||B||

diagnostics_enabled = logical(config_enable_diagnostics);
diagnostics_stride = max(1, round(double(config_diagnostics_stride)));
diag_step = nan(1, maxsteps + 1);
diag_temporal_mix_r = nan(1, maxsteps + 1);
diag_lrate = nan(1, maxsteps + 1);
diag_eta_B = nan(1, maxsteps + 1);
diag_maxCosB = nan(1, maxsteps + 1);
diag_EoffB = nan(1, maxsteps + 1);
diag_condA = nan(1, maxsteps + 1);
diag_sigmaMinA = nan(1, maxsteps + 1);
diag_rcondA = nan(1, maxsteps + 1);
diag_relchg = nan(1, maxsteps + 1);
diag_spatialCorrAcc = nan(1, maxsteps + 1);
diag_temporalCorrAcc = nan(1, maxsteps + 1);
diag_update_angle_deg = nan(1, maxsteps + 1);
diag_accepted_updates = zeros(1, maxsteps + 1);
diag_rejected_updates = zeros(1, maxsteps + 1);
diag_retries = zeros(1, maxsteps + 1);
diag_anneal_events = zeros(1, maxsteps + 1);
diag_naninf = false(1, maxsteps + 1);
diag_n = 0;
diag_total_accepted_updates = 0;
diag_total_rejected_updates = 0;
diag_total_retries = 0;
diag_total_anneal_events = 0;
diag_stop_reason = 'maxsteps';
diag_converged = false;
diag_rng_state_start = rng;
if diagnostics_enabled
  [diag_n, diag_step, diag_temporal_mix_r, diag_lrate, diag_eta_B, ...
    diag_maxCosB, diag_EoffB, diag_condA, diag_sigmaMinA, diag_rcondA, ...
    diag_relchg, diag_spatialCorrAcc, diag_temporalCorrAcc, ...
    diag_update_angle_deg, ...
    diag_accepted_updates, diag_rejected_updates, ...
    diag_retries, diag_anneal_events, diag_naninf] = ...
    append_emsica_diagnostic_row(diag_n, diag_step, diag_temporal_mix_r, ...
      diag_lrate, diag_eta_B, diag_maxCosB, diag_EoffB, diag_condA, ...
      diag_sigmaMinA, diag_rcondA, diag_relchg, diag_spatialCorrAcc, ...
      diag_temporalCorrAcc, diag_update_angle_deg, ...
      diag_accepted_updates, diag_rejected_updates, ...
      diag_retries, diag_anneal_events, diag_naninf, ...
      step, NaN, lrate, NaN, B, L, X, target_B, Utarget_track, ...
      NaN, NaN, 0, 0, 0, 0);
end

startB  = B;                   % <-- restart anchor in B-space
oldB    = B;
stop_training_early = false;

%% ========================= (7) Training Loop ==========================
while step < maxsteps
  timeperm = randperm(T);
  eta_B_epoch = NaN;
  diag_epoch_accepted_updates = 0;
  diag_epoch_rejected_updates = 0;
  diag_epoch_retries = 0;
  diag_epoch_anneal_events = 0;

  for t = 1:block:lastt
    Xblk = X(:, timeperm(t:t+block-1));

    % ===== (1) demix in sensor space: u = (L*B)\Xblk =====
    a = L * B;                                                              % <-- a is current mixing (I x K)
    rcondA = rcond(double(a));
    if ~isfinite(rcondA) || rcondA < 1e-12
      illCondMsg = sprintf(['runemsica_cpu_tidy(): rcond(L*B)=%.3e is too small ' ...
        '(step=%d, blockno=%d).'], rcondA, step, blockno);
      error('runemsica:IllConditionedA', '%s', illCondMsg);
    end
    % u = a \ Xblk;                                                            % <-- u is K x block
    u = a \ Xblk + bias*onesrow;  % <-- (use A\X)


  % ===== (3) Infomax score for temporal separation =====
  % y = tanh(u);                                                       % <-- EEGLAB extended uses tanh(u)

  % % ===== (4) runica style =====
  % G  = (1/block)*(-signs*y*u' - u*u');
  varphi = -(signs*tanh(u) + u);        % example based on your G form
  G      = (1/block) * (varphi*u');


  % ===== alternating optimization =====
		% Spatial projection gradient in B-space form.
  AinvT = (double(a) \ eye(size(a, 1)))';
  grad_temporal = -double(L)' * AinvT * block * double(Imat + G);
  temporal_mix_r = compute_spatiotemporal_mix_for_step(step, spatiotemporal_mix_ramp_steps, spatiotemporal_mix_exp_k, spatiotemporal_mix_r_begin, spatiotemporal_mix_r_end);

    % ---- constrained direct update in B space ----
    if pilot_skip_inner_B
      if ~pilot_skip_inner_B_notified
        mdisp('yellow', 'pilot-calibration: skipping the B update for a short calibration run.');
        pilot_skip_inner_B_notified = true;
      end
    else
      grad_smooth = -mybeta * (invC * B);
      grad_sparse = -2.0 * myalpha * tanh(B);
      eta_B = 1;
      accepted = false;
      B_base = B;
      repEnergyAcceptTol = 0.0005;
      repEnergyCurr = normalized_repulsion_energy(B);

      for damp_try = 1:8
        if isnan(temporal_mix_r)
          B_step = grad_temporal + double(grad_sparse) + double(grad_smooth);
        else
          B_step = temporal_mix_r * grad_temporal + ...
            (1 - temporal_mix_r) * (double(grad_sparse) + double(grad_smooth));
        end
        B_try = cast(double(B_base) + ...
          eta_B * (lrate * b_update_lrate_scale) * B_step, 'like', B0);
        repEnergyTry = normalized_repulsion_energy(B_try);
        if repEnergyTry <= (repEnergyCurr + repEnergyAcceptTol)
          B = B_try;
          accepted = true;
          break;
        end
        eta_B = 0.5 * eta_B;
      end

      eta_B_epoch = eta_B;
      if accepted
        diag_epoch_accepted_updates = diag_epoch_accepted_updates + 1;
        diag_epoch_retries = diag_epoch_retries + max(0, damp_try - 1);
      else
        B = B_base;
        diag_epoch_rejected_updates = diag_epoch_rejected_updates + 1;
        diag_epoch_retries = diag_epoch_retries + 8;
      end

      if ~isempty(target_B) && isfinite(spatialCorrAccB0)
        spatialCorrAccB_after_inner = compute_spatial_corr_accuracy(B, target_B);
        if isfinite(spatialCorrAccB_after_inner) && spatialCorrAccB_after_inner < spatialCorrAccB0
          mdisp('red', sprintf(['Early stopping EMSICA: spatialCorrAcc(B)=%.6f dropped below ' ...
            'spatialCorrAcc(B0)=%.6f at step=%d, blockno=%d. ' ...
            'Parameters r, myalpha, or mybeta may not be set appropriately.'], ...
            spatialCorrAccB_after_inner, spatialCorrAccB0, step, blockno));
          stop_training_early = true;
          break;
        end
      end
    end
   % bias = bias + lrate * sum((-2*y)')';                % <-- keep tanh-style bias update
bias   = bias + lrate * mean(varphi,2) * block;  % or sum(varphi,2)


    % ---- STABILITY CHECK & NORMALIZATION ----
    if max(abs(B(:))) > MAX_WEIGHT
      wts_blowup = 1; break
    end

    % ---- kurtosis-based sign estimation (on U) ----
    if extblocks > 0 && rem(blockno, extblocks) == 0
      if kurtsize < T
        rp = fix(rand(1,kurtsize) * T);
        rp(rp == 0) = 1;
        partact = (L * B) \ double(X(:, rp));             % <-- U = A\X (not A-space W*X)
      else
        partact = (L * B) \ double(X);
      end

      m2 = mean(partact'.^2).^2;
      m4 = mean(partact'.^4);
      kk = (m4./m2) - 3.0;

      kk = extmomentum*old_kk + (1-extmomentum)*kk;
      old_kk = kk;

      signs = diag(sign(kk + signsbias));

      if isequal(signs, oldsigns)
        signcount = signcount + 1;
      else
        signcount = 0;
      end
      oldsigns = signs;

      if signcount >= SIGNCOUNT_THRESHOLD
        extblocks = fix(extblocks * SIGNCOUNT_STEP);
        signcount = 0;
      end
    end

    blockno = blockno + 1;
    if stop_training_early
      break
    end
  end % for t = 1:block:lastt

  if stop_training_early
    diag_stop_reason = 'spatial_accuracy_drop';
    break
  end

  if wts_blowup
    olddelta  = [];
    oldchange = NaN;

    lrate = lrate * DEFAULT_RESTART_FAC;
    if lrate < MIN_LRATE
      mdisp('red', 'quitting (B blew up).');
      % keyboard
    end

    B = startB;                                               % <-- restart B
    oldB = B;
    bias = zeros(K,1,'like',B);
    wts_blowup = 0;
    step = 0;
    blockno = 1;
    continue
  end

  %% ====================== Step Logs + Annealing ======================
  step = step + 1;

  dB    = B - oldB;                                              % <-- delta in B-space

  % ===== (NEW) relative change metric for stopping ===== %<--
  relchg = norm(dB,'fro') / (norm(oldB,'fro') + eps);            %<--
  relchg_hist(step) = relchg;                                    %<--
  dvec  = dB(:);                                                          %<--
  dnorm = norm(dvec) + eps;                                               %<--

  angledelta = 0;                                                         %<--
  if step > 2 && ~isempty(olddelta) && isfinite(oldchange) && oldchange > 0 %<--
    cang = (dvec' * olddelta) / (dnorm * oldchange);                      %<--
    cang = max(-1, min(1, cang));                                         %<--
    angledelta = acos(cang);                                              %<--
  end                                                                     %<--

    fprintf(['step %d - lrate %g, eta_B %g, r %s, ' ...
      'relchg %.3e, angledelta %4.1f deg\n'], ...
      step, lrate, eta_B_epoch, num2str_or_default(temporal_mix_r), relchg, degconst*angledelta);
  if degconst*angledelta > annealdeg                                  %<--
    lrate_prev = lrate;                                                   %<--
    lrate = lrate * annealstep;                                           %<--
    diag_epoch_anneal_events = diag_epoch_anneal_events + 1;
    mdisp('yellow', sprintf('anneal fired: angledelta %.1f deg > %.1f deg | lrate %.9g->%.9g', ...
      degconst*angledelta, annealdeg, lrate_prev, lrate)); %<--
    olddelta  = dvec;                                                     %<--
    oldchange = dnorm;                                                    %<--
  elseif step == 1                                                        %<--
    olddelta  = dvec;                                                     %<--
    oldchange = dnorm;                                                    %<--
  end                                                                     %<--

  %% ============== (2) Stopping Rule (Simple + Robust) ============== %<--
  if step >= patience                                                %<--
    win = (step-patience+1):step;                                  %<--
    ok_rel = max(relchg_hist(win)) < rel_tol;                      %<--
    if ok_rel                                                    %<--
      mdisp('yellow', ['Stopping: relchg plateau for ' num2str(patience) ' steps.']); %<--
      diag_converged = true;
      diag_stop_reason = 'relchg_plateau';
      stop_training_early = true;                              %<--
    end                                                          %<--
  end                                                                  %<--

  oldB = B; % <-- ensure oldB is updated every epoch

  diag_total_accepted_updates = diag_total_accepted_updates + diag_epoch_accepted_updates;
  diag_total_rejected_updates = diag_total_rejected_updates + diag_epoch_rejected_updates;
  diag_total_retries = diag_total_retries + diag_epoch_retries;
  diag_total_anneal_events = diag_total_anneal_events + diag_epoch_anneal_events;
  if diagnostics_enabled && (step == 1 || mod(step, diagnostics_stride) == 0 || step >= maxsteps)
    [diag_n, diag_step, diag_temporal_mix_r, diag_lrate, diag_eta_B, ...
      diag_maxCosB, diag_EoffB, diag_condA, diag_sigmaMinA, diag_rcondA, ...
      diag_relchg, diag_spatialCorrAcc, diag_temporalCorrAcc, ...
      diag_update_angle_deg, ...
      diag_accepted_updates, diag_rejected_updates, ...
      diag_retries, diag_anneal_events, diag_naninf] = ...
      append_emsica_diagnostic_row(diag_n, diag_step, diag_temporal_mix_r, ...
        diag_lrate, diag_eta_B, diag_maxCosB, diag_EoffB, diag_condA, ...
        diag_sigmaMinA, diag_rcondA, diag_relchg, diag_spatialCorrAcc, ...
        diag_temporalCorrAcc, diag_update_angle_deg, ...
        diag_accepted_updates, diag_rejected_updates, ...
        diag_retries, diag_anneal_events, diag_naninf, ...
        step, temporal_mix_r, lrate, eta_B_epoch, B, L, X, target_B, ...
        Utarget_track, relchg, degconst*angledelta, ...
        diag_epoch_accepted_updates, diag_epoch_rejected_updates, ...
        diag_epoch_retries, diag_epoch_anneal_events);
  end

  if stop_training_early
    break
  end

end % while step < maxsteps

if step >= maxsteps && ~diag_converged
  diag_stop_reason = 'maxsteps';
end

if diagnostics_enabled
  save_emsica_diagnostics(s, B, L, step, maxsteps, diag_converged, ...
    diag_stop_reason, diag_rng_state_start, rng, sim_run_args, ...
    diag_n, diag_step, diag_temporal_mix_r, diag_lrate, diag_eta_B, ...
    diag_maxCosB, diag_EoffB, diag_condA, diag_sigmaMinA, diag_rcondA, ...
    diag_relchg, diag_spatialCorrAcc, diag_temporalCorrAcc, ...
    diag_update_angle_deg, ...
    diag_accepted_updates, diag_rejected_updates, diag_retries, ...
    diag_anneal_events, diag_naninf, diag_total_accepted_updates, ...
    diag_total_rejected_updates, diag_total_retries, diag_total_anneal_events);
end

diary off;

[~, hn] = system('hostname');              % includes newline
hn = strtrim(hn);
mdisp('yellow', ['Finished and the diary log is on ' hn ':' fileName]);
% keyboard


%% ======================= (8) Finalize Outputs =========================
a = L * B;                                                        % <-- final A
w = a \ eye(size(a,1));                    % <-- if you truly need explicit W

% component activations (mean-removed)
U = w * double(X);                                                % <-- U = W*X (should match A\X)

% runica-style sorting by projected variance
winv = a;
meanvar = sum(winv.^2) .* sum((U').^2) / ((I*T)-1);

[~, windex] = sort(meanvar, 'descend');
meanvar = meanvar(windex);

w     = w(windex,:);
B     = B(:,windex);
a = L * B;                                                        % <-- final A
U     = U(windex,:);
bias  = bias(windex);
sg    = diag(signs);
signs = sg(windex);










%% ============= Helper: (1) Compute spatial correlation accuracy =============
function acc = compute_spatial_corr_accuracy(B, target_B)
Bd = double(B);
Td = double(target_B);
Ktruth = size(Td, 2);
Kest = size(Bd, 2);
if isempty(Td) || isempty(Bd) || Ktruth < 1 || Kest < Ktruth
  acc = NaN;
  return
end
C = nan(Ktruth, Kest);
for truth_idx = 1:Ktruth
  for est_idx = 1:Kest
    C(truth_idx, est_idx) = abs(spatial_fastcorr(Td(:, truth_idx), Bd(:, est_idx)));
  end
end
validRows = all(isfinite(C), 2);
validCols = all(isfinite(C), 1);
C = C(validRows, validCols);
if isempty(C) || size(C,2) < size(C,1)
  acc = NaN;
  return
end
[~, scores] = spatial_best_component_assignment(C);
acc = mean(scores, 'omitnan');
end

%% =============== Helper: (2) Compute temporal correlation accuracy ===============
function acc = compute_temporal_corr_accuracy(U_est, U_target)
Ud = double(U_est);
Td = double(U_target);
Ktruth = size(Td, 1);
Kest = size(Ud, 1);
if isempty(Td) || isempty(Ud) || Ktruth < 1 || Kest < Ktruth
  acc = NaN;
  return
end
C = nan(Ktruth, Kest);
for truth_idx = 1:Ktruth
  for est_idx = 1:Kest
    C(truth_idx, est_idx) = abs(spatial_fastcorr(Td(truth_idx, :), Ud(est_idx, :)));
  end
end
validRows = all(isfinite(C), 2);
validCols = all(isfinite(C), 1);
C = C(validRows, validCols);
if isempty(C) || size(C,2) < size(C,1)
  acc = NaN;
  return
end
[~, scores] = spatial_best_component_assignment(C);
acc = mean(scores, 'omitnan');
end

%% =============== Helper: (3) Find best component assignment ===============
function [bestPerm, bestScores] = spatial_best_component_assignment(C)
Ktruth = size(C,1);
Kest = size(C,2);
if Kest < Ktruth
  error('spatial_best_component_assignment:NotEnoughComponents', ...
    'Need at least as many estimated components as truth components.');
end
colSets = nchoosek(1:Kest, Ktruth);
bestTotal = -Inf;
bestPerm = nan(1, Ktruth);
for set_idx = 1:size(colSets, 1)
  cols = colSets(set_idx, :);
  permsCols = perms(cols);
  totals = sum(C(sub2ind(size(C), repmat(1:Ktruth, size(permsCols,1), 1), permsCols)), 2);
  [candTotal, idx] = max(totals);
  if candTotal > bestTotal
    bestTotal = candTotal;
    bestPerm = permsCols(idx,:);
  end
end
bestScores = C(sub2ind(size(C), 1:Ktruth, bestPerm));
end

%% ==================== Helper: (4) Compute fast correlation ====================
function r = spatial_fastcorr(x, y)
x = double(x(:));
y = double(y(:));
ok = isfinite(x) & isfinite(y);
x = x(ok);
y = y(ok);
if numel(x) < 5
  r = NaN;
  return
end
x = x - mean(x);
y = y - mean(y);
sx = std(x);
sy = std(y);
if sx == 0 || sy == 0
  r = NaN;
  return
end
r = (x' * y) / ((numel(x)-1) * sx * sy);
end

function [diag_n, diag_step, diag_temporal_mix_r, diag_lrate, diag_eta_B, ...
  diag_maxCosB, diag_EoffB, diag_condA, diag_sigmaMinA, diag_rcondA, ...
  diag_relchg, diag_spatialCorrAcc, diag_temporalCorrAcc, ...
  diag_update_angle_deg, ...
  diag_accepted_updates, diag_rejected_updates, ...
  diag_retries, diag_anneal_events, diag_naninf] = ...
  append_emsica_diagnostic_row(diag_n, diag_step, diag_temporal_mix_r, ...
    diag_lrate, diag_eta_B, diag_maxCosB, diag_EoffB, diag_condA, ...
    diag_sigmaMinA, diag_rcondA, diag_relchg, diag_spatialCorrAcc, ...
    diag_temporalCorrAcc, diag_update_angle_deg, ...
    diag_accepted_updates, diag_rejected_updates, ...
    diag_retries, diag_anneal_events, diag_naninf, ...
    step, temporal_mix_r, lrate, eta_B_epoch, B, L, X, target_B, ...
    Utarget_track, relchg, update_angle_deg, accepted_updates, ...
    rejected_updates, retries, anneal_events)

diag_n = diag_n + 1;
diag_step(diag_n) = step;
diag_temporal_mix_r(diag_n) = temporal_mix_r;
diag_lrate(diag_n) = lrate;
diag_eta_B(diag_n) = eta_B_epoch;
[diag_maxCosB(diag_n), diag_EoffB(diag_n)] = compute_spatial_collapse_metrics(B);
A = double(L) * double(B);
[diag_condA(diag_n), diag_sigmaMinA(diag_n), diag_rcondA(diag_n)] = matrix_health_metrics(A);
diag_relchg(diag_n) = relchg;
diag_update_angle_deg(diag_n) = update_angle_deg;
if ~isempty(target_B)
  diag_spatialCorrAcc(diag_n) = compute_spatial_corr_accuracy(B, target_B);
else
  diag_spatialCorrAcc(diag_n) = NaN;
end
if ~isempty(Utarget_track) && ~isempty(X)
  diag_temporalCorrAcc(diag_n) = compute_temporal_corr_accuracy(A \ double(X), Utarget_track);
else
  diag_temporalCorrAcc(diag_n) = NaN;
end
diag_accepted_updates(diag_n) = accepted_updates;
diag_rejected_updates(diag_n) = rejected_updates;
diag_retries(diag_n) = retries;
diag_anneal_events(diag_n) = anneal_events;
diag_naninf(diag_n) = any(~isfinite(double(B(:)))) || any(~isfinite(A(:)));
end

function save_emsica_diagnostics(s, B, L, step, maxsteps, converged, ...
  stop_reason, rng_state_start, rng_state_end, sim_run_args, ...
  diag_n, diag_step, diag_temporal_mix_r, diag_lrate, diag_eta_B, ...
  diag_maxCosB, diag_EoffB, diag_condA, diag_sigmaMinA, diag_rcondA, ...
  diag_relchg, diag_spatialCorrAcc, diag_temporalCorrAcc, ...
  diag_update_angle_deg, ...
  diag_accepted_updates, diag_rejected_updates, diag_retries, ...
  diag_anneal_events, diag_naninf, total_accepted_updates, ...
  total_rejected_updates, total_retries, total_anneal_events)

A = double(L) * double(B);
[final_condA, final_sigmaMinA, final_rcondA] = matrix_health_metrics(A);
[final_maxCosB, final_EoffB] = compute_spatial_collapse_metrics(B);
idx = 1:diag_n;
total_proposed_updates = total_accepted_updates + total_rejected_updates;
trajectory_lrate = diag_lrate(idx);
trajectory_angle_deg = diag_update_angle_deg(idx);
diagnostics = struct();
diagnostics.subject = s.subject;
diagnostics.created = datestr(now, 'yyyy-mm-dd HH:MM:SS');
diagnostics.maxsteps = maxsteps;
diagnostics.iterations_completed = step;
diagnostics.converged = logical(converged);
diagnostics.stop_reason = stop_reason;
diagnostics.rng_state_start = rng_state_start;
diagnostics.rng_state_end = rng_state_end;
diagnostics.simulation_run_args = sim_run_args;
diagnostics.final = struct( ...
  'maxCosB', final_maxCosB, ...
  'EoffB', final_EoffB, ...
  'condA', final_condA, ...
  'sigmaMinA', final_sigmaMinA, ...
  'rcondA', final_rcondA, ...
  'naninf_B_or_A', any(~isfinite(double(B(:)))) || any(~isfinite(A(:))), ...
  'proposed_updates', total_proposed_updates, ...
  'accepted_updates', total_accepted_updates, ...
  'rejected_updates', total_rejected_updates, ...
  'retries', total_retries, ...
  'anneal_events', total_anneal_events, ...
  'final_lrate', last_finite_local(trajectory_lrate), ...
  'min_lrate', min_finite_local(trajectory_lrate), ...
  'max_update_angle_deg', max_finite_local(trajectory_angle_deg), ...
  'mean_update_angle_deg', mean_finite_local(trajectory_angle_deg));

diagnostics.trajectory = table( ...
  diag_step(idx)', diag_temporal_mix_r(idx)', diag_lrate(idx)', ...
  diag_eta_B(idx)', diag_maxCosB(idx)', diag_EoffB(idx)', ...
  diag_condA(idx)', diag_sigmaMinA(idx)', diag_rcondA(idx)', ...
  diag_relchg(idx)', diag_spatialCorrAcc(idx)', diag_temporalCorrAcc(idx)', ...
  diag_update_angle_deg(idx)', ...
  (diag_accepted_updates(idx)' + diag_rejected_updates(idx)'), ...
  diag_accepted_updates(idx)', ...
  diag_rejected_updates(idx)', diag_retries(idx)', ...
  diag_anneal_events(idx)', diag_naninf(idx)', ...
  'VariableNames', {'step','temporal_mix_r','lrate','eta_B', ...
  'maxCosB','EoffB','condA','sigmaMinA','rcondA','relchg', ...
  'spatial_accuracy','temporal_accuracy', ...
  'update_angle_deg','proposed_updates','accepted_updates', ...
  'rejected_updates','retries','anneal_events','naninf_B_or_A'});

if isfield(s, 'workingdir') && ~isempty(s.workingdir)
  outdir = s.workingdir;
else
  outdir = pwd;
end
if ~exist(outdir, 'dir')
  mkdir(outdir);
end
save(fullfile(outdir, 'emsica_diagnostics.mat'), 'diagnostics');
try
  writetable(diagnostics.trajectory, fullfile(outdir, 'emsica_diagnostics_trajectory.csv'));
catch err
  warning('runemsica:DiagnosticsCsvWriteFailed', ...
    'Could not write emsica_diagnostics_trajectory.csv: %s', err.message);
end
fprintf('runemsica_cpu_tidy(): saved diagnostics to %s\n', fullfile(outdir, 'emsica_diagnostics.mat'));
end

function [condA, sigmaMinA, rcondA] = matrix_health_metrics(A)
Ad = double(A);
if isempty(Ad) || any(~isfinite(Ad(:)))
  condA = NaN;
  sigmaMinA = NaN;
  rcondA = NaN;
  return
end
svals = svd(Ad);
if isempty(svals)
  condA = NaN;
  sigmaMinA = NaN;
  rcondA = NaN;
  return
end
sigmaMinA = min(svals);
sigmaMaxA = max(svals);
condA = sigmaMaxA / max(sigmaMinA, eps);
rcondA = rcond(Ad);
end

function val = last_finite_local(x)
x = double(x(:));
x = x(isfinite(x));
if isempty(x)
  val = NaN;
else
  val = x(end);
end
end

function val = min_finite_local(x)
x = double(x(:));
x = x(isfinite(x));
if isempty(x)
  val = NaN;
else
  val = min(x);
end
end

function val = max_finite_local(x)
x = double(x(:));
x = x(isfinite(x));
if isempty(x)
  val = NaN;
else
  val = max(x);
end
end

function val = mean_finite_local(x)
x = double(x(:));
x = x(isfinite(x));
if isempty(x)
  val = NaN;
else
  val = mean(x);
end
end

%% ================= Helper: (7) Compute normalized repulsion energy =================
function energy = normalized_repulsion_energy(B)
Bd = double(B);
[~, Klocal] = size(Bd);
if Klocal <= 1
  energy = 0;
  return
end
nrm = sqrt(sum(Bd.^2, 1)) + eps;
Q = Bd ./ nrm;
Gnorm = Q' * Q;
energy = 0.5 * norm(Gnorm - eye(Klocal), 'fro')^2;
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

function txt = num2str_or_default(value, fmt)
if nargin < 2 || isempty(fmt)
  fmt = '%.6g';
end
if isempty(value) || (isscalar(value) && isnumeric(value) && ~isfinite(value))
  txt = '(default)';
else
  txt = num2str(value, fmt);
end
end

function temporal_mix_r = compute_spatiotemporal_mix_for_step(step, spatiotemporal_mix_ramp_steps, spatiotemporal_mix_exp_k, spatiotemporal_mix_r_begin, spatiotemporal_mix_r_end)
temporal_mix_r = NaN;
if isempty(spatiotemporal_mix_ramp_steps) || ~isfinite(spatiotemporal_mix_ramp_steps) || spatiotemporal_mix_ramp_steps <= 0
  return
end
if isempty(spatiotemporal_mix_exp_k) || ~isfinite(spatiotemporal_mix_exp_k) || spatiotemporal_mix_exp_k <= 0
  spatiotemporal_mix_exp_k = 5;
end
if isempty(spatiotemporal_mix_r_begin) || ~isfinite(spatiotemporal_mix_r_begin)
  spatiotemporal_mix_r_begin = 0;
end
if isempty(spatiotemporal_mix_r_end) || ~isfinite(spatiotemporal_mix_r_end)
  spatiotemporal_mix_r_end = 1;
end
progress = min(max(double(step) / double(spatiotemporal_mix_ramp_steps), 0), 1);
denom = exp(spatiotemporal_mix_exp_k) - 1;
if abs(denom) < eps
  temporal_mix_r_unit = progress;
else
  temporal_mix_r_unit = (exp(spatiotemporal_mix_exp_k * progress) - 1) / denom;
end
temporal_mix_r = spatiotemporal_mix_r_begin + (spatiotemporal_mix_r_end - spatiotemporal_mix_r_begin) * temporal_mix_r_unit;
end

end
