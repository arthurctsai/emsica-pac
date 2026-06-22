function files = demo_run_all(mode, maxsteps)
% demo_run_all() Run the one-command EMSICA-PAC demonstration.
%
% demo_run_all()             regenerates figures from the validated result.
% demo_run_all('train', 100) reruns Extended EMSICA and then makes figures.
%
% Author: Arthur C. Tsai
% Email: arthur@stat.sinica.edu.tw; arthurctsai@gmail.com
% Copyright (c) Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

if nargin < 1 || isempty(mode), mode = 'reference'; end
if nargin < 2 || isempty(maxsteps), maxsteps = 100; end
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

mode = lower(string(mode));
switch mode
  case "reference"
    tag = 'reference';
  case "train"
    tag = 'demo';
    demo_run_emsica(maxsteps, tag);
  otherwise
    error('demo_run_all:UnknownMode', 'Mode must be "reference" or "train".');
end
files = demo_generate_figures(tag);
end
