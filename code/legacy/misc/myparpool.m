% myparpool() Initializes a parallel pool with the maximum available workers.
%
  % If a pool already exists, it displays the number of active workers.
  % History:
  % 2024-12-19 arthur @UCSD

  % Measure execution time
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function myparpool(nWorkers)
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

  pp = tic;

  % Check if a parallel pool is already open
  pool = gcp('nocreate');

  % Determine the number of workers to use
  if nargin < 1 || isempty(nWorkers)
    nWorkers = parcluster().NumWorkers; % Use maximum workers if nWorkers is not provided
  end

  if isempty(pool)
    % No pool exists, create a new one
    mdisp(['No pool found. Creating a pool with up to ', num2str(nWorkers), ' workers.']);
    try                                                                 % <--
      parpool(nWorkers);                                               % <--
    catch ME                                                           % <--
      warning('Failed to start parpool: %s', ME.message);              % <--
    end                                                                % <--
  else
    % A pool is already open
    mdisp(['A pool is already open with ', num2str(pool.NumWorkers), ' workers.']);
  end

  % Display initialization time
  mdisp(['Initializing a parallel pool took ', mytoc(toc(pp))]);
end
