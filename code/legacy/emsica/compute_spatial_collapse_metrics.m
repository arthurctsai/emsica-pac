% compute_spatial_collapse_metrics() column-overlap diagnostics for EMSICA B.
%
%
% Q is B after column normalization. maxCosB is the maximum absolute
% off-diagonal entry of Q'Q. EoffB follows the Analysis 2 definition:
%
%   Eoff(B) = || Q'Q - I ||_F^2
%
% This helper is diagnostic only; do not use it to change the EMSICA update
% acceptance rule, which may intentionally use a differently scaled energy.
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function [maxCosB, EoffB, Q, G] = compute_spatial_collapse_metrics(B)
Bd = double(B);
if isempty(Bd) || any(~isfinite(Bd(:)))
  maxCosB = NaN;
  EoffB = NaN;
  Q = [];
  G = [];
  return
end
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

[~, K] = size(Bd);
if K == 0
  maxCosB = NaN;
  EoffB = NaN;
  Q = [];
  G = [];
  return
end

col_norm = sqrt(sum(Bd.^2, 1));
col_norm(col_norm <= eps) = eps;
Q = Bd ./ col_norm;
G = Q' * Q;

offdiag = G;
offdiag(1:K+1:end) = 0;
maxCosB = max(abs(offdiag(:)));
EoffB = norm(G - eye(K), 'fro')^2;
end
