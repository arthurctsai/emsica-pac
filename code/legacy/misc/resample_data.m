% resample_data() Resamples data by randomly selecting time points with replacement.
%
% INPUT:
% X : A matrix of size [channels x timepoints]
% random_indices : optional 1 x T index vector. When provided, reuse the
%                  same temporal resampling for another aligned matrix.
%
% OUTPUT:
% surrogate_X : Resampled data matrix of the same size as X
% random_indices : sampled indices actually used
%
% Example:
%   % Generate synthetic data: 3 channels x 1000 time points
%   X = rand(3, 5);
%   %
%   % Display original data size
%   disp('Original Data Size:');
%   disp(size(X));
%   %
%   % Resample data
%   surrogate_X = resample_data(X);
%   %
%   % Display resampled data size
%   disp('Surrogate Data Size:');
%   disp(size(surrogate_X));
%   %
%   % Compare the first few values of original and surrogate data
%   disp('First few values of original data:');
%   disp(X(:, 1:5));
%   %
%   disp('First few values of surrogate data:');
%   disp(surrogate_X(:, 1:5));
%
% History:
% 2024-11-29 arthur with chatgpt
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function [surrogate_X, random_indices] = resample_data(X, random_indices)
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

  [I, T] = size(X);

  % Generate random indices with replacement
  if nargin < 2 || isempty(random_indices)
    random_indices = randi(T, 1, T);
  end
  if numel(random_indices) ~= T
    error('resample_data:IndexLengthMismatch', ...
      'random_indices has length %d but X has %d time points.', ...
      numel(random_indices), T);
  end

  % Create surrogate dataset
  surrogate_X = X(:, random_indices);
end
